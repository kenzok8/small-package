<?php

ini_set('memory_limit', '128M'); 

$logMessages = [];

function logMessage($message) {
    global $logMessages;
    $timestamp = date('H:i:s', strtotime('+8 hours'));
    $logMessages[] = "[$timestamp] $message";
}

$urls = [
    "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/nekobox/luci-app-nekobox/root/etc/neko/config/mihomo.yaml" => "/etc/neko/config/mihomo.yaml",
    "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/nekobox/luci-app-nekobox/root/etc/neko/config/Puernya.json" => "/etc/neko/config/Puernya.json"
];

$maxConnections = 5;
$retries = 3;
$downloadedFiles = []; 

function parallelDownload($urls, $retries, $maxConnections) {
    $multiCurl = curl_multi_init();
    $handles = [];
    $failedUrls = [];
    
    global $downloadedFiles;

    foreach ($urls as $url => $path) {
        if (in_array($path, $downloadedFiles)) {
            continue;
        }

        $dir = dirname($path);
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_FAILONERROR, true);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
        curl_setopt($ch, CURLOPT_WRITEFUNCTION, function($curl, $data) use ($path) {
            $fp = fopen($path, 'a'); 
            if ($fp === false) {
                return -1; 
            }
            fwrite($fp, $data);
            fclose($fp);
            return strlen($data);
        });

        curl_multi_add_handle($multiCurl, $ch);
        $handles[] = ['handle' => $ch, 'path' => $path, 'url' => $url];
    }

    do {
        curl_multi_exec($multiCurl, $running);
        curl_multi_select($multiCurl);
    } while ($running > 0);

    foreach ($handles as $data) {
        $ch = $data['handle'];
        $path = $data['path'];

        if (curl_errno($ch) === 0) {
            logMessage(basename($path) . " 文件已成功更新！");
            $downloadedFiles[] = $path;
        } else {
            $failedUrls[$data['url']] = $path;
            logMessage("下载失败：{$data['url']}，重试中...");
        }
        curl_multi_remove_handle($multiCurl, $ch);
        curl_close($ch);
    }

    curl_multi_close($multiCurl);

    return $failedUrls;
}

$failedUrls = parallelDownload($urls, $retries, $maxConnections);

if (!empty($failedUrls)) {
    logMessage("重试下载失败的文件...");
    parallelDownload($failedUrls, $retries, $maxConnections);
}

echo implode("\n", $logMessages);

?>