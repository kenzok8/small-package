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

function buildFinalUrl($subscription_url, $config_url, $include, $exclude, $backend_url, $emoji, $udp, $xudp, $tfo) {
    $encoded_subscription_url = urlencode($subscription_url);
    $encoded_config_url = urlencode($config_url);
    $encoded_include = urlencode($include);
    $encoded_exclude = urlencode($exclude);
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
    $final_url .= "&list=false&expand=true&scv=false&fdn=false&new_name=true";

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

if [ $? -eq 0 ]; then
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
        '2' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_MultiCountry.ini?',
        '3' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full.ini?',
        '4' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_Google.ini?',
        '5' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_MultiMode.ini?',
        '6' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_Netflix.ini?',
        '7' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/default_with_clash_adg.yml?',
        '8' => 'https://raw.githubusercontent.com/WC-Dream/ACL4SSR/WD/Clash/config/ACL4SSR_Online_Full_Dream.ini?',
        '9' => 'https://raw.githubusercontent.com/WC-Dream/ACL4SSR/WD/Clash/config/ACL4SSR_Mini_Dream.ini?',
        '10' => 'https://raw.githubusercontent.com/justdoiting/ClashRule/main/GeneralClashRule.ini?',
        '11' => 'https://raw.githubusercontent.com/lhl77/sub-ini/main/tsutsu-full.ini?',
        '12' => 'https://raw.githubusercontent.com/Mazeorz/airports/master/Clash/Examine_Full.ini?',
        '13' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/lhie1_dler.ini?',
        '14' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/connershua_backtocn.in?',
    ];

    $emoji = isset($_POST['emoji']) ? $_POST['emoji'] === 'true' : true;
    $udp = isset($_POST['udp']) ? $_POST['udp'] === 'true' : true;
    $xudp = isset($_POST['xudp']) ? $_POST['xudp'] === 'true' : true;
    $tfo = isset($_POST['tfo']) ? $_POST['tfo'] === 'true' : true;
   
    $filename = isset($_POST['filename']) && $_POST['filename'] !== '' ? $_POST['filename'] : 'config.yaml'; 
    $subscription_url = isset($_POST['subscription_url']) ? $_POST['subscription_url'] : ''; 
    $backend_url = $_POST['backend_url'] ?? 'https://url.v1.mk/sub?';
    $template_key = $_POST['template'] ?? ''; 
    $include = $_POST['include'] ?? ''; 
    $exclude = $_POST['exclude'] ?? '';        
    $template = $templates[$template_key] ?? '';

    if (isset($_POST['action'])) {
        if ($_POST['action'] === 'generate_subscription') {
            $final_url = buildFinalUrl($subscription_url, $template, $include, $exclude, $backend_url, $emoji, $udp, $xudp, $tfo);

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
    <title>Personal - Neko</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
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
        <h1 class="text-center p-2" style="margin-top: 2rem; margin-bottom: 1rem;">Mihomo 订阅转换模板</h1>

        <div class="col-12">
            <div class="form-section">
                <form method="post">
                    <div class="mb-3">
                        <label for="subscription_url" class="form-label">输入订阅链接:</label>
                        <input type="text" class="form-control" id="subscription_url" name="subscription_url"
                               value="<?php echo htmlspecialchars($current_subscription_url); ?>" required>
                    </div>

                    <div class="mb-3">
                        <label for="filename" class="form-label">自定义文件名 (默认: config.yaml):</label>
                        <input type="text" class="form-control" id="filename" name="filename"
                               value="<?php echo htmlspecialchars(isset($_POST['filename']) ? $_POST['filename'] : ''); ?>"
                               placeholder="config.yaml">
                    </div>

                    <div class="mb-3">
                        <label for="backend_url" class="form-label">选择后端地址:</label>
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
                        </select>
                    </div>

                    <div class="mb-3">
                        <label for="template" class="form-label">选择订阅转换模板:</label>
                        <select class="form-select" id="template" name="template" required>
                            <option value="1" <?php echo ($_POST['template'] ?? '') === '1' ? 'selected' : ''; ?>>默认</option>
                            <option value="2" <?php echo ($_POST['template'] ?? '') === '2' ? 'selected' : ''; ?>>ACL_多国家版</option>
                            <option value="3" <?php echo ($_POST['template'] ?? '') === '3' ? 'selected' : ''; ?>>ACL_全分组版</option>
                            <option value="4" <?php echo ($_POST['template'] ?? '') === '4' ? 'selected' : ''; ?>>ACL_全分组谷歌版</option>
                            <option value="5" <?php echo ($_POST['template'] ?? '') === '5' ? 'selected' : ''; ?>>ACL_全分组多模式版</option>
                            <option value="6" <?php echo ($_POST['template'] ?? '') === '6' ? 'selected' : ''; ?>>ACL_全分组奈飞版</option>
                            <option value="7" <?php echo ($_POST['template'] ?? '') === '7' ? 'selected' : ''; ?>>附带用于 Clash 的 AdGuard DNS</option>
                            <option value="8" <?php echo ($_POST['template'] ?? '') === '8' ? 'selected' : ''; ?>>ACL_全分组 Dream修改版</option>
                            <option value="9" <?php echo ($_POST['template'] ?? '') === '9' ? 'selected' : ''; ?>>ACL_精简分组 Dream修改版</option>
                            <option value="10" <?php echo ($_POST['template'] ?? '') === '10' ? 'selected' : ''; ?>>emby-TikTok-流媒体分组-去广告加强版</option>
                            <option value="11" <?php echo ($_POST['template'] ?? '') === '11' ? 'selected' : ''; ?>>lhl77全分组（定期更新）</option>
                            <option value="12" <?php echo ($_POST['template'] ?? '') === '12' ? 'selected' : ''; ?>>品云专属配置（全地域分组）</option>
                            <option value="13" <?php echo ($_POST['template'] ?? '') === '13' ? 'selected' : ''; ?>>lhie1 洞主规则完整版</option>
                            <option value="14" <?php echo ($_POST['template'] ?? '') === '14' ? 'selected' : ''; ?>>神机规则 Inbound 回国专用</option>
                        </select>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">选择额外配置选项:</label>
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
                            <div class="form-check">
                                <input type="checkbox" class="form-check-input" id="tfo" name="tfo" value="true"
                                       <?php echo isset($_POST['tfo']) && $_POST['tfo'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="tfo">启用 TFO</label>
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label for="include" class="form-label">包含节点 (可选):</label>
                        <input type="text" class="form-control" id="include" name="include"
                               value="<?php echo htmlspecialchars($_POST['include'] ?? ''); ?>" placeholder="要保留的节点，支持正则 | 分割">
                    </div>

                    <div class="mb-3">
                        <label for="exclude" class="form-label">排除节点 (可选):</label>
                        <input type="text" class="form-control" id="exclude" name="exclude"
                               value="<?php echo htmlspecialchars($_POST['exclude'] ?? ''); ?>" placeholder="要排除的节点，支持正则 | 分割">
                    </div>

                    <button type="submit" class="btn btn-primary" name="action" value="generate_subscription">生成配置文件</button>
                </form>
            </div>
        </div>

        <div class="form-section mt-4">
            <form method="post">
                <div class="mb-3">
                    <label for="cron_time" class="form-label">设置 Cron 时间 (例如: 0 3 * * *):</label>
                    <input type="text" class="form-control" id="cron_time" name="cron_time"
                           value="<?php echo htmlspecialchars(isset($_POST['cron_time']) ? $_POST['cron_time'] : '0 3 * * *'); ?>"
                           placeholder="0 3 * * *">
                </div>
                <button type="submit" class="btn btn-primary" name="action" value="update_cron">更新 Cron 作业</button>
            </form>
        </div>

        <div class="help mt-4">
            <h2 class="text-center">帮助说明</h2>
            <p>欢迎使用 Mihomo 订阅程序！请按照以下步骤进行操作：</p>
            <ul class="list-group">
                <li class="list-group-item"><strong>输入订阅链接:</strong> 在文本框中输入您的 Clash 订阅链接。</li>
                <li class="list-group-item"><strong>输入保存文件名:</strong> 指定保存配置文件的文件名，默认为 "config.yaml"，无需添加后缀。</li>
                <li class="list-group-item">点击 "生成订阅链接" 按钮，系统将下载订阅内容，并进行转换和保存。</li>
                <li class="list-group-item">推荐使用文件管理的Mihomo订阅</li>
            </ul>
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
});
</script>

