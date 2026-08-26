# luci-theme-istorenas

Argon 主题，但修改登录界面，并且可配置默认登录后跳转路径。

### 修改登录后默认跳转路径

例如
```bash
cat >/etc/config/istorenas <<-EOF
config login
    option landing_page "/cgi-bin/luci/istorenas/landing"
EOF
```

注意 `landing_page` 需要以 `/cgi-bin/luci/` 开头，如果需要跳转到其他位置，可以在 landing 页面再重定向。

注意 `landing_page` 必须在 Luci 中注册，不能是 404，不然无法登录。
