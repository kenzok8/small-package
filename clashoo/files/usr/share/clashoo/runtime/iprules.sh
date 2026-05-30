#!/bin/sh
. /lib/functions.sh


TMP_PREFIX="/tmp/clashoo_iprules.$$"
CUSTOM_RULE_FILE="${TMP_PREFIX}.ipadd.conf"
RULE="${TMP_PREFIX}.rules_conf.yaml"
CLASH="${TMP_PREFIX}.conf.yaml"
CONFIG_YAML="/etc/clashoo/config.yaml"
CLASH_CONFIG="${TMP_PREFIX}.config.yaml"
trap 'rm -f "$CUSTOM_RULE_FILE" "$RULE" "$CLASH" "$CLASH_CONFIG"' EXIT

[ -f "$CONFIG_YAML" ] || exit 0

# 「代理」占位符 __PROXY__ → 实际主代理组(由 RPC detect_primary_group 探测并缓存）。
# 探测不到时回退 GLOBAL（mihomo 内置全局策略组，始终存在）。
PRIMARY_GROUP="$(uci -q get clashoo.config.primary_proxy_group)"
[ -n "$PRIMARY_GROUP" ] || PRIMARY_GROUP="GLOBAL"

# ===== append_rules：把订阅自带的 rules 块整体挪到文件末尾（原有逻辑，保持不变） =====
append=$(uci get clashoo.config.append_rules 2>/dev/null)
if [ "${append:-0}" -eq 1 ];then

	if [ -f $CLASH_CONFIG ];then
		rm -rf $CLASH_CONFIG 2>/dev/null
	fi

	cp $CONFIG_YAML $CLASH_CONFIG 2>/dev/null
	if [ ! -z "$(grep "^Rule:" "$CLASH_CONFIG")" ]; then
		sed -i "/^Rule:/i\#RULESTART#" $CLASH_CONFIG 2>/dev/null
	elif [ ! -z "$(grep "^rules:" "$CLASH_CONFIG")" ]; then
		sed -i "/^rules:/i\#RULESTART#" $CLASH_CONFIG 2>/dev/null
	fi
	sed -i -e "\$a#RULEEND#" $CLASH_CONFIG 2>/dev/null

	awk '/#RULESTART#/,/#RULEEND#/{print}' "$CLASH_CONFIG" 2>/dev/null |sed "s/\'//g" 2>/dev/null |sed 's/\"//g' 2>/dev/null |sed 's/\t/ /g' 2>/dev/null |grep '^ \{0,\}- '|awk -F '- ' '{print "- "$2}' | sed 's/^ \{0,\}//' 2>/dev/null |sed 's/ \{0,\}$//' 2>/dev/null  >$RULE 2>&1

	sed -i '/#RULESTART#/,/#RULEEND#/d' "$CLASH_CONFIG" 2>/dev/null

	sed -i -e "\$a " $CLASH_CONFIG 2>/dev/null
	sed -i "1i\rules:" $RULE 2>/dev/null
	cat $CLASH_CONFIG $RULE  >$CLASH 2>/dev/null
	mv $CLASH $CONFIG_YAML 2>/dev/null
	rm -f $RULE $CLASH_CONFIG 2>/dev/null
fi

# ===== 自定义分流规则（UCI: config addtype），与 append_rules 解耦，始终生效 =====
# 每条规则字段：type(DOMAIN/DOMAIN-SUFFIX/DOMAIN-KEYWORD/IP-CIDR)、ipaaddr(地址)、
# pgroup(走向：DIRECT 或占位符 __PROXY__)、res(IP 规则的 no-resolve，1/0)。
rm -f "$CUSTOM_RULE_FILE" 2>/dev/null

ipadd()
{
	local section="$1"
	config_get "pgroup" "$section" "pgroup" ""
	config_get "ipaaddr" "$section" "ipaaddr" ""
	config_get "type" "$section" "type" ""
	config_get "res" "$section" "res" ""

	[ -z "$type" ] && return
	[ -z "$ipaaddr" ] && return
	[ -z "$pgroup" ] && return

	[ "$pgroup" = "__PROXY__" ] && pgroup="$PRIMARY_GROUP"

	# 缩进与现有 rules 列表一致 + 整条加引号（策略组名可能含空格/emoji，如「🚀 节点选择」），
	# 否则与订阅自带的 2 空格缩进列表混用会让 mihomo 解析 YAML 失败。
	if [ "${res}" = "1" ];then
		echo "${RULE_INDENT}- \"$type,$ipaaddr,$pgroup,no-resolve\"" >> "$CUSTOM_RULE_FILE"
	else
		echo "${RULE_INDENT}- \"$type,$ipaaddr,$pgroup\"" >> "$CUSTOM_RULE_FILE"
	fi
}

# 探测 rules: 段下现有条目的缩进，注入时对齐（默认 2 空格）
RULE_INDENT="$(awk '/^[[:space:]]*rules:/{f=1;next} f&&/^[[:space:]]*-/{match($0,/^[[:space:]]*/);print substr($0,1,RLENGTH);exit}' "$CONFIG_YAML" 2>/dev/null)"
[ -n "$RULE_INDENT" ] || RULE_INDENT="  "

config_load "clashoo"
config_foreach ipadd "addtype"

# 先清掉上一轮注入的自定义块（幂等）
sed -i '/#CUSTOMRULESTART#/,/#CUSTOMRULEEND#/d' "$CONFIG_YAML" 2>/dev/null

if [ -f "$CUSTOM_RULE_FILE" ];then
	sed -i -e "\$a#CUSTOMRULEEND#" "$CUSTOM_RULE_FILE" 2>/dev/null
	if [ ! -z "$(grep "^ \{0,\}rules:" "$CONFIG_YAML")" ]; then
		# 插在 rules: 段最前面，优先于订阅自带规则命中（纠错）
		sed -i '/^ \{0,\}rules:/a\#CUSTOMRULESTART#' "$CONFIG_YAML" 2>/dev/null
	else
		echo "rules:" >> "$CONFIG_YAML" 2>/dev/null
		echo "#CUSTOMRULESTART#" >> "$CONFIG_YAML" 2>/dev/null
	fi
	sed -i "/#CUSTOMRULESTART#/r${CUSTOM_RULE_FILE}" "$CONFIG_YAML" 2>/dev/null
fi
