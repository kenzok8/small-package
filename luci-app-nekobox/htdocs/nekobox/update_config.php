<?php

ini_set('memory_limit', '128M'); 

$logMessages = [];

function logMessage($message) {
    global $logMessages;
    $timestamp = date('H:i:s');
    $logMessages[] = "[$timestamp] $message";
}

$urls = [
    "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/nekobox/luci-app-nekobox/root/etc/neko/config/mihomo.yaml" => "/etc/neko/config/mihomo.yaml",
    "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/nekobox/luci-app-nekobox/root/etc/neko/config/Puernya.json" => "/etc/neko/config/Puernya.json"
];

function downloadFile($url, $path, $retries = 3) {
    for ($i = 0; $i < $retries; $i++) {
        $command = "curl -L --fail -o '$path' '$url'";
        exec($command, $output, $return_var);

        if ($return_var === 0) {
            logMessage(basename($path) . " 文件已成功更新！");
            return true;
        } else {
            logMessage("下载失败：$path，重试中（" . ($i + 1) . "/$retries）...");
            sleep(2);  
        }
    }
    logMessage("下载失败：$path，已超过最大重试次数！");
    return false;
}

foreach ($urls as $download_url => $destination_path) {
    if (!is_dir(dirname($destination_path))) {
        mkdir(dirname($destination_path), 0755, true);
    }
    downloadFile($download_url, $destination_path);
}

echo implode("\n", $logMessages);

?>
