#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      turn_off_ipv6                   Disable IPv6"
  echo "      full_ipv6                       Full IPv6"
  echo "      half_ipv6                       Half IPv6 (Only Router)"
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

