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
            echo '<div class="log-message alert alert-danger" role="alert" data-translate="file_delete_failed"></div>';
        }
    }

    if (isset($_POST['deleteConfigFile'])) {
        $fileToDelete = $configDir . basename($_POST['deleteConfigFile']);
        if (file_exists($fileToDelete) && unlink($fileToDelete)) {
            echo '<div class="log-message alert alert-success" role="alert" data-translate="config_delete_success" data-dynamic-content="' . htmlspecialchars(basename($_POST['deleteConfigFile'])) . '"></div>';
        } else {
            echo '<div class="log-message alert alert-danger" role="alert" data-translate="config_delete_failed"></div>';
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

$subscriptionPath = '/etc/neko/proxy_provider/';
$subscriptionFile = $subscriptionPath . 'subscriptions.json';
$notificationMessage = "";
$subscriptions = [];
$updateCompleted = false;

function storeUpdateLog($message) {
    if (!isset($_SESSION['update_logs'])) {
        $_SESSION['update_logs'] = [];
    }
    $_SESSION['update_logs'][] = $message;
}

if (!file_exists($subscriptionPath)) {
    mkdir($subscriptionPath, 0755, true);
}

if (!file_exists($subscriptionFile)) {
    file_put_contents($subscriptionFile, json_encode([]));
}

$subscriptions = json_decode(file_get_contents($subscriptionFile), true);
if (!$subscriptions) {
    for ($i = 0; $i < 6; $i++) {
        $subscriptions[$i] = [
            'url' => '',
            'file_name' => "subscription_" . ($i + 1) . ".yaml",  
        ];
    }
}

if (isset($_POST['update'])) {
    $index = intval($_POST['index']);
    $url = trim($_POST['subscription_url'] ?? '');
    $customFileName = trim($_POST['custom_file_name'] ?? "subscription_" . ($index + 1) . ".yaml");  

    $subscriptions[$index]['url'] = $url;
    $subscriptions[$index]['file_name'] = $customFileName;

    if (!empty($url)) {
        $tempPath = $subscriptionPath . $customFileName . ".temp";
        $finalPath = $subscriptionPath . $customFileName;

        $command = "curl -s -L -o {$tempPath} {$url}";
        exec($command . ' 2>&1', $output, $return_var);

        if ($return_var !== 0) {
            $command = "wget -q --show-progress -O {$tempPath} {$url}";
            exec($command . ' 2>&1', $output, $return_var);
        }

        if ($return_var === 0) {
            $_SESSION['update_logs'] = [];
            storeUpdateLog('<span data-translate="subscription_downloaded" data-dynamic-content="' . htmlspecialchars($url) . '"></span> <span data-translate="saved_to_temp_file" data-dynamic-content="' . htmlspecialchars($tempPath) . '"></span>');
            //echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="subscription_downloaded" data-dynamic-content="' . htmlspecialchars($url) . '"></span> <span data-translate="saved_to_temp_file" data-dynamic-content="' . htmlspecialchars($tempPath) . '"></span></div>';
            $fileContent = file_get_contents($tempPath);

            if (base64_encode(base64_decode($fileContent, true)) === $fileContent) {
                $decodedContent = base64_decode($fileContent);
                if ($decodedContent !== false && strlen($decodedContent) > 0) {
                    file_put_contents($finalPath, "# Clash Meta Config\n\n" . $decodedContent);
                    storeUpdateLog('<span data-translate="base64_decode_success" data-dynamic-content="' . htmlspecialchars($finalPath) . '"></span>');
                    echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="base64_decode_success" data-dynamic-content="' . htmlspecialchars($finalPath) . '"></span></div>';
                    unlink($tempPath); 
                    $notificationMessage = '<span data-translate="update_success"></span>';
                    $updateCompleted = true;
                } else {
                    storeUpdateLog('<span data-translate="base64_decode_failed"></span>');
                    echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="base64_decode_failed"></span></div>';
                    unlink($tempPath); 
                    $notificationMessage = '<span data-translate="update_failed"></span>';
                }
            } 
            elseif (substr($fileContent, 0, 2) === "\x1f\x8b") {
                $decompressedContent = gzdecode($fileContent);
                if ($decompressedContent !== false) {
                    file_put_contents($finalPath, "# Clash Meta Config\n\n" . $decompressedContent);
                    storeUpdateLog('<span data-translate="gzip_decompress_success" data-dynamic-content="' . htmlspecialchars($finalPath) . '"></span>');
                    echo '<div  class="log-message alert alert-warning custom-alert-success"><span data-translate="gzip_decompress_success" data-dynamic-content="' . htmlspecialchars($finalPath) . '"></span></div>';
                    unlink($tempPath); 
                    $notificationMessage = '<span data-translate="update_success"></span>';
                    $updateCompleted = true;
                } else {
                    storeUpdateLog('<span data-translate="gzip_decompress_failed"></span>');
                    echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="gzip_decompress_failed"></span></div>';
                    unlink($tempPath); 
                    $notificationMessage = '<span data-translate="update_failed"></span>';
                }
            } 
            else {
                rename($tempPath, $finalPath); 
                storeUpdateLog('<span data-translate="subscription_downloaded_no_decode"></span>');
                echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="subscription_downloaded_no_decode"></span></div>';
                $notificationMessage = '<span data-translate="update_success"></span>';
                $updateCompleted = true;
            }
        } else {
            storeUpdateLog('<span data-translate="subscription_update_failed" data-dynamic-content="' . htmlspecialchars(implode("\n", $output)) . '"></span>');
            echo '<div class="log-message alert alert-warning custom-alert-success"><span data-translate="subscription_update_failed" data-dynamic-content="' . htmlspecialchars(implode("\n", $output)) . '"></span></div>';
            unlink($tempPath); 
            $notificationMessage = '<span data-translate="update_failed"></span>';
        }
    } else {
        storeUpdateLog('<span data-translate="subscription_url_empty" data-dynamic-content="' . ($index + 1) . '"></span>');
        $notificationMessage = '<span data-translate="update_failed"></span>';
    }

    file_put_contents($subscriptionFile, json_encode($subscriptions));
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
            echo "<div class='log-message alert alert-success' data-translate='shell_script_created' data-dynamic-content='$shellScriptPath'></div>";
        } else {
            echo "<div class='log-message alert alert-danger' data-translate='shell_script_failed'></div>";
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

.icon-btn-group {
    display: flex;
    flex-wrap: wrap;
    gap: 0.4rem;
    justify-content: flex-start;
}
.icon-btn {
    display: inline-flex !important;
    align-items: center !important;
    justify-content: center !important;
    width: 2rem !important;
    height: 2rem !important;
    padding: 0 !important;
    border-radius: 1rem !important;
    font-size: 1rem !important;
    line-height: 1 !important;
    flex-shrink: 0;
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
<div class="container-sm container-bg mt-4">
    <div class="row">
        <a href="./index.php" class="col btn btn-lg text-nowrap"><i class="bi bi-house-door"></i> <span data-translate="home">Home</span></a>
        <a href="./mihomo_manager.php" class="col btn btn-lg text-nowrap"><i class="bi bi-folder"></i> <span data-translate="manager">Manager</span></a>
        <a href="./singbox.php" class="col btn btn-lg text-nowrap"><i class="bi bi-shop"></i> <span data-translate="template_i">Template I</span></a>
        <a href="./subscription.php" class="col btn btn-lg text-nowrap"><i class="bi bi-bank"></i> <span data-translate="template_ii">Template II</span></a>
        <a href="./mihomo.php" class="col btn btn-lg text-nowrap"><i class="bi bi-building"></i> <span data-translate="template_iii">Template III</span></a>
    </div>

<h2 class="container-fluid text-center mt-4 mb-4" data-translate="subscriptionManagement"></h2>
<div class="container-fluid text-center px-md-3">
<?php if (isset($message) && $message): ?>
    <div class="alert alert-info">
        <?php echo nl2br(htmlspecialchars($message)); ?>
    </div>
<?php endif; ?>
<?php if (isset($subscriptions) && is_array($subscriptions)): ?>
    <div class="container-fluid px-4">
        <?php 
        $maxSubscriptions = 6;
        for ($i = 0; $i < $maxSubscriptions; $i++):
            $displayIndex = $i + 1;
            $url = $subscriptions[$i]['url'] ?? '';
            $fileName = $subscriptions[$i]['file_name'] ?? "subscription_" . $displayIndex . ".yaml";
            
            if ($i % 3 == 0) echo '<div class="row">';
        ?>
            <div class="col-md-4 mb-3 px-1">
                <form method="post" class="card shadow-sm">
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
                        <div class="text-center mt-3">
                            <button type="submit" name="update" class="btn btn-info btn-block">
                                <i class="bi bi-arrow-repeat"></i> <span data-translate="updateSubscription">Settings</span> <?php echo $displayIndex; ?>
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        <?php 
            if ($i % 3 == 2 || $i == $maxSubscriptions - 1) echo '</div>';
        endfor;
        ?>
    </div>
<?php else: ?>
<?php endif; ?>

<div class="text-center mt-1 mb-1">
    <form method="post">
        <button type="button" class="btn btn-primary mx-1 mb-2" data-bs-toggle="modal" data-bs-target="#cronModal">
            <i class="bi bi-clock"></i> <span data-translate="set_cron_job"></span>
        </button>
        
        <button type="submit" name="createShellScript" value="true" class="btn btn-success mx-1 mb-2">
            <i class="bi bi-terminal"></i> <span data-translate="generate_update_script"></span>
        </button>
        
        <button type="button" class="btn btn-info mx-1 mb-2" data-bs-toggle="modal" data-bs-target="#downloadModal">
            <i class="bi bi-download"></i> <span data-translate="update_database"></span>
        </button>
    </form>
</div>

<h2 class="text-center mt-4 mb-3" data-translate="fileManagement">File Management</h2>

<div class="container-fluid px-2 px-md-3">
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
    ?>
    <div class="col-12 col-md-6 col-lg-3">
      <div class="card shadow-sm h-100 text-start">
        <div class="card-body d-flex flex-column justify-content-between">
          <h5 class="card-title mb-2" data-translate-title="fileName"><?= htmlspecialchars($file) ?></h5>
          <p class="card-text mb-1"><strong data-translate="fileSize">Size</strong>: <?= $size ?></p>
          <p class="card-text mb-1"><strong data-translate="lastModified">Last Modified</strong>: <?= $modified ?></p>
          <p class="card-text mb-2"><strong data-translate="fileType">Type</strong>: <span class="badge <?= $isProxy ? 'bg-primary' : 'bg-success' ?>"><?= htmlspecialchars($fileTypes[$index]) ?></span></p>
          <?php

          $lines = file($filePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

          $flowLeft = '';
          $resetDaysLeft = '';
          $expireDateText = '';

          $hasInfo = false;

          foreach ($lines as $line) {
              if (preg_match('/#(.*)$/', $line, $matches)) {
                  $hashComment = urldecode(trim($matches[1]));

                  if (preg_match('/剩余流量[:：]\s*([\d.]+)\s*GB/u', $hashComment, $flowMatch)) {
                      $flowLeft = $flowMatch[1] . 'GB';
                      $hasInfo = true;
                  }

                  if (preg_match('/距离下次重置剩余[:：]\s*(\d+)\s*天/u', $hashComment, $resetMatch)) {
                      $resetDaysLeft = $resetMatch[1];
                      $hasInfo = true;
                  }

                  if (preg_match('/套餐到期[:：]\s*(\d{4}-\d{2}-\d{2})/u', $hashComment, $dateMatch)) {
                      $expireDateText = $dateMatch[1];
                      $hasInfo = true;
                  }
              }
          }

          if ($hasInfo) {
              $infoParts = [];

              if ($flowLeft) {
                  $infoParts[] = $flowLeft;
              }

              if ($resetDaysLeft !== '') {
                  $infoParts[] = 
                      ($translations['resetDaysLeftLabel'] ?? 'Remaining') . ' ' 
                      . $resetDaysLeft . ' ' 
                      . ($translations['daysUnit'] ?? 'days');
              }

              if ($expireDateText) {
                  $infoParts[] = 
                      ($translations['expireDateLabel'] ?? 'Expires') . ' ' 
                      . $expireDateText;
              }

              $infoText = implode(' / ', $infoParts);

              echo '<p class="card-text mb-2"><strong data-translate="subscriptionInfo">'
                  . ($translations['subscriptionInfo'] ?? 'Subscription Info') 
                  . '</strong>: ' . htmlspecialchars($infoText) . '</p>';
          }
          ?>
          <div class="icon-btn-group mt-2" style="gap:0.4rem; display:flex; flex-wrap: wrap;">
            <?php if ($isProxy): ?>
              <form method="post" class="d-inline m-0 p-0">
                <input type="hidden" name="deleteFile" value="<?= htmlspecialchars($file) ?>">
                <button type="submit" class="btn btn-danger icon-btn" onclick="return confirmDelete()" data-translate-title="delete"><i class="bi bi-trash"></i></button>
              </form>
              <button type="button" class="btn btn-success icon-btn" data-bs-toggle="modal" data-bs-target="#renameModal" data-filename="<?= htmlspecialchars($file) ?>" data-filetype="proxy" data-translate-title="rename"><i class="bi bi-pencil"></i></button>
              <button type="button" class="btn btn-warning icon-btn" onclick="openEditModal('<?= htmlspecialchars($file) ?>','proxy')" data-translate-title="edit"><i class="bi bi-pen"></i></button>
              <button type="button" class="btn btn-info icon-btn" onclick="openUploadModal('proxy')" data-translate-title="upload"><i class="bi bi-upload"></i></button>
              <form method="get" class="d-inline m-0 p-0">
                <input type="hidden" name="downloadFile" value="<?= htmlspecialchars($file) ?>">
                <input type="hidden" name="fileType" value="proxy">
                <button type="submit" class="btn btn-primary icon-btn" data-translate-title="download"><i class="bi bi-download"></i></button>
              </form>
            <?php else: ?>
              <form method="post" class="d-inline m-0 p-0">
                <input type="hidden" name="deleteConfigFile" value="<?= htmlspecialchars($file) ?>">
                <button type="submit" class="btn btn-danger icon-btn" onclick="return confirmDelete()" data-translate-title="delete"><i class="bi bi-trash"></i></button>
              </form>
              <button type="button" class="btn btn-success icon-btn" data-bs-toggle="modal" data-bs-target="#renameModal" data-filename="<?= htmlspecialchars($file) ?>" data-filetype="config" data-translate-title="rename"><i class="bi bi-pencil"></i></button>
              <button type="button" class="btn btn-warning icon-btn" onclick="openEditModal('<?= htmlspecialchars($file) ?>','config')" data-translate-title="edit"><i class="bi bi-pen"></i></button>
              <button type="button" class="btn btn-info icon-btn" onclick="openUploadModal('config')" data-translate-title="upload"><i class="bi bi-upload"></i></button>
              <form method="get" class="d-inline m-0 p-0">
                <input type="hidden" name="downloadFile" value="<?= htmlspecialchars($file) ?>">
                <input type="hidden" name="fileType" value="config">
                <button type="submit" class="btn btn-primary icon-btn" data-translate-title="download"><i class="bi bi-download"></i></button>
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
                <button id="aceScriptToggleBtn" class="btn btn-secondary" onclick="toggleAceScript()"><i id="aceIcon" class="bi bi-code-slash"></i> <span id="aceLabel"></span></button>
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
let aceEnabled = null;

function checkAceScript() {
    fetch('ace_loader.php?action=check')
        .then(response => response.text())
        .then(result => {
            aceEnabled = (result.trim() === '1');
            updateAceButton();
        });
}

function toggleAceScript() {
    const action = aceEnabled ? 'remove' : 'add';
    fetch('ace_loader.php?action=' + action)
        .then(response => response.text())
        .then(result => {
            aceEnabled = !aceEnabled;
            updateAceButton();
            document.getElementById('aceScriptStatus').innerText = result;
        })
        .catch(error => {
            document.getElementById('aceScriptStatus').innerText = '请求失败: ' + error;
        });
}

function updateAceButton() {
    const btn = document.getElementById('aceScriptToggleBtn');
    const icon = document.getElementById('aceIcon');
    const label = document.getElementById('aceLabel');

    if (aceEnabled) {
        btn.className = 'btn btn-danger';
        icon.className = 'bi bi-x-circle';
        label.textContent = langData[currentLang]?.remove_ace || 'Remove Ace Component';
    } else {
        btn.className = 'btn btn-success';
        icon.className = 'bi bi-plus-circle';
        label.textContent = langData[currentLang]?.add_ace || 'Add Ace Component';
    }
}

checkAceScript();
</script>

<script>
let isJsonDetected = false;

let aceEditorInstance;

function initializeAceEditor() {
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

    function openFullScreenEditor() {
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
        aceEditorInstance.execCommand("find");
    }

    function isYamlFormat(content) {
            const yamlPattern = /^(---|\w+:\s)/m;
            return yamlPattern.test(content);
    }

    function validateJsonSyntax() {
            const content = aceEditorInstance.getValue();
            let annotations = [];
        try {
            JSON.parse(content);
            alert(langData[currentLang]['validateJson'] + " " + langData[currentLang]['jsonSyntaxCorrect']); 
        } catch (e) {
            const line = e.lineNumber ? e.lineNumber - 1 : 0;
            annotations.push({
            row: line,
            column: 0,
            text: e.message,
            type: "error"
        });
        aceEditorInstance.session.setAnnotations(annotations);
        alert(langData[currentLang]['validateJson'] + " " + langData[currentLang]['jsonSyntaxError'] + ": " + e.message); 
        }
    }

    function validateYamlSyntax() {
            const content = aceEditorInstance.getValue();
            let annotations = [];
        try {
            jsyaml.load(content); 
            alert(langData[currentLang]['validateYaml'] + " " + langData[currentLang]['yamlSyntaxCorrect']);
        } catch (e) {
            const line = e.mark ? e.mark.line : 0;
            annotations.push({
            row: line,
            column: 0,
            text: e.message,
            type: "error"
        });
        aceEditorInstance.session.setAnnotations(annotations);
        alert(langData[currentLang]['validateYaml'] + " " + langData[currentLang]['yamlSyntaxError'] + ": " + e.message); 
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
                alert(langData[currentLang]['formatIndentation'] + " " + langData[currentLang]['jsonFormatSuccess']);
            } else if (mode === "ace/mode/javascript") {
                formattedContent = js_beautify(content, { indent_size: 4 });
                aceEditorInstance.setValue(formattedContent, -1);
                alert(langData[currentLang]['formatIndentation'] + " " + langData[currentLang]['jsFormatSuccess']); 
            } else {
                alert(langData[currentLang]['formatIndentation'] + " " + langData[currentLang]['unsupportedMode']);
            }
        } catch (e) {
            alert(langData[currentLang]['formatIndentation'] + " " + langData[currentLang]['formatError'] + ": " + e.message); 
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
            alert(langData[currentLang]['yamlSyntaxError'] + ": " + e.message);
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
            .then(response => response.text())
            .then(data => {
                document.getElementById('fileContent').value = data; 
                $('#editModal').modal('show');
            })
            .catch(error => console.error('Failed to retrieve file content:', error));
    }

    function syncEditorContent() {
        document.getElementById('fileContent').value = document.getElementById('fileContent').value;
    }

    function updateEditorStatus() {
        const cursor = aceEditorInstance.getCursorPosition();
        const line = cursor.row + 1;
        const column = cursor.column + 1;
        const charCount = aceEditorInstance.getValue().length;

        const lineColumnText = langData[currentLang]['lineColumnDisplay'].replace("{line}", line).replace("{column}", column);
        const charCountText = langData[currentLang]['charCountDisplay'].replace("{charCount}", charCount);

        document.getElementById('lineColumnDisplay').textContent = lineColumnText;
        document.getElementById('charCountDisplay').textContent = charCountText;
    }

    $(document).ready(function() {
        initializeAceEditor();
    });

    document.addEventListener('DOMContentLoaded', function () {
        const renameModal = document.getElementById('renameModal');
        renameModal.addEventListener('show.bs.modal', function (event) {
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
                .catch((err) => console.error(`Error attempting to enable full-screen mode: ${err.message}`));
        } else {
            document.exitFullscreen()
                .then(() => {
                    document.getElementById('toggleFullscreenBtn').textContent = 'Fullscreen';
                })
                .catch((err) => console.error(`Error attempting to exit full-screen mode: ${err.message}`));
            }
       }

    let fileType = ''; 
    function openUploadModal(type) {
        fileType = type;
        const modal = new bootstrap.Modal(document.getElementById('uploadModal'));
        modal.show();
    }

    const dropZone = document.getElementById('dropZone');
    dropZone.addEventListener('dragover', (event) => {
        event.preventDefault();
        dropZone.classList.add('bg-light');
    });

    dropZone.addEventListener('dragleave', () => {
        dropZone.classList.remove('bg-light');
    });

    dropZone.addEventListener('drop', (event) => {
        event.preventDefault();
        dropZone.classList.remove('bg-light');
        const files = event.dataTransfer.files;
        if (files.length > 0) {
            handleFileUpload(files[0]);
        }
    });

    document.getElementById('selectFileBtn').addEventListener('click', () => {
        document.getElementById('fileInputModal').click();
    });

    document.getElementById('fileInputModal').addEventListener('change', (event) => {
        const files = event.target.files;
        if (files.length > 0) {
            handleFileUpload(files[0]);
        }
    });

    function handleFileUpload(file) {
        const formData = new FormData();
        formData.append(fileType === 'proxy' ? 'fileInput' : 'configFileInput', file);

        fetch('', {
            method: 'POST',
            body: formData,
        })
            .then((response) => response.text())
            .then((result) => {
                alert(result);
                location.reload(); 
        })
            .catch((error) => {
                alert('上传失败：' + error.message);
        });
    }

    function confirmDelete() {
        return confirm(langData[currentLang]['confirmDelete']);
    }
</script>
    <div class="modal fade" id="downloadModal" tabindex="-1" aria-labelledby="downloadModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="downloadModalLabel" data-translate="select_database_download"></h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
                </div>
                <div class="modal-body">
                    <form method="GET" action="">
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
                    </form>
                </div>
            </div>
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
