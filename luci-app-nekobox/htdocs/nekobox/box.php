<?php
ob_start();
include './cfg.php';
date_default_timezone_set('Asia/Shanghai');

$dataFilePath = '/tmp/subscription_data.txt';
$lastSubscribeUrl = '';

if (file_exists($dataFilePath)) {
    $fileContent = file_get_contents($dataFilePath);
    $lastPos = strrpos($fileContent, '订阅链接地址:');
    if ($lastPos !== false) {
        $urlSection = substr($fileContent, $lastPos);
        $httpPos = strpos($urlSection, 'http');
        if ($httpPos !== false) {
            $endPos = strpos($urlSection, '自定义模板URL:', $httpPos);
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

    if (preg_match('/^(\*|\d+)( (\*|\d+)){4}$/', $cronExpression)) {
        $cronJob = "$cronExpression $shellScriptPath";
        $currentCrons = shell_exec('crontab -l 2>/dev/null'); 
        $updatedCrons = preg_replace(
            "/^.*".preg_quote($shellScriptPath, '/').".*$/m",
            '', 
            $currentCrons
        ); 

        $updatedCrons = trim($updatedCrons) . "\n" . $cronJob . "\n"; 

        $tempCronFile = tempnam(sys_get_temp_dir(), 'cron');
        file_put_contents($tempCronFile, $updatedCrons);
        exec("crontab $tempCronFile"); 
        unlink($tempCronFile); 

        echo "<div class='alert alert-success'>定时任务已设置: $cronExpression</div>";
    } else {
        echo "<div class='alert alert-danger'>无效的 Cron 表达式，请检查格式。</div>";
    }
}

?>

<?php
$shellScriptPath = '/etc/neko/core/update_subscription.sh';
$DATA_FILE = '/tmp/subscription_data.txt'; 
$LOG_FILE = '/tmp/update_subscription.log'; 
$SUBSCRIBE_URL = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['subscribeUrl'])) {
        $SUBSCRIBE_URL = trim($_POST['subscribeUrl']);
        
        if (empty($SUBSCRIBE_URL)) {
            echo "<div class='alert alert-warning'>订阅链接不能为空。</div>";
            exit;
        }
        
        echo "<div class='alert alert-success'>提交成功: 订阅链接已保存为 $SUBSCRIBE_URL</div>";
    }

    if (isset($_POST['createShellScript'])) {
        $shellScriptContent = <<<EOL
#!/bin/sh

DATA_FILE="/tmp/subscription_data.txt"
CONFIG_DIR="/etc/neko/config"
LOG_FILE="/tmp/update_subscription.log"
TEMPLATE_URL="https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/json/config_8.json"
SUBSCRIBE_URL=$(grep "订阅链接地址:" "$DATA_FILE" | tail -1 | sed 's/^[^|]*| //g' | cut -d ':' -f2- | tr -d '\n\r' | xargs)

if [ -z "\$SUBSCRIBE_URL" ]; then
  echo "\$(date): 订阅链接地址为空或提取失败。" >> "\$LOG_FILE"
  exit 1
fi

COMPLETE_URL="https://sing-box-subscribe-doraemon.vercel.app/config/\${SUBSCRIBE_URL}&file=\${TEMPLATE_URL}"
echo "\$(date): 生成的订阅链接: \$COMPLETE_URL" >> "\$LOG_FILE"

if [ ! -d "\$CONFIG_DIR" ]; then
  mkdir -p "\$CONFIG_DIR"
  if [ \$? -ne 0 ]; then
    echo "\$(date): 无法创建配置目录: \$CONFIG_DIR" >> "\$LOG_FILE"
    exit 1
  fi
fi

CONFIG_FILE="\$CONFIG_DIR/sing-box.json"
wget -O "\$CONFIG_FILE" "\$COMPLETE_URL" >> "\$LOG_FILE" 2>&1

if [ \$? -eq 0 ]; then
  echo "\$(date): 配置文件更新成功，保存路径: \$CONFIG_FILE" >> "\$LOG_FILE"
else
  echo "\$(date): 配置文件更新失败，请检查链接或网络。" >> "\$LOG_FILE"
  exit 1
fi
EOL;

        if (file_put_contents($shellScriptPath, $shellScriptContent) !== false) {
            chmod($shellScriptPath, 0755);
            echo "<div class='alert alert-success'>Shell 脚本已创建成功！路径: $shellScriptPath</div>";
        } else {
            echo "<div class='alert alert-danger'>无法创建 Shell 脚本，请检查权限。</div>";
        }
    }
}
?>

<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme, 0, -4) ?>">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Box - Neko</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/bootstrap/bootstrap.bundle.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/neko.js"></script>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
</head>
<body>
<style>
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
        <a href="./index.php" class="col btn btn-lg">🏠 首页</a>
        <a href="./mihomo_manager.php" class="col btn btn-lg">📂 Mihomo</a>
        <a href="./singbox_manager.php" class="col btn btn-lg">🗂️ Sing-box</a>
        <a href="./box.php" class="col btn btn-lg">💹 订阅转换</a>
        <a href="./filekit.php" class="col btn btn-lg">📦 文件助手</a>
<div class="outer-container">
    <div class="container">
        <h1 class="title text-center" style="margin-top: 3rem; margin-bottom: 2rem;">Sing-box 订阅转换模板</h1>
        <div class="alert alert-info">
            <h4 class="alert-heading">帮助信息</h4>
            <p>
                  请选择一个模板以生成配置文件：根据订阅节点信息选择相应的模板。若选择带有地区分组的模板，请确保您的节点包含以下线路。挂梯子更新！</p>
                 <strong>说明：</strong>定时任务为自动更新操作，默认使用 6 号模板生成配置文件，文件名为 <strong>sing-box.json</strong>。
            </p>
            <ul>
                <li><strong>默认模板 1</strong>：无地区  无分组 通用。</li>
                <li><strong>默认模板 2</strong>：无地区  带分流规则 通用。</li>
                <li><strong>默认模板 3</strong>：香港 日本 美国 分组 带分流规则。</li>
                <li><strong>默认模板 4</strong>：香港 新加坡 日本 美国 分组 带分流规则。</li>
                <li><strong>默认模板 5</strong>：新加坡 日本 美国 韩国 分组 带分流规则。</li>
                <li><strong>默认模板 6</strong>：香港 台湾 新加坡 日本 美国 韩国 分组 带分流规则。</li>
            </ul>
        </div>
        <form method="post" action="">
            <div class="mb-3">
                <label for="subscribeUrl" class="form-label">订阅链接地址:</label>
                <input type="text" class="form-control" id="subscribeUrl" name="subscribeUrl" value="<?php echo htmlspecialchars($lastSubscribeUrl); ?>" placeholder="输入订阅链接" required>
            </div>
            <div class="mb-3">
                <label for="customFileName" class="form-label">自定义文件名（无需输入后缀）</label>
                <input type="text" class="form-control" id="customFileName" name="customFileName" placeholder="输入自定义文件名">
            </div>
            <fieldset class="mb-3">
                <legend class="form-label">选择模板</legend>
                <div class="row">
                    <div class="col">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate1" name="defaultTemplate" value="1" checked>
                        <label class="form-check-label" for="useDefaultTemplate1">默认模板 1</label>
                    </div>
                    <div class="col">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate2" name="defaultTemplate" value="2">
                        <label class="form-check-label" for="useDefaultTemplate2">默认模板 2</label>
                    </div>
                    <div class="col">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate3" name="defaultTemplate" value="3">
                        <label class="form-check-label" for="useDefaultTemplate3">默认模板 3</label>
                    </div>
                    <div class="col">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate4" name="defaultTemplate" value="4">
                        <label class="form-check-label" for="useDefaultTemplate3">默认模板 4</label>
                    </div>
                    <div class="col">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate5" name="defaultTemplate" value="5">
                        <label class="form-check-label" for="useDefaultTemplate3">默认模板 5</label>
                    </div>
                    <div class="col">
                        <input type="radio" class="form-check-input" id="useDefaultTemplate6" name="defaultTemplate" value="6">
                        <label class="form-check-label" for="useDefaultTemplate3">默认模板 6</label>
                    </div>
                </div>
                <div class="mt-3">
                    <input type="radio" class="form-check-input" id="useCustomTemplate" name="templateOption" value="custom">
                    <label class="form-check-label" for="useCustomTemplate">使用自定义模板URL:</label>
                    <input type="text" class="form-control" id="customTemplateUrl" name="customTemplateUrl" placeholder="输入自定义模板URL">
                </div>
            </fieldset>
            <div class="row mb-4"> 
                <div class="col-auto">
                    <form method="post" action="">
                        <button type="submit" name="generateConfig" class="btn btn-info">
                            <i class="bi bi-file-earmark-text"></i> 生成配置文件
                        </button>
                    </form>
                </div>
                <div class="col-auto">
                    <button type="button" class="btn btn-secondary" data-bs-toggle="modal" data-bs-target="#cronModal">
                        <i class="bi bi-clock"></i> 设置定时任务
                    </button>
                </div>
                <div class="col-auto">
                    <form method="post" action="">
                        <button type="submit" name="createShellScript" class="btn btn-primary">
                            <i class="bi bi-terminal"></i> 生成更新脚本
                        </button>
                    </form>
                </div>
            </div>
        <div class="modal fade" id="cronModal" tabindex="-1" aria-labelledby="cronModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
          <div class="modal-dialog modal-lg">
            <div class="modal-content">
              <div class="modal-header">
                <h5 class="modal-title" id="cronModalLabel">设置定时任务</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
              </div>
              <form method="post" action="">
                <div class="modal-body">
                  <div class="mb-3">
                    <label for="cronExpression" class="form-label">Cron 表达式</label>
                    <input type="text" class="form-control" id="cronExpression" name="cronExpression" placeholder="如: 0 2 * * *" required>
                  </div>
                  <div class="alert alert-info">
                    <strong>提示:</strong> Cron 表达式格式：
                    <ul>
                      <li><code>分钟 小时 日 月 星期</code></li>
                      <li>示例: 每天凌晨 2 点: <code>0 2 * * *</code></li>
                      <li>每周一凌晨 3 点: <code>0 3 * * 1</code></li>
                      <li>工作日（周一至周五）的上午 9 点: <code>0 9 * * 1-5</code></li>
                    </ul>
                  </div>
                </div>
                <div class="modal-footer">
                  <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                  <button type="submit" name="setCron" class="btn btn-primary">保存</button>
                </div>
              </form>
            </div>
          </div>
        </div>
        <?php
        $dataFilePath = '/tmp/subscription_data.txt';
        $configFilePath = '/etc/neko/config/sing-box.json';
        $downloadedContent = ''; 

        if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['generateConfig'])) {
            $subscribeUrl = trim($_POST['subscribeUrl']);
            $customTemplateUrl = trim($_POST['customTemplateUrl']);
            $templateOption = $_POST['templateOption'] ?? 'default';
            $currentTime = date('Y-m-d H:i:s');
            $dataContent = $currentTime . " | 订阅链接地址: " . $subscribeUrl . "\n";            
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
            if ($templateOption === 'custom' && !empty($customTemplateUrl)) {
                $templateUrlEncoded = urlencode($customTemplateUrl);
            } else {
                $defaultTemplates = [
                    '1' => "https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/json/config_7.json",
                    '2' => "https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/json/config_6.json",
                    '3' => "https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/json/config_9.json",
                    '4' => "https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/json/config_10.json",
                    '5' => "https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/json/config_11.json",
                    '6' => "https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/json/config_8.json"
                ];

                $templateUrlEncoded = urlencode($defaultTemplates[$_POST['defaultTemplate']] ?? $defaultTemplates['mixed']);
            }

            $completeSubscribeUrl = "https://sing-box-subscribe-doraemon.vercel.app/config/{$subscribeUrlEncoded}&file={$templateUrlEncoded}";
            $tempFilePath = '/tmp/' . $customFileName;
            $command = "wget -O " . escapeshellarg($tempFilePath) . " " . escapeshellarg($completeSubscribeUrl);
            exec($command, $output, $returnVar);
            $logMessages = [];

            if ($returnVar !== 0) {
                $logMessages[] = "无法下载内容: " . htmlspecialchars($completeSubscribeUrl);
            } else {
                $downloadedContent = file_get_contents($tempFilePath);
                if ($downloadedContent === false) {
                    $logMessages[] = "无法读取下载的文件内容";
                } else {
                    $configFilePath = '/etc/neko/config/' . $customFileName; 
                    if (file_put_contents($configFilePath, $downloadedContent) === false) {
                        $logMessages[] = "无法保存修改后的内容到: " . $configFilePath;
                    } else {
                        $logMessages[] = "配置文件生成并保存成功: " . $configFilePath;
                        $logMessages[] = "生成并下载的订阅URL: <a href='" . htmlspecialchars($completeSubscribeUrl) . "' target='_blank'>" . htmlspecialchars($completeSubscribeUrl) . "</a>";
                    }
                }
            }

            echo "<div class='result-container'>";
            echo "<form method='post' action=''>";
            echo "<div class='mb-3'>";
            echo "<textarea id='configContent' name='configContent' class='form-control' style='height: 300px;'>" . htmlspecialchars($downloadedContent) . "</textarea>";
            echo "</div>";
            echo "<div class='text-center' mb-3>";
            echo "<button class='btn btn-info me-3' type='button' onclick='copyToClipboard()'><i class='bi bi-clipboard'></i> 复制到剪贴</button>";
            echo "<input type='hidden' name='saveContent' value='1'>";
            echo "<button class='btn btn-success' type='submit'><i class='bi bi-save'></i>保存修改</button>";
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
                    echo "<div class='alert alert-danger'>无法保存修改后的内容到: " . htmlspecialchars($configFilePath) . "</div>";
                } else {
                    echo "<div class='alert alert-success'>内容已成功保存到: " . htmlspecialchars($configFilePath) . "</div>";
                }
            }
        }

        if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['clearData'])) {
            if (file_exists($dataFilePath)) {
                file_put_contents($dataFilePath, '');
                echo "<div class='alert alert-success'>保存的数据已清空。</div>";
            }
        }

        if (file_exists($dataFilePath)) {
            $savedData = file_get_contents($dataFilePath);
            echo "<div class='card'>";
            echo "<div class='card-body'>";
            echo "<h2 class='card-title'>保存的数据</h2>";
            echo "<pre>" . htmlspecialchars($savedData) . "</pre>";
            echo "<form method='post' action=''>";
            echo "<button class='btn btn-danger' type='submit' name='clearData'>清空数据</button>";
            echo "</form>";
            echo "</div>";
            echo "</div>";
        }
        ?>
    </div>
</div>
<script src="./assets/bootstrap/jquery.min.js"></script>
<script>
    function copyToClipboard() {
        const copyText = document.getElementById("configContent");
        copyText.select();
        document.execCommand("copy");
        alert("已复制到剪贴板");
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
</body>
</html>
