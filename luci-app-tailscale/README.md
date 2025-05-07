# luci-app-tailscale

Tailscale is a zero config VPN for building secure networks.

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/asvow/luci-app-tailscale?style=flat-square)](https://github.com/asvow/luci-app-tailscale/releases)
[![GitHub stars](https://img.shields.io/github/stars/asvow/luci-app-tailscale?style=flat-square)](https://github.com/asvow/luci-app-tailscale/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/asvow/luci-app-tailscale?style=flat-square)](https://github.com/asvow/luci-app-tailscale/network/members)
[![License](https://img.shields.io/github/license/asvow/luci-app-tailscale?style=flat-square)](LICENSE)
[![GitHub All Releases](https://img.shields.io/github/downloads/asvow/luci-app-tailscale/total?style=flat-square)](https://github.com/asvow/luci-app-tailscale/releases)

## How to build

- Only compatible with luci2 version

- Enter in your openwrt dir

  *1. replace the default startup script and configuration of Tailscale.*
  ```shell
  sed -i '/\/etc\/init\.d\/tailscale/d;/\/etc\/config\/tailscale/d;' feeds/packages/net/tailscale/Makefile
  ```

  *2. get luci-app-tailscale source & building*
  ```shell
  git clone https://github.com/asvow/luci-app-tailscale package/luci-app-tailscale
  make menuconfig # choose LUCI -> Applications -> luci-app-tailscale
  make package/luci-app-tailscale/compile V=s # luci-app-tailscale
  ```

--------------

## How to install prebuilt packages

- Upload the prebuilt ipk or apk package to the /tmp directory of OpenWrt
- Login OpenWrt terminal (SSH)

### opkg package manager 
  ```shell
  opkg update
  opkg install --force-overwrite /tmp/luci-*-tailscale*.ipk
  ```

### apk package manager 
  ```shell
  apk update
  apk add --allow-untrusted --force-overwrite /tmp/luci-*-tailscale*.apk
  ```

--------------

## Thanks
- [Carseason/openwrt-tailscale](https://github.com/Carseason/openwrt-tailscale)
- [immortalwrt/luci-app-zerotier](https://github.com/immortalwrt/luci/blob/master/applications/luci-app-zerotier)

--------------

## Screenshot
<img width="573" alt="Basic" src="https://github.com/user-attachments/assets/bfca389a-bcec-42de-b5dd-b9588fd5db23" />
<img width="577" alt="Advanced" src="https://github.com/user-attachments/assets/d60ce19e-b3f3-43a7-98fc-7df6e2231898" />
<img width="575" alt="Extra" src="https://github.com/user-attachments/assets/6de5eaa7-6c18-48b8-a44a-0eaa311b0b79" />

