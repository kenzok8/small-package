<?php
ob_start();
include './cfg.php';
ini_set('memory_limit', '256M');
$result = $result ?? ''; 
$subscription_file = '/etc/neko/ singbox.txt'; 
$download_path = '/etc/neko/config/'; 
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

function buildFinalUrl($subscription_url, $config_url, $include, $exclude, $backend_url, $emoji, $udp, $xudp, $tfo, $ipv6) {
    $encoded_subscription_url = urlencode($subscription_url);
    $encoded_config_url = urlencode($config_url);
    $encoded_include = urlencode($include);
    $encoded_exclude = urlencode($exclude);
    $final_url = "{$backend_url}target=singbox&url={$encoded_subscription_url}&insert=false&config={$encoded_config_url}";

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
    $final_url .= "&list=false&expand=true&scv=false&fdn=false";

    if ($ipv6 === 'true') {
        $final_url .= "&singbox.ipv6=1";
    }

    return $final_url;
}

function saveSubscriptionUrlToFile($url, $file) {
    $success = file_put_contents($file, $url) !== false;
    logMessage($success ? "订阅链接已保存到 $file" : "保存订阅链接失败到 $file");
    return $success;
}

function transformContent($content) {
    $parsedData = json_decode($content, true);
    if ($parsedData === null) {
        logMessage("无法解析内容为 JSON 格式");
        return "无法解析内容为 JSON 格式";
    }

    if (isset($parsedData['inbounds'])) {
        $newInbounds = [];

        foreach ($parsedData['inbounds'] as $inbound) {
            if (isset($inbound['type']) && $inbound['type'] === 'mixed' && $inbound['tag'] === 'mixed-in') {
                if ($inbound['listen_port'] !== 2080) {
                    $newInbounds[] = $inbound;
                }
            } elseif (isset($inbound['type']) && $inbound['type'] === 'tun') {
                continue;
            }
        }

        $newInbounds[] = [
            "domain_strategy" => "prefer_ipv4",
            "listen" => "127.0.0.1",
            "listen_port" => 2334,
            "sniff" => true,
            "sniff_override_destination" => true,
            "tag" => "mixed-in",
            "type" => "mixed",
            "users" => []
        ];

        $newInbounds[] = [
            "tag" => "tun",
            "type" => "tun",
            "address" => [
                "172.19.0.1/30",
                "fdfe:dcba:9876::1/126"
            ],
            "route_address" => [
                "0.0.0.0/1",
                "128.0.0.0/1",
                "::/1",
                "8000::/1"
            ],
            "route_exclude_address" => [
                "192.168.0.0/16",
                "fc00::/7"
            ],
            "stack" => "system",
            "auto_route" => true,
            "strict_route" => true,
            "sniff" => true,
            "platform" => [
                "http_proxy" => [
                    "enabled" => true,
                    "server" => "0.0.0.0",
                    "server_port" => 1082
                ]
            ]
        ];

        $newInbounds[] = [
            "tag" => "mixed",
            "type" => "mixed",
            "listen" => "0.0.0.0",
            "listen_port" => 1082,
            "sniff" => true
        ];

        $parsedData['inbounds'] = $newInbounds;
    }

    if (isset($parsedData['experimental']['clash_api'])) {
        $parsedData['experimental']['clash_api'] = [
            "external_ui" => "/etc/neko/ui/",
            "external_controller" => "0.0.0.0:9090",
            "secret" => "Akun"
        ];
    }

    $fileContent = json_encode($parsedData, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

    return $fileContent;
}

function saveSubscriptionContentToYaml($url, $filename) {
    global $download_path;

    if (pathinfo($filename, PATHINFO_EXTENSION) !== 'json') {
        $filename .= '.json';
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

    $transformed_data = transformContent($subscription_data);

    $file_path = $download_path . $filename;
    $success = file_put_contents($file_path, $transformed_data) !== false;
    $message = $success ? "内容已成功保存到：$file_path" : "文件保存失败。";
    logMessage($message);
    return $message;
}

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
        '15' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full_AdblockPlus.ini?',
        '16' => 'https://raw.githubusercontent.com/youshandefeiyang/webcdn/main/SONY.ini?',
        '17' => 'https://raw.githubusercontent.com/cutethotw/ClashRule/main/GeneralClashRule.ini?',
        '18' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online.ini?',
        '19' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_NoAuto.ini?',
        '20' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_AdblockPlus.ini?',
        '21' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Mini_MultiMode.ini?',
        '22' => 'https://gist.githubusercontent.com/tindy2013/1fa08640a9088ac8652dbd40c5d2715b/raw/ehpo1_main.ini?',
        '23' => 'https://github.com/UlinoyaPed/ShellClash/raw/master/rules/ShellClash.ini?',
        '24' => 'https://unpkg.com/proxy-script/config/Clash/clash.ini?',
        '25' => 'https://raw.githubusercontent.com/Mazeorz/airports/master/Clash/Stitch.ini?',
        '26' => 'https://raw.githubusercontent.com/Mazeorz/airports/master/Clash/Stitch-Balance.ini?',
        '27' => 'https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online_Full.ini?',
    ];

    $emoji = isset($_POST['emoji']) ? $_POST['emoji'] === 'true' : true;
    $udp = isset($_POST['udp']) ? $_POST['udp'] === 'true' : true;
    $xudp = isset($_POST['xudp']) ? $_POST['xudp'] === 'true' : true;
    $tfo = isset($_POST['tfo']) ? $_POST['tfo'] === 'true' : true;
    $ipv6 = isset($_POST['ipv6']) ? $_POST['ipv6'] : 'false';

    $filename = isset($_POST['filename']) && $_POST['filename'] !== '' ? $_POST['filename'] : 'config.json'; 
    $subscription_url = isset($_POST['subscription_url']) ? $_POST['subscription_url'] : ''; 
    $backend_url = $_POST['backend_url'] ?? 'https://url.v1.mk/sub?';
    $template_key = $_POST['template'] ?? ''; 
    $include = $_POST['include'] ?? ''; 
    $exclude = $_POST['exclude'] ?? '';        
    $template = $templates[$template_key] ?? '';

    if (isset($_POST['action']) && $_POST['action'] === 'generate_subscription') {
        $final_url = buildFinalUrl($subscription_url, $template, $include, $exclude, $backend_url, $emoji, $udp, $xudp, $tfo, $ipv6);

        if (saveSubscriptionUrlToFile($final_url, $subscription_file)) {
            $result = saveSubscriptionContentToYaml($final_url, $filename);
        } else {
            $result = "保存订阅链接到文件失败。";
        }
    }

    if (isset($result)) {
        echo nl2br(htmlspecialchars($result)); 
    }

    $download_option = $_POST['download_option'] ?? 'none';
    if (isset($_POST['download_action']) && $_POST['download_action'] === 'download_files') {
        if ($download_option === 'geoip') {
            $geoip_url = "https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db";
            $geoip_path = '/www/nekobox/geoip.db';
            echo downloadFileWithWget($geoip_url, $geoip_path); 
        } elseif ($download_option === 'geosite') {
            $geosite_url = "https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db";
            $geosite_path = '/www/nekobox/geosite.db';
            echo downloadFileWithWget($geosite_url, $geosite_path); 
        }
    }
}

function downloadFileWithWget($url, $path) {
    $command = "wget -q --no-check-certificate -O " . escapeshellarg($path) . " " . escapeshellarg($url);
    exec($command, $output, $return_var);
    
    if ($return_var === 0) {
        return "文件下载成功: $path<br>";
    } else {
        return "文件下载失败: $path<br>";
    }
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
        <a href="./subscription.php" class="col btn btn-lg">💹 Singbox</a>
        <h1 class="text-center p-2" style="margin-top: 2rem; margin-bottom: 1rem;">Sing-box 订阅转换模板 二</h1>

        <div class="col-12">
            <div class="form-section">
                <form method="post">
                    <div class="mb-3">
                        <label for="subscription_url" class="form-label">输入订阅链接</label>
                        <input type="text" class="form-control" id="subscription_url" name="subscription_url"
                               value="<?php echo htmlspecialchars($current_subscription_url); ?>"placeholder="支持各种订阅链接或单节点链接，多个链接用 | 分隔" required>
                    </div>

                    <div class="mb-3">
                        <label for="filename" class="form-label">自定义文件名 (默认: config.json)</label>
                        <input type="text" class="form-control" id="filename" name="filename"
                               value="<?php echo htmlspecialchars(isset($_POST['filename']) ? $_POST['filename'] : ''); ?>"
                               placeholder="config.json">
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
                        <label for="template" class="form-label">选择订阅转换模板</label>
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
                            <option value="15" <?php echo ($_POST['template'] ?? '') === '15' ? 'selected' : ''; ?>>自动测速</option>
                            <option value="16" <?php echo ($_POST['template'] ?? '') === '16' ? 'selected' : ''; ?>>索尼电视专用</option>
                            <option value="17" <?php echo ($_POST['template'] ?? '') === '17' ? 'selected' : ''; ?>>流媒体通用分组</option>
                            <option value="18" <?php echo ($_POST['template'] ?? '') === '18' ? 'selected' : ''; ?>>ACL_默认版</option>
                            <option value="19" <?php echo ($_POST['template'] ?? '') === '19' ? 'selected' : ''; ?>>ACL_无测速版</option>
                            <option value="20" <?php echo ($_POST['template'] ?? '') === '20' ? 'selected' : ''; ?>>ACL_去广告版</option>
                            <option value="21" <?php echo ($_POST['template'] ?? '') === '21' ? 'selected' : ''; ?>>ACL_多模式精简版</option>
                            <option value="22" <?php echo ($_POST['template'] ?? '') === '22' ? 'selected' : ''; ?>>eHpo1 规则</option>
                            <option value="23" <?php echo ($_POST['template'] ?? '') === '23' ? 'selected' : ''; ?>>ShellClash修改版规则 (by UlinoyaPed)</option>
                            <option value="24" <?php echo ($_POST['template'] ?? '') === '24' ? 'selected' : ''; ?>>ProxyStorage自用）</option>
                            <option value="25" <?php echo ($_POST['template'] ?? '') === '25' ? 'selected' : ''; ?>>史迪仔-自动测速</option>
                            <option value="26" <?php echo ($_POST['template'] ?? '') === '26' ? 'selected' : ''; ?>>史迪仔-负载均衡</option>
                            <option value="27" <?php echo ($_POST['template'] ?? '') === '27' ? 'selected' : ''; ?>>Full 全分组</option>
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
                                <input type="checkbox" class="form-check-input" id="tfo" name="tfo" value="true"
                                       <?php echo isset($_POST['tfo']) && $_POST['tfo'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="tfo">启用 TFO</label>
                            </div>
                            <div class="form-check">
                                <input type="checkbox" class="form-check-input" id="ipv6" name="ipv6" value="true"
                                       <?php echo isset($_POST['ipv6']) && $_POST['ipv6'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="ipv6">启用 IPv6</label>
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
                        <label class="form-label" for="download_option">选择要下载的数据库</label>
                        <select class="form-select" id="download_option" name="download_option">
                               <option value="geoip" <?php echo isset($_POST['download_option']) && $_POST['download_option'] === 'geoip' ? 'selected' : ''; ?>>GeoIP 数据库 (geoip.db)</option>
                              <option value="geosite" <?php echo isset($_POST['download_option']) && $_POST['download_option'] === 'geosite' ? 'selected' : ''; ?>>Geosite 数据库 (geosite.db)</option>
                        </select>
                    </div>
                    <button type="submit" class="btn btn-primary" name="action" value="generate_subscription">生成配置文件</button>
                    <button type="submit" class="btn btn-success" name="download_action" value="download_files">下载数据库</button>
                </form>
            </div>
        </div>
        <div class="help mt-4">
            <p style="color: red;">注意：在线订阅转换存在隐私泄露风险，需下载geoip/geosite使用</p>
        </div>
        <div class="result mt-4">
            <?php echo nl2br(htmlspecialchars($result)); ?>
        </div>
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
        document.getElementById('ipv6'), 
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
      <footer class="text-center">
    <p><?php echo $footer ?></p>
</footer>
