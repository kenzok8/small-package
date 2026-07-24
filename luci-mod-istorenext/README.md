## 自定义后端与luci共享session

### 主要流程：
```
1. nginx转发/cgi-bin/luci/istorenext/开头的请求到自定义后端

2. 如果自定义后端返回403，则下一步。否则直接透传，回到步骤1。

3. nginx渲染登录界面，登录URL参数会加上istorenextlogin=1。用户登录时会用POST请求

4. 当nginx收到POST的请求且istorenextlogin=1就转发给luci

5. luci登录失败的话，会返回403，回到步骤3；luci登录成功的话会原地重定向，URL中还是有istorenextlogin=1，但是变成GET请求，到下一步

6. nginx收到GET请求且istorenextlogin=1就再次重定向到没有istorenextlogin=1的URL，回到步骤1，由于已经登录且cookie共享，自定义后端就不会再返回403，除非session过期了

```

### 示例
`./root-demo` 文件夹下包含一个自定义后端的 demo。demo判断登录则渲染200页面，没登录就403。
