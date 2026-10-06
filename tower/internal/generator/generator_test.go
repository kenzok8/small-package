package generator

import (
	"crypto/sha256"
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"regexp"
	"strings"
	"testing"

	yamlv3 "gopkg.in/yaml.v3"

	"github.com/kenzok8/tower/internal/model"
	"github.com/kenzok8/tower/internal/rules"
)

func sampleNodes() []model.ProxyNode {
	return []model.ProxyNode{
		{Kind: model.KindShadowsocks, Name: "香港 01", Server: "hk.example.com", Port: 8388, Cipher: "aes-256-gcm", Password: "pass123"},
		{Kind: model.KindTrojan, Name: "日本 02", Server: "jp.example.com", Port: 443, Password: "pass456", TLS: true, SNI: "jp.example.com", Transport: "ws", Path: "/ws"},
		{Kind: model.KindVMess, Name: "美国 03", Server: "us.example.com", Port: 443, UUID: "12345678-1234-4321-8765-123456789abc", Cipher: "auto", Transport: "ws", Path: "/ws", HostHeader: "us.example.com", TLS: true},
	}
}

func kenzok8Nodes() []model.ProxyNode {
	nodes := sampleNodes()
	for i, name := range []string{"新加坡 01", "台湾 01", "韩国 01", "英国 01", "德国 01", "法国 01", "其他地区 01"} {
		nodes = append(nodes, model.ProxyNode{
			Kind:     model.KindShadowsocks,
			Name:     name,
			Server:   "region.example.com",
			Port:     8388 + i,
			Cipher:   "aes-256-gcm",
			Password: "fixture",
		})
	}
	nodes = append(nodes, model.ProxyNode{
		Kind: model.KindShadowsocks, Name: "Netflix 节点", Server: "region.example.com",
		Port: 8399, Cipher: "aes-256-gcm", Password: "fixture",
	})
	return nodes
}

func TestGenerateClash(t *testing.T) {
	out, err := Generate(Options{Target: model.ClientClashVerge, Nodes: sampleNodes()})
	if err != nil {
		t.Fatal(err)
	}
	var doc map[string]any
	if err := yamlv3.Unmarshal([]byte(out), &doc); err != nil {
		t.Fatalf("clash output is not valid YAML: %v\n%s", err, out)
	}
	proxies, ok := doc["proxies"].([]any)
	if !ok || len(proxies) != 3 {
		t.Fatalf("want 3 proxies, got %v", doc["proxies"])
	}
	if !strings.Contains(out, "type: ss") || !strings.Contains(out, "type: trojan") || !strings.Contains(out, "type: vmess") {
		t.Errorf("clash output missing proxy types:\n%s", out)
	}
}

func TestOpenWrtTargetHeaders(t *testing.T) {
	tests := []struct {
		target model.ClientTarget
		name   string
	}{
		{model.ClientOpenClash, "OpenClash"},
		{model.ClientNikki, "Nikki"},
		{model.ClientClashoo, "Clashoo (Mihomo)"},
	}
	for _, tt := range tests {
		out, err := Generate(Options{Target: tt.target, Nodes: sampleNodes()})
		if err != nil {
			t.Fatal(err)
		}
		if !strings.HasPrefix(out, "# Generated locally by Tower for "+tt.name+"\n") {
			t.Fatalf("%s header is wrong", tt.name)
		}
	}
}

func TestRemovedAndUnknownTargetsAreRejected(t *testing.T) {
	for _, target := range []model.ClientTarget{"daede-config", "homeproxy-uci", "unknown"} {
		if _, err := Generate(Options{Target: target, Nodes: sampleNodes()}); err == nil {
			t.Fatalf("target %q unexpectedly generated a config", target)
		}
	}
}

func TestDAEDegradedPlanRequiresExactAcknowledgement(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "Auto", Kind: model.KindURLTest, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules:  []model.RuleSchemeRule{{Group: "Auto", Body: "DOMAIN,example.test"}, {Group: "Auto", Final: true}},
	}
	base := Options{Target: model.ClientDAE, Nodes: sampleNodes(), Scheme: scheme}
	result := DAEPreflight(base)
	if result.Status != PreflightDegraded || result.PlanDigest == "" || len(result.Warnings) != 1 || result.Warnings[0].ID != "group_policy@groups[0].kind" {
		t.Fatalf("DAEPreflight = %#v, want one identified degraded warning and digest", result)
	}
	if _, err := Generate(base); err == nil {
		t.Fatal("Generate bypassed DAE degraded consent")
	}
	if _, err := GenerateDAE(base); err == nil {
		t.Fatal("GenerateDAE bypassed degraded consent")
	}
	accepted := base
	accepted.PlanDigest = result.PlanDigest
	accepted.AcceptedDegradations = []string{result.Warnings[0].ID}
	if _, err := Generate(accepted); err != nil {
		t.Fatalf("Generate with exact acknowledgement: %v", err)
	}
	if _, err := GenerateDAE(accepted); err != nil {
		t.Fatalf("GenerateDAE with exact acknowledgement: %v", err)
	}
	stale := accepted
	stale.PlanDigest = "stale"
	if _, err := Generate(stale); err == nil {
		t.Fatal("Generate accepted stale DAE plan digest")
	}
	incomplete := accepted
	incomplete.AcceptedDegradations = nil
	if _, err := Generate(incomplete); err == nil {
		t.Fatal("Generate accepted DAE plan without warning acknowledgement")
	}
}

func TestDAENativeDATMappingKeepsKnownMRSResourcesCompact(t *testing.T) {
	scheme := &model.RuleScheme{
		ID:     "kenzok8-dae-native",
		Groups: []model.RuleSchemeGroup{{Name: "AI", Kind: model.KindDAENativeAuto, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "AI", Resource: &model.RuleSchemeRuleSet{Tag: "openai", URL: "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/openai.mrs", Format: "mrs", Behavior: "domain"}},
			{Group: "AI", Final: true},
		},
	}
	base := Options{Target: model.ClientDAE, Nodes: sampleNodes(), Scheme: scheme, Strict: true}
	result := DAEPreflight(base)
	if result.Status != PreflightExact || result.PlanDigest == "" {
		t.Fatalf("DAEPreflight = %#v, want exact native DAT plan", result)
	}
	var mapped bool
	for _, item := range result.Planned {
		if item.Kind == "resource" && item.Name == "openai" {
			mapped = item.Format == "dae-dat" && item.ExpandedRules == 1 && item.MappingReason == daeDATPolicyRevision
		}
	}
	if !mapped {
		t.Fatalf("planned resources = %#v, want compact DAT mapping metadata", result.Planned)
	}
	base.PlanDigest = result.PlanDigest
	out, err := GenerateDAE(base)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "domain(geosite: openai) -> group_001") || strings.Contains(out, "openai.mrs") || len(out) > 4096 {
		t.Fatalf("DAE output did not use compact native DAT mapping (size %d)", len(out))
	}

	for _, resourceURL := range []string{
		"https://example.invalid/MetaCubeX/meta-rules-dat/meta/geo/geosite/openai.mrs",
		"https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/not-allowlisted.mrs",
		"https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/openai.mrs?x=1",
	} {
		if _, ok := DAENativeRuleSet("kenzok8-dae-native", model.RuleSchemeRuleSet{URL: resourceURL, Format: "mrs"}); ok {
			t.Errorf("DAENativeRuleSet unexpectedly mapped %q", resourceURL)
		}
	}
	if _, ok := DAENativeRuleSet("user-import", model.RuleSchemeRuleSet{URL: "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/openai.mrs", Format: "mrs"}); ok {
		t.Fatal("DAENativeRuleSet mapped a user-imported scheme without a target policy")
	}
}

func TestEffectiveRegionUsesOverrideThenKnownNameAliases(t *testing.T) {
	tests := []struct {
		node model.ProxyNode
		want string
	}{
		{model.ProxyNode{Name: "香港 01"}, "hk"},
		{model.ProxyNode{Name: "🇯🇵 Tokyo 02"}, "jp"},
		{model.ProxyNode{Name: "US-West 01"}, "us"},
		{model.ProxyNode{Name: "server-usual"}, ""},
		{model.ProxyNode{Name: "香港 01", CountryOverride: "SG"}, "sg"},
		{model.ProxyNode{Name: "香港 01", CountryOverride: "invalid"}, "hk"},
	}
	for _, test := range tests {
		if got := EffectiveRegion(test.node); got != test.want {
			t.Errorf("EffectiveRegion(%q, %q) = %q, want %q", test.node.Name, test.node.CountryOverride, got, test.want)
		}
	}
}

func TestACLServiceRegionsInjectIndependentRulesAfterPrivatePrefix(t *testing.T) {
	scheme := &model.RuleScheme{
		ID: "acl4ssr-online", Name: "ACL fixture",
		Groups: []model.RuleSchemeGroup{{Name: "Proxy", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "DIRECT", Body: "DOMAIN-SUFFIX,lan"},
			{Group: "DIRECT", Body: "GEOIP,CN"},
			{Group: "Proxy", Body: "DOMAIN-SUFFIX,example.test"},
			{Group: "Proxy", Final: true},
		},
	}
	nodes := []model.ProxyNode{
		{ID: "hk", Kind: model.KindShadowsocks, Name: "same name", CountryOverride: "hk", Server: "hk.example", Port: 8388, Cipher: "aes-256-gcm", Password: "fixture"},
		{ID: "tw", Kind: model.KindShadowsocks, Name: "same name", CountryOverride: "tw", Server: "tw.example", Port: 8389, Cipher: "aes-256-gcm", Password: "fixture"},
	}
	for _, target := range []model.ClientTarget{model.ClientSingBox, model.ClientDAE} {
		t.Run(string(target), func(t *testing.T) {
			opts := Options{Target: target, Nodes: nodes, Scheme: scheme, PreferRuleSets: true, Strict: true, ServiceRegions: map[string]string{"openai": "hk", "netflix": "tw"}}
			prepared := PrepareServiceRegionPolicy(opts)
			if len(scheme.Groups) != 1 || len(scheme.Rules) != 4 {
				t.Fatalf("region preparation mutated the source scheme: groups=%d rules=%d", len(scheme.Groups), len(scheme.Rules))
			}
			if len(prepared.Scheme.Groups) != 3 || len(prepared.Scheme.Rules) != 7 || prepared.Scheme.Rules[0].Body != "DOMAIN-SUFFIX,lan" || prepared.Scheme.Rules[1].Resource == nil || prepared.Scheme.Rules[1].Resource.Tag != "tower-service-openai-hk-geosite-openai" || prepared.Scheme.Rules[4].Body != "GEOIP,CN" {
				t.Fatalf("service-specific rules were not inserted after the private prefix: %#v", prepared.Scheme.Rules)
			}
			for _, group := range prepared.Scheme.Groups[1:] {
				if len(group.Members) != 1 {
					t.Fatalf("service region group %q has invalid member count: %#v", group.Name, group.Members)
				}
				matcher := regexp.MustCompile(group.Members[0].Value)
				if strings.Contains(group.Name, "OpenAI") && (!matcher.MatchString("same name") || matcher.MatchString("same name · 2")) {
					t.Fatalf("service region group %q has invalid node selection: %#v", group.Name, group.Members)
				}
				if strings.Contains(group.Name, "Netflix") && (!matcher.MatchString("same name · 2") || matcher.MatchString("same name")) {
					t.Fatalf("region member matcher included duplicate name from another country: %q", group.Members[0].Value)
				}
			}
			preflight := Preflight(prepared)
			if target.Family() == model.FamilyDAE {
				preflight = DAEPreflight(prepared)
			}
			if preflight.Status != PreflightExact || preflight.PlanDigest == "" {
				t.Fatalf("service-region preflight = %s, issues=%v", preflight.Status, preflight.Issues)
			}
			prepared.PlanDigest = preflight.PlanDigest
			content, err := Generate(prepared)
			if err != nil {
				t.Fatal(err)
			}
			if target.Family() == model.FamilyDAE {
				if !strings.Contains(content, "domain(geosite: openai) -> group_") || !strings.Contains(content, "dip(geoip: netflix) -> group_") {
					t.Fatalf("service-specific native rules are missing from %s output", target)
				}
			} else if !strings.Contains(content, "Tower-Service-OpenAI-hk") || !strings.Contains(content, "Tower-Service-Netflix-tw") {
				t.Fatalf("service-specific routes are missing from %s output", target)
			}
		})
	}
}

func TestDAEACLPoliciesRunBundledSchemesWithExplicitTargetPolicy(t *testing.T) {
	schemes, err := rules.LoadBundled("../../files/rules")
	if err != nil {
		t.Fatal(err)
	}
	wanted := map[string]bool{"acl4ssr-online": true, "acl4ssr-full": true, "self-configuration": true}
	for _, scheme := range schemes {
		if !wanted[scheme.ID] {
			continue
		}
		t.Run(scheme.ID, func(t *testing.T) {
			lines := make(map[string][]string)
			var expectedProcessPredicates []string
			for _, rule := range scheme.Rules {
				if rule.Resource == nil {
					continue
				}
				if name := rules.LocalRuleFilename(rule.Resource.URL); name != "" {
					if data, readErr := os.ReadFile(filepath.Join("../../files/rules", name)); readErr == nil {
						lines[rule.Resource.URL] = strings.Split(string(data), "\n")
						payload, payloadErr := resourceLines(*rule.Resource, lines[rule.Resource.URL])
						if payloadErr != nil {
							t.Fatalf("read bundled resource %s: %v", name, payloadErr)
						}
						for _, line := range payload {
							if strings.HasPrefix(strings.ToUpper(strings.TrimSpace(line)), "PROCESS-NAME,") {
								predicate, ruleErr := daeRule(line, "fixture_target")
								if ruleErr != nil {
									t.Fatalf("lower bundled %s process rule: %v", name, ruleErr)
								}
								expectedProcessPredicates = append(expectedProcessPredicates, strings.TrimSuffix(predicate, " -> fixture_target"))
							}
						}
						continue
					}
				}
				if strings.EqualFold(rule.Resource.Format, "yaml") {
					lines[rule.Resource.URL] = []string{"payload:", "  - DOMAIN-SUFFIX,fixture.example"}
				} else {
					lines[rule.Resource.URL] = []string{"DOMAIN-SUFFIX,fixture.example", "URL-REGEX,^https?://fixture\\.example/path"}
				}
			}
			opts := Options{Target: model.ClientDAE, Nodes: kenzok8Nodes(), Scheme: scheme, RuleSetLines: lines, Strict: true}
			preflight := DAEPreflight(opts)
			if preflight.Status != PreflightExact || preflight.PlanDigest == "" || preflight.TargetPolicy != "tower-dae-acl-policy-v2" || !strings.Contains(preflight.PolicyNote, "URL-REGEX") {
				codes := make([]string, 0, len(preflight.Issues))
				for _, issue := range preflight.Issues {
					codes = append(codes, issue.Code+":"+issue.Location+":"+issue.Message)
				}
				t.Fatalf("DAE preflight = %s, policy=%q, issues=%v", preflight.Status, preflight.TargetPolicy, codes)
			}
			opts.PlanDigest = preflight.PlanDigest
			out, err := GenerateDAE(opts)
			if err != nil {
				t.Fatal(err)
			}
			if strings.Contains(out, "URL-REGEX") || !strings.Contains(out, "routing {") || !strings.Contains(out, "fallback:") {
				t.Fatalf("DAE target policy output omitted routing structure or leaked URL-REGEX")
			}
			lastProcessOffset := -1
			for _, predicate := range expectedProcessPredicates {
				offset := strings.Index(out, predicate)
				if offset <= lastProcessOffset {
					t.Fatalf("bundled PROCESS-NAME lowering missing or reordered at %q", predicate)
				}
				lastProcessOffset = offset
			}
		})
	}
}

func TestDAEBundledPoliciesAgainstFetchedRuleSources(t *testing.T) {
	manifestPath := os.Getenv("TOWER_RULE_SOURCE_MANIFEST")
	if manifestPath == "" {
		t.Skip("set TOWER_RULE_SOURCE_MANIFEST to run the fetched public-source matrix")
	}
	manifestData, err := os.ReadFile(manifestPath)
	if err != nil {
		t.Fatal(err)
	}
	var manifest []struct {
		URL  string `json:"url"`
		Path string `json:"path"`
	}
	if err := json.Unmarshal(manifestData, &manifest); err != nil {
		t.Fatal(err)
	}
	sourceLines := make(map[string][]string, len(manifest))
	for _, source := range manifest {
		data, err := os.ReadFile(source.Path)
		if err != nil {
			t.Fatalf("read fetched public source %s: %v", source.URL, err)
		}
		sourceLines[source.URL] = strings.Split(string(data), "\n")
	}

	schemes, err := rules.LoadBundled("../../files/rules")
	if err != nil {
		t.Fatal(err)
	}
	wanted := map[string]bool{"acl4ssr-online": true, "acl4ssr-full": true, "self-configuration": true}
	for i := range schemes {
		scheme := schemes[i]
		if !wanted[scheme.ID] {
			continue
		}
		for _, target := range []model.ClientTarget{model.ClientSingBox, model.ClientDAE} {
			t.Run(scheme.ID+"/"+string(target), func(t *testing.T) {
				lines := make(map[string][]string)
				for _, rule := range scheme.Rules {
					if rule.Resource == nil {
						continue
					}
					if cached, ok := sourceLines[rule.Resource.URL]; ok {
						lines[rule.Resource.URL] = cached
						continue
					}
					if name := rules.LocalRuleFilename(rule.Resource.URL); name != "" {
						data, readErr := os.ReadFile(filepath.Join("../../files/rules", name))
						if readErr == nil {
							lines[rule.Resource.URL] = strings.Split(string(data), "\n")
							continue
						}
					}
					t.Fatalf("no fetched or bundled source for public ruleset %s", rule.Resource.URL)
				}
				opts := Options{
					Target: target, Nodes: kenzok8Nodes(), Scheme: scheme, RuleSetLines: lines,
					PreferRuleSets: true, Strict: true,
					ServiceRegions: map[string]string{"claude": "sg", "openai": "hk", "gemini": "jp", "netflix": "tw"},
				}
				preflight := Preflight(opts)
				if target.Family() == model.FamilyDAE {
					preflight = DAEPreflight(opts)
				}
				if preflight.Status != PreflightExact || preflight.PlanDigest == "" {
					codes := make([]string, 0, len(preflight.Issues)+len(preflight.Warnings))
					for _, issue := range preflight.Issues {
						codes = append(codes, issue.Code+"@"+issue.Location+":"+issue.Message)
					}
					for _, warning := range preflight.Warnings {
						codes = append(codes, warning.Code+"@"+warning.Location)
					}
					t.Fatalf("real-source preflight=%s issues=%v", preflight.Status, codes)
				}
				opts.PlanDigest = preflight.PlanDigest
				content, err := Generate(opts)
				if err != nil {
					t.Fatal(err)
				}
				t.Logf("exact export: bytes=%d planned=%d resources=%d sha256=%x", len(content), len(preflight.Planned), len(lines), sha256.Sum256([]byte(content)))
			})
		}
	}
}

func TestGenerateSingBox(t *testing.T) {
	out, err := Generate(Options{Target: model.ClientSingBox, Nodes: sampleNodes()})
	if err != nil {
		t.Fatal(err)
	}
	var doc map[string]any
	if err := json.Unmarshal([]byte(out), &doc); err != nil {
		t.Fatalf("sing-box output is not valid JSON: %v\n%s", err, out)
	}
	ob, ok := doc["outbounds"].([]any)
	if !ok {
		t.Fatalf("outbounds missing: %v", doc["outbounds"])
	}
	// 3 nodes + selector + urltest + direct = 6
	if len(ob) != 6 {
		t.Errorf("want 6 outbounds, got %d", len(ob))
	}
}

func TestMomoSingBoxDNSIsHijackedBeforeSchemeRules(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{
			Name: "Proxy", Kind: model.KindSelect,
			Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}},
		}},
		Rules: []model.RuleSchemeRule{
			{Group: "Proxy", Body: "DOMAIN,example.com"},
			{Group: "Proxy", Final: true},
		},
	}

	for _, target := range []model.ClientTarget{model.ClientMomo, model.ClientSingBox, model.ClientClashooSB} {
		out, err := Generate(Options{Target: target, Nodes: sampleNodes(), Scheme: scheme})
		if err != nil {
			t.Fatalf("Generate(%s): %v", target, err)
		}
		var config map[string]any
		if err := json.Unmarshal([]byte(out), &config); err != nil {
			t.Fatalf("Generate(%s) emitted invalid JSON: %v", target, err)
		}

		route := config["route"].(map[string]any)
		rules, _ := route["rules"].([]any)
		if target != model.ClientMomo {
			if config["dns"] != nil {
				t.Errorf("Generate(%s) unexpectedly added Momo DNS config: %#v", target, config["dns"])
			}
			if route["default_domain_resolver"] != nil {
				t.Errorf("Generate(%s) unexpectedly added a Momo DNS resolver: %v", target, route["default_domain_resolver"])
			}
			for _, raw := range rules {
				if raw.(map[string]any)["action"] == "hijack-dns" {
					t.Errorf("Generate(%s) unexpectedly added Momo DNS hijacking", target)
				}
			}
			continue
		}

		dns, ok := config["dns"].(map[string]any)
		if !ok {
			t.Fatal("Momo export omitted its DNS configuration")
		}
		if dns["final"] != "tower-dns-direct" {
			t.Fatalf("Momo DNS final = %v, want tower-dns-direct", dns["final"])
		}
		if route["default_domain_resolver"] != "tower-dns-direct" {
			t.Fatalf("Momo default domain resolver = %v, want tower-dns-direct", route["default_domain_resolver"])
		}
		servers := dns["servers"].([]any)
		if len(servers) != 1 {
			t.Fatalf("Momo DNS servers = %#v, want one direct server", servers)
		}
		server := servers[0].(map[string]any)
		if server["type"] != "udp" || server["tag"] != "tower-dns-direct" || server["server"] != "223.5.5.5" || server["server_port"] != float64(53) || server["detour"] != singBoxDirectTag {
			t.Fatalf("Momo DNS server = %#v", server)
		}
		if len(rules) < 2 {
			t.Fatalf("Momo route rules = %#v, want DNS hijack and scheme rules", rules)
		}
		firstRule := rules[0].(map[string]any)
		if firstRule["action"] != "hijack-dns" || !reflect.DeepEqual(firstRule["inbound"], []any{"dns-in"}) {
			t.Fatalf("first Momo route rule = %#v, want dns-in hijack-dns", firstRule)
		}
		foundSchemeRule := false
		for _, raw := range rules[1:] {
			if domains, ok := raw.(map[string]any)["domain"].([]any); ok && len(domains) > 0 && domains[0] == "example.com" {
				foundSchemeRule = true
				break
			}
		}
		if !foundSchemeRule {
			t.Fatalf("Momo DNS rule displaced the scheme rule: %#v", rules)
		}
	}
}

func TestGenerateSurge(t *testing.T) {
	out, err := Generate(Options{Target: model.ClientSurge, Nodes: sampleNodes()})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "[Proxy]") || !strings.Contains(out, "[Proxy Group]") || !strings.Contains(out, "[Rule]") {
		t.Errorf("surge output missing sections:\n%s", out)
	}
	if !strings.Contains(out, "香港 01 = ss,") {
		t.Errorf("surge output missing ss node:\n%s", out)
	}
}

func TestNotImplemented(t *testing.T) {
	_, err := Generate(Options{Target: model.ClientLoon, Nodes: sampleNodes()})
	if err == nil {
		t.Error("loon should not be implemented yet")
	}
}

func TestGenerateWithScheme(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{
			{
				Name: "手动选择", IconURL: "https://cdn.simpleicons.org/github", Kind: model.KindSelect,
				Members: []model.RuleGroupMember{
					{Type: model.MemberReference, Value: "自动选择"},
					{Type: model.MemberReference, Value: "DIRECT"},
					{Type: model.MemberNodePattern, Value: ".*"},
				},
			},
			{
				Name: "自动选择", IconURL: "https://cdn.simpleicons.org/google", Kind: model.KindURLTest,
				URL: "http://www.gstatic.com/generate_204", Interval: 300, Tolerance: 50,
				Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}},
			},
		},
		Rules: []model.RuleSchemeRule{
			{Group: "手动选择", Body: "DOMAIN-SUFFIX,google.com"},
			{Group: "DIRECT", Body: "GEOIP,CN"},
			{Group: "手动选择", Final: true},
		},
	}

	out, err := Generate(Options{Target: model.ClientClashVerge, Nodes: sampleNodes(), Scheme: scheme})
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"- name: \"手动选择\"", "icon: \"https://cdn.simpleicons.org/github\"", "- name: \"自动选择\"", "icon: \"https://cdn.simpleicons.org/google\"", "DOMAIN-SUFFIX,google.com,手动选择", "GEOIP,CN,DIRECT", "MATCH,手动选择"} {
		if !strings.Contains(out, want) {
			t.Errorf("clash scheme output missing %q:\n%s", want, out)
		}
	}
	// The .* node pattern must expand to the available node names.
	for _, n := range []string{"香港 01", "日本 02", "美国 03"} {
		if !strings.Contains(out, n) {
			t.Errorf("node pattern not expanded to %q:\n%s", n, out)
		}
	}

	// Surge path.
	surge, err := Generate(Options{Target: model.ClientSurge, Nodes: sampleNodes(), Scheme: scheme})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(surge, "手动选择 = select") || !strings.Contains(surge, "自动选择 = url-test") {
		t.Errorf("surge scheme groups wrong:\n%s", surge)
	}
	if !strings.Contains(surge, "icon-url=https://cdn.simpleicons.org/github") || !strings.Contains(surge, "icon-url=https://cdn.simpleicons.org/google") {
		t.Errorf("surge scheme icons missing:\n%s", surge)
	}
	if !strings.Contains(surge, "DOMAIN-SUFFIX,google.com,手动选择") || !strings.Contains(surge, "FINAL,手动选择") {
		t.Errorf("surge scheme rules wrong:\n%s", surge)
	}
}

func TestRuleOptionsFollowPolicy(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "节点选择", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules:  []model.RuleSchemeRule{{Group: "节点选择", Body: "IP-CIDR,10.0.0.0/8,no-resolve"}},
	}
	for _, target := range []model.ClientTarget{model.ClientClashVerge, model.ClientSurge} {
		out, err := Generate(Options{Target: target, Nodes: sampleNodes(), Scheme: scheme})
		if err != nil {
			t.Fatal(err)
		}
		want := "IP-CIDR,10.0.0.0/8,节点选择,no-resolve"
		if target.Family() == model.FamilySurge {
			want = "IP-CIDR,10.0.0.0/8,节点选择,no-resolve"
		}
		if !strings.Contains(out, want) {
			t.Fatalf("%s output does not keep policy before no-resolve:\n%s", target, out)
		}
	}
}

func TestDomainRuleSetNormalizesMihomoDomainPrefixes(t *testing.T) {
	resource := model.RuleSchemeRuleSet{Behavior: "domain"}
	for input, want := range map[string]string{
		"+.example.com": "DOMAIN-SUFFIX,example.com",
		".example.net":  "DOMAIN-SUFFIX,example.net",
		"example.org":   "DOMAIN-SUFFIX,example.org",
	} {
		if got, _ := normalizeResourceLine(resource, input); got != want {
			t.Errorf("normalizeResourceLine(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestRuleSetNativeAndInlinePlans(t *testing.T) {
	url := "https://example.com/rules.list"
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "节点选择", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules:  []model.RuleSchemeRule{{Group: "节点选择", Options: []string{"no-resolve"}, Resource: &model.RuleSchemeRuleSet{URL: url, Tag: "remote", Behavior: "classical", Format: "text"}}},
	}
	clash, err := Generate(Options{Target: model.ClientClashVerge, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true})
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"rule-providers:", "type: http", "url: \"" + url + "\"", "RULE-SET,remote,节点选择,no-resolve"} {
		if !strings.Contains(clash, want) {
			t.Fatalf("native Clash output missing %q:\n%s", want, clash)
		}
	}
	surge, err := Generate(Options{Target: model.ClientSurge, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(surge, "RULE-SET,"+url+",节点选择,no-resolve") {
		t.Fatalf("native Surge output missing rule-set:\n%s", surge)
	}

	inline, err := Generate(Options{Target: model.ClientSurge, Nodes: sampleNodes(), Scheme: scheme, RuleSetLines: map[string][]string{url: {"IP-CIDR,10.0.0.0/8,no-resolve"}}})
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(inline, "RULE-SET,") || !strings.Contains(inline, "IP-CIDR,10.0.0.0/8,节点选择,no-resolve") {
		t.Fatalf("inline fallback did not preserve rule order:\n%s", inline)
	}
}

func TestSingBoxScheme(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{
			{
				Name: "手动选择", Kind: model.KindSelect,
				Members: []model.RuleGroupMember{
					{Type: model.MemberReference, Value: "自动选择"},
					{Type: model.MemberReference, Value: "DIRECT"},
				},
			},
			{
				Name: "自动选择", Kind: model.KindURLTest,
				URL: "http://www.gstatic.com/generate_204", Interval: 300, Tolerance: 50,
				Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}},
			},
		},
		Rules: []model.RuleSchemeRule{
			{Group: "手动选择", Body: "DOMAIN-SUFFIX,google.com"},
			{Group: "DIRECT", Body: "IP-CIDR,10.0.0.0/8"},
			{Group: "REJECT", Body: "DOMAIN-SUFFIX,ads.example"},
			{Group: "手动选择", Final: true},
		},
	}

	out, err := Generate(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme})
	if err != nil {
		t.Fatal(err)
	}
	var doc map[string]any
	if err := json.Unmarshal([]byte(out), &doc); err != nil {
		t.Fatalf("sing-box scheme output is not valid JSON: %v\n%s", err, out)
	}

	// 2 scheme groups + direct + 3 nodes = 6 outbounds.
	ob, _ := doc["outbounds"].([]any)
	if len(ob) != 6 {
		t.Fatalf("want 6 outbounds, got %d:\n%s", len(ob), out)
	}

	route, _ := doc["route"].(map[string]any)
	if route["final"] != "手动选择" {
		t.Errorf("route.final = %v, want 手动选择", route["final"])
	}
	rules, _ := route["rules"].([]any)
	if len(rules) == 0 {
		t.Fatalf("route.rules missing:\n%s", out)
	}

	var sawDomain, sawIP, sawReject bool
	for _, r := range rules {
		rm, _ := r.(map[string]any)
		if _, ok := rm["domain_suffix"]; ok {
			sawDomain = true
		}
		if _, ok := rm["ip_cidr"]; ok {
			sawIP = true
		}
		if rm["action"] == "reject" {
			sawReject = true
		}
	}
	if !sawDomain || !sawIP || !sawReject {
		t.Errorf("rules missing expected fields (domain=%v ip=%v reject=%v):\n%s", sawDomain, sawIP, sawReject, out)
	}
}

func TestSingBoxSchemeRulesKeepSourceOrder(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}, {Name: "B", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules:  []model.RuleSchemeRule{{Group: "A", Body: "DOMAIN,a.example"}, {Group: "B", Body: "DOMAIN,b.example"}, {Group: "A", Body: "DOMAIN,c.example"}, {Group: "A", Body: "DOMAIN-SUFFIX,example.net"}, {Group: "A", Final: true}},
	}
	out, err := Generate(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme})
	if err != nil {
		t.Fatal(err)
	}
	var config map[string]any
	if err := json.Unmarshal([]byte(out), &config); err != nil {
		t.Fatal(err)
	}
	route := config["route"].(map[string]any)
	rules := route["rules"].([]any)
	var got []string
	for _, raw := range rules {
		rule := raw.(map[string]any)
		for _, field := range []string{"domain", "domain_suffix"} {
			if values, ok := rule[field].([]any); ok {
				for _, value := range values {
					got = append(got, value.(string)+":"+rule["outbound"].(string))
				}
			}
		}
	}
	want := []string{"a.example:A", "b.example:B", "c.example:A", "example.net:A"}
	if strings.Join(got, ",") != strings.Join(want, ",") {
		t.Fatalf("route rule order = %v, want %v", got, want)
	}
}

func TestSingBoxPreflightRejectsUnsupportedRule(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules:  []model.RuleSchemeRule{{Group: "A", Body: "GEOIP,CN"}, {Group: "A", Final: true}},
	}
	result := Preflight(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme})
	if result.Status != PreflightUnsupported || len(result.Issues) == 0 {
		t.Fatalf("Preflight = %#v, want blocking unsupported result", result)
	}
	if _, err := Generate(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme}); err == nil {
		t.Fatal("Generate accepted unsupported GEOIP rule")
	}
}

func TestSingBoxMapsGeoIPCNToSameSourceSRS(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules:  []model.RuleSchemeRule{{Group: "A", Body: "GEOIP,CN"}, {Group: "A", Final: true}},
	}
	opts := Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true}
	result := Preflight(opts)
	if result.Status != PreflightDegraded || len(result.Warnings) != 1 || result.Warnings[0].Code != "geoip_cn" || result.PlanDigest == "" {
		t.Fatalf("Preflight = %#v, want GEOIP,CN degradation warning", result)
	}
	const wantURL = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/0a9e013b5bb8971992bc09ebfe1b889cd74d65d0/geo/geoip/cn.srs"
	var mapped bool
	for _, item := range result.Planned {
		if item.Kind == "resource" && item.SourceURL == singBoxGeoIPCNURL {
			mapped = item.URL == wantURL && item.Format == "binary" && item.SourceFormat == "mrs"
		}
	}
	if !mapped {
		t.Fatalf("Preflight plan omitted GEOIP,CN SRS mapping: %#v", result.Planned)
	}
	if _, err := Generate(opts); err == nil {
		t.Fatal("Generate accepted degraded plan without confirmation")
	}
	opts.PlanDigest = result.PlanDigest
	opts.AcceptedDegradations = []string{result.Warnings[0].ID}
	out, err := Generate(opts)
	if err != nil {
		t.Fatal(err)
	}
	var config map[string]any
	if err := json.Unmarshal([]byte(out), &config); err != nil {
		t.Fatal(err)
	}
	route := config["route"].(map[string]any)
	providers := route["rule_set"].([]any)
	if len(providers) != 1 || providers[0].(map[string]any)["url"] != wantURL {
		t.Fatalf("GEOIP,CN provider = %#v", providers)
	}
	rules := route["rules"].([]any)
	if len(rules) != 1 || rules[0].(map[string]any)["rule_set"].([]any)[0] != "tower-geoip-cn" {
		t.Fatalf("GEOIP,CN route rule = %#v", rules)
	}
	opts.PlanDigest = "stale"
	if _, err := Generate(opts); err == nil {
		t.Fatal("Generate accepted stale degraded-plan digest")
	}
}

func TestSingBoxRejectsURLRegexWithoutDomainOnlyApproximation(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "A", Body: "DOMAIN,first.example"},
			{Group: "A", Body: `URL-REGEX,^https?://example\\.test/path`},
			{Group: "A", Body: "DOMAIN,second.example"},
			{Group: "A", Final: true},
		},
	}
	result := Preflight(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme})
	if result.Status != PreflightDegraded || len(result.Warnings) != 1 || !strings.Contains(result.Warnings[0].Message, "不能等价转换") {
		t.Fatalf("URL-REGEX Preflight = %#v, want explicit omission warning", result)
	}
	opts := Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, PlanDigest: result.PlanDigest, AcceptedDegradations: []string{result.Warnings[0].ID}}
	out, err := Generate(opts)
	if err != nil {
		t.Fatal(err)
	}
	var config map[string]any
	if err := json.Unmarshal([]byte(out), &config); err != nil {
		t.Fatal(err)
	}
	rules := config["route"].(map[string]any)["rules"].([]any)
	if len(rules) != 2 || rules[0].(map[string]any)["domain"].([]any)[0] != "first.example" || rules[1].(map[string]any)["domain"].([]any)[0] != "second.example" {
		t.Fatalf("URL-REGEX omission changed remaining rule order/content: %#v", rules)
	}
}

func TestSingBoxDegradedBundledSchemesRequireExactAcknowledgement(t *testing.T) {
	bundled, err := rules.LoadBundled("../../files/rules")
	if err != nil {
		t.Fatal(err)
	}
	wantURLRegex := map[string]int{"acl4ssr-online": 1, "acl4ssr-full": 9, "self-configuration": 1}
	targets := []model.ClientTarget{model.ClientSingBox, model.ClientHiddify, model.ClientMomo, model.ClientClashooSB}
	for _, scheme := range bundled {
		if wantURLRegex[scheme.ID] == 0 {
			continue
		}
		t.Run(scheme.ID, func(t *testing.T) {
			lines := make(map[string][]string)
			for i, rule := range scheme.Rules {
				if rule.Resource == nil {
					continue
				}
				if localName := rules.LocalRuleFilename(rule.Resource.URL); localName != "" {
					data, err := os.ReadFile(filepath.Join("../../files/rules", localName))
					if err == nil {
						lines[rule.Resource.URL] = strings.Split(string(data), "\n")
						continue
					}
				}
				payload := "payload:\n  - DOMAIN-SUFFIX,fixture.example\n"
				if scheme.ID == "self-configuration" && i == 0 {
					payload += "  - URL-REGEX,^https?://fixture\\.example/path\n"
				}
				lines[rule.Resource.URL] = strings.Split(payload, "\n")
			}

			for _, target := range targets {
				nodes := append(kenzok8Nodes(), model.ProxyNode{Kind: model.KindShadowsocks, Name: "Netflix", Server: "stream.example", Port: 8388, Cipher: "aes-256-gcm", Password: "fixture"})
				opts := Options{Target: target, Nodes: nodes, Scheme: scheme, PreferRuleSets: true, RuleSetLines: lines}
				if target == model.ClientClashooSB {
					resource := model.RuleSchemeRuleSet{Tag: "tower-geoip-cn", URL: singBoxGeoIPCNURL, Behavior: "ipcidr", Format: "mrs"}
					inlineURL, ok := ClashooInlineSourceURL(resource)
					if !ok || inlineURL != "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/"+singBoxGeoIPCNRevision+"/geo/geoip/cn.json" {
						t.Fatalf("Clashoo GEOIP inline source = %q, %v", inlineURL, ok)
					}
					lines[singBoxGeoIPCNURL] = []string{`{"version":2,"rules":[{"ip_cidr":["1.2.3.0/24"]}]}`}
				}
				result := Preflight(opts)
				if result.Status != PreflightExact || len(result.Issues) != 0 {
					t.Fatalf("Preflight(%s) = status %q, issues %#v", target, result.Status, result.Issues)
				}
				if result.PlanDigest == "" || result.TargetPolicy != "tower-singbox-acl-policy-v2" || !strings.Contains(result.PolicyNote, "URL-REGEX") {
					t.Fatalf("Preflight(%s) omitted the digest or disclosed target policy: %#v", target, result)
				}
				counts := map[string]int{}
				for _, warning := range result.Warnings {
					counts[warning.Code]++
					if warning.Code == "url_regex" && !strings.Contains(warning.Message, scheme.Name) && !strings.Contains(warning.Message, ".list:") && !strings.Contains(warning.Message, ".yaml:") {
						t.Errorf("URL-REGEX warning lacks source file/line and scheme context: %#v", warning)
					}
				}
				if counts["geoip_cn"] != 0 || counts["reject_first"] != 0 || counts["url_regex"] != 0 {
					t.Fatalf("Preflight(%s) warning counts = %#v", target, counts)
				}
				opts.PlanDigest = result.PlanDigest
				opts.AcceptedDegradations = nil
				out, err := Generate(opts)
				if err != nil {
					t.Fatalf("Generate(%s): %v", target, err)
				}
				var config map[string]any
				if err := json.Unmarshal([]byte(out), &config); err != nil {
					t.Fatalf("Generate(%s) emitted invalid JSON: %v", target, err)
				}
				route := config["route"].(map[string]any)
				providers := route["rule_set"].([]any)
				foundCN := false
				for _, raw := range providers {
					provider := raw.(map[string]any)
					if provider["tag"] == "tower-geoip-cn" {
						foundCN = true
						if target == model.ClientClashooSB {
							if provider["type"] != "inline" || provider["url"] != nil {
								t.Fatalf("Clashoo emitted non-inline GEOIP provider: %#v", provider)
							}
						} else if provider["url"] != "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/"+singBoxGeoIPCNRevision+"/geo/geoip/cn.srs" {
							t.Fatalf("sing-box GEOIP provider did not use pinned SRS: %#v", provider)
						}
					}
				}
				if !foundCN {
					t.Fatalf("Generate(%s) omitted GEOIP rule_set", target)
				}
				for _, raw := range route["rules"].([]any) {
					if _, ok := raw.(map[string]any)["domain_regex"]; ok {
						t.Fatalf("Generate(%s) widened URL-REGEX into domain_regex: %#v", target, raw)
					}
				}
				outbounds := config["outbounds"].([]any)
				for _, group := range scheme.Groups {
					if len(group.Members) == 0 || group.Members[0].Type != model.MemberReference || !isSingBoxReject(group.Members[0].Value) {
						continue
					}
					foundBlock := false
					for _, raw := range outbounds {
						outbound := raw.(map[string]any)
						if outbound["tag"] == "REJECT" && outbound["type"] == "block" {
							foundBlock = true
						}
						if outbound["tag"] == group.Name {
							members := outbound["outbounds"].([]any)
							if members[0] != "REJECT" {
								t.Fatalf("selector %q lost its REJECT first choice: %#v", group.Name, members)
							}
						}
					}
					if !foundBlock {
						t.Fatalf("selector %q has no sing-box block outbound", group.Name)
					}
				}
			}
		})
	}
}

func TestSingBoxSelectorPreservesRejectDirectAndNodes(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "proxy", Kind: model.KindSelect, Members: []model.RuleGroupMember{
			{Type: model.MemberReference, Value: "REJECT"},
			{Type: model.MemberReference, Value: "DIRECT"},
			{Type: model.MemberNodePattern, Value: ".*"},
		}}},
		Rules: []model.RuleSchemeRule{{Group: "proxy", Body: "DOMAIN,example.test"}, {Group: "proxy", Final: true}},
	}
	result := Preflight(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, Strict: true})
	if result.Status != PreflightExact || len(result.Warnings) != 0 {
		t.Fatalf("Preflight = %#v, want exact selector preservation", result)
	}
	out, err := Generate(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, Strict: true, PlanDigest: result.PlanDigest})
	if err != nil {
		t.Fatal(err)
	}
	var config map[string]any
	if err := json.Unmarshal([]byte(out), &config); err != nil {
		t.Fatal(err)
	}
	var selector []any
	foundBlock := false
	for _, raw := range config["outbounds"].([]any) {
		outbound := raw.(map[string]any)
		switch outbound["tag"] {
		case "proxy":
			selector = outbound["outbounds"].([]any)
		case "REJECT":
			foundBlock = outbound["type"] == "block"
		}
	}
	if !reflect.DeepEqual(selector[:2], []any{"REJECT", "DIRECT"}) || !foundBlock {
		t.Fatalf("selector = %#v, block outbound = %t", selector, foundBlock)
	}
}

func TestSingBoxPreflightRejectsLossySchemeFeatures(t *testing.T) {
	base := func() *model.RuleScheme {
		return &model.RuleScheme{
			Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
			Rules:  []model.RuleSchemeRule{{Group: "A", Body: "DOMAIN,example.test"}, {Group: "A", Final: true}},
		}
	}
	tests := []struct {
		name   string
		change func(*model.RuleScheme)
	}{
		{"unsupported group kind", func(s *model.RuleScheme) { s.Groups[0].Kind = model.KindFallback }},
		{"invalid node regex", func(s *model.RuleScheme) { s.Groups[0].Members[0].Value = "[" }},
		{"unknown group reference", func(s *model.RuleScheme) {
			s.Groups[0].Members = []model.RuleGroupMember{{Type: model.MemberReference, Value: "missing"}}
		}},
		{"empty rule value", func(s *model.RuleScheme) { s.Rules[0].Body = "DOMAIN," }},
		{"unsupported rule option", func(s *model.RuleScheme) { s.Rules[0].Options = []string{"no-resolve"} }},
		{"missing MATCH", func(s *model.RuleScheme) { s.Rules = s.Rules[:1] }},
		{"non-final MATCH", func(s *model.RuleScheme) {
			s.Rules = append([]model.RuleSchemeRule{{Group: "A", Final: true}}, s.Rules...)
		}},
		{"ignored network settings", func(s *model.RuleScheme) {
			value := true
			s.NetworkSettings = &model.RuleSchemeNetworkSettings{IPv6Enabled: &value}
		}},
		{"builtin tag collision", func(s *model.RuleScheme) { s.Groups[0].Name = "DIRECT" }},
		{"empty group", func(s *model.RuleScheme) { s.Groups[0].Members = nil }},
		{"cyclic groups", func(s *model.RuleScheme) {
			s.Groups = []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberReference, Value: "B"}}}, {Name: "B", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberReference, Value: "A"}}}}
		}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			scheme := base()
			tt.change(scheme)
			result := Preflight(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme})
			if result.Status != PreflightUnsupported || len(result.Issues) == 0 {
				t.Fatalf("Preflight = %#v, want a blocking issue", result)
			}
		})
	}
}

func TestSingBoxRulesKeepInlineNativeAndExpandedResourceOrder(t *testing.T) {
	nativeURL := "https://example.test/native.json"
	textURL := "https://example.test/rules.txt"
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "A", Body: "DOMAIN,before.test"},
			{Group: "A", Resource: &model.RuleSchemeRuleSet{Tag: "native", URL: nativeURL, Format: "json", Behavior: "classical"}},
			{Group: "A", Resource: &model.RuleSchemeRuleSet{URL: textURL, Format: "text", Behavior: "classical"}},
			{Group: "A", Body: "DOMAIN,after.test"},
			{Group: "A", Final: true},
		},
	}
	cache := map[string][]string{
		nativeURL: {`{"version":1,"rules":[{"domain":["native.test"]}]}`},
		textURL:   {"DOMAIN,first.test", "DOMAIN,second.test"},
	}
	out, err := Generate(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: cache})
	if err != nil {
		t.Fatal(err)
	}
	var config map[string]any
	if err := json.Unmarshal([]byte(out), &config); err != nil {
		t.Fatal(err)
	}
	route := config["route"].(map[string]any)
	rules := route["rules"].([]any)
	var got []string
	for _, raw := range rules {
		rule := raw.(map[string]any)
		if values, ok := rule["rule_set"].([]any); ok {
			got = append(got, "rule_set:"+values[0].(string))
			continue
		}
		got = append(got, rule["domain"].([]any)[0].(string))
	}
	want := []string{"before.test", "rule_set:native", "first.test", "second.test", "after.test"}
	if strings.Join(got, ",") != strings.Join(want, ",") {
		t.Fatalf("route rule order = %v, want %v", got, want)
	}
}

func TestSingBoxPreflightRejectsUnsupportedNodeProtocol(t *testing.T) {
	result := Preflight(Options{Target: model.ClientSingBox, Nodes: []model.ProxyNode{{Kind: model.KindUnknown, Name: "unknown"}}})
	if result.Status != PreflightUnsupported || len(result.Issues) == 0 {
		t.Fatalf("Preflight = %#v, want unsupported node protocol issue", result)
	}
}

func TestSingBoxPreflightRejectsRemovedShadowsocksR(t *testing.T) {
	node := model.ProxyNode{Kind: model.KindShadowsocksR, Name: "legacy", Server: "node.test", Port: 443}
	for _, target := range []model.ClientTarget{model.ClientSingBox, model.ClientClashooSB, model.ClientMomo} {
		result := Preflight(Options{Target: target, Nodes: []model.ProxyNode{node}})
		if result.Status != PreflightUnsupported || len(result.Issues) != 1 || result.Issues[0].Code != "node_protocol" {
			t.Fatalf("%s preflight = %#v, want one blocking protocol issue", target, result)
		}
		if _, err := Generate(Options{Target: target, Nodes: []model.ProxyNode{node}}); err == nil {
			t.Fatalf("%s exported removed ShadowsocksR protocol", target)
		}
	}
}

func TestSingBoxPreflightRejectsReservedAndDefaultNodeTags(t *testing.T) {
	tests := []struct {
		name string
		tag  string
	}{
		{"direct", "DIRECT"},
		{"reject", "REJECT"},
		{"default selector", selectGroupName},
		{"default urltest", autoGroupName},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := Preflight(Options{Target: model.ClientSingBox, Nodes: []model.ProxyNode{{Kind: model.KindShadowsocks, Name: tt.tag, Server: "node.test", Port: 443}}})
			if result.Status != PreflightUnsupported || len(result.Issues) == 0 {
				t.Fatalf("Preflight accepted colliding node tag %q: %#v", tt.tag, result)
			}
			if result.Issues[0].Severity != "blocking" || result.Issues[0].Location != "nodes[0].tag" {
				t.Fatalf("issue metadata = %#v, want blocking nodes[0].tag", result.Issues[0])
			}
		})
	}
}

func TestSingBoxPreflightPlanItemsHaveStableOrderAndLocations(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules:  []model.RuleSchemeRule{{Group: "A", Body: "DOMAIN,example.test"}, {Group: "A", Final: true}},
	}
	result := Preflight(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme})
	if result.Status != PreflightExact {
		t.Fatalf("Preflight status = %q, issues = %#v", result.Status, result.Issues)
	}
	var locations []string
	for _, item := range result.Planned {
		locations = append(locations, item.Location)
	}
	want := []string{"nodes[0]", "nodes[1]", "nodes[2]", "groups[0]", "rules[0]", "rules[1]"}
	if strings.Join(locations, ",") != strings.Join(want, ",") {
		t.Fatalf("planned locations = %v, want %v", locations, want)
	}
}

func TestSingBoxPreflightRejectsInvalidNativeResource(t *testing.T) {
	url := "https://example.test/rules.json"
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "A", Resource: &model.RuleSchemeRuleSet{URL: url, Format: "json", Behavior: "classical"}},
			{Group: "A", Final: true},
		},
	}
	for _, cache := range []map[string][]string{
		nil,
		{url: {`{"version":2,"rules":[{"domain":["example.test"]}]}`}},
		{url: {`{"version":1,"rules":[]}`}},
		{url: {`{"version":1,"rules":[{"bogus":true}]}`}},
		{url: {`{"version":1,"rules":[{"domain":"example.test"}]}`}},
		{url: {`{"version":1,"rules":[{"domain_regex":["["]}]}`}},
	} {
		result := Preflight(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: cache})
		if result.Status != PreflightUnsupported || len(result.Issues) == 0 {
			t.Fatalf("Preflight accepted invalid/missing source cache: %#v", result)
		}
	}
}

func TestSingBoxPreflightAcceptsSupportedNativeSourceSubset(t *testing.T) {
	url := "https://example.test/rules.json"
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "A", Resource: &model.RuleSchemeRuleSet{URL: url, Format: "json", Behavior: "classical"}},
			{Group: "A", Final: true},
		},
	}
	cache := map[string][]string{url: {`{"version":1,"rules":[{"domain":["example.test"],"ip_cidr":["192.0.2.0/24"]},{"domain_regex":["^api\\.example\\.test$"]}]}`}}
	result := Preflight(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: cache})
	if result.Status != PreflightExact {
		t.Fatalf("supported source subset rejected: %#v", result.Issues)
	}
}

func TestSingBoxPreflightRejectsDifferentResourcesWithSameProviderID(t *testing.T) {
	firstURL := "https://example.test/first.json"
	secondURL := "https://example.test/second.json"
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "A", Resource: &model.RuleSchemeRuleSet{Tag: "Rule Set", URL: firstURL, Format: "json", Behavior: "classical"}},
			{Group: "A", Resource: &model.RuleSchemeRuleSet{Tag: "ruleset", URL: secondURL, Format: "json", Behavior: "classical"}},
			{Group: "A", Final: true},
		},
	}
	cache := map[string][]string{
		firstURL:  {`{"version":1,"rules":[{"domain":["first.test"]}]}`},
		secondURL: {`{"version":1,"rules":[{"domain":["second.test"]}]}`},
	}
	result := Preflight(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: cache})
	if result.Status != PreflightUnsupported || len(result.Issues) == 0 {
		t.Fatalf("Preflight accepted provider ID collision: %#v", result)
	}
	if _, err := Generate(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: cache}); err == nil {
		t.Fatal("Generate accepted provider ID collision")
	}
}

func TestSingBoxPlanDeduplicatesSameResourceURL(t *testing.T) {
	url := "https://example.test/rules.json"
	resource := &model.RuleSchemeRuleSet{Tag: "ruleset", URL: url, Format: "json", Behavior: "classical"}
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "A", Resource: resource},
			{Group: "A", Resource: resource},
			{Group: "A", Final: true},
		},
	}
	opts := Options{
		Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true,
		RuleSetLines: map[string][]string{url: {`{"version":1,"rules":[{"domain":["example.test"]}]}`}},
	}
	plan, providers, err := planSchemeRules(opts)
	if err != nil {
		t.Fatal(err)
	}
	if len(plan) != 3 || len(providers) != 1 {
		t.Fatalf("planned rules/providers = %d/%d, want 3/1", len(plan), len(providers))
	}
	result := Preflight(opts)
	if result.Status != PreflightExact {
		t.Fatalf("same-resource duplicate was rejected: %#v", result.Issues)
	}
}

func TestSingBoxPreflightBlocksMRSWithoutMapping(t *testing.T) {
	url := "https://example.test/rules.mrs"
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "A", Resource: &model.RuleSchemeRuleSet{URL: url, Format: "mrs", Behavior: "classical"}},
			{Group: "A", Final: true},
		},
	}
	result := Preflight(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: map[string][]string{url: {"opaque"}}})
	if result.Status != PreflightUnsupported {
		t.Fatalf("MRS without a mapping was accepted: %#v", result)
	}
}

func TestSingBoxMRSMappingAllowlist(t *testing.T) {
	base := "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo"
	tests := []struct {
		path     string
		behavior string
	}{
		{"geosite/private", "domain"},
		{"geosite/openai", "domain"},
		{"geosite/anthropic", "domain"},
		{"geosite/google-gemini", "domain"},
		{"geosite/twitter", "domain"},
		{"geosite/youtube", "domain"},
		{"geosite/google", "domain"},
		{"geosite/github", "domain"},
		{"geosite/netflix", "domain"},
		{"geosite/paypal", "domain"},
		{"geosite/onedrive", "domain"},
		{"geosite/microsoft", "domain"},
		{"geosite/apple-cn", "domain"},
		{"geosite/tiktok", "domain"},
		{"geosite/gfw", "domain"},
		{"geosite/geolocation-!cn", "domain"},
		{"geosite/cn", "domain"},
		{"geoip/cn", "ipcidr"},
		{"geoip/google", "ipcidr"},
		{"geoip/netflix", "ipcidr"},
	}
	for _, tt := range tests {
		t.Run(tt.path, func(t *testing.T) {
			resource := model.RuleSchemeRuleSet{URL: base + "/" + tt.path + ".mrs", Format: "mrs", Behavior: tt.behavior}
			got, _, ok := mapSingBoxMRS(resource)
			want := "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/refs/heads/sing/geo/" + tt.path + ".srs"
			if !ok || got != want {
				t.Fatalf("mapSingBoxMRS(%#v) = %q, %v; want %q, true", resource, got, ok, want)
			}
		})
	}
	unsafe := []model.RuleSchemeRuleSet{
		{URL: base + "/geosite/openai.mrs?mirror=1", Format: "mrs", Behavior: "domain"},
		{URL: base + "/geosite/openai.mrs#", Format: "mrs", Behavior: "domain"},
		{URL: "https://user@raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/openai.mrs", Format: "mrs", Behavior: "domain"},
		{URL: "https://github.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/openai.mrs", Format: "mrs", Behavior: "domain"},
		{URL: "https://raw.githubusercontent.com/Other/meta-rules-dat/meta/geo/geosite/openai.mrs", Format: "mrs", Behavior: "domain"},
		{URL: strings.Replace(base, "/meta/", "/main/", 1) + "/geosite/openai.mrs", Format: "mrs", Behavior: "domain"},
		{URL: base + "/geosite/custom.mrs", Format: "mrs", Behavior: "domain"},
		{URL: base + "/geoip/google.mrs", Format: "mrs", Behavior: "domain"},
	}
	for _, resource := range unsafe {
		if _, _, ok := mapSingBoxMRS(resource); ok {
			t.Fatalf("unsafe resource was mapped: %#v", resource)
		}
	}
}

func TestSingBoxMRSMappingUsesBinaryRemoteRuleSets(t *testing.T) {
	domainURL := "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/openai.mrs"
	ipURL := "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/netflix.mrs"
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "A", Resource: &model.RuleSchemeRuleSet{Tag: "openai", URL: domainURL, Format: "mrs", Behavior: "domain"}},
			{Group: "A", Resource: &model.RuleSchemeRuleSet{Tag: "netflix-ip", URL: ipURL, Format: "mrs", Behavior: "ipcidr"}, Options: []string{"no-resolve"}},
			{Group: "A", Body: "DOMAIN,after.test"},
			{Group: "A", Final: true},
		},
	}
	var result PreflightResult
	for _, target := range []model.ClientTarget{model.ClientSingBox, model.ClientHiddify, model.ClientMomo} {
		result = Preflight(Options{Target: target, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true})
		if result.Status != PreflightExact {
			t.Fatalf("MRS mapping preflight for %s failed: %#v", target, result.Issues)
		}
	}
	var sawMappedResource bool
	for _, item := range result.Planned {
		if item.Kind == "resource" && item.SourceURL == domainURL {
			sawMappedResource = item.URL == "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/refs/heads/sing/geo/geosite/openai.srs" && item.Format == "binary" && item.SourceFormat == "mrs" && strings.Contains(item.MappingReason, "动态更新")
			if !sawMappedResource || item.Author != "MetaCubeX" || item.License != "GPL-3.0" {
				t.Fatalf("Preflight mapping metadata = %#v", item)
			}
		}
	}
	if !sawMappedResource {
		t.Fatal("Preflight did not report mapped URL, source URL, and same-category limitation")
	}
	out, err := Generate(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true})
	if err != nil {
		t.Fatal(err)
	}
	var config map[string]any
	if err := json.Unmarshal([]byte(out), &config); err != nil {
		t.Fatal(err)
	}
	experimental := config["experimental"].(map[string]any)
	if experimental["cache_file"].(map[string]any)["enabled"] != true {
		t.Fatal("remote rule sets must enable cache_file")
	}
	route := config["route"].(map[string]any)
	providers := route["rule_set"].([]any)
	if len(providers) != 2 {
		t.Fatalf("provider count = %d, want 2", len(providers))
	}
	for _, raw := range providers {
		provider := raw.(map[string]any)
		if provider["format"] != "binary" || strings.Contains(provider["url"].(string), ".mrs") {
			t.Fatalf("unexpected provider mapping: %#v", provider)
		}
		if provider["download_detour"] != "DIRECT" {
			t.Fatalf("remote provider must use DIRECT to bootstrap downloads: %#v", provider)
		}
	}
	rules := route["rules"].([]any)
	var got []string
	for _, raw := range rules {
		rule := raw.(map[string]any)
		if values, ok := rule["rule_set"].([]any); ok {
			got = append(got, values[0].(string))
		} else if values, ok := rule["domain"].([]any); ok {
			got = append(got, values[0].(string))
		}
	}
	if strings.Join(got, ",") != "openai,netflix-ip,after.test" {
		t.Fatalf("route rule order = %v", got)
	}
}

func TestSurgeFamilyExpandsMappedMRSInOrder(t *testing.T) {
	domainURL := "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/private.mrs"
	ipURL := "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/cn.mrs"
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "Proxy", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberReference, Value: "DIRECT"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "Proxy", Body: "DOMAIN,before.test"},
			{Group: "Proxy", Resource: &model.RuleSchemeRuleSet{Tag: "private", URL: domainURL, Format: "mrs", Behavior: "domain"}},
			{Group: "Proxy", Resource: &model.RuleSchemeRuleSet{Tag: "cn", URL: ipURL, Format: "mrs", Behavior: "ipcidr"}},
			{Group: "Proxy", Body: "DOMAIN,after.test"},
			{Group: "Proxy", Final: true},
		},
	}
	cache := map[string][]string{
		domainURL: {"binary MRS fixture"},
		ipURL:     {"binary MRS fixture"},
		strings.TrimSuffix(domainURL, ".mrs") + ".yaml": {"payload:", "  - exact.test", "  - +.suffix.test"},
		strings.TrimSuffix(ipURL, ".mrs") + ".yaml":     {"payload:", "  - 203.0.113.0/24", "  - 2001:db8::/32"},
	}
	for _, target := range []model.ClientTarget{model.ClientShadowrocket, model.ClientSurge, model.ClientSurgeMac} {
		out, err := Generate(Options{Target: target, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: cache})
		if err != nil {
			t.Fatalf("%s export: %v", target, err)
		}
		finalRule := "MATCH,Proxy"
		if target.Family() == model.FamilySurge {
			finalRule = "FINAL,Proxy"
		}
		parts := []string{"DOMAIN,before.test,Proxy", "DOMAIN,exact.test,Proxy", "DOMAIN-SUFFIX,suffix.test,Proxy", "IP-CIDR,203.0.113.0/24,Proxy", "IP-CIDR6,2001:db8::/32,Proxy", "DOMAIN,after.test,Proxy", finalRule}
		previous := -1
		for _, part := range parts {
			index := strings.Index(out, part)
			if index <= previous {
				t.Fatalf("%s rule %q missing or out of order:\n%s", target, part, out)
			}
			previous = index
		}
		if strings.Contains(out, ".mrs") || strings.Contains(out, "payload:") {
			t.Fatalf("%s output contains an unconverted MRS/YAML source", target)
		}
	}
}

func TestMappedMRSYAMLRejectsUnsupportedEntries(t *testing.T) {
	resource := model.RuleSchemeRuleSet{
		URL:    "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/private.mrs",
		Format: "mrs", Behavior: "domain",
	}
	for _, payload := range []string{"payload:\n  - '*.example.test'\n", "payload:\n  - ''\n", "payload:\n  - regexp:example\n"} {
		if err := ValidateMRSYAMLSource(resource, []byte(payload)); err == nil {
			t.Fatalf("unsupported payload was accepted: %q", payload)
		}
	}
	resource.URL = "https://example.test/private.mrs"
	if _, ok := MRSYAMLSourceURL(resource); ok {
		t.Fatal("unrecognized MRS source was mapped")
	}
}

func TestKenzok8SchemeSurgeFamilyWithSyntheticMRS(t *testing.T) {
	data, err := os.ReadFile("../../files/rules/Kenzok8.yaml")
	if err != nil {
		t.Fatal(err)
	}
	scheme, err := rules.Parse(string(data), nil)
	if err != nil {
		t.Fatal(err)
	}
	cache := make(map[string][]string)
	for _, rule := range scheme.Rules {
		if rule.Resource == nil {
			continue
		}
		resource := *rule.Resource
		if sourceURL, mapped := MRSYAMLSourceURL(resource); mapped {
			value := "  - +.example.test"
			if resource.Behavior == "ipcidr" {
				value = "  - 203.0.113.0/24"
			}
			cache[sourceURL] = []string{"payload:", value}
		} else {
			cache[resource.URL] = []string{"DOMAIN,example.test"}
		}
	}
	for _, target := range []model.ClientTarget{model.ClientShadowrocket, model.ClientSurge, model.ClientSurgeMac} {
		out, err := Generate(Options{Target: target, Nodes: kenzok8Nodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: cache})
		if err != nil {
			t.Fatalf("%s Kenzok8 export: %v", target, err)
		}
		if strings.Contains(out, ".mrs") || !strings.Contains(out, "DOMAIN-SUFFIX,example.test,OpenAI") || !strings.Contains(out, "IP-CIDR,203.0.113.0/24,NETFLIX") {
			t.Fatalf("%s Kenzok8 MRS rules were not expanded correctly", target)
		}
	}
}

func TestKenzok8ReferencedMRSResourcesMapWithoutTextCache(t *testing.T) {
	data, err := os.ReadFile("../../files/rules/Kenzok8.yaml")
	if err != nil {
		t.Fatal(err)
	}
	scheme, err := rules.Parse(string(data), nil)
	if err != nil {
		t.Fatal(err)
	}
	var final model.RuleSchemeRule
	filtered := *scheme
	filtered.Rules = nil
	for _, rule := range scheme.Rules {
		if rule.Final {
			final = rule
			continue
		}
		if rule.Resource != nil && strings.EqualFold(rule.Resource.Format, "mrs") {
			filtered.Rules = append(filtered.Rules, rule)
		}
	}
	filtered.Rules = append(filtered.Rules, final)
	options := Options{Target: model.ClientSingBox, Nodes: kenzok8Nodes(), Scheme: &filtered, PreferRuleSets: true}
	result := Preflight(options)
	if result.Status != PreflightExact {
		t.Fatalf("Kenzok8 MRS subset preflight failed: %#v", result.Issues)
	}
	out, err := Generate(options)
	if err != nil {
		t.Fatal(err)
	}
	var config map[string]any
	if err := json.Unmarshal([]byte(out), &config); err != nil {
		t.Fatal(err)
	}
	route := config["route"].(map[string]any)
	providers := route["rule_set"].([]any)
	if len(providers) != 18 {
		t.Fatalf("mapped referenced providers = %d, want 18", len(providers))
	}
	for _, raw := range providers {
		if raw.(map[string]any)["format"] != "binary" {
			t.Fatalf("provider is not binary: %#v", raw)
		}
	}
}

func TestClashooSingBoxPreflightBlocksRemoteRuleSets(t *testing.T) {
	url := "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/openai.mrs"
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "A", Resource: &model.RuleSchemeRuleSet{Tag: "openai", URL: url, Format: "mrs", Behavior: "domain"}},
			{Group: "A", Final: true},
		},
	}
	missing := Preflight(Options{Target: model.ClientClashooSB, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true})
	if missing.Status != PreflightUnsupported {
		t.Fatalf("Clashoo sing-box accepted missing inline source cache: %#v", missing)
	}
	invalid := Preflight(Options{Target: model.ClientClashooSB, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: map[string][]string{url: {`{"bogus":true}`}}})
	if invalid.Status != PreflightUnsupported {
		t.Fatalf("Clashoo sing-box accepted invalid inline source cache: %#v", invalid)
	}
	lines := map[string][]string{url: {`{"version":2,"rules":[{"domain":["api.openai.com"]}]}`}}
	result := Preflight(Options{Target: model.ClientClashooSB, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: lines})
	if result.Status != PreflightExact {
		t.Fatalf("Clashoo sing-box inline MRS mapping failed: %#v", result.Issues)
	}
	out, err := Generate(Options{Target: model.ClientClashooSB, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: lines})
	if err != nil {
		t.Fatal(err)
	}
	var config map[string]any
	if err := json.Unmarshal([]byte(out), &config); err != nil {
		t.Fatal(err)
	}
	sets := config["route"].(map[string]any)["rule_set"].([]any)
	if len(sets) != 1 || sets[0].(map[string]any)["type"] != "inline" {
		t.Fatalf("Clashoo output contains a non-inline rule set: %#v", sets)
	}
	rules := sets[0].(map[string]any)["rules"].([]any)
	if len(rules) != 1 || rules[0].(map[string]any)["domain"].([]any)[0] != "api.openai.com" {
		t.Fatalf("unexpected embedded inline rules: %#v", rules)
	}
	sourceURL := "https://example.test/rules.json"
	scheme.Rules[0].Resource = &model.RuleSchemeRuleSet{Tag: "source", URL: sourceURL, Format: "json", Behavior: "classical"}
	result = Preflight(Options{Target: model.ClientClashooSB, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: map[string][]string{sourceURL: {`{"version":1,"rules":[{"domain":["example.test"]}]}`}}})
	if result.Status != PreflightUnsupported {
		t.Fatalf("Clashoo sing-box accepted native remote source set: %#v", result)
	}
}

func TestParseClashooInlineRuleSetStrictSubset(t *testing.T) {
	valid := []byte(`{"version":2,"rules":[{"domain":["example.test"],"domain_suffix":["example.org"]},{"ip_cidr":["192.0.2.0/24"]}]}`)
	rules, err := ParseClashooInlineRuleSet(valid)
	if err != nil || len(rules) != 2 || rules[0]["domain"][0] != "example.test" || rules[1]["ip_cidr"][0] != "192.0.2.0/24" {
		t.Fatalf("valid source parse = %#v, %v", rules, err)
	}
	for _, invalid := range []string{
		`{"version":1,"rules":[{"domain":["example.test"]}]}`,
		`{"version":2,"rules":[]}`,
		`{"version":2,"rules":[{"process_name":["browser"]}]}`,
		`{"version":2,"rules":[{"domain_regex":["["]}]}`,
		`{"version":2,"rules":[{"ip_cidr":["not-cidr"]}]}`,
		`{"version":2,"rules":[{"domain":["example.test"]}],"description":"extra"}`,
	} {
		if _, err := ParseClashooInlineRuleSet([]byte(invalid)); err == nil {
			t.Fatalf("invalid sing source was accepted: %s", invalid)
		}
	}
}

func TestClashooInlineSourceURLUsesCuratedRawBranch(t *testing.T) {
	resource := model.RuleSchemeRuleSet{URL: "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/openai.mrs", Format: "mrs", Behavior: "domain"}
	got, ok := ClashooInlineSourceURL(resource)
	want := "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/refs/heads/sing/geo/geosite/openai.json"
	if !ok || got != want {
		t.Fatalf("ClashooInlineSourceURL() = %q, %v; want %q, true", got, ok, want)
	}
}

func TestSingBoxMRSMappingRejectsUnsupportedOptions(t *testing.T) {
	url := "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/openai.mrs"
	for _, tt := range []struct {
		behavior string
		options  []string
	}{
		{"domain", []string{"no-resolve"}},
		{"ipcidr", []string{"no-resolve", "src"}},
		{"ipcidr", []string{"src"}},
	} {
		resourceURL := url
		if tt.behavior == "ipcidr" {
			resourceURL = "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/netflix.mrs"
		}
		scheme := &model.RuleScheme{
			Groups: []model.RuleSchemeGroup{{Name: "A", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}},
			Rules: []model.RuleSchemeRule{
				{Group: "A", Resource: &model.RuleSchemeRuleSet{URL: resourceURL, Format: "mrs", Behavior: tt.behavior}, Options: tt.options},
				{Group: "A", Final: true},
			},
		}
		result := Preflight(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme, PreferRuleSets: true})
		if result.Status != PreflightUnsupported {
			t.Fatalf("unsupported mapped-resource options accepted (%q, %v)", tt.behavior, tt.options)
		}
	}
}

func TestSchemeEmptyGroupIsError(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{{Name: "未匹配地区", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: "不存在"}}}},
		Rules:  []model.RuleSchemeRule{{Group: "未匹配地区", Final: true}},
	}
	if _, err := Generate(Options{Target: model.ClientClashVerge, Nodes: sampleNodes(), Scheme: scheme}); err == nil {
		t.Fatal("empty selected group must not fall back to DIRECT")
	}
}

func TestSchemePrunesUnmatchedOptionalRegion(t *testing.T) {
	scheme := &model.RuleScheme{
		Groups: []model.RuleSchemeGroup{
			{Name: "节点选择", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberReference, Value: "香港节点"}, {Type: model.MemberReference, Value: "日本节点"}}},
			{Name: "香港节点", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: "港|HK", Exclude: "日本"}}},
			{Name: "日本节点", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: "日|JP"}}},
		},
		Rules: []model.RuleSchemeRule{{Group: "节点选择", Final: true}},
	}
	out, err := Generate(Options{Target: model.ClientClashVerge, Nodes: sampleNodes()[:1], Scheme: scheme})
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(out, "日本节点") || !strings.Contains(out, "香港节点") {
		t.Fatalf("optional region pruning failed")
	}
	if len(scheme.Groups) != 3 || len(scheme.Groups[0].Members) != 2 {
		t.Fatal("export mutated stored scheme")
	}
}

func TestKenzok8ExampleExportsAllAndSelectedNodes(t *testing.T) {
	data, err := os.ReadFile("../../files/rules/Kenzok8.yaml")
	if err != nil {
		t.Fatal(err)
	}
	scheme, err := rules.Parse(string(data), nil)
	if err != nil {
		t.Fatal(err)
	}
	for _, nodes := range [][]model.ProxyNode{kenzok8Nodes(), sampleNodes()[:1]} {
		out, err := Generate(Options{Target: model.ClientClashVerge, Nodes: nodes, Scheme: scheme, PreferRuleSets: true})
		if err != nil {
			t.Fatal(err)
		}
		var config map[string]any
		if err := yamlv3.Unmarshal([]byte(out), &config); err != nil {
			t.Fatalf("invalid YAML: %v", err)
		}
		if !strings.Contains(out, "name: \"🇭🇰 香港节点\"") || !strings.Contains(out, "icon: \"https://cdn.simpleicons.org/github/24292F/FFFFFF\"") {
			t.Fatal("expected region and icon missing")
		}
		if len(nodes) == 1 && strings.Contains(out, "name: \"🇯🇵 日本节点\"") {
			t.Fatal("unmatched Japan group was not pruned")
		}
	}
}

func TestBundledSelfConfigurationExportsGroupsAndRemoteRules(t *testing.T) {
	schemes, err := rules.LoadBundled("../../files/rules")
	if err != nil {
		t.Fatal(err)
	}
	var scheme *model.RuleScheme
	for _, candidate := range schemes {
		if candidate.ID == "self-configuration" {
			scheme = candidate
			break
		}
	}
	if scheme == nil {
		t.Fatal("Self-Configuration scheme missing")
	}
	if len(scheme.Groups) != 27 || len(scheme.Rules) != 68 {
		t.Fatalf("scheme groups=%d rules=%d, want 27 and 68", len(scheme.Groups), len(scheme.Rules))
	}
	remoteCount := 0
	for _, rule := range scheme.Rules {
		if rule.Resource != nil {
			remoteCount++
			if rule.Resource.Format != "yaml" {
				t.Errorf("remote ruleset format = %q, want yaml", rule.Resource.Format)
			}
		}
	}
	if remoteCount != 66 {
		t.Fatalf("remote YAML rulesets = %d, want 66", remoteCount)
	}

	clash, err := Generate(Options{Target: model.ClientClashVerge, Nodes: kenzok8Nodes(), Scheme: scheme, PreferRuleSets: true})
	if err != nil {
		t.Fatal(err)
	}
	var config map[string]any
	if err := yamlv3.Unmarshal([]byte(clash), &config); err != nil {
		t.Fatalf("kenzok8 Clash output is invalid YAML: %v", err)
	}
	if len(config["rule-providers"].(map[string]any)) != 66 {
		t.Fatalf("Clash providers = %d, want 66", len(config["rule-providers"].(map[string]any)))
	}
	if !strings.Contains(clash, "name: \"🚀 节点选择\"") || !strings.Contains(clash, "name: \"🤖 AI服务\"") {
		t.Fatal("Clash output is missing imported kenzok8 strategy groups")
	}

	cache := make(map[string][]string, remoteCount)
	for _, rule := range scheme.Rules {
		if rule.Resource != nil {
			cache[rule.Resource.URL] = []string{"payload:", "  - DOMAIN-SUFFIX,example.test"}
		}
	}
	surge, err := Generate(Options{Target: model.ClientSurgeMac, Nodes: kenzok8Nodes(), Scheme: scheme, PreferRuleSets: true, RuleSetLines: cache})
	if err != nil {
		t.Fatalf("Surge export failed: %v", err)
	}
	if !strings.Contains(surge, "🚀 节点选择 = select") || !strings.Contains(surge, "DOMAIN-SUFFIX,example.test") {
		t.Fatal("Surge output is missing imported groups or expanded YAML provider rules")
	}
}

func TestStrictSingBoxExportRequiresTheCurrentExactPreflightDigest(t *testing.T) {
	node := model.ProxyNode{
		ID: "vless-1", Kind: model.KindVLESS, Name: "leaf", Server: "leaf.example", Port: 443,
		UUID: "12345678-1234-4321-8765-123456789abc", TLS: true, SNI: "leaf.example",
	}
	opts := Options{Target: model.ClientSingBox, Nodes: []model.ProxyNode{node}, Strict: true}
	preflight := Preflight(opts)
	if preflight.Status != PreflightExact || preflight.PlanDigest == "" {
		t.Fatalf("preflight = %#v, want exact plan with digest", preflight)
	}
	if _, err := Generate(opts); err == nil {
		t.Fatal("strict exact export accepted a missing preflight digest")
	}
	opts.PlanDigest = strings.Repeat("0", 64)
	if _, err := Generate(opts); err == nil {
		t.Fatal("strict exact export accepted a mismatched preflight digest")
	}
	opts.PlanDigest = preflight.PlanDigest
	if _, err := Generate(opts); err != nil {
		t.Fatalf("strict export rejected its matching exact preflight digest: %v", err)
	}
}

func TestStrictSingBoxDigestBindsToCachedResourceContents(t *testing.T) {
	node := model.ProxyNode{
		ID: "vless-1", Kind: model.KindVLESS, Name: "leaf", Server: "leaf.example", Port: 443,
		UUID: "12345678-1234-4321-8765-123456789abc", TLS: true, SNI: "leaf.example",
	}
	url := "https://rules.example/source.json"
	scheme := &model.RuleScheme{
		ID: "fixture", Groups: []model.RuleSchemeGroup{{Name: "Proxy", Kind: model.KindSelect, Members: []model.RuleGroupMember{{Type: model.MemberReference, Value: "DIRECT"}}}},
		Rules: []model.RuleSchemeRule{
			{Group: "Proxy", Resource: &model.RuleSchemeRuleSet{Tag: "fixture", URL: url, Format: "json", Behavior: "domain"}},
			{Group: "Proxy", Final: true},
		},
	}
	opts := Options{Target: model.ClientSingBox, Nodes: []model.ProxyNode{node}, Scheme: scheme, PreferRuleSets: true, Strict: true,
		RuleSetLines: map[string][]string{url: {`{"version":1,"rules":[{"domain":["first.example"]}]}`}},
	}
	preflight := Preflight(opts)
	if preflight.Status != PreflightExact || preflight.PlanDigest == "" {
		t.Fatalf("preflight = %#v, want exact plan with digest", preflight)
	}
	opts.PlanDigest = preflight.PlanDigest
	opts.RuleSetLines[url] = []string{`{"version":1,"rules":[{"domain":["changed.example"]}]}`}
	changed := Preflight(opts)
	if changed.Status != PreflightExact || changed.PlanDigest == "" || changed.PlanDigest == preflight.PlanDigest {
		t.Fatalf("changed-content preflight = %#v, want exact plan with a different digest", changed)
	}
	if _, err := Generate(opts); err == nil {
		t.Fatal("strict export accepted cached resource content changed after preflight")
	}
	opts.PlanDigest = changed.PlanDigest
	if _, err := Generate(opts); err != nil {
		t.Fatalf("strict export rejected the digest for its current resource contents: %v", err)
	}
}

func TestSingBoxCapabilitiesMatchTargetCoreProtocols(t *testing.T) {
	tests := []struct {
		target    model.ClientTarget
		kind      model.ProxyKind
		supported bool
	}{
		{model.ClientSingBox, model.KindSnell, false},
		{model.ClientHiddify, model.KindSnell, false},
		{model.ClientMomo, model.KindSnell, false},
		{model.ClientClashooSB, model.KindSnell, true},
		{model.ClientSingBox, model.KindWireGuard, false},
		{model.ClientHiddify, model.KindWireGuard, false},
		{model.ClientClashooSB, model.KindWireGuard, false},
		{model.ClientMomo, model.KindWireGuard, false},
	}

	for _, tt := range tests {
		node := model.ProxyNode{Kind: tt.kind, Name: "fixture", Server: "node.test", Port: 443, Password: "fixture"}
		if got := SupportsProtocol(tt.target, tt.kind); got != tt.supported {
			t.Errorf("SupportsProtocol(%s, %s) = %v, want %v", tt.target, tt.kind, got, tt.supported)
		}
		result := Preflight(Options{Target: tt.target, Nodes: []model.ProxyNode{node}})
		if tt.supported {
			if result.Status != PreflightExact {
				t.Errorf("Preflight(%s, %s) = %#v, want exact", tt.target, tt.kind, result)
			}
			continue
		}
		if result.Status != PreflightUnsupported || len(result.Issues) != 1 || result.Issues[0].Code != "node_protocol" {
			t.Errorf("Preflight(%s, %s) = %#v, want a blocking protocol issue", tt.target, tt.kind, result)
		}
		if _, err := Generate(Options{Target: tt.target, Nodes: []model.ProxyNode{node}}); err == nil {
			t.Errorf("Generate(%s, %s) accepted a protocol missing from the target core", tt.target, tt.kind)
		}
	}
}

func TestTargetCapabilitiesRejectUnknownProtocols(t *testing.T) {
	if SupportsProtocol(model.ClientSingBox, model.ProxyKind("future")) {
		t.Fatal("unknown protocol was advertised as supported by sing-box")
	}
	if !SupportsProtocol(model.ClientSingBox, model.KindVLESS) {
		t.Fatal("known sing-box protocol was not advertised")
	}
}

func TestDAEResourceLoweringPreservesExactSuffixAndNoResolveSemantics(t *testing.T) {
	full, err := daeRule("DOMAIN,example.com", "group_001")
	if err != nil || full != "domain(full: example.com) -> group_001" {
		t.Fatalf("DOMAIN lowering = %q, err=%v", full, err)
	}
	suffix, err := daeRule("DOMAIN-SUFFIX,example.com", "group_001")
	if err != nil || suffix != "domain(suffix: example.com) -> group_001" {
		t.Fatalf("DOMAIN-SUFFIX lowering = %q, err=%v", suffix, err)
	}
	resource := model.RuleSchemeRuleSet{URL: "https://rules.example/ip.list", Format: "text", Behavior: "classical"}
	if _, err := daeResourceBodies(resource, []string{"no-resolve"}, map[string][]string{resource.URL: {"IP-CIDR,192.0.2.0/24"}}); err != nil {
		t.Fatalf("IP-CIDR no-resolve lowering failed: %v", err)
	}
	if _, err := daeResourceBodies(resource, []string{"no-resolve"}, map[string][]string{resource.URL: {"DOMAIN-SUFFIX,example.com"}}); err == nil {
		t.Fatal("no-resolve was accepted for a domain rule")
	}
	if _, err := daeResourceBodies(resource, []string{"url-regex"}, map[string][]string{resource.URL: {"DOMAIN,example.com"}}); err == nil {
		t.Fatal("unknown rule option was silently discarded")
	}
	if _, err := daeRule("DOMAIN,*.example.com", "group_001"); err == nil {
		t.Fatal("wildcard DOMAIN was silently widened into a suffix match")
	}
	process, err := daeRule("PROCESS-NAME,WebTorrent Helper.exe", "group_001")
	if err != nil || process != "pname('WebTorrent Helper.exe') -> group_001" {
		t.Fatalf("PROCESS-NAME lowering = %q, err=%v", process, err)
	}
	if _, err := daeRule("PROCESS-NAME,helper; block()", "group_001"); err == nil {
		t.Fatal("PROCESS-NAME accepted DAE expression syntax")
	}
}

func TestDAERejectsUnmappedRejectSemanticsAndFinalFields(t *testing.T) {
	for _, target := range []string{"REJECT", "REJECT-DROP"} {
		scheme := &model.RuleScheme{Rules: []model.RuleSchemeRule{
			{Group: target, Body: "DOMAIN,example.test"},
			{Group: "DIRECT", Final: true},
		}}
		if result := DAEPreflight(Options{Target: model.ClientDAE, Nodes: sampleNodes(), Scheme: scheme}); result.Status != PreflightUnsupported {
			t.Errorf("DAEPreflight target %s = %s, want unsupported", target, result.Status)
		}
	}

	for name, mutate := range map[string]func(*model.RuleSchemeRule){
		"body": func(rule *model.RuleSchemeRule) { rule.Body = "DOMAIN,example.test" },
		"resource": func(rule *model.RuleSchemeRule) {
			rule.Resource = &model.RuleSchemeRuleSet{URL: "https://rules.example/list", Format: "text", Behavior: "domain"}
		},
		"options": func(rule *model.RuleSchemeRule) { rule.Options = []string{"no-resolve"} },
	} {
		rule := model.RuleSchemeRule{Group: "DIRECT", Final: true}
		mutate(&rule)
		scheme := &model.RuleScheme{Rules: []model.RuleSchemeRule{rule}}
		result := DAEPreflight(Options{Target: model.ClientDAE, Nodes: sampleNodes(), Scheme: scheme})
		if result.Status != PreflightUnsupported || !hasIssueCode(result, "rule_final_fields") {
			t.Errorf("final %s fields: status=%s issues=%v, want rule_final_fields blocker", name, result.Status, result.Issues)
		}
	}

	scheme := &model.RuleScheme{Rules: []model.RuleSchemeRule{
		{Group: "BLOCK", Body: "DOMAIN,example.test"},
		{Group: "DIRECT", Final: true},
	}}
	result := DAEPreflight(Options{Target: model.ClientDAE, Nodes: sampleNodes(), Scheme: scheme})
	if result.Status != PreflightExact {
		t.Fatalf("explicit BLOCK preflight = %s (%v), want exact", result.Status, result.Issues)
	}
	content, err := GenerateDAE(Options{Target: model.ClientDAE, Nodes: sampleNodes(), Scheme: scheme})
	if err != nil || !strings.Contains(content, "domain(full: example.test) -> block") {
		t.Fatalf("explicit BLOCK render missing: err=%v", err)
	}
}

func hasIssueCode(result PreflightResult, code string) bool {
	for _, issue := range result.Issues {
		if issue.Code == code {
			return true
		}
	}
	return false
}

func TestDAENativeAutoKindIsRejectedByOtherTargetFamilies(t *testing.T) {
	scheme := &model.RuleScheme{Groups: []model.RuleSchemeGroup{{Name: "auto", Kind: model.KindDAENativeAuto, Members: []model.RuleGroupMember{{Type: model.MemberNodePattern, Value: ".*"}}}}}
	for _, target := range []model.ClientTarget{model.ClientClashVerge, model.ClientSurge, model.ClientShadowrocket, model.ClientClashooSB} {
		if _, err := Generate(Options{Target: target, Nodes: sampleNodes(), Scheme: scheme}); err == nil || !strings.Contains(err.Error(), "dae 原生自动测速") {
			t.Fatalf("Generate(%s) error = %v, want explicit DAE-only rejection", target, err)
		}
	}
}
