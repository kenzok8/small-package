# luci-app-dnsproxy

> [dnsproxy][] is a simple DNS proxy server that supports all existing DNS protocols including
`DNS-over-TLS`, `DNS-over-HTTPS`, `DNSCrypt`, and `DNS-over-QUIC`. Moreover,
it can work as a `DNS-over-HTTPS`, `DNS-over-TLS` or `DNS-over-QUIC` server.

## How to install

1. Go to [here](https://fantastic-packages.github.io/packages/)
2. Download the latest version of ipk
3. Login router and goto **System --> Software**
4. Upload and install ipk
5. Reboot if the app is not automatically added in page
6. Goto **Services --> DNS Proxy**

## Build

Compile from OpenWrt/LEDE SDK

```
# Take the x86_64 platform as an example
tar xjf openwrt-sdk-22.03.5-x86-64_gcc-8.4.0_musl.Linux-x86_64.tar.xz
# Go to the SDK root dir
cd OpenWrt-sdk-*-x86_64_*
# First run to generate a .config file
make menuconfig
./scripts/feeds update -a
./scripts/feeds install -a
# Get Makefile
git clone --depth 1 --branch master --single-branch --no-checkout https://github.com/muink/luci-app-dnsproxy.git package/luci-app-dnsproxy
pushd package/luci-app-dnsproxy
umask 022
git checkout
popd
# Select the package LuCI -> Applications -> luci-app-dnsproxy
make menuconfig
# Start compiling
make package/luci-app-dnsproxy/compile V=99
```

[dnsproxy]: https://github.com/AdguardTeam/dnsproxy

## License

This project is licensed under the [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)
