#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      turn_off_ipv6                   Disable IPv6"
  echo "      reset_rom_pkgs                  Reset pkgs from rom"
  echo "      qb_reset_password               Reset qBitorent password"
  echo "      disk_power_mode                 Show disk power status"
  echo "      speedtest                       Start a speedtest"
}

case ${ACTION} in
  "turn_off_ipv6")
    /usr/share/systools/turn_off_ipv6.run
  ;;
  "reset_rom_pkgs")
    /usr/share/systools/reset_rom_pkgs.run
  ;;
  "qb_reset_password")
    /usr/share/systools/qb_reset_password.run
  ;;
  "disk_power_mode")
    /usr/share/systools/disk_power_mode.run
  ;;
  "speedtest")
    /usr/share/systools/speedtest.run ${1}
  ;;
  "openssl-aes256gcm")
    bash "/usr/share/systools/${ACTION}.run"
  ;;
  "openssl-chacha20-poly1305")
    bash "/usr/share/systools/${ACTION}.run"
  ;;
  *)
    usage
    exit 1
  ;;
esac

