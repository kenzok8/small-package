<?php
ob_start();
include './cfg.php';
ini_set('memory_limit', '256M');
$subscription_file = '/etc/neko/config/subscription.txt'; 
$download_path = '/etc/neko/config/'; 
$php_script_path = '/www/nekobox/personal.php'; 
$sh_script_path = '/etc/neko/update_config.sh'; 
$log_file = '/var/log/neko_update.log'; 

function logMessage($message) {
    global $log_file;
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($log_file, "[$timestamp] $message\n", FILE_APPEND);
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

    if ($subscription_data === false || empty($subscription_data)) {
        $message = "无法获取订阅内容。请检查链接是否正确。";
        logMessage($message);
        return $message;
    }

    if (base64_decode($subscription_data, true) !== false) {
        $decoded_data = base64_decode($subscription_data);
    } else {
        $decoded_data = $subscription_data;
    }

    $transformed_data = transformContent($decoded_data);

    $file_path = $download_path . $filename;
    $success = file_put_contents($file_path, $transformed_data) !== false;
    $message = $success ? "内容已成功保存到：$file_path" : "文件保存失败。";
    logMessage($message);
    return $message;
}

function generateShellScript() {
    global $subscription_file, $download_path, $php_script_path, $sh_script_path;

    $sh_script_content = <<<EOD
#!/bin/bash

SUBSCRIPTION_FILE='$subscription_file'
DOWNLOAD_PATH='$download_path'
DEST_PATH='/etc/neko/config/config.yaml'
PHP_SCRIPT_PATH='$php_script_path'

if [ ! -f "\$SUBSCRIPTION_FILE" ]; then
    echo "未找到订阅文件: \$SUBSCRIPTION_FILE"
    exit 1
fi

SUBSCRIPTION_URL=\$(cat "\$SUBSCRIPTION_FILE")

php -f "\$PHP_SCRIPT_PATH" <<EOF
POST
subscription_url=\$SUBSCRIPTION_URL
filename=config.yaml
EOF

UPDATED_FILE="\$DOWNLOAD_PATH/config.yaml"
if [ ! -f "\$UPDATED_FILE" ]; then
    echo "未找到更新后的配置文件: \$UPDATED_FILE"
    exit 1
fi

mv "\$UPDATED_FILE" "\$DEST_PATH"

if [ \$? -eq 0 ]; then
    echo "配置文件已成功更新并移动到 \$DEST_PATH"
else
    echo "配置文件移动到 \$DEST_PATH 失败"
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
    
    if (strpos($current_cron, $sh_script_path) !== false) {
        $updated_cron = preg_replace('/.*' . preg_quote($sh_script_path, '/') . '/', $cron_entry, $current_cron);
    } else {
        $updated_cron = $current_cron . $cron_entry;
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
    if (isset($_POST['subscription_url']) && isset($_POST['filename'])) {
        $subscription_url = $_POST['subscription_url'];
        $filename = $_POST['filename'];

        if (empty($filename)) {
            $filename = 'config.yaml';
        }

        if (saveSubscriptionUrlToFile($subscription_url, $subscription_file)) {
            $result .= saveSubscriptionContentToYaml($subscription_url, $filename) . "<br>";
            $result .= generateShellScript() . "<br>";
        } else {
            $result = "保存订阅链接失败。";
        }
    }

    if (isset($_POST['cron_time'])) {
        $cron_time = $_POST['cron_time'];
        $cron_result .= setupCronJob($cron_time) . "<br>";
    }
}

function getSubscriptionUrlFromFile($file) {
    if (file_exists($file)) {
        return file_get_contents($file);
    }
    return '';
}

$current_subscription_url = getSubscriptionUrlFromFile($subscription_file);
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
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
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
        <a href="./mihomo_manager.php" class="col btn btn-lg">📂 Mihomo</a>
        <a href="./singbox_manager.php" class="col btn btn-lg">🗂️ Sing-box</a>
        <a href="./box.php" class="col btn btn-lg">💹 订阅转换</a>
        <a href="./personal.php" class="col btn btn-lg">📦 订阅</a>
        <h1 class="text-center p-2" style="margin-top: 2rem; margin-bottom: 1rem;">Mihomo 订阅（Clash版）</h1>

        <div class="col-12">
            <div class="form-section">
                <form method="post">
                    <div class="mb-3">
                        <label for="subscription_url" class="form-label">输入订阅链接:</label>
                        <input type="text" class="form-control" id="subscription_url" name="subscription_url"
                               value="<?php echo htmlspecialchars($current_subscription_url); ?>" required>
                    </div>
                    <div class="mb-3">
                        <label for="filename" class="form-label">输入保存文件名 (默认: config.yaml):</label>
                        <input type="text" class="form-control" id="filename" name="filename"
                               value="<?php echo htmlspecialchars(isset($_POST['filename']) ? $_POST['filename'] : ''); ?>"
                               placeholder="config.yaml">
                    </div>
                    <button type="submit" class="btn btn-primary" name="action" value="update_subscription">更新订阅</button>
                </form>
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
        </div>

        <div class="help mt-4">
            <h2 class="text-center">帮助说明</h2>
            <p>欢迎使用 Mihomo 订阅程序！请按照以下步骤进行操作：</p>
            <ul class="list-group">
                <li class="list-group-item"><strong>输入订阅链接:</strong> 在文本框中输入您的 Clash 订阅链接。</li>
                <li class="list-group-item"><strong>输入保存文件名:</strong> 指定保存配置文件的文件名，默认为 "config.yaml"。</li>
                <li class="list-group-item">点击 "更新订阅" 按钮，系统将下载订阅内容，并进行转换和保存。</li>
                <li class="list-group-item"><strong>只支持Clash格式的订阅。</li>
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
</div>
</body>
</html>
