# luci-app-netdata
1.33.1 汉化（部分）
## 食用方法  
```  
rm -rf ./feeds/luci/applications/luci-app-netdata/  
git clone https://github.com/Jason6111/luci-app-netdata ./feeds/luci/applications/luci-app-netdata/  
```  
也可以用web里文件，覆盖至路径 `/usr/share/netdata/web/` ，请先备份

 -  dashboard_info.js   
 -  dashboard.js   
 -  main.js   
 -  index.html  
  
已经开启了远程查看权，不需要的手动关闭  
`/root/etc/netdata/netdata.conf`  
allow connections from = *  
allow dashboard from = *  
把这两行第一个*删除即可  
# 如发现luci进不去netdata请尝试 连接ssh进入openwrt输入以下指令
```  
mkdir /usr/lib/lua/luci/view/netdata
mv -f /usr/lib/lua/luci/view/netdata.htm /usr/lib/lua/luci/view/netdata/netdata.htm  

```  

# 还原1.33.1（留作以后用）  
```  
rm -rf ./feeds/packages/admin/netdata  
git clone -b 1.33.1 https://github.com/Jason6111/luci-app-netdata ./feeds/packages/admin/netdata  
```
