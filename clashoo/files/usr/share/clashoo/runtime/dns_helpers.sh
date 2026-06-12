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

# Route DNS upstreams by rules and preserve the original setting.
dns_mihomo_apply_respect_rules() {
  local cfg="$1" enabled="${2:-0}" tmp="${1}.$$"
  [ -f "$cfg" ] || return 0

  awk -v enabled="$enabled" '
    function indent_len(s) { match(s, /[^ ]/); return RSTART ? RSTART - 1 : length(s) }
    function spaces(n,   out,i) {
      out = ""
      for (i = 0; i < n; i++)
        out = out " "
      return out
    }
    function trim_value(s) {
      sub(/^[[:space:]]*/, "", s)
      sub(/[[:space:]]*$/, "", s)
      return s
    }
    function flush_dns(   i, sp) {
      if (!in_dns)
        return
      sp = spaces(child_indent > 0 ? child_indent : dns_indent + 2)
      print dns_lines[1]
      if (enabled == "1") {
        print sp "# >>> clashoo:dns_leak_protect_respect_rules"
        print sp "# original-respect-rules: " (original_value != "" ? original_value : "absent")
        print sp "respect-rules: true"
        print sp "# <<< clashoo:dns_leak_protect_respect_rules"
      } else if (original_value != "" && original_value != "absent") {
        print sp "respect-rules: " original_value
      }
      for (i = 2; i <= dns_n; i++)
        print dns_lines[i]
      in_dns = 0
      dns_n = 0
    }

    /^dns:[[:space:]]*$/ {
      flush_dns()
      in_dns = 1
      dns_indent = indent_len($0)
      child_indent = -1
      dns_n = 1
      dns_lines[dns_n] = $0
      original_value = ""
      in_marker = 0
      next
    }
    in_dns {
      cur_indent = indent_len($0)
      if ($0 ~ /^[^[:space:]#][^:]*:/ && cur_indent <= dns_indent) {
        flush_dns()
        print
        next
      }
      if ($0 ~ /^[[:space:]]*#[[:space:]]*>>>[[:space:]]*clashoo:dns_leak_protect_respect_rules[[:space:]]*$/) {
        in_marker = 1
        if (child_indent < 0) child_indent = cur_indent
        next
      }
      if (in_marker) {
        if ($0 ~ /^[[:space:]]*#[[:space:]]*original-respect-rules:[[:space:]]*/) {
          value = $0
          sub(/^[[:space:]]*#[[:space:]]*original-respect-rules:[[:space:]]*/, "", value)
          original_value = trim_value(value)
        }
        if ($0 ~ /^[[:space:]]*#[[:space:]]*<<<[[:space:]]*clashoo:dns_leak_protect_respect_rules[[:space:]]*$/)
          in_marker = 0
        next
      }
      if ($0 ~ /^[[:space:]]*respect-rules:[[:space:]]*/) {
        if (original_value == "") {
          value = $0
          sub(/^[[:space:]]*respect-rules:[[:space:]]*/, "", value)
          original_value = trim_value(value)
        }
        if (child_indent < 0) child_indent = cur_indent
        next
      }
      if ($0 ~ /^[[:space:]]*[^#[:space:]][^:]*:/ && cur_indent > dns_indent && child_indent < 0)
        child_indent = cur_indent
      dns_lines[++dns_n] = $0
      next
    }
    { print }
    END { flush_dns() }
  ' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
  rm -f "$tmp" 2>/dev/null
}

# Use fallback DNS for queries; keep bootstrap DNS unchanged.
dns_mihomo_apply_leak_nameservers() {
  local cfg="$1" enabled="${2:-0}" state="${1}.dns-leak-nameserver"
  local selected="${1}.dns-leak-selected" current="${1}.dns-leak-current" tmp="${1}.$$"
  [ -f "$cfg" ] || return 0
  command -v yq >/dev/null 2>&1 || return 0

  if [ "$enabled" = "1" ]; then
    yq e -r '.dns.fallback[]' "$cfg" > "$selected" 2>/dev/null || true
    if [ ! -s "$selected" ]; then
      printf '%s\n' 'https://1.1.1.1/dns-query' 'https://8.8.8.8/dns-query' > "$selected"
    fi
    yq e -r '.dns.nameserver[]' "$cfg" > "$current" 2>/dev/null || true

    if [ ! -f "$state" ] ||
       ! grep -q 'clashoo:dns_leak_protect_respect_rules' "$cfg" ||
       ! cmp -s "$current" "$selected"; then
      awk '
        function indent_len(s) { match(s, /[^ ]/); return RSTART ? RSTART - 1 : length(s) }
        /^dns:[[:space:]]*$/ { in_dns = 1; dns_indent = indent_len($0); next }
        in_dns && /^[^[:space:]#][^:]*:/ { exit }
        in_dns && /^[[:space:]]*nameserver:[[:space:]]*$/ {
          in_ns = 1
          ns_indent = indent_len($0)
          print
          next
        }
        in_ns {
          cur_indent = indent_len($0)
          if ($0 ~ /^[[:space:]]*$/ || cur_indent > ns_indent) {
            print
            next
          }
          exit
        }
      ' "$cfg" > "$state"
      [ -s "$state" ] || printf '__ABSENT__\n' > "$state"
    fi

    awk -v selected="$selected" '
      function indent_len(s) { match(s, /[^ ]/); return RSTART ? RSTART - 1 : length(s) }
      function spaces(n,   out,i) {
        out = ""
        for (i = 0; i < n; i++) out = out " "
        return out
      }
      function print_selected(sp,   line) {
        print sp "nameserver:"
        while ((getline line < selected) > 0)
          if (line != "") print sp "  - " line
        close(selected)
        inserted = 1
      }
      /^dns:[[:space:]]*$/ {
        in_dns = 1
        dns_indent = indent_len($0)
        child_indent = -1
        print
        next
      }
      in_dns && /^[^[:space:]#][^:]*:/ {
        if (!inserted) print_selected(spaces(child_indent > 0 ? child_indent : dns_indent + 2))
        in_dns = 0
        print
        next
      }
      in_dns && /^[[:space:]]*[^#[:space:]][^:]*:/ && child_indent < 0 {
        child_indent = indent_len($0)
      }
      in_dns && /^[[:space:]]*nameserver:[[:space:]]*$/ {
        ns_indent = indent_len($0)
        print_selected(spaces(ns_indent))
        skip_ns = 1
        next
      }
      skip_ns {
        cur_indent = indent_len($0)
        if ($0 ~ /^[[:space:]]*$/ || cur_indent > ns_indent) next
        skip_ns = 0
      }
      { print }
      END {
        if (in_dns && !inserted)
          print_selected(spaces(child_indent > 0 ? child_indent : dns_indent + 2))
      }
    ' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
  elif [ -f "$state" ]; then
    awk -v state="$state" '
      function indent_len(s) { match(s, /[^ ]/); return RSTART ? RSTART - 1 : length(s) }
      function print_original(   line) {
        if ((getline line < state) > 0 && line != "__ABSENT__") {
          print line
          while ((getline line < state) > 0) print line
        }
        close(state)
        restored = 1
      }
      /^dns:[[:space:]]*$/ { in_dns = 1; print; next }
      in_dns && /^[^[:space:]#][^:]*:/ {
        if (!restored) print_original()
        in_dns = 0
        print
        next
      }
      in_dns && /^[[:space:]]*nameserver:[[:space:]]*$/ {
        ns_indent = indent_len($0)
        print_original()
        skip_ns = 1
        next
      }
      skip_ns {
        cur_indent = indent_len($0)
        if ($0 ~ /^[[:space:]]*$/ || cur_indent > ns_indent) next
        skip_ns = 0
      }
      { print }
      END { if (in_dns && !restored) print_original() }
    ' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
    rm -f "$state"
  fi
  rm -f "$selected" "$current" "$tmp" 2>/dev/null
}


# handle mihomo dns block:
#   - strip previous injection markers + all ipv6: lines
#   - rewrite ipv6 from ipv6_value (skip when empty)
#   - when enabled=1, append geosite gfw marker block to fallback-filter
#     create fallback-filter (geoip: false skeleton) if absent
# Marker:
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

# handle DST-PORT,853,REJECT injection into rules block
# only remove Clashoo marker block, never user original rules
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
  dns_mihomo_apply_leak_nameservers "$cfg" "$enabled"
  dns_mihomo_apply_respect_rules "$cfg" "$enabled"
  dns_mihomo_apply_leak_dns_block "$cfg" "$enabled" "$ipv6_value"
  dns_mihomo_apply_leak_rule "$cfg" "$enabled"
}
