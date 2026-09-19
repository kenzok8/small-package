#!/bin/bash
# 部署 luci-app-pushbot r23 到所有第一批终端

TERMINALS="10.1.0.1 10.2.0.1 10.3.0.1 10.12.0.1 10.13.0.1 10.101.0.1 10.102.0.1 10.103.0.1 10.104.0.1"
MAIN_APK="/home/zed/coding/openwrt/luci-app-pushbot/luci-app-pushbot-5.17-r23.apk"
I18N_APK="/home/zed/coding/openwrt/luci-app-pushbot/luci-i18n-pushbot-zh-cn-5.17-r23.apk"

for ip in $TERMINALS; do
    echo "=========================================="
    echo "部署到 $ip"
    echo "=========================================="
    
    # 1. 卸载旧包（如果存在）
    echo "卸载旧包..."
    ssh -F /dev/null root@$ip "apk del luci-i18n-pushbot-zh-cn luci-app-pushbot 2>&1 || true"
    
    # 2. 传输 apk 文件
    echo "传输 apk 文件..."
    cat $MAIN_APK | ssh -F /dev/null root@$ip "cat > /tmp/luci-app-pushbot-5.17-r23.apk"
    cat $I18N_APK | ssh -F /dev/null root@$ip "cat > /tmp/luci-i18n-pushbot-zh-cn-5.17-r23.apk"
    
    # 3. 验证文件传输
    ssh -F /dev/null root@$ip "ls -lh /tmp/*.apk"
    
    # 4. 安装主包
    echo "安装主包..."
    ssh -F /dev/null root@$ip "apk add --allow-untrusted /tmp/luci-app-pushbot-5.17-r23.apk 2>&1"
    
    # 5. 安装 i18n 包
    echo "安装 i18n 包..."
    ssh -F /dev/null root@$ip "apk add --allow-untrusted /tmp/luci-i18n-pushbot-zh-cn-5.17-r23.apk 2>&1"
    
    # 6. 验证安装
    echo "验证安装..."
    ssh -F /dev/null root@$ip "apk info luci-app-pushbot 2>&1 | head -3"
    
    # 7. 清理临时文件
    ssh -F /dev/null root@$ip "rm -f /tmp/*.apk"
    
    echo ""
done

echo "=========================================="
echo "部署完成"
echo "=========================================="
