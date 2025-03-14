<?php
ini_set('memory_limit', '128M');
ini_set('max_execution_time', 300);

$logMessages = [];

function logMessage($filename, $message) {
    global $logMessages;
    $timestamp = date('H:i:s');
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
                throw new Exception("wget error message: " . implode("\n", $output));
            }
            
            logMessage(basename($destination), "Download and save successful");
            return true;
            
        } catch (Exception $e) {
            logMessage(basename($destination), "Attempt $attempt failed: " . $e->getMessage());
            
            if ($attempt === $retries) {
                logMessage(basename($destination), "All download attempts failed");
                return false;
            }
            
            $attempt++;
            sleep(2);
        }
    }
    
    return false;
}

echo "Start updating configuration file...\n";

$urls = [
    "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/refs/heads/main/luci-app-nekobox/root/etc/neko/config/mihomo.yaml" => "/etc/neko/config/mihomo.yaml",
    "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/nekobox/luci-app-nekobox/root/etc/neko/config/Puernya.json" => "/etc/neko/config/Puernya.json"
];

foreach ($urls as $url => $destination) {
    logMessage(basename($destination), "Start downloading from $url");
    
    if (downloadFile($url, $destination)) {
        logMessage(basename($destination), "File update successful");
    } else {
        logMessage(basename($destination), "File update failed");
    }
}

echo "\nConfiguration file update completed！\n\n";

foreach ($logMessages as $message) {
    echo $message . "\n";
}
?>