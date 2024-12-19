<?php
ob_start();
include './cfg.php';
ini_set('memory_limit', '256M');

$subscription_file = '/etc/neko/subscription.txt'; 
$download_path = '/etc/neko/config/'; 
$sh_script_path = '/etc/neko/core/update_config.sh'; 
$log_file = '/var/log/neko_update.log'; 

$current_subscription_url = ''; 
if (isset($_POST['subscription_url'])) {
    $current_subscription_url = $_POST['subscription_url'];
}

function logMessage($message) {
    global $log_file;
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($log_file, "[$timestamp] $message\n", FILE_APPEND);
}

function buildFinalUrl($subscription_url, $config_url, $include, $exclude, $backend_url, $emoji, $udp, $xudp, $tfo, $tls13, $fdn, $sort, $rename) {
    $encoded_subscription_url = urlencode($subscription_url);
    $encoded_config_url = urlencode($config_url);
    $encoded_include = urlencode($include);
    $encoded_exclude = urlencode($exclude);
    $encoded_rename = urlencode($rename); 
    $final_url = "{$backend_url}target=clash&url={$encoded_subscription_url}&insert=false&config={$encoded_config_url}";

    if (!empty($include)) {
        $final_url .= "&include={$encoded_include}";
    }
    if (!empty($exclude)) {
        $final_url .= "&exclude={$encoded_exclude}";
    }

    $final_url .= "&emoji=" . (isset($_POST['emoji']) && $_POST['emoji'] === 'true' ? "true" : "false");
    $final_url .= "&xudp=" . (isset($_POST['xudp']) && $_POST['xudp'] === 'true' ? "true" : "false");
    $final_url .= "&udp=" . (isset($_POST['udp']) && $_POST['udp'] === 'true' ? "true" : "false");
    $final_url .= "&tfo=" . (isset($_POST['tfo']) && $_POST['tfo'] === 'true' ? "true" : "false");
    $final_url .= "&fdn=" . (isset($_POST['fdn']) && $_POST['fdn'] === 'true' ? "true" : "false");
    $final_url .= "&tls13=" . (isset($_POST['tls13']) && $_POST['tls13'] === 'true' ? "true" : "false");
    $final_url .= "&sort=" . (isset($_POST['sort']) && $_POST['sort'] === 'true' ? "true" : "false");
    $final_url .= "&list=false&expand=true&scv=false&new_name=true";

    return $final_url;
}

function saveSubscriptionUrlToFile($url, $file) {
    $success = file_put_contents($file, $url) !== false;
    logMessage($success ? "订阅链接已保存到 $file" : "保存订阅链接失败到 $file");
    return $success;
}

function transformContent($content) {
    $new_config_start = "redir-port: 7892
port: 7890
socks-port: 7891
mixed-port: 7893
mode: rule
log-level: info
allow-lan: true
unified-delay: true
external-controller: 0.0.0.0:9090
secret: Akun
bind-address: 0.0.0.0
external-ui: ui
tproxy-port: 7895
tcp-concurrent: true    
enable-process: true
find-process-mode: always
ipv6: true
experimental:
  ignore-resolve-fail: true
  sniff-tls-sni: true
  tracing: true
hosts:
  \"localhost\": 127.0.0.1
profile:
  store-selected: true
  store-fake-ip: true
sniffer:
  enable: true
  sniff:
    http: { ports: [1-442, 444-8442, 8444-65535], override-destination: true }
    tls: { ports: [1-79, 81-8079, 8081-65535], override-destination: true }
  force-domain:
      - \"+.v2ex.com\"
      - www.google.com
      - google.com
  skip-domain:
      - Mijia Cloud
      - dlg.io.mi.com
  sniffing:
    - tls
    - http
  port-whitelist:
    - \"80\"
    - \"443\"
tun:
  enable: true
  prefer-h3: true
  listen: 0.0.0.0:53
  stack: gvisor
  dns-hijack:
     - \"any:53\"
     - \"tcp://any:53\"
  auto-redir: true
  auto-route: true
  auto-detect-interface: true
dns:
  enable: true
  ipv6: true
  default-nameserver:
    - '1.1.1.1'
    - '8.8.8.8'
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  fake-ip-filter:
    - 'stun.*.*'
    - 'stun.*.*.*'
    - '+.stun.*.*'
    - '+.stun.*.*.*'
    - '+.stun.*.*.*.*'
    - '+.stun.*.*.*.*.*'
    - '*.lan'
    - '+.msftncsi.com'
    - msftconnecttest.com
    - 'time?.*.com'
    - 'time.*.com'
    - 'time.*.gov'
    - 'time.*.apple.com'
    - time-ios.apple.com
    - 'time1.*.com'
    - 'time2.*.com'
    - 'time3.*.com'
    - 'time4.*.com'
    - 'time5.*.com'
    - 'time6.*.com'
    - 'time7.*.com'
    - 'ntp?.*.com'
    - 'ntp.*.com'
    - 'ntp1.*.com'
    - 'ntp2.*.com'
    - 'ntp3.*.com'
    - 'ntp4.*.com'
    - 'ntp5.*.com'
    - 'ntp6.*.com'
    - 'ntp7.*.com'
    - '+.pool.ntp.org'
    - '+.ipv6.microsoft.com'
    - speedtest.cros.wr.pvp.net
    - network-test.debian.org
    - detectportal.firefox.com
    - cable.auth.com
    - miwifi.com
    - routerlogin.com
    - routerlogin.net
    - tendawifi.com
    - tendawifi.net
    - tplinklogin.net
    - tplinkwifi.net
    - '*.xiami.com'
    - tplinkrepeater.net
    - router.asus.com
    - '*.*.*.srv.nintendo.net'
    - '*.*.stun.playstation.net'
    - '*.openwrt.pool.ntp.org'
    - resolver1.opendns.com
    - 'GC._msDCS.*.*'
    - 'DC._msDCS.*.*'
    - 'PDC._msDCS.*.*'
  use-hosts: true
  nameserver:
    - '8.8.4.4'
    - '1.0.0.1'
    - \"https://1.0.0.1/dns-query\"
    - \"https://8.8.4.4/dns-query\"
";

    $parts = explode('proxies:', $content, 2);
    if (count($parts) == 2) {
        return $new_config_start . "\nproxies:" . $parts[1];
    } else {
        return $content;
    }
}

function saveSubscriptionContentToYaml($url, $filename) {
    global $download_path;

    if (pathinfo($filename, PATHINFO_EXTENSION) !== 'yaml') {
        $filename .= '.yaml';
    }

    if (strpbrk($filename, "!@#$%^&*()+=[]\\\';,/{}|\":<>?") !== false) {
        $message = "文件名包含非法字符，请使用字母、数字、点、下划线或横杠。";
        logMessage($message);
        return $message;
    }

    if (!is_dir($download_path)) {
        if (!mkdir($download_path, 0755, true)) {
            $message = "无法创建目录：$download_path";
            logMessage($message);
            return $message;
        }
    }

    $output_file = escapeshellarg($download_path . $filename);
    $command = "wget -q --no-check-certificate -O $output_file " . escapeshellarg($url);
    exec($command, $output, $return_var);
    if ($return_var !== 0) {
        $message = "wget 错误，无法获取订阅内容。请检查链接是否正确。";
        logMessage($message);
    }
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
    $subscription_data = curl_exec($ch);

    if (curl_errno($ch)) {
        $error_msg = curl_error($ch);
        curl_close($ch);
        $message = "cURL 错误: $error_msg";
        logMessage($message);
        return $message;
    }
    curl_close($ch);

    if (empty($subscription_data)) {
        $message = "无法获取订阅内容。请检查链接是否正确。";
        logMessage($message);
        return $message;
    }

    $decoded_data = (base64_decode($subscription_data, true) !== false) ? base64_decode($subscription_data) : $subscription_data;
    $transformed_data = transformContent($decoded_data);

    $file_path = $download_path . $filename;
    $success = file_put_contents($file_path, $transformed_data) !== false;
    $message = $success ? "内容已成功保存到：$file_path" : "文件保存失败。";
    logMessage($message);
    return $message;
}

function generateShellScript() {
    global $subscription_file, $download_path, $sh_script_path;

    $sh_script_content = <<<EOD
#!/bin/bash

SUBSCRIPTION_FILE='$subscription_file'
DOWNLOAD_PATH='$download_path'
DEST_PATH='/etc/neko/config/config.yaml'

if [ ! -f "\$SUBSCRIPTION_FILE" ]; then
    echo "未找到订阅文件: \$SUBSCRIPTION_FILE"
    exit 1
fi

SUBSCRIPTION_URL=\$(cat "\$SUBSCRIPTION_FILE")

subscription_data=\$(wget -qO- "\$SUBSCRIPTION_URL")
if [ -z "\$subscription_data" ]; then
    echo "无法获取订阅内容，请检查订阅链接。"
    exit 1
fi

subscription_data=\$(echo "\$subscription_data" | sed '/port: 7890/d')
subscription_data=\$(echo "\$subscription_data" | sed '/socks-port: 7891/d')
subscription_data=\$(echo "\$subscription_data" | sed '/allow-lan: true/d')
subscription_data=\$(echo "\$subscription_data" | sed '/mode: Rule/d')
subscription_data=\$(echo "\$subscription_data" | sed '/log-level: info/d')
subscription_data=\$(echo "\$subscription_data" | sed '/external-controller: :9090/d')
subscription_data=\$(echo "\$subscription_data" | sed '/dns:/d')
subscription_data=\$(echo "\$subscription_data" | sed '/enabled: true/d')
subscription_data=\$(echo "\$subscription_data" | sed '/nameserver:/d')
subscription_data=\$(echo "\$subscription_data" | sed '/119.29.29.29/d')
subscription_data=\$(echo "\$subscription_data" | sed '/223.5.5.5/d')
subscription_data=\$(echo "\$subscription_data" | sed '/fallback:/d')
subscription_data=\$(echo "\$subscription_data" | sed '/8.8.8.8/d')
subscription_data=\$(echo "\$subscription_data" | sed '/8.8.4.4/d')
subscription_data=\$(echo "\$subscription_data" | sed '/tls:\/\/1.0.0.1:853/d')
subscription_data=\$(echo "\$subscription_data" | sed '/- tls:\/\/dns.google:853/d')

new_config_start="redir-port: 7892
port: 7890
socks-port: 7891
mixed-port: 7893
mode: rule
log-level: info
allow-lan: true
unified-delay: true
external-controller: 0.0.0.0:9090
secret: Akun
bind-address: 0.0.0.0
external-ui: ui
tproxy-port: 7895
tcp-concurrent: true
enable-process: true
find-process-mode: always
ipv6: true
experimental:
  ignore-resolve-fail: true
  sniff-tls-sni: true
  tracing: true
hosts:
  \"localhost\": 127.0.0.1
profile:
  store-selected: true
  store-fake-ip: true
sniffer:
  enable: true
  sniff:
    http: { ports: [1-442, 444-8442, 8444-65535], override-destination: true }
    tls: { ports: [1-79, 81-8079, 8081-65535], override-destination: true }
  force-domain:
      - \"+.v2ex.com\"
      - www.google.com
      - google.com
  skip-domain:
      - Mijia Cloud
      - dlg.io.mi.com
  sniffing:
    - tls
    - http
  port-whitelist:
    - \"80\"
    - \"443\"
tun:
  enable: true
  prefer-h3: true
  listen: 0.0.0.0:53
  stack: gvisor
  dns-hijack:
     - \"any:53\"
     - \"tcp://any:53\"
  auto-redir: true
  auto-route: true
  auto-detect-interface: true
dns:
  enable: true
  ipv6: true
  default-nameserver:
    - '1.1.1.1'
    - '8.8.8.8'
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  fake-ip-filter:
    - 'stun.*.*'
    - 'stun.*.*.*'
    - '+.stun.*.*'
    - '+.stun.*.*.*'
    - '+.stun.*.*.*.*'
    - '+.stun.*.*.*.*.*'
    - '*.lan'
    - '+.msftncsi.com'
    - msftconnecttest.com
    - 'time?.*.com'
    - 'time.*.com'
    - 'time.*.gov'
    - 'time.*.apple.com'
    - time-ios.apple.com
    - 'time1.*.com'
    - 'time2.*.com'
    - 'time3.*.com'
    - 'time4.*.com'
    - 'time5.*.com'
    - 'time6.*.com'
    - 'time7.*.com'
    - 'ntp?.*.com'
    - 'ntp.*.com'
    - 'ntp1.*.com'
    - 'ntp2.*.com'
    - 'ntp3.*.com'
    - 'ntp4.*.com'
    - 'ntp5.*.com'
    - 'ntp6.*.com'
    - 'ntp7.*.com'
    - '+.pool.ntp.org'
    - '+.ipv6.microsoft.com'
    - speedtest.cros.wr.pvp.net
    - network-test.debian.org
    - detectportal.firefox.com
    - cable.auth.com
    - miwifi.com
    - routerlogin.com
    - routerlogin.net
    - tendawifi.com
    - tendawifi.net
    - tplinklogin.net
    - tplinkwifi.net
    - '*.xiami.com'
    - tplinkrepeater.net
    - router.asus.com
    - '*.*.*.srv.nintendo.net'
    - '*.*.stun.playstation.net'
    - '*.openwrt.pool.ntp.org'
    - resolver1.opendns.com
    - 'GC._msDCS.*.*'
    - 'DC._msDCS.*.*'
    - 'PDC._msDCS.*.*'
  use-hosts: true
  nameserver:
    - '8.8.4.4'
    - '1.0.0.1'
    - \"https://1.0.0.1/dns-query\"
    - \"https://8.8.4.4/dns-query\"
"

echo -e "\$new_config_start\$subscription_data" > "\$DOWNLOAD_PATH/config.yaml"

mv "\$DOWNLOAD_PATH/config.yaml" "\$DEST_PATH"

if [ \$? -eq 0 ]; then
    echo "配置文件已成功更新并移动到 \$DEST_PATH"
else
    echo "配置文件移动失败"
    exit 1
fi
EOD;

    $success = file_put_contents($sh_script_path, $sh_script_content) !== false;
    logMessage($success ? "Shell 脚本已成功创建并赋予执行权限。" : "无法创建 Shell 脚本文件。");
    if ($success) {
        shell_exec("chmod +x $sh_script_path");
    }
    return $success ? "Shell 脚本已成功创建并赋予执行权限。" : "无法创建 Shell 脚本文件。";
}

function setupCronJob($cron_time) {
    global $sh_script_path;
    $cron_entry = "$cron_time $sh_script_path\n";
    $current_cron = shell_exec('crontab -l 2>/dev/null');

    if (empty($current_cron)) {
        $updated_cron = $cron_entry;
    } else {
        $updated_cron = preg_replace('/.*' . preg_quote($sh_script_path, '/') . '/m', $cron_entry, $current_cron);
        if ($updated_cron == $current_cron) {
            $updated_cron .= $cron_entry;
        }
    }

    $success = file_put_contents('/tmp/cron.txt', $updated_cron) !== false;
    if ($success) {
        shell_exec('crontab /tmp/cron.txt');
        logMessage("Cron 作业已成功设置为 $cron_time 运行。");
        return "Cron 作业已成功设置为 $cron_time 运行。";
    } else {
        logMessage("无法写入临时 Cron 文件。");
        return "无法写入临时 Cron 文件。";
    }
}

$result = '';
$cron_result = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $templates = [
        '1' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_NoAuto.ini?',
        '2' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_AdblockPlus.ini?',
        '3' => 'https://raw.githubusercontent.com/youshandefeiyang/webcdn/main/SONY.ini',
        '4' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/default_with_clash_adg.yml?',
        '5' => 'https://raw.githubusercontent.com/WC-Dream/ACL4SSR/WD/Clash/config/ACL4SSR_Online_Full_Dream.ini?',
        '6' => 'https://raw.githubusercontent.com/WC-Dream/ACL4SSR/WD/Clash/config/ACL4SSR_Mini_Dream.ini?',
        '7' => 'https://raw.githubusercontent.com/justdoiting/ClashRule/main/GeneralClashRule.ini?',
        '8' => 'https://raw.githubusercontent.com/cutethotw/ClashRule/main/GeneralClashRule.ini?',

        '9' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online.ini?',
        '10' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_NoAuto.ini?',
        '11' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_AdblockPlus.ini?',
        '12' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_MultiCountry.ini?',
        '13' => 'ttps://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_NoReject.ini?',
        '14' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Mini_NoAuto.ini?',
        '15' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full.ini?',
        '16' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_Google.ini?',
        '17' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_MultiMode.ini?',
        '18' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_Netflix.ini?',
        '19' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Mini.ini?',
        '20' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Mini_AdblockPlus.ini?',
        '21' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Mini_Fallback.ini?',
        '22' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Mini_MultiCountry.ini?',
        '23' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Mini_MultiMode.ini?',

        '24' => 'https://raw.githubusercontent.com/flyhigherpi/merlinclash_clash_related/master/Rule_config/ZHANG.ini?',
        '25' => 'https://raw.githubusercontent.com/xiaoshenxian233/cool/rule/complex.ini?',
        '26' => 'https://subweb.s3.fr-par.scw.cloud/RemoteConfig/special/phaors.ini?',
        '27' => 'https://raw.githubusercontent.com/flyhigherpi/merlinclash_clash_related/master/Rule_config/ZHANG_Area_Fallback.ini?',
        '28' => 'https://raw.githubusercontent.com/flyhigherpi/merlinclash_clash_related/master/Rule_config/ZHANG_Area_Urltest.ini?',
        '29' => 'https://raw.githubusercontent.com/flyhigherpi/merlinclash_clash_related/master/Rule_config/ZHANG_Area_NoAuto.ini?',
        '30' => 'https://raw.githubusercontent.com/OoHHHHHHH/ini/master/config.ini?',
        '31' => 'https://raw.githubusercontent.com/OoHHHHHHH/ini/master/cfw-tap.ini?',
        '32' => 'https://raw.githubusercontent.com/lhl77/sub-ini/main/tsutsu-full.ini?',
        '33' => 'https://raw.githubusercontent.com/lhl77/sub-ini/main/tsutsu-mini-gfw.ini?',
        '34' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/connershua_new.ini?',
        '35' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/connershua_backtocn.ini?',
        '36' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/lhie1_clash.ini?',
        '37' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/lhie1_dler.ini?',
        '38' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/ehpo1_main.ini?',
        '39' => 'https://raw.nameless13.com/api/public/dl/ROzQqi2S/white.ini?',
        '40' => 'https://raw.nameless13.com/api/public/dl/ptLeiO3S/mayinggfw.ini?',
        '41' => 'https://raw.nameless13.com/api/public/dl/FWSh3dXz/easy3.ini?',
        '42' => 'https://raw.nameless13.com/api/public/dl/L_-vxO7I/youtube.ini?',
        '43' => 'https://raw.nameless13.com/api/public/dl/zKF9vFbb/easy.ini?',
        '44' => 'https://raw.nameless13.com/api/public/dl/E69bzCaE/easy2.ini?',
        '45' => 'https://raw.nameless13.com/api/public/dl/XHr0miMg/ipip.ini?',
        '46' => 'https://raw.nameless13.com/api/public/dl/BBnfb5lD/MAYINGVIP.ini?',
        '47' => 'https://raw.githubusercontent.com/Mazeorz/airports/master/Clash/Examine.ini?',
        '48' => 'https://raw.githubusercontent.com/Mazeorz/airports/master/Clash/Examine_Full.ini?',
        '49' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/nzw9314_custom.ini?',
        '50' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/maicoo-l_custom.ini?',
        '51' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/dlercloud_lige_platinum.ini?',
        '52' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/dlercloud_lige_gold.ini?',
        '53' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/dlercloud_lige_silver.ini?',
        '54' => 'https://unpkg.com/proxy-script/config/Clash/clash.ini?',
        '55' => 'https://github.com/UlinoyaPed/ShellClash/raw/master/rules/ShellClash.ini?',

        '56' => 'https://gist.github.com/jklolixxs/16964c46bad1821c70fa97109fd6faa2/raw/EXFLUX.ini?',
        '57' => 'https://gist.github.com/jklolixxs/32d4e9a1a5d18a92beccf3be434f7966/raw/NaNoport.ini?',
        '58' => 'https://gist.github.com/jklolixxs/dfbe0cf71ffc547557395c772836d9a8/raw/CordCloud.ini?',
        '59' => 'https://gist.github.com/jklolixxs/e2b0105c8be6023f3941816509a4c453/raw/BigAirport.ini?',
        '60' => 'https://gist.github.com/jklolixxs/9f6989137a2cfcc138c6da4bd4e4cbfc/raw/PaoLuCloud.ini?',
        '61' => 'https://gist.github.com/jklolixxs/fccb74b6c0018b3ad7b9ed6d327035b3/raw/WaveCloud.ini?',
        '62' => 'https://gist.github.com/jklolixxs/bfd5061dceeef85e84401482f5c92e42/raw/JiJi.ini?',
        '63' => 'https://gist.github.com/jklolixxs/6ff6e7658033e9b535e24ade072cf374/raw/SJ.ini?',
        '64' => 'https://gist.github.com/jklolixxs/24f4f58bb646ee2c625803eb916fe36d/raw/ImmTelecom.ini?',
        '65' => 'https://gist.github.com/jklolixxs/b53d315cd1cede23af83322c26ce34ec/raw/AmyTelecom.ini?',
        '66' => 'https://subweb.s3.fr-par.scw.cloud/RemoteConfig/customized/convenience.ini?',
        '67' => 'https://gist.github.com/jklolixxs/ff8ddbf2526cafa568d064006a7008e7/raw/Miaona.ini?',
        '68' => 'https://gist.github.com/jklolixxs/df8fda1aa225db44e70c8ac0978a3da4/raw/Foo&Friends.ini?',
        '69' => 'https://gist.github.com/jklolixxs/b1f91606165b1df82e5481b08fd02e00/raw/ABCloud.ini?',
        '70' => 'https://raw.githubusercontent.com/SleepyHeeead/subconverter-config/master/remote-config/customized/xianyu.ini?',
        '71' => 'https://subweb.oss-cn-hongkong.aliyuncs.com/RemoteConfig/customized/convenience.ini?',
        '72' => 'https://raw.githubusercontent.com/Mazeorz/airports/master/Clash/SSRcloud.ini?',
        '73' => 'https://raw.githubusercontent.com/Mazetsz/ACL4SSR/master/Clash/config/V2rayPro.ini?',
        '74' => 'https://raw.githubusercontent.com/Mazeorz/airports/master/Clash/V2Pro.ini?',
        '75' => 'https://raw.githubusercontent.com/Mazeorz/airports/master/Clash/Stitch.ini?',
        '76' => 'https://raw.githubusercontent.com/Mazeorz/airports/master/Clash/Stitch-Balance.ini?',
        '77' => 'https://raw.githubusercontent.com/SleepyHeeead/subconverter-config/master/remote-config/customized/maying.ini?',
        '78' => 'https://subweb.s3.fr-par.scw.cloud/RemoteConfig/customized/ytoo.ini?',
        '79' => 'https://raw.nameless13.com/api/public/dl/M-We_Fn7/w8ves.ini?',
        '80' => 'https://raw.githubusercontent.com/SleepyHeeead/subconverter-config/master/remote-config/customized/nyancat.ini?',
        '81' => 'https://subweb.s3.fr-par.scw.cloud/RemoteConfig/customized/nexitally.ini?',
        '82' => 'https://raw.githubusercontent.com/SleepyHeeead/subconverter-config/master/remote-config/customized/socloud.ini?',
        '83' => 'https://raw.githubusercontent.com/SleepyHeeead/subconverter-config/master/remote-config/customized/ark.ini?',
        '84' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/n3ro_optimized.ini?',
        '85' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/scholar_optimized.ini?',
        '86' => 'https://subweb.s3.fr-par.scw.cloud/RemoteConfig/customized/flower.ini?',

        '88' => 'https://raw.githubusercontent.com/SleepyHeeead/subconverter-config/master/remote-config/special/netease.ini?',
        '89' => 'https://raw.githubusercontent.com/SleepyHeeead/subconverter-config/master/remote-config/special/basic.ini?'
    ];

    $emoji = isset($_POST['emoji']) ? $_POST['emoji'] === 'true' : true;
    $udp = isset($_POST['udp']) ? $_POST['udp'] === 'true' : true;
    $xudp = isset($_POST['xudp']) ? $_POST['xudp'] === 'true' : true;
    $tfo = isset($_POST['tfo']) ? $_POST['tfo'] === 'true' : true;
    $fdn = isset($_POST['fdn']) ? $_POST['fdn'] === 'true' : true;
    $sort = isset($_POST['sort']) ? $_POST['sort'] === 'true' : true;
    $tls13 = isset($_POST['tls13']) ? $_POST['tls13'] === 'true' : true;
   
    $filename = isset($_POST['filename']) && $_POST['filename'] !== '' ? $_POST['filename'] : 'config.yaml'; 
    $subscription_url = isset($_POST['subscription_url']) ? $_POST['subscription_url'] : ''; 
    $backend_url = isset($_POST['backend_url']) && $_POST['backend_url'] === 'custom' && !empty($_POST['custom_backend_url'])
    ? rtrim($_POST['custom_backend_url'], '?') . '?'
    : ($_POST['backend_url'] ?? 'https://url.v1.mk/sub?');
    $template_key = $_POST['template'] ?? ''; 
    $include = $_POST['include'] ?? ''; 
    $exclude = $_POST['exclude'] ?? '';        
    $template = $templates[$template_key] ?? '';
    $rename = isset($_POST['rename']) ? $_POST['rename'] : ''; 

    if (isset($_POST['action'])) {
        if ($_POST['action'] === 'generate_subscription') {
            $final_url = buildFinalUrl($subscription_url, $template, $include, $exclude, $backend_url, $emoji, $udp, $xudp, $tfo, $rename, $tls13, $fdn, $sort);

            if (saveSubscriptionUrlToFile($final_url, $subscription_file)) {
                $result = saveSubscriptionContentToYaml($final_url, $filename);
                $result .= generateShellScript() . "<br>";

                if (isset($_POST['cron_time'])) {
                    $cron_time = $_POST['cron_time'];
                    $cron_result = setupCronJob($cron_time) . "<br>";
                }
            } else {
                echo "保存订阅链接到文件失败。";
            }
        } elseif ($_POST['action'] === 'update_cron') {
            if (isset($_POST['cron_time']) && $_POST['cron_time']) {
                $cron_time = $_POST['cron_time'];
                $cron_result = setupCronJob($cron_time);
            }
        }
    }
}

function getSubscriptionUrlFromFile($file) {
    if (file_exists($file)) {
        return file_get_contents($file);
    }
    return '';
}

?>

<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme, 0, -4) ?>">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Mihomo - Nekobox</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/bootstrap/bootstrap.bundle.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/neko.js"></script>
</head>
<body>
<style>
@media (max-width: 767px) {
    .row a {
        font-size: 9px; 
    }
}

.table-responsive {
    width: 100%;
}
</style>
<div class="container-sm container-bg callout border border-3 rounded-4 col-11">
    <div class="row">
        <a href="./index.php" class="col btn btn-lg">🏠 首页</a>
        <a href="./mihomo_manager.php" class="col btn btn-lg">📂 文件管理</a>
        <a href="./mihomo.php" class="col btn btn-lg">🗂️ Mihomo</a>
        <a href="./singbox.php" class="col btn btn-lg">💹 Sing-box</a>
        <a href="./subscription.php" class="col btn btn-lg">💹 Singbox</a>
        <h1 class="text-center p-2" style="margin-top: 2rem; margin-bottom: 1rem;">Mihomo 订阅转换模板</h1>

        <div class="col-12">
            <div class="form-section">
                <form method="post">
                    <div class="mb-3">
                        <label for="subscription_url" class="form-label">输入订阅链接</label>
                        <input type="text" class="form-control" id="subscription_url" name="subscription_url"
                               value="<?php echo htmlspecialchars($current_subscription_url); ?>" placeholder="支持各种订阅链接或单节点链接，多个链接用 | 分隔"  required>
                    </div>

                    <div class="mb-3">
                        <label for="filename" class="form-label">自定义文件名 (默认: config.yaml)</label>
                        <input type="text" class="form-control" id="filename" name="filename"
                               value="<?php echo htmlspecialchars(isset($_POST['filename']) ? $_POST['filename'] : ''); ?>"
                               placeholder="config.yaml">
                    </div>

                    <div class="mb-3">
                        <label for="backend_url" class="form-label">选择后端地址</label>
                        <select class="form-select" id="backend_url" name="backend_url" required>
                            <option value="https://url.v1.mk/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://url.v1.mk/sub?' ? 'selected' : ''; ?>>
                                肥羊增强型后端【vless reality+hy1+hy2】
                            </option>
                            <option value="https://sub.d1.mk/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://sub.d1.mk/sub?' ? 'selected' : ''; ?>>
                                肥羊备用后端【vless reality+hy1+hy2】
                            </option>
                            <option value="https://sub.xeton.dev/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://sub.xeton.dev/sub?' ? 'selected' : ''; ?>>
                                subconverter作者提供
                            </option>
                            </option>
                            <option value="https://www.tline.website/sub/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://www.tline.website/sub/sub?' ? 'selected' : ''; ?>>
                                tline.website
                            </option>
                            <option value="https://api.dler.io/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://api.dler.io/sub?' ? 'selected' : ''; ?>>
                                api.dler.io
                            </option>
                            <option value="https://v.id9.cc/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://v.id9.cc/sub?' ? 'selected' : ''; ?>>
                                v.id9.cc(品云提供）
                            </option>
                            <option value="https://sub.id9.cc/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://sub.id9.cc/sub?' ? 'selected' : ''; ?>>
                                sub.id9.cc
                            </option>
                            <option value="https://api.wcc.best/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://api.wcc.best/sub?' ? 'selected' : ''; ?>>
                                api.wcc.best
                            </option>
                            <option value="https://yun-api.subcloud.xyz/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://yun-api.subcloud.xyz/sub?' ? 'selected' : ''; ?>>
                                subcloud.xyz
                            </option>
                            <option value="https://sub.maoxiongnet.com/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://sub.maoxiongnet.com/sub?' ? 'selected' : ''; ?>>
                                sub.maoxiongnet.com(猫熊提供)
                            </option>
                            <option value="http://localhost:25500/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'http://localhost:25500/sub?' ? 'selected' : ''; ?>>
                                localhost:25500 本地版
                            </option>
                            <option value="custom" <?php echo ($_POST['backend_url'] ?? '') === 'custom' ? 'selected' : ''; ?>>
                                自定义后端地址
                            </option>
                        </select>
                    </div>

                    <div class="mb-3" id="custom_backend_url_input" style="display: none;">
                        <label for="custom_backend_url" class="form-label">请输入自定义后端地址</label>
                        <input type="text" class="form-control" id="custom_backend_url" name="custom_backend_url" value="<?php echo htmlspecialchars($_POST['custom_backend_url'] ?? '') . (empty($_POST['custom_backend_url']) ? '' : '?'); ?>" />
                    </div>

                    <div class="mb-3">
                        <label for="template" class="form-label">选择订阅转换模板</label>
                        <select class="form-select" id="template" name="template" required>
                        <optgroup label="通用" style="color: #28a745; font-size: 20px;">
                            <option value="1" <?php echo ($_POST['template'] ?? '') === '1' ? 'selected' : ''; ?>>默认</option>
                            <option value="2" <?php echo ($_POST['template'] ?? '') === '2' ? 'selected' : ''; ?>>默认（自动测速）</option>
                            <option value="3" <?php echo ($_POST['template'] ?? '') === '3' ? 'selected' : ''; ?>>默认（索尼电视专用）</option>
                            <option value="4" <?php echo ($_POST['template'] ?? '') === '4' ? 'selected' : ''; ?>>默认（附带用于 Clash 的 AdGuard DNS）</option>
                            <option value="5" <?php echo ($_POST['template'] ?? '') === '5' ? 'selected' : ''; ?>>ACL_全分组 Dream修改版</option>
                            <option value="6" <?php echo ($_POST['template'] ?? '') === '6' ? 'selected' : ''; ?>>ACL_精简分组 Dream修改版</option>
                            <option value="7" <?php echo ($_POST['template'] ?? '') === '7' ? 'selected' : ''; ?>>emby-TikTok-流媒体分组-去广告加强版</option>
                            <option value="8" <?php echo ($_POST['template'] ?? '') === '8' ? 'selected' : ''; ?>>流媒体通用分组</option>
                        </optgroup>
                        <optgroup label="ACL规则" style="color: #fd7e14; font-size: 20px;">
                            <option value="9" <?php echo ($_POST['template'] ?? '') === '9' ? 'selected' : ''; ?>>ACL_默认版</option>
                            <option value="10" <?php echo ($_POST['template'] ?? '') === '10' ? 'selected' : ''; ?>>ACL_无测速版</option>
                            <option value="11" <?php echo ($_POST['template'] ?? '') === '11' ? 'selected' : ''; ?>>ACL_去广告版</option>
                            <option value="12" <?php echo ($_POST['template'] ?? '') === '12' ? 'selected' : ''; ?>>ACL_多国家版</option>
                            <option value="13" <?php echo ($_POST['template'] ?? '') === '13' ? 'selected' : ''; ?>>ACL_无Reject版</option>
                            <option value="14" <?php echo ($_POST['template'] ?? '') === '14' ? 'selected' : ''; ?>>ACL_无测速精简版</option>
                            <option value="15" <?php echo ($_POST['template'] ?? '') === '15' ? 'selected' : ''; ?>>ACL_全分组版</option>
                            <option value="16" <?php echo ($_POST['template'] ?? '') === '16' ? 'selected' : ''; ?>>ACL_全分组谷歌版</option>
                            <option value="17" <?php echo ($_POST['template'] ?? '') === '17' ? 'selected' : ''; ?>>ACL_全分组多模式版</option>
                            <option value="18" <?php echo ($_POST['template'] ?? '') === '18' ? 'selected' : ''; ?>>ACL_全分组奈飞版</option>
                            <option value="19" <?php echo ($_POST['template'] ?? '') === '19' ? 'selected' : ''; ?>>ACL_精简版</option>
                            <option value="20" <?php echo ($_POST['template'] ?? '') === '20' ? 'selected' : ''; ?>>ACL_去广告精简版</option>
                            <option value="21" <?php echo ($_POST['template'] ?? '') === '21' ? 'selected' : ''; ?>>ACL_Fallback精简版</option>
                            <option value="22" <?php echo ($_POST['template'] ?? '') === '22' ? 'selected' : ''; ?>>ACL_多国家精简版</option>
                            <option value="23" <?php echo ($_POST['template'] ?? '') === '23' ? 'selected' : ''; ?>>ACL_多模式精简版</option>
                        </optgroup>
                        <optgroup label="全网搜集规则" style="color: #6f42c1; font-size: 20px;">
                            <option value="24" <?php echo ($_POST['template'] ?? '') === '24' ? 'selected' : ''; ?>>常规规则</option>
                            <option value="25" <?php echo ($_POST['template'] ?? '') === '25' ? 'selected' : ''; ?>>酷酷自用</option>
                            <option value="26" <?php echo ($_POST['template'] ?? '') === '26' ? 'selected' : ''; ?>>PharosPro无测速</option>
                            <option value="27" <?php echo ($_POST['template'] ?? '') === '27' ? 'selected' : ''; ?>>分区域故障转移</option>
                            <option value="28" <?php echo ($_POST['template'] ?? '') === '28' ? 'selected' : ''; ?>>分区域自动测速</option>
                            <option value="29" <?php echo ($_POST['template'] ?? '') === '29' ? 'selected' : ''; ?>>分区域无自动测速</option>
                            <option value="30" <?php echo ($_POST['template'] ?? '') === '30' ? 'selected' : ''; ?>>OoHHHHHHH</option>
                            <option value="31" <?php echo ($_POST['template'] ?? '') === '31' ? 'selected' : ''; ?>>CFW-TAP</option>
                            <option value="32" <?php echo ($_POST['template'] ?? '') === '32' ? 'selected' : ''; ?>>lhl77全分组（定期更新）</option>
                            <option value="33" <?php echo ($_POST['template'] ?? '') === '33' ? 'selected' : ''; ?>>lhl77简易版（定期更新）</option>
                            <option value="34" <?php echo ($_POST['template'] ?? '') === '34' ? 'selected' : ''; ?>>ConnersHua 神机规则 Outbound</option>
                            <option value="35" <?php echo ($_POST['template'] ?? '') === '35' ? 'selected' : ''; ?>>ConnersHua 神机规则 Inbound 回国专用</option>
                            <option value="36" <?php echo ($_POST['template'] ?? '') === '36' ? 'selected' : ''; ?>>lhie1 洞主规则（使用 Clash 分组规则）</option>
                            <option value="37" <?php echo ($_POST['template'] ?? '') === '37' ? 'selected' : ''; ?>>lhie1 洞主规则完整版</option>
                            <option value="38" <?php echo ($_POST['template'] ?? '') === '38' ? 'selected' : ''; ?>>eHpo1 规则</option>
                            <option value="39" <?php echo ($_POST['template'] ?? '') === '39' ? 'selected' : ''; ?>>多策略组默认白名单模式</option>
                            <option value="40" <?php echo ($_POST['template'] ?? '') === '40' ? 'selected' : ''; ?>>多策略组可以有效减少审计触发</option>
                            <option value="41" <?php echo ($_POST['template'] ?? '') === '41' ? 'selected' : ''; ?>>精简策略默认白名单</option>
                            <option value="42" <?php echo ($_POST['template'] ?? '') === '42' ? 'selected' : ''; ?>>多策略增加SMTP策略</option>
                            <option value="43" <?php echo ($_POST['template'] ?? '') === '43' ? 'selected' : ''; ?>>无策略入门推荐</option>
                            <option value="44" <?php echo ($_POST['template'] ?? '') === '44' ? 'selected' : ''; ?>>无策略入门推荐国家分组</option>
                            <option value="45" <?php echo ($_POST['template'] ?? '') === '45' ? 'selected' : ''; ?>>无策略仅IPIP CN + Final</option>
                            <option value="46" <?php echo ($_POST['template'] ?? '') === '46' ? 'selected' : ''; ?>>无策略魅影vip分组</option>
                            <option value="47" <?php echo ($_POST['template'] ?? '') === '47' ? 'selected' : ''; ?>>品云专属配置（仅香港区域分组）</option>
                            <option value="48" <?php echo ($_POST['template'] ?? '') === '48' ? 'selected' : ''; ?>>品云专属配置（全地域分组）</option>
                            <option value="49" <?php echo ($_POST['template'] ?? '') === '49' ? 'selected' : ''; ?>>nzw9314 规则</option>
                            <option value="50" <?php echo ($_POST['template'] ?? '') === '50' ? 'selected' : ''; ?>>maicoo-l 规则</option>
                            <option value="51" <?php echo ($_POST['template'] ?? '') === '51' ? 'selected' : ''; ?>>DlerCloud Platinum 李哥定制规则</option>
                            <option value="52" <?php echo ($_POST['template'] ?? '') === '52' ? 'selected' : ''; ?>>DlerCloud Gold 李哥定制规则</option>
                            <option value="53" <?php echo ($_POST['template'] ?? '') === '53' ? 'selected' : ''; ?>>DlerCloud Silver 李哥定制规则</option>
                            <option value="54" <?php echo ($_POST['template'] ?? '') === '54' ? 'selected' : ''; ?>>ProxyStorage自用</option>
                            <option value="55" <?php echo ($_POST['template'] ?? '') === '55' ? 'selected' : ''; ?>>ShellClash修改版规则 (by UlinoyaPed)</option>
                        </optgroup>
                        <optgroup label="各大机场规则" style="color: #007bff; font-size: 20px;">
                            <option value="56" <?php echo ($_POST['template'] ?? '') === '56' ? 'selected' : ''; ?>>EXFLUX</option>
                            <option value="57" <?php echo ($_POST['template'] ?? '') === '57' ? 'selected' : ''; ?>>NaNoport</option>
                            <option value="58" <?php echo ($_POST['template'] ?? '') === '58' ? 'selected' : ''; ?>>CordCloud</option>
                            <option value="59" <?php echo ($_POST['template'] ?? '') === '59' ? 'selected' : ''; ?>>BigAirport</option>
                            <option value="60" <?php echo ($_POST['template'] ?? '') === '60' ? 'selected' : ''; ?>>跑路云</option>
                            <option value="61" <?php echo ($_POST['template'] ?? '') === '61' ? 'selected' : ''; ?>>WaveCloud</option>
                            <option value="62" <?php echo ($_POST['template'] ?? '') === '62' ? 'selected' : ''; ?>>几鸡</option>
                            <option value="63" <?php echo ($_POST['template'] ?? '') === '63' ? 'selected' : ''; ?>>四季加速</option>
                            <option value="64" <?php echo ($_POST['template'] ?? '') === '64' ? 'selected' : ''; ?>>ImmTelecom</option>
                            <option value="65" <?php echo ($_POST['template'] ?? '') === '65' ? 'selected' : ''; ?>>AmyTelecom</option>
                            <option value="66" <?php echo ($_POST['template'] ?? '') === '66' ? 'selected' : ''; ?>>LinkCube</option>
                            <option value="67" <?php echo ($_POST['template'] ?? '') === '67' ? 'selected' : ''; ?>>Miaona</option>
                            <option value="68" <?php echo ($_POST['template'] ?? '') === '68' ? 'selected' : ''; ?>>Foo&Friends</option>
                            <option value="69" <?php echo ($_POST['template'] ?? '') === '69' ? 'selected' : ''; ?>>ABCloud</option>
                            <option value="70" <?php echo ($_POST['template'] ?? '') === '70' ? 'selected' : ''; ?>>咸鱼</option>
                            <option value="71" <?php echo ($_POST['template'] ?? '') === '71' ? 'selected' : ''; ?>>便利店</option>
                            <option value="72" <?php echo ($_POST['template'] ?? '') === '72' ? 'selected' : ''; ?>>CNIX</option>
                            <option value="73" <?php echo ($_POST['template'] ?? '') === '73' ? 'selected' : ''; ?>>Nirvana</option>
                            <option value="74" <?php echo ($_POST['template'] ?? '') === '74' ? 'selected' : ''; ?>>V2Pro</option>
                            <option value="75" <?php echo ($_POST['template'] ?? '') === '75' ? 'selected' : ''; ?>>史迪仔-自动测速</option>
                            <option value="76" <?php echo ($_POST['template'] ?? '') === '76' ? 'selected' : ''; ?>>史迪仔-负载均衡</option>
                            <option value="77" <?php echo ($_POST['template'] ?? '') === '77' ? 'selected' : ''; ?>>Maying</option>
                            <option value="78" <?php echo ($_POST['template'] ?? '') === '78' ? 'selected' : ''; ?>>Ytoo</option>
                            <option value="79" <?php echo ($_POST['template'] ?? '') === '79' ? 'selected' : ''; ?>>w8ves</option>
                            <option value="80" <?php echo ($_POST['template'] ?? '') === '80' ? 'selected' : ''; ?>>NyanCAT</option>
                            <option value="81" <?php echo ($_POST['template'] ?? '') === '81' ? 'selected' : ''; ?>>Nexitally</option>
                            <option value="82" <?php echo ($_POST['template'] ?? '') === '82' ? 'selected' : ''; ?>>SoCloud</option>
                            <option value="83" <?php echo ($_POST['template'] ?? '') === '83' ? 'selected' : ''; ?>>ARK</option>
                            <option value="84" <?php echo ($_POST['template'] ?? '') === '84' ? 'selected' : ''; ?>>N3RO</option>
                            <option value="85" <?php echo ($_POST['template'] ?? '') === '85' ? 'selected' : ''; ?>>Scholar</option>
                            <option value="86" <?php echo ($_POST['template'] ?? '') === '86' ? 'selected' : ''; ?>>Flowercloud</option>
                        </optgroup>
                        <optgroup label="特殊" style="color: #ff0000; font-size: 20px;">
                            <option value="87" <?php echo ($_POST['template'] ?? '') === '87' ? 'selected' : ''; ?>>NeteaseUnblock</option>
                            <option value="88" <?php echo ($_POST['template'] ?? '') === '88' ? 'selected' : ''; ?>>Basic</option>
                        </optgroup>
                        </select>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">选择额外配置选项</label>
                        <div class="d-flex flex-wrap align-items-center">
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="emoji" name="emoji" value="true"
                                       <?php echo isset($_POST['emoji']) && $_POST['emoji'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="emoji">启用 Emoji</label>
                            </div>
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="udp" name="udp" value="true"
                                       <?php echo isset($_POST['udp']) && $_POST['udp'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="udp">启用 UDP</label>
                            </div>
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="xudp" name="xudp" value="true"
                                       <?php echo isset($_POST['xudp']) && $_POST['xudp'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="xudp">启用 XUDP</label>
                            </div>
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="fdn" name="fdn" value="true"
                                       <?php echo isset($_POST['fdn']) && $_POST['fdn'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="tls13">启用 FDN</label>
                            </div>
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="sort" name="sort" value="true"
                                       <?php echo isset($_POST['sort']) && $_POST['sort'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="sort">启用 SORT</label>
                            </div>
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="tls13" name="tls13" value="true"
                                       <?php echo isset($_POST['tls13']) && $_POST['tls13'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="tls13">启用 TLS_1.3</label>
                            </div>
                            <div class="form-check">
                                <input type="checkbox" class="form-check-input" id="tfo" name="tfo" value="true"
                                       <?php echo isset($_POST['tfo']) && $_POST['tfo'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="tfo">启用 TFO</label>
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label for="include" class="form-label">包含节点 (可选)</label>
                        <input type="text" class="form-control" id="include" name="include"
                               value="<?php echo htmlspecialchars($_POST['include'] ?? ''); ?>" placeholder="要保留的节点，支持正则 | 分隔">
                    </div>

                    <div class="mb-3">
                        <label for="exclude" class="form-label">排除节点 (可选)</label>
                        <input type="text" class="form-control" id="exclude" name="exclude"
                               value="<?php echo htmlspecialchars($_POST['exclude'] ?? ''); ?>" placeholder="要排除的节点，支持正则 | 分隔">
                    </div>

                   <div class="mb-3">
                        <label for="rename" class="form-label">节点命名</label>
                        <input type="text" class="form-control" id="rename" name="rename"
                               value="<?php echo htmlspecialchars(isset($_POST['rename']) ? $_POST['rename'] : ''); ?>"
                               placeholder="输入重命名内容（举例：`a@b``1@2`，|符可用\转义）">
                    </div>
                    <button type="submit" class="btn btn-primary" name="action" value="generate_subscription"><i class="bi bi-file-earmark-text"></i> 生成配置文件</button>
                </form>
            </div>
        </div>

        <div class="form-section mt-4">
            <form method="post">
                <div class="mb-3">
                    <label for="cron_time" class="form-label">设置 Cron 时间 (例如: 0 3 * * *)</label>
                    <input type="text" class="form-control" id="cron_time" name="cron_time"
                           value="<?php echo htmlspecialchars(isset($_POST['cron_time']) ? $_POST['cron_time'] : '0 3 * * *'); ?>"
                           placeholder="0 3 * * *">
                </div>
                <button type="submit" class="btn btn-primary" name="action" value="update_cron"><i class="bi bi-clock"></i> 设置定时任务</button>
            </form>
        </div>

        <div class="help mt-4">
            <p style="color: red;">注意：在线订阅转换存在隐私泄露风险</p>
            <p>订阅转换由肥羊提供</p>
            <a href="https://github.com/youshandefeiyang/sub-web-modify" target="_blank" class="btn btn-primary" style="color: white;">
            点击访问
            </a>
        </div>

        <div class="result mt-4">
            <?php echo nl2br(htmlspecialchars($result)); ?>
        </div>
        <div class="result mt-2">
            <?php echo nl2br(htmlspecialchars($cron_result)); ?>
        </div>
    </div>
</div>

<script>
document.addEventListener("DOMContentLoaded", function() {
    const formInputs = [
        document.getElementById('subscription_url'),
        document.getElementById('filename'),
        document.getElementById('backend_url'),
        document.getElementById('template'),
        document.getElementById('include'),
        document.getElementById('exclude'),
        document.getElementById('cron_time'),
        document.getElementById('emoji'),
        document.getElementById('udp'),
        document.getElementById('xudp'),
        document.getElementById('sort'),
        document.getElementById('fdn'),
        document.getElementById('tls13'),
        document.getElementById('rename'),
        document.getElementById('custom_backend_url'),
        document.getElementById('tfo')
    ];

    formInputs.forEach(input => {
        if (input) {
            if (input.type === 'checkbox') {
                input.checked = localStorage.getItem(input.id) === 'true'; 
            } else {
                input.value = localStorage.getItem(input.id) || input.value;
            }
        }
    });

    function saveSelections() {
        formInputs.forEach(input => {
            if (input) {
                if (input.type === 'checkbox') {
                    localStorage.setItem(input.id, input.checked);  
                } else {
                    localStorage.setItem(input.id, input.value);    
                }
            }
        });
    }

    document.querySelectorAll('form').forEach(form => {
        form.addEventListener('submit', saveSelections);
    });

    formInputs.forEach(input => {
        if (input) {
            input.addEventListener('change', saveSelections);
        }
    });

    toggleCustomBackendInput();
    var backendSelect = document.getElementById('backend_url');
    backendSelect.addEventListener('change', toggleCustomBackendInput);
});

function toggleCustomBackendInput() {
    var backendSelect = document.getElementById('backend_url');
    var customInput = document.getElementById('custom_backend_url_input');

    if (backendSelect.value === 'custom') {
        customInput.style.display = 'block';
    } else {
        customInput.style.display = 'none';
    }
}
</script>
      <footer class="text-center">
    <p><?php echo $footer ?></p>
</footer>
