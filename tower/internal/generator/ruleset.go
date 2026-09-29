package generator

import (
	"crypto/sha1"
	"fmt"
	"strings"

	"github.com/kenzok8/tower/internal/model"
	yamlv3 "gopkg.in/yaml.v3"
)

type plannedRule struct {
	rule       model.RuleSchemeRule
	native     bool
	providerID string
}

type plannedProvider struct {
	id       string
	resource model.RuleSchemeRuleSet
}

func planSchemeRules(opts Options) ([]plannedRule, []plannedProvider, error) {
	if opts.Scheme == nil {
		return nil, nil, nil
	}
	var rules []plannedRule
	var providers []plannedProvider
	providerSeen := make(map[string]bool)
	clashTarget := opts.Target.Family() == model.FamilyClash
	surgeTarget := opts.Target.Family() == model.FamilySurge

	for _, source := range opts.Scheme.Rules {
		if source.Resource == nil {
			rules = append(rules, plannedRule{rule: source})
			continue
		}
		resource := *source.Resource
		format := strings.ToLower(strings.TrimSpace(resource.Format))
		if format == "" {
			format = "text"
		}
		native := opts.PreferRuleSets && ((clashTarget && (format == "text" || format == "yaml" || format == "mrs")) || (surgeTarget && format == "text"))
		if native {
			id := ruleSetID(resource)
			rules = append(rules, plannedRule{rule: source, native: true, providerID: id})
			if clashTarget && !providerSeen[id] {
				providerSeen[id] = true
				providers = append(providers, plannedProvider{id: id, resource: resource})
			}
			continue
		}

		lines, ok := opts.RuleSetLines[resource.URL]
		if !ok || len(lines) == 0 {
			return nil, nil, fmt.Errorf("规则集 %s 没有可用的本地缓存；请刷新规则后重试", resource.URL)
		}
		var err error
		lines, err = resourceLines(resource, lines)
		if err != nil {
			return nil, nil, err
		}
		for _, line := range lines {
			line = strings.TrimSpace(line)
			if line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, ";") || strings.HasPrefix(line, "//") {
				continue
			}
			body, options := normalizeResourceLine(resource, line)
			if body == "" {
				continue
			}
			options = append(options, source.Options...)
			rule := model.RuleSchemeRule{Group: source.Group, Body: body, Options: dedupStrings(options)}
			rules = append(rules, plannedRule{rule: rule})
		}
	}
	return rules, providers, nil
}

func resourceLines(resource model.RuleSchemeRuleSet, lines []string) ([]string, error) {
	switch strings.ToLower(strings.TrimSpace(resource.Format)) {
	case "", "text":
		return lines, nil
	case "yaml":
		var doc struct {
			Payload []string `yaml:"payload"`
		}
		if err := yamlv3.Unmarshal([]byte(strings.Join(lines, "\n")), &doc); err != nil {
			return nil, fmt.Errorf("无法展开 YAML 规则集 %s：%w", resource.URL, err)
		}
		if len(doc.Payload) == 0 {
			return nil, fmt.Errorf("YAML 规则集 %s 没有 payload", resource.URL)
		}
		return doc.Payload, nil
	case "mrs":
		return nil, fmt.Errorf("MRS 规则集 %s 暂不支持本地展开", resource.URL)
	default:
		return nil, fmt.Errorf("规则集 %s 使用不支持的格式 %q", resource.URL, resource.Format)
	}
}

func ruleSetID(resource model.RuleSchemeRuleSet) string {
	if tag := safeProviderName(resource.Tag); tag != "" {
		return tag
	}
	h := sha1.Sum([]byte(resource.URL))
	return fmt.Sprintf("tower-%x", h[:6])
}

func safeProviderName(raw string) string {
	raw = strings.ToLower(strings.TrimSpace(raw))
	var b strings.Builder
	for _, r := range raw {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '-' || r == '_' {
			b.WriteRune(r)
		}
	}
	return strings.Trim(b.String(), "-_")
}

func normalizeResourceLine(resource model.RuleSchemeRuleSet, line string) (string, []string) {
	behavior := strings.ToLower(strings.TrimSpace(resource.Behavior))
	if behavior == "domain" {
		domain := strings.TrimPrefix(line, "+.")
		domain = strings.TrimPrefix(domain, ".")
		return "DOMAIN-SUFFIX," + domain, nil
	}
	if behavior == "ipcidr" {
		kind := "IP-CIDR"
		if strings.Contains(line, ":") {
			kind = "IP-CIDR6"
		}
		return kind + "," + line, nil
	}
	fields := splitRuleFields(line)
	if len(fields) < 2 {
		return "", nil
	}
	conditionEnd := len(fields)
	for conditionEnd > 2 && isInlineRuleOption(fields[conditionEnd-1]) {
		conditionEnd--
	}
	return strings.Join(fields[:conditionEnd], ","), fields[conditionEnd:]
}

func renderRule(rule plannedRule, target model.ClientTarget) string {
	if rule.rule.Final {
		if target.Family() == model.FamilySurge {
			return "FINAL," + confName(rule.rule.Group)
		}
		return "MATCH," + rule.rule.Group
	}
	if rule.native {
		value := rule.rule.Resource.URL
		if target.Family() == model.FamilyClash {
			value = rule.providerID
		}
		fields := []string{"RULE-SET", value, policyName(rule.rule.Group, target)}
		fields = append(fields, rule.rule.Options...)
		return strings.Join(fields, ",")
	}
	fields := splitRuleFields(rule.rule.Body)
	if len(fields) == 0 {
		return ""
	}
	conditionEnd := len(fields)
	options := append([]string(nil), rule.rule.Options...)
	for conditionEnd > 2 && isInlineRuleOption(fields[conditionEnd-1]) {
		conditionEnd--
		options = append([]string{fields[conditionEnd]}, options...)
	}
	fields = fields[:conditionEnd]
	fields = append(fields, policyName(rule.rule.Group, target))
	fields = append(fields, options...)
	return strings.Join(fields, ",")
}

func splitRuleFields(line string) []string {
	var fields []string
	var current strings.Builder
	quoted := false
	for _, r := range line {
		switch {
		case r == '"':
			quoted = !quoted
			current.WriteRune(r)
		case r == ',' && !quoted:
			fields = append(fields, strings.TrimSpace(current.String()))
			current.Reset()
		default:
			current.WriteRune(r)
		}
	}
	fields = append(fields, strings.TrimSpace(current.String()))
	return fields
}

func isInlineRuleOption(value string) bool {
	return strings.EqualFold(value, "no-resolve") || strings.EqualFold(value, "src") || strings.EqualFold(value, "extended-matching")
}

func policyName(name string, target model.ClientTarget) string {
	if target.Family() == model.FamilySurge || target.Family() == model.FamilyShadowrocket {
		return confName(name)
	}
	return name
}
