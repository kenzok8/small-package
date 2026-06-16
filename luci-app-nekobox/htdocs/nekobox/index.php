<?php
include './cfg.php';
$needRefresh = false;  
$str_cfg = substr($selected_config, strlen("$neko_dir/config") + 1);
$_IMG = '/luci-static/ssr/';
$singbox_bin = '/usr/bin/sing-box';
$singbox_log = '/var/log/singbox_log.txt';
$singbox_config_dir = '/etc/neko/config';
$log = '/etc/neko/tmp/log.txt';
$start_script_path = '/etc/neko/core/start.sh';

$neko_enabled = exec("uci -q get neko.cfg.enabled");
$singbox_enabled = exec("uci -q get neko.cfg.singbox_enabled");

$neko_status = ($neko_enabled == '1') ? '1' : '0';
$singbox_status = ($singbox_enabled == '1') ? '1' : '0';

$log_dir = dirname($log);
if (!file_exists($log_dir)) {
    mkdir($log_dir, 0755, true);
}

$start_script_template = <<<'EOF'
#!/bin/bash

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
    iifname { eth0, wlan0 } meta l4proto { tcp, udp } ct state new goto singbox-tproxy
  }
}
NFTABLES

elif command -v fw3 > /dev/null; then
    log "FW3 Detected. Starting iptables."

    iptables -t mangle -F
    iptables -t mangle -X
    ip6tables -t mangle -F
    ip6tables -t mangle -X

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
    iptables -t mangle -A PREROUTING -i eth0 -p tcp -j singbox-tproxy
    iptables -t mangle -A PREROUTING -i eth0 -p udp -j singbox-tproxy
    iptables -t mangle -A PREROUTING -i wlan0 -p tcp -j singbox-tproxy
    iptables -t mangle -A PREROUTING -i wlan0 -p udp -j singbox-tproxy

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
ENABLE_DEPRECATED_SPECIAL_OUTBOUNDS=true "$SINGBOX_BIN" run -c "$CONFIG_FILE"
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

LOG_FILES=("$log_file" "$tmp_log_file" "$additional_log_file")
LOG_NAMES=("Sing-box" "Mihomo" "NeKoBox")
MAX_SIZE=$max_size
LOG_PATH="/etc/neko/tmp/log.txt"

timestamp() {
    date "+[ %H:%M:%S ]"
}

check_and_clear_log() {
    local file="\$1"
    local name="\$2"
    if [ -f "\$file" ]; then
        if [ ! -r "\$file" ]; then
            echo "\$(timestamp) \$name log file (\$file) exists but is not readable. Check permissions." >> \$LOG_PATH
            return 1
        fi
        size=\$(ls -l "\$file" 2>/dev/null | awk '{print \$5}')
        if [ -z "\$size" ] || ! echo "\$size" | grep -q '^[0-9]\+$'; then
            echo "\$(timestamp) \$name log file (\$file) size could not be determined. ls command failed or output invalid." >> \$LOG_PATH
            return 1
        fi
        if [ \$size -gt \$MAX_SIZE ]; then
            echo "\$(timestamp) \$name log file (\$file) exceeded \$MAX_SIZE bytes (\$size). Clearing log..." >> \$LOG_PATH
            > "\$file"
            echo "\$(timestamp) \$name log file (\$file) has been cleared." >> \$LOG_PATH
        else
            echo "\$(timestamp) \$name log file (\$file) is within the size limit (\$size bytes). No action needed." >> \$LOG_PATH
        fi
    else
        echo "\$(timestamp) \$name log file (\$file) not found." >> \$LOG_PATH
    fi
}

for i in \${!LOG_FILES[@]}; do
    check_and_clear_log "\${LOG_FILES[\$i]}" "\${LOG_NAMES[\$i]}"
done

echo "\$(timestamp) Log rotation completed." >> \$LOG_PATH

(crontab -l 2>/dev/null | grep -v '/etc/neko/core/set_cron.sh'; echo "$cron_schedule") | sort -u | crontab -
EOL;

    $cronScriptPath = '/etc/neko/core/set_cron.sh';
    file_put_contents($cronScriptPath, $cronScriptContent);
    chmod($cronScriptPath, 0755);
    shell_exec("bash $cronScriptPath");
}

function rotateLogs($logFile, $maxSize = 1048576) {
    if (file_exists($logFile) && filesize($logFile) > $maxSize) {
        file_put_contents($logFile, '');
        chmod($logFile, 0644);
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
   writeToLog("Received Mihomo action: $dt");
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
   writeToLog("Mihomo action completed: $dt");
}

if (isset($_POST['singbox'])) {
    $action = $_POST['singbox'];
    $config_file = isset($_POST['config_file']) ? $_POST['config_file'] : '';
    
    writeToLog("Received singbox action: $action with config: $config_file");
    
    switch ($action) {
        case 'start':
            if (isNekoBoxRunning()) {
                writeToLog("Cannot start Sing-box: Sing-box is running");
            } elseif (!file_exists($config_file)) {
                writeToLog("Config file not found: $config_file");
            } else {
                writeToLog("Starting Sing-box");
                $singbox_version = trim(preg_replace(['/^Revision:.*$/m', '/sing-box version\s*/i'], '', shell_exec("$singbox_bin version")));
                writeToLog("Sing-box version: $singbox_version");
                
                shell_exec("mkdir -p " . dirname($singbox_log));
                shell_exec("touch $singbox_log && chmod 644 $singbox_log");
                rotateLogs($singbox_log);
                
                createStartScript($config_file);
                createCronScript();
                shell_exec("sh $start_script_path >> $singbox_log 2>&1 &");
                
                sleep(3);
                $pid = getSingboxPID();
                if ($pid) {
                    writeToLog("Sing-box started successfully. PID: $pid");
                    $needRefresh = true;
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
                sleep(1);
                if (isSingboxRunning()) {
                    writeToLog("Force killing Sing-box");
                    shell_exec("kill -9 $pid");
                }
                if (file_exists('/usr/sbin/fw4')) {
                    shell_exec("nft flush ruleset");
                } else {
                    shell_exec("iptables -t mangle -F");
                    shell_exec("iptables -t mangle -X");
                    shell_exec("ip6tables -t mangle -F");
                    shell_exec("ip6tables -t mangle -X");
                }
                shell_exec("/etc/init.d/firewall restart");
                writeToLog("Cleared firewall rules and restarted firewall");
                if (!isSingboxRunning()) {
                    writeToLog("Sing-box stopped successfully");
                    $needRefresh = true;
                }
            } else {
                writeToLog("Sing-box is not running");
            }
            break;
           
        case 'restart':
            if (isNekoBoxRunning()) {
                writeToLog("Cannot restart Sing-box: Sing-box is running");
            } elseif (!file_exists($config_file)) {
                writeToLog("Config file not found: $config_file");
            } else {
                writeToLog("Restarting Sing-box");
                $pid = getSingboxPID();
                if ($pid) {
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
                    writeToLog("Sing-box restarted successfully. New PID: $new_pid");
                    $needRefresh = true;
                } else {
                    writeToLog("Failed to restart Sing-box");
                }
            }
            break;
    }  
    
    sleep(2);
    $singbox_status = isSingboxRunning() ? '1' : '0';
    shell_exec("uci set neko.cfg.singbox_enabled='$singbox_status'");
    shell_exec("uci commit neko");
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
if ($needRefresh):
?>
<script>
window.addEventListener('load', function() {
    if (!sessionStorage.getItem('refreshed')) {
        sessionStorage.setItem('refreshed', 'true');
        window.location.reload();
    } else {
        sessionStorage.removeItem('refreshed');
    }
});
</script>
<?php endif; ?>

<?php
$confDirectory = '/etc/neko/config';  
$storageFile = '/www/nekobox/lib/singbox.txt';

$storageDir = dirname($storageFile);
if (!is_dir($storageDir)) {
    mkdir($storageDir, 0755, true);
}

if (!file_exists($storageFile)) {
    file_put_contents($storageFile, '');
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
    $isNginx = false;
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

    $timezone = trim(shell_exec("uci get system.@system[0].zonename 2>/dev/null"));
    if (!$timezone) {
        $timezone = 'UTC';
    }
    date_default_timezone_set($timezone);
    $currentTime = date("Y-m-d H:i:s");

    echo json_encode([
        'systemInfo' => "$devices - $fullOSInfo",
        'ramUsage' => "$ramUsage/$ramTotal MB",
        'cpuLoad' => "$cpuLoadAvg1Min $cpuLoadAvg5Min $cpuLoadAvg15Min",
        'uptime' => "{$days} days {$hours} hours {$minutes} minutes {$seconds} seconds",
        'cpuLoadAvg1Min' => $cpuLoadAvg1Min,
        'ramTotal' => $ramTotal,
        'ramUsageOnly' => $ramUsage,
        'timezone' => $timezone,
        'currentTime' => $currentTime,
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

<meta charset="utf-8">
<title>Home - Nekobox</title>
<link rel="icon" href="./assets/img/nekobox.png">
<?php include './ping.php'; ?>

<?php if ($isNginx): ?>
    <div id="nginxWarning"
         class="alert alert-warning alert-dismissible fade show"
         role="alert"
         style="position: fixed; top: 20px; left: 50%; transform: translateX(-50%); z-index: 1050;">
        <strong data-translate="nginxWarningStrong"></strong> 
        <span data-translate="nginxWarning"></span>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>

    <script>
    document.addEventListener("DOMContentLoaded", function () {
        const lastWarningTime = localStorage.getItem('nginxWarningTime');
        const currentTime = new Date().getTime();
        const warningInterval = 12 * 60 * 60 * 1000;

        if (!lastWarningTime || currentTime - lastWarningTime > warningInterval) {
            localStorage.setItem('nginxWarningTime', currentTime);

            const warningAlert = document.getElementById('nginxWarning');
            if (warningAlert) {
                warningAlert.style.display = 'block';

                setTimeout(function () {
                    warningAlert.classList.remove('show');
                    setTimeout(function () {
                        warningAlert.remove();
                    }, 300);
                }, 5000);
            }
        }
    });
    </script>
<?php endif; ?>
<div class="container-sm container-bg mt-0">
    <?php include 'navbar.php'; ?>
    <div class="container-sm text-center col-8">
        <img src="./assets/img/nekobox.png" alt="Icon" class="centered-img">
        <div id="version-info" class="d-flex align-items-center justify-content-center mt-1 gap-1">
            <a id="version-link"
               href="https://github.com/Thaolga/openwrt-nekobox/releases"
               target="_blank">
                <img id="current-version" src="./assets/img/curent.svg" alt="Current Version" class="img-fluid" style="height:23px;">
            </a>
        </div>
    </div>

<h2 id="neko-title" class="neko-title-style m-2" style="cursor: pointer;" data-bs-toggle="modal" data-bs-target="#systemInfoModal">NekoBox</h2>
<?php
function getSingboxVersion() {
    $singBoxPath = '/usr/bin/sing-box'; 
    $command = "$singBoxPath version 2>&1";
    exec($command, $output, $returnVar);

    if ($returnVar === 0) {
        foreach ($output as $line) {
            if (strpos($line, 'version') !== false) {
                $parts = explode(' ', $line);
                return end($parts);
            }
        }
    }

    return 'Not installed';
}

function getMihomoVersion() {
    $mihomoPath = '/usr/bin/mihomo';
    
    if (!file_exists($mihomoPath)) {
        return 'Not installed';
    }
    
    $command = "$mihomoPath -v 2>&1";  
    exec($command, $output, $returnVar);

    if ($returnVar === 0 && !empty($output)) {
        $line = trim($output[0]);

        if (preg_match('/Mihomo Meta\s+([^\s]+)/i', $line, $matches)) {
            return $matches[1];
        }

        return $line;
    }

    return 'Command failed: ' . $returnVar;
}


$singboxVersion = getSingboxVersion();
$mihomoVersion  = getMihomoVersion();
?>
<div class="px-0 px-sm-4 mt-3 control-box">
    <div class="card">
        <div class="card-body">
            <div class="mb-4">
                <h6 class="mb-2"><i data-feather="activity"></i> <span data-translate="status">Status</span></h6>
                <div class="btn-group w-100" role="group">
                    <?php if ($neko_status == '1'): ?>
                        <button type="button" class="btn btn-success">
                            <i class="bi bi-router"></i> 
                            <span data-translate="mihomoRunning" data-index="(<?= htmlspecialchars($mihomoVersion) ?>)"></span>
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

                    <?php if ($singbox_status == '1'): ?>
                        <button type="button" class="btn btn-success">
                            <i class="bi bi-hdd-stack"></i> 
                            <span data-translate="singboxRunning" data-index="(<?= htmlspecialchars($singboxVersion) ?>)"></span>
                        </button>
                    <?php else: ?>
                        <button type="button" class="btn btn-outline-danger">
                            <i class="bi bi-hdd-stack"></i> 
                            <span data-translate="singboxNotRunning">Sing-box Not Running</span>
                        </button>
                    <?php endif; ?>
                </div>
            </div>

            <div class="mb-4 control-box" id="mihomoControl">
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
                        
                        <div class="btn-group w-100  position-relative" style="top: 25px;">
                            <button type="submit" name="neko" value="start" 
                                    class="btn btn<?= ($neko_status == 1) ? "-outline" : "" ?>-success">
                                <i class="bi bi-power"></i> 
                                <span data-translate="enableMihomo">Enable Mihomo</span>
                            </button>
                            <button type="submit" name="neko" value="disable" 
                                    class="btn btn<?= ($neko_status == 0) ? "-outline" : "" ?>-danger">
                                <i class="bi bi-x-octagon"></i> 
                                <span data-translate="disableMihomo">Disable Mihomo</span>
                            </button>
                            <button type="submit" name="neko" value="restart" 
                                    class="btn btn<?= ($neko_status == 0) ? "-outline" : "" ?>-warning">
                                <i class="bi bi-arrow-clockwise"></i> 
                                <span data-translate="restartMihomo">Restart Mihomo</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <div class="mb-4 control-box" id="singboxControl">
                <h6 class="mb-2"><i data-feather="codesandbox"></i> <span data-translate="singboxControl">Singbox Control</span><i class="fas fa-question-circle ms-1" data-tooltip="first_time_singbox_user" style="cursor: help;"></i></h6>
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
                        
                        <div class="btn-group w-100 position-relative" style="top: 25px;">
                            <button type="submit" name="singbox" value="start" 
                                    class="btn btn<?= ($singbox_status == 1) ? "-outline" : "" ?>-success">
                                <i class="bi bi-power"></i> 
                                <span data-translate="enableSingbox">Enable Sing-box</span>
                            </button>
                            <button type="submit" name="singbox" value="disable" 
                                    class="btn btn<?= ($singbox_status == 0) ? "-outline" : "" ?>-danger">
                                <i class="bi bi-x-octagon"></i> 
                                <span data-translate="disableSingbox">Disable Sing-box</span>
                            </button>
                            <button type="submit" name="singbox" value="restart" 
                                    class="btn btn<?= ($singbox_status == 0) ? "-outline" : "" ?>-warning">
                                <i class="bi bi-arrow-clockwise"></i> 
                                <span data-translate="restartSingbox">Restart Sing-box</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <div class="mb-4">
                <h6 class="mb-2"><i class="bi bi-gear-fill custom-icon"></i> <span data-translate="runningMode">Running Mode</span></h6>
                <div class="btn-group w-100">
                    <?php
                    $mode_placeholder = '';
                    if ($neko_status == '1') {
                        $mode_placeholder = $neko_cfg['echanced'] . " | " . $neko_cfg['mode'];
                    } elseif ($singbox_status == '1') {
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

<style>
.centered-img {
	display: block;
	margin-left: auto;
	margin-right: auto;
	width: 12%;
	height: auto;
	min-width: 40px;
	max-width: 100%;
}

@media (max-width: 576px) {
	.centered-img {
		width: 30%;
	}
}

.btn-group .btn {
	width: 120%;
}

.custom-icon {
	width: 20px !important;
	height: 20px !important;
	vertical-align: middle !important;
	margin-right: 5px !important;
	stroke: #FF00FF !important;
	fill: none !important;
}

@media (max-width: 767px) {
	.control-box .table {
		display: block;
		width: 100%;
	}

	.control-box .table tbody,
        .control-box .table thead,
        .control-box .table tr {
		display: block;
	}

	.control-box .table td {
		display: block;
		width: 100%;
		padding: 10px;
		border: 1px solid #ddd;
		margin-bottom: 10px;
	}

	.control-box .table td:first-child {
		font-weight: bold;
		background-color: #f8f9fa;
	}

	.control-box .btn-group {
		display: flex;
		flex-direction: column;
		gap: 10px;
	}

	.control-box .form-select,
        .control-box .form-control,
        .control-box .input-group {
		width: 100%;
		font-size: 14px;
	}

	#mihomoControl .btn,
        #singboxControl .btn,
        .control-box .btn-group .btn {
		border-radius: 0.5rem !important;
	}

	.control-box .btn {
		width: 100%;
		font-size: 14px;
	}
}

@media (max-width: 768px) {
	#neko-title.neko-title-style {
		font-size: 2.7rem !important;
	}
}

.form-inline {
	display: inline-block;
}

@media (max-width: 767px) {
	#logTabs .nav-item {
		display: block;
		width: 100%;
	}
}

#logTabs {
	margin-top: 1rem;
	margin-bottom: 1rem;
	font-size: 1.3rem;
	color: var(--text-primary);
	display: flex;
	gap: 1rem;
	flex-wrap: wrap;
}

#logTabs .nav-link {
	all: unset;
	display: inline-block;
	cursor: pointer;
	padding: 0;
	color: inherit !important;
	font-weight: inherit !important;
	text-decoration: none !important;
}

#logTabs .nav-link.active {
	font-weight: 700 !important;
	color: var(--accent-color) !important;
}
</style>
  <div class="modal fade" id="systemInfoModal" tabindex="-1" aria-labelledby="systemInfoModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-xl">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title d-flex align-items-center" id="systemInfoModalLabel">
            <span style="width: 320px;" data-translate="systemInfo">System Information</span>
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <div class="mb-3 d-flex align-items-center">
            <h6 class="mb-0" style="width: 320px;">
              <i data-feather="cpu" class="me-2"></i><span data-translate="systemInfo">System Info</span>
            </h6>
            <div class="flex-grow-1">
              <span id="systemInfo" class="form-control text-start ps-3"></span>
            </div>
          </div>
          <div class="mb-3 d-flex align-items-center">
            <h6 class="mb-0" style="width: 320px;">
              <i data-feather="database" class="me-2"></i><span data-translate="systemMemory">System Memory</span>
            </h6>
            <div class="flex-grow-1">
              <span id="ramUsage" class="form-control text-start ps-3"></span>
            </div>
          </div>
          <div class="mb-3 d-flex align-items-center">
            <h6 class="mb-0" style="width: 320px;">
              <i data-feather="zap" class="me-2"></i><span data-translate="avgLoad">Average Load</span>
            </h6>
            <div class="flex-grow-1">
              <span id="cpuLoad" class="form-control text-start ps-3"></span>
            </div>
          </div>
          <div class="mb-3 d-flex align-items-center">
            <h6 class="mb-0" style="width: 320px;">
              <i data-feather="globe" class="me-2"></i><span data-translate="systemTimezone">System Timezone</span>
            </h6>
            <div class="flex-grow-1">
              <span id="systemTimezone" class="form-control text-start ps-3"></span>
            </div>
          </div>
          <div class="mb-3 d-flex align-items-center">
            <h6 class="mb-0" style="width: 320px;">
              <i data-feather="clock" class="me-2"></i><span data-translate="currentTime">Current Time</span>
            </h6>
            <div class="flex-grow-1">
              <span id="systemCurrentTime" class="form-control text-start ps-3"></span>
            </div>
          </div>
          <div class="mb-3 d-flex align-items-center">
            <h6 class="mb-0" style="width: 320px;">
              <i data-feather="clock" class="me-2"></i><span data-translate="uptime">Uptime</span>
            </h6>
            <div class="flex-grow-1">
              <span id="uptime" class="form-control text-start ps-3"></span>
            </div>
          </div>
          <div class="mb-3 d-flex align-items-center">
            <h6 class="mb-0" style="width: 320px;">
              <i data-feather="bar-chart-2" class="me-2"></i><span data-translate="trafficStats">Traffic Stats</span>
            </h6>
            <div class="flex-grow-1">
              <span class="form-control text-start ps-3">
                <i class="fa fa-download me-1"></i><span id="downtotal"></span> | 
                <i class="fa fa-upload me-1"></i><span id="uptotal"></span>
              </span>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close">Close</button>
        </div>
      </div>
    </div>
  </div>
<script>
document.addEventListener('DOMContentLoaded', function() {
    function fetchSystemStatus() {
        fetch('?ajax=1')
            .then(response => response.json())
            .then(data => {
                const systemInfoEl = document.getElementById('systemInfo');
                if (systemInfoEl) systemInfoEl.innerText = data.systemInfo;

                const ramUsageEl = document.getElementById('ramUsage');
                if (ramUsageEl) ramUsageEl.innerText = data.ramUsage;

                const cpuLoadEl = document.getElementById('cpuLoad');
                if (cpuLoadEl) cpuLoadEl.innerText = data.cpuLoad;

                const timezoneEl = document.getElementById('systemTimezone');
                if (timezoneEl) timezoneEl.innerText = data.timezone;

                const currentTimeEl = document.getElementById('systemCurrentTime');
                if (currentTimeEl) currentTimeEl.innerText = data.currentTime;

                const uptimeEl = document.getElementById('uptime');
                if (uptimeEl) {
                    let uptimeText = data.uptime;
                    if (typeof uptimeText === 'string') {
                        uptimeText = uptimeText.replace(/days/, translations['days'] || 'days')
                                               .replace(/hours/, translations['hours'] || 'hours')
                                               .replace(/minutes/, translations['minutes'] || 'minutes')
                                               .replace(/seconds/, translations['seconds'] || 'seconds');
                        uptimeEl.innerText = uptimeText;
                    } else {
                        uptimeEl.innerText = data.uptime;
                    }
                }

                const cpuLoadAvg1MinEl = document.getElementById('cpuLoadAvg1Min');
                if (cpuLoadAvg1MinEl) cpuLoadAvg1MinEl.innerText = data.cpuLoadAvg1Min;

                const ramUsageOnlyEl = document.getElementById('ramUsageOnly');
                if (ramUsageOnlyEl) ramUsageOnlyEl.innerText = data.ramUsageOnly + ' / ' + data.ramTotal + ' MB';
            })
            .catch(error => console.error('Error fetching data:', error));
    }

    setInterval(fetchSystemStatus, 1000);
    fetchSystemStatus();
});
</script>

<div class="px-0 px-sm-4 mt-4">
    <div class="card border-1">
        <ul class="nav nav-tabs mb-0 border-bottom-0 text-center" id="logTabs" role="tablist">
            <li class="nav-item mb-2 me-1" role="presentation">
                <a class="nav-link" id="pluginLogTab" data-bs-toggle="pill" href="#pluginLog" role="tab" aria-controls="pluginLog" aria-selected="true">
                    <span data-translate="nekoBoxLog"></span>
                </a>
            </li>
            <li class="nav-item" role="presentation">
                <a class="nav-link" id="mihomoLogTab" data-bs-toggle="pill" href="#mihomoLog" role="tab" aria-controls="mihomoLog" aria-selected="false">
                    <span data-translate="mihomoLog"></span>
                </a>
            </li>
            <li class="nav-item" role="presentation">
                <a class="nav-link" id="singboxLogTab" data-bs-toggle="pill" href="#singboxLog" role="tab" aria-controls="singboxLog" aria-selected="false">
                    <span data-translate="singboxLog"></span>
                </a>
            </li>
        </ul>

        <div class="tab-content px-3 py-1" id="logTabsContent">
            <div class="tab-pane fade" id="pluginLog" role="tabpanel" aria-labelledby="pluginLogTab">
                <div class="log-content-container mb-1">
                    <pre id="plugin_log" class="log-content-area" spellcheck="false"></pre>
                </div>
                <div class="log-actions mt-1">
                    <form action="index.php" method="post">
                        <button type="submit" name="clear_plugin_log" class="btn btn-clear-log">
                            <i class="bi bi-trash"></i> <span data-translate="clearLog"></span>
                        </button>
                    </form>
                </div>
            </div>

            <div class="tab-pane fade" id="mihomoLog" role="tabpanel" aria-labelledby="mihomoLogTab">
                <div class="log-content-container mb-1">
                    <pre id="bin_logs" class="log-content-area" spellcheck="false"></pre>
                </div>
                <div class="log-actions mt-1">
                    <form action="index.php" method="post">
                        <button type="submit" name="neko" value="clear" class="btn btn-clear-log">
                            <i class="bi bi-trash"></i> <span data-translate="clearLog"></span>
                        </button>
                    </form>
                </div>
            </div>

            <div class="tab-pane fade" id="singboxLog" role="tabpanel" aria-labelledby="singboxLogTab">
                <div class="log-content-container mb-1">
                    <pre id="singbox_log" class="log-content-area" spellcheck="false"></pre>
                </div>
                <div class="log-actions multiple-actions mt-1">
                    <form action="index.php" method="post">
                        <div class="log-action-group">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="autoRefresh" checked>
                                <label class="form-check-label" for="autoRefresh">
                                    <span data-translate="autoRefresh"></span>
                                </label>
                            </div>
                            <button type="submit" name="clear_singbox_log" class="btn btn-clear-log">
                                <i class="bi bi-trash"></i> <span data-translate="clearLog"></span>
                            </button>
                            <button type="button" class="btn btn-schedule" data-bs-toggle="modal" data-bs-target="#cronModal">
                                <i class="bi bi-clock"></i> <span data-translate="scheduledRestart"></span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<footer class="text-center mt-1">
    <p><?php echo $footer ?></p>
</footer>

<div class="modal fade" id="cronModal" tabindex="-1" role="dialog" aria-labelledby="cronModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
  <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="cronModalLabel" data-translate="setCronTitle"></h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <form id="cronForm" method="POST" class="no-loader">
          <div class="form-group ">
            <label for="cronTime" data-translate="setRestartTime"></label>
            <input type="text" class="form-control mt-3" id="cronTime" name="cronTime" value="0 3 * * *" required>
          </div>
          <div class="alert alert-info mt-3">
            <strong><?= $langData[$currentLang]['tip'] ?>:</strong> <?= $langData[$currentLang]['cronFormat'] ?>:
            <ul>
              <li><span data-translate="cron_format_help"></span></li>
              <li><?= $langData[$currentLang]['example1'] ?>: <code>0 2 * * *</code></li>
              <li><?= $langData[$currentLang]['example2'] ?>: <code>0 3 * * 1</code></li>
              <li><?= $langData[$currentLang]['example3'] ?>: <code>0 9 * * 1-5</code></li>
            </ul>
          </div>
        </form>
        <div id="resultMessage" class="mt-3"></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancel"></button>
        <button type="submit" class="btn btn-primary" form="cronForm" data-translate="save"></button>
      </div>
    </div>
  </div>
</div>

<script>
$(document).ready(function() {
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
                $('#resultMessage').html('<div class="alert alert-danger">Failed to set up Cron job, please try again!</div>');
            }
        });
    });

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

    const defaultIcon = './assets/img/curent.svg';
    const latestIcon  = './assets/img/Latest.svg';
    const versionFile = 'version_debug.json';
    const intervalSec = 5 * 60;

    function compareVersions(current, latest) {
        if (!current || !latest) return null;
        const parseVersion = (version) => {
            const parts = version.split("-");
            const mainVersion = parts[0].split(".").map(num => parseInt(num, 10));
            const preRelease = parts[1] || "";
            let preReleaseType = "", preReleaseNum = 0;
            if (/^r\d+$/i.test(preRelease)) { preReleaseType = "r"; preReleaseNum = parseInt(preRelease.replace(/\D+/g,"")); }
            else if (/^rc\d+$/i.test(preRelease)) { preReleaseType = "rc"; preReleaseNum = parseInt(preRelease.replace(/\D+/g,"")); }
            return { mainVersion, preReleaseType, preReleaseNum };
        };
        const order = { "":0, "r":1, "rc":2 };
        const cur = parseVersion(current);
        const lat = parseVersion(latest);
        const len = Math.max(cur.mainVersion.length, lat.mainVersion.length);
        for (let i=0;i<len;i++){
            const a=cur.mainVersion[i]||0, b=lat.mainVersion[i]||0;
            if(a>b) return 1; if(a<b) return -1;
        }
        if(order[cur.preReleaseType] !== order[lat.preReleaseType]) return order[cur.preReleaseType]-order[lat.preReleaseType];
        if(cur.preReleaseNum>lat.preReleaseNum) return 1;
        if(cur.preReleaseNum<lat.preReleaseNum) return -1;
        return 0;
    }

    function loadVersionJSON(callback) {
        $.getJSON(versionFile, function(data) {
            callback(data);
        }).fail(function() {
            callback(null);
        });
    }

    function checkForUpdate() {
        loadVersionJSON(function(data){
            const now = Math.floor(Date.now()/1000);
            if(!data || !data.timestamp || now - data.timestamp > intervalSec){
                $.getJSON('check_update.php', function(newData){
                    updateIcon(newData);
                });
            } else {
                updateIcon(data);
            }
        });
    }

    function updateIcon(data){
        if(!data) { $('#current-version').attr('src', defaultIcon); return; }
        const hasUpdate = compareVersions(data.currentVersion, data.latestVersion) < 0;
        $('#current-version').attr('src', hasUpdate ? latestIcon : defaultIcon);
        //console.log("Current:", data.currentVersion, "Latest:", data.latestVersion, "Update:", hasUpdate);
    }

    $(document).ready(function(){
        checkForUpdate();
        setInterval(checkForUpdate, 60 * 1000);
    });

    const tabElms = document.querySelectorAll('#logTabs .nav-link');
    const savedTabId = localStorage.getItem('activeTab') || 'pluginLogTab';
    const savedTab = document.getElementById(savedTabId);
    if (savedTab) {
        const tab = new bootstrap.Tab(savedTab);
        tab.show();
    }
    tabElms.forEach(tab => {
        tab.addEventListener('shown.bs.tab', function(event) {
            localStorage.setItem('activeTab', event.target.id);
        });
    });

    const autoRefreshCheckbox = document.getElementById('autoRefresh');
    let refreshInterval;
    
    const autoRefreshSetting = localStorage.getItem('autoRefresh');
    autoRefreshCheckbox.checked = autoRefreshSetting === null || autoRefreshSetting === 'true';
    
    function scrollToBottom(id) {
        const el = document.getElementById(id);
        if (el) el.scrollTop = el.scrollHeight;
    }

    function handleAutoScroll() {
        if (autoRefreshCheckbox.checked) {
            scrollToBottom('plugin_log');
            scrollToBottom('singbox_log');
            scrollToBottom('bin_logs');
        }
    }

    function fetchLogs() {
        Promise.all([
            fetch('fetch_logs.php?file=plugin_log'),
            fetch('fetch_logs.php?file=singbox_log')
        ])
        .then(responses => Promise.all(responses.map(res => res.text())))
        .then(([pluginData, singboxData]) => {
            document.getElementById('plugin_log').textContent = pluginData;
            document.getElementById('singbox_log').textContent = singboxData;
            handleAutoScroll();
        })
        .catch(err => console.error('Error fetching logs:', err));
    }

    function setupRefreshInterval() {
        if (autoRefreshCheckbox.checked) {
            refreshInterval = setInterval(fetchLogs, 5000);
        }
    }
    
    autoRefreshCheckbox.addEventListener('change', function() {
        localStorage.setItem('autoRefresh', this.checked);
        clearInterval(refreshInterval);
        if (this.checked) {
            setupRefreshInterval();
        }
    });

    fetchLogs();
    handleAutoScroll();
    setupRefreshInterval();
});
</script>

