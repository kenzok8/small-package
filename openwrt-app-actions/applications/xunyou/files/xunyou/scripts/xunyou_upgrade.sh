#!/bin/sh
#参数1 =1 解压升级包 ;参数2:待解压文件
#参数1 =6 restart 程序;参数2：程序路径;参数3:程序名

BasePath=""
XunyouPath=${BasePath}/xunyou
[ ! -d ${XunyouPath} ] && exit 1

case $1 in
    1)
        [ -e "/tmp/$2" ] && cd /tmp/ && tar -xzf $2
        ;;
    6)
        echo "restart the program"
        [ ！ -d "/tmp/xunyou" ] && exit 0
        sh ${XunyouPath}/uninstall.sh upgrade
        sh /tmp/xunyou/install.sh app
        ;;
    *)
        ;;
esac
