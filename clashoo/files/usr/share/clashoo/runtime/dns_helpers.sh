#!/bin/sh
# Shared DNS helpers for ClashOO runtime generators. Keep POSIX sh compatible.

dns_trim() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

dns_has_scheme() {
  printf '%s' "$1" | grep -Eq '^[A-Za-z][A-Za-z0-9+.-]*://'
}

dns_norm_protocol() {
  case "$(dns_trim "${1:-}")" in
    ''|'none') printf '' ;;
    udp|'udp://') printf 'udp://' ;;
    tcp|'tcp://') printf 'tcp://' ;;
    dot|tls|'tls://') printf 'tls://' ;;
    doh|https|'https://') printf 'https://' ;;
    doq|quic|'quic://') printf 'quic://' ;;
    *) printf '%s' "$1" ;;
  esac
}

dns_normalize_server() {
  local address protocol port prefix
  address=$(dns_trim "${1:-}")
  protocol=$(dns_trim "${2:-}")
  port=$(dns_trim "${3:-}")

  [ -n "$address" ] || return 0

  if dns_has_scheme "$address"; then
    printf '%s' "$address"
    return 0
  fi

  prefix=$(dns_norm_protocol "$protocol")
  if [ -n "$port" ]; then
    printf '%s%s:%s' "$prefix" "$address" "$port"
  else
    printf '%s%s' "$prefix" "$address"
  fi
}

dns_yaml_sq() {
  printf "%s" "$1" | sed "s/'/''/g"
}

dns_yaml_list_item() {
  local value
  value=$(dns_yaml_sq "$1")
  printf "   - '%s'\n" "$value"
}

# 处理 mihomo dns 块：
#   - 总是先擦掉历史注入痕迹（marker 块、所有 ipv6: 行）
#   - 按 ipv6_value 重新写入 ipv6 行（空字符串则不写）
#   - enabled=1 时在 fallback-filter 末尾追加 marker 包裹的 geosite gfw；
#     fallback-filter 不存在则一并创建（含 geoip: false 骨架）
# Marker：`# >>> clashoo:dns_leak_protect` ... `# <<< clashoo:dns_leak_protect`
dns_mihomo_apply_leak_dns_block() {
  local cfg="$1" enabled="${2:-0}" ipv6_value="${3:-}" tmp="${1}.$$"
  [ -f "$cfg" ] || return 0

  awk -v enabled="$enabled" -v ipv6_value="$ipv6_value" '
    function indent_len(s) { match(s, /[^ ]/); return RSTART ? RSTART - 1 : length(s) }
    function spaces(n,   out,i) {
      out = ""
      for (i = 0; i < n; i++)
        out = out " "
      return out
    }
    function flush_dns(   i, sp, ff_sp) {
      if (!in_dns)
        return
      if (in_ff) ff_end = dns_n
      sp = spaces(child_indent > 0 ? child_indent : dns_indent + 2)
      ff_sp = (ff_child_indent > 0 ? spaces(ff_child_indent) : sp "  ")

      print dns_lines[1]
      if (ipv6_value != "")
        print sp "ipv6: " ipv6_value
      for (i = 2; i <= dns_n; i++) {
        print dns_lines[i]
        if (enabled == "1" && has_ff && !ff_has_gfw && i == ff_end) {
          print ff_sp "# >>> clashoo:dns_leak_protect"
          print ff_sp "geosite:"
          print ff_sp "  - gfw"
          print ff_sp "# <<< clashoo:dns_leak_protect"
        }
      }
      if (enabled == "1" && !has_ff) {
        print sp "fallback-filter:"
        print sp "  geoip: false"
        print sp "  # >>> clashoo:dns_leak_protect"
        print sp "  geosite:"
        print sp "    - gfw"
        print sp "  # <<< clashoo:dns_leak_protect"
      }
      in_dns = 0
      dns_n = 0
    }

    /^[[:space:]]*#[[:space:]]*>>>[[:space:]]*clashoo:dns_leak_protect[[:space:]]*$/ {
      in_marker = 1
      next
    }
    in_marker {
      if ($0 ~ /^[[:space:]]*#[[:space:]]*<<<[[:space:]]*clashoo:dns_leak_protect[[:space:]]*$/)
        in_marker = 0
      next
    }

    /^dns:[[:space:]]*$/ {
      flush_dns()
      in_dns = 1
      dns_indent = indent_len($0)
      child_indent = -1
      dns_n = 1
      dns_lines[dns_n] = $0
      has_ff = 0
      in_ff = 0
      in_ff_geosite = 0
      ff_indent = -1
      ff_child_indent = -1
      ff_geosite_indent = -1
      ff_has_gfw = 0
      ff_end = -1
      next
    }
    in_dns {
      cur_indent = indent_len($0)
      if ($0 ~ /^[^[:space:]#][^:]*:/ && cur_indent <= dns_indent) {
        flush_dns()
        print
        next
      }
      if ($0 ~ /^[[:space:]]*[^#[:space:]][^:]*:/ && cur_indent > dns_indent && child_indent < 0)
        child_indent = cur_indent
      if (in_ff && cur_indent <= ff_indent) {
        ff_end = dns_n
        in_ff = 0
        in_ff_geosite = 0
      }
      if (in_ff_geosite && cur_indent <= ff_geosite_indent)
        in_ff_geosite = 0
      if ($0 ~ /^[[:space:]]*fallback-filter:[[:space:]]*$/) {
        has_ff = 1
        in_ff = 1
        ff_indent = cur_indent
        ff_child_indent = -1
      } else if (in_ff && $0 ~ /^[[:space:]]*[^#[:space:]][^:]*:/ && ff_child_indent < 0) {
        ff_child_indent = cur_indent
      }
      if (in_ff && $0 ~ /^[[:space:]]*geosite:[[:space:]]*$/) {
        in_ff_geosite = 1
        ff_geosite_indent = cur_indent
      } else if (in_ff_geosite && $0 ~ /^[[:space:]]*-[[:space:]]*gfw([[:space:]]*(#.*)?)?$/) {
        ff_has_gfw = 1
      }
      if ($0 ~ /^[[:space:]]*ipv6:[[:space:]]*/)
        next
      dns_lines[++dns_n] = $0
      next
    }
    { print }
    END { flush_dns() }
  ' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
  rm -f "$tmp" 2>/dev/null
}

# 处理 rules 段的 DST-PORT,853,REJECT 注入。
# 只删除 Clashoo marker 块，不删除用户原有的同名规则。
dns_mihomo_apply_leak_rule() {
  local cfg="$1" enabled="${2:-0}" tmp="${1}.$$" has_user_853
  [ -f "$cfg" ] || return 0

  has_user_853=$(awk '
    /^[[:space:]]*#[[:space:]]*>>>[[:space:]]*clashoo:dns_leak_protect_rule[[:space:]]*$/ {
      in_marker = 1
      next
    }
    in_marker {
      if ($0 ~ /^[[:space:]]*#[[:space:]]*<<<[[:space:]]*clashoo:dns_leak_protect_rule[[:space:]]*$/)
        in_marker = 0
      next
    }
    /^[[:space:]]*-[[:space:]]*DST-PORT,853,REJECT([[:space:]]*(#.*)?)?$/ { found = 1 }
    END { print found ? 1 : 0 }
  ' "$cfg")

  awk -v enabled="$enabled" -v has_user_853="$has_user_853" '
    BEGIN { inserted = 0; saw_rules = 0 }
    /^[[:space:]]*#[[:space:]]*>>>[[:space:]]*clashoo:dns_leak_protect_rule[[:space:]]*$/ {
      in_marker = 1
      next
    }
    in_marker {
      if ($0 ~ /^[[:space:]]*#[[:space:]]*<<<[[:space:]]*clashoo:dns_leak_protect_rule[[:space:]]*$/)
        in_marker = 0
      next
    }
    /^rules:[[:space:]]*$/ {
      saw_rules = 1
      print
      if (enabled == "1" && has_user_853 != "1") {
        print "  # >>> clashoo:dns_leak_protect_rule"
        print "  - DST-PORT,853,REJECT"
        print "  # <<< clashoo:dns_leak_protect_rule"
        inserted = 1
      }
      next
    }
    { print }
    END {
      if (enabled == "1" && has_user_853 != "1" && !inserted && !saw_rules) {
        print ""
        print "rules:"
        print "  # >>> clashoo:dns_leak_protect_rule"
        print "  - DST-PORT,853,REJECT"
        print "  # <<< clashoo:dns_leak_protect_rule"
      }
    }
  ' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
  rm -f "$tmp" 2>/dev/null
}

dns_mihomo_apply_leak_protect() {
  local cfg="$1" enabled="${2:-0}" ipv6_value="${3:-}"
  [ -f "$cfg" ] || return 0
  dns_mihomo_apply_leak_dns_block "$cfg" "$enabled" "$ipv6_value"
  dns_mihomo_apply_leak_rule "$cfg" "$enabled"
}
