<?php
ob_start();
include './cfg.php';

$dataFilePath = '/etc/neko/proxy_provider/subscription_data.txt';
$lastSubscribeUrl = '';

if (file_exists($dataFilePath)) {
    $fileContent = file_get_contents($dataFilePath);
    $subscriptionLinkAddress = $translations['subscription_link_address'] ?? 'Subscription Link Address:';
    $lastPos = strrpos($fileContent, $subscriptionLinkAddress);
    if ($lastPos !== false) {
        $urlSection = substr($fileContent, $lastPos);
        $httpPos = strpos($urlSection, 'http');
        if ($httpPos !== false) {
            $endPos = strpos($urlSection, 'Custom Template URL:', $httpPos);
            if ($endPos !== false) {
                $lastSubscribeUrl = trim(substr($urlSection, $httpPos, $endPos - $httpPos));
            } else {
                $lastSubscribeUrl = trim(substr($urlSection, $httpPos));
            }
        }
    }
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['setCron'])) {
    $cronExpression = trim($_POST['cronExpression']);
    $shellScriptPath = '/etc/neko/core/update_subscription.sh';
    $logFile = '/etc/neko/tmp/log.txt'; 

    if (preg_match('/^(\*|\d+)( (\*|\d+)){4}$/', $cronExpression)) {
        $cronJob = "$cronExpression $shellScriptPath";
        $currentCrons = shell_exec('crontab -l 2>/dev/null');
        $updatedCrons = preg_replace(
            "/^.*" . preg_quote($shellScriptPath, '/') . ".*$/m",
            '',
            $currentCrons
        );

        $updatedCrons = trim($updatedCrons) . "\n" . $cronJob . "\n";

        $tempCronFile = tempnam(sys_get_temp_dir(), 'cron');
        file_put_contents($tempCronFile, $updatedCrons);
        exec("crontab $tempCronFile");
        unlink($tempCronFile);

        $timestamp = date('[ H:i:s ]');
        file_put_contents($logFile, "$timestamp Cron job successfully set. Sing-box will update at $cronExpression.\n", FILE_APPEND);
        echo "<div class='log-message alert alert-success' data-translate='cron_job_set' data-dynamic-content='$cronExpression'></div>";
    } else {
        $timestamp = date('[ H:i:s ]');
        file_put_contents($logFile, "$timestamp Invalid Cron expression: $cronExpression\n", FILE_APPEND);
        echo "<div class='log-message alert alert-danger' data-translate='cron_job_added_failed'></div>";
    }
}
?>

<?php
$subscriptionFilePath = '/etc/neko/proxy_provider/subscription_data.txt';

$latestLink = '';
if (file_exists($subscriptionFilePath)) {
    $fileContent = trim(file_get_contents($subscriptionFilePath));

    if (!empty($fileContent)) {
        $lines = explode("\n", $fileContent);
        $latestTimestamp = '';

        foreach ($lines as $line) {
            if (preg_match('/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \| .*: (.*)$/', $line, $matches)) {
                $timestamp = $matches[1]; 
                $linkCandidate = $matches[2]; 
                if ($timestamp > $latestTimestamp) {
                    $latestTimestamp = $timestamp;
                    $latestLink = $linkCandidate;
                }
            }
        }
    }
}
?>

<?php
$shellScriptPath = '/etc/neko/core/update_subscription.sh';
$LOG_FILE = '/etc/neko/tmp/log.txt'; 

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['subscribeUrl'])) {
        $SUBSCRIBE_URL = trim($_POST['subscribeUrl']);
        
        if (empty($SUBSCRIBE_URL)) {
            echo "<div class='log-message alert alert-warning'><span data-translate='subscribe_url_empty'></span></div>";
            exit;
        }
        
        //echo '<div class="log-message alert alert-success" data-translate="subscribe_url_saved" data-dynamic-content="' . $SUBSCRIBE_URL . '"></div>';
    }

    if (isset($_POST['createShellScript'])) {
        $shellScriptContent = <<<EOL
#!/bin/sh

LOG_FILE="$LOG_FILE"
SUBSCRIBE_URL=\$(cat /etc/neko/proxy_provider/subscription.txt | tr -d '\\n\\r')

if [ -z "\$SUBSCRIBE_URL" ]; then
  echo "\$(date '+[ %H:%M:%S ]') Subscription URL is empty or extraction failed." >> "\$LOG_FILE"
  exit 1
fi

echo "\$(date '+[ %H:%M:%S ]') Using subscription URL: \$SUBSCRIBE_URL" >> "\$LOG_FILE"

CONFIG_DIR="/etc/neko/config"
if [ ! -d "\$CONFIG_DIR" ]; then
  mkdir -p "\$CONFIG_DIR"
  if [ \$? -ne 0 ]; then
    echo "\$(date '+[ %H:%M:%S ]') Failed to create config directory: \$CONFIG_DIR" >> "\$LOG_FILE"
    exit 1
  fi
fi

CONFIG_FILE="\$CONFIG_DIR/sing-box.json"
wget -q -O "\$CONFIG_FILE" "\$SUBSCRIBE_URL" >/dev/null 2>&1

if [ \$? -eq 0 ]; then
  echo "\$(date '+[ %H:%M:%S ]') Sing-box configuration file updated successfully. Saved to: \$CONFIG_FILE" >> "\$LOG_FILE"

  sed -i 's/"Proxy"/"DIRECT"/g' "\$CONFIG_FILE"

  if [ \$? -eq 0 ]; then
    echo "\$(date '+[ %H:%M:%S ]') Successfully replaced 'Proxy' with 'DIRECT' in the configuration file." >> "\$LOG_FILE"
  else
    echo "\$(date '+[ %H:%M:%S ]') Failed to replace 'Proxy' with 'DIRECT'. Please check the configuration file." >> "\$LOG_FILE"
    exit 1
  fi
else
  echo "\$(date '+[ %H:%M:%S ]') Configuration file update failed. Please check the URL or network." >> "\$LOG_FILE"
  exit 1
fi
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
$dataFilePath = '/etc/neko/proxy_provider/subscription_data.txt';
$lastUpdateTime = null;

$validUrls = [];
if (file_exists($dataFilePath)) {
    $lines = file($dataFilePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $line = trim($line);
        if ($line === '') continue;

        $parts = explode('|', $line);
        foreach ($parts as $part) {
            $part = trim($part);
            if ($part !== '' && preg_match('/^https?:\/\//i', $part)) {
                $validUrls[] = $part;
            }
        }
    }
}

$libDir = __DIR__ . '/lib';
$cacheFile = $libDir . '/sub_info.json';
if (empty($validUrls) && file_exists($cacheFile)) {
    unlink($cacheFile);
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
        return ["http_code"=>$http_code,"sub_info"=>"Request Failed","get_time"=>time()];
    }

    if (!preg_match("/subscription-userinfo: (.*)/i", $response, $matches)) {
        return ["http_code"=>$http_code,"sub_info"=>"No Sub Info Found","get_time"=>time()];
    }

    $info = $matches[1];
    preg_match("/upload=(\d+)/",$info,$m);   $upload   = isset($m[1]) ? (int)$m[1] : 0;
    preg_match("/download=(\d+)/",$info,$m); $download = isset($m[1]) ? (int)$m[1] : 0;
    preg_match("/total=(\d+)/",$info,$m);    $total    = isset($m[1]) ? (int)$m[1] : 0;
    preg_match("/expire=(\d+)/",$info,$m);   $expire   = isset($m[1]) ? (int)$m[1] : 0;

    $used = $upload + $download;
    $percent = ($total > 0) ? ($used / $total) * 100 : 100;

    $expireDate = "null";
    $day_left = "null";
    if ($expire > 0) {
        $expireDate = date("Y-m-d H:i:s",$expire);
        $day_left   = $expire > time() ? ceil(($expire-time())/(3600*24)) : 0;
    } elseif ($expire === 0) {
        $expireDate = "Long-term";
        $day_left   = "∞";
    }

    return [
        "http_code"=>$http_code,
        "sub_info"=>"Successful",
        "upload"=>$upload,
        "download"=>$download,
        "used"=>$used,
        "total"=>$total > 0 ? $total : "∞",
        "percent"=>round($percent,1),
        "day_left"=>$day_left,
        "expire"=>$expireDate,
        "get_time"=>time(),
        "url"=>$subUrl
    ];
}

function saveAllSubInfos($results) {
    $libDir = __DIR__ . '/lib';
    if (!is_dir($libDir)) mkdir($libDir, 0755, true);
    $filePath = $libDir . '/sub_info.json';
    file_put_contents($filePath, json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    return $filePath;
}

function loadAllSubInfosFromFile(&$lastUpdateTime = null) {
    $libDir = __DIR__ . '/lib';
    $filePath = $libDir . '/sub_info.json';
    $results = [];
    if (file_exists($filePath)) {
        $results = json_decode(file_get_contents($filePath), true);
        if ($results) {
            $times = array_column($results, 'get_time');
            if (!empty($times)) $lastUpdateTime = max($times);
        }
    }
    return $results;
}

function clearSubFile() {
    $libDir = __DIR__ . '/lib';
    $filePath = $libDir . '/sub_info.json';
    if (file_exists($filePath)) unlink($filePath);
}

function fetchAllSubInfos($urls) {
    $results = [];
    foreach ($urls as $url) {
        if (empty(trim($url))) continue;
        $userAgents = ["Clash","clash","ClashVerge","Stash","NekoBox","Quantumult%20X","Surge","Shadowrocket","V2rayU","Sub-Store","Mozilla/5.0"];
        $subInfo = null;
        foreach ($userAgents as $ua) {
            $subInfo = getSubInfo($url,$ua);
            if ($subInfo['sub_info']==="Successful") break;
        }
        $results[$url] = $subInfo;
    }

    saveAllSubInfos($results);
    return $results;
}

if ($_SERVER['REQUEST_METHOD']=='POST' && isset($_POST['clearSubscriptions'])) {
    clearSubFile();
    header("Location: ".$_SERVER['PHP_SELF']);
    exit;
}


$lastUpdateTime = null;
if ($_SERVER['REQUEST_METHOD']=='POST' && isset($_POST['generateConfig'])) {
    $subscribeUrls = preg_split('/[\r\n,|]+/', trim($_POST['subscribeUrl'] ?? ''));
    $subscribeUrls = array_filter($subscribeUrls);

    $customFileName = basename(trim($_POST['customFileName'] ?? ''));
    if (empty($customFileName)) $customFileName = 'sing-box';
    if (substr($customFileName,-5) !== '.json') $customFileName .= '.json';
    $configFilePath = '/etc/neko/config/'.$customFileName;

    $allSubInfos = fetchAllSubInfos($subscribeUrls);
    $lastUpdateTime = time();
} else {
    $allSubInfos = loadAllSubInfosFromFile($lastUpdateTime);
}
?>

<meta charset="utf-8">
<title>singbox - Nekobox</title>
<link rel="icon" href="./assets/img/nekobox.png">
<script src="./assets/bootstrap/jquery.min.js"></script>
<?php include './ping.php'; ?>

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
<div class="outer-container px-3">
    <div class="container-fluid">
        <h2 class="title text-center mt-3 mb-3" data-translate="title">Sing-box Conversion Template One</h2>
        <div class="card">
            <div class="card-body">
                <h4 class="card-title" data-translate="helpInfoHeading">Help Information</h4>
                <ul class="list-unstyled ps-3">
                    <li data-translate="template1"><strong>Template 1</strong>: No Region, No Groups.</li>
                    <li data-translate="template2"><strong>Template 2</strong>: No Region, With Routing Rules.</li>
                    <li data-translate="template3"><strong>Template 3</strong>: Hong Kong, Taiwan, Singapore, Japan, USA, South Korea, With Routing Rules.</li>
                    <li data-translate="template4"><strong>Template 4</strong>: Same As Above, Multiple Rules.</li>
                </ul>
            </div>
        </div>

        <form method="post" action="">
            <div class="mb-3 mt-3">
                <label for="subscribeUrl" class="form-label" data-translate="subscribeUrlLabel">Subscription URL</label>         
                <input type="text" class="form-control" id="subscribeUrl" name="subscribeUrl" value="<?php echo htmlspecialchars($latestLink); ?>" placeholder="Enter subscription URL, multiple URLs separated by |"  data-translate-placeholder="subscribeUrlPlaceholder" required>
            </div>
            <div class="mb-3">
                <label for="customFileName" class="form-label" data-translate="customFileNameLabel">Custom Filename (Default: sing-box.json)</label>
                <input type="text" class="form-control" id="customFileName" name="customFileName" placeholder="sing-box.json">
            </div>
            <fieldset class="mb-3">
                <legend class="form-label" data-translate="chooseTemplateLabel">Choose Template</legend>
                <div class="row">
                    <div class="col d-flex align-items-center">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate0" name="defaultTemplate" value="0">
                        <label class="form-check-label ms-2" for="useDefaultTemplate0" data-translate="defaultTemplateLabel">Default Template</label>
                    </div>
                    <div class="col d-flex align-items-center">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate1" name="defaultTemplate" value="1">
                        <label class="form-check-label ms-2" for="useDefaultTemplate1" data-translate="template1Label">Template 1</label>
                    </div>
                    <div class="col d-flex align-items-center">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate2" name="defaultTemplate" value="2">
                        <label class="form-check-label ms-2" for="useDefaultTemplate2" data-translate="template2Label">Template 2</label>
                    </div>
                    <div class="col d-flex align-items-center">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate3" name="defaultTemplate" value="3" checked>
                        <label class="form-check-label ms-2" for="useDefaultTemplate3" data-translate="template3Label">Template 3</label>
                    </div>
                    <div class="col d-flex align-items-center">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate4" name="defaultTemplate" value="4">
                        <label class="form-check-label ms-2" for="useDefaultTemplate4" data-translate="template4Label">Template 4</label>
                    </div>
                </div>
                <div class="mt-3">
                    <div class="d-flex align-items-center">
                        <input type="radio" class="form-check-input" id="useCustomTemplate" name="templateOption" value="custom">
                        <label class="form-check-label ms-2 mb-0" for="useCustomTemplate" data-translate="useCustomTemplateLabel">Use Custom Template URL</label>
                    </div>
                    <input type="text" class="form-control mt-2" id="customTemplateUrl" name="customTemplateUrl" placeholder="Enter custom template URL" data-translate-placeholder="customTemplateUrlPlaceholder">
                </div>
            </fieldset>
            <div class="d-flex flex-wrap gap-2 mb-4">
                <div class="col-auto">
                    <form method="post" action="">
                        <button type="submit" name="generateConfig" class="btn btn-info">
                            <i class="bi bi-file-earmark-text"></i> <span data-translate="generateConfigLabel">Generate Configuration File</span>
                        </button>
                    </form>
                </div>
                <div class="col-auto">
                    <button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#cronModal">
                        <i class="bi bi-clock"></i> <span data-translate="setCronLabel">Set Cron Job</span>
                    </button>
                </div>
                <div class="col-auto">
                    <form method="post" action="">
                        <button type="submit" name="createShellScript" class="btn btn-primary">
                            <i class="bi bi-terminal"></i> <span data-translate="generateShellLabel">Generate Update Script</span>
                        </button>
                   </form>
             </div>
         </div>
    </div>
<div class="modal fade" id="cronModal" tabindex="-1" aria-labelledby="cronModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <form method="post" action="">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="cronModalLabel" data-translate="setCronModalTitle">Set Cron Job</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>              
                <div class="modal-body">
                    <div class="mb-3">
                        <label for="cronExpression" class="form-label" data-translate="cronExpressionLabel">Cron Expression</label>
                        <input type="text" class="form-control" id="cronExpression" name="cronExpression" value="0 2 * * *" required>
                    </div>
                    <div class="alert alert-info mb-0">
                        <div class="fw-bold" data-translate="cron_hint"></div>
                        <div class="mt-2" data-translate="cron_expression_format"></div>
                        <ul class="mt-2 mb-0">
                            <li><span data-translate="cron_format_help"></span></li>
                            <li>
                                <span data-translate="cron_example"></span>
                                <code>0 2 * * *</code>
                            </li>
                        </ul>
                    </div>
                </div>             
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancelButton">Cancel</button>
                    <button type="submit" name="setCron" class="btn btn-primary" data-translate="saveButton">Save</button>
                </div>
            </div>
        </form>
    </div>
</div>
<?php if (!empty($allSubInfos)): ?>
<div class="container-sm py-1">
    <div class="card">
        <div class="card-body p-2">
            <h5 class="py-1 ps-3">
                <i class="bi bi-bar-chart"></i>
                <span data-translate="subscriptionInfo"></span>
            </h5>
            <div class="rounded-3 p-2 border mx-3">
                <?php foreach ($allSubInfos as $url => $subInfo): ?>
                    <?php
                        $total   = formatBytes($subInfo['total'] ?? 0);
                        $used    = formatBytes($subInfo['used'] ?? 0);
                        $percent = $subInfo['percent'] ?? 0;
                        $dayLeft = $subInfo['day_left'] ?? '∞';
                        $expire  = $subInfo['expire'] ?? 'expire';

                        $remainingLabel = $translations['resetDaysLeftLabel'] ?? 'Remaining';
                        $daysUnit       = $translations['daysUnit'] ?? 'days';
                        $expireLabel    = $translations['expireDateLabel'] ?? 'Expires';
                    ?>
                    <div class="mb-1">
                        <?= htmlspecialchars($url) ?>:
                        <?php if ($subInfo['sub_info'] === "Successful"): ?>
                            <span class="text-success">
                                <?= "{$used} / {$total} ({$percent}%) • {$remainingLabel} {$dayLeft} {$daysUnit} • {$expireLabel}: {$expire}" ?>
                            </span>
                        <?php else: ?>
                            <span class="text-danger">
                                <?= htmlspecialchars($translations['subscriptionFetchFailed'] ?? 'Failed to obtain') ?>
                            </span>
                        <?php endif; ?>
                    </div>
                <?php endforeach; ?>

                <?php if (!empty($lastUpdateTime)): ?>
                    <div class="mt-2 text-end" style="font-size: 0.9em; color: var(--accent-color);">
                        <?= ($translations['lastModified'] ?? 'Last Updated') ?>: <?= date('Y-m-d H:i:s', $lastUpdateTime) ?>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>
<?php endif; ?>
<?php
function displayLogData($dataFilePath, $translations) {
    if (isset($_POST['clearData'])) {
        if (file_exists($dataFilePath)) {
            file_put_contents($dataFilePath, '');
        }
        header("Location: " . $_SERVER['PHP_SELF']);
        exit;
    }

    if (file_exists($dataFilePath)) {
        $savedData = file_get_contents($dataFilePath);
        ?>
        <div class="container-sm py-2">
            <div class="card">
                <div class="card-body p-2">
                    <div class="d-flex justify-content-between align-items-center mb-2 mt-2">
                        <h4 class="py-2 ps-3"><?= htmlspecialchars($translations['data_saved']) ?></h4>
                    </div>
                    <div class="rounded-3 p-2 border mx-3" style="height: 300px; overflow-y: auto; overflow-x: hidden;">
                        <pre class="p-1 m-0 ms-2" style="white-space: pre-wrap; word-wrap: break-word; overflow: hidden;"><?= htmlspecialchars($savedData) ?></pre>
                    </div>
                    <div class="text-center mt-3">
                        <form method="post" action="">
                            <button class="btn btn-sm btn-danger" type="submit" name="clearData">
                                <i class="bi bi-trash"></i> <?= htmlspecialchars($translations['clear_data']) ?>
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
        <?php
    }
}
displayLogData('/etc/neko/proxy_provider/subscription_data.txt', $translations);
?>

<?php
ini_set('memory_limit', '512M'); 
$dataFilePath = '/etc/neko/proxy_provider/subscription_data.txt';
$configFilePath = '/etc/neko/config/sing-box.json';
$downloadedContent = '';
$fixedFileName = 'subscription.txt';

function isValidSubscriptionContent($content) {
    $patterns = ['shadowsocks', 'vmess', 'vless', 'trojan', 'hysteria2', 'socks5', 'http'];
    foreach ($patterns as $p) {
        if (stripos($content, $p) !== false) {
            return true;
        }
    }
    return false;
}

function url_decode_fields(&$node) {
    $fields_to_decode = ['password', 'uuid', 'public_key', 'psk', 'id', 'alterId', 'short_id'];
    
    foreach ($fields_to_decode as $field) {
        if (isset($node[$field]) && is_string($node[$field])) {
            $node[$field] = urldecode($node[$field]);
            
            if (in_array($field, ['password', 'public_key', 'psk'])) {
                $node[$field] = trim($node[$field]);
            }
        }
    }
    
    if (isset($node['tls']['reality'])) {
        url_decode_fields($node['tls']['reality']);
    }
    
    if (isset($node['transport']['path']) && is_string($node['transport']['path'])) {
        $node['transport']['path'] = urldecode($node['transport']['path']);
    }
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['generateConfig'])) {
    $subscribeUrl = trim($_POST['subscribeUrl'] ?? '');
    $customTemplateUrl = trim($_POST['customTemplateUrl'] ?? '');
    $templateOption = $_POST['templateOption'] ?? 'default';
    $currentTime = date('Y-m-d H:i:s');

    $lang = $_GET['lang'] ?? 'en';
    $lang = isset($translations[$lang]) ? $lang : 'en';
    $subscribeLinkText = $langData[$currentLang]['subscriptionLink'] ?? 'Subscription Link Address';

    $dataContent = $currentTime . " | " . $subscribeLinkText . ": " . $subscribeUrl . "\n";

    $customFileName = basename(trim($_POST['customFileName'] ?? ''));
    if (empty($customFileName)) {
        $customFileName = 'sing-box';
    }
    if (substr($customFileName, -5) !== '.json') {
        $customFileName .= '.json';
    }

    $currentData = file_exists($dataFilePath) ? file_get_contents($dataFilePath) : '';
    $logEntries = array_filter(explode("\n\n", trim($currentData)));
    if (!in_array(trim($dataContent), $logEntries)) {
        $logEntries[] = trim($dataContent);
    }
    while (count($logEntries) > 100) {
        array_shift($logEntries);
    }
    file_put_contents($dataFilePath, implode("\n\n", $logEntries) . "\n\n");

    $subscribeUrlEncoded = urlencode($subscribeUrl);

    if (isset($_POST['defaultTemplate']) && $_POST['defaultTemplate'] == '0') {
        $templateUrlEncoded = '';
    } elseif ($templateOption === 'custom' && !empty($customTemplateUrl)) {
        $templateUrlEncoded = urlencode($customTemplateUrl);
    } else {
        $defaultTemplates = [
            '1' => "https://raw.githubusercontent.com/Thaolga/Rules/main/sing-box/config_1.json",
            '2' => "https://raw.githubusercontent.com/Thaolga/Rules/main/sing-box/config_2.json",
            '3' => "https://raw.githubusercontent.com/Thaolga/Rules/main/sing-box/config_3.json",
            '4' => "https://raw.githubusercontent.com/Thaolga/Rules/main/sing-box/config_4.json"
        ];
        $templateUrlEncoded = urlencode($defaultTemplates[$_POST['defaultTemplate']] ?? '');
    }

    if (empty($templateUrlEncoded)) {
        $completeSubscribeUrl = "https://sing-box-subscribe-doraemon.vercel.app/config/{$subscribeUrlEncoded}";
    } else {
        $completeSubscribeUrl = "https://sing-box-subscribe-doraemon.vercel.app/config/{$subscribeUrlEncoded}&file={$templateUrlEncoded}";
    }

    $tempFilePath = '/etc/neko/' . $customFileName;
    $logMessages = [];
    $command = "wget -O " . escapeshellarg($tempFilePath) . " " . escapeshellarg($completeSubscribeUrl);
    exec($command, $output, $returnVar);

    if ($returnVar !== 0) {
        $command = "curl -s -L -o " . escapeshellarg($tempFilePath) . " " . escapeshellarg($completeSubscribeUrl);
        exec($command, $output, $returnVar);

        if ($returnVar !== 0) {
            $logMessages[] = "Unable to download content: " . htmlspecialchars($completeSubscribeUrl);
        }
    }

    if ($returnVar === 0) {
        $downloadedContent = file_get_contents($tempFilePath);
        if ($downloadedContent === false) {
            $logMessages[] = "Unable to read the downloaded file content";
        } else {
            $data = json_decode($downloadedContent, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                $logMessages[] = "Invalid JSON format in downloaded file: " . json_last_error_msg();
            } else {
                $removedTags = [];

                if (isset($data['outbounds']) && is_array($data['outbounds'])) {
                    foreach ($data['outbounds'] as &$node) {
                        url_decode_fields($node);
                    }
                    unset($node);
                }

                if (isset($data['outbounds']) && is_array($data['outbounds'])) {
                    $data['outbounds'] = array_values(array_filter($data['outbounds'], function ($node) use (&$removedTags) {
                        if (
                            (isset($node['method']) && strtolower($node['method']) === 'chacha20') ||
                            (isset($node['plugin']) && stripos($node['plugin'], 'v2ray-plugin') !== false)
                        ) {
                            if (isset($node['tag'])) {
                                $removedTags[] = $node['tag'];
                            }
                            return false;
                        }
                        return true;
                    }));
                }

                if (isset($data['outbounds']) && is_array($data['outbounds'])) {
                    foreach ($data['outbounds'] as &$node) {
                        if (
                            isset($node['type']) && in_array($node['type'], ['selector', 'urltest'], true) &&
                            isset($node['outbounds']) && is_array($node['outbounds'])
                        ) {
                            $filteredOutbounds = array_filter($node['outbounds'], function ($tag) use ($removedTags) {
                                return !in_array($tag, $removedTags, true);
                            });

                            $filteredOutbounds = array_map(function ($tag) {
                                return $tag === 'Proxy' ? 'DIRECT' : $tag;
                            }, $filteredOutbounds);

                            if (empty($filteredOutbounds)) {
                                $filteredOutbounds = ['DIRECT'];
                            }

                            $node['outbounds'] = array_values($filteredOutbounds);
                        }
                    }
                    unset($node);
                }

                if (isset($_POST['defaultTemplate']) && $_POST['defaultTemplate'] == '0') {
                    $data['clash_api'] = [
                        'external_ui' => '/etc/neko/ui/',
                        'external_controller' => '0.0.0.0:9090',
                        'secret' => 'Akun',
                        'external_ui_download_url' => ''
                    ];
                }

                if (isset($data['outbounds']) && is_array($data['outbounds'])) {
                    foreach ($data['outbounds'] as &$node) {
                        url_decode_fields($node);
                    }
                    unset($node);
                }

                $downloadedContent = json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
                if ($downloadedContent === false) {
                    $logMessages[] = "Failed to encode JSON: " . json_last_error_msg();
                } else {
                    if (!isValidSubscriptionContent($downloadedContent)) {
                        $logMessages[] = $translations['update_fail'];
                    } else {
                        $tmpFileSavePath = '/etc/neko/proxy_provider/' . $fixedFileName;
                        if (file_put_contents($tmpFileSavePath, $completeSubscribeUrl) === false) {
                            $logMessages[] = $translations['save_subscribe_url_failed'] . $tmpFileSavePath;
                        } else {
                            $logMessages[] = $translations['subscribe_url_saved'] . $tmpFileSavePath;
                        }

                        $configFilePath = '/etc/neko/config/' . $customFileName;
                        if (file_put_contents($configFilePath, $downloadedContent) === false) {
                            $logMessages[] = $translations['save_config_failed'] . $configFilePath;
                        } else {
                            $logMessages[] = $translations['config_saved'] . $configFilePath;
                        }
                    }
                }

                if (file_exists($tempFilePath)) {
                    unlink($tempFilePath);
                    $logMessages[] = $translations['temp_file_cleaned'] . $tempFilePath;
                } else {
                    $logMessages[] = $translations['temp_file_not_found'] . $tempFilePath;
                }
            }
        }
    }

    echo "<div class='result-container'>";
    echo "<form method='post' action=''>";
    echo "<div class='mb-3 px-2'>";
    echo "<textarea id='configContent' name='configContent' class='form-control' style='height: 300px;'>" . htmlspecialchars($downloadedContent) . "</textarea>";
    echo "</div>";
    echo "<div class='text-center' mb-3>";
    echo "<button class='btn btn-info me-3' type='button' onclick='copyToClipboard()'><i class='bi bi-clipboard'></i> " . $translations['copy_to_clipboard'] . "</button>";
    echo "<input type='hidden' name='saveContent' value='1'>";
    echo "<button class='btn btn-success' type='submit'><i class='bi bi-save'></i> " . $translations['save_changes'] . "</button>";
    echo "</div>";
    echo "</form>";
    echo "</div>";
    echo "<div class='log-message alert alert-success mt-3' style='word-wrap: break-word; overflow-wrap: break-word;'>";
    foreach ($logMessages as $message) {
        echo $message . "<br>";
    }
    echo "</div>";
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['saveContent'])) {
    if (isset($_POST['configContent'])) {
        $editedContent = trim($_POST['configContent']);
        if (file_put_contents($configFilePath, $editedContent) === false) {
            echo "<div class='log-message alert alert-danger'>" . $translations['error_save_content'] . htmlspecialchars($configFilePath) . "</div>";
        } else {
            echo "<div class='log-message alert alert-success'>" . $translations['success_save_content'] . htmlspecialchars($configFilePath) . "</div>";
        }
    }
}

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['clearData'])) {
    if (file_exists($dataFilePath)) {
        file_put_contents($dataFilePath, '');
        echo "<div class='log-message alert alert-info'>" . $translations['save_data_cleared'] . "</div>";
    }
}
?>
 <footer class="text-center"><p><?php echo $footer ?></p></footer>

<script>
function copyToClipboard() {
    const copyText = document.getElementById("configContent");
    copyText.select();
    document.execCommand("copy");
    alert("<?php echo $translations['copyToClipboardAlert']; ?>");
}

document.addEventListener('DOMContentLoaded', () => {
    const customTemplateRadio = document.getElementById('useCustomTemplate');
    const customTemplateInput = document.getElementById('customTemplateUrl');
    const defaultTemplateRadios = document.querySelectorAll('input[name="defaultTemplate"]');

    function toggleCustomInput() {
        customTemplateInput.style.display = customTemplateRadio.checked ? 'block' : 'none';
    }

    function updateTemplateState() {
        if (customTemplateRadio.checked) {
            defaultTemplateRadios.forEach(radio => {
                radio.checked = false;
            });
        }
        const isDefaultSelected = Array.from(defaultTemplateRadios).some(radio => radio.checked);
        if (isDefaultSelected) {
            customTemplateRadio.checked = false;
        }
        toggleCustomInput();
    }

    const fileNameInput = document.getElementById('customFileName');
    const savedFileName = localStorage.getItem('customFileName');
    if (savedFileName) {
        fileNameInput.value = savedFileName;
    }
    fileNameInput.addEventListener('input', function() {
        localStorage.setItem('customFileName', this.value.trim());
    });

    const savedTemplate = localStorage.getItem("selectedTemplate");
    const customTemplateUrl = localStorage.getItem("customTemplateUrl");
    if (savedTemplate === "custom" && customTemplateUrl) {
        customTemplateRadio.checked = true;
        customTemplateInput.value = customTemplateUrl;
    } else if (savedTemplate) {
        const templateInput = document.querySelector(`input[name="defaultTemplate"][value="${savedTemplate}"]`);
        if (templateInput) templateInput.checked = true;
    }

    defaultTemplateRadios.forEach(radio => {
        radio.addEventListener('change', function() {
            if (this.checked) {
                localStorage.setItem("selectedTemplate", this.value);
                localStorage.removeItem("customTemplateUrl");
                customTemplateRadio.checked = false;
                toggleCustomInput();
            }
        });
    });

    customTemplateRadio.addEventListener('change', function() {
        if (this.checked) {
            localStorage.setItem("selectedTemplate", "custom");
            defaultTemplateRadios.forEach(radio => {
                radio.checked = false;
            });
        }
        toggleCustomInput();
    });

    customTemplateInput.addEventListener('input', function() {
        localStorage.setItem("customTemplateUrl", this.value);
    });

    toggleCustomInput();
});
</script>
