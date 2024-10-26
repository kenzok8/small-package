<?php

ini_set('memory_limit', '128M'); 

function logMessage($message) {
    $logFile = '/var/log/config_update.log'; 
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($logFile, "[$timestamp] $message\n", FILE_APPEND);
}

$urls = [
    "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/nekobox/luci-app-nekobox/root/etc/neko/config/mihomo.yaml" => "/etc/neko/config/mihomo.yaml",
    "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/nekobox/luci-app-nekobox/root/etc/neko/config/Puernya.json" => "/etc/neko/config/Puernya.json"
];

foreach ($urls as $download_url => $destination_path) {
    if (!is_dir(dirname($destination_path))) {
        mkdir(dirname($destination_path), 0755, true);
    }

    exec("wget -O '$destination_path' '$download_url'", $output, $return_var);
    if ($return_var !== 0) {
        logMessage("下载失败：$destination_path");
        die("下载失败：$destination_path");
    }

    logMessage(basename($destination_path) . " 文件已成功更新！");
}

echo "文件已成功更新！";

?>
