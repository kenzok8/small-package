// Package service holds the core operations shared by the HTTP daemon and the
// CLI entry points: add/remove/refresh subscriptions and generate configs.
package service

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/kenzok8/tower/internal/generator"
	"github.com/kenzok8/tower/internal/model"
	"github.com/kenzok8/tower/internal/parser"
	"github.com/kenzok8/tower/internal/rules"
	"github.com/kenzok8/tower/internal/store"
)

// Service bundles the store with the subscription fetch path.
type Service struct {
	Store     *store.Store
	rulesDir  string
	ruleCache *rules.Cache
}

// New creates a Service.
func New(st *store.Store) *Service {
	return &Service{
		Store:     st,
		rulesDir:  filepath.Join(st.Dir(), "rules"),
		ruleCache: rules.NewCache(filepath.Join(st.Dir(), "rule-cache")),
	}
}

// RefreshResult reports the outcome of refreshing one subscription.
type RefreshResult struct {
	ID       string `json:"id"`
	Nodes    int    `json:"nodes"`
	Rejected int    `json:"rejected"`
	Error    string `json:"error,omitempty"`
}

// AddSubscription inserts a new subscription source.
func (s *Service) AddSubscription(name, url, userAgent string) (model.SubscriptionSource, error) {
	if url == "" {
		return model.SubscriptionSource{}, fmt.Errorf("url is required")
	}
	if name == "" {
		name = url
	}
	sub := model.SubscriptionSource{
		ID:        model.NewID(),
		Name:      name,
		URL:       url,
		Enabled:   true,
		CreatedAt: time.Now(),
	}
	if userAgent != "" {
		sub.RequestOptions = &model.RequestOptions{UserAgent: userAgent}
	}
	if _, err := s.Store.Update(func(st *store.State) error {
		st.Subscriptions = append(st.Subscriptions, sub)
		return nil
	}); err != nil {
		return model.SubscriptionSource{}, err
	}
	return sub, nil
}

// ImportNodes parses a pasted config (URI list / Clash YAML / Surge INI / Base64)
// and appends the detected nodes as local nodes (no subscription source).
func (s *Service) ImportNodes(content string) (int, error) {
	parsed := parser.Parse([]byte(content), "")
	if len(parsed.Nodes) == 0 {
		return 0, fmt.Errorf("no nodes found in input")
	}
	_, err := s.Store.Update(func(st *store.State) error {
		st.Nodes = append(st.Nodes, parsed.Nodes...)
		return nil
	})
	if err != nil {
		return 0, err
	}
	return len(parsed.Nodes), nil
}

// UpdateOwnedNode updates one manually imported node without allowing callers
// to modify or replace subscription nodes.
func (s *Service) UpdateOwnedNode(node model.ProxyNode) error {
	if strings.TrimSpace(node.ID) == "" {
		return fmt.Errorf("node id is required")
	}
	if strings.TrimSpace(node.Name) == "" || strings.TrimSpace(node.Server) == "" {
		return fmt.Errorf("node name and server are required")
	}
	if node.Port < 1 || node.Port > 65535 {
		return fmt.Errorf("node port must be between 1 and 65535")
	}
	_, err := s.Store.Update(func(st *store.State) error {
		for i := range st.Nodes {
			if st.Nodes[i].ID != node.ID {
				continue
			}
			if st.Nodes[i].SourceID != "" {
				return fmt.Errorf("subscription nodes cannot be edited")
			}
			node.ID = st.Nodes[i].ID
			node.SourceID = st.Nodes[i].SourceID
			node.Kind = st.Nodes[i].Kind
			node.Name = strings.TrimSpace(node.Name)
			node.Server = strings.TrimSpace(node.Server)
			st.Nodes[i] = node
			return nil
		}
		return fmt.Errorf("node not found: %s", node.ID)
	})
	return err
}

// RemoveOwnedNode deletes one manually imported node.
func (s *Service) RemoveOwnedNode(id string) error {
	id = strings.TrimSpace(id)
	if id == "" {
		return fmt.Errorf("node id is required")
	}
	removed := false
	_, err := s.Store.Update(func(st *store.State) error {
		var nodes []model.ProxyNode
		for _, node := range st.Nodes {
			if node.ID == id {
				if node.SourceID != "" {
					return fmt.Errorf("subscription nodes cannot be deleted here")
				}
				removed = true
				continue
			}
			nodes = append(nodes, node)
		}
		if !removed {
			return fmt.Errorf("node not found: %s", id)
		}
		st.Nodes = nodes
		return nil
	})
	return err
}

// RemoveSubscription deletes a subscription and its parsed nodes.
func (s *Service) RemoveSubscription(id string) error {
	_, err := s.Store.Update(func(st *store.State) error {
		var subs []model.SubscriptionSource
		for _, sub := range st.Subscriptions {
			if sub.ID != id {
				subs = append(subs, sub)
			}
		}
		st.Subscriptions = subs
		var nodes []model.ProxyNode
		for _, n := range st.Nodes {
			if n.SourceID != id {
				nodes = append(nodes, n)
			}
		}
		st.Nodes = nodes
		return nil
	})
	return err
}

// Refresh fetches and re-parses one subscription (id) or all (id == "").
func (s *Service) Refresh(id string) ([]RefreshResult, error) {
	state, err := s.Store.Load()
	if err != nil {
		return nil, err
	}
	var targets []model.SubscriptionSource
	if id != "" {
		for _, sub := range state.Subscriptions {
			if sub.ID == id {
				targets = append(targets, sub)
				break
			}
		}
	} else {
		targets = state.Subscriptions
	}
	if len(targets) == 0 {
		return nil, fmt.Errorf("subscription not found")
	}

	results := []RefreshResult{}
	_, err = s.Store.Update(func(st *store.State) error {
		for _, sub := range targets {
			var current *model.SubscriptionSource
			for i := range st.Subscriptions {
				if st.Subscriptions[i].ID == sub.ID {
					current = &st.Subscriptions[i]
					break
				}
			}
			if current == nil {
				continue
			}
			ua := ""
			if current.RequestOptions != nil {
				ua = current.RequestOptions.UserAgent
			}
			res := RefreshResult{ID: current.ID}
			body, usage, err := FetchSubscription(current.URL, ua)
			if err != nil {
				res.Error = err.Error()
				current.LastError = err.Error()
				results = append(results, res)
				continue
			}
			parsed := parser.Parse(body, current.ID)
			now := time.Now()
			current.LastUpdatedAt = &now
			current.LastError = ""
			current.Usage = usage
			if current.Usage == nil {
				current.Usage = parsed.Status
			}
			var nodes []model.ProxyNode
			for _, n := range st.Nodes {
				if n.SourceID != current.ID {
					nodes = append(nodes, n)
				}
			}
			nodes = append(nodes, parsed.Nodes...)
			st.Nodes = nodes
			res.Nodes = len(parsed.Nodes)
			res.Rejected = parsed.RejectedLineCount
			results = append(results, res)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return results, nil
}

// Export generates a configuration for the given client target. protocols is
// the set of enabled proxy kinds (nil = all); nodeIDs limits output to specific
// nodes (nil = all); schemeID selects a rule scheme (empty = built-in fallback).
func (s *Service) Export(target model.ClientTarget, protocols []model.ProxyKind, nodeIDs []string, schemeID string) (string, error) {
	return s.ExportWithOptions(target, protocols, nodeIDs, schemeID, true)
}

// ExportWithOptions generates a configuration with an explicit preference for
// client-native remote rule sets.
func (s *Service) ExportWithOptions(target model.ClientTarget, protocols []model.ProxyKind, nodeIDs []string, schemeID string, preferRuleSets bool) (string, error) {
	nodes, err := s.selectedNodes(nodeIDs)
	if err != nil {
		return "", err
	}
	var scheme *model.RuleScheme
	if schemeID != "" {
		if scheme, err = s.findScheme(schemeID); err != nil {
			return "", err
		}
	}
	lines := make(map[string][]string)
	if scheme != nil {
		for _, rule := range scheme.Rules {
			if rule.Resource == nil {
				continue
			}
			if cached, err := s.ruleCache.Lines(rule.Resource.URL); err == nil {
				lines[rule.Resource.URL] = cached
				continue
			}
			if name := rules.LocalRuleFilename(rule.Resource.URL); name != "" {
				if b, err := os.ReadFile(filepath.Join(s.rulesDir, name)); err == nil {
					lines[rule.Resource.URL] = strings.Split(string(b), "\n")
				}
			}
		}
	}
	return generator.Generate(generator.Options{
		Target: target, Nodes: nodes, Protocols: protocols, Scheme: scheme,
		PreferRuleSets: preferRuleSets, RuleSetLines: lines,
	})
}

// Schemes returns the bundled presets followed by user-imported schemes.
func (s *Service) Schemes() ([]model.RuleScheme, error) {
	bundled, err := rules.LoadBundled(s.rulesDir)
	if err != nil {
		return nil, err
	}
	state, err := s.Store.Load()
	if err != nil {
		return nil, err
	}
	out := make([]model.RuleScheme, 0, len(bundled)+len(state.Schemes))
	for _, b := range bundled {
		out = append(out, *b)
	}
	out = append(out, state.Schemes...)
	return out, nil
}

// Scheme returns one full compact model for the LuCI details view.
func (s *Service) Scheme(id string) (*model.RuleScheme, error) {
	if strings.TrimSpace(id) == "" {
		return nil, fmt.Errorf("scheme id is required")
	}
	scheme, err := s.findScheme(id)
	if err != nil {
		return nil, err
	}
	copy := *scheme
	copy.RawConfig = ""
	return &copy, nil
}

// SchemeSummary is the compact list representation used by LuCI and rpcd.
type SchemeSummary struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Summary   string `json:"summary,omitempty"`
	SourceURL string `json:"source_url,omitempty"`
	IsBundled bool   `json:"is_bundled,omitempty"`
	Groups    int    `json:"groups"`
	Rules     int    `json:"rules"`
	RuleSets  int    `json:"rule_sets"`
	Cached    bool   `json:"cached"`
}

// SchemeSummaries returns counts without sending rule bodies through rpcd.
func (s *Service) SchemeSummaries() ([]SchemeSummary, error) {
	schemes, err := s.Schemes()
	if err != nil {
		return nil, err
	}
	out := make([]SchemeSummary, 0, len(schemes))
	for _, scheme := range schemes {
		summary := SchemeSummary{
			ID: scheme.ID, Name: scheme.Name, Summary: scheme.Summary,
			SourceURL: publicSourceURL(scheme.SourceURL), IsBundled: scheme.IsBundled,
			Groups: len(scheme.Groups), Cached: true,
		}
		for _, rule := range scheme.Rules {
			if rule.Resource == nil {
				if rule.Final || rule.Body != "" {
					summary.Rules++
				}
				continue
			}
			summary.RuleSets++
			lines, err := s.cachedRuleLines(rule.Resource.URL)
			if err != nil {
				summary.Cached = false
				continue
			}
			for _, line := range lines {
				line = strings.TrimSpace(line)
				if line != "" && !strings.HasPrefix(line, "#") && !strings.HasPrefix(line, ";") && !strings.HasPrefix(line, "//") {
					summary.Rules++
				}
			}
		}
		out = append(out, summary)
	}
	return out, nil
}

func publicSourceURL(raw string) string {
	u, err := url.Parse(raw)
	if err != nil {
		return ""
	}
	u.User = nil
	u.RawQuery = ""
	u.Fragment = ""
	return u.String()
}

func (s *Service) cachedRuleLines(rawURL string) ([]string, error) {
	if lines, err := s.ruleCache.Lines(rawURL); err == nil {
		return lines, nil
	}
	if name := rules.LocalRuleFilename(rawURL); name != "" {
		if b, err := os.ReadFile(filepath.Join(s.rulesDir, name)); err == nil {
			return strings.Split(string(b), "\n"), nil
		}
	}
	return nil, fmt.Errorf("local ruleset cache missing")
}

// AddScheme parses a rule configuration and persists it as a user scheme.
func (s *Service) AddScheme(name, configText, sourceURL string) (model.RuleScheme, error) {
	name = strings.TrimSpace(name)
	if name == "" {
		return model.RuleScheme{}, fmt.Errorf("scheme name is required")
	}
	if strings.TrimSpace(configText) == "" {
		return model.RuleScheme{}, fmt.Errorf("config text is required")
	}
	scheme, err := rules.Parse(configText, nil)
	if err != nil {
		return model.RuleScheme{}, err
	}
	scheme.ID = model.NewID()
	scheme.Name = strings.TrimSpace(name)
	scheme.SourceURL = sourceURL
	// The source document may contain node credentials; the scheme model already
	// holds only groups and rules, so never persist the unfiltered source text.
	scheme.RawConfig = ""
	scheme.IsBundled = false
	if _, err := s.Store.Update(func(st *store.State) error {
		for _, existing := range st.Schemes {
			if strings.EqualFold(existing.Name, name) {
				return fmt.Errorf("规则方案名称已存在")
			}
		}
		st.Schemes = append(st.Schemes, *scheme)
		return nil
	}); err != nil {
		return model.RuleScheme{}, err
	}
	return *scheme, nil
}

// RenameScheme gives an imported scheme a distinct, user-managed label.
func (s *Service) RenameScheme(id, name string) error {
	name = strings.TrimSpace(name)
	if name == "" {
		return fmt.Errorf("规则方案名称不能为空")
	}
	_, err := s.Store.Update(func(st *store.State) error {
		index := -1
		for i, scheme := range st.Schemes {
			if scheme.ID == id {
				index = i
			} else if strings.EqualFold(scheme.Name, name) {
				return fmt.Errorf("规则方案名称已存在")
			}
		}
		if index < 0 {
			return fmt.Errorf("找不到已导入的规则方案")
		}
		st.Schemes[index].Name = name
		return nil
	})
	return err
}

// AddSchemeFromURL fetches a complete rule configuration and imports only its
// groups, rules and remote rule resources.
func (s *Service) AddSchemeFromURL(name, sourceURL string) (model.RuleScheme, error) {
	if strings.TrimSpace(name) == "" {
		return model.RuleScheme{}, fmt.Errorf("scheme name is required")
	}
	u, err := rules.RawFileURL(sourceURL)
	if err != nil {
		return model.RuleScheme{}, err
	}
	client := &http.Client{Timeout: 25 * time.Second, CheckRedirect: func(req *http.Request, via []*http.Request) error {
		if len(via) >= 5 || req.URL.Scheme != "https" {
			return fmt.Errorf("unsafe or excessive redirect")
		}
		return nil
	}}
	req, err := http.NewRequest(http.MethodGet, u, nil)
	if err != nil {
		return model.RuleScheme{}, err
	}
	req.Header.Set("User-Agent", "Tower/0.1")
	resp, err := client.Do(req)
	if err != nil {
		return model.RuleScheme{}, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return model.RuleScheme{}, fmt.Errorf("配置下载失败：HTTP %d", resp.StatusCode)
	}
	body, err := io.ReadAll(io.LimitReader(resp.Body, 8<<20+1))
	if err != nil {
		return model.RuleScheme{}, err
	}
	if len(body) > 8<<20 {
		return model.RuleScheme{}, fmt.Errorf("配置文件超过 8 MiB 限制")
	}
	return s.AddScheme(name, string(body), sourceURL)
}

// RefreshSchemeRulesets refreshes every unique remote resource referenced by a
// scheme. A failed download leaves the previous cached copy untouched.
func (s *Service) RefreshSchemeRulesets(id string) (int, int, error) {
	scheme, err := s.findScheme(id)
	if err != nil {
		return 0, 0, err
	}
	seen := make(map[string]bool)
	updated, failed := 0, 0
	for _, rule := range scheme.Rules {
		if rule.Resource == nil || seen[rule.Resource.URL] {
			continue
		}
		seen[rule.Resource.URL] = true
		if err := s.ruleCache.Download(rule.Resource.URL); err != nil {
			failed++
		} else {
			updated++
		}
	}
	return updated, failed, nil
}

// RemoveScheme deletes a user-imported scheme. Bundled schemes are immutable.
func (s *Service) RemoveScheme(id string) error {
	if strings.TrimSpace(id) == "" {
		return fmt.Errorf("scheme id is required")
	}
	bundled, err := rules.LoadBundled(s.rulesDir)
	if err != nil {
		return err
	}
	for _, scheme := range bundled {
		if scheme.ID == id {
			return fmt.Errorf("bundled schemes cannot be removed")
		}
	}
	var removed model.RuleScheme
	updated, err := s.Store.Update(func(st *store.State) error {
		var out []model.RuleScheme
		for _, sc := range st.Schemes {
			if sc.ID == id {
				removed = sc
				continue
			}
			out = append(out, sc)
		}
		if removed.ID == "" {
			return fmt.Errorf("scheme not found: %s", id)
		}
		st.Schemes = out
		return nil
	})
	if err != nil {
		return err
	}
	used := make(map[string]bool)
	for _, scheme := range updated.Schemes {
		for _, rule := range scheme.Rules {
			if rule.Resource != nil {
				used[rule.Resource.URL] = true
			}
		}
	}
	for _, scheme := range bundled {
		for _, rule := range scheme.Rules {
			if rule.Resource != nil {
				used[rule.Resource.URL] = true
			}
		}
	}
	for _, rule := range removed.Rules {
		if rule.Resource != nil && !used[rule.Resource.URL] {
			s.ruleCache.Remove(rule.Resource.URL)
		}
	}
	return nil
}

// findScheme locates a scheme by id across bundled presets and user schemes.
func (s *Service) findScheme(id string) (*model.RuleScheme, error) {
	bundled, err := rules.LoadBundled(s.rulesDir)
	if err != nil {
		return nil, err
	}
	for _, b := range bundled {
		if b.ID == id {
			return b, nil
		}
	}
	state, err := s.Store.Load()
	if err != nil {
		return nil, err
	}
	for i := range state.Schemes {
		if state.Schemes[i].ID == id {
			return &state.Schemes[i], nil
		}
	}
	return nil, fmt.Errorf("scheme not found: %s", id)
}

// Links converts nodes to shareable subscription links (one per node).
// protocols and nodeIDs filter the node set exactly like Export.
func (s *Service) Links(protocols []model.ProxyKind, nodeIDs []string) ([]generator.LinkResult, error) {
	nodes, err := s.selectedNodes(nodeIDs)
	if err != nil {
		return nil, err
	}
	nodes = generator.FilterNodes(nodes, protocols)
	return generator.Links(nodes), nil
}

// selectedNodes loads the stored nodes, optionally narrowed to the given ids.
func (s *Service) selectedNodes(nodeIDs []string) ([]model.ProxyNode, error) {
	state, err := s.Store.Load()
	if err != nil {
		return nil, err
	}
	if len(nodeIDs) == 0 {
		return state.Nodes, nil
	}
	want := make(map[string]bool, len(nodeIDs))
	for _, id := range nodeIDs {
		want[id] = true
	}
	filtered := make([]model.ProxyNode, 0, len(state.Nodes))
	for _, n := range state.Nodes {
		if want[n.ID] {
			filtered = append(filtered, n)
			delete(want, n.ID)
		}
	}
	if len(want) != 0 {
		return nil, fmt.Errorf("所选节点已不存在，请刷新页面后重试")
	}
	return filtered, nil
}

// ParseNodeIDs splits a comma-separated node id list.
func ParseNodeIDs(raw string) []string {
	if raw == "" {
		return nil
	}
	seen := map[string]bool{}
	var out []string
	for _, part := range strings.Split(raw, ",") {
		id := strings.TrimSpace(part)
		if id == "" || seen[id] {
			continue
		}
		seen[id] = true
		out = append(out, id)
	}
	return out
}

// ParseProtocols splits a comma-separated protocol list into ProxyKind values.
func ParseProtocols(raw string) []model.ProxyKind {
	if raw == "" {
		return nil
	}
	seen := map[model.ProxyKind]bool{}
	var out []model.ProxyKind
	for _, part := range strings.Split(raw, ",") {
		k := model.ProxyKind(strings.TrimSpace(part))
		if k == "" || k == model.KindUnknown || seen[k] {
			continue
		}
		seen[k] = true
		out = append(out, k)
	}
	return out
}

// FetchSubscription downloads a subscription payload.
//
// An empty userAgent means "auto": it tries a sequence of common client UAs and
// accepts the first response that parses to nodes. Airports that only support
// non-Clash formats return a Base64 share link regardless of UA, which the
// parser also understands, so the first attempt usually succeeds.
func FetchSubscription(url, userAgent string) ([]byte, *model.SubscriptionUsage, error) {
	if strings.TrimSpace(userAgent) != "" {
		return fetchOnce(url, userAgent)
	}

	for _, ua := range []string{"clash-verge/v2.4.2", "ClashMeta", "ClashForWindows/0.20.39", "Clash"} {
		body, usage, err := fetchOnce(url, ua)
		if err != nil {
			continue
		}
		if len(parser.Parse(body, "").Nodes) > 0 {
			return body, usage, nil
		}
	}
	return nil, nil, fmt.Errorf("no nodes found at %s", url)
}

func fetchOnce(url, userAgent string) ([]byte, *model.SubscriptionUsage, error) {
	client := &http.Client{Timeout: 20 * time.Second}
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return nil, nil, err
	}
	req.Header.Set("User-Agent", userAgent)
	resp, err := client.Do(req)
	if err != nil {
		return nil, nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, nil, fmt.Errorf("HTTP %d", resp.StatusCode)
	}
	body, err := io.ReadAll(io.LimitReader(resp.Body, 50<<20))
	if err != nil {
		return nil, nil, err
	}
	return body, parseSubscriptionUserinfo(resp.Header.Get("Subscription-Userinfo")), nil
}

func parseSubscriptionUserinfo(value string) *model.SubscriptionUsage {
	usage := &model.SubscriptionUsage{}
	found := false
	for _, item := range strings.Split(value, ";") {
		key, raw, ok := strings.Cut(strings.TrimSpace(item), "=")
		if !ok {
			continue
		}
		n, err := strconv.ParseInt(strings.TrimSpace(raw), 10, 64)
		if err != nil || n < 0 {
			continue
		}
		switch strings.ToLower(strings.TrimSpace(key)) {
		case "upload":
			usage.UploadBytes, found = n, true
		case "download":
			usage.DownloadBytes, found = n, true
		case "total":
			usage.TotalBytes, found = n, true
		case "expire":
			if n > 0 {
				expires := time.Unix(n, 0)
				usage.ExpiresAt, found = &expires, true
			}
		}
	}
	if !found {
		return nil
	}
	return usage
}
