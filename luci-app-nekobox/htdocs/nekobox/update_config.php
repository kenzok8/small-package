<?php
ini_set('memory_limit', '128M');
ini_set('max_execution_time', 300);

$logMessages = [];

function logMessage($filename, $message) {
    global $logMessages;
    $timestamp = date('H:i:s', strtotime('+8 hours'));
    $logMessages[] = "[$timestamp] $filename: $message";
}

function downloadFile($url, $destination, $retries = 3, $timeout = 30) {
    $attempt = 1;
    
    while ($attempt <= $retries) {
        try {
            $dir = dirname($destination);
            if (!is_dir($dir)) {
                mkdir($dir, 0755, true);
            }

            $command = sprintf(
                "wget -q --timeout=%d --tries=%d --header='Accept-Charset: utf-8' -O %s %s",
                $timeout, 
                $retries, 
                escapeshellarg($destination),
                escapeshellarg($url)
            );

            $output = [];
            $return_var = null;
            exec($command, $output, $return_var);
            
            if ($return_var !== 0) {
                throw new Exception("wget 错误信息: " . implode("\n", $output));
            }
            
            logMessage(basename($destination), "下载并保存成功");
            return true;
            
        } catch (Exception $e) {
            logMessage(basename($destination), "第 $attempt 次尝试失败: " . $e->getMessage());
            
            if ($attempt === $retries) {
                logMessage(basename($destination), "所有下载尝试均失败");
                return false;
            }
            
            $attempt++;
            sleep(2);
        }
    }
    
    return false;
}

echo "开始更新配置文件...\n";

$urls = [
    "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/nekobox/luci-app-nekobox/root/etc/neko/config/mihomo.yaml" => "/etc/neko/config/mihomo.yaml",
    "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/nekobox/luci-app-nekobox/root/etc/neko/config/Puernya.json" => "/etc/neko/config/Puernya.json"
];

foreach ($urls as $url => $destination) {
    logMessage(basename($destination), "开始从 $url 下载");
    
    if (downloadFile($url, $destination)) {
        logMessage(basename($destination), "文件更新成功");
    } else {
        logMessage(basename($destination), "文件更新失败");
    }
}

echo "\n配置文件更新完成！\n\n";

foreach ($logMessages as $message) {
    echo $message . "\n";
}
?>
