# luci-app-rtorrent
rTorrent frontend for OpenWrt's LuCI web interface

:new: _2021-06-24: Complete rewrite from scratch ([0.2.x](https://github.com/wolandmaster/luci-app-rtorrent/tree/0.2.x))_

:new: _202?-??-??: Complete rewrite from scratch No.2: this time in JavaScript ([0.3.x](https://github.com/wolandmaster/luci-app-rtorrent/tree/0.3.x))_

## Features
- List all torrent downloads
- Add new torrent by url/magnet uri/file
- Stop/start/pause/hash/delete torrents
- Categorize torrents by tags
- Set priority per file
- Enable/disable and add trackers to torrent
- Detailed peer and chunk listing
- Completely LuCI based interface
- OpenWrt device independent (written in lua)
- Opkg package manager support
- RSS feed downloader (automatically download torrents that match the specified criteria)

## Screenshots
[luci-app-rtorrent 0.2.0](https://github.com/wolandmaster/luci-app-rtorrent/wiki/Screenshots)

## Install instructions

### Install rtorrent-rpc
```
opkg update
opkg install rtorrent-rpc screen
```
### Create rTorrent config file

#### Minimal _/root/.rtorrent.rc_ file (don't forget to update the paths!):
```
directory = /path/to/downloads/
session = /path/to/session/

scgi_port = 127.0.0.1:6000

method.set_key = event.download.erased, on_erase, "branch=d.custom5=,\"execute2={rm,-rf,--,$d.base_path=}\""

schedule2 = rss_downloader, 60, 300, ((execute.throw, /usr/lib/lua/rss_downloader.lua, --uci))
```

### Create _/etc/init.d/rtorrent_ autostart script
```
#!/bin/sh /etc/rc.common

START=99
STOP=99

start() {
  HOME=/root screen -dmS rtorrent nice -19 rtorrent
}

boot() {
  start "$@"
}

stop() {
  killall rtorrent
}
```

### Start rtorrent
```
chmod +x /etc/init.d/rtorrent
/etc/init.d/rtorrent enable
/etc/init.d/rtorrent start
```

### Install luci-app-rtorrent
```
opkg install libustream-wolfssl
wget -q https://github.com/wolandmaster/luci-app-rtorrent/releases/download/latest/e1a1ba8004c4220f -O /etc/opkg/keys/e1a1ba8004c4220f
echo 'src/gz luci_app_rtorrent https://github.com/wolandmaster/luci-app-rtorrent/releases/download/latest' >> /etc/opkg.conf
opkg update
opkg install luci-app-rtorrent
```

### Upgrade already installed version
```
opkg update
opkg upgrade luci-app-rtorrent
```

### References
<https://www.pcsuggest.com/openwrt-torrent-download-box-luci/>

<https://medium.com/openwrt-iot/lede-openwrt-setting-up-torrent-downloading-a06fe37a1ea2>
