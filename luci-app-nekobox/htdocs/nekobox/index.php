<?php
include './cfg.php';

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

  chain common-exclude {
    fib daddr type { unspec, local, anycast, multicast } return
    meta nfproto ipv4 ip daddr @local_ipv4 return
    meta nfproto ipv6 ip6 daddr @local_ipv6 return
    udp dport { 123 } return
  }

  chain singbox-tproxy {
    goto common-exclude
    meta l4proto { tcp, udp } meta mark set 1 tproxy to :9888 accept
  }

  chain singbox-mark {
    goto common-exclude
    meta l4proto { tcp, udp } meta mark set 1
  }

  chain mangle-output {
    type route hook output priority mangle; policy accept;
    meta l4proto { tcp, udp } ct state new skgid != 1 goto singbox-mark
  }

  chain mangle-prerouting {
    type filter hook prerouting priority mangle; policy accept;
    iifname eth0 meta l4proto { tcp, udp } ct state new goto singbox-tproxy
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
    echo "\$(timestamp) Sing-box log file (\$LOG_FILE) exceeded \$MAX_SIZE bytes. Clearing log..." >> \$LOG_PATH 2>&1
    > "\$LOG_FILE"  
    echo "\$(timestamp) Sing-box log file (\$LOG_FILE) has been cleared." >> \$LOG_PATH 2>&1
else
    echo "\$(timestamp) Sing-box log file (\$LOG_FILE) is within the size limit. No action needed." >> \$LOG_PATH 2>&1
fi

if [ -f "\$TMP_LOG_FILE" ] && [ \$(stat -c %s "\$TMP_LOG_FILE") -gt \$MAX_SIZE ]; then
    echo "\$(timestamp) Mihomo log file (\$TMP_LOG_FILE) exceeded \$MAX_SIZE bytes. Clearing log..." >> \$LOG_PATH 2>&1
    > "\$TMP_LOG_FILE"  
    echo "\$(timestamp) Mihomo log file (\$TMP_LOG_FILE) has been cleared." >> \$LOG_PATH 2>&1
else
    echo "\$(timestamp) Mihomo log file (\$TMP_LOG_FILE) is within the size limit. No action needed." >> \$LOG_PATH 2>&1
fi

if [ -f "\$ADDITIONAL_LOG_FILE" ] && [ \$(stat -c %s "\$ADDITIONAL_LOG_FILE") -gt \$MAX_SIZE ]; then
    echo "\$(timestamp) NeKoBox log file (\$ADDITIONAL_LOG_FILE) exceeded \$MAX_SIZE bytes. Clearing log..." >> \$LOG_PATH 2>&1
    > "\$ADDITIONAL_LOG_FILE"
    echo "\$(timestamp) NeKoBox log file (\$ADDITIONAL_LOG_FILE) has been cleared." >> \$LOG_PATH 2>&1
else
    echo "\$(timestamp) NeKoBox log file (\$ADDITIONAL_LOG_FILE) is within the size limit. No action needed." >> \$LOG_PATH 2>&1
fi

echo "\$(timestamp) Log rotation completed." >> \$LOG_PATH 2>&1
EOL;

    $cronScriptPath = '/etc/neko/core/set_cron.sh';
    file_put_contents($cronScriptPath, $cronScriptContent);
    chmod($cronScriptPath, 0755);
    shell_exec("sh $cronScriptPath");
}

function rotateLogs($logFile, $maxSize = 1048576) {
    if (file_exists($logFile) && filesize($logFile) > $maxSize) {
        file_put_contents($logFile, '');
        chmod($logFile, 0644);      
        //echo "Log file cleared successfully.\n";
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
        $logMessage = "Please provide a valid Cron time format!";
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
    echo "$(timestamp) Sing-box is already running, restarting..." >> \$LOG_PATH
    kill $(pgrep -x "singbox")
    sleep 2
    start_singbox  

    RETRY_COUNT=0
    while ! check_singbox && [ \$RETRY_COUNT -lt \$MAX_RETRIES ]; do
        echo "$(timestamp) Sing-box restart failed, retrying... (\$((RETRY_COUNT + 1))/\$MAX_RETRIES)" >> \$LOG_PATH
        sleep \$RETRY_INTERVAL
        start_singbox  
        ((RETRY_COUNT++))
    done

    if check_singbox; then
        echo "$(timestamp) Sing-box restarted successfully!" >> \$LOG_PATH
    else
        echo "$(timestamp) Sing-box restart failed, max retries reached!" >> \$LOG_PATH
    fi
else
    echo "$(timestamp) Sing-box is not running, starting Sing-box..." >> \$LOG_PATH
    start_singbox  

    RETRY_COUNT=0
    while ! check_singbox && [ \$RETRY_COUNT -lt \$MAX_RETRIES ]; do
        echo "$(timestamp) Sing-box start failed, retrying... (\$((RETRY_COUNT + 1))/\$MAX_RETRIES)" >> \$LOG_PATH
        sleep \$RETRY_INTERVAL
        start_singbox  
        ((RETRY_COUNT++))
    done

    if check_singbox; then
        echo "$(timestamp) Sing-box started successfully!" >> \$LOG_PATH
    else
        echo "$(timestamp) Sing-box start failed, max retries reached!" >> \$LOG_PATH
    fi
fi
EOL;

    $scriptPath = '/etc/neko/core/restart_singbox.sh';
    file_put_contents($scriptPath, $restartScriptContent);
    chmod($scriptPath, 0755);

    $cronSchedule = $cronTime . " /bin/bash $scriptPath";
    exec("crontab -l | grep -v '$scriptPath' | crontab -"); 
    exec("(crontab -l 2>/dev/null; echo \"$cronSchedule\") | crontab -");  

    $logMessage = "Cron job successfully set. Sing-box will restart automatically at $cronTime.";
    file_put_contents('/etc/neko/tmp/log.txt', date('[ H:i:s ] ') . "$logMessage\n", FILE_APPEND);
    echo json_encode(['success' => true, 'message' => 'Cron job successfully set.']);
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
       $str_cfg = 'Sing-box configuration file: No running configuration file found';
       writeToLog("No running config file found");
   }
}

function readRecentLogLines($filePath, $lines = 1000) {
   if (!file_exists($filePath)) {
       return "The log file does not exist: $filePath";
   }
   if (!is_readable($filePath)) {
       return "Unable to read the log file: $filePath";
   }
   $command = "tail -n $lines " . escapeshellarg($filePath);
   $output = shell_exec($command);
   return $output ?: "The log is empty";
}

function readLogFile($filePath) {
   if (file_exists($filePath)) {
       return nl2br(htmlspecialchars(readRecentLogLines($filePath, 1000), ENT_NOQUOTES));
   } else {
       return 'The log file does not exist';
   }
}

$neko_log_content = readLogFile("$neko_dir/tmp/neko_log.txt");
$singbox_log_content = readLogFile($singbox_log);
?>

<?php
$confDirectory = '/etc/neko/config';  
$storageFile = '/www/nekobox/lib/singbox.txt';

$storageDir = dirname($storageFile);
if (!is_dir($storageDir)) {
    mkdir($storageDir, 0755, true);
}

$currentConfigPath = '';
if (file_exists($storageFile)) {
    $rawPath = trim(file_get_contents($storageFile));
    $currentConfigPath = realpath($rawPath) ?: $rawPath; 
}

if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST['config_file'])) {
    $submittedPath = trim($_POST['config_file']);
    $normalizedPath = realpath($submittedPath); 
    
    if ($normalizedPath && 
        strpos($normalizedPath, realpath($confDirectory)) === 0 && 
        file_exists($normalizedPath)
    ) {
        if (file_put_contents($storageFile, $normalizedPath) !== false) {
            $currentConfigPath = $normalizedPath;
        } else {
            error_log("Write failed: $storageFile");
        }
    } else {
        error_log("Invalid path: $submittedPath");
    }
}

function fetchConfigFiles() {
    global $confDirectory;
    $baseDir = rtrim($confDirectory, '/') . '/'; 
    return glob($baseDir . '*.json') ?: [];
}

$foundConfigs = fetchConfigFiles();
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
        'uptime' => "{$days} days {$hours} hours {$minutes} minutes {$seconds} seconds",
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
    $default_config_content .= "# Please edit this file as needed\n";
    
    file_put_contents($current_config, $default_config_content);
    file_put_contents('/www/nekobox/lib/selected_config.txt', $current_config);

    $logMessage = "The configuration file is missing; a default configuration file has been created.";
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
        $logMessage = "The configuration file is missing some options; the missing configuration items have been added automatically";
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
        echo "<script>alert('Invalid configuration file');</script>";
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
        <strong data-translate="nginxWarningStrong"></strong> 
        <span data-translate="nginxWarning"></span>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
    <script>
    document.addEventListener("DOMContentLoaded", function () {
        let lastWarningTime = localStorage.getItem('nginxWarningTime');
        let currentTime = new Date().getTime();
        let warningInterval = 12 * 60 * 60 * 1000; 

        if (!lastWarningTime || currentTime - lastWarningTime > warningInterval) {
            localStorage.setItem('nginxWarningTime', currentTime); 
            let warningAlert = document.getElementById('nginxWarning');
        
            if (warningAlert) {
                warningAlert.style.display = 'block';

                setTimeout(function() {
                    warningAlert.classList.remove('show');
                    setTimeout(function() {
                        warningAlert.remove();
                    }, 300);
                }, 5000);
            }
        }
    });
    </script>
    <?php endif; ?>
<div class="container-sm container-bg callout border border-3 rounded-4 col-11">
    <div class="row">
        <a href="./index.php" class="col btn btn-lg text-nowrap"><i class="bi bi-house-door"></i> <span data-translate="home">Home</span></a>
        <a href="./dashboard.php" class="col btn btn-lg text-nowrap"><i class="bi bi-bar-chart"></i> <span data-translate="panel">Panel</span></a>
        <a href="./singbox.php" class="col btn btn-lg text-nowrap"><i class="bi bi-box"></i> <span data-translate="document">Document</span></a> 
        <a href="./settings.php" class="col btn btn-lg text-nowrap"><i class="bi bi-gear"></i> <span data-translate="settings">Settings</span></a>
    <div class="container-sm text-center col-8">
  <img src="./assets/img/nekobox.png">
<div id="version-info">
    <a id="version-link" href="https://github.com/Thaolga/openwrt-nekobox/releases" target="_blank">
        <img id="current-version" src="./assets/img/curent.svg" alt="Current Version" style="max-width: 100%; height: auto;" />
    </a>
</div>
</div>
<script>
function checkForUpdate() {
    $.ajax({
        url: 'check_update.php',
        method: 'GET',
        dataType: 'json',
        success: function(data) {
            if (data.hasUpdate) {
                $('#current-version').attr('src', 'https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/refs/heads/main/luci-app-nekobox/htdocs/nekobox/assets/img/Latest.svg');
            }
            console.log('Current Version:', data.currentVersion);
            console.log('Latest Version:', data.latestVersion);
            console.log('Has Update:', data.hasUpdate);

            localStorage.setItem('lastUpdateCheck', Date.now());
            startUpdateTimer(); 
        },
        error: function(jqXHR, textStatus, errorThrown) {
            console.error('AJAX Error:', textStatus, errorThrown);
        }
    });
}

function startUpdateTimer() {
    const now = Date.now();
    const lastCheck = localStorage.getItem('lastUpdateCheck');

    let timeSinceLastCheck = lastCheck ? now - parseInt(lastCheck, 10) : Infinity;
    let timeUntilNextCheck = Math.max(28800000 - timeSinceLastCheck, 0); 

    console.log('Time until next check:', timeUntilNextCheck / 1000 / 60, 'minutes');

    setTimeout(checkForUpdate, timeUntilNextCheck); 
}

startUpdateTimer(); 
</script>
<script>
document.addEventListener('DOMContentLoaded', function () {
    const titleElement = document.getElementById('neko-title');
    const cachedTitle = localStorage.getItem('nekoTitle');

    if (cachedTitle) {
        titleElement.textContent = cachedTitle; 
    }

    function updateTitle(newTitle) {
        titleElement.textContent = newTitle;
        localStorage.setItem('nekoTitle', newTitle);
    }

});
</script>
<h2 id="neko-title" class="royal-style">NekoBox</h2>
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

    .custom-icon {
        width: 20px !important;
        height: 20px !important;
        vertical-align: middle !important;
        margin-right: 5px !important;
        stroke: #FF00FF !important; 
        fill: none !important;
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

@media (max-width: 767px) {
    .section-container .table {
        display: block;
        width: 100%;
    }

    .section-container .table tbody,
    .section-container .table thead,
    .section-container .table tr {
        display: block;
    }

    .section-container .table td {
        display: block;
        width: 100%;
        padding: 10px;
        border: 1px solid #ddd;
        margin-bottom: 10px;
    }

    .section-container .table td:first-child {
        font-weight: bold;
        background-color: #f8f9fa;
    }

    .section-container .btn-group {
        display: flex;
        flex-direction: column;
        gap: 10px;
    }

    .section-container .form-select,
    .section-container .form-control,
    .section-container .input-group {
        width: 100%;
    }

    .section-container .btn {
        width: 100%;
    }
}

@media (max-width: 767px) {
    .section-container .table td {
        background-color: #fff;
        border-radius: 5px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }

    .section-container .table td:first-child {
        background-color: #f0f0f0;
        font-size: 1.1em;
    }

    .section-container .btn {
        border-radius: 5px;
    }

    .section-container .btn-group {
        gap: 15px;
    }
}

</style>
<div class="section-container">
    <div class="card">
        <div class="card-body">
            <div class="mb-4">
                <h6 class="mb-2"><i data-feather="activity"></i> <span data-translate="status">Status</span></h6>
                <div class="btn-group w-100" role="group">
                    <?php if ($neko_status == 1): ?>
                        <button type="button" class="btn btn-success">
                            <i class="bi bi-router"></i> 
                            <span data-translate="mihomoRunning">Mihomo Running</span>
                        </button>
                    <?php else: ?>
                        <button type="button" class="btn btn-outline-danger">
                            <i class="bi bi-router"></i> 
                            <span data-translate="mihomoNotRunning">Mihomo Not Running</span>
                        </button>
                    <?php endif; ?>

                    <button type="button" class="btn btn-deepskyblue">
                        <i class="bi bi-file-earmark-text"></i> <?= $str_cfg ?>
                    </button>

                    <?php if ($singbox_status == 1): ?>
                        <button type="button" class="btn btn-success">
                            <i class="bi bi-hdd-stack"></i> 
                            <span data-translate="singboxRunning">Sing-box Running</span>
                        </button>
                    <?php else: ?>
                        <button type="button" class="btn btn-outline-danger">
                            <i class="bi bi-hdd-stack"></i> 
                            <span data-translate="singboxNotRunning">Sing-box Not Running</span>
                        </button>
                    <?php endif; ?>
                </div>
            </div>

            <div class="mb-4" id="mihomoControl" class="control-box">
                <h6 class="mb-2"><i class="fas fa-box custom-icon"></i> <span data-translate="mihomoControl">Mihomo Control</span></h6>
                <div class="d-flex flex-column gap-2">
                    <form action="index.php" method="post">
                        <select id="configSelect" class="form-select mb-2" name="selected_config" 
                                onchange="saveConfigToLocalStorage(); this.form.submit()">
                            <option value="">
                                <span data-translate="selectConfig">Please select a configuration file</span>
                            </option>
                            <?php
                            $config_dir = '/etc/neko/config';
                            $files = array_diff(scandir($config_dir), array('..', '.'));
                            foreach ($files as $file):
                                if (pathinfo($file, PATHINFO_EXTENSION) == 'yaml'):
                                    $selected = (realpath($config_dir . '/' . $file) == realpath($current_config)) ? 'selected' : '';
                                    ?>
                                    <option value="<?= $file ?>" <?= $selected ?>>
                                        <?= $file ?>
                                    </option>
                            <?php
                                endif;
                            endforeach;
                            ?>
                        </select>
                        
                        <div class="btn-group w-100">
                            <button type="submit" name="neko" value="start" 
                                    class="btn btn<?= ($neko_status == 1) ? "-outline" : "" ?>-success <?= ($neko_status == 1) ? "disabled" : "" ?>">
                                <i class="bi bi-power"></i> 
                                <span data-translate="enableMihomo">Enable Mihomo</span>
                            </button>
                            <button type="submit" name="neko" value="disable" 
                                    class="btn btn<?= ($neko_status == 0) ? "-outline" : "" ?>-danger <?= ($neko_status == 0) ? "disabled" : "" ?>">
                                <i class="bi bi-x-octagon"></i> 
                                <span data-translate="disableMihomo">Disable Mihomo</span>
                            </button>
                            <button type="submit" name="neko" value="restart" 
                                    class="btn btn<?= ($neko_status == 0) ? "-outline" : "" ?>-warning <?= ($neko_status == 0) ? "disabled" : "" ?>">
                                <i class="bi bi-arrow-clockwise"></i> 
                                <span data-translate="restartMihomo">Restart Mihomo</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <div class="mb-4" id="singboxControl" class="control-box">
                <h6 class="mb-2"><i data-feather="codesandbox"></i> <span data-translate="singboxControl">Singbox Control</span></h6>
                <div class="d-flex flex-column gap-2">
                    <form action="index.php" method="post">
                        <select name="config_file" class="form-select mb-2" onchange="this.form.submit()">
                            <option value="">
                                <span data-translate="selectConfig">Please select a configuration file</span>
                            </option>
                            <?php foreach ($foundConfigs as $configPath): ?>
                                <?php 
                                $cleanPath = str_replace('//', '/', $configPath); 
                                $displayName = basename($cleanPath);
                                ?>
                                <option value="<?= htmlspecialchars($cleanPath) ?>"
                                    <?= ($currentConfigPath === realpath($cleanPath)) ? 'selected' : '' ?>>
                                    <?= htmlspecialchars($displayName) ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                        
                        <div class="btn-group w-100">
                            <button type="submit" name="singbox" value="start" 
                                    class="btn btn<?= ($singbox_status == 1) ? "-outline" : "" ?>-success <?= ($singbox_status == 1) ? "disabled" : "" ?>">
                                <i class="bi bi-power"></i> 
                                <span data-translate="enableSingbox">Enable Sing-box</span>
                            </button>
                            <button type="submit" name="singbox" value="disable" 
                                    class="btn btn<?= ($singbox_status == 0) ? "-outline" : "" ?>-danger <?= ($singbox_status == 0) ? "disabled" : "" ?>">
                                <i class="bi bi-x-octagon"></i> 
                                <span data-translate="disableSingbox">Disable Sing-box</span>
                            </button>
                            <button type="submit" name="singbox" value="restart" 
                                    class="btn btn<?= ($singbox_status == 0) ? "-outline" : "" ?>-warning <?= ($singbox_status == 0) ? "disabled" : "" ?>">
                                <i class="bi bi-arrow-clockwise"></i> 
                                <span data-translate="restartSingbox">Restart Sing-box</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <div class="mb-4">
                <h6 class="mb-2"><i class="fas fa-cog custom-icon"></i> <span data-translate="runningMode">Running Mode</span></h6>
                <div class="btn-group w-100">
                    <?php
                    $mode_placeholder = '';
                    if ($neko_status == 1) {
                        $mode_placeholder = $neko_cfg['echanced'] . " | " . $neko_cfg['mode'];
                    } elseif ($singbox_status == 1) {
                        $mode_placeholder = "Sing-box | Rule Mode";
                    } else {
                        $mode_placeholder = "Not Running";
                    }
                    ?>
                    <input class="form-control text-center" name="mode" type="text" 
                           placeholder="<?= $mode_placeholder ?>" disabled>
                </div>
            </div>
        </div>
    </div>
</div>
<script>
document.addEventListener('DOMContentLoaded', () => {
    const mihomoControl = document.getElementById('mihomoControl');
    const singboxControl = document.getElementById('singboxControl');

    const mihomoStatus = <?php echo $neko_status; ?>; 
    const singboxStatus = <?php echo $singbox_status; ?>; 

    if (mihomoStatus === 1 && singboxStatus === 1) {
        mihomoControl.style.display = 'block';
        singboxControl.style.display = 'block';
    } else if (mihomoStatus === 1) {
        mihomoControl.style.display = 'block';
        singboxControl.style.display = 'none';
    } else if (singboxStatus === 1) {
        mihomoControl.style.display = 'none';
        singboxControl.style.display = 'block';
    } else {
        mihomoControl.style.display = 'block';
        singboxControl.style.display = 'block';
    }
});
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
<div class="section-container"> 
  <div id="collapsibleHeader" style="cursor: pointer; display: flex; flex-direction: column; align-items: center; justify-content: center; margin-top: 20px;">
      <i id="toggleIcon" class="triangle-icon"></i> 
  </div>
  <div class="card mt-4 py-3"> 
      <div class="text-center" id="systemHeader" class="system-header">
          <h3 class="mb-0"></h3>
      </div>
      <div id="collapsible" class="card-body collapsible-body">
          <!-- System Info -->
          <div class="mb-4">
              <h6 class="mb-2"><i data-feather="cpu"></i> <span data-translate="systemInfo">System Info</span></h6>
              <div class="btn-group w-100">
                  <span id="systemInfo" class="form-control text-center"></span>
              </div>
          </div>

          <div class="mb-4">
              <h6 class="mb-2"><i data-feather="database"></i> <span data-translate="systemMemory">System Memory</span></h6>
              <div class="btn-group w-100">
                  <span id="ramUsage" class="form-control text-center"></span>
              </div>
          </div>

          <div class="mb-4">
              <h6 class="mb-2"><i data-feather="zap"></i> <span data-translate="avgLoad">Average Load</span></h6>
              <div class="btn-group w-100">
                  <span id="cpuLoad" class="form-control text-center"></span>
              </div>
          </div>

          <div class="mb-4">
              <h6 class="mb-2"><i data-feather="clock"></i> <span data-translate="uptime">Uptime</span></h6>
              <div class="btn-group w-100">
                  <span id="uptime" class="form-control text-center"></span>
              </div>
          </div>

          <div class="mb-4">
              <h6 class="mb-2"><i data-feather="bar-chart-2"></i> <span data-translate="trafficStats">Traffic Stats</span></h6>
              <div class="btn-group w-100">
                  <span class="form-control text-center">
                      ⬇️ <span id="downtotal"></span> | ⬆️ <span id="uptotal"></span>
                  </span>
              </div>
          </div>
      </div>
  </div>
</div>

<script>
    const collapsible = document.getElementById('collapsible');
    const collapsibleHeader = document.getElementById('collapsibleHeader');
    const toggleIcon = document.getElementById('toggleIcon');
    const systemHeader = document.getElementById('systemHeader');  
    
    let isCollapsed = true;

    if (localStorage.getItem('isCollapsed') === 'false') {
        isCollapsed = false;
        collapsible.style.display = 'block';  
        systemHeader.style.display = 'block';  
        toggleIcon.classList.add('rotated'); 
    } else {
        collapsible.style.display = 'none';   
        systemHeader.style.display = 'none';   
    }

    collapsibleHeader.addEventListener('click', () => {
        if (isCollapsed) {
            collapsible.style.display = 'block';  
            systemHeader.style.display = 'block';  
            toggleIcon.classList.add('rotated');  
        } else {
            collapsible.style.display = 'none';   
            systemHeader.style.display = 'none';   
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
<div class="section-container">
<ul class="nav nav-pills mb-3" id="logTabs" role="tablist">
    <li class="nav-item" role="presentation">
        <a class="nav-link" id="pluginLogTab" data-bs-toggle="pill" href="#pluginLog" role="tab" aria-controls="pluginLog" aria-selected="true"><span data-translate="nekoBoxLog"></span></a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link" id="mihomoLogTab" data-bs-toggle="pill" href="#mihomoLog" role="tab" aria-controls="mihomoLog" aria-selected="false"><span data-translate="mihomoLog"></span></a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link" id="singboxLogTab" data-bs-toggle="pill" href="#singboxLog" role="tab" aria-controls="singboxLog" aria-selected="false"><span data-translate="singboxLog"></span></a>
    </li>
</ul>
<div class="tab-content" id="logTabsContent">
    <div class="tab-pane fade" id="pluginLog" role="tabpanel" aria-labelledby="pluginLogTab">
        <div class="card log-card">
            <div class="card-body">
                <pre id="plugin_log" class="log-container form-control" style="resize: vertical; overflow: auto; height: 370px; white-space: pre-wrap;" contenteditable="true"></pre>
            </div>
            <div class="card-footer text-center">
                <form action="index.php" method="post">
                    <button type="submit" name="clear_plugin_log" class="btn btn-danger"><i class="bi bi-trash"></i> <span data-translate="clearLog"></span></button>
                </form>
            </div>
        </div>
    </div>

    <div class="tab-pane fade" id="mihomoLog" role="tabpanel" aria-labelledby="mihomoLogTab">
        <div class="card log-card">
            <div class="card-body">
                <pre id="bin_logs" class="log-container form-control" style="resize: vertical; overflow: auto; height: 370px; white-space: pre-wrap;" contenteditable="true"></pre>
            </div>
            <div class="card-footer text-center">
                <form action="index.php" method="post">
                    <button type="submit" name="neko" value="clear" class="btn btn-danger"><i class="bi bi-trash"></i> <span data-translate="clearLog"></span></button>
                </form>
            </div>
        </div>
    </div>

    <div class="tab-pane fade" id="singboxLog" role="tabpanel" aria-labelledby="singboxLogTab">
        <div class="card log-card">
            <div class="card-body">
                <pre id="singbox_log" class="log-container form-control" style="resize: vertical; overflow: auto; height: 370px; white-space: pre-wrap;" contenteditable="true"></pre>
            </div>
            <div class="card-footer text-center">
                <form action="index.php" method="post" class="form-inline">
                    <div class="form-check form-check-inline mb-2">
                        <input class="form-check-input" type="checkbox" id="autoRefresh" checked>
                        <label class="form-check-label" for="autoRefresh"><span data-translate="autoRefresh"></span></label>
                    </div>
                    <button type="submit" name="clear_singbox_log" class="btn btn-danger me-2"><i class="bi bi-trash"></i> <span data-translate="clearLog"></span></button>
                    <button type="button" class="btn btn-primary me-2" data-toggle="modal" data-target="#cronModal"><i class="bi bi-clock"></i> <span data-translate="scheduledRestart"></span></button>
                </form>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="cronModal" tabindex="-1" role="dialog" aria-labelledby="cronModalLabel" aria-hidden="true" data-backdrop="static" data-keyboard="false">
  <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="cronModalLabel" data-translate="setCronTitle"></h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body">
        <form id="cronForm" method="POST">
          <div class="form-group ">
            <label for="cronTime" data-translate="setRestartTime"></label>
            <input type="text" class="form-control mt-3" id="cronTime" name="cronTime" value="0 3 * * *" required>
          </div>
          <div class="alert alert-info mt-3">
            <strong><?= $langData[$currentLang]['tip'] ?>:</strong> <?= $langData[$currentLang]['cronFormat'] ?>:
            <ul>
              <li><code>分钟 小时 日 月 星期</code></li>
              <li><?= $langData[$currentLang]['example1'] ?>: <code>0 2 * * *</code></li>
              <li><?= $langData[$currentLang]['example2'] ?>: <code>0 3 * * 1</code></li>
              <li><?= $langData[$currentLang]['example3'] ?>: <code>0 9 * * 1-5</code></li>
            </ul>
          </div>
        </form>
        <div id="resultMessage" class="mt-3"></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-dismiss="modal" data-translate="cancel"></button>
        <button type="submit" class="btn btn-primary" form="cronForm" data-translate="save"></button>
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

