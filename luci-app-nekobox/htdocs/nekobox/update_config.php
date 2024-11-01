<?php

ini_set('memory_limit', '128M'); 

$logMessages = [];

function logMessage($filename, $message) {
    global $logMessages;
    $timestamp = date('H:i:s', strtotime('+8 hours'));
    $logMessages[] = "[$timestamp] $filename: $message";
}

$urls = [
    "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/nekobox/luci-app-nekobox/root/etc/neko/config/mihomo.yaml" => "/etc/neko/config/mihomo.yaml",
    "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/nekobox/luci-app-nekobox/root/etc/neko/config/Puernya.json" => "/etc/neko/config/Puernya.json"
];

$multiHandle = curl_multi_init();
$curlHandles = [];

foreach ($urls as $url => $path) {
    $ch = curl_init($url);
    $directory = dirname($path);
    if (!is_dir($directory)) {
        if (!mkdir($directory, 0755, true)) {
            logMessage("创建目录失败: $directory");
            continue;
        }
    }

    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FILE, fopen($path, 'w'));
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_multi_add_handle($multiHandle, $ch);
    $curlHandles[$url] = $ch; 
}

$running = null;
do {
    curl_multi_exec($multiHandle, $running);
    curl_multi_select($multiHandle);
} while ($running > 0);

foreach ($curlHandles as $url => $ch) {
    $return_var = curl_errno($ch);
    $filename = basename($urls[$url]); 
    if ($return_var !== CURLE_OK) {
        logMessage($filename, "下载失败: " . curl_error($ch));
    } else {
        logMessage($filename, "成功下载到: " . $urls[$url]);
    }
    curl_multi_remove_handle($multiHandle, $ch);
    curl_close($ch);
}

curl_multi_close($multiHandle);

foreach ($logMessages as $logMessage) {
    echo $logMessage . "\n";
}
?>
