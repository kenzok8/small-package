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
        echo "<div id='log-message' class='alert alert-success' data-translate='cron_job_set' data-dynamic-content='$cronExpression'></div>";
    } else {
        $timestamp = date('[ H:i:s ]');
        file_put_contents($logFile, "$timestamp Invalid Cron expression: $cronExpression\n", FILE_APPEND);
        echo "<div id='log-message' class='alert alert-danger' data-translate='cron_job_added_failed'></div>";
    }
}
?>

<?php
$subscriptionFilePath = '/etc/neko/proxy_provider/subscription_data.txt';

if (file_exists($subscriptionFilePath)) {
    $fileContent = file_get_contents($subscriptionFilePath);
    $fileContent = trim($fileContent); 
} else {
    $fileContent = ''; 
}

$latestLink = '';
if (!empty($fileContent)) {
    $lines = explode("\n", $fileContent);

    $latestTimestamp = '';
    $latestLink = '';

    foreach ($lines as $line) {
        if (preg_match('/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \| .*: (.*)$/', $line, $matches)) {
            $timestamp = $matches[1]; 
            $links = $matches[2]; 

            if ($timestamp > $latestTimestamp) {
                $latestTimestamp = $timestamp;
                $latestLink = $links;
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
            echo "<div class='alert alert-warning' data-translate='subscribe_url_empty'></div>";
            exit;
        }
        
        echo '<div id="log-message" class="alert alert-success" data-translate="subscribe_url_saved" data-dynamic-content="' . $SUBSCRIBE_URL . '"></div>';
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
            echo "<div id='log-message' class='alert alert-success' data-translate='shell_script_created' data-dynamic-content='$shellScriptPath'></div>";
        } else {
            echo "<div id='log-message' class='alert alert-danger' data-translate='shell_script_failed'></div>";
        }
    }
}
?>

<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme, 0, -4) ?>">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>singbox - Nekobox</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/bootstrap/bootstrap.bundle.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/neko.js"></script>
    <link href="./assets/bootstrap/bootstrap-icons.css" rel="stylesheet">
    <?php include './ping.php'; ?>
</head>
<body>
<style>
.container-fluid {
    max-width: 2400px;
    width: 100%;
    margin: 0 auto;
}

.section-container {
   padding-left: 32px;  
   padding-right: 32px;
}

.container {
   padding-left: 40px;  
   padding-right: 40px;
}

@media (max-width: 767px) {
    .row a {
        font-size: 9px; 
    }
}

.table-responsive {
    width: 100%;
}

</style>
<div class="container-sm container-bg callout border border-3 rounded-4 col-11">
    <div class="row">
        <a href="./index.php" class="col btn btn-lg text-nowrap"><i class="bi bi-house-door"></i> <span data-translate="home">Home</span></a>
        <a href="./mihomo_manager.php" class="col btn btn-lg text-nowrap"><i class="bi bi-folder"></i> <span data-translate="manager">Manager</span></a>
        <a href="./singbox.php" class="col btn btn-lg text-nowrap"><i class="bi bi-shop"></i> <span data-translate="template_i">Template I</span></a>
        <a href="./subscription.php" class="col btn btn-lg text-nowrap"><i class="bi bi-bank"></i> <span data-translate="template_ii">Template II</span></a>
        <a href="./mihomo.php" class="col btn btn-lg text-nowrap"><i class="bi bi-building"></i> <span data-translate="template_iii">Template III</span></a>
<div class="outer-container section-container">
    <div class="container-fluid">
        <h1 class="title text-center" style="margin-top: 3rem; margin-bottom: 2rem;" data-translate="title">Sing-box Conversion Template One</h1>
        <div class="alert alert-info">
            <h4 class="alert-heading" data-translate="helpInfoHeading">Help Information</h4>
            <ul>
                <li data-translate="template1"><strong>Template 1</strong>: No Region, No Groups.</li>
                <li data-translate="template2"><strong>Template 2</strong>: No Region, With Routing Rules.</li>
                <li data-translate="template3"><strong>Template 3</strong>: Hong Kong, Taiwan, Singapore, Japan, USA, South Korea, With Routing Rules.</li>
                <li data-translate="template4"><strong>Template 4</strong>: Same As Above, Multiple Rules.</li>
            </ul>
        </div>
        <form method="post" action="">
            <div class="mb-3">
                <label for="subscribeUrl" class="form-label" data-translate="subscribeUrlLabel">Subscription URL</label>         
                <input type="text" class="form-control" id="subscribeUrl" name="subscribeUrl" value="<?php echo htmlspecialchars($links); ?>" placeholder="Enter subscription URL, multiple URLs separated by |"  data-translate-placeholder="subscribeUrlPlaceholder" required>
            </div>
            <div class="mb-3">
                <label for="customFileName" class="form-label" data-translate="customFileNameLabel">Custom Filename (Default: sing-box.json)</label>
                <input type="text" class="form-control" id="customFileName" name="customFileName" placeholder="sing-box.json">
            </div>
            <fieldset class="mb-3">
                <legend class="form-label" data-translate="chooseTemplateLabel">Choose Template</legend>
                <div class="row">
                    <div class="col">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate0" name="defaultTemplate" value="0" checked>
                        <label class="form-check-label" for="useDefaultTemplate0" data-translate="defaultTemplateLabel">Default Template</label>
                    </div>
                    <div class="col">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate1" name="defaultTemplate" value="1">
                        <label class="form-check-label" for="useDefaultTemplate1" data-translate="template1Label">Template 1</label>
                    </div>
                    <div class="col">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate2" name="defaultTemplate" value="2">
                        <label class="form-check-label" for="useDefaultTemplate2" data-translate="template2Label">Template 2</label>
                    </div>
                    <div class="col">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate3" name="defaultTemplate" value="3">
                        <label class="form-check-label" for="useDefaultTemplate3" data-translate="template3Label">Template 3</label>
                    </div>
                    <div class="col">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate4" name="defaultTemplate" value="4">
                        <label class="form-check-label" for="useDefaultTemplate4" data-translate="template4Label">Template 4</label>
                    </div>
                </div>
                <div class="mt-3">
                    <input type="radio" class="form-check-input" id="useCustomTemplate" name="templateOption" value="custom">
                    <label class="form-check-label mb-3" for="useCustomTemplate" data-translate="useCustomTemplateLabel">Use Custom Template URL</label>
                    <input type="text" class="form-control" id="customTemplateUrl" name="customTemplateUrl" placeholder="Enter custom template URL" data-translate-placeholder="customTemplateUrlPlaceholder">
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
        </form>
        <div class="modal fade" id="cronModal" tabindex="-1" aria-labelledby="cronModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="cronModalLabel" data-translate="setCronModalTitle">Set Cron Job</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form method="post" action="">
                        <div class="modal-body">
                            <div class="mb-3">
                                <label for="cronExpression" class="form-label" data-translate="cronExpressionLabel">Cron Expression</label>
                                <input type="text" class="form-control" id="cronExpression" name="cronExpression" value="0 2 * * *" required>
                            </div>
                            <div class="alert alert-info">
                                <strong data-translate="cron_hint"></strong> <span data-translate="cron_expression_format"></span>
                                <ul>
                                    <li><span data-translate="cron_format_help"></span></li>
                                    <li><span data-translate="cron_example"></span><code>0 2 * * *</code></li>
                                </ul>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancelButton">Cancel</button>
                            <button type="submit" name="setCron" class="btn btn-primary" data-translate="saveButton">Save</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    document.querySelectorAll('input[name="defaultTemplate"]').forEach((elem) => {
        elem.addEventListener('change', function () {
            const customTemplateDiv = document.getElementById('customTemplateUrlDiv');
            if (this.value === 'custom') {
                customTemplateDiv.style.display = 'block';
            } else {
                customTemplateDiv.style.display = 'none';
            }
        });
    });
</script>
        <?php
        $dataFilePath = '/etc/neko/proxy_provider/subscription_data.txt';
        $configFilePath = '/etc/neko/config/sing-box.json';
        $downloadedContent = ''; 
        $fixedFileName = 'subscription.txt'; 

        if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['generateConfig'])) {
            $subscribeUrl = trim($_POST['subscribeUrl']);
            $customTemplateUrl = trim($_POST['customTemplateUrl']);
            $templateOption = $_POST['templateOption'] ?? 'default';
            $currentTime = date('Y-m-d H:i:s');

            $lang = $_GET['lang'] ?? 'en'; 
            $lang = isset($translations[$lang]) ? $lang : 'en'; 
            $subscribeLinkText = $langData[$currentLang]['subscriptionLink'] ?? 'Subscription Link Address';
    
            $dataContent = $currentTime . " | " . $subscribeLinkText . ": " . $subscribeUrl . "\n";     
    
            $customFileName = trim($_POST['customFileName']);
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

            while (count($logEntries) > 10) {
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
                    '1' => "https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/json/config_7.json",
                    '2' => "https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/json/config_6.json",
                    '3' => "https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/json/config_8.json",
                    '4' => "https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/json/config_12.json",
                    '5' => "https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/json/config_2.json"
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
                    $downloadedContent = preg_replace_callback(
                        '/\{\s*"tag":\s*"(.*?)",\s*"type":\s*"selector",\s*"outbounds":\s*\[\s*"Proxy"\s*\]\s*\}/s',
                        function ($matches) {
                            return str_replace('"Proxy"', '"DIRECT"', $matches[0]);
                        },
                        $downloadedContent
                    );

                    if (isset($_POST['defaultTemplate']) && $_POST['defaultTemplate'] == '0') {
                $replacement = '
  "clash_api": {
      "external_ui": "/etc/neko/ui/",
      "external_controller": "0.0.0.0:9090",
      "secret": "Akun",
      "external_ui_download_url": ""
    },';  

                $downloadedContent = preg_replace('/"clash_api":\s*\{.*?\},/s', $replacement, $downloadedContent);
            }

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

                    if (file_exists($tempFilePath)) {
                        unlink($tempFilePath); 
                        $logMessages[] = $translations['temp_file_cleaned'] . $tempFilePath;
                    } else {
                        $logMessages[] = $translations['temp_file_not_found'] . $tempFilePath;
                    }
                }
            }

            echo "<div class='result-container'>";
            echo "<form method='post' action=''>";
            echo "<div class='mb-3'>";
            echo "<textarea id='configContent' name='configContent' class='form-control' style='height: 300px;'>" . htmlspecialchars($downloadedContent) . "</textarea>";
            echo "</div>";
            echo "<div class='text-center' mb-3>";
            echo "<button class='btn btn-info me-3' type='button' onclick='copyToClipboard()'><i class='bi bi-clipboard'></i> " . $translations['copy_to_clipboard'] . "</button>";
            echo "<input type='hidden' name='saveContent' value='1'>";
            echo "<button class='btn btn-success' type='submit'><i class='bi bi-save'></i> " . $translations['save_changes'] . "</button>";
            echo "</div>";
            echo "</form>";
            echo "</div>";
            echo "<div class='alert alert-info mt-3' style='word-wrap: break-word; overflow-wrap: break-word;'>";
            foreach ($logMessages as $message) {
            echo $message . "<br>";
            }
            echo "</div>";
        }

        if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['saveContent'])) {
            if (isset($_POST['configContent'])) {
                $editedContent = trim($_POST['configContent']);
                if (file_put_contents($configFilePath, $editedContent) === false) {
                    echo "<div class='alert alert-danger'>" . $translations['error_save_content'] . htmlspecialchars($configFilePath) . "</div>";
                } else {
                    echo "<div class='alert alert-success'>" . $translations['success_save_content'] . htmlspecialchars($configFilePath) . "</div>";
                }
            }
        }

        if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['clearData'])) {
            if (file_exists($dataFilePath)) {
                file_put_contents($dataFilePath, '');
                echo "<div class='alert alert-success'>" . $translations['save_data_cleared'] . "</div>";
            }
        }

        if (file_exists($dataFilePath)) {
            $savedData = file_get_contents($dataFilePath);
            echo "<div class='container'>";
            echo "<div class='card'>";
            echo "<div class='card-body'>";
            echo "<h2 class='card-title'>" . $translations['data_saved'] . "</h2>";
            echo "<pre>" . htmlspecialchars($savedData) . "</pre>";
            echo "<form method='post' action=''>";
            echo '<input type="hidden" name="lang" value="' . $currentLang . '">'; 
            echo '<button class="btn btn-danger" type="submit" name="clearData"><i class="bi bi-trash"></i> ' . $translations['clear_data'] . '</button>';
            echo "</form>";
            echo "</div>";
            echo "</div>";
        }
        ?>
    </div>
</div>
    </div>
</form>
<script src="./assets/bootstrap/jquery.min.js"></script>
<script>
    function copyToClipboard() {
        const copyText = document.getElementById("configContent");
        copyText.select();
        document.execCommand("copy");
        alert("Copied to clipboard");
    }
</script>

<script>
document.addEventListener('DOMContentLoaded', (event) => {
    const savedFileName = localStorage.getItem('customFileName');

    if (savedFileName) {
        document.getElementById('customFileName').value = savedFileName;
        }
    });

document.getElementById('customFileName').addEventListener('input', function() {
    const customFileName = this.value.trim();
    localStorage.setItem('customFileName', customFileName);
    });

document.addEventListener("DOMContentLoaded", function () {
    const savedTemplate = localStorage.getItem("selectedTemplate");
    const customTemplateUrl = localStorage.getItem("customTemplateUrl");

    if (savedTemplate) {
        const templateInput = document.querySelector(`input[name="defaultTemplate"][value="${savedTemplate}"]`);
        if (templateInput) {
            templateInput.checked = true;
        }
    }

    if (customTemplateUrl) {
        document.getElementById("customTemplateUrl").value = customTemplateUrl;
        document.getElementById("useCustomTemplate").checked = true;
    }

    document.querySelectorAll('input[name="defaultTemplate"]').forEach(input => {
        input.addEventListener("change", function () {
            localStorage.setItem("selectedTemplate", this.value);
            localStorage.removeItem("customTemplateUrl"); 
        });
    });

    document.getElementById("customTemplateUrl").addEventListener("input", function () {
        localStorage.setItem("customTemplateUrl", this.value);
        localStorage.setItem("selectedTemplate", "custom"); 
    });

    document.getElementById("useCustomTemplate").addEventListener("change", function () {
        localStorage.setItem("selectedTemplate", "custom");
    });
});
</script>
</div>
      <footer class="text-center">
    <p><?php echo $footer ?></p>
</footer>
</body>
</html>
