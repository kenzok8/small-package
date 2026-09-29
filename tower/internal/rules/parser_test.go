package rules

import (
	"os"
	"strings"
	"testing"

	"github.com/kenzok8/tower/internal/model"
)

func TestParseINI(t *testing.T) {
	text := `[custom]
ruleset=🎯 全球直连,[]GEOIP,CN
ruleset=🚀 节点选择,https://example.com/Telegram.list
ruleset=🐟 漏网之鱼,[]FINAL
custom_proxy_group=🚀 节点选择` + "`" + `select` + "`" + `[]♻️ 自动选择` + "`" + `[]DIRECT` + "`" + `.*
custom_proxy_group=♻️ 自动选择` + "`" + `url-test` + "`" + `.*` + "`" + `http://www.gstatic.com/generate_204` + "`" + `300,,50
custom_proxy_group=🎯 全球直连` + "`" + `select` + "`" + `[]DIRECT` + "`" + `[]🚀 节点选择
`

	resolver := func(source string) ([]string, error) {
		if source != "https://example.com/Telegram.list" {
			t.Fatalf("unexpected source %s", source)
		}
		return []string{"# 注释", "DOMAIN-SUFFIX,t.me", "IP-CIDR,91.108.0.0/16"}, nil
	}

	scheme, err := Parse(text, resolver)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if len(scheme.Groups) != 3 {
		t.Fatalf("groups = %d, want 3", len(scheme.Groups))
	}
	// url-test group carries url + timing
	ut := scheme.Groups[1]
	if ut.Kind != model.KindURLTest || ut.URL != "http://www.gstatic.com/generate_204" ||
		ut.Interval != 300 || ut.Tolerance != 50 {
		t.Fatalf("url-test group wrong: %+v", ut)
	}
	// Keep the remote Telegram set as one resource reference instead of
	// expanding its contents into the persisted scheme.
	if len(scheme.Rules) != 3 {
		t.Fatalf("rules = %d, want 3: %+v", len(scheme.Rules), scheme.Rules)
	}
	if scheme.Rules[1].Resource == nil || scheme.Rules[1].Resource.URL != "https://example.com/Telegram.list" {
		t.Fatalf("remote ruleset not preserved: %+v", scheme.Rules[1])
	}
	if !scheme.Rules[2].Final || scheme.Rules[2].Group != "🐟 漏网之鱼" {
		t.Fatalf("final rule wrong: %+v", scheme.Rules[2])
	}
}

func TestParseClashYAML(t *testing.T) {
	text := `proxy-groups:
  - name: 节点选择
    type: select
    icon: https://cdn.simpleicons.org/openai
    proxies:
      - 自动选择
      - DIRECT
      - 香港
  - name: 自动选择
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    include-all-proxies: true
    filter: ".*"
rules:
  - DOMAIN-SUFFIX,google.com,节点选择
  - GEOIP,CN,DIRECT
  - MATCH,节点选择
`
	scheme, err := Parse(text, nil)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if len(scheme.Groups) != 2 || len(scheme.Rules) != 3 {
		t.Fatalf("groups=%d rules=%d", len(scheme.Groups), len(scheme.Rules))
	}
	// member classification: "自动选择"/"DIRECT" are references, "香港" is a pattern
	g := scheme.Groups[0]
	if g.IconURL != "https://cdn.simpleicons.org/openai" {
		t.Fatalf("group icon not preserved: %+v", g)
	}
	if len(g.Members) != 3 {
		t.Fatalf("members = %d", len(g.Members))
	}
	if g.Members[2].Type != model.MemberNodePattern || g.Members[2].Value != "^香港$" {
		t.Fatalf("member wrong: %+v", g.Members[2])
	}
	if scheme.Groups[1].Members[0].Type != model.MemberNodePattern || scheme.Groups[1].Members[0].Value != ".*" {
		t.Fatalf("Mihomo node filter was not preserved: %+v", scheme.Groups[1].Members)
	}
	if !scheme.Rules[2].Final {
		t.Fatalf("MATCH not marked final")
	}
}

func TestParseClashIncludeAllAndLookaheadFilter(t *testing.T) {
	text := `proxy-groups:
  - name: 香港节点
    type: select
    include-all: true
    filter: "(?i)港|hk|hongkong|hong kong"
  - name: 香港自动
    type: url-test
    include-all: true
    filter: "(?=.*(港|HK|(?i)Hong))^((?!(台|日|韩|新|深|美)).)*$"
rules:
  - MATCH,香港节点
`
	scheme, err := Parse(text, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(scheme.Groups[0].Members) != 1 || scheme.Groups[0].Members[0].Value != "(?i)港|hk|hongkong|hong kong" {
		t.Fatalf("include-all group lost node filter: %+v", scheme.Groups[0].Members)
	}
	filter := scheme.Groups[1].Members[0]
	if filter.Value != "港|HK|(?i)Hong" || filter.Exclude != "台|日|韩|新|深|美" {
		t.Fatalf("lookahead filter not split: %+v", filter)
	}
}

func TestKenzok8BundledTemplateIsImportable(t *testing.T) {
	data, err := os.ReadFile("../../files/rules/Kenzok8.yaml")
	if err != nil {
		t.Fatal(err)
	}
	scheme, err := Parse(string(data), nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(scheme.Groups) != 30 || len(scheme.Rules) != 21 {
		t.Fatalf("groups=%d rules=%d, want 30 and 21", len(scheme.Groups), len(scheme.Rules))
	}
	groups := make(map[string]model.RuleSchemeGroup, len(scheme.Groups))
	for _, group := range scheme.Groups {
		groups[group.Name] = group
	}
	for _, name := range []string{"🇹🇼 台湾节点", "🇰🇷 韩国节点", "♻️ 台湾自动", "♻️ 韩国自动", "🌐 直连"} {
		if _, ok := groups[name]; !ok {
			t.Errorf("missing group %s", name)
		}
	}
	for _, name := range []string{"🇺🇳 集合节点", "♻️ 集合自动"} {
		if _, ok := groups[name]; ok {
			t.Errorf("redundant group %s remains", name)
		}
	}
	for _, name := range []string{"▶️ YouTube", "📔 Google", "🔮 OpenAI", "🧠 Claude", "🤖 Gemini", "🐦 Twitter", "📦 GitHub", "Ⓜ️ Microsoft", "🎵 TikTok", "📺 NETFLIX", "💳 PayPal"} {
		if groups[name].IconURL == "" {
			t.Errorf("missing icon for %s", name)
		}
	}
}

func TestParseClashRuleProvider(t *testing.T) {
	text := `rule-providers:
  telegram:
    type: http
    behavior: classical
    format: text
    url: https://example.com/telegram.list
    interval: 43200
proxy-groups:
  - name: 节点选择
    type: select
    proxies: [DIRECT]
rules:
  - RULE-SET,telegram,节点选择,no-resolve
  - MATCH,节点选择
`
	scheme, err := Parse(text, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(scheme.Rules) != 2 || scheme.Rules[0].Resource == nil {
		t.Fatalf("remote provider was not preserved: %+v", scheme.Rules)
	}
	rule := scheme.Rules[0]
	if rule.Group != "节点选择" || len(rule.Options) != 1 || rule.Options[0] != "no-resolve" {
		t.Fatalf("RULE-SET binding or options lost: %+v", rule)
	}
	if got := rule.Resource; got.URL != "https://example.com/telegram.list" || got.Tag != "telegram" || got.Interval != 43200 {
		t.Fatalf("provider metadata lost: %+v", got)
	}
}

func TestParseClashRejectsMissingRuleProvider(t *testing.T) {
	text := `proxy-groups:
  - name: 节点选择
    type: select
    proxies: [DIRECT]
rules:
  - RULE-SET,missing,节点选择
`
	if _, err := Parse(text, nil); err == nil || !strings.Contains(err.Error(), "unknown provider") {
		t.Fatalf("missing provider should be an explicit error, got %v", err)
	}
}

func TestParseClashRejectsUnsafeIconURL(t *testing.T) {
	text := `proxy-groups:
  - name: 节点选择
    type: select
    icon: http://example.com/icon.png
    proxies: [DIRECT]
rules:
  - MATCH,节点选择
`
	if _, err := Parse(text, nil); err == nil || !strings.Contains(err.Error(), "credential-free HTTPS URL") {
		t.Fatalf("non-HTTPS icon should be rejected, got %v", err)
	}
}

func TestParseSurgeRuleScheme(t *testing.T) {
	text := `[General]
ipv6 = true
[Proxy]
node = ss, example.com, 443, encrypt-method=aes-128-gcm, password=secret
[Proxy Group]
节点选择 = select, node, DIRECT
[Rule]
RULE-SET,https://example.com/list.txt,节点选择,no-resolve
FINAL,节点选择
`
	scheme, err := Parse(text, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(scheme.Groups) != 1 || len(scheme.Rules) != 2 || scheme.Rules[0].Resource == nil {
		t.Fatalf("Surge scheme was not parsed: %+v", scheme)
	}
	if scheme.NetworkSettings == nil || scheme.NetworkSettings.IPv6Enabled == nil || !*scheme.NetworkSettings.IPv6Enabled {
		t.Fatalf("Surge IPv6 preference was not imported: %+v", scheme.NetworkSettings)
	}
	if scheme.RawConfig != "" {
		t.Fatal("parser must not retain original node-bearing source text")
	}
}

func TestParseINIRuleSetFormatFromExtension(t *testing.T) {
	text := "[custom]\nruleset=视频,https://example.com/Netflix.yaml\n" +
		"custom_proxy_group=视频`select`[]DIRECT\n"
	scheme, err := Parse(text, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(scheme.Rules) != 1 || scheme.Rules[0].Resource == nil || scheme.Rules[0].Resource.Format != "yaml" {
		t.Fatalf("YAML ruleset format was not inferred: %+v", scheme.Rules)
	}
}

func TestLoadBundled(t *testing.T) {
	dir := "../../files/rules"
	schemes, err := LoadBundled(dir)
	if err != nil {
		t.Fatalf("load bundled: %v", err)
	}
	if len(schemes) != 4 {
		t.Fatalf("bundled schemes = %d, want 4", len(schemes))
	}
	for _, s := range schemes {
		if !s.IsBundled || len(s.Groups) == 0 || len(s.Rules) == 0 {
			t.Fatalf("scheme %s incomplete: groups=%d rules=%d", s.Name, len(s.Groups), len(s.Rules))
		}
		// every non-final rule body must still contain its condition
		for _, r := range s.Rules {
			if !r.Final && r.Resource == nil && !strings.Contains(r.Body, ",") {
				t.Fatalf("scheme %s rule body lacks condition: %+v", s.Name, r)
			}
		}
		t.Logf("scheme %s: groups=%d rules=%d", s.Name, len(s.Groups), len(s.Rules))
	}
	var personal *model.RuleScheme
	for i := range schemes {
		if schemes[i].ID == "self-configuration" {
			personal = schemes[i]
		}
	}
	if personal == nil || personal.Name != "Self-Configuration" {
		t.Fatal("Self-Configuration preset was not loaded")
	}
	if len(personal.Groups) != 27 || len(personal.Rules) != 68 {
		t.Fatalf("personal preset has groups=%d rules=%d, want 27 and 68", len(personal.Groups), len(personal.Rules))
	}
	remoteRules := 0
	for _, rule := range personal.Rules {
		if rule.Resource == nil {
			if rule.Body == "" && !rule.Final {
				t.Fatalf("personal preset has an empty inline rule: %+v", rule)
			}
			continue
		}
		remoteRules++
		if rule.Resource.Format != "yaml" {
			t.Fatalf("personal preset remote provider format = %q, want yaml", rule.Resource.Format)
		}
	}
	if remoteRules != 66 {
		t.Fatalf("personal preset remote providers = %d, want 66", remoteRules)
	}
	var kenzok8 *model.RuleScheme
	for _, scheme := range schemes {
		if scheme.ID == "kenzok8-rules" {
			kenzok8 = scheme
			break
		}
	}
	if kenzok8 == nil || kenzok8.Name != "kenzok8方案" || len(kenzok8.Groups) != 30 {
		t.Fatal("kenzok8 bundled scheme missing or incomplete")
	}
}

func TestSelfConfigurationPresetUsesOriginalSource(t *testing.T) {
	schemes, err := LoadBundled("../../files/rules")
	if err != nil {
		t.Fatal(err)
	}
	var personal *model.RuleScheme
	for _, scheme := range schemes {
		if scheme.ID == "self-configuration" {
			personal = scheme
			break
		}
	}
	if personal == nil || personal.Name != "Self-Configuration" {
		t.Fatal("Self-Configuration scheme is missing")
	}
	groupNames := make(map[string]bool)
	for _, group := range personal.Groups {
		groupNames[group.Name] = true
	}
	for _, name := range []string{"🚀 节点选择", "🌍 Other Regions", "🤖 AI服务", "✈️ Telegram"} {
		if !groupNames[name] {
			t.Errorf("missing service group %q", name)
		}
	}
	if personal.SourceURL != "https://github.com/ClashConnectRules/Self-Configuration/blob/main/Clash.yaml" {
		t.Fatalf("scheme source = %q", personal.SourceURL)
	}
}
