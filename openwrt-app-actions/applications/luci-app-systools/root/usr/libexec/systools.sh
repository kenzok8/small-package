#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      select_none                     Select action"
  echo "      ipv6_pd                         Enable IPv6 (PD mode)"
  echo "      ipv6_relay                      Enable IPv6 (Relay mode)"
  echo "      ipv6_nat                        Enable IPv6 (NAT mode)"
  echo "      ipv6_half                       Half IPv6 (Only Router)"
  echo "      ipv6_off                        Disable IPv6"
  echo "      disable-planb                   Diable planb"
  echo "      reset_rom_pkgs                  Reset pkgs from rom"
  echo "      qb_reset_password               Reset qBitorent password"
  echo "      disk_power_mode                 Show disk power status"
  echo "      speedtest                       Start a speedtest"
}

case "${ACTION}" in
  "speedtest")
    /usr/share/systools/speedtest.run ${1}
  ;;
  "ipv6_pd")
    /usr/share/systools/ipv6.run pd
  ;;
  "ipv6_relay")
    /usr/share/systools/ipv6.run relay
  ;;
  "ipv6_nat")
    /usr/share/systools/ipv6.run nat
  ;;
  "ipv6_half")
    /usr/share/systools/ipv6.run half
  ;;
  "ipv6_off")
    /usr/share/systools/ipv6.run off
  ;;
  *)
    if [ -n "${ACTION}" -a -s /usr/share/systools/${ACTION}.run ]; then
      bash "/usr/share/systools/${ACTION}.run"
    else
      usage
      exit 1
    fi
  ;;
esac

