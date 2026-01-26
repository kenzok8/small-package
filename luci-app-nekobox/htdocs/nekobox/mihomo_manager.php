<?php
ob_start();
include './cfg.php';
$uploadDir = '/etc/neko/proxy_provider/';
$configDir = '/etc/neko/config/';

ini_set('memory_limit', '256M');

if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

if (!is_dir($configDir)) {
    mkdir($configDir, 0755, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_FILES['fileInput'])) {
        $file = $_FILES['fileInput'];
        $uploadFilePath = $uploadDir . basename($file['name']);

        if ($file['error'] === UPLOAD_ERR_OK) {
            if (move_uploaded_file($file['tmp_name'], $uploadFilePath)) {
                echo '<div class="log-message alert alert-success" role="alert" data-translate="file_upload_success" data-dynamic-content="' . htmlspecialchars(basename($file['name'])) . '"></div>';
            } else {
                echo '<div class="log-message alert alert-danger" role="alert" data-translate="file_upload_failed"></div>';
            }
        } else {
            echo '<div class="log-message alert alert-danger" role="alert" data-translate="file_upload_error" data-dynamic-content="' . $file['error'] . '"></div>';
        }
    }

    if (isset($_FILES['configFileInput'])) {
        $file = $_FILES['configFileInput'];
        $uploadFilePath = $configDir . basename($file['name']);

        if ($file['error'] === UPLOAD_ERR_OK) {
            if (move_uploaded_file($file['tmp_name'], $uploadFilePath)) {
                echo '<div class="log-message alert alert-success" role="alert" data-translate="config_upload_success" data-dynamic-content="' . htmlspecialchars(basename($file['name'])) . '"></div>';
            } else {
                echo '<div class="log-message alert alert-danger" role="alert" data-translate="config_upload_failed"></div>';
            }
        } else {
            echo '<div class="log-message alert alert-danger" role="alert" data-translate="file_upload_error" data-dynamic-content="' . $file['error'] . '"></div>';
        }
    }

    if (isset($_POST['deleteFile'])) {
        $fileToDelete = $uploadDir . basename($_POST['deleteFile']);
        if (file_exists($fileToDelete) && unlink($fileToDelete)) {
            echo '<div class="log-message alert alert-success" role="alert" data-translate="file_delete_success" data-dynamic-content="' . htmlspecialchars(basename($_POST['deleteFile'])) . '"></div>';
        } else {
            //echo '<div class="log-message alert alert-danger" role="alert" data-translate="file_delete_failed"></div>';
        }
    }

    if (isset($_POST['deleteConfigFile'])) {
        $fileToDelete = $configDir . basename($_POST['deleteConfigFile']);
        if (file_exists($fileToDelete) && unlink($fileToDelete)) {
            echo '<div class="log-message alert alert-success" role="alert" data-translate="config_delete_success" data-dynamic-content="' . htmlspecialchars(basename($_POST['deleteConfigFile'])) . '"></div>';
        } else {
           // echo '<div class="log-message alert alert-danger" role="alert" data-translate="config_delete_failed"></div>';
        }
    }

    if (isset($_POST['oldFileName'], $_POST['newFileName'], $_POST['fileType'])) {
        $oldFileName = basename($_POST['oldFileName']);
        $newFileName = basename($_POST['newFileName']);
        $fileType = $_POST['fileType'];

        if ($fileType === 'proxy') {
            $oldFilePath = $uploadDir . $oldFileName;
            $newFilePath = $uploadDir . $newFileName;
        } elseif ($fileType === 'config') {
            $oldFilePath = $configDir . $oldFileName;
            $newFilePath = $configDir . $newFileName;
        } else {
            echo '<div class="log-message alert alert-danger" role="alert" data-translate="file_not_found"></div>';
            exit;
        }

        if (file_exists($oldFilePath) && !file_exists($newFilePath)) {
            if (rename($oldFilePath, $newFilePath)) {
                echo '<div class="log-message alert alert-success" role="alert" data-translate="file_rename_success" data-dynamic-content="' . htmlspecialchars($oldFileName) . ' -> ' . htmlspecialchars($newFileName) . '"></div>';
            } else {
                echo '<div class="log-message alert alert-danger" role="alert" data-translate="file_rename_failed"></div>';
            }
        } else {
            echo '<div class="log-message alert alert-danger" role="alert" data-translate="file_rename_exists"></div>';
        }
    }

    if (isset($_POST['saveContent'], $_POST['fileName'], $_POST['fileType'])) {
        $fileToSave = ($_POST['fileType'] === 'proxy') ? $uploadDir . basename($_POST['fileName']) : $configDir . basename($_POST['fileName']);
        $contentToSave = $_POST['saveContent'];
        file_put_contents($fileToSave, $contentToSave);
        echo '<div class="log-message alert alert-info" role="alert" data-translate="file_save_success" data-dynamic-content="' . htmlspecialchars(basename($fileToSave)) . '"></div>';
    }
}

function formatFileModificationTime($filePath) {
    if (file_exists($filePath)) {
        $fileModTime = filemtime($filePath);
        return date('Y-m-d H:i:s', $fileModTime);
    } else {
        return '<span data-translate="file_not_found"></span>';
    }
}

$proxyFiles = scandir($uploadDir);
$configFiles = scandir($configDir);

if ($proxyFiles !== false) {
    $proxyFiles = array_diff($proxyFiles, array('.', '..'));
    $proxyFiles = array_filter($proxyFiles, function($file) {
        return pathinfo($file, PATHINFO_EXTENSION) !== 'txt';
    });
} else {
    $proxyFiles = []; 
}

if ($configFiles !== false) {
    $configFiles = array_diff($configFiles, array('.', '..'));
} else {
    $configFiles = []; 
}

function formatSize($size) {
    $units = array('B', 'KB', 'MB', 'GB', 'TB');
    $unit = 0;
    while ($size >= 1024 && $unit < count($units) - 1) {
        $size /= 1024;
        $unit++;
    }
    return round($size, 2) . ' ' . $units[$unit];
}

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['editFile'], $_GET['fileType'])) {
    $filePath = ($_GET['fileType'] === 'proxy') ? $uploadDir. basename($_GET['editFile']) : $configDir . basename($_GET['editFile']);
    if (file_exists($filePath)) {
        header('Content-Type: text/plain');
        echo file_get_contents($filePath);
        exit;
    } else {
        echo '<span data-translate="file_not_found"></span>';
        exit;
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['downloadFile'], $_GET['fileType'])) {
    $fileType = $_GET['fileType'];
    $fileName = basename($_GET['downloadFile']);
    $filePath = ($fileType === 'proxy') ? $uploadDir . $fileName : $configDir . $fileName;

    if (file_exists($filePath)) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . $fileName . '"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($filePath));
        readfile($filePath);
        exit;
    } else {
        echo '<span data-translate="file_not_found"></span>';
    }
}
?>
<?php
$JSON_FILE = '/etc/neko/proxy_provider/subscriptions.json';
$subscriptionPath = '/etc/neko/proxy_provider/';
$notificationMessage = "";
$updateCompleted = false;

if (!file_exists($subscriptionPath)) {
    mkdir($subscriptionPath, 0755, true);
}

if (!file_exists($JSON_FILE)) {
    $emptySubs = [];
    for ($i = 0; $i < 6; $i++) {
        $emptySubs[] = [
            'url' => '',
            'file_name' => "subscription_" . ($i + 1) . ".yaml"
        ];
    }
    file_put_contents($JSON_FILE, json_encode($emptySubs, JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT));
}

function getSubscriptionsFromFile() {
    global $JSON_FILE;
    if (file_exists($JSON_FILE)) {
        $content = file_get_contents($JSON_FILE);
        $data = json_decode($content, true);
        if (!is_array($data) || count($data) < 6) {
            $data = $data ?? [];
            for ($i = count($data); $i < 6; $i++) {
                $data[$i] = [
                    'url' => '',
                    'file_name' => "subscription_" . ($i + 1) . ".yaml"
                ];
            }
        }
        return $data;
    }
    return [];
}

function formatBytes($bytes, $precision = 2) {
    if ($bytes === INF || $bytes === "∞") return "∞";
    if ($bytes <= 0) return "0 B";
    $units = ['B', 'KB', 'MB', 'GB', 'TB'];
    $pow = floor(log($bytes, 1024));
    $pow = min($pow, count($units) - 1);
    $bytes /= pow(1024, $pow);
    return round($bytes, $precision) . ' ' . $units[$pow];
}

function getSubInfo($subUrl, $userAgent = "Clash") {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $subUrl);
    curl_setopt($ch, CURLOPT_NOBODY, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HEADER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_USERAGENT, $userAgent);

    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($http_code !== 200 || !$response) {
        return [
            "http_code" => $http_code,
            "sub_info" => "Request Failed",
            "get_time" => time()
        ];
    }

    if (!preg_match("/subscription-userinfo: (.*)/i", $response, $matches)) {
        return [
            "http_code" => $http_code,
            "sub_info" => "No Sub Info Found",
            "get_time" => time()
        ];
    }

    $info = $matches[1];
    preg_match("/upload=(\d+)/", $info, $m);   $upload   = isset($m[1]) ? (int)$m[1] : 0;
    preg_match("/download=(\d+)/", $info, $m); $download = isset($m[1]) ? (int)$m[1] : 0;
    preg_match("/total=(\d+)/", $info, $m);    $total    = isset($m[1]) ? (int)$m[1] : 0;
    preg_match("/expire=(\d+)/", $info, $m);   $expire   = isset($m[1]) ? (int)$m[1] : 0;

    $used = $upload + $download;
    $surplus = ($total > 0) ? $total - $used : INF;
    $percent = ($total > 0) ? (($total - $used) / $total) * 100 : 100;

    $expireDate = "null";
    $day_left = "null";
    if ($expire > 0) {
        $expireDate = date("Y-m-d H:i:s", $expire);
        $day_left = $expire > time() ? ceil(($expire - time()) / (3600*24)) : 0;
    } elseif ($expire === 0) {
        $expireDate = "Long-term";
        $day_left = "∞";
    }

    return [
        "http_code" => $http_code,
        "sub_info" => "Successful",
        "upload" => $upload,
        "download" => $download,
        "used" => $used,
        "total" => $total > 0 ? $total : "∞",
        "surplus" => $surplus,
        "percent" => round($percent, 1),
        "day_left" => $day_left,
        "expire" => $expireDate,
        "get_time" => time()
    ];
}

function saveSubInfoToFile($index, $subInfo) {
    $libDir = __DIR__ . '/lib';
    if (!is_dir($libDir)) mkdir($libDir, 0755, true);
    $filePath = $libDir . '/sub_info_' . $index . '.json';
    file_put_contents($filePath, json_encode($subInfo));
}

function getSubInfoFromFile($index) {
    $filePath = __DIR__ . '/lib/sub_info_' . $index . '.json';
    if (file_exists($filePath)) {
        return json_decode(file_get_contents($filePath), true);
    }
    return null;
}

function clearSubInfo($index) {
    $filePath = __DIR__ . '/lib/sub_info_' . $index . '.json';
    if (file_exists($filePath)) {
        unlink($filePath);
        return true;
    }
    return false;
}

$subscriptions = getSubscriptionsFromFile();

function autoCleanInvalidSubInfo($subscriptions) {
    $maxSubscriptions = 6;
    $cleaned = 0;
    
    for ($i = 0; $i < $maxSubscriptions; $i++) {
        $url = trim($subscriptions[$i]['url'] ?? '');
        
        if (empty($url)) {
            if (clearSubInfo($i)) {
                $cleaned++;
            }
        }
    }
    
    return $cleaned;
}

function isValidSubscriptionContent($content) {
    $keywords = ['ss', 'shadowsocks', 'vmess', 'vless', 'trojan', 'hysteria2', 'socks5', 'http'];
    foreach ($keywords as $keyword) {
        if (stripos($content, $keyword) !== false) {
            return true;
        }
    }
    return false;
}

autoCleanInvalidSubInfo($subscriptions);

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['update'])) {
    $index = intval($_POST['index']);
    $url = trim($_POST['subscription_url'] ?? '');
    $customFileName = trim($_POST['custom_file_name'] ?? "subscription_" . ($index + 1) . ".yaml");

    $subscriptions[$index]['url'] = $url;
    $subscriptions[$index]['file_name'] = $customFileName;

    if (!empty($url)) {
        $tempPath = $subscriptionPath . $customFileName . ".temp";
        $finalPath = $subscriptionPath . $customFileName;

        $command = "curl -s -L -o {$tempPath} " . escapeshellarg($url);
        exec($command . ' 2>&1', $output, $return_var);

        if ($return_var !== 0) {
            $command = "wget -q --show-progress -O {$tempPath} " . escapeshellarg($url);
            exec($command . ' 2>&1', $output, $return_var);
        }

        if ($return_var === 0 && file_exists($tempPath)) {
            //echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="subscription_downloaded" data-dynamic-content="' . htmlspecialchars($url) . '"></span></div>';
            
            $fileContent = file_get_contents($tempPath);

            if (base64_encode(base64_decode($fileContent, true)) === $fileContent) {
                $decodedContent = base64_decode($fileContent);
                if ($decodedContent !== false && strlen($decodedContent) > 0 && isValidSubscriptionContent($decodedContent)) {
                    file_put_contents($finalPath, "# Clash Meta Config\n\n" . $decodedContent);
                    echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="base64_decode_success" data-dynamic-content="' . htmlspecialchars($finalPath) . '"></span></div>';
                    $notificationMessage = '<span data-translate="update_success"></span>';
                    $updateCompleted = true;
                } else {
                    echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="base64_decode_failed"></span></div>';
                    $notificationMessage = '<span data-translate="update_failed"></span>';
                }
            } 
            elseif (substr($fileContent, 0, 2) === "\x1f\x8b") {
                $decompressedContent = gzdecode($fileContent);
                if ($decompressedContent !== false && isValidSubscriptionContent($decompressedContent)) {
                    file_put_contents($finalPath, "# Clash Meta Config\n\n" . $decompressedContent);
                    echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="gzip_decompress_success" data-dynamic-content="' . htmlspecialchars($finalPath) . '"></span></div>';
                    $notificationMessage = '<span data-translate="update_success"></span>';
                    $updateCompleted = true;
                } else {
                    echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="gzip_decompress_failed"></span></div>';
                    $notificationMessage = '<span data-translate="update_failed"></span>';
                }
            } 
            else {
                if (isValidSubscriptionContent($fileContent) && rename($tempPath, $finalPath)) {
                    echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="subscription_downloaded_no_decode"></span></div>';
                    $notificationMessage = '<span data-translate="update_success"></span>';
                    $updateCompleted = true;
                } else {
                    echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="subscription_update_failed" data-dynamic-content="' . htmlspecialchars(implode("\n", $output)) . '"></span></div>';
                    $notificationMessage = '<span data-translate="update_failed"></span>';
                }
            }
            
            $userAgents = ["Clash","clash","ClashVerge","Stash","NekoBox","Quantumult%20X","Surge","Shadowrocket","V2rayU","Sub-Store","Mozilla/5.0"];
            $subInfo = null;
            foreach ($userAgents as $ua) {
                $subInfo = getSubInfo($url, $ua);
                if ($subInfo['sub_info'] === "Successful") break;
            }
            if ($subInfo) {
                saveSubInfoToFile($index, $subInfo);
            }
            
            if (file_exists($tempPath)) {
                unlink($tempPath);
            }
        } else {
            echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="subscription_update_failed" data-dynamic-content="' . htmlspecialchars(implode("\n", $output)) . '"></span></div>';
            $notificationMessage = '<span data-translate="update_failed"></span>';
            if (file_exists($tempPath)) {
                unlink($tempPath);
            }
        }
    } else {
        clearSubInfo($index);
        $notificationMessage = '<span data-translate="update_failed"></span>';
    }

    file_put_contents($JSON_FILE, json_encode($subscriptions, JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['updateAll'])) {
    $updated = 0;
    $failed = 0;
    
    for ($i = 0; $i < 6; $i++) {
        $url = trim($subscriptions[$i]['url'] ?? '');
        $customFileName = trim($subscriptions[$i]['file_name'] ?? "subscription_" . ($i + 1) . ".yaml");
        
        if (!empty($url)) {
            $tempPath = $subscriptionPath . $customFileName . ".temp";
            $finalPath = $subscriptionPath . $customFileName;

            $command = "curl -s -L -o {$tempPath} " . escapeshellarg($url);
            exec($command . ' 2>&1', $output, $return_var);

            if ($return_var !== 0) {
                $command = "wget -q --show-progress -O {$tempPath} " . escapeshellarg($url);
                exec($command . ' 2>&1', $output, $return_var);
            }

            if ($return_var === 0 && file_exists($tempPath)) {
                $fileContent = file_get_contents($tempPath);
                $success = false;
                
                if (base64_encode(base64_decode($fileContent, true)) === $fileContent) {
                    $decodedContent = base64_decode($fileContent);
                    if ($decodedContent !== false && strlen($decodedContent) > 0 && isValidSubscriptionContent($decodedContent)) {
                        file_put_contents($finalPath, "# Clash Meta Config\n\n" . $decodedContent);
                        $success = true;
                    }
                } 
                elseif (substr($fileContent, 0, 2) === "\x1f\x8b") {
                    $decompressedContent = gzdecode($fileContent);
                    if ($decompressedContent !== false && isValidSubscriptionContent($decompressedContent)) {
                        file_put_contents($finalPath, "# Clash Meta Config\n\n" . $decompressedContent);
                        $success = true;
                    }
                } 
                else {
                    if (isValidSubscriptionContent($fileContent) && rename($tempPath, $finalPath)) {
                        $success = true;
                    }
                }
                
                if ($success) {
                    $updated++;
                    echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="subscription_updated_success" data-index="' . ($i + 1) . '"></span></div>';
                    
                    $userAgents = ["Clash","clash","ClashVerge","Stash","NekoBox","Quantumult%20X","Surge","Shadowrocket","V2rayU","Sub-Store","Mozilla/5.0"];
                    $subInfo = null;
                    foreach ($userAgents as $ua) {
                        $subInfo = getSubInfo($url, $ua);
                        if ($subInfo['sub_info'] === "Successful") break;
                    }
                    if ($subInfo) {
                        saveSubInfoToFile($i, $subInfo);
                    }
                } else {
                    $failed++;
                    echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="subscription_updated_failed" data-index="' . ($i + 1) . '"></span></div>';
                }
                
                if (file_exists($tempPath)) {
                    unlink($tempPath);
                }
            } else {
                $failed++;
                echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="subscription_updated_failed" data-index="' . ($i + 1) . '"></span></div>';
                if (file_exists($tempPath)) {
                    unlink($tempPath);
                }
            }
        }
    }
    
    if ($updated > 0) {
        $notificationMessage = '<span data-translate="update_all_success" data-count="' . $updated . '"></span>';
        $updateCompleted = true;
    } else {
        $notificationMessage = '<span data-translate="update_all_failed"></span>';
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['clear'])) {
    $index = $_POST['index'] ?? 0;
    clearSubInfo($index);
    header('Location: ' . $_SERVER['PHP_SELF']);
    exit;
}
?>
<?php
$shellScriptPath = '/etc/neko/core/update_mihomo.sh';
$LOG_FILE = '/etc/neko/tmp/log.txt'; 
$JSON_FILE = '/etc/neko/proxy_provider/subscriptions.json';
$SAVE_DIR = '/etc/neko/proxy_provider';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['createShellScript'])) {
        $shellScriptContent = <<<EOL
#!/bin/bash

LOG_FILE="/etc/neko/tmp/log.txt"
JSON_FILE="/etc/neko/proxy_provider/subscriptions.json"
SAVE_DIR="/etc/neko/proxy_provider"

log() {
    echo "$(date '+[ %H:%M:%S ]') \$1" >> "\$LOG_FILE"
}

log "Starting subscription update task..."

if [ ! -f "\$JSON_FILE" ]; then
    log "❌ Error: JSON file does not exist: \$JSON_FILE"
    exit 1
fi

jq -c '.[]' "\$JSON_FILE" | while read -r ITEM; do
    URL=\$(echo "\$ITEM" | jq -r '.url')         
    FILE_NAME=\$(echo "\$ITEM" | jq -r '.file_name')  

    if [ -z "\$URL" ] || [ "\$URL" == "null" ]; then
        log "⚠️ Skipping empty subscription URL, file name: \$FILE_NAME"
        continue
    fi

    if [ -z "\$FILE_NAME" ] || [ "\$FILE_NAME" == "null" ]; then
        log "❌ Error: File name is empty, skipping this URL: \$URL"
        continue
    fi

    SAVE_PATH="\$SAVE_DIR/\$FILE_NAME"
    TEMP_PATH="\$SAVE_PATH.temp"  

    log "🔄 Downloading: \$URL to temporary file: \$TEMP_PATH"

    curl -s -L -o "\$TEMP_PATH" "\$URL"

    if [ \$? -ne 0 ]; then
        wget -q -O "\$TEMP_PATH" "\$URL"
    fi

    if [ \$? -eq 0 ]; then
        log "✅ File downloaded successfully: \$TEMP_PATH"

        if base64 -d "\$TEMP_PATH" > /dev/null 2>&1; then
            base64 -d "\$TEMP_PATH" > "\$SAVE_PATH"
            if [ \$? -eq 0 ]; then
                log "📂 Base64 decoding successful, configuration saved: \$SAVE_PATH"
                rm -f "\$TEMP_PATH"
            else
                log "⚠️ Base64 decoding failed: \$SAVE_PATH"
                rm -f "\$TEMP_PATH"
            fi
        elif file "\$TEMP_PATH" | grep -q "gzip compressed"; then
            gunzip -c "\$TEMP_PATH" > "\$SAVE_PATH"
            if [ \$? -eq 0 ]; then
                log "📂 Gzip decompression successful, configuration saved: \$SAVE_PATH"
                rm -f "\$TEMP_PATH"
            else
                log "⚠️ Gzip decompression failed: \$SAVE_PATH"
                rm -f "\$TEMP_PATH"
            fi
        else
            mv "\$TEMP_PATH" "\$SAVE_PATH"
            log "✅ Subscription content successfully downloaded, no decoding required"
        fi
    else
        log "❌ Subscription update failed: \$URL"
        rm -f "\$TEMP_PATH"
    fi
done

log "🚀 All subscription links updated successfully！"
EOL;

        if (file_put_contents($shellScriptPath, $shellScriptContent) !== false) {
            chmod($shellScriptPath, 0755); 
            echo "<div class='log-message alert alert-success'><span data-translate='shell_script_created' data-dynamic-content='$shellScriptPath'></span></div>";
        } else {
            echo "<div class='log-message alert alert-danger'><span data-translate='shell_script_failed'></span></div>";
        }
    }
}
?>

<?php
$CRON_LOG_FILE = '/etc/neko/tmp/log.txt'; 

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['createCronJob'])) {
        $cronExpression = trim($_POST['cronExpression']);

        if (empty($cronExpression)) {
            file_put_contents($CRON_LOG_FILE, date('[ H:i:s ] ') . "Error: Cron expression cannot be empty.\n", FILE_APPEND);
            echo "<div class='log-message alert alert-warning' data-translate='cron_expression_empty'></div>";
            exit;
        }

        $cronJob = "$cronExpression /etc/neko/core/update_mihomo.sh";

        exec("crontab -l | grep -v '/etc/neko/core/update_mihomo.sh' | crontab -", $output, $returnVarRemove);
        if ($returnVarRemove === 0) {
            file_put_contents($CRON_LOG_FILE, date('[ H:i:s ] ') . "Successfully removed old Cron job.\n", FILE_APPEND);
        } else {
            file_put_contents($CRON_LOG_FILE, date('[ H:i:s ] ') . "Failed to remove old Cron job.\n", FILE_APPEND);
        }

        exec("(crontab -l; echo '$cronJob') | crontab -", $output, $returnVarAdd);
        if ($returnVarAdd === 0) {
            file_put_contents($CRON_LOG_FILE, date('[ H:i:s ] ') . "Successfully added new Cron job: $cronJob\n", FILE_APPEND);
            echo "<div class='log-message alert alert-success' data-translate='cron_job_added_success'></div>";
        } else {
            file_put_contents($CRON_LOG_FILE, date('[ H:i:s ] ') . "Failed to add new Cron job.\n", FILE_APPEND);
            echo "<div class='log-message alert alert-danger' data-translate='cron_job_added_failed'></div>";
        }
    }
}
?>

<?php
$file_urls = [
    'geoip' => 'https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.metadb',
    'geosite' => 'https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat',
    'cache' => 'https://github.com/Thaolga/neko/raw/main/cache.db' 
];

$download_directories = [
    'geoip' => '/etc/neko/',
    'geosite' => '/etc/neko/',
    'cache' => '/www/nekobox/' 
];

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['file'])) {
    $file = $_GET['file'];

    if (isset($file_urls[$file])) {
        $file_url = $file_urls[$file];
        $destination_directory = $download_directories[$file];
        $destination_path = $destination_directory . basename($file_url);

        if (download_file($file_url, $destination_path)) {
            echo "<div class='log-message alert alert-success' data-translate='file_download_success' data-dynamic-content='$destination_path'></div>";
        } else {
            echo "<div class='log-message alert alert-danger' data-translate='file_download_failed'></div>";
        }
    } else {
        echo "<div class='log-message alert alert-warning' data-translate='invalid_file_request'></div>";
    }
}

function download_file($url, $destination) {
    $ch = curl_init($url);
    $fp = fopen($destination, 'wb');

    curl_setopt($ch, CURLOPT_FILE, $fp);
    curl_setopt($ch, CURLOPT_HEADER, 0);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);

    $result = curl_exec($ch);
    curl_close($ch);
    fclose($fp);

    return $result !== false;
}
?>

<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['clearJsonFile'])) {
    $fileToClear = $_POST['clearJsonFile'];
    if ($fileToClear === 'subscriptions.json') {
        $filePath = '/etc/neko/proxy_provider/subscriptions.json';
        if (file_exists($filePath)) {
            file_put_contents($filePath, '[]');
            echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="subscriptionClearedSuccess">Subscription information cleared successfully</span></div>';
        }
    }
}
?>

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Mihomo - NekoBox</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <script src="./assets/bootstrap/beautify.min.js"></script> 
    <script src="./assets/bootstrap/js-yaml.min.js"></script>
    <script src="./assets/bootstrap/jquery.min.js"></script>
    <?php include './ping.php'; ?>
</head>
<style>
.custom-alert-success {
    background-color: #d4edda !important;
    border-color: #c3e6cb !important;
    color: #155724 !important;
}

#updateNotification {
    background: linear-gradient(135deg, #1e3a8a, #2563eb);
    color: #fff;
    border: none;
    border-radius: 0.5rem;
    padding: 1rem;
    position: relative;
}

#updateNotification .alert-info {
    background: rgba(255, 255, 255, 0.1);
    color: #fff;
    border: none;
}

#updateNotification .spinner-border {
    filter: invert(1);
}

#dropZone i {
    font-size: 50px;
    color: #007bff;
    animation: iconPulse 1.5s infinite; 
}

@keyframes iconPulse {
    0% {
        transform: scale(1);
        opacity: 1;
    }
    50% {
        transform: scale(1.2); 
        opacity: 0.7;
    }
    100% {
        transform: scale(1);
        opacity: 1;
    }
}

.table-hover tbody tr:hover td {
    color: #cc0fa9;
}

.node-count-badge {
    position: absolute;
    top: 1.4rem;
    right: 0.9rem;
    background-color: var(--accent-color);
    color: #fff;
    padding: 0.2rem 0.5rem;
    border-radius: 0.5rem;
    font-size: 0.75rem;
    font-weight: bold;
    z-index: 10;
}
</style>
<?php if ($updateCompleted): ?>
    <script>
        if (!sessionStorage.getItem('refreshed')) {
            sessionStorage.setItem('refreshed', 'true');
            window.location.reload(); 
        } else {
            sessionStorage.removeItem('refreshed'); 
        }
    </script>
<?php endif; ?>
<body>
<div class="position-fixed w-100 d-flex flex-column align-items-center" style="top: 20px; z-index: 1050;">
    <div id="updateNotification" class="alert alert-info alert-dismissible fade show shadow-lg" role="alert" style="display: none; min-width: 320px; max-width: 600px; opacity: 0.95;">
        <div class="d-flex align-items-center">
            <div class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></div>
            <strong data-translate="update_notification"></strong>
        </div>
        
        <div class="alert alert-info mt-2 p-2 small">
            <strong data-translate="usage_instruction"></strong>
            <ul class="mb-0 pl-3">
                <li data-translate="max_subscriptions"></li>
                <li data-translate="no_rename"></li>
                <li data-translate="supports_all_formats"></li>
            </ul>
        </div>

        <div id="updateLogContainer" class="small mt-2"></div>

    </div>
</div>

<script>
function displayUpdateNotification() {
    const notification = $('#updateNotification');
    const updateLogs = <?php echo json_encode($_SESSION['update_logs'] ?? []); ?>;
    
    if (updateLogs.length > 0) {
        const logsHtml = updateLogs.map(log => `<div>${log}</div>`).join('');
        $('#updateLogContainer').html(logsHtml);
    }
    
    notification.fadeIn().addClass('show');
    
    setTimeout(function() {
        notification.fadeOut(300, function() {
            notification.hide();
            $('#updateLogContainer').html('');
        });
    }, 5000);
}

$(document).ready(function() {
    const notificationMessageExists = <?php echo json_encode(!empty($notificationMessage)); ?>;

    if (notificationMessageExists) {
        const lastNotificationTime = localStorage.getItem('lastUpdateNotificationTime');
        const now = Date.now();
        const twentyFourHours = 24 * 60 * 60 * 1000;

        if (!lastNotificationTime || now - parseInt(lastNotificationTime, 10) > twentyFourHours) {
            displayUpdateNotification();
            localStorage.setItem('lastUpdateNotificationTime', now.toString());
        }
    }
});
</script>
<div class="container-sm container-bg px-0 px-sm-4 mt-4">
<nav class="navbar navbar-expand-lg sticky-top">
    <div class="container-sm container px-4 px-sm-3 px-md-4">
        <a class="navbar-brand d-flex align-items-center" href="#">
            <?= $iconHtml ?>
            <span style="color: var(--accent-color); letter-spacing: 1px;"><?= htmlspecialchars($title) ?></span>
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarContent">
            <i class="bi bi-list" style="color: var(--accent-color); font-size: 1.8rem;"></i>
        </button>
        <div class="collapse navbar-collapse" id="navbarContent">
            <ul class="navbar-nav me-auto mb-2 mb-lg-0" style="font-size: 18px;">
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'index.php' ? 'active' : '' ?>" href="./index.php"><i class="bi bi-house-door"></i> <span data-translate="home">Home</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'mihomo_manager.php' ? 'active' : '' ?>" href="./mihomo_manager.php"><i class="bi bi-folder"></i> <span data-translate="manager">Manager</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'singbox.php' ? 'active' : '' ?>" href="./singbox.php"><i class="bi bi-shop"></i> <span data-translate="template_i">Template I</span></a>
                </li>
                <li class="nav-item d-none">
                    <a class="nav-link <?= $current == 'subscription.php' ? 'active' : '' ?>" href="./subscription.php"><i class="bi bi-bank"></i> <span data-translate="template_ii">Template II</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'mihomo.php' ? 'active' : '' ?>" href="./mihomo.php"><i class="bi bi-building"></i> <span data-translate="template_iii">Template III</span></a>
                </li>
                <li class="nav-item d-none">
                    <a class="nav-link <?= $current == 'netmon.php' ? 'active' : '' ?>" href="./netmon.php"><i class="bi bi-activity"></i> <span data-translate="traffic_monitor">Traffic Monitor</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'monaco.php' ? 'active' : '' ?>" href="./monaco.php"><i class="bi bi-bank"></i> <span data-translate="pageTitle">File Assistant</span></a>
                </li>
            </ul>
            <div class="d-flex align-items-center">
                <div class="me-3 d-block">
                    <button type="button" class="btn btn-primary icon-btn me-2" onclick="toggleControlPanel()" data-tooltip="control_panel"><i class="bi bi-gear"> </i></button>
                    <button type="button" class="btn btn-danger icon-btn me-2" data-bs-toggle="modal" data-bs-target="#langModal" data-tooltip="set_language"><i class="bi bi-translate"></i></button>
                    <button type="button" class="btn btn-success icon-btn me-2" data-bs-toggle="modal" data-bs-target="#musicModal" data-tooltip="music_player"><i class="bi bi-music-note-beamed"></i></button>
                    <button type="button" id="toggleIpStatusBtn" class="btn btn-warning icon-btn me-2" onclick="toggleIpStatusBar()" data-tooltip="hide_ip_info"><i class="bi bi-eye-slash"> </i></button>
                    <button type="button" class="btn btn-pink icon-btn me-2" data-bs-toggle="modal" data-bs-target="#portModal" data-tooltip="viewPortInfoButton"><i class="bi bi-plug"></i></button>
                    <button type="button" class="btn-refresh-page btn btn-orange icon-btn me-2 d-none d-sm-inline"><i class="fas fa-sync-alt"></i></button>
                    <button type="button" class="btn btn-info icon-btn me-2" onclick="document.getElementById('colorPicker').click()" data-tooltip="component_bg_color"><i class="bi bi-palette"></i></button>
                    <input type="color" id="colorPicker" value="#0f3460" style="display: none;">
            </div>
        </div>
    </div>
</nav>

<style>
.card {
    position: relative;
}

.sub-info {
    display: none;
    position: absolute;
    bottom: 0;
    left: 0;
    width: 100%;
    background: var(--accent-color);
    color: #fff;
    padding: 5px 10px;
    border-top: 1px solid #ccc;
    box-shadow: 0 2px 6px rgba(0,0,0,0.2);
    white-space: nowrap;
    z-index: 10;
}

.card:hover .sub-info {
    display: block;
}

.update-indicator {
    position: absolute;
    top: 15px;
    right: 15px;
    width: 12px;
    height: 12px;
    border-radius: 50%;
    background: #28a745;
    animation: pulse-success 2s infinite;
    box-shadow: 0 0 0 0 rgba(40, 167, 69, 0.7);
    transition: all 0.3s ease;
}

.update-indicator.failed {
    background: #dc3545;
    animation: pulse-error 2s infinite;
    box-shadow: 0 0 0 0 rgba(220, 53, 69, 0.7);
}

.update-indicator:hover {
    transform: scale(1.2);
}

@keyframes pulse-success {
    0% {
        transform: scale(0.95);
        box-shadow: 0 0 0 0 rgba(40, 167, 69, 0.7);
    }
    
    50% {
        transform: scale(1);
        box-shadow: 0 0 0 8px rgba(40, 167, 69, 0);
    }
    
    100% {
        transform: scale(0.95);
        box-shadow: 0 0 0 0 rgba(40, 167, 69, 0);
    }
}

@keyframes pulse-error {
    0% {
        transform: scale(0.95);
        box-shadow: 0 0 0 0 rgba(220, 53, 69, 0.7);
    }
    
    50% {
        transform: scale(1);
        box-shadow: 0 0 0 8px rgba(220, 53, 69, 0);
    }
    
    100% {
        transform: scale(0.95);
        box-shadow: 0 0 0 0 rgba(220, 53, 69, 0);
    }
}

.clear-json-btn {
    padding: 0.25rem 0.5rem;
    font-size: 0.95rem;
    min-height: 1.5em;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: #dc3545;
    color: #fff;
    border: none;
    border-radius: 0.5rem;
    z-index: 11;
    line-height: 1;
}

.clear-json-btn i {
    display: block;
    font-size: inherit;
    line-height: 1;
}

.clear-json-btn:hover {
    background-color: #c82333;
}

@media (max-width: 768px) {
    .clear-json-btn {
        padding: 0.5rem 1.1rem;
        font-size: 1.1rem;
        min-height: 1.8em;
    }
}
</style>

<h2 class="container-fluid text-center mt-4 mb-4" data-translate="subscriptionManagement"></h2>

<div class="text-center mt-4 mb-1">
    <form method="post">
        <button type="button" class="btn btn-primary mx-1 mb-2" data-bs-toggle="modal" data-bs-target="#cronModal">
            <i class="bi bi-clock"></i> <span data-translate="set_cron_job"></span>
        </button>
        
        <button type="submit" name="createShellScript" value="true" class="btn btn-success mx-1 mb-2">
            <i class="bi bi-terminal"></i> <span data-translate="generate_update_script"></span>
        </button>
        
        <button type="submit" name="updateAll" value="true" class="btn btn-warning mx-1 mb-2">
            <i class="bi bi-arrow-repeat"></i> <span data-translate="update_all_subscriptions"></span>
        </button>
        
        <button type="button" class="btn btn-info mx-1 mb-2" data-bs-toggle="modal" data-bs-target="#downloadModal">
            <i class="bi bi-download"></i> <span data-translate="update_database"></span>
        </button>
    </form>
</div>

<div class="container-sm text-center px-2 px-md-3">
    <?php if (isset($subscriptions) && is_array($subscriptions)): ?>
        <div class="container-fluid px-3">
            <?php 
            $maxSubscriptions = 6;
            for ($i = 0; $i < $maxSubscriptions; $i++):
                $displayIndex = $i + 1;
                $url = $subscriptions[$i]['url'] ?? '';
                $fileName = $subscriptions[$i]['file_name'] ?? "subscription_" . $displayIndex . ".yaml";

                $subInfo = getSubInfoFromFile($i);

                if ($i % 3 == 0) echo '<div class="row">';
            ?>
                <div class="col-md-4 mb-3 px-1">
                    <div class="card">
                        <?php if (!empty($url)): ?>
                            <div class="update-indicator <?php 
                                if (empty($subInfo)) echo 'failed';
                            ?>" title="<?php 
                                if (empty($subInfo)) {
                                    echo htmlspecialchars($translations['noSubInfo'] ?? 'No subscription information obtained');
                                } else {
                                    echo htmlspecialchars($translations['subInfoObtained'] ?? 'Subscription information obtained');
                                }
                            ?>"></div>
                        <?php endif; ?>
                        
                        <form method="post">
                            <div class="card-body">
                                <div class="form-group">
                                    <h5 class="mb-2" data-translate="subscriptionLink"><?php echo $displayIndex; ?></h5>
                                    <input type="text" name="subscription_url" id="subscription_url_<?php echo $displayIndex; ?>" value="<?php echo htmlspecialchars($url); ?>" class="form-control" data-translate-placeholder="enterSubscriptionUrl">
                                </div>

                                <div class="form-group">
                                    <label for="custom_file_name_<?php echo $displayIndex; ?>" data-translate="customFileName"></label>
                                    <input type="text" name="custom_file_name" id="custom_file_name_<?php echo $displayIndex; ?>" value="<?php echo htmlspecialchars($fileName); ?>" class="form-control">
                                </div>

                                <input type="hidden" name="index" value="<?php echo $i; ?>">

                                <?php if (!empty($subInfo) && $subInfo['sub_info'] === "Successful"): ?>
                                    <div class="sub-info">
                                        <?php
                                        $total   = formatBytes($subInfo['total']);
                                        $used    = formatBytes($subInfo['used']);
                                        $percent = $subInfo['percent'];
                                        $dayLeft = $subInfo['day_left'];
                                        $expire  = $subInfo['expire'];
                                        $remainingLabel = $translations['resetDaysLeftLabel'] ?? 'Remaining';
                                        $daysUnit       = $translations['daysUnit'] ?? 'days';
                                        $expireLabel    = $translations['expireDateLabel'] ?? 'Expires';
                                        echo "{$used} / {$total} ({$percent}%) • {$remainingLabel} {$dayLeft} {$daysUnit} • {$expireLabel}: {$expire}";
                                        ?>
                                    </div>
                                <?php elseif (!empty($subInfo)): ?>
                                    <div class="sub-info">
                                        <span data-translate="subscriptionFetchFailed"></span>: <?php echo htmlspecialchars($subInfo['sub_info']); ?>
                                    </div>
                                <?php endif; ?>

                                <div class="text-center mt-3">
                                    <button type="submit" name="update" class="btn btn-primary btn-block">
                                        <i class="bi bi-arrow-repeat"></i> 
                                        <span data-translate="updateSubscription">Settings</span> <?php echo $displayIndex; ?>
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            <?php 
                if ($i % 3 == 2 || $i == $maxSubscriptions - 1) echo '</div>';
            endfor; ?>
        </div>
    <?php endif; ?>
</div>

<h2 class="text-center mt-3 mb-4" data-translate="fileManagement">File Management</h2>

<div class="container-sm px-3 px-md-4">
  <div class="row g-3">
    <?php
    $proxyFiles = $proxyFiles ?? [];
    $configFiles = $configFiles ?? [];
    $uploadDir = $uploadDir ?? '';
    $configDir = $configDir ?? '';
    $langData = $langData ?? [];
    $currentLang = $currentLang ?? 'en';
    $translations = $translations ?? [];

    $allFiles = array_merge($proxyFiles, $configFiles);
    $allFilePaths = array_merge(
      array_map(fn($file) => $uploadDir . $file, $proxyFiles),
      array_map(fn($file) => $configDir . $file, $configFiles)
    );

    $fileTypes = array_merge(
      array_fill(0, count($proxyFiles), $langData[$currentLang]['file_type_proxy'] ?? 'Proxy'),
      array_fill(0, count($configFiles), $langData[$currentLang]['file_type_config'] ?? 'Config')
    );

    foreach ($allFiles as $index => $file):
      $filePath = $allFilePaths[$index];
      $isProxy = ($index < count($proxyFiles));
      $size = file_exists($filePath) ? formatSize(filesize($filePath)) : ($translations['fileNotExist'] ?? 'Not Exist');
      $modified = file_exists($filePath) ? date('Y-m-d H:i:s', filemtime($filePath)) : '-';

      $validProtocols = '/^(ss|shadowsocks|vmess|vless|trojan|hysteria2|socks5|http)$/i';
      $nodeCount = 0;

      if (file_exists($filePath)) {
          $content = file_get_contents($filePath);

          $json = json_decode($content, true);
          if (json_last_error() === JSON_ERROR_NONE && isset($json['outbounds']) && is_array($json['outbounds'])) {
              foreach ($json['outbounds'] as $outbound) {
                  if (!empty($outbound['type']) && preg_match($validProtocols, $outbound['type'])) {
                      $nodeCount++;
                  }
              }
          } else {
              if (preg_match('/^\s*proxies\s*:/im', $content, $matches, PREG_OFFSET_CAPTURE)) {
                  $start = $matches[0][1] + strlen($matches[0][0]);
                  $rest = substr($content, $start);
                  $lines = preg_split("/\r?\n/", $rest);
            
                  $hasRealProxies = false;
                  foreach ($lines as $line) {
                      $line = trim($line);
                      if ($line === '' || str_starts_with($line, '#')) continue;
                
                      if (preg_match('/^\-\s*(\{|.*type.*:)/', $line)) {
                          $hasRealProxies = true;
                          break;
                      }
                  }
            
                  if (!$hasRealProxies) {
                      $nodeCount = 0;
                  } else {
                      foreach ($lines as $line) {
                          $line = trim($line);
                          if ($line === '' || str_starts_with($line, '#')) continue;
                    
                          if (preg_match('/^\-\s*\{.*\}$/', $line)) {
                              if (preg_match('/^\-\s*\{(.*)\}\s*$/', $line, $match)) {
                                  $objContent = $match[1];
                            
                                  $pairs = preg_split('/\s*,\s*/', $objContent);
                                  $typeFound = false;
                            
                                  foreach ($pairs as $pair) {
                                      if (preg_match('/^\s*(\w+)\s*:\s*(.+?)\s*$/', $pair, $kvMatch)) {
                                          $key = $kvMatch[1];
                                          $value = trim($kvMatch[2], " '\"");
                                     
                                          if ($key === 'type' && preg_match($validProtocols, $value)) {
                                              $nodeCount++;
                                              $typeFound = true;
                                              break;
                                          }
                                      }
                                  }
                            
                                  if (!$typeFound) {
                                      $objStr = '{' . $objContent . '}';
                                      $objStrClean = preg_replace("/(['\"])?([a-zA-Z0-9_]+)(['\"])?\s*:/", '"$2":', $objStr);
                                      $objStrClean = str_replace("'", '"', $objStrClean);
                                      $obj = json_decode($objStrClean, true);
                                      if (json_last_error() === JSON_ERROR_NONE && isset($obj['type']) && preg_match($validProtocols, $obj['type'])) {
                                          $nodeCount++;
                                      }
                                  }
                              }
                          } 
                          elseif (preg_match('/type\s*:\s*["\']?(\w+)["\']?/i', $line, $match)) {
                              if (preg_match($validProtocols, $match[1])) {
                                   $nodeCount++;
                              }
                          }
                      }
                  }
              }
              elseif (preg_match('/^(ss|vmess|vless|trojan|hysteria2|socks5|http):\/\//im', $content)) {
                  $lines = preg_split("/\r?\n/", $content);
                  foreach ($lines as $line) {
                      $line = trim($line);
                      if ($line === '' || str_starts_with($line, '#')) continue;
                      if (preg_match('/^(ss|vmess|vless|trojan|hysteria2|socks5|http):\/\//i', $line)) {
                          $nodeCount++;
                      }
                  }
              }
              else {
                  $nodeCount = 0;
              }
          }
      }
    ?>
    <div class="col-12 col-md-6 col-lg-3">
      <div class="card h-100 text-start position-relative">
        <?php if ($file === 'subscriptions.json'): ?>
        <form method="post" class="position-absolute m-0 p-0" 
              style="top: 1.4rem; right: 5.2rem;">
            <input type="hidden" name="clearJsonFile" value="<?= htmlspecialchars($file) ?>">
            <button type="submit" class="btn btn-sm btn-outline-danger clear-json-btn" 
                    onclick="return confirm('<?= htmlspecialchars($translations['confirmClearJson'] ?? 'Are you sure to clear all subscription links?') ?>');" 
                    data-tooltip="clearJsonTooltip">
              <i class="bi bi-trash"></i>
            </button>
        </form>
        <?php endif; ?>
        <span class="node-count-badge"><span class="node-number"><?= $nodeCount ?></span> <span data-translate="nodesLabel">Nodes</span></span>
        <div class="card-body d-flex flex-column justify-content-between">
          <h5 class="card-title mb-2" <?= $file === 'subscriptions.json' ? '' : 'data-tooltip="fileName"' ?>><?= htmlspecialchars($file) ?></h5>
          <p class="card-text mb-1"><strong data-translate="fileSize">Size</strong>: <?= $size ?></p>
          <p class="card-text mb-1"><strong data-translate="lastModified">Last Modified</strong>: <?= $modified ?></p>
          <p class="card-text mb-2"><strong data-translate="fileType">Type</strong>: <span class="badge <?= $isProxy ? 'bg-primary' : 'bg-success' ?>"><?= htmlspecialchars($fileTypes[$index]) ?></span></p>
          <?php
          $lines = file($filePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

          $flowLeft = '';
          $resetDaysLeft = '';
          $expireDateText = '';

          foreach ($lines as $line) {
              $line = trim($line);
              if (empty($line)) continue;

              if (preg_match('/訂閱資訊[:：]\s*([\d.]+)\s*(T|TB|G|GB|M|MB|K|KB)?(?:\s*\/\s*(?:剩餘|剩余)\s*(\d+)\s*天)?(?:\s*\/\s*(?:到期|expire)\s*(\d{4}-\d{2}-\d{2}))?/iu', $line, $matches)) {
                  if (!empty($matches[1])) {
                     $flowLeft = $matches[1] . strtoupper($matches[2] ?? 'MB');
                  }
                  if (isset($matches[3]) && $matches[3] !== '') {
                      $resetDaysLeft = $matches[3];
                  }
                  if (!empty($matches[4])) {
                      $expireDateText = $matches[4];
                  }
                  break;
              } elseif (preg_match('/#(.*)$/', $line, $matches)) {
                  $hashComment = urldecode(trim($matches[1]));

                  if (preg_match('/(?:剩余流量|流量)[:：]\s*([\d.]+)\s*(T|TB|G|GB|M|MB|K|KB)?(?:\s|$)/iu', $hashComment, $flowMatch)) {
                      $flowLeft = $flowMatch[1] . strtoupper($flowMatch[2] ?? 'MB');
                  }

                  if (preg_match('/(?:距离下次重置剩余|距离|重置)[:：]\s*(\d+)\s*天/u', $hashComment, $resetMatch)) {
                      $resetDaysLeft = $resetMatch[1];
                  }

                  if (preg_match('/(?:套餐到期|套餐|到期)[:：]\s*(\d{4}-\d{2}-\d{2})/u', $hashComment, $dateMatch)) {
                      $expireDateText = $dateMatch[1];
                  }
              }
          }

          if (empty($resetDaysLeft) && !empty($expireDateText)) {
              $currentDate = date('Y-m-d');
              $expireTimestamp = strtotime($expireDateText . ' 23:59:59');
              $currentTimestamp = strtotime($currentDate);
    
              if ($expireTimestamp !== false && $currentTimestamp !== false) {
                  $daysLeft = ceil(($expireTimestamp - $currentTimestamp) / (60 * 60 * 24));
                  $resetDaysLeft = (string)$daysLeft;
              }
          }

          $needMoreInfo = empty($flowLeft) || empty($resetDaysLeft) || empty($expireDateText);
          if ($needMoreInfo) {
              $fileContent = file_get_contents($filePath);
    
              $config = json_decode($fileContent, true);
    
              if (json_last_error() === JSON_ERROR_NONE && is_array($config)) {
                  if (isset($config['outbounds']) && is_array($config['outbounds'])) {
                      foreach ($config['outbounds'] as $outbound) {
                          if (isset($outbound['tag'])) {
                              $tag = $outbound['tag'];
                    
                              if (empty($flowLeft) && preg_match('/(?:剩余流量|剩余|流量)[:：]\s*([\d.]+)\s*(T|TB|G|GB|M|MB|K|KB)?/iu', $tag, $matches)) {
                                   $flowLeft = $matches[1] . strtoupper($matches[2] ?? 'MB');
                              }
                    
                              if (empty($resetDaysLeft) && preg_match('/(?:距离下次重置剩余|距离|重置)[:：]\s*(\d+)\s*天/u', $tag, $matches)) {
                                   $resetDaysLeft = $matches[1];
                              }
                    
                              if (empty($expireDateText) && preg_match('/(?:套餐到期|套餐|到期)[:：]\s*(\d{4}-\d{2}-\d{2})/u', $tag, $matches)) {
                                  $expireDateText = $matches[1];
                              }
                           }
                
                          if (!empty($flowLeft) && !empty($resetDaysLeft) && !empty($expireDateText)) {
                              break;
                          }
                      }
                  }
        
                  if (isset($config['tag'])) {
                      $tag = $config['tag'];
            
                      if (empty($flowLeft) && preg_match('/(?:剩余流量|剩余|流量)[:：]\s*([\d.]+)\s*(T|TB|G|GB|M|MB|K|KB)?/iu', $tag, $matches)) {
                           $flowLeft = $matches[1] . strtoupper($matches[2] ?? 'MB');
                      }
            
                      if (empty($resetDaysLeft) && preg_match('/(?:距离下次重置剩余|距离|重置)[:：]\s*(\d+)\s*天/u', $tag, $matches)) {
                          $resetDaysLeft = $matches[1];
                       }
            
                      if (empty($expireDateText) && preg_match('/(?:套餐到期|套餐|到期)[:：]\s*(\d{4}-\d{2}-\d{2})/u', $tag, $matches)) {
                           $expireDateText = $matches[1];
                      }
                  }
        
                  if (empty($resetDaysLeft) && !empty($expireDateText)) {
                      $currentDate = date('Y-m-d');
                      $expireTimestamp = strtotime($expireDateText . ' 23:59:59');
                      $currentTimestamp = strtotime($currentDate);
            
                      if ($expireTimestamp !== false && $currentTimestamp !== false) {
                          $daysLeft = floor(($expireTimestamp - $currentTimestamp) / (60 * 60 * 24));
                          $resetDaysLeft = (string)$daysLeft;
                      }
                  }
              }
          }

          if (empty($flowLeft)) {
              $flowLeft = '0MB';
          }
          if ($resetDaysLeft === '') {
              $resetDaysLeft = '0';
          }

          $hasFlow = ($flowLeft !== '0MB');
          $hasResetDays = ($resetDaysLeft !== '0');
          $hasExpireDate = !empty($expireDateText);

          if ($hasFlow || $hasResetDays || $hasExpireDate) {
              $infoParts = [];

              if ($flowLeft) {
                  $infoParts[] = $flowLeft;
              }

              if ($hasResetDays) {
                  $days = (int)$resetDaysLeft;
                  if ($days < 0) {
                      $infoParts[] = '<span style="color: red;">已过期 ' . abs($days) . ' 天</span>';
                  } else {
                      $infoParts[] = 
                          ($translations['resetDaysLeftLabel'] ?? 'Remaining') . ' ' 
                          . $resetDaysLeft . ' ' 
                          . ($translations['daysUnit'] ?? 'days');
                  }
              }

              if ($hasExpireDate) {
                  $currentDate = date('Y-m-d');
                  $isExpired = strtotime($expireDateText) < strtotime($currentDate);
                  $expireText = ($translations['expireDateLabel'] ?? 'Expires') . ' ' . $expireDateText;
                  if ($isExpired) {
                      $infoParts[] = '<span style="color: red;">' . $expireText . '</span>';
                  } else {
                      $infoParts[] = $expireText;
                  }
              }

              $infoText = implode(' / ', $infoParts);

              echo '<p class="card-text mb-2"><strong data-translate="subscriptionInfo">'
                  . ($translations['subscriptionInfo'] ?? 'Subscription Info')
                  . '</strong>: ' . $infoText . '</p>';
          }
          ?>
          <div class="icon-btn-group mt-2" style="gap:0.4rem; display:flex; flex-wrap: wrap;">
            <?php if ($isProxy): ?>
              <form method="post" class="d-inline m-0 p-0">
                <input type="hidden" name="deleteFile" value="<?= htmlspecialchars($file) ?>">
                <button type="submit" class="btn btn-danger icon-btn" onclick="return confirmDelete('<?= htmlspecialchars($file) ?>', event)" data-tooltip="delete"><i class="bi bi-trash"></i></button>
              </form>
              <button type="button" class="btn btn-success icon-btn" data-bs-toggle="modal" data-bs-target="#renameModal" data-filename="<?= htmlspecialchars($file) ?>" data-filetype="proxy" data-tooltip="rename"><i class="bi bi-pencil"></i></button>
              <button type="button" class="btn btn-warning icon-btn" onclick="openEditModal('<?= htmlspecialchars($file) ?>','proxy')" data-tooltip="edit"><i class="bi bi-pen"></i></button>
              <button type="button" class="btn btn-info icon-btn" onclick="openUploadModal('proxy')" data-tooltip="upload"><i class="bi bi-upload"></i></button>
              <form method="get" class="d-inline m-0 p-0 no-loader">
                <input type="hidden" name="downloadFile" value="<?= htmlspecialchars($file) ?>">
                <input type="hidden" name="fileType" value="proxy">
                <button type="submit" class="btn btn-primary icon-btn" data-tooltip="download"><i class="bi bi-download"></i></button>
              </form>
            <?php else: ?>
              <form method="post" class="d-inline m-0 p-0">
                <input type="hidden" name="deleteConfigFile" value="<?= htmlspecialchars($file) ?>">
                <button type="submit" class="btn btn-danger icon-btn" onclick="return confirmDelete('<?= htmlspecialchars($file) ?>', event)" data-tooltip="delete"><i class="bi bi-trash"></i></button>
              </form>
              <button type="button" class="btn btn-success icon-btn" data-bs-toggle="modal" data-bs-target="#renameModal" data-filename="<?= htmlspecialchars($file) ?>" data-filetype="config" data-tooltip="rename"><i class="bi bi-pencil"></i></button>
              <button type="button" class="btn btn-warning icon-btn" onclick="openEditModal('<?= htmlspecialchars($file) ?>','config')" data-tooltip="edit"><i class="bi bi-pen"></i></button>
              <button type="button" class="btn btn-info icon-btn" onclick="openUploadModal('config')" data-tooltip="upload"><i class="bi bi-upload"></i></button>
              <form method="get" class="d-inline m-0 p-0 no-loader">
                <input type="hidden" name="downloadFile" value="<?= htmlspecialchars($file) ?>">
                <input type="hidden" name="fileType" value="config">
                <button type="submit" class="btn btn-primary icon-btn" data-tooltip="download"><i class="bi bi-download"></i></button>
              </form>
            <?php endif; ?>
          </div>
        </div>
      </div>
    </div>
    <?php endforeach; ?>
  </div>
</div>

<footer class="text-center">
    <p><?php echo $footer ?></p>
</footer>

<div class="modal fade" id="uploadModal" tabindex="-1" aria-labelledby="uploadModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="uploadModalLabel" data-translate="uploadFile"></h5> 
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="close"> 
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <div id="dropZone" class="border border-primary rounded text-center py-4 position-relative">
                    <i class="fas fa-cloud-upload-alt"></i>
                    <p class="mb-0 mt-3" data-translate="dragOrClickToUpload"></p> 
                </div>
                <input type="file" id="fileInputModal" class="form-control mt-3" hidden>
                <button id="selectFileBtn" class="btn btn-primary btn-block mt-3 w-100" data-translate="selectFile"></button> 
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close"></button> 
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="renameModal" tabindex="-1" aria-labelledby="renameModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="renameModalLabel" data-translate="rename_file"></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form id="renameForm" action="" method="post">
                    <input type="hidden" name="oldFileName" id="oldFileName">
                    <input type="hidden" name="fileType" id="fileType">

                    <div class="mb-3">
                        <label for="newFileName" class="form-label" data-translate="new_file_name"></label>
                        <input type="text" class="form-control" id="newFileName" name="newFileName" required>
                    </div>
                </form>
            </div>
            <div class="modal-footer justify-content-end">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancel"></button>
                <button type="submit" form="renameForm" class="btn btn-primary" data-translate="save"></button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="editModal" tabindex="-1" aria-labelledby="editModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="editModalLabel"><?php echo $langData[$currentLang]['editFile']; ?>: <span id="editingFileName"></span></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form id="editForm" action="" method="post" onsubmit="syncEditorContent()">
                    <textarea name="saveContent" id="fileContent" class="form-control" style="height: 500px;"></textarea>
                    <input type="hidden" name="fileName" id="hiddenFileName">
                    <input type="hidden" name="fileType" id="hiddenFileType">
                </form>
            </div>
            <div class="modal-footer justify-content-end">
                <button type="button" class="btn btn-pink" onclick="openFullScreenEditor()" data-translate="advancedEdit"></button>
                <button type="submit" form="editForm" class="btn btn-primary" data-translate="save"></button>
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close"></button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="fullScreenEditorModal" tabindex="-1" role="dialog" aria-hidden="true" data-backdrop="static" data-keyboard="false">
    <div class="modal-dialog modal-fullscreen" role="document">
        <div class="modal-content" style="border: none;">
            <div class="modal-header d-flex justify-content-between align-items-center" style="border-bottom: none;">
                <div class="d-flex align-items-center">
                    <h5 class="modal-title mr-3" data-translate="advancedEditorTitle"></h5>
                    <select id="fontSize" onchange="changeFontSize()" class="form-select mx-1" style="width: auto; font-size: 0.8rem;">
                        <option value="18px">18px</option>
                        <option value="20px" selected>20px</option>
                        <option value="22px">22px</option>
                        <option value="24px">24px</option>
                        <option value="26px">26px</option>
                        <option value="28px">28px</option>
                        <option value="30px">30px</option>
                        <option value="32px">32px</option>
                        <option value="34px">34px</option>
                        <option value="36px">36px</option>
                        <option value="38px">38px</option>
                        <option value="40px">40px</option>
                    </select>

                    <select id="editorTheme" onchange="changeEditorTheme()" class="form-select mx-1" style="width: auto; font-size: 0.9rem;">
                        <option value="ace/theme/vibrant_ink">Vibrant Ink</option>
                        <option value="ace/theme/gob">Gob</option>
                        <option value="ace/theme/monokai">Monokai</option>
                        <option value="ace/theme/github">GitHub</option>
                        <option value="ace/theme/tomorrow">Tomorrow</option>
                        <option value="ace/theme/twilight">Twilight</option>
                        <option value="ace/theme/solarized_dark">Solarized Dark</option>
                        <option value="ace/theme/solarized_light">Solarized Light</option>
                        <option value="ace/theme/textmate">TextMate</option>
                        <option value="ace/theme/terminal">Terminal</option>
                        <option value="ace/theme/chrome">Chrome</option>
                        <option value="ace/theme/eclipse">Eclipse</option>
                        <option value="ace/theme/dreamweaver">Dreamweaver</option>
                        <option value="ace/theme/xcode">Xcode</option>
                        <option value="ace/theme/kuroir">Kuroir</option>
                        <option value="ace/theme/iplastic">Iplastic</option>
                        <option value="ace/theme/katzenmilch">KatzenMilch</option>
                        <option value="ace/theme/sqlserver">SQL Server</option>
                        <option value="ace/theme/ambiance">Ambiance</option>
                        <option value="ace/theme/chaos">Chaos</option>
                        <option value="ace/theme/clouds_midnight">Clouds Midnight</option>
                        <option value="ace/theme/cobalt">Cobalt</option>
                        <option value="ace/theme/gruvbox">Gruvbox</option>
                        <option value="ace/theme/idle_fingers">Idle Fingers</option>
                        <option value="ace/theme/kr_theme">krTheme</option>
                        <option value="ace/theme/merbivore">Merbivore</option>
                        <option value="ace/theme/mono_industrial">Mono Industrial</option>
                        <option value="ace/theme/pastel_on_dark">Pastel on Dark</option>
                    </select>

                    <button type="button" class="btn btn-success btn-sm mx-1" onclick="formatContent()" data-translate="formatIndentation"></button>
                    <button type="button" class="btn btn-success btn-sm mx-1" id="yamlFormatBtn" onclick="formatYamlContent()" style="display: none;" data-translate="formatYaml"></button>
                    <button type="button" class="btn btn-info btn-sm mx-1" id="jsonValidationBtn" onclick="validateJsonSyntax()" data-translate="validateJson"></button>
                    <button type="button" class="btn btn-info btn-sm mx-1" id="yamlValidationBtn" onclick="validateYamlSyntax()" style="display: none;" data-translate="validateYaml"></button>
                    <button type="button" class="btn btn-primary btn-sm mx-1" onclick="saveFullScreenContent()" data-translate="saveAndClose"></button>
                    <button type="button" class="btn btn-primary btn-sm mx-1" onclick="openSearch()" data-translate="search"></button>
                    <button type="button" class="btn btn-primary btn-sm mx-1" onclick="closeFullScreenEditor()" data-translate="cancel"></button>
                    <button type="button" class="btn btn-warning btn-sm mx-1" id="toggleFullscreenBtn" onclick="toggleFullscreen()" data-translate="toggleFullscreen"></button>
                </div>

                <button type="button" class="btn-close" data-dismiss="modal" aria-label="Close" onclick="closeFullScreenEditor()">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>

            <div class="d-flex justify-content-center align-items-center my-1" id="editorStatus" style="font-weight: bold; font-size: 0.9rem;">
                    <span id="lineColumnDisplay" style="color: blue; font-size: 1.1rem;" data-translate="lineColumnDisplay"></span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span id="charCountDisplay" style="color: blue; font-size: 1.1rem;" data-translate="charCountDisplay"></span>
                </div>
                    <div class="modal-body" style="padding: 0; height: 100%;">
                <div id="aceEditorContainer" style="height: 100%; width: 100%;"></div>
            </div>
        </div>
    </div>
</div>

<script>
let isJsonDetected = false;
let aceEditorInstance;
let aceLoaded = false;

function loadAceEditor() {
    return new Promise((resolve, reject) => {
        if (aceLoaded && window.ace) {
            resolve();
            return;
        }

        const aceScript = document.createElement('script');
        aceScript.src = 'https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/ace.js';
        
        aceScript.onload = () => {
            aceLoaded = true;
            resolve();
        };

        aceScript.onerror = () => {
            reject(new Error('Failed to load ACE Editor'));
        };

        document.head.appendChild(aceScript);
    });
}

async function initializeAceEditor() {
    if (!aceLoaded) {
        try {
            await loadAceEditor();
        } catch (error) {
            console.error('Failed to load ACE Editor:', error);
            return;
        }
    }

    aceEditorInstance = ace.edit("aceEditorContainer");
    const savedTheme = localStorage.getItem("editorTheme") || "ace/theme/vibrant_ink";
    aceEditorInstance.setTheme(savedTheme);
    aceEditorInstance.session.setMode("ace/mode/javascript");
    aceEditorInstance.setOptions({
        fontSize: "20px",
        wrap: true
    });

    document.getElementById("editorTheme").value = savedTheme;

    aceEditorInstance.getSession().on('change', () => {
        updateEditorStatus();
        detectContentFormat();
    });

    aceEditorInstance.selection.on('changeCursor', updateEditorStatus);
    detectContentFormat();
}

async function openFullScreenEditor() {
    if (!aceEditorInstance) {
        await initializeAceEditor();
    }
    
    aceEditorInstance.setValue(document.getElementById('fileContent').value, -1);
    $('#fullScreenEditorModal').modal('show');
    updateEditorStatus();
}

function saveFullScreenContent() {
    document.getElementById('fileContent').value = aceEditorInstance.getValue();
    $('#fullScreenEditorModal').modal('hide');
    $('#editModal').modal('hide');
    document.getElementById('editForm').submit();
}

function closeFullScreenEditor() {
    $('#fullScreenEditorModal').modal('hide');
}

function changeFontSize() {
    const fontSize = document.getElementById("fontSize").value;
    aceEditorInstance.setFontSize(fontSize);
}

function changeEditorTheme() {
    const theme = document.getElementById("editorTheme").value;
    aceEditorInstance.setTheme(theme);
    localStorage.setItem("editorTheme", theme);
}

function openSearch() {
    if (!aceEditorInstance) {
        console.error("Ace Editor instance not initialized.");
        return;
    }

    aceEditorInstance.execCommand("find");

    setTimeout(() => {
        const searchBox = document.querySelector(".ace_search");
        if (!searchBox) return;

        const searchInput = searchBox.querySelector(".ace_search_form .ace_search_field");
        if (searchInput) {
            searchInput.placeholder = translations['search_placeholder'] || 'Search...';
        }

        const replaceInput = searchBox.querySelector(".ace_replace_form .ace_search_field");
        if (replaceInput) {
            replaceInput.placeholder = translations['replace_placeholder'] || 'Replace with...';
        }

        const buttons = searchBox.querySelectorAll(".ace_searchbtn");
        buttons.forEach(button => {
            const action = button.getAttribute("action");
            switch (action) {
                case "findPrev":
                    button.textContent = "";
                    button.onclick = () => {
                        aceEditorInstance.execCommand("findprevious");
                        aceEditorInstance.scrollToLine(
                            aceEditorInstance.getCursorPosition().row,
                            true,
                            true
                        );
                    };
                    break;
                case "findNext":
                    button.textContent = "";
                    button.onclick = () => {
                        aceEditorInstance.execCommand("findnext");
                        aceEditorInstance.scrollToLine(
                            aceEditorInstance.getCursorPosition().row,
                            true,
                            true
                        );
                    };
                    break;
                case "findAll":
                    button.textContent = translations['find_all'] || 'All';
                    break;
                case "replaceAndFindNext":
                    button.textContent = translations['replace'] || 'Replace';
                    break;
                case "replaceAll":
                    button.textContent = translations['replace_all'] || 'Replace All';
                    break;
            }
        });

        const optionButtons = searchBox.querySelectorAll(".ace_button");
        optionButtons.forEach(button => {
            const action = button.getAttribute("action");
            switch (action) {
                case "toggleReplace":
                    button.title = translations['toggle_replace_mode'] || 'Toggle Replace Mode';
                    break;
                case "toggleRegexpMode":
                    button.title = translations['toggle_regexp_mode'] || 'Regular Expression Search';
                    break;
                case "toggleCaseSensitive":
                    button.title = translations['toggle_case_sensitive'] || 'Case-Sensitive Search';
                    break;
                case "toggleWholeWords":
                    button.title = translations['toggle_whole_words'] || 'Whole Word Search';
                    break;
                case "searchInSelection":
                    button.title = translations['search_in_selection'] || 'Search in Selection';
                    break;
            }
        });

        const counter = searchBox.querySelector(".ace_search_counter");
        if (counter && counter.textContent.includes("of")) {
            counter.textContent = counter.textContent.replace(
                "of",
                translations['search_counter_of'] || 'of'
            );
        }
    }, 100);
}

function isYamlFormat(content) {
    const yamlPattern = /^(---|\w+:\s)/m;
    return yamlPattern.test(content);
}

function validateJsonSyntax() {
    const content = aceEditorInstance.getValue();
    const annotations = [];
    try {
        JSON.parse(content);
        alert(`${langData[currentLang]['validateJson']} ${langData[currentLang]['jsonSyntaxCorrect']}`);
    } catch (e) {
        const line = e.lineNumber ? e.lineNumber - 1 : 0;
        annotations.push({
            row: line,
            column: 0,
            text: e.message,
            type: "error"
        });
        aceEditorInstance.session.setAnnotations(annotations);
        alert(
            `${langData[currentLang]['validateJson']} ${langData[currentLang]['jsonSyntaxError']}: ${e.message}`
        );
    }
}

function validateYamlSyntax() {
    const content = aceEditorInstance.getValue();
    const annotations = [];
    try {
        jsyaml.load(content);
        alert(`${langData[currentLang]['validateYaml']} ${langData[currentLang]['yamlSyntaxCorrect']}`);
    } catch (e) {
        const line = e.mark ? e.mark.line : 0;
        annotations.push({
            row: line,
            column: 0,
            text: e.message,
            type: "error"
        });
        aceEditorInstance.session.setAnnotations(annotations);
        alert(
            `${langData[currentLang]['validateYaml']} ${langData[currentLang]['yamlSyntaxError']}: ${e.message}`
        );
    }
}

function formatContent() {
    const content = aceEditorInstance.getValue();
    const mode = aceEditorInstance.session.$modeId;
    let formattedContent;

    try {
        if (mode === "ace/mode/json") {
            formattedContent = JSON.stringify(JSON.parse(content), null, 4);
            aceEditorInstance.setValue(formattedContent, -1);
            alert(`${langData[currentLang]['formatIndentation']} ${langData[currentLang]['jsonFormatSuccess']}`);
        } else if (mode === "ace/mode/javascript") {
            formattedContent = js_beautify(content, { indent_size: 4 });
            aceEditorInstance.setValue(formattedContent, -1);
            alert(`${langData[currentLang]['formatIndentation']} ${langData[currentLang]['jsFormatSuccess']}`);
        } else {
            alert(`${langData[currentLang]['formatIndentation']} ${langData[currentLang]['unsupportedMode']}`);
        }
    } catch (e) {
        alert(`${langData[currentLang]['formatIndentation']} ${langData[currentLang]['formatError']}: ${e.message}`);
    }
}

function formatYamlContent() {
    const content = aceEditorInstance.getValue();
    try {
        const yamlObject = jsyaml.load(content);
        const formattedYaml = jsyaml.dump(yamlObject, { indent: 4 });
        aceEditorInstance.setValue(formattedYaml, -1);
        alert(langData[currentLang]['yamlFormatSuccess']);
    } catch (e) {
        alert(`${langData[currentLang]['yamlSyntaxError']}: ${e.message}`);
    }
}

function detectContentFormat() {
    const content = aceEditorInstance.getValue().trim();

    if (isJsonDetected) {
        document.getElementById("jsonValidationBtn").style.display = "inline-block";
        document.getElementById("yamlValidationBtn").style.display = "none";
        document.getElementById("yamlFormatBtn").style.display = "none";
        return;
    }

    try {
        JSON.parse(content);
        document.getElementById("jsonValidationBtn").style.display = "inline-block";
        document.getElementById("yamlValidationBtn").style.display = "none";
        document.getElementById("yamlFormatBtn").style.display = "none";
        isJsonDetected = true;
    } catch {
        if (isYamlFormat(content)) {
            document.getElementById("jsonValidationBtn").style.display = "none";
            document.getElementById("yamlValidationBtn").style.display = "inline-block";
            document.getElementById("yamlFormatBtn").style.display = "inline-block";
        } else {
            document.getElementById("jsonValidationBtn").style.display = "none";
            document.getElementById("yamlValidationBtn").style.display = "none";
            document.getElementById("yamlFormatBtn").style.display = "none";
        }
    }
}

function openEditModal(fileName, fileType) {
    document.getElementById('editingFileName').textContent = fileName;
    document.getElementById('hiddenFileName').value = fileName;
    document.getElementById('hiddenFileType').value = fileType;

    fetch(`?editFile=${encodeURIComponent(fileName)}&fileType=${fileType}`)
        .then(res => res.text())
        .then(data => {
            document.getElementById('fileContent').value = data;
            $('#editModal').modal('show');
        })
        .catch(err => console.error('Failed to retrieve file content:', err));
}

function syncEditorContent() {
    document.getElementById('fileContent').value = document.getElementById('fileContent').value;
}

function updateEditorStatus() {
    const cursor = aceEditorInstance.getCursorPosition();
    const line = cursor.row + 1;
    const column = cursor.column + 1;
    const charCount = aceEditorInstance.getValue().length;

    const lineColumnText = langData[currentLang]['lineColumnDisplay']
        .replace("{line}", line)
        .replace("{column}", column);
    const charCountText = langData[currentLang]['charCountDisplay']
        .replace("{charCount}", charCount);

    document.getElementById('lineColumnDisplay').textContent = lineColumnText;
    document.getElementById('charCountDisplay').textContent = charCountText;
}

$(document).ready(() => {
});

document.addEventListener('DOMContentLoaded', () => {
    const renameModal = document.getElementById('renameModal');
    renameModal.addEventListener('show.bs.modal', event => {
        const button = event.relatedTarget;
        const oldFileName = button.getAttribute('data-filename');
        const fileType = button.getAttribute('data-filetype');

        document.getElementById("oldFileName").value = oldFileName;
        document.getElementById("fileType").value = fileType;
        document.getElementById("newFileName").value = oldFileName;
    });
});

function toggleFullscreen() {
    const modal = document.getElementById('fullScreenEditorModal');

    if (!document.fullscreenElement) {
        modal.requestFullscreen()
            .then(() => {
                document.getElementById('toggleFullscreenBtn').textContent = 'Exit Fullscreen';
            })
            .catch(err => console.error(`Error attempting to enable full-screen mode: ${err.message}`));
    } else {
        document.exitFullscreen()
            .then(() => {
                document.getElementById('toggleFullscreenBtn').textContent = 'Fullscreen';
            })
            .catch(err => console.error(`Error attempting to exit full-screen mode: ${err.message}`));
    }
}

let fileType = '';

function openUploadModal(type) {
    fileType = type;
    const modal = new bootstrap.Modal(document.getElementById('uploadModal'));
    modal.show();
}

const dropZone = document.getElementById('dropZone');

dropZone.addEventListener('dragover', e => {
    e.preventDefault();
    dropZone.classList.add('bg-light');
});

dropZone.addEventListener('dragleave', () => {
    dropZone.classList.remove('bg-light');
});

dropZone.addEventListener('drop', e => {
    e.preventDefault();
    dropZone.classList.remove('bg-light');
    const files = e.dataTransfer.files;
    if (files.length > 0) handleFileUpload(files[0]);
});

document.getElementById('selectFileBtn').addEventListener('click', () => {
    document.getElementById('fileInputModal').click();
});

document.getElementById('fileInputModal').addEventListener('change', e => {
    const files = e.target.files;
    if (files.length > 0) handleFileUpload(files[0]);
});

function handleFileUpload(file) {
    const formData = new FormData();
    formData.append(fileType === 'proxy' ? 'fileInput' : 'configFileInput', file);

    fetch('', {
        method: 'POST',
        body: formData
    })
        .then(res => res.text())
        .then(result => {
            alert(result);
            location.reload();
        })
        .catch(error => {
            alert('上传失败：' + error.message);
        });
}

function confirmDelete(name, event) {
    let confirmMessage = translations['delete_confirm'] 
        || '⚠️ Are you sure you want to delete "{name}"? This action cannot be undone!';
    
    confirmMessage = confirmMessage.replace('{name}', name);

    showConfirmation(encodeURIComponent(confirmMessage), () => {
        event.target.closest('form').submit();
    });

    return false;
}
</script>

<div class="modal fade" id="downloadModal" tabindex="-1" aria-labelledby="downloadModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
  <div class="modal-dialog modal-lg">
    <form method="GET" action="" class="no-loader">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="downloadModalLabel" data-translate="select_database_download"></h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <div class="mb-3">
            <label for="fileSelect" class="form-label" data-translate="select_file"></label>
            <select class="form-select" id="fileSelect" name="file">
              <option value="geoip">geoip.metadb</option>
              <option value="geosite">geosite.dat</option>
              <option value="cache">cache.db</option>
            </select>
          </div>
        </div>
        <div class="modal-footer d-flex justify-content-end gap-3">
          <button type="submit" class="btn btn-primary me-2" data-translate="download_button"></button>
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancel_button"></button>
        </div>
      </div>
    </form>
  </div>
</div>

<form method="POST">
    <div class="modal fade" id="cronModal" tabindex="-1" aria-labelledby="cronModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="cronModalLabel" data-translate="cron_task_title"></h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label for="cronExpression" class="form-label" data-translate="cron_expression_label"></label>
                        <input type="text" class="form-control" id="cronExpression" name="cronExpression" value="0 2 * * *" required>
                    </div>
                    <div class="alert alert-info">
                        <strong data-translate="cron_hint">提示:</strong> <span data-translate="cron_expression_format"></span>
                        <ul>
                            <li><code>分钟 小时 日 月 星期</code></li>
                            <li><span data-translate="cron_example"></code></li>
                        </ul>
                    </div>
                </div>
                <div class="modal-footer d-flex justify-content-end gap-3">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancel_button"></button>
                    <button type="submit" name="createCronJob" class="btn btn-primary" data-translate="save_button"></button>
                </div>
            </div>
        </div>
    </div>
</form>
</div>

