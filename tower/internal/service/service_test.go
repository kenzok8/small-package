package service

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/kenzok8/tower/internal/generator"
	"github.com/kenzok8/tower/internal/model"
	"github.com/kenzok8/tower/internal/store"
)

func TestFetchSubscriptionReadsUserinfoHeader(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Subscription-Userinfo", "upload=1024;download=2048;total=8192;expire=2000000000")
		_, _ = w.Write([]byte("ss://example"))
	}))
	defer server.Close()

	body, usage, err := FetchSubscription(server.URL, "test-agent")
	if err != nil {
		t.Fatalf("FetchSubscription() error = %v", err)
	}
	if string(body) != "ss://example" {
		t.Fatalf("body = %q, want fixture body", body)
	}
	if usage == nil {
		t.Fatal("usage is nil")
	}
	if usage.UploadBytes != 1024 || usage.DownloadBytes != 2048 || usage.TotalBytes != 8192 {
		t.Fatalf("usage bytes = %+v", usage)
	}
	if usage.ExpiresAt == nil || usage.ExpiresAt.Unix() != 2000000000 {
		t.Fatalf("expiry = %v, want Unix timestamp 2000000000", usage.ExpiresAt)
	}
}

func TestClashooInlineExportUsesCachedMappedSource(t *testing.T) {
	dir := t.TempDir()
	st := store.New(dir)
	svc := New(st)
	svc.rulesDir = filepath.Join("..", "..", "files", "rules")
	resourceURL := "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/openai.mrs"
	sourceURL := "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/refs/heads/sing/geo/geosite/openai.json"
	data := `{"version":2,"rules":[{"domain_suffix":["openai.com"]}]}`
	scheme := model.RuleScheme{
		ID: "cached-inline", Name: "cached inline",
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberReference, Value: "DIRECT"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "A", Resource: &model.RuleSchemeRuleSet{Tag: "openai", URL: resourceURL, Format: "mrs", Behavior: "domain"}},
			{Group: "A", Final: true},
		},
	}
	if _, err := st.Update(func(state *store.State) error {
		state.Schemes = append(state.Schemes, scheme)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	hash := sha256.Sum256([]byte(sourceURL))
	cachePath := filepath.Join(dir, "rule-cache", hex.EncodeToString(hash[:])+".list")
	if err := os.MkdirAll(filepath.Dir(cachePath), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(cachePath, []byte(`{"bogus":true}`), 0o644); err != nil {
		t.Fatal(err)
	}
	blocked, err := svc.PreflightExportWithOptions(model.ClientClashooSB, nil, nil, scheme.ID, true)
	if err != nil || blocked.Status != "unsupported" || len(blocked.Issues) != 1 || blocked.Issues[0].Code != "resource_source" {
		t.Fatalf("invalid cached inline source preflight = %#v, %v", blocked, err)
	}
	if err := os.WriteFile(cachePath, []byte(data), 0o644); err != nil {
		t.Fatal(err)
	}
	for i := 0; i < 2; i++ {
		result, err := svc.PreflightExportWithOptions(model.ClientClashooSB, nil, nil, scheme.ID, true)
		if err != nil || result.Status != "exact" {
			t.Fatalf("preflight #%d = %#v, %v", i+1, result, err)
		}
		out, err := svc.ExportWithOptions(model.ClientClashooSB, nil, nil, scheme.ID, true)
		if err != nil || !strings.Contains(out, `"type":"inline"`) || strings.Contains(out, `"type":"remote"`) {
			t.Fatalf("export #%d did not use inline rule set: %v\n%s", i+1, err, out)
		}
	}
}

func TestSurgeFamilyExportUsesCachedMRSYAMLSource(t *testing.T) {
	dir := t.TempDir()
	svc := New(store.New(dir))
	svc.rulesDir = filepath.Join("..", "..", "files", "rules")
	mrsURL := "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/private.mrs"
	yamlURL := strings.TrimSuffix(mrsURL, ".mrs") + ".yaml"
	scheme := model.RuleScheme{
		ID: "mrs-yaml", Name: "MRS YAML",
		Groups: []model.RuleSchemeGroup{{Name: "Proxy", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberReference, Value: "DIRECT"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "Proxy", Resource: &model.RuleSchemeRuleSet{Tag: "private", URL: mrsURL, Format: "mrs", Behavior: "domain"}},
			{Group: "Proxy", Final: true},
		},
	}
	if _, err := svc.Store.Update(func(state *store.State) error {
		state.Schemes = append(state.Schemes, scheme)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	hash := sha256.Sum256([]byte(yamlURL))
	cachePath := filepath.Join(dir, "rule-cache", hex.EncodeToString(hash[:])+".list")
	if err := os.MkdirAll(filepath.Dir(cachePath), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(cachePath, []byte("payload:\n  - exact.test\n  - +.suffix.test\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	mrsHash := sha256.Sum256([]byte(mrsURL))
	mrsCachePath := filepath.Join(dir, "rule-cache", hex.EncodeToString(mrsHash[:])+".list")
	if err := os.WriteFile(mrsCachePath, []byte("binary MRS fixture"), 0o644); err != nil {
		t.Fatal(err)
	}
	summaries, err := svc.SchemeSummaries()
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, summary := range summaries {
		if summary.ID == scheme.ID {
			found = true
			if !summary.Cached || summary.Rules != 3 {
				t.Fatalf("mapped YAML summary = %#v, want 2 payload rules and FINAL", summary)
			}
		}
	}
	if !found {
		t.Fatal("mapped YAML scheme summary missing")
	}
	for _, target := range []model.ClientTarget{model.ClientShadowrocket, model.ClientSurge, model.ClientSurgeMac} {
		out, err := svc.ExportWithOptions(target, nil, nil, scheme.ID, true)
		if err != nil {
			t.Fatalf("%s export: %v", target, err)
		}
		if !strings.Contains(out, "DOMAIN,exact.test,Proxy") || !strings.Contains(out, "DOMAIN-SUFFIX,suffix.test,Proxy") || strings.Contains(out, mrsURL) {
			t.Fatalf("%s did not use the mapped YAML cache", target)
		}
	}
	if err := os.Remove(cachePath); err != nil {
		t.Fatal(err)
	}
	summaries, err = svc.SchemeSummaries()
	if err != nil {
		t.Fatal(err)
	}
	for _, summary := range summaries {
		if summary.ID == scheme.ID && summary.Cached {
			t.Fatal("binary MRS cache incorrectly marked scheme as cached")
		}
	}
}

func TestParseSubscriptionUserinfoToleratesSpacingAndInvalidFields(t *testing.T) {
	usage := parseSubscriptionUserinfo(" upload = 12 ; download=bad; total=40; expire=-1 ")
	if usage == nil || usage.UploadBytes != 12 || usage.TotalBytes != 40 || usage.DownloadBytes != 0 || usage.ExpiresAt != nil {
		t.Fatalf("parsed usage = %+v", usage)
	}
}

func TestAddSchemeRequiresName(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	if _, err := svc.AddScheme("  ", "proxies: []", ""); err == nil {
		t.Fatal("AddScheme() accepted an empty name")
	}
}

func TestImportedSchemeCanBeRenamedAndNamesStayDistinct(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	config := "proxy-groups:\n  - name: 节点选择\n    type: select\n    proxies: [DIRECT]\nrules:\n  - MATCH,节点选择\n"
	first, err := svc.AddScheme("个人方案", config, "")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := svc.AddScheme("个人方案", config, ""); err == nil {
		t.Fatal("AddScheme() accepted a duplicate name")
	}
	if err := svc.RenameScheme(first.ID, "旅行方案"); err != nil {
		t.Fatal(err)
	}
	state, err := svc.Store.Load()
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, scheme := range state.Schemes {
		if scheme.ID == first.ID {
			found = scheme.Name == "旅行方案"
		}
	}
	if !found {
		t.Fatal("renamed scheme was not persisted")
	}
}

func TestAddSchemeDoesNotRequireRemoteRuleAccess(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	config := `rule-providers:
  offline:
    type: http
    behavior: classical
    format: text
    url: https://127.0.0.1:1/rules.list
proxy-groups:
  - name: 节点选择
    type: select
    proxies: [DIRECT]
rules:
  - RULE-SET,offline,节点选择
  - MATCH,节点选择
`
	scheme, err := svc.AddScheme("离线导入", config, "")
	if err != nil {
		t.Fatal(err)
	}
	if scheme.ID == "" || len(scheme.Rules) != 2 {
		t.Fatalf("scheme not persisted: %+v", scheme)
	}
	state, err := svc.Store.Load()
	if err != nil {
		t.Fatal(err)
	}
	if len(state.Schemes) != 1 || state.Schemes[0].ID != scheme.ID {
		t.Fatal("imported scheme missing from state")
	}
	if svc.ruleCache.Has("https://127.0.0.1:1/rules.list") {
		t.Fatal("remote rule was unexpectedly cached")
	}
}

func TestUpdateAndRemoveOwnedNode(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	local := model.ProxyNode{ID: "local-1", Kind: model.KindVLESS, Name: "old", Server: "old.example", Port: 443}
	subscription := model.ProxyNode{ID: "sub-1", SourceID: "sub", Kind: model.KindVMess, Name: "subscribed", Server: "sub.example", Port: 443}
	if _, err := svc.Store.Update(func(state *store.State) error {
		state.Nodes = append(state.Nodes, local, subscription)
		return nil
	}); err != nil {
		t.Fatal(err)
	}

	local.Name = "new"
	local.Server = "new.example"
	if err := svc.UpdateOwnedNode(local); err != nil {
		t.Fatalf("UpdateOwnedNode() error = %v", err)
	}
	if err := svc.UpdateOwnedNode(subscription); err == nil {
		t.Fatal("UpdateOwnedNode() accepted a subscription node")
	}
	if err := svc.RemoveOwnedNode("sub-1"); err == nil {
		t.Fatal("RemoveOwnedNode() accepted a subscription node")
	}
	if err := svc.RemoveOwnedNode("local-1"); err != nil {
		t.Fatalf("RemoveOwnedNode() error = %v", err)
	}

	state, err := svc.Store.Load()
	if err != nil {
		t.Fatal(err)
	}
	if len(state.Nodes) != 1 || state.Nodes[0].ID != "sub-1" || state.Nodes[0].Name != "subscribed" {
		t.Fatalf("unexpected remaining nodes: %+v", state.Nodes)
	}
}

func TestStoredRenewalNoticeIsExcludedFromNodesAndExports(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	good := model.ProxyNode{ID: "good", Kind: model.KindShadowsocks, Name: "香港 01", Server: "203.0.113.10", Port: 8388, Cipher: "aes-256-gcm", Password: "password"}
	notice := model.ProxyNode{ID: "renew", Kind: model.KindShadowsocks, Name: "急续费节点-10X", Server: "203.0.113.11", Port: 8388, Cipher: "aes-256-gcm", Password: "password"}
	if _, err := svc.Store.Update(func(state *store.State) error {
		state.Nodes = append(state.Nodes, good, notice)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	nodes, err := svc.Nodes()
	if err != nil || len(nodes) != 1 || nodes[0].ID != good.ID {
		t.Fatalf("visible nodes = %#v, %v", nodes, err)
	}
	selected, err := svc.selectedNodes(nil)
	if err != nil || len(selected) != 1 || selected[0].ID != good.ID {
		t.Fatalf("export nodes = %#v, %v", selected, err)
	}
	if _, err := svc.selectedNodes([]string{notice.ID}); err == nil {
		t.Fatal("stored renewal notice was selectable for export")
	}
}

func TestUpdateOwnedNodeValidatesRequiredFields(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	if err := svc.UpdateOwnedNode(model.ProxyNode{ID: "node-1", Name: "node", Server: "example.com", Port: 0}); err == nil {
		t.Fatal("UpdateOwnedNode() accepted an invalid port")
	}
	if err := svc.RemoveOwnedNode(" "); err == nil {
		t.Fatal("RemoveOwnedNode() accepted an empty id")
	}
}

func TestStrictPreflightTreatsEmptyNodeSelectionAsEmpty(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	node := model.ProxyNode{ID: "stored", Kind: model.KindVLESS, Name: "stored", Server: "stored.example", Port: 443, UUID: "12345678-1234-4321-8765-123456789abc", TLS: true, SNI: "stored.example"}
	if _, err := svc.Store.Update(func(state *store.State) error {
		state.Nodes = append(state.Nodes, node)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	for _, ids := range [][]string{nil, {}} {
		result, err := svc.PreflightExportStrict(model.ClientSingBox, nil, ids, "", true)
		if err != nil {
			t.Fatalf("PreflightExportStrict() error = %v", err)
		}
		if result.Status != "unsupported" || len(result.Issues) == 0 || result.Issues[0].Code != "nodes_empty" {
			t.Fatalf("empty strict selection preflight = %#v, want nodes_empty blocking issue", result)
		}
	}
}

func TestStrictExportRejectsEmptyNodeSelection(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	node := model.ProxyNode{ID: "stored", Kind: model.KindVLESS, Name: "stored", Server: "stored.example", Port: 443, UUID: "12345678-1234-4321-8765-123456789abc", TLS: true, SNI: "stored.example"}
	if _, err := svc.Store.Update(func(state *store.State) error {
		state.Nodes = append(state.Nodes, node)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	if _, err := svc.ExportStrict(model.ClientSingBox, nil, nil, "", true, ""); err == nil || !strings.Contains(err.Error(), "至少需要一个已选择的节点") {
		t.Fatalf("ExportStrict() error = %v, want an empty selection error", err)
	}
}

func TestLegacyExportStillTreatsEmptyNodeIDsAsAll(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	node := model.ProxyNode{ID: "node-1", Kind: model.KindShadowsocks, Name: "node", Server: "node.example", Port: 8388, Cipher: "aes-256-gcm", Password: "fixture"}
	if _, err := svc.Store.Update(func(state *store.State) error {
		state.Nodes = append(state.Nodes, node)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	out, err := svc.ExportWithOptions(model.ClientSurge, nil, nil, "", true)
	if err != nil || !strings.Contains(out, "node.example") {
		t.Fatalf("legacy empty node IDs did not select all nodes: err=%v", err)
	}
}

func TestStrictPreflightBindsRenderedContentAndAllowsNoProtocolFilter(t *testing.T) {
	for _, target := range []model.ClientTarget{model.ClientClashVerge, model.ClientSurge, model.ClientSurgeMac, model.ClientShadowrocket} {
		t.Run(string(target), func(t *testing.T) {
			svc := New(store.New(t.TempDir()))
			node := model.ProxyNode{ID: "node-1", Kind: model.KindShadowsocks, Name: "node", Server: "node.example", Port: 8388, Cipher: "aes-256-gcm", Password: "fixture"}
			if _, err := svc.Store.Update(func(state *store.State) error {
				state.Nodes = append(state.Nodes, node)
				return nil
			}); err != nil {
				t.Fatal(err)
			}
			preflight, err := svc.PreflightExportStrict(target, nil, []string{"node-1"}, "", true)
			if err != nil || preflight.Status != "exact" || preflight.PlanDigest == "" {
				t.Fatalf("strict preflight = %#v, err=%v, want exact digest", preflight, err)
			}
			strict, err := svc.ExportStrict(target, nil, []string{"node-1"}, "", true, preflight.PlanDigest)
			if err != nil {
				t.Fatalf("strict export failed with matching digest: %v", err)
			}
			legacy, err := svc.ExportWithOptions(target, nil, []string{"node-1"}, "", true)
			if err != nil || strict != legacy {
				t.Fatalf("strict output differs from legacy renderer: strict=%t err=%v", strict == legacy, err)
			}
			if _, err := svc.ExportStrict(target, nil, []string{"node-1"}, "", true, "stale"); err == nil {
				t.Fatal("strict export accepted a stale digest")
			}
		})
	}
}

func TestServiceRegionIsDigestBoundAndNarrowsGroupMembers(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	svc.rulesDir = filepath.Join("..", "..", "files", "rules")
	scheme := model.RuleScheme{
		ID: "region-test", Name: "region test",
		Groups: []model.RuleSchemeGroup{{Name: "OpenAI", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules:  []model.RuleSchemeRule{{Group: "OpenAI", Body: "DOMAIN,openai.example"}, {Group: "DIRECT", Final: true}},
	}
	nodes := []model.ProxyNode{
		{ID: "hk", Kind: model.KindShadowsocks, Name: "🇭🇰 Hong Kong A", Server: "hk.example", Port: 8388, Cipher: "aes-256-gcm", Password: "fixture"},
		{ID: "tw", Kind: model.KindShadowsocks, Name: "🇹🇼 Taiwan A", Server: "tw.example", Port: 8389, Cipher: "aes-256-gcm", Password: "fixture"},
	}
	if _, err := svc.Store.Update(func(state *store.State) error {
		state.Schemes = append(state.Schemes, scheme)
		state.Nodes = append(state.Nodes, nodes...)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	regions := map[string]string{"openai": "hk"}
	preflight, err := svc.PreflightExportStrictWithServiceRegions(model.ClientSingBox, nil, []string{"hk", "tw"}, scheme.ID, true, regions)
	if err != nil || preflight.Status != generator.PreflightExact || preflight.PlanDigest == "" {
		t.Fatalf("region preflight = %#v, err=%v", preflight, err)
	}
	content, err := svc.ExportStrictWithServiceRegions(model.ClientSingBox, nil, []string{"hk", "tw"}, scheme.ID, true, preflight.PlanDigest, regions)
	if err != nil {
		t.Fatal(err)
	}
	var config struct {
		Outbounds []struct {
			Tag       string   `json:"tag"`
			Outbounds []string `json:"outbounds"`
		} `json:"outbounds"`
	}
	if err := json.Unmarshal([]byte(content), &config); err != nil {
		t.Fatal(err)
	}
	var members []string
	for _, outbound := range config.Outbounds {
		if outbound.Tag == "OpenAI" {
			members = outbound.Outbounds
			break
		}
	}
	if len(members) != 1 || !strings.Contains(members[0], "Hong Kong") || strings.Contains(strings.Join(members, " "), "Taiwan") || !strings.Contains(content, "openai.example") {
		t.Fatalf("region export OpenAI group members = %v", members)
	}
	if _, err := svc.ExportStrictWithServiceRegions(model.ClientSingBox, nil, []string{"hk", "tw"}, scheme.ID, true, preflight.PlanDigest, map[string]string{"openai": "tw"}); err == nil {
		t.Fatal("region export accepted a digest generated for a different region")
	}
}

func TestNodesExposeDerivedRegionWithoutPersistingIt(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	node := model.ProxyNode{ID: "hk", Kind: model.KindShadowsocks, Name: "香港 A", Server: "hk.example", Port: 8388, Cipher: "aes-256-gcm", Password: "fixture"}
	if _, err := svc.Store.Update(func(state *store.State) error {
		state.Nodes = append(state.Nodes, node)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	listed, err := svc.Nodes()
	if err != nil || len(listed) != 1 || listed[0].EffectiveRegion != "hk" {
		t.Fatalf("nodes response effective_region = %#v, err=%v", listed, err)
	}
	stored, err := svc.Store.Load()
	if err != nil || len(stored.Nodes) != 1 || stored.Nodes[0].EffectiveRegion != "" {
		t.Fatalf("derived effective_region was persisted: %#v, err=%v", stored.Nodes, err)
	}
}

func TestNativeDAESchemeClonesKenzok8AndExpandsCachedResources(t *testing.T) {
	svc := New(store.New(t.TempDir()))
	svc.rulesDir = filepath.Join("..", "..", "files", "rules")
	schemes, err := svc.Schemes()
	if err != nil {
		t.Fatal(err)
	}
	var source, native *model.RuleScheme
	for i := range schemes {
		switch schemes[i].ID {
		case "kenzok8-rules":
			source = &schemes[i]
		case nativeDAESchemeID:
			native = &schemes[i]
		}
	}
	if source == nil || native == nil {
		t.Fatal("bundled and native Kenzok8 schemes were not both registered")
	}
	if native.TargetOnly != model.ClientDAE || len(native.Rules) != 21 {
		t.Fatalf("native scheme target/rules = %s/%d, want dae-config/21", native.TargetOnly, len(native.Rules))
	}
	resourceCount := 0
	for _, rule := range native.Rules {
		if rule.Resource != nil {
			resourceCount++
		}
	}
	if resourceCount != 20 || source.Rules[0].Group != "🌐 直连" || native.Rules[0].Group != "DIRECT" {
		t.Fatalf("clone resource/rule mapping = %d/%q/%q, want 20 resources, preserved source, direct policy mapping", resourceCount, source.Rules[0].Group, native.Rules[0].Group)
	}
	lines := make(map[string][]string)
	for _, rule := range native.Rules {
		if rule.Resource == nil {
			continue
		}
		resource := rule.Resource
		if resource.Format != "mrs" {
			lines[resource.URL] = []string{"DOMAIN-SUFFIX,example.test"}
		}
	}
	nodes := []model.ProxyNode{
		{ID: "hk", Kind: model.KindVLESS, Name: "香港 node", Server: "hk.example", Port: 443, UUID: "12345678-1234-4321-8765-123456789abc", TLS: true, SNI: "hk.example"},
		{ID: "tw", Kind: model.KindVLESS, Name: "台湾 node", Server: "tw.example", Port: 443, UUID: "12345678-1234-4321-8765-123456789abc", TLS: true, SNI: "tw.example"},
		{ID: "sg", Kind: model.KindVLESS, Name: "新加坡 node", Server: "sg.example", Port: 443, UUID: "12345678-1234-4321-8765-123456789abc", TLS: true, SNI: "sg.example"},
		{ID: "jp", Kind: model.KindVLESS, Name: "日本 node", Server: "jp.example", Port: 443, UUID: "12345678-1234-4321-8765-123456789abc", TLS: true, SNI: "jp.example"},
	}
	opts := generator.Options{
		Target: model.ClientDAE, Nodes: nodes, Scheme: native, RuleSetLines: lines, Strict: true,
		ServiceRegions: map[string]string{"claude": "sg", "openai": "hk", "gemini": "jp", "netflix": "tw"},
	}
	preflight := generator.DAEPreflight(opts)
	if preflight.Status != generator.PreflightExact || preflight.PlanDigest == "" {
		codes := make([]string, 0, len(preflight.Issues))
		for _, issue := range preflight.Issues {
			codes = append(codes, issue.Code)
		}
		t.Fatalf("native DAE preflight = %s, issues=%v, want exact target-specific DAT mapping", preflight.Status, codes)
	}
	plannedResourceCount := 0
	for _, item := range preflight.Planned {
		if item.Kind == "resource" {
			plannedResourceCount++
			if item.URL == "" || item.SourceURL == "" || item.ExpandedRules == 0 {
				t.Fatalf("native DAE resource manifest is incomplete: %#v", item)
			}
			if item.SourceFormat == "mrs" && (item.Format != "dae-dat" || item.MappingReason != generator.DAENativeDATPolicyRevision()) {
				t.Fatalf("MRS resource did not use the declared DAT policy: %#v", item)
			}
		}
	}
	if plannedResourceCount != 25 {
		t.Fatalf("native DAE manifest has %d resources, want 20 original plus five service resources", plannedResourceCount)
	}
	opts.PlanDigest = preflight.PlanDigest
	content, err := generator.Generate(opts)
	if err != nil {
		t.Fatalf("native DAE generation failed with matching digest: %v", err)
	}
	if !strings.Contains(content, "domain(suffix: example.test)") || strings.Contains(content, "192.0.2.0/24") || strings.Count(content, " -> ") != 26 || !strings.Contains(content, "domain(geosite: openai)") || !strings.Contains(content, "domain(geosite: anthropic)") || !strings.Contains(content, "domain(geosite: google-gemini)") || !strings.Contains(content, "domain(geosite: netflix)") || !strings.Contains(content, "dip(geoip: netflix)") || !strings.Contains(content, "dip(geoip: cn)") || !strings.Contains(content, "fallback: group_") || len(content) > 16<<10 {
		t.Fatalf("native DAE compact-output assertions: suffix=%t inlineCIDR=%t route_rules=%d geosite=%t/%t/%t/%t geoip=%t/%t fallback=%t bytes=%d", strings.Contains(content, "domain(suffix: example.test)"), strings.Contains(content, "192.0.2.0/24"), strings.Count(content, " -> "), strings.Contains(content, "domain(geosite: openai)"), strings.Contains(content, "domain(geosite: anthropic)"), strings.Contains(content, "domain(geosite: google-gemini)"), strings.Contains(content, "domain(geosite: netflix)"), strings.Contains(content, "dip(geoip: netflix)"), strings.Contains(content, "dip(geoip: cn)"), strings.Contains(content, "fallback: group_"), len(content))
	}
	if privateOffset, openAIOffset := strings.Index(content, "domain(geosite: private)"), strings.Index(content, "domain(geosite: openai)"); privateOffset < 0 || openAIOffset < 0 || privateOffset > openAIOffset {
		t.Fatalf("private DAT rule must remain ahead of regional service rules: private=%d openai=%d", privateOffset, openAIOffset)
	}
	changedLines := make(map[string][]string, len(lines))
	for url, values := range lines {
		changedLines[url] = append([]string(nil), values...)
	}
	for url := range changedLines {
		changedLines[url] = []string{"DOMAIN-SUFFIX,changed.test"}
		break
	}
	changedOptions := opts
	changedOptions.RuleSetLines = changedLines
	changed := generator.DAEPreflight(changedOptions)
	if changed.Status != generator.PreflightExact || changed.PlanDigest == preflight.PlanDigest {
		t.Fatalf("changed cached resource preflight = %s, digest changed=%t", changed.Status, changed.PlanDigest != preflight.PlanDigest)
	}
	changedOptions.PlanDigest = preflight.PlanDigest
	if _, err := generator.Generate(changedOptions); err == nil {
		t.Fatal("DAE export accepted a stale resource-content digest")
	}
	changedOptions.PlanDigest = changed.PlanDigest
	if _, err := generator.Generate(changedOptions); err != nil {
		t.Fatalf("DAE export rejected the digest for the changed source snapshot: %v", err)
	}
}
