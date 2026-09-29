package generator

import (
	"encoding/json"
	"os"
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

func TestSchemeNotSilentlyIgnoredBySingBox(t *testing.T) {
	scheme := &model.RuleScheme{Rules: []model.RuleSchemeRule{{Group: "节点选择", Final: true}}}
	if _, err := Generate(Options{Target: model.ClientSingBox, Nodes: sampleNodes(), Scheme: scheme}); err == nil {
		t.Fatal("sing-box must reject unsupported schemes")
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
