#!/bin/sh
. /lib/functions.sh

uci_get_config() {
    local key="$1"
    uci -q get openclash.@overwrite[0]."$key" || uci -q get openclash.config."$key"
}

uci_get_age_public_keys() {
  local name="$1"
  [ -n "$name" ] || return 0

  _print_pub() {
    local section="$1"
    config_get cfg_name "$section" name
    if [ "$cfg_name" = "$name" ]; then
      config_get pub "$section" public
      [ -n "$pub" ] && printf '%s\n' "$pub"
    fi
  }

  config_load openclash
  config_foreach _print_pub config_age_secret
}

uci_get_age_secret_keys() {
  local name="$1"
  [ -n "$name" ] || return 0

  _print_sec() {
    local section="$1"
    config_get cfg_name "$section" name
    if [ "$cfg_name" = "$name" ]; then
      config_get sec "$section" secret
      [ -n "$sec" ] && printf '%s\n' "$sec"
    fi
  }

  config_load openclash
  config_foreach _print_sec config_age_secret
}

uci_set_age_keys_by_name() {
  local name="$1"
  local secret="$2"
  local public="$3"
  local target_section=""

  [ -n "$name" ] || return 1

  _find_age_section() {
    local section="$1"
    local cfg_name
    config_get cfg_name "$section" name
    [ "$cfg_name" = "$name" ] && target_section="$section"
  }

  config_load openclash
  config_foreach _find_age_section config_age_secret

  if [ -z "$target_section" ]; then
    target_section=$(uci -q add openclash config_age_secret)
  fi

  [ -n "$target_section" ] || return 1

  uci -q set openclash."$target_section".name="$name"
  [ -n "$secret" ] && uci -q set openclash."$target_section".secret="$secret"
  [ -n "$public" ] && uci -q set openclash."$target_section".public="$public"
  uci -q commit openclash

  return 0
}