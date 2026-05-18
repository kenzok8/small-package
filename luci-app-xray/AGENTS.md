# AGENTS.md

## Repository Shape
- This is an OpenWrt package repository, not a standalone JS app. There is no npm/test runner config in this repo.
- Packages live in `core/`, `geodata/`, and `status/`; each has its own OpenWrt `Makefile` and installs files from its `root/` tree.
- The base package name is `luci-app-xray` from `core/Makefile`; optional packages are `luci-app-xray-geodata` and `luci-app-xray-status`.

## Build / Verification
- Build from an OpenWrt SDK tree with this repo linked as `package/luci-app-xray`, then run `./scripts/feeds update -a`, `./scripts/feeds install -a`, `make defconfig`.
- CI builds only the status target with `make package/luci-app-xray/status/{clean,compile} V=s` on OpenWrt SDK `23.05.5` x86_64; use that command as the closest verified package build smoke test.
- For full local checks, compile the package subdir you changed, for example `make package/luci-app-xray/core/{clean,compile} V=s`, `make package/luci-app-xray/geodata/{clean,compile} V=s`, or `make package/luci-app-xray/status/{clean,compile} V=s`.

## Runtime Wiring
- LuCI views are client-side JS under `*/root/www/luci-static/resources/view/xray/`; menu registration is in `*/root/usr/share/luci/menu.d/*.json`, and ACLs are in `*/root/usr/share/rpcd/acl.d/*.json`.
- Shared LuCI state uses UCI config `xray_core`; `core/root/www/luci-static/resources/view/xray/shared.js` exposes this as `shared.variant`.
- Xray config generation runs on-device via `ucode /usr/share/xray/gen_config.uc`; feature modules live under `core/root/usr/share/xray/feature/`, protocol modules under `core/root/usr/share/xray/protocol/`, and common helpers under `core/root/usr/share/xray/common/`.
- The init script `core/root/etc/init.d/xray_core` generates `/var/etc/xray/config.json`, renders nftables and dnsmasq snippets with `utpl`, restarts firewall/dnsmasq for transparent proxy, and starts Xray with `-confdir /var/etc/xray`.

## Change Gotchas
- When adding installed files, update the relevant package `Makefile` install section; files under `root/` are not automatically packaged.
- When adding or moving a LuCI page, update both the menu JSON and ACL JSON if the page needs UCI, file, or exec access.
- Keep package versions in sync across `core/Makefile`, `geodata/Makefile`, and `status/Makefile` when doing a release version bump.
- README states OpenWrt before `22.03` and Lean's OpenWrt source are unsupported because this package depends on firewall4 and client-side-rendered LuCI.
