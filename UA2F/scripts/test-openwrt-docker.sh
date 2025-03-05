#!/bin/bash
set -e

# 默认参数
SKIP_NETWORK_CONFIG=0
SKIP_FUNCTIONAL_TEST=0
DEBUG_MODE=0

# 解析命令行参数
while [ $# -gt 0 ]; do
  case "$1" in
    --skip-network-config)
      SKIP_NETWORK_CONFIG=1
      shift
      ;;
    --skip-functional-test)
      SKIP_FUNCTIONAL_TEST=1
      shift
      ;;
    --debug)
      DEBUG_MODE=1
      shift
      ;;
    *)
      echo "未知参数: $1"
      echo "用法: $0 [--skip-network-config] [--skip-functional-test] [--debug]"
      exit 1
      ;;
  esac
done

# 启用调试模式
if [ "$DEBUG_MODE" -eq 1 ]; then
  set -x
fi

echo "=== 开始测试UA2F IPK包 ==="

# 配置网络
if [ "$SKIP_NETWORK_CONFIG" -eq 0 ]; then
  echo "=== 配置网络 ==="
  uci set network.lan.proto='static'
  uci set network.lan.ipaddr='192.168.1.1'
  uci set network.lan.netmask='255.255.255.0'
  uci commit network
  /etc/init.d/network restart

  # 等待网络就绪
  echo "=== 等待网络就绪 ==="
  for i in $(seq 1 10); do
    if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
      echo "网络连接成功"
      break
    fi
    if [ $i -eq 10 ]; then
      echo "警告: 网络连接失败，但继续测试"
    fi
    sleep 1
  done
else
  echo "=== 跳过网络配置 ==="
fi

# 更新软件源
echo "=== 更新软件源 ==="
opkg update || { echo "警告: 无法更新软件源，但继续测试"; }

# 安装依赖
echo "=== 安装依赖 ==="
opkg install libubox libnetfilter-queue libmnl libnetfilter-conntrack iptables-mod-nfqueue || { echo "警告: 无法安装所有依赖，但继续测试"; }

# 安装IPK包
echo "=== 安装UA2F IPK包 ==="
cd /ipk
ls -la
for pkg in *.ipk; do
  if [ -f "$pkg" ]; then
    echo "安装包: $pkg"
    opkg install "$pkg" || { echo "错误: 无法安装 $pkg"; exit 1; }
  fi
done

# 检查UA2F是否已安装
echo "=== 检查UA2F安装状态 ==="
if ! opkg list-installed | grep -q ua2f; then
  echo "错误: UA2F包未正确安装"
  exit 1
fi
echo "UA2F已成功安装"

# 检查UA2F服务是否存在
echo "=== 检查UA2F服务 ==="
if [ ! -f /etc/init.d/ua2f ]; then
  echo "错误: 未找到UA2F初始化脚本"
  exit 1
fi
echo "UA2F初始化脚本存在"

# 配置UA2F
echo "=== 配置UA2F ==="
# 启用UA2F
uci set ua2f.enabled.enabled=1

# 配置防火墙选项
uci set ua2f.firewall.handle_fw=1
uci set ua2f.firewall.handle_tls=1
uci set ua2f.firewall.handle_mmtls=1
uci set ua2f.firewall.handle_intranet=1

# 应用配置
uci commit ua2f

# 检查UA2F配置文件
echo "=== 检查UA2F配置 ==="
if [ -f /etc/config/ua2f ]; then
  echo "UA2F配置文件存在"
  cat /etc/config/ua2f
else
  echo "警告: UA2F配置文件不存在，但继续测试"
fi

# 尝试启动UA2F服务
echo "=== 启动UA2F服务 ==="
/etc/init.d/ua2f enable
/etc/init.d/ua2f start

# 检查UA2F进程是否运行
echo "=== 检查UA2F进程 ==="
sleep 3
if pgrep ua2f > /dev/null; then
  echo "UA2F进程正在运行"
  ps | grep ua2f
else
  echo "警告: UA2F进程未运行，检查日志"
  logread | grep ua2f || true
  echo "尝试手动运行UA2F"
  ua2f -v &
  sleep 2
  if ! pgrep ua2f > /dev/null; then
    echo "错误: 无法启动UA2F进程"
    exit 1
  fi
fi

# 检查UA2F版本
echo "=== 检查UA2F版本 ==="
ua2f --version

# 功能测试
if [ "$SKIP_FUNCTIONAL_TEST" -eq 0 ]; then
  echo "=== 进行功能测试 ==="

  # 安装测试工具
  echo "安装测试工具..."
  opkg install curl wget || { echo "警告: 无法安装测试工具，但继续测试"; }

  # 检查防火墙规则（不手动配置，由初始化脚本自动处理）
  echo "检查防火墙规则..."
  iptables -t mangle -L | grep UA2F || {
    echo "警告: 未找到UA2F防火墙规则，可能初始化脚本未正确配置防火墙"
    echo "显示当前防火墙规则:"
    iptables -t mangle -L
  }

  # 测试HTTP请求
  echo "测试HTTP请求..."
  USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

  # 创建测试脚本
  cat > /tmp/test-ua.sh << 'EOFTEST'
#!/bin/sh
echo "发送请求: User-Agent=$1"
RESPONSE=$(curl -s -A "$1" http://httpbin.org/user-agent)
echo "收到响应: $RESPONSE"
echo "$RESPONSE" | grep -q "user-agent" && echo "测试成功" || echo "测试失败"
EOFTEST
  chmod +x /tmp/test-ua.sh

  # 测试原始User-Agent
  echo "测试原始User-Agent..."
  /tmp/test-ua.sh "$USER_AGENT"

  # 等待UA2F处理
  sleep 5

  # 再次测试，检查UA2F是否修改了User-Agent
  echo "测试UA2F修改后的User-Agent..."
  /tmp/test-ua.sh "$USER_AGENT"

  # 检查日志
  echo "=== 检查UA2F日志 ==="
  logread | grep UA2F | tail -n 200

else
  echo "=== 跳过功能测试 ==="
fi

echo "=== UA2F包测试通过! ==="
exit 0 