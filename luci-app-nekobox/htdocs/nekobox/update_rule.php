<?php

ini_set('memory_limit', '128M');

$logMessages = [];

function logMessage($message) {
    global $logMessages;
    $timestamp = date('H:i:s', strtotime('+8 hours'));
    $logMessages[] = "[$timestamp] $message";
}

$urls = [
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/ads.srs" => "/www/nekobox/rules/ads.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/ai.srs" => "/www/nekobox/rules/ai.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/apple-cn.srs" => "/www/nekobox/rules/apple-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/applications.srs" => "/www/nekobox/rules/applications.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/cn.srs" => "/www/nekobox/rules/cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/cnip.srs" => "/www/nekobox/rules/cnip.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/disney.srs" => "/www/nekobox/rules/disney.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/fakeip-filter.srs" => "/www/nekobox/rules/fakeip-filter.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/games-cn.srs" => "/www/nekobox/rules/games-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/google-cn.srs" => "/www/nekobox/rules/google-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/microsoft-cn.srs" => "/www/nekobox/rules/microsoft-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/netflix.srs" => "/www/nekobox/rules/netflix.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/networktest.srs" => "/www/nekobox/rules/networktest.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/private.srs" => "/www/nekobox/rules/private.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/privateip.srs" => "/www/nekobox/rules/privateip.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/proxy.srs" => "/www/nekobox/rules/proxy.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/telegramip.srs" => "/www/nekobox/rules/telegramip.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/tiktok.srs" => "/www/nekobox/rules/tiktok.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/youtube.srs" => "/www/nekobox/rules/youtube.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/geosite/tiktok.srs" => "/www/nekobox/rules/geosite/tiktok.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/geosite/netflix.srs" => "/www/nekobox/rules/geosite/netflix.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite/geosite-cn.srs" => "/www/nekobox/geosite/geosite-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/ads.srs" => "/www/nekobox/ads.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/cache.db" => "/www/nekobox/cache.db",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/cn.srs" => "/www/nekobox/cn.srs", 
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/cnip.srs" => "/www/nekobox/cnip.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geoip-apple.srs" => "/www/nekobox/geoip-apple.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geoip-cn.srs" => "/www/nekobox/geoip-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geoip-google.srs" => "/www/nekobox/geoip-google.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geoip-netflix.srs" => "/www/nekobox/geoip-netflix.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geoip-telegram.srs" => "/www/nekobox/geoip-telegram.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geoip-tiktok.srs" => "/www/nekobox/geoip-tiktok.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-apple.srs" => "/www/nekobox/geosite-apple.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-bilibili.srs" => "/www/nekobox/geosite-bilibili.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-cn.srs" => "/www/nekobox/geosite/geosite-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-disney.srs" => "/www/nekobox/geosite-disney.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-geolocation-!cn.srs" => "/www/nekobox/geosite-geolocation-!cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-github.srs" => "/www/nekobox/geosite-github.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-google.srs" => "/www/nekobox/geosite-google.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-microsoft.srs" => "/www/nekobox/geosite-microsoft.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-netflix.srs" => "/www/nekobox/geosite-netflix.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-openai.srs" => "/www/nekobox/geosite-openai.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-telegram.srs" => "/www/nekobox/geosite-telegram.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-tiktok.srs" => "/www/nekobox/geosite-tiktok.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-youtube.srs" => "/www/nekobox/geosite-youtube.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite.db" => "/www/nekobox/geosite.db"
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
