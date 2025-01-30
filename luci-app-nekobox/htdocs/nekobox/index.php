<?php
include './cfg.php';
date_default_timezone_set('Asia/Shanghai');
$str_cfg = substr($selected_config, strlen("$neko_dir/config") + 1);
$_IMG = '/luci-static/ssr/';
$singbox_bin = '/usr/bin/sing-box';
$singbox_log = '/var/log/singbox_log.txt';
$singbox_config_dir = '/etc/neko/config';
$log = '/etc/neko/tmp/log.txt';
$start_script_path = '/etc/neko/core/start.sh';

$log_dir = dirname($log);
if (!file_exists($log_dir)) {
    mkdir($log_dir, 0755, true);
}

$start_script_template = <<<'EOF'
#!/bin/bash

export ENABLE_DEPRECATED_TUN_ADDRESS_X=true 

SINGBOX_LOG="%s"
CONFIG_FILE="%s"
SINGBOX_BIN="%s"
FIREWALL_LOG="%s"

mkdir -p "$(dirname "$SINGBOX_LOG")"
mkdir -p "$(dirname "$FIREWALL_LOG")"
touch "$SINGBOX_LOG"
touch "$FIREWALL_LOG"
chmod 644 "$SINGBOX_LOG"
chmod 644 "$FIREWALL_LOG"

exec >> "$SINGBOX_LOG" 2>&1

log() {
    echo "[$(date)] $1" >> "$FIREWALL_LOG"
}

log "Starting Sing-box with config: $CONFIG_FILE"

log "Restarting firewall..."
/etc/init.d/firewall restart
sleep 2

if command -v fw4 > /dev/null; then
    log "FW4 Detected. Starting nftables."

    nft flush ruleset
    
    nft -f - <<'NFTABLES'
flush ruleset

table inet singbox {
  set local_ipv4 {
    type ipv4_addr
    flags interval
    elements = {
      10.0.0.0/8,
      127.0.0.0/8,
      169.254.0.0/16,
      172.16.0.0/12,
      192.168.0.0/16,
      240.0.0.0/4
    }
  }

  set local_ipv6 {
    type ipv6_addr
    flags interval
    elements = {
      ::ffff:0.0.0.0/96,
      64:ff9b::/96,
      100::/64,
      2001::/32,
      2001:10::/28,
      2001:20::/28,
      2001:db8::/32,
      2002::/16,
      fc00::/7,
      fe80::/10
    }
  }

  chain singbox-tproxy {
    fib daddr type { unspec, local, anycast, multicast } return
    ip daddr @local_ipv4 return
    ip6 daddr @local_ipv6 return
    udp dport { 123 } return
    meta l4proto { tcp, udp } meta mark set 1 tproxy to :9888 accept
  }

  chain singbox-mark {
    fib daddr type { unspec, local, anycast, multicast } return
    ip daddr @local_ipv4 return
    ip6 daddr @local_ipv6 return
    udp dport { 123 } return
    meta mark set 1
  }

  chain mangle-output {
    type route hook output priority mangle; policy accept;
    meta l4proto { tcp, udp } skgid != 1 ct direction original goto singbox-mark
  }

  chain mangle-prerouting {
    type filter hook prerouting priority mangle; policy accept;
    iifname { lo, eth0 } meta l4proto { tcp, udp } ct direction original goto singbox-tproxy
  }
}
NFTABLES

elif command -v fw3 > /dev/null; then
    log "FW3 Detected. Starting iptables."

    iptables -t mangle -F
    iptables -t mangle -X
    iptables -t mangle -N singbox-mark
    iptables -t mangle -A singbox-mark -m addrtype --dst-type UNSPEC,LOCAL,ANYCAST,MULTICAST -j RETURN
    iptables -t mangle -A singbox-mark -d 10.0.0.0/8 -j RETURN
    iptables -t mangle -A singbox-mark -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A singbox-mark -d 169.254.0.0/16 -j RETURN
    iptables -t mangle -A singbox-mark -d 172.16.0.0/12 -j RETURN
    iptables -t mangle -A singbox-mark -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A singbox-mark -d 240.0.0.0/4 -j RETURN
    iptables -t mangle -A singbox-mark -p udp --dport 123 -j RETURN
    iptables -t mangle -A singbox-mark -j MARK --set-mark 1

    iptables -t mangle -N singbox-tproxy
    iptables -t mangle -A singbox-tproxy -m addrtype --dst-type UNSPEC,LOCAL,ANYCAST,MULTICAST -j RETURN
    iptables -t mangle -A singbox-tproxy -d 10.0.0.0/8 -j RETURN
    iptables -t mangle -A singbox-tproxy -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A singbox-tproxy -d 169.254.0.0/16 -j RETURN
    iptables -t mangle -A singbox-tproxy -d 172.16.0.0/12 -j RETURN
    iptables -t mangle -A singbox-tproxy -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A singbox-tproxy -d 240.0.0.0/4 -j RETURN
    iptables -t mangle -A singbox-tproxy -p udp --dport 123 -j RETURN
    iptables -t mangle -A singbox-tproxy -p tcp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 9888
    iptables -t mangle -A singbox-tproxy -p udp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 9888

    iptables -t mangle -A OUTPUT -p tcp -m cgroup ! --cgroup 1 -j singbox-mark
    iptables -t mangle -A OUTPUT -p udp -m cgroup ! --cgroup 1 -j singbox-mark
    iptables -t mangle -A PREROUTING -i lo -p tcp -j singbox-tproxy
    iptables -t mangle -A PREROUTING -i lo -p udp -j singbox-tproxy
    iptables -t mangle -A PREROUTING -i eth0 -p tcp -j singbox-tproxy
    iptables -t mangle -A PREROUTING -i eth0 -p udp -j singbox-tproxy

    ip6tables -t mangle -N singbox-mark
    ip6tables -t mangle -A singbox-mark -m addrtype --dst-type UNSPEC,LOCAL,ANYCAST,MULTICAST -j RETURN
    ip6tables -t mangle -A singbox-mark -d ::ffff:0.0.0.0/96 -j RETURN
    ip6tables -t mangle -A singbox-mark -d 64:ff9b::/96 -j RETURN
    ip6tables -t mangle -A singbox-mark -d 100::/64 -j RETURN
    ip6tables -t mangle -A singbox-mark -d 2001::/32 -j RETURN
    ip6tables -t mangle -A singbox-mark -d 2001:10::/28 -j RETURN
    ip6tables -t mangle -A singbox-mark -d 2001:20::/28 -j RETURN
    ip6tables -t mangle -A singbox-mark -d 2001:db8::/32 -j RETURN
    ip6tables -t mangle -A singbox-mark -d 2002::/16 -j RETURN
    ip6tables -t mangle -A singbox-mark -d fc00::/7 -j RETURN
    ip6tables -t mangle -A singbox-mark -d fe80::/10 -j RETURN
    ip6tables -t mangle -A singbox-mark -p udp --dport 123 -j RETURN
    ip6tables -t mangle -A singbox-mark -j MARK --set-mark 1

    ip6tables -t mangle -N singbox-tproxy
    ip6tables -t mangle -A singbox-tproxy -m addrtype --dst-type UNSPEC,LOCAL,ANYCAST,MULTICAST -j RETURN
    ip6tables -t mangle -A singbox-tproxy -d ::ffff:0.0.0.0/96 -j RETURN
    ip6tables -t mangle -A singbox-tproxy -d 64:ff9b::/96 -j RETURN
    ip6tables -t mangle -A singbox-tproxy -d 100::/64 -j RETURN
    ip6tables -t mangle -A singbox-tproxy -d 2001::/32 -j RETURN
    ip6tables -t mangle -A singbox-tproxy -d 2001:10::/28 -j RETURN
    ip6tables -t mangle -A singbox-tproxy -d 2001:20::/28 -j RETURN
    ip6tables -t mangle -A singbox-tproxy -d 2001:db8::/32 -j RETURN
    ip6tables -t mangle -A singbox-tproxy -d 2002::/16 -j RETURN
    ip6tables -t mangle -A singbox-tproxy -d fc00::/7 -j RETURN
    ip6tables -t mangle -A singbox-tproxy -d fe80::/10 -j RETURN
    ip6tables -t mangle -A singbox-tproxy -p udp --dport 123 -j RETURN
    ip6tables -t mangle -A singbox-tproxy -p tcp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 9888
    ip6tables -t mangle -A singbox-tproxy -p udp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 9888

    ip6tables -t mangle -A OUTPUT -p tcp -m cgroup ! --cgroup 1 -j singbox-mark
    ip6tables -t mangle -A OUTPUT -p udp -m cgroup ! --cgroup 1 -j singbox-mark
    ip6tables -t mangle -A PREROUTING -i lo -p tcp -j singbox-tproxy
    ip6tables -t mangle -A PREROUTING -i lo -p udp -j singbox-tproxy
    ip6tables -t mangle -A PREROUTING -i eth0 -p tcp -j singbox-tproxy
    ip6tables -t mangle -A PREROUTING -i eth0 -p udp -j singbox-tproxy

else
    log "Neither fw3 nor fw4 detected, unable to configure firewall rules."
    exit 1
fi

log "Firewall rules applied successfully"
log "Starting sing-box with config: $CONFIG_FILE"
exec "$SINGBOX_BIN" run -c "$CONFIG_FILE"
EOF;

function createStartScript($configFile) {
    global $start_script_template, $singbox_bin, $singbox_log, $log; 
    $script = sprintf($start_script_template, $singbox_log, $configFile, $singbox_bin, $log);
    
    $dir = dirname('/etc/neko/core/start.sh');
    if (!file_exists($dir)) {
        mkdir($dir, 0755, true);
    }
    
    file_put_contents('/etc/neko/core/start.sh', $script);
    chmod('/etc/neko/core/start.sh', 0755);
    
    //writeToLog("Created start script with config: $configFile");
    //writeToLog("Singbox binary: $singbox_bin");
    //writeToLog("Log file: $singbox_log"); 
    //writeToLog("Firewall log file: $log");
}

function writeToLog($message) {
    global $log;
    $dateTime = new DateTime();  
    $time = $dateTime->format('H:i:s'); 
    $logMessage = "[ $time ] $message\n";
    if (file_put_contents($log, $logMessage, FILE_APPEND) === false) {
        error_log("Failed to write to log file: $log");
    }
}

function createCronScript() {
    $log_file = '/var/log/singbox_log.txt';
    $tmp_log_file = '/etc/neko/tmp/neko_log.txt'; 
    $additional_log_file = '/etc/neko/tmp/log.txt'; 
    $max_size = 1048576;  
    $cron_schedule = "0 */4 * * * /bin/bash /etc/neko/core/set_cron.sh"; 
    $cronScriptContent = <<<EOL
#!/bin/bash

LOG_FILE="$log_file"
TMP_LOG_FILE="$tmp_log_file"  
ADDITIONAL_LOG_FILE="$additional_log_file"
MAX_SIZE=$max_size
LOG_PATH="/etc/neko/tmp/log.txt" 

crontab -l | grep -v "/etc/neko/core/set_cron.sh" | crontab - 
(crontab -l 2>/dev/null; echo "$cron_schedule") | crontab -

timestamp() {
    date "+[ %H:%M:%S ]"
}

if [ -f "\$LOG_FILE" ] && [ \$(stat -c %s "\$LOG_FILE") -gt \$MAX_SIZE ]; then
    echo "\$(timestamp) Sing-box 日志文件 (\$LOG_FILE) 超过 \$MAX_SIZE 字节. 清理日志..." >> \$LOG_PATH 2>&1
    > "\$LOG_FILE"  
    echo "\$(timestamp) Sing-box 日志文件 (\$LOG_FILE) 已清空." >> \$LOG_PATH 2>&1
else
    echo "\$(timestamp) Sing-box 日志文件 (\$LOG_FILE) 在大小限制内, 无需操作." >> \$LOG_PATH 2>&1
fi

if [ -f "\$TMP_LOG_FILE" ] && [ \$(stat -c %s "\$TMP_LOG_FILE") -gt \$MAX_SIZE ]; then
    echo "\$(timestamp) Mihomo 日志文件 (\$TMP_LOG_FILE) 超过 \$MAX_SIZE 字节. 清理日志..." >> \$LOG_PATH 2>&1
    > "\$TMP_LOG_FILE"  
    echo "\$(timestamp) Mihomo 日志文件 (\$TMP_LOG_FILE) 已清空." >> \$LOG_PATH 2>&1
else
    echo "\$(timestamp) Mihomo 日志文件 (\$TMP_LOG_FILE) 在大小限制内, 无需操作." >> \$LOG_PATH 2>&1
fi

if [ -f "\$ADDITIONAL_LOG_FILE" ] && [ \$(stat -c %s "\$ADDITIONAL_LOG_FILE") -gt \$MAX_SIZE ]; then
    echo "\$(timestamp) NeKoBox 日志文件 (\$ADDITIONAL_LOG_FILE) 超过 \$MAX_SIZE 字节. 清理日志..." >> \$LOG_PATH 2>&1
    > "\$ADDITIONAL_LOG_FILE"
    echo "\$(timestamp) NeKoBox 日志文件 (\$ADDITIONAL_LOG_FILE) 已清空." >> \$LOG_PATH 2>&1
else
    echo "\$(timestamp) NeKoBox 日志文件 (\$ADDITIONAL_LOG_FILE) 在大小限制内, 无需操作." >> \$LOG_PATH 2>&1
fi

echo "\$(timestamp) 日志轮换完成." >> \$LOG_PATH 2>&1
EOL;

    $cronScriptPath = '/etc/neko/core/set_cron.sh';
    file_put_contents($cronScriptPath, $cronScriptContent);
    chmod($cronScriptPath, 0755);
    shell_exec("sh $cronScriptPath");
    echo '<div id="cron-success-message" style="display: none;" class="alert alert-success">已创建并执行定时任务脚本，添加或更新日志清理任务，清理 $log_file 和 $tmp_log_file 的日志。</div>';
}

function rotateLogs($logFile, $maxSize = 1048576) {
    if (file_exists($logFile) && filesize($logFile) > $maxSize) {
        file_put_contents($logFile, '');
        chmod($logFile, 0644);      
       // echo "Log file cleared successfully.\n";
    }
}

function isSingboxRunning() {
   global $singbox_bin;
   $command = "pgrep -f " . escapeshellarg($singbox_bin);
   exec($command, $output);
   return !empty($output);
}

function isNekoBoxRunning() {
    global $neko_dir;
    $pid = trim(shell_exec("cat $neko_dir/tmp/neko.pid 2>/dev/null"));
    return !empty($pid) && file_exists("/proc/$pid");
}

function getSingboxPID() {
   global $singbox_bin;
   $command = "pgrep -f " . escapeshellarg($singbox_bin);
   exec($command, $output);
   return isset($output[0]) ? $output[0] : null;
}

function getRunningConfigFile() {
   global $singbox_bin;
   $command = "ps w | grep '$singbox_bin' | grep -v grep";
   exec($command, $output);
   foreach ($output as $line) {
       if (strpos($line, '-c') !== false) {
           $parts = explode('-c', $line);
           if (isset($parts[1])) {
               $configPath = trim(explode(' ', trim($parts[1]))[0]);
               return $configPath;
           }
       }
   }
   return null;
}

function getAvailableConfigFiles() {
   global $singbox_config_dir;
   return glob("$singbox_config_dir/*.json");
}

$availableConfigs = getAvailableConfigFiles();

//writeToLog("Script started");

if(isset($_POST['neko'])){
   $dt = $_POST['neko'];
   writeToLog("Received neko action: $dt");
   if ($dt == 'start') {
       if (isSingboxRunning()) {
           writeToLog("Cannot start NekoBox: Sing-box is running");
       } else {
           shell_exec("$neko_dir/core/neko -s");
           writeToLog("Mihomo started successfully");
       }
   }
   if ($dt == 'disable') {
       shell_exec("$neko_dir/core/neko -k");
       writeToLog("Mihomo stopped");
   }
   if ($dt == 'restart') {
       if (isSingboxRunning()) {
           writeToLog("Cannot restart NekoBox: Sing-box is running");
       } else {
           shell_exec("$neko_dir/core/neko -r");
           writeToLog("Mihomo restarted successfully");
       }
   }
   if ($dt == 'clear') {
       shell_exec("echo \"Logs has been cleared...\" > $neko_dir/tmp/neko_log.txt");
       writeToLog("Mihomo logs cleared");
   }
   writeToLog("Neko action completed: $dt");
}

if (isset($_POST['singbox'])) {
   $action = $_POST['singbox'];
   $config_file = isset($_POST['config_file']) ? $_POST['config_file'] : '';
   
   writeToLog("Received singbox action: $action");
   //writeToLog("Config file: $config_file");
   
   switch ($action) {
       case 'start':
           if (isNekoBoxRunning()) {
               writeToLog("Cannot start Sing-box: NekoBox is running");
           } else {
               writeToLog("Starting Sing-box");

               $singbox_version = trim(shell_exec("$singbox_bin version"));
               writeToLog("Sing-box version: $singbox_version");
               
               shell_exec("mkdir -p " . dirname($singbox_log));
               shell_exec("touch $singbox_log && chmod 644 $singbox_log");
               rotateLogs($singbox_log);
               
               createStartScript($config_file);
               createCronScript();
               $output = shell_exec("sh $start_script_path >> $singbox_log 2>&1 &");
               //writeToLog("Shell output: " . ($output ?: "No output"));
               
               sleep(3);
               $pid = getSingboxPID();
               if ($pid) {
                   writeToLog("Sing-box Started successfully. PID: $pid");
               } else {
                   writeToLog("Failed to start Sing-box");
               }
           }
           break;
           
       case 'disable':
           writeToLog("Stopping Sing-box");
           $pid = getSingboxPID();
           if ($pid) {
               writeToLog("Killing Sing-box PID: $pid");
               shell_exec("kill $pid");
               if (file_exists('/usr/sbin/fw4')) {
                   shell_exec("nft flush ruleset");
               } else {
                   shell_exec("iptables -t mangle -F");
                   shell_exec("iptables -t mangle -X");
           }
               shell_exec("/etc/init.d/firewall restart");
               writeToLog("Cleared firewall rules and restarted firewall");
               sleep(1);
               if (!isSingboxRunning()) {
                   writeToLog("Sing-box has been stopped successfully");
               } else {
                   writeToLog("Force killing Sing-box");
                   shell_exec("kill -9 $pid");
                   writeToLog("Sing-box has been force stopped");
               }
           } else {
               writeToLog("Sing-box is not running");
           }
           break;
           
       case 'restart':
           if (isNekoBoxRunning()) {
               writeToLog("Cannot restart Sing-box: NekoBox is running");
           } else {
               writeToLog("Restarting Sing-box");
               
               $pid = getSingboxPID();
               if ($pid) {
                   writeToLog("Killing Sing-box PID: $pid");
                   shell_exec("kill $pid");
                   sleep(1);
               }
               
               shell_exec("mkdir -p " . dirname($singbox_log));
               shell_exec("touch $singbox_log && chmod 644 $singbox_log");
               rotateLogs($singbox_log);
               
               createStartScript($config_file);
               shell_exec("sh $start_script_path >> $singbox_log 2>&1 &");
               
               sleep(3);
               $new_pid = getSingboxPID();
               if ($new_pid) {
                   writeToLog("Sing-box Restarted successfully. New PID: $new_pid");
               } else {
                   writeToLog("Failed to restart Sing-box");
               }
           }
           break;
   }
   
   sleep(2);
   
   $singbox_status = isSingboxRunning() ? '1' : '0';
   exec("uci set neko.cfg.singbox_enabled='$singbox_status'");
   exec("uci commit neko");
   //writeToLog("Singbox status set to: $singbox_status");
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['cronTime'])) {
    $cronTime = $_POST['cronTime'];

    if (empty($cronTime)) {
        $logMessage = "请提供有效的 Cron 时间格式！";
        file_put_contents('/etc/neko/tmp/log.txt', date('Y-m-d H:i:s') . " - ERROR: $logMessage\n", FILE_APPEND);
        echo $logMessage;
        exit;
    }

    $startScriptPath = '/etc/neko/core/start.sh';

    if (!file_exists('/etc/neko/tmp')) {
        mkdir('/etc/neko/tmp', 0755, true);  
    }

    $restartScriptContent = <<<EOL
#!/bin/bash
LOG_PATH="/etc/neko/tmp/log.txt"

timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

MAX_RETRIES=5
RETRY_INTERVAL=5  

start_singbox() {
    sh /etc/neko/core/start.sh  
}

check_singbox() {
    pgrep -x "singbox" > /dev/null
    return $?
}

if pgrep -x "singbox" > /dev/null
then
    echo "$(timestamp) Sing-box 正在运行，正在重启..." >> \$LOG_PATH
    kill $(pgrep -x "singbox")
    sleep 2
    start_singbox  

    RETRY_COUNT=0
    while ! check_singbox && [ \$RETRY_COUNT -lt \$MAX_RETRIES ]; do
        echo "$(timestamp) Sing-box 重启失败，正在尝试重新启动... (\$((RETRY_COUNT + 1))/\$MAX_RETRIES)" >> \$LOG_PATH
        sleep \$RETRY_INTERVAL
        start_singbox  
        ((RETRY_COUNT++))
    done

    if check_singbox; then
        echo "$(timestamp) Sing-box 重启成功!" >> \$LOG_PATH
    else
        echo "$(timestamp) Sing-box 重启失败，已达到最大重试次数!" >> \$LOG_PATH
    fi
else
    echo "$(timestamp) Sing-box 没有运行, 启动 Sing-box..." >> \$LOG_PATH
    start_singbox  

    RETRY_COUNT=0
    while ! check_singbox && [ \$RETRY_COUNT -lt \$MAX_RETRIES ]; do
        echo "$(timestamp) Sing-box 启动失败，正在尝试重新启动... (\$((RETRY_COUNT + 1))/\$MAX_RETRIES)" >> \$LOG_PATH
        sleep \$RETRY_INTERVAL
        start_singbox  
        ((RETRY_COUNT++))
    done

    if check_singbox; then
        echo "$(timestamp) Sing-box 启动成功!" >> \$LOG_PATH
    else
        echo "$(timestamp) Sing-box 启动失败，已达到最大重试次数!" >> \$LOG_PATH
    fi
fi
EOL;

    $scriptPath = '/etc/neko/core/restart_singbox.sh';
    file_put_contents($scriptPath, $restartScriptContent);
    chmod($scriptPath, 0755);

    $cronSchedule = $cronTime . " /bin/bash $scriptPath";
    exec("crontab -l | grep -v '$scriptPath' | crontab -"); 
    exec("(crontab -l 2>/dev/null; echo \"$cronSchedule\") | crontab -");  

    $logMessage = "定时任务已设置成功，Sing-box 将在 $cronTime 自动重启。";
    file_put_contents('/etc/neko/tmp/log.txt', date('[ H:i:s ] ') . "$logMessage\n", FILE_APPEND);
    echo json_encode(['success' => true, 'message' => '定时任务已设置成功']);
    exit;
}

if (isset($_POST['clear_singbox_log'])) {
   file_put_contents($singbox_log, '');
   writeToLog("Singbox log cleared");
}

if (isset($_POST['clear_plugin_log'])) {
    $plugin_log_file = "$neko_dir/tmp/log.txt";
    file_put_contents($plugin_log_file, '');
    writeToLog("Nekobox log cleared");
}

$neko_status = exec("uci -q get neko.cfg.enabled");
$singbox_status = isSingboxRunning() ? '1' : '0';
exec("uci set neko.cfg.singbox_enabled='$singbox_status'");
exec("uci commit neko");

//writeToLog("Final neko status: $neko_status");
//writeToLog("Final singbox status: $singbox_status");

if ($singbox_status == '1') {
   $runningConfigFile = getRunningConfigFile();
   if ($runningConfigFile) {
       $str_cfg = htmlspecialchars(basename($runningConfigFile));
       //writeToLog("Running config file: $str_cfg");
   } else {
       $str_cfg = 'Sing-box 配置文件：未找到运行中的配置文件';
       writeToLog("No running config file found");
   }
}

function readRecentLogLines($filePath, $lines = 1000) {
   if (!file_exists($filePath)) {
       return "日志文件不存在: $filePath";
   }
   if (!is_readable($filePath)) {
       return "无法读取日志文件: $filePath";
   }
   $command = "tail -n $lines " . escapeshellarg($filePath);
   $output = shell_exec($command);
   return $output ?: "日志为空";
}

function readLogFile($filePath) {
   if (file_exists($filePath)) {
       return nl2br(htmlspecialchars(readRecentLogLines($filePath, 1000), ENT_NOQUOTES));
   } else {
       return '日志文件不存在。';
   }
}

$neko_log_content = readLogFile("$neko_dir/tmp/neko_log.txt");
$singbox_log_content = readLogFile($singbox_log);
?>

<?php
$isNginx = false;
if (isset($_SERVER['SERVER_SOFTWARE']) && strpos($_SERVER['SERVER_SOFTWARE'], 'nginx') !== false) {
    $isNginx = true;
}
?>

<?php
if (isset($_GET['ajax'])) {
    $dt = json_decode(shell_exec("ubus call system board"), true);
    $devices = $dt['model'];

    $kernelv = exec("cat /proc/sys/kernel/ostype"); 
    $osrelease = exec("cat /proc/sys/kernel/osrelease"); 
    $OSVer = $dt['release']['distribution'] . ' ' . $dt['release']['version']; 
    $kernelParts = explode('.', $osrelease, 3);
    $kernelv = 'Linux ' . 
               (isset($kernelParts[0]) ? $kernelParts[0] : '') . '.' . 
               (isset($kernelParts[1]) ? $kernelParts[1] : '') . '.' . 
               (isset($kernelParts[2]) ? $kernelParts[2] : '');
    $kernelv = strstr($kernelv, '-', true) ?: $kernelv;
    $fullOSInfo = $kernelv . ' ' . $OSVer;

    $tmpramTotal = exec("cat /proc/meminfo | grep MemTotal | awk '{print $2}'");
    $tmpramAvailable = exec("cat /proc/meminfo | grep MemAvailable | awk '{print $2}'");

    $ramTotal = number_format(($tmpramTotal / 1000), 1);
    $ramAvailable = number_format(($tmpramAvailable / 1000), 1);
    $ramUsage = number_format((($tmpramTotal - $tmpramAvailable) / 1000), 1);

    $raw_uptime = exec("cat /proc/uptime | awk '{print $1}'");
    $days = floor($raw_uptime / 86400);
    $hours = floor(($raw_uptime / 3600) % 24);
    $minutes = floor(($raw_uptime / 60) % 60);
    $seconds = $raw_uptime % 60;

    $cpuLoad = shell_exec("cat /proc/loadavg");
    $cpuLoad = explode(' ', $cpuLoad);
    $cpuLoadAvg1Min = round($cpuLoad[0], 2);
    $cpuLoadAvg5Min = round($cpuLoad[1], 2);
    $cpuLoadAvg15Min = round($cpuLoad[2], 2);

    echo json_encode([
        'systemInfo' => "$devices - $fullOSInfo",
        'ramUsage' => "$ramUsage/$ramTotal MB",
        'cpuLoad' => "$cpuLoadAvg1Min $cpuLoadAvg5Min $cpuLoadAvg15Min",
        'uptime' => "{$days}天 {$hours}小时 {$minutes}分钟 {$seconds}秒",
        'cpuLoadAvg1Min' => $cpuLoadAvg1Min,
        'ramTotal' => $ramTotal,
        'ramUsageOnly' => $ramUsage,
    ]);
    exit;
}
?>
<?php
$default_config = '/etc/neko/config/mihomo.yaml';

$current_config = file_exists('/www/nekobox/lib/selected_config.txt') 
    ? trim(file_get_contents('/www/nekobox/lib/selected_config.txt')) 
    : $default_config;

if (!file_exists($current_config)) {
    $default_config_content = "external-controller: 0.0.0.0:9090\n";
    $default_config_content .= "secret: Akun\n";
    $default_config_content .= "external-ui: ui\n";
    $default_config_content .= "# 请根据需要编辑此文件\n";
    
    file_put_contents($current_config, $default_config_content);
    file_put_contents('/www/nekobox/lib/selected_config.txt', $current_config);

    $logMessage = "配置文件丢失，已创建默认配置文件。";
} else {
    $config_content = file_get_contents($current_config);

    $missing_config = false;
    $default_config_content = [
        "external-controller" => "0.0.0.0:9090",
        "secret" => "Akun",
        "external-ui" => "ui"
    ];

    foreach ($default_config_content as $key => $value) {
        if (strpos($config_content, "$key:") === false) {
            $config_content .= "$key: $value\n"; 
            $missing_config = true;
        }
    }

    if ($missing_config) {
        file_put_contents($current_config, $config_content);
        $logMessage = "配置文件缺少某些选项，已自动添加缺失的配置项。";
    }
}

if (isset($logMessage)) {
    echo "<script>alert('$logMessage');</script>";
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['selected_config'])) {
    $selected_file = $_POST['selected_config'];
    $config_dir = '/etc/neko/config';
    $selected_file_path = $config_dir . '/' . $selected_file;

    if (file_exists($selected_file_path) && pathinfo($selected_file, PATHINFO_EXTENSION) == 'yaml') {
        file_put_contents('/www/nekobox/lib/selected_config.txt', $selected_file_path);
    } else {
        echo "<script>alert('无效的配置文件');</script>";
    }
}
?>

<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme,0,-4) ?>">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Home - Nekobox</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <link href="./assets/bootstrap/bootstrap-icons.css" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/neko.js"></script>
    <script type="text/javascript" src="./assets/bootstrap/bootstrap.min.js"></script>
    <script src="./assets/js/bootstrap.bundle.min.js"></script>
    <?php include './ping.php'; ?>
  </head>
<body>
    <?php if ($isNginx): ?>
    <div id="nginxWarning" class="alert alert-warning alert-dismissible fade show" role="alert" style="position: fixed; top: 20px; left: 50%; transform: translateX(-50%); z-index: 1050;">
        <strong>警告！</strong> 检测到您正在使用Nginx。本插件不支持Nginx，请使用Uhttpd构建固件。
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
    <script>
    setTimeout(function() {
        var warningAlert = document.getElementById('nginxWarning');
        if (warningAlert) {
            warningAlert.classList.remove('show');
            setTimeout(function() {
                warningAlert.remove();
            }, 300);
        }
    }, 5000);
    </script>
    <?php endif; ?>
<div class="container-sm container-bg callout border border-3 rounded-4 col-11">
    <div class="row">
            <a href="./index.php" class="col btn btn-lg"><i class="bi bi-house-door"></i> 首页</a>
            <a href="./dashboard.php" class="col btn btn-lg"><i class="bi bi-bar-chart"></i> 面板</a>
            <a href="./singbox.php" class="col btn btn-lg"><i class="bi bi-box"></i> 订阅</a> 
            <a href="./settings.php" class="col btn btn-lg"><i class="bi bi-gear"></i> 设定</a>
    <div class="container-sm text-center col-8">
  <img src="./assets/img/nekobox.png">
<div id="version-info">
    <a id="version-link" href="https://github.com/Thaolga/openwrt-nekobox/releases" target="_blank">
        <img id="current-version" src="./assets/img/curent.svg" alt="Current Version" style="max-width: 100%; height: auto;" />
    </a>
</div>
</div>
<script>
$(document).ready(function() {
    $.ajax({
        url: 'check_update.php',
        method: 'GET',
        dataType: 'json',
        success: function(data) {
            if (data.hasUpdate) {
                $('#current-version').attr('src', 'https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/refs/heads/nekobox/luci-app-nekobox/htdocs/nekobox/assets/img/Latest.svg');
            }

            console.log('Current Version:', data.currentVersion);
            console.log('Latest Version:', data.latestVersion);
            console.log('Has Update:', data.hasUpdate);
        },
        error: function(jqXHR, textStatus, errorThrown) {
            //$('#version-info').text('Error fetching version information');
            console.error('AJAX Error:', textStatus, errorThrown);
        }
    });
});
</script>
<h2 class="royal-style">NekoBox</h2>
<style>

    .nav-pills .nav-link {
        background-color: transparent !important;
        color: inherit;
        font-size: 1.25rem; 
    }

    .nav-pills .nav-link.active {
        background-color: transparent !important; 
        font-size: 1.25rem; 
    }

   .section-container {
       padding-left: 42px;  
       padding-right: 42px;
   }

   .btn-group .btn {
       width: 120%;
   }

   .log-container {
       height: 270px; 
       overflow-y: auto;
       overflow-x: hidden;
       white-space: pre-wrap;
       word-wrap: break-word;
   }

   .log-card {
       margin-bottom: 20px;
   }

   @media (max-width: 768px) {
      .section-container {
         padding-left: 15px;
         padding-right: 15px;
      }
   }

   @media (max-width: 768px) {
      tr {
          margin-bottom: 15px;
          display: block;
      }
   }
</style>
<div class="section-container">
   <table class="table table-borderless mb-2">
       <tbody>
           <tr>
               <td style="width:150px">运行状态</td>
               <td class="d-grid">
                   <div class="btn-group w-100" role="group" aria-label="ctrl">
                       <?php
                       if ($neko_status == 1) {
                           echo "<button type=\"button\" class=\"btn btn-success\">Mihomo 运行中</button>\n";
                       } else {
                           echo "<button type=\"button\" class=\"btn btn-outline-danger\">Mihomo 未运行</button>\n";
                       }
                       echo "<button type=\"button\" class=\"btn btn-deepskyblue\">$str_cfg</button>\n";
                       if ($singbox_status == 1) {
                           echo "<button type=\"button\" class=\"btn btn-success\">Sing-box 运行中</button>\n";
                       } else {
                           echo "<button type=\"button\" class=\"btn btn-outline-danger\">Sing-box 未运行</button>\n";
                       }
                       ?>
                   </div>
               </td>
           </tr>
            <tr>
               <td style="width:150px">Mihomo 控制</td>
               <td class="d-grid">
                   <form action="index.php" method="post" style="display: inline-block; width: 100%; margin-bottom: 10px;">
                       <div class="form-group">
                           <select id="configSelect" class="form-select" name="selected_config" onchange="saveConfigToLocalStorage(); this.form.submit()">
                               <option value="">请选择配置文件</option> 
                               <?php
                                   $config_dir = '/etc/neko/config';
                                   $files = array_diff(scandir($config_dir), array('..', '.')); 
                                   foreach ($files as $file) {
                                       if (pathinfo($file, PATHINFO_EXTENSION) == 'yaml') {
                                           $selected = (realpath($config_dir . '/' . $file) == realpath($current_config)) ? 'selected' : '';  
                                           echo "<option value='$file' $selected>$file</option>";
                                       }
                                   }
                               ?>
                           </select>
                       </div>
                    </form>
                   <form action="index.php" method="post" style="display: inline-block; width: 100%;">
                       <div class="btn-group w-100">
                           <button type="submit" name="neko" value="start" class="btn btn<?php if ($neko_status == 1) echo "-outline" ?>-success <?php if ($neko_status == 1) echo "disabled" ?>">启用 Mihomo</button>
                           <button type="submit" name="neko" value="disable" class="btn btn<?php if ($neko_status == 0) echo "-outline" ?>-danger <?php if ($neko_status == 0) echo "disabled" ?>">停用 Mihomo</button>
                           <button type="submit" name="neko" value="restart" class="btn btn<?php if ($neko_status == 0) echo "-outline" ?>-warning <?php if ($neko_status == 0) echo "disabled" ?>">重启 Mihomo</button>
                       </div>
                   </form>
               </td>
           </tr>
           <tr>
               <td style="width:150px">Sing-box 控制</td>
               <td class="d-grid">
                   <form action="index.php" method="post">
                       <div class="input-group mb-2">
                           <select name="config_file" id="config_file" class="form-select" onchange="saveConfigSelection()">
                               <?php foreach ($availableConfigs as $config): ?>
                                   <option value="<?= htmlspecialchars($config) ?>" <?= isset($_POST['config_file']) && $_POST['config_file'] === $config ? 'selected' : '' ?>>
                                       <?= htmlspecialchars(basename($config)) ?>
                                   </option>
                               <?php endforeach; ?>
                           </select>
                       </div>
                       <div class="btn-group w-100">
                           <button type="submit" name="singbox" value="start" class="btn btn<?php echo ($singbox_status == 1) ? "-outline" : "" ?>-success <?php echo ($singbox_status == 1) ? "disabled" : "" ?>">启用 Sing-box</button>
                           <button type="submit" name="singbox" value="disable" class="btn btn<?php echo ($singbox_status == 0) ? "-outline" : "" ?>-danger <?php echo ($singbox_status == 0) ? "disabled" : "" ?>">停用 Sing-box</button>
                           <button type="submit" name="singbox" value="restart" class="btn btn<?php echo ($singbox_status == 0) ? "-outline" : "" ?>-warning <?php echo ($singbox_status == 0) ? "disabled" : "" ?>">重启 Sing-box</button>
                       </div>
                   </form>
               </td>
           </tr>
           <tr>
               <td style="width:150px">运行模式</td>
               <td class="d-grid">
                   <?php
                   $mode_placeholder = '';
                   if ($neko_status == 1) {
                       $mode_placeholder = $neko_cfg['echanced'] . " | " . $neko_cfg['mode'];
                   } elseif ($singbox_status == 1) {
                       $mode_placeholder = "Rule 模式";
                   } else {
                       $mode_placeholder = "未运行";
                   }
                   ?>
                   <input class="form-control text-center" name="mode" type="text" placeholder="<?php echo $mode_placeholder; ?>" disabled>
               </td>
           </tr>
       </tbody>
   </table>

<div class="modal fade" id="singboxModal" tabindex="-1" aria-labelledby="singboxModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="singboxModalLabel">Sing-box 启动提示</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <p>如遇启动失败，请前往文件管理 ⇨ 更新数据库 ⇨ 下载 cache.db 缓存数据。</p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
      </div>
    </div>
  </div>
</div>

<script>
    $(document).ready(function() {
        var lastShown = localStorage.getItem('singboxModalLastShown');
        var currentTime = new Date().getTime();

        if (!lastShown || (currentTime - lastShown) > 12 * 60 * 60 * 1000) {
            $('#singboxModal').modal('show');  
        }

        localStorage.setItem('singboxModalLastShown', currentTime);
    });
</script>

<script>
    document.addEventListener("DOMContentLoaded", function() {
        const savedConfig = localStorage.getItem("configSelection");
        if (savedConfig) {
            document.getElementById("config_file").value = savedConfig;
        }
    });
    function saveConfigSelection() {
        const selectedConfig = document.getElementById("config_file").value;
        localStorage.setItem("configSelection", selectedConfig);
    }
</script>

<script>
    const lastShownTime = localStorage.getItem('lastCronMessageShownTime');
    const currentTime = new Date().getTime(); 

    if (!lastShownTime || (currentTime - lastShownTime) > 12 * 60 * 60 * 1000) {
        document.getElementById('cron-success-message').style.display = 'block';
        localStorage.setItem('lastCronMessageShownTime', currentTime);
    }
</script>

<script>
function saveConfigToLocalStorage() {
    const selectedConfig = document.getElementById('configSelect').value;
    if (selectedConfig) {
        localStorage.setItem('selected_config', selectedConfig);
    }
}

window.onload = function() {
    const savedConfig = localStorage.getItem('selected_config');
    if (savedConfig) {
        const configSelect = document.getElementById('configSelect');
        configSelect.value = savedConfig; 
    }
};
</script>
<div id="collapsibleHeader" style="cursor: pointer; display: flex; flex-direction: column; align-items: center; justify-content: center;">
    <i id="toggleIcon" class="triangle-icon"></i> 
    <h2 id="systemTitle" class="text-center" style="display: none; margin-top: 0;">系统状态</h2> 
</div>

<div id="collapsible" style="display: none; margin-top: 5px;"> 
   <table class="table table-borderless rounded-4 mb-2">
       <tbody>
           <tr>
               <td style="width:150px">系统信息</td>
               <td id="systemInfo"></td>
           </tr>
           <tr>
               <td style="width:150px">内存</td>
               <td id="ramUsage"></td>
           </tr>
           <tr>
               <td style="width:150px">平均负载</td>
               <td id="cpuLoad"></td>
           </tr>
           <tr>
               <td style="width:150px">运行时间</td>
               <td id="uptime"></td>
           </tr>
           <tr>
               <td style="width:150px">流量统计</td>
               <td>⬇️ <span id="downtotal"></span> | ⬆️ <span id="uptotal"></span></td>
           </tr>
       </tbody>
   </table>
</div>

<script>
    const collapsible = document.getElementById('collapsible');
    const collapsibleHeader = document.getElementById('collapsibleHeader');
    const toggleIcon = document.getElementById('toggleIcon');
    const systemTitle = document.getElementById('systemTitle');
    
    let isCollapsed = true;

    if (localStorage.getItem('isCollapsed') === 'false') {
        isCollapsed = false;
        collapsible.style.display = 'block';
        systemTitle.style.display = 'block';
        toggleIcon.classList.add('rotated'); 
    }

    collapsibleHeader.addEventListener('click', () => {
        if (isCollapsed) {
            collapsible.style.display = 'block'; 
            systemTitle.style.display = 'block'; 
            toggleIcon.classList.add('rotated'); 
        } else {
            collapsible.style.display = 'none';   
            systemTitle.style.display = 'none';  
            toggleIcon.classList.remove('rotated'); 
        }
        isCollapsed = !isCollapsed;  
        localStorage.setItem('isCollapsed', isCollapsed); 
    });

    function fetchSystemStatus() {
        fetch('?ajax=1')
            .then(response => response.json())
            .then(data => {
                document.getElementById('systemInfo').innerText = data.systemInfo;
                document.getElementById('ramUsage').innerText = data.ramUsage;
                document.getElementById('cpuLoad').innerText = data.cpuLoad;
                document.getElementById('uptime').innerText = data.uptime;
                document.getElementById('cpuLoadAvg1Min').innerText = data.cpuLoadAvg1Min;
                document.getElementById('ramUsageOnly').innerText = data.ramUsageOnly + ' / ' + data.ramTotal + ' MB';
            })
            .catch(error => console.error('Error fetching data:', error));
    }

    setInterval(fetchSystemStatus, 1000);
    fetchSystemStatus();  
</script>

<style>
    .triangle-icon {
        width: 0;
        height: 0;
        border-left: 12px solid transparent;
        border-right: 12px solid transparent;
        border-top: 12px solid blue; 
        display: inline-block;
        transition: transform 0.3s ease-in-out;
    }

    .rotated {
        transform: rotate(180deg); 
    }


    .form-inline {
        display: inline-block;  
    }

    @media (max-width: 767px) {
        .form-inline {
            display: flex;         
            flex-wrap: nowrap;     
            justify-content: center; 
            gap: 5px;         
        }

        .form-check-inline, .btn {
            font-size: 10px;      
        }
    }

    @media (max-width: 767px) {
        #logTabs .nav-item {
            display: block;  
            width: 100%;     
        }
    }

</style>
<h2 class="text-center">日志</h2>
<ul class="nav nav-pills mb-3" id="logTabs" role="tablist">
    <li class="nav-item" role="presentation">
        <a class="nav-link" id="pluginLogTab" data-bs-toggle="pill" href="#pluginLog" role="tab" aria-controls="pluginLog" aria-selected="true">NeKoBox 日志</a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link" id="mihomoLogTab" data-bs-toggle="pill" href="#mihomoLog" role="tab" aria-controls="mihomoLog" aria-selected="false">Mihomo 日志</a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link" id="singboxLogTab" data-bs-toggle="pill" href="#singboxLog" role="tab" aria-controls="singboxLog" aria-selected="false">Sing-box 日志</a>
    </li>
</ul>
<div class="tab-content" id="logTabsContent">
    <div class="tab-pane fade" id="pluginLog" role="tabpanel" aria-labelledby="pluginLogTab">
        <div class="card log-card">
            <div class="card-body">
                <pre id="plugin_log" class="log-container form-control" style="resize: vertical; overflow: auto; height: 350px; white-space: pre-wrap;" contenteditable="true"></pre>
            </div>
            <div class="card-footer text-center">
                <form action="index.php" method="post">
                    <button type="submit" name="clear_plugin_log" class="btn btn-danger"><i class="bi bi-trash"></i> 清空日志</button>
                </form>
            </div>
        </div>
    </div>

    <div class="tab-pane fade" id="mihomoLog" role="tabpanel" aria-labelledby="mihomoLogTab">
        <div class="card log-card">
            <div class="card-body">
                <pre id="bin_logs" class="log-container form-control" style="resize: vertical; overflow: auto; height: 350px; white-space: pre-wrap;" contenteditable="true"></pre>
            </div>
            <div class="card-footer text-center">
                <form action="index.php" method="post">
                    <button type="submit" name="neko" value="clear" class="btn btn-danger"><i class="bi bi-trash"></i> 清空日志</button>
                </form>
            </div>
        </div>
    </div>

    <div class="tab-pane fade" id="singboxLog" role="tabpanel" aria-labelledby="singboxLogTab">
        <div class="card log-card">
            <div class="card-body">
                <pre id="singbox_log" class="log-container form-control" style="resize: vertical; overflow: auto; height: 350px; white-space: pre-wrap;" contenteditable="true"></pre>
            </div>
            <div class="card-footer text-center">
                <form action="index.php" method="post" class="form-inline">
                    <div class="form-check form-check-inline mb-2">
                        <input class="form-check-input" type="checkbox" id="autoRefresh" checked>
                        <label class="form-check-label" for="autoRefresh">自动刷新</label>
                    </div>
                    <button type="submit" name="clear_singbox_log" class="btn btn-danger me-2"><i class="bi bi-trash"></i> 清空日志</button>
                    <button type="button" class="btn btn-primary me-2" data-toggle="modal" data-target="#cronModal"><i class="bi bi-clock"></i> 定时重启</button>
                    <button id="showHelpButton" class="btn btn-info" data-bs-toggle="modal" data-bs-target="#helpModal" type="button"><i class="bi bi-keyboard"></i> 键盘说明</button>
                </form>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="helpModal" tabindex="-1" aria-labelledby="helpModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="helpModalLabel">键盘操作说明</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <ul>
                    <li><strong>鼠标左键:</strong> 双击打开播放器界面</li>
                    <li><strong>F9键:</strong> 切换播放/暂停</li>
                    <li><strong>上下箭头键:</strong> 切换上一首/下一首</li>
                    <li><strong>左右箭头键:</strong> 快进/快退 10 秒</li>
                    <li><strong>ESC键:</strong> 返回播放列表的第一首</li>
                    <li><strong>F2键:</strong> 切换循环播放和顺序播放模式</li>
                    <li><strong>F8键:</strong> 启动网站连通性检查</li>
                    <li><strong>F4键:</strong> 开启天气信息播报</li>
                    <li><strong>Ctrl + F6键:</strong> 启动/停止雪花动画 </li>
                    <li><strong>Ctrl + F7键:</strong> 启动/停止方块灯光动画 </li>
                    <li><strong>Ctrl + F10键:</strong> 启动/停止方块动画 </li>
                    <li><strong>Ctrl + F11键:</strong> 启动/停止光点动画 </li>
                    <li><strong>Ctrl + Shift + C键:</strong> 清空缓存</li>
                    <li><strong>Ctrl + Shift + V键:</strong> 定制播放列表</li>
                    <li><strong>Ctrl + Shift + X键:</strong> 设置城市</li>
                </ul>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="cronModal" tabindex="-1" role="dialog" aria-labelledby="cronModalLabel" aria-hidden="true" data-backdrop="static" data-keyboard="false">
  <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="cronModalLabel">设置 Cron 任务时间</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body">
        <form id="cronForm" method="POST">
          <div class="form-group ">
            <label for="cronTime">设置 Sing-box 重启时间</label>
            <input type="text" class="form-control mt-3" id="cronTime" name="cronTime" value="0 3 * * *" required>
          </div>
          <div class="alert alert-info mt-3">
            <strong>提示:</strong> Cron 表达式格式：
            <ul>
              <li><code>分钟 小时 日 月 星期</code></li>
              <li>示例: 每天凌晨 2 点: <code>0 2 * * *</code></li>
              <li>每周一凌晨 3 点: <code>0 3 * * 1</code></li>
              <li>工作日（周一至周五）的上午 9 点: <code>0 9 * * 1-5</code></li>
            </ul>
          </div>
        </form>
        <div id="resultMessage" class="mt-3"></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-dismiss="modal">取消</button>
        <button type="submit" class="btn btn-primary" form="cronForm">保存</button>
      </div>
    </div>
  </div>
</div>
<script>
    $('#cronForm').submit(function(event) {
        event.preventDefault(); 
        var cronTime = $('#cronTime').val(); 
        $.ajax({
            type: 'POST',
            url: '',  
            data: { cronTime: cronTime },
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    $('#resultMessage').html('<div class="alert alert-success">' + response.message + '</div>');
                    setTimeout(function() {
                        $('#cronModal').modal('hide'); 
                    }, 2000);
                }
            },
            error: function() {
                $('#resultMessage').html('<div class="alert alert-danger">设置 Cron 任务失败，请重试！</div>');
            }
        });
    });
</script>
<script>
    function scrollToBottom(elementId) {
        var logElement = document.getElementById(elementId);
        logElement.scrollTop = logElement.scrollHeight;
    }
    function fetchLogs() {
        if (!document.getElementById('autoRefresh').checked) {
            return;
        }
        Promise.all([
            fetch('fetch_logs.php?file=plugin_log'),
            fetch('fetch_logs.php?file=mihomo_log'),
            fetch('fetch_logs.php?file=singbox_log')
        ])
        .then(responses => Promise.all(responses.map(res => res.text())))
        .then(data => {
            document.getElementById('plugin_log').textContent = data[0];
            document.getElementById('bin_logs').textContent = data[1];
            document.getElementById('singbox_log').textContent = data[2];
            scrollToBottom('plugin_log');
            scrollToBottom('bin_logs');
            scrollToBottom('singbox_log');
        })
        .catch(err => console.error('Error fetching logs:', err));
    }
    fetchLogs();
    let intervalId = setInterval(fetchLogs, 5000);
    document.getElementById('autoRefresh').addEventListener('change', function() {
        if (this.checked) {
            intervalId = setInterval(fetchLogs, 5000);
        } else {
            clearInterval(intervalId);
        }
    });
</script>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const autoRefreshCheckbox = document.getElementById('autoRefresh');
        const isChecked = localStorage.getItem('autoRefresh') === 'true';
        autoRefreshCheckbox.checked = isChecked;

        if (isChecked) {
            intervalId = setInterval(fetchLogs, 5000);
        }
    });

    document.getElementById('autoRefresh').addEventListener('change', function() {
        localStorage.setItem('autoRefresh', this.checked);
        if (this.checked) {
            intervalId = setInterval(fetchLogs, 5000);
        } else {
            clearInterval(intervalId);
        }
    });
</script>

<script>
    window.addEventListener('load', function() {
        const activeTab = localStorage.getItem('activeTab') || 'pluginLogTab'; 
        const activeTabLink = document.getElementById(activeTab);
        const activeTabPane = document.getElementById(activeTab.replace('Tab', ''));      
        activeTabLink.classList.add('active');  
        activeTabPane.classList.add('show', 'active');  
    });

    document.querySelectorAll('.nav-link').forEach(tab => {
        tab.addEventListener('click', function() {
            const selectedTab = this.id;
            localStorage.setItem('activeTab', selectedTab); 
        });
    });
</script>
</body>
</html>
    <footer class="text-center">
        <p><?php echo isset($message) ? $message : ''; ?></p>
        <p><?php echo $footer; ?></p>
    </footer>
</body>
</html>