#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      select_none                     Select action"
  echo "      turn_off_ipv6                   Disable IPv6"
  echo "      ipv6_full_1                     Enable IPv6"
  echo "      ipv6_full_try_2                 Enable IPv6 method 2"
  echo "      ipv6_nat_3                      Enable IPv6 NAT"
  echo "      half_ipv6                       Half IPv6 (Only Router)"
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
  *)
    if [ -n "${ACTION}" -a -s /usr/share/systools/${ACTION}.run ]; then
      bash "/usr/share/systools/${ACTION}.run"
    else
      usage
      exit 1
    fi
  ;;
esac

