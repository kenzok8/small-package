#!/bin/bash
# 安装 i18n 包到所有第一批终端

TERMINALS="10.1.0.1 10.2.0.1 10.3.0.1 10.12.0.1 10.13.0.1 10.101.0.1 10.102.0.1 10.103.0.1 10.104.0.1"
I18N_APK="/home/zed/coding/openwrt/luci-app-pushbot/luci-i18n-pushbot-zh-cn-5.17-r23.apk"

for ip in $TERMINALS; do
    echo "=========================================="
    echo "安装 i18n 到 $ip"
    echo "=========================================="
    
    # 1. 传输 i18n 包
    echo "传输 i18n 包..."
    cat $I18N_APK | ssh -F /dev/null root@$ip "cat > /tmp/luci-i18n-pushbot-zh-cn-5.17-r23.apk"
    
    # 2. 验证文件传输
    ssh -F /dev/null root@$ip "ls -lh /tmp/luci-i18n-pushbot-zh-cn-5.17-r23.apk"
    
    # 3. 安装 i18n 包
    echo "安装 i18n 包..."
    ssh -F /dev/null root@$ip "apk add --allow-untrusted /tmp/luci-i18n-pushbot-zh-cn-5.17-r23.apk 2>&1"
    
    # 4. 验证安装
    echo "验证安装..."
    ssh -F /dev/null root@$ip "apk info luci-i18n-pushbot-zh-cn 2>&1 | head -3"
    
    # 5. 清理临时文件
    ssh -F /dev/null root@$ip "rm -f /tmp/luci-i18n-pushbot-zh-cn-5.17-r23.apk"
    
    echo ""
done

echo "=========================================="
echo "i18n 包安装完成"
echo "=========================================="
