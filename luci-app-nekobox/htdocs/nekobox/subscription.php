<?php
ob_start();
include './cfg.php';
ini_set('memory_limit', '256M');
$result = $result ?? ''; 
$subscription_file = '/etc/neko/tmp/singbox.txt'; 
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

function buildFinalUrl($subscription_url, $config_url, $include, $exclude, $backend_url, $emoji, $udp, $xudp, $tfo, $ipv6, $tls13, $fdn, $sort, $rename) {
    $encoded_subscription_url = urlencode($subscription_url);
    $encoded_config_url = urlencode($config_url);
    $encoded_include = urlencode($include);
    $encoded_exclude = urlencode($exclude);
    $encoded_rename = urlencode($rename); 
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
    $final_url .= "&fdn=" . (isset($_POST['fdn']) && $_POST['fdn'] === 'true' ? "true" : "false");
    $final_url .= "&tls13=" . (isset($_POST['tls13']) && $_POST['tls13'] === 'true' ? "true" : "false");
    $final_url .= "&sort=" . (isset($_POST['sort']) && $_POST['sort'] === 'true' ? "true" : "false");
    $final_url .= "&list=false&expand=true&scv=false";

    if (!empty($rename)) {
        $final_url .= "&rename={$encoded_rename}"; 
    }

    if ($ipv6 === 'true') {
        $final_url .= "&singbox.ipv6=1";
    }

    return $final_url;
}

function saveSubscriptionUrlToFile($url, $file) {
    $success = file_put_contents($file, $url) !== false;
    logMessage($success ? "Subscription link has been saved to $file" : "Failed to save subscription link to $file");
    return $success;
}

function transformContent($content) {
    $parsedData = json_decode($content, true);
    if ($parsedData === null) {
        logMessage("Unable to parse content into JSON format");
        return "Unable to parse content as JSON";
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
        $message = "Filename contains illegal characters. Please use letters, numbers, dots, underscores, or hyphens.";
        logMessage($message);
        return $message;
    }

    if (!is_dir($download_path)) {
        if (!mkdir($download_path, 0755, true)) {
            $message = "Unable to create directory: $download_path";
            logMessage($message);
            return $message;
        }
    }

    $output_file = escapeshellarg($download_path . $filename);
    $command = "wget -q --no-check-certificate -O $output_file " . escapeshellarg($url);
    exec($command, $output, $return_var);
    if ($return_var !== 0) {
        $message = "wget Error，Unable to retrieve subscription content. Please check if the link is correct.";
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
        $message = "cURL Error: $error_msg";
        logMessage($message);
        return $message;
    }
    curl_close($ch);

    if (empty($subscription_data)) {
        $message = "Unable to retrieve subscription content. Please check if the link is correct.";
        logMessage($message);
        return $message;
    }

    $transformed_data = transformContent($subscription_data);

    $file_path = $download_path . $filename;
    $success = file_put_contents($file_path, $transformed_data) !== false;
    $message = $success ? "Content successfully saved to: $file_path" : "File save failed.";  
    logMessage($message);
    return $message;
}

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
    $ipv6 = isset($_POST['ipv6']) ? $_POST['ipv6'] : 'false';

    $filename = isset($_POST['filename']) && $_POST['filename'] !== '' ? $_POST['filename'] : 'config.json'; 
    $subscription_url = isset($_POST['subscription_url']) ? $_POST['subscription_url'] : ''; 
    $backend_url = isset($_POST['backend_url']) && $_POST['backend_url'] === 'custom' && !empty($_POST['custom_backend_url'])
    ? rtrim($_POST['custom_backend_url'], '?') . '?'
    : ($_POST['backend_url'] ?? 'https://url.v1.mk/sub?');
    $template_key = $_POST['template'] ?? ''; 
    $include = $_POST['include'] ?? ''; 
    $exclude = $_POST['exclude'] ?? '';        
    $template = $templates[$template_key] ?? '';
    $rename = isset($_POST['rename']) ? $_POST['rename'] : ''; 

    if (isset($_POST['action']) && $_POST['action'] === 'generate_subscription') {
        $final_url = buildFinalUrl($subscription_url, $template, $include, $exclude, $backend_url, $emoji, $udp, $xudp, $tfo, $ipv6, $rename, $tls13, $fdn, $sort);

        if (saveSubscriptionUrlToFile($final_url, $subscription_file)) {
            $result = saveSubscriptionContentToYaml($final_url, $filename);
        } else {
            $result = "Failed to save subscription link to file";
        }
    }

    if (isset($result)) {
        echo "<div id='log-message' class='alert alert-success'>" . nl2br(htmlspecialchars($result)) . "</div>";
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
        return "File downloaded successfully: $path<br>";
    } else {
        return "File download failed: $path<br>";
    }
}
?>
<?php
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['createCronJob'])) {
        $cronExpression = trim($_POST['cronExpression']);

        if (empty($cronExpression)) {
            echo "<div class='alert alert-warning'>The cron expression cannot be empty</div>";
            exit;
        }

        $cronJob = "$cronExpression /etc/neko/core/update_singbox.sh > /dev/null 2>&1";
        exec("crontab -l | grep -v '/etc/neko/core/update_singbox.sh' | crontab -");
        exec("(crontab -l; echo '$cronJob') | crontab -");
        echo "<div class='alert alert-success'>The cron job has been successfully added or updated.</div>";
    }
}
?>

<?php
$shellScriptPath = '/etc/neko/core/update_singbox.sh';
$LOG_FILE = '/etc/neko/tmp/log.txt';
$CONFIG_FILE = '/etc/neko/config/config.json';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['createShellScript'])) {
        $shellScriptContent = <<<EOL
#!/bin/sh

LOG_FILE="/etc/neko/tmp/log.txt"
LINK_FILE="/etc/neko/tmp/singbox.txt"
CONFIG_FILE="/etc/neko/config/config.json"

log() {
  echo "[ \$(date +'%H:%M:%S') ] \$1" >> "\$LOG_FILE"
}

log "Starting the update script..."
log "Attempting to read subscription link file: \$LINK_FILE"

if [ ! -f "\$LINK_FILE" ]; then
  log "Error: File \$LINK_FILE does not exist."
  exit 1
fi

SUBSCRIBE_URL=\$(awk 'NR==1 {print \$0}' "\$LINK_FILE" | tr -d '\\n\\r' | xargs)

if [ -z "\$SUBSCRIBE_URL" ]; then
  log "Error: Subscription link is empty or extraction failed."
  exit 1
fi

log "Using subscription link: \$SUBSCRIBE_URL"
log "Attempting to download and update the configuration file..."

wget -q -O "\$CONFIG_FILE" "\$SUBSCRIBE_URL" >> "\$LOG_FILE" 2>&1

if [ \$? -eq 0 ]; then
  log "Configuration file updated successfully. Saved to: \$CONFIG_FILE"
else
  log "Configuration file update failed. Please check the link or network."
  exit 1
fi

jq '.inbounds = [
  {
    "domain_strategy": "prefer_ipv4",
    "listen": "127.0.0.1",
    "listen_port": 2334,
    "sniff": true,
    "sniff_override_destination": true,
    "tag": "mixed-in",
    "type": "mixed",
    "users": []
  },
  {
    "tag": "tun",
    "type": "tun",
    "address": [
      "172.19.0.1/30",
      "fdfe:dcba:9876::1/126"
    ],
    "route_address": [
      "0.0.0.0/1",
      "128.0.0.0/1",
      "::/1",
      "8000::/1"
    ],
    "route_exclude_address": [
      "192.168.0.0/16",
      "fc00::/7"
    ],
    "stack": "system",
    "auto_route": true,
    "strict_route": true,
    "sniff": true,
    "platform": {
      "http_proxy": {
        "enabled": true,
        "server": "0.0.0.0",
        "server_port": 1082
      }
    }
  },
  {
    "tag": "mixed",
    "type": "mixed",
    "listen": "0.0.0.0",
    "listen_port": 1082,
    "sniff": true
  }
]' "\$CONFIG_FILE" > /tmp/config_temp.json && mv /tmp/config_temp.json "\$CONFIG_FILE"

jq '.experimental.clash_api = {
  "external_ui": "/etc/neko/ui/",
  "external_controller": "0.0.0.0:9090",
  "secret": "Akun"
}' "\$CONFIG_FILE" > /tmp/config_temp.json && mv /tmp/config_temp.json "\$CONFIG_FILE"

if [ \$? -eq 0 ]; then
  log "Configuration file modifications completed successfully."
else
  log "Error: Configuration file modification failed."
  exit 1
fi

EOL;

        if (file_put_contents($shellScriptPath, $shellScriptContent) !== false) {
            chmod($shellScriptPath, 0755); 
            echo "<div class='alert alert-success' data-translate='shell_script_created' data-dynamic-content='$shellScriptPath'></div>";
        } else {
            echo "<div class='alert alert-danger' data-translate='shell_script_failed'></div>";
        }
    }
}
?>

<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme, 0, -4) ?>">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>singbox - Nekobox</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/bootstrap/bootstrap-icons.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/bootstrap/bootstrap.bundle.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/neko.js"></script>
    <?php include './ping.php'; ?>
</head>
<body>
<style>
.custom-padding {
    padding-left: 5ch;  
    padding-right: 5ch;  
}

@media (max-width: 767px) {
.custom-padding {
    padding-left: 3ch;  
    padding-right: 3ch;  
}

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
        <a href="./index.php" class="col btn btn-lg text-nowrap"><i class="bi bi-house-door"></i> <span data-translate="home">Home</span></a>
        <a href="./mihomo_manager.php" class="col btn btn-lg text-nowrap"><i class="bi bi-folder"></i> <span data-translate="manager">Manager</span></a>
        <a href="./singbox.php" class="col btn btn-lg text-nowrap"><i class="bi bi-shop"></i> <span data-translate="template_i">Template I</span></a>
        <a href="./subscription.php" class="col btn btn-lg text-nowrap"><i class="bi bi-bank"></i> <span data-translate="template_ii">Template II</span></a>
        <a href="./mihomo.php" class="col btn btn-lg text-nowrap"><i class="bi bi-building"></i> <span data-translate="template_iii">Template III</span></a>
        <h1 class="text-center p-2" style="margin-top: 2rem; margin-bottom: 1rem;" data-translate="form_title"></h1>

        <div class="col-12 custom-padding">
            <div class="form-section">
                <form method="post">
                    <div class="mb-3">
                        <label for="subscription_url" class="form-label" data-translate="subscription_url_label"></label>
                        <input type="text" class="form-control" id="subscription_url" name="subscription_url"
                               value="<?php echo htmlspecialchars($current_subscription_url); ?>" placeholder="" data-translate-placeholder="subscription_url_placeholder"  required>
                    </div>

                    <div class="mb-3">
                        <label for="filename" class="form-label" data-translate="filename_label"></label>
                        <input type="text" class="form-control" id="filename" name="filename"
                               value="<?php echo htmlspecialchars(isset($_POST['filename']) ? $_POST['filename'] : ''); ?>"
                               placeholder="config.json">
                    </div>

                    <div class="mb-3">
                        <label for="backend_url" class="form-label" data-translate="backend_url_label"></label>
                        <select class="form-select" id="backend_url" name="backend_url" required>
                            <option value="https://url.v1.mk/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://url.v1.mk/sub?' ? 'selected' : ''; ?> data-translate="backend_url_option_1"></option>
                            <option value="https://sub.d1.mk/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://sub.d1.mk/sub?' ? 'selected' : ''; ?> data-translate="backend_url_option_2"></option>
                            <option value="https://sub.xeton.dev/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://sub.xeton.dev/sub?' ? 'selected' : ''; ?> data-translate="backend_url_option_3"></option>
                            <option value="https://www.tline.website/sub/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://www.tline.website/sub/sub?' ? 'selected' : ''; ?>>
                                tline.website
                            </option>
                            <option value="https://api.dler.io/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://api.dler.io/sub?' ? 'selected' : ''; ?>>
                                api.dler.io
                            </option>
                            <option value="https://v.id9.cc/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://v.id9.cc/sub?' ? 'selected' : ''; ?> data-translate="backend_url_option_6"></option>
                            <option value="https://sub.id9.cc/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://sub.id9.cc/sub?' ? 'selected' : ''; ?>>
                                sub.id9.cc
                            </option>
                            <option value="https://api.wcc.best/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://api.wcc.best/sub?' ? 'selected' : ''; ?>>
                                api.wcc.best
                            </option>
                            <option value="https://yun-api.subcloud.xyz/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://yun-api.subcloud.xyz/sub?' ? 'selected' : ''; ?>>
                                subcloud.xyz
                            </option>
                            <option value="https://sub.maoxiongnet.com/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'https://sub.maoxiongnet.com/sub?' ? 'selected' : ''; ?> data-translate="backend_url_option_10"></option>
                            <option value="http://localhost:25500/sub?" <?php echo ($_POST['backend_url'] ?? '') === 'http://localhost:25500/sub?' ? 'selected' : ''; ?> data-translate="backend_url_option_11"></option>
                            <option value="custom" <?php echo ($_POST['backend_url'] ?? '') === 'custom' ? 'selected' : ''; ?> data-translate="backend_url_option_custom"></option>
                        </select>
                    </div>

                    <div class="mb-3" id="custom_backend_url_input" style="display: none;">
                        <label for="custom_backend_url" class="form-label" data-translate="custom_backend_url_label"></label>
                        <input type="text" class="form-control" id="custom_backend_url" name="custom_backend_url" value="<?php echo htmlspecialchars($_POST['custom_backend_url'] ?? '') . (empty($_POST['custom_backend_url']) ? '' : '?'); ?>" />
                    </div>

                    <div class="mb-3">
                        <label for="template" class="form-label" data-translate="subscription"></label>
                        <select class="form-select" id="template" name="template" required>
                        <optgroup label="通用" style="color: #28a745; font-size: 20px;" data-translate="general">
                            <option value="1" <?php echo ($_POST['template'] ?? '') === '1' ? 'selected' : ''; ?> data-translate="default">默认</option>
                            <option value="2" <?php echo ($_POST['template'] ?? '') === '2' ? 'selected' : ''; ?> data-translate="auto_test">默认（自动测速）</option>
                            <option value="3" <?php echo ($_POST['template'] ?? '') === '3' ? 'selected' : ''; ?> data-translate="sony_tv">默认（索尼电视专用）</option>
                            <option value="4" <?php echo ($_POST['template'] ?? '') === '4' ? 'selected' : ''; ?> data-translate="clash_adguard">默认（附带用于 Clash 的 AdGuard DNS）</option>
                            <option value="5" <?php echo ($_POST['template'] ?? '') === '5' ? 'selected' : ''; ?> data-translate="acl_full_dream">ACL_全分组 Dream修改版</option>
                            <option value="6" <?php echo ($_POST['template'] ?? '') === '6' ? 'selected' : ''; ?> data-translate="acl_simplified_dream">ACL_精简分组 Dream修改版</option>
                            <option value="7" <?php echo ($_POST['template'] ?? '') === '7' ? 'selected' : ''; ?> data-translate="emby_tiktok_stream">emby-TikTok-流媒体分组-去广告加强版</option>
                            <option value="8" <?php echo ($_POST['template'] ?? '') === '8' ? 'selected' : ''; ?> data-translate="stream_general_group">流媒体通用分组</option>
                        </optgroup>
                        <optgroup label="ACL规则" style="color: #fd7e14; font-size: 20px;" data-translate="acl_rules">
                            <option value="9" <?php echo ($_POST['template'] ?? '') === '9' ? 'selected' : ''; ?> data-translate="acl_default">ACL_默认版</option>
                            <option value="10" <?php echo ($_POST['template'] ?? '') === '10' ? 'selected' : ''; ?> data-translate="acl_no_test">ACL_无测速版</option>
                            <option value="11" <?php echo ($_POST['template'] ?? '') === '11' ? 'selected' : ''; ?> data-translate="acl_adfree">ACL_去广告版</option>
                            <option value="12" <?php echo ($_POST['template'] ?? '') === '12' ? 'selected' : ''; ?> data-translate="acl_multicountry">ACL_多国家版</option>
                            <option value="13" <?php echo ($_POST['template'] ?? '') === '13' ? 'selected' : ''; ?> data-translate="acl_no_reject">ACL_无Reject版</option>
                            <option value="14" <?php echo ($_POST['template'] ?? '') === '14' ? 'selected' : ''; ?> data-translate="acl_no_speedtest_simplified">ACL_无测速精简版</option>
                            <option value="15" <?php echo ($_POST['template'] ?? '') === '15' ? 'selected' : ''; ?> data-translate="acl_full_group">ACL_全分组版</option>
                            <option value="16" <?php echo ($_POST['template'] ?? '') === '16' ? 'selected' : ''; ?> data-translate="acl_full_group_google">ACL_全分组谷歌版</option>
                            <option value="17" <?php echo ($_POST['template'] ?? '') === '17' ? 'selected' : ''; ?> data-translate="acl_full_group_multi_mode">ACL_全分组多模式版</option>
                            <option value="18" <?php echo ($_POST['template'] ?? '') === '18' ? 'selected' : ''; ?> data-translate="acl_full_group_nflx">ACL_全分组奈飞版</option>
                            <option value="19" <?php echo ($_POST['template'] ?? '') === '19' ? 'selected' : ''; ?> data-translate="acl_simplified">ACL_精简版</option>
                            <option value="20" <?php echo ($_POST['template'] ?? '') === '20' ? 'selected' : ''; ?> data-translate="acl_adfree_simplified">ACL_去广告精简版</option>
                            <option value="21" <?php echo ($_POST['template'] ?? '') === '21' ? 'selected' : ''; ?> data-translate="acl_fallback_simplified">ACL_Fallback精简版</option>
                            <option value="22" <?php echo ($_POST['template'] ?? '') === '22' ? 'selected' : ''; ?> data-translate="acl_multi_country_simplified">ACL_多国家精简版</option>
                            <option value="23" <?php echo ($_POST['template'] ?? '') === '23' ? 'selected' : ''; ?> data-translate="acl_multi_mode_simplified">ACL_多模式精简版</option>
                        </optgroup>
                        <optgroup label="全网搜集规则" style="color: #6f42c1; font-size: 20px;" data-translate="global_collection_rules">
                            <option value="24" <?php echo ($_POST['template'] ?? '') === '24' ? 'selected' : ''; ?> data-translate="general_rules">常规规则</option>
                            <option value="25" <?php echo ($_POST['template'] ?? '') === '25' ? 'selected' : ''; ?> data-translate="cool_private">酷酷自用</option>
                            <option value="26" <?php echo ($_POST['template'] ?? '') === '26' ? 'selected' : ''; ?> data-translate="pharos_no_test">PharosPro无测速</option>
                            <option value="27" <?php echo ($_POST['template'] ?? '') === '27' ? 'selected' : ''; ?> data-translate="region_failover">分区域故障转移</option>
                            <option value="28" <?php echo ($_POST['template'] ?? '') === '28' ? 'selected' : ''; ?> data-translate="regional_auto_test">分区域自动测速</option>
                            <option value="29" <?php echo ($_POST['template'] ?? '') === '29' ? 'selected' : ''; ?> data-translate="regional_no_auto_test">分区域无自动测速</option>
                            <option value="30" <?php echo ($_POST['template'] ?? '') === '30' ? 'selected' : ''; ?>>OoHHHHHHH</option>
                            <option value="31" <?php echo ($_POST['template'] ?? '') === '31' ? 'selected' : ''; ?>>CFW-TAP</option>
                            <option value="32" <?php echo ($_POST['template'] ?? '') === '32' ? 'selected' : ''; ?> data-translate="lhl77_full_group">lhl77全分组（定期更新）</option>
                            <option value="33" <?php echo ($_POST['template'] ?? '') === '33' ? 'selected' : ''; ?> data-translate="lhl77_simple">lhl77简易版（定期更新）</option>
                            <option value="34" <?php echo ($_POST['template'] ?? '') === '34' ? 'selected' : ''; ?> data-translate="connershua_outbound">ConnersHua 神机规则 Outbound</option>
                            <option value="35" <?php echo ($_POST['template'] ?? '') === '35' ? 'selected' : ''; ?> data-translate="connershua_inbound">ConnersHua 神机规则 Inbound 回国专用</option>
                            <option value="36" <?php echo ($_POST['template'] ?? '') === '36' ? 'selected' : ''; ?> data-translate="lhie1_dongzhu">lhie1 洞主规则（使用 Clash 分组规则）</option>
                            <option value="37" <?php echo ($_POST['template'] ?? '') === '37' ? 'selected' : ''; ?> data-translate="lhie1_dongzhu_full">lhie1 洞主规则完整版</option>
                            <option value="38" <?php echo ($_POST['template'] ?? '') === '38' ? 'selected' : ''; ?> data-translate="epho1">eHpo1 规则</option>
                            <option value="39" <?php echo ($_POST['template'] ?? '') === '39' ? 'selected' : ''; ?> data-translate="multi_strategy_default_whitelist">多策略组默认白名单模式</option>
                            <option value="40" <?php echo ($_POST['template'] ?? '') === '40' ? 'selected' : ''; ?> data-translate="multi_strategy_reduced_audit">多策略组可以有效减少审计触发</option>
                            <option value="41" <?php echo ($_POST['template'] ?? '') === '41' ? 'selected' : ''; ?> data-translate="simplified_strategy_default_whitelist">精简策略默认白名单</option>
                            <option value="42" <?php echo ($_POST['template'] ?? '') === '42' ? 'selected' : ''; ?> data-translate="multi_strategy_smtp">多策略增加SMTP策略</option>
                            <option value="43" <?php echo ($_POST['template'] ?? '') === '43' ? 'selected' : ''; ?> data-translate="no_strategy_recommended">无策略入门推荐</option>
                            <option value="44" <?php echo ($_POST['template'] ?? '') === '44' ? 'selected' : ''; ?> data-translate="no_strategy_country_group">无策略入门推荐国家分组</option>
                            <option value="45" <?php echo ($_POST['template'] ?? '') === '45' ? 'selected' : ''; ?> data-translate="no_strategy_advanced">无策略进阶版</option>
                            <option value="46" <?php echo ($_POST['template'] ?? '') === '46' ? 'selected' : ''; ?> data-translate="no_strategy_shadow_vip">无策略魅影vip分组</option>
                            <option value="47" <?php echo ($_POST['template'] ?? '') === '47' ? 'selected' : ''; ?> data-translate="pinyun_exclusive_hk">品云专属配置（仅香港区域分组）</option>
                            <option value="48" <?php echo ($_POST['template'] ?? '') === '48' ? 'selected' : ''; ?> data-translate="pinyun_exclusive_all_regions">品云专属配置（全地域分组）</option>
                            <option value="49" <?php echo ($_POST['template'] ?? '') === '49' ? 'selected' : ''; ?> data-translate="nzw9314_rules">nzw9314 规则</option>
                            <option value="50" <?php echo ($_POST['template'] ?? '') === '50' ? 'selected' : ''; ?> data-translate="maicoo_l_rules">maicoo-l 规则</option>
                            <option value="51" <?php echo ($_POST['template'] ?? '') === '51' ? 'selected' : ''; ?> data-translate="dlercloud_platinum">DlerCloud Platinum 李哥定制规则</option>
                            <option value="52" <?php echo ($_POST['template'] ?? '') === '52' ? 'selected' : ''; ?> data-translate="dlercloud_gold">DlerCloud Gold 李哥定制规则</option>
                            <option value="53" <?php echo ($_POST['template'] ?? '') === '53' ? 'selected' : ''; ?> data-translate="dlercloud_silver">DlerCloud Silver 李哥定制规则</option>
                            <option value="54" <?php echo ($_POST['template'] ?? '') === '54' ? 'selected' : ''; ?> data-translate="proxystorage_personal">ProxyStorage自用</option>
                            <option value="55" <?php echo ($_POST['template'] ?? '') === '55' ? 'selected' : ''; ?> data-translate="shellclash_modified">ShellClash修改版规则 (by UlinoyaPed)</option>
                        </optgroup>
                        <optgroup label="各大机场规则" style="color: #007bff; font-size: 20px;" data-translate="airport_rules">
                            <option value="56" <?php echo ($_POST['template'] ?? '') === '56' ? 'selected' : ''; ?>>EXFLUX</option>
                            <option value="57" <?php echo ($_POST['template'] ?? '') === '57' ? 'selected' : ''; ?>>NaNoport</option>
                            <option value="58" <?php echo ($_POST['template'] ?? '') === '58' ? 'selected' : ''; ?>>CordCloud</option>
                            <option value="59" <?php echo ($_POST['template'] ?? '') === '59' ? 'selected' : ''; ?>>BigAirport</option>
                            <option value="60" <?php echo ($_POST['template'] ?? '') === '60' ? 'selected' : ''; ?> data-translate="runaway_cloud">跑路云</option>
                            <option value="61" <?php echo ($_POST['template'] ?? '') === '61' ? 'selected' : ''; ?>>WaveCloud</option>
                            <option value="62" <?php echo ($_POST['template'] ?? '') === '62' ? 'selected' : ''; ?> data-translate="jiji">几鸡</option>
                            <option value="63" <?php echo ($_POST['template'] ?? '') === '63' ? 'selected' : ''; ?> data-translate="four_seasons_acceleration">四季加速</option>
                            <option value="64" <?php echo ($_POST['template'] ?? '') === '64' ? 'selected' : ''; ?>>ImmTelecom</option>
                            <option value="65" <?php echo ($_POST['template'] ?? '') === '65' ? 'selected' : ''; ?>>AmyTelecom</option>
                            <option value="66" <?php echo ($_POST['template'] ?? '') === '66' ? 'selected' : ''; ?>>LinkCube</option>
                            <option value="67" <?php echo ($_POST['template'] ?? '') === '67' ? 'selected' : ''; ?>>Miaona</option>
                            <option value="68" <?php echo ($_POST['template'] ?? '') === '68' ? 'selected' : ''; ?>>Foo&Friends</option>
                            <option value="69" <?php echo ($_POST['template'] ?? '') === '69' ? 'selected' : ''; ?>>ABCloud</option>
                            <option value="70" <?php echo ($_POST['template'] ?? '') === '70' ? 'selected' : ''; ?> data-translate="saltedfish">咸鱼</option>
                            <option value="71" <?php echo ($_POST['template'] ?? '') === '71' ? 'selected' : ''; ?> data-translate="convenience_store">便利店</option>
                            <option value="72" <?php echo ($_POST['template'] ?? '') === '72' ? 'selected' : ''; ?>>CNIX</option>
                            <option value="73" <?php echo ($_POST['template'] ?? '') === '73' ? 'selected' : ''; ?>>Nirvana</option>
                            <option value="74" <?php echo ($_POST['template'] ?? '') === '74' ? 'selected' : ''; ?>>V2Pro</option>
                            <option value="75" <?php echo ($_POST['template'] ?? '') === '75' ? 'selected' : ''; ?> data-translate="stitch_auto_test">史迪仔-自动测速</option>
                            <option value="76" <?php echo ($_POST['template'] ?? '') === '76' ? 'selected' : ''; ?> data-translate="stitch_load_balance">史迪仔-负载均衡</option>
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
                        <optgroup label="特殊" style="color: #ff0000; font-size: 20px;" data-translate="special">
                            <option value="87" <?php echo ($_POST['template'] ?? '') === '87' ? 'selected' : ''; ?>>NeteaseUnblock</option>
                            <option value="88" <?php echo ($_POST['template'] ?? '') === '88' ? 'selected' : ''; ?>>Basic</option>
                        </optgroup>
                        </select>
                    </div>

                    <div class="mb-3">
                        <label class="form-label" data-translate="choose_additional_options"></label>
                        <div class="d-flex flex-wrap align-items-center">
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="emoji" name="emoji" value="true"
                                       <?php echo isset($_POST['emoji']) && $_POST['emoji'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="emoji" data-translate="enable_emoji"></label>
                            </div>
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="udp" name="udp" value="true"
                                       <?php echo isset($_POST['udp']) && $_POST['udp'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="udp" data-translate="enable_udp"></label>
                            </div>
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="xudp" name="xudp" value="true"
                                       <?php echo isset($_POST['xudp']) && $_POST['xudp'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="xudp" data-translate="enable_xudp"></label>
                            </div>
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="tfo" name="tfo" value="true"
                                       <?php echo isset($_POST['tfo']) && $_POST['tfo'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="tfo" data-translate="enable_tfo"></label>
                            </div>
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="fdn" name="fdn" value="true"
                                       <?php echo isset($_POST['fdn']) && $_POST['fdn'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="tls13" data-translate="enable_fdn"></label>
                            </div>
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="sort" name="sort" value="true"
                                       <?php echo isset($_POST['sort']) && $_POST['sort'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="sort" data-translate="enable_sort"></label>
                            </div>
                            <div class="form-check me-3">
                                <input type="checkbox" class="form-check-input" id="tls13" name="tls13" value="true"
                                       <?php echo isset($_POST['tls13']) && $_POST['tls13'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="tls13" data-translate="enable_tls13"></label>
                            </div>
                            <div class="form-check">
                                <input type="checkbox" class="form-check-input" id="ipv6" name="ipv6" value="true"
                                       <?php echo isset($_POST['ipv6']) && $_POST['ipv6'] == 'true' ? 'checked' : ''; ?>>
                                <label class="form-check-label" for="ipv6" data-translate="enable_ipv6"></label>
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label for="include" class="form-label" data-translate="include_nodes"></label>
                        <input type="text" class="form-control" id="include" name="include"
                               value="<?php echo htmlspecialchars($_POST['include'] ?? ''); ?>" placeholder="要保留的节点，支持正则 | 分隔" data-translate-placeholder="include_placeholder">
                    </div>

                    <div class="mb-3">
                        <label for="exclude" class="form-label" data-translate="exclude_nodes"></label>
                        <input type="text" class="form-control" id="exclude" name="exclude"
                               value="<?php echo htmlspecialchars($_POST['exclude'] ?? ''); ?>" placeholder="要排除的节点，支持正则 | 分隔" data-translate-placeholder="exclude_placeholder">
                    </div>

                   <div class="mb-3">
                        <label for="rename" class="form-label" data-translate="rename_nodes"></label>
                        <input type="text" class="form-control" id="rename" name="rename"
                               value="<?php echo htmlspecialchars(isset($_POST['rename']) ? $_POST['rename'] : ''); ?>"
                               placeholder="输入重命名内容（举例：`a@b``1@2`，|符可用\转义）" data-translate-placeholder="rename_placeholder">
                    </div>

                    <div class="mb-3">
                        <label class="form-label" for="download_option" data-translate="choose_download_database"></label>
                        <select class="form-select" id="download_option" name="download_option">
                               <option value="geoip" <?php echo isset($_POST['download_option']) && $_POST['download_option'] === 'geoip' ? 'selected' : ''; ?>data-translate="geoip_database">GeoIP 数据库 (geoip.db)</option>
                              <option value="geosite" <?php echo isset($_POST['download_option']) && $_POST['download_option'] === 'geosite' ? 'selected' : ''; ?>data-translate="geosite_database">Geosite 数据库 (geosite.db)</option>
                        </select>
                    </div>
                   <button type="submit" class="btn btn-primary col mx-2" name="action" value="generate_subscription"><i class="bi bi-file-earmark-text"></i> <span data-translate="generate_configuration_file"></span></button>
                    <button type="submit" class="btn btn-success" name="download_action" value="download_files"><i class="bi bi-download"></i>  <span data-translate="download_database"></span></button>
                </form>
            </div>
        </div>
    <div class="container custom-padding">
        <form method="post">
            <h5 style="margin-top: 20px;" data-translate="scheduled_tasks"></h5>
            <button type="button" class="btn btn-primary mx-2" data-bs-toggle="modal" data-bs-target="#cronModal"><i class="bi bi-clock"></i> <span data-translate="set_scheduled_task"></span></button>
            <button type="submit" name="createShellScript" value="true" class="btn btn-success"><i class="bi bi-terminal"></i> <span data-translate="generate_update_script"></span></button>
        </form>
    </div>
        <div class="modal fade" id="cronModal" tabindex="-1" aria-labelledby="cronModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="cronModalLabel" data-translate="cron_task_title"></h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <div class="modal-body">
                        <form method="POST">
                            <div class="mb-3">
                                <label for="cronExpression" class="form-label" data-translate="cron_expression_label"></label>
                                <input type="text" class="form-control" id="cronExpression" name="cronExpression"  value="0 2 * * *" required>
                            </div>
                            <div class="alert alert-info">
                              <strong data-translate="cron_hint">提示:</strong> <span data-translate="cron_expression_format">Cron 表达式格式：</span>
                              <ul>
                                <li><span data-translate="cron_format_help"></span></li>
                                <li><?= $langData[$currentLang]['example1'] ?>: <code>0 2 * * *</code></li>
                                <li><?= $langData[$currentLang]['example2'] ?>: <code>0 3 * * 1</code></li>
                                <li><?= $langData[$currentLang]['example3'] ?>: <code>0 9 * * 1-5</code></li>
                              </ul>
                            </div>
                          </div>
                          <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancel_button"></button>
                            <button type="submit" name="createCronJob" class="btn btn-primary" data-translate="save_button"></button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
        <div class="help mt-4 custom-padding">
            <p data-translate="first_time_singbox_user"><p>
            <p style="color: red;" data-translate="warning"></p>
            <p data-translate="subscription_conversion"></p>
            <a href="https://github.com/youshandefeiyang/sub-web-modify" target="_blank" class="btn btn-primary" style="color: white;">
            <i data-feather="github"></i> <span data-translate="visit_link"></span>
            </a>
        </div>
        <div class="result mt-4 custom-padding">
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
