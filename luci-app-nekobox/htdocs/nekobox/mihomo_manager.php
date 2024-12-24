<?php
ob_start();
include './cfg.php';
date_default_timezone_set('Asia/Shanghai');
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
                echo '文件上传成功：' . htmlspecialchars(basename($file['name']));
            } else {
                echo '文件上传失败！';
            }
        } else {
            echo '上传错误：' . $file['error'];
        }
    }

    if (isset($_FILES['configFileInput'])) {
        $file = $_FILES['configFileInput'];
        $uploadFilePath = $configDir . basename($file['name']);

        if ($file['error'] === UPLOAD_ERR_OK) {
            if (move_uploaded_file($file['tmp_name'], $uploadFilePath)) {
                echo '配置文件上传成功：' . htmlspecialchars(basename($file['name']));
            } else {
                echo '配置文件上传失败！';
            }
        } else {
            echo '上传错误：' . $file['error'];
        }
    }

    if (isset($_POST['deleteFile'])) {
        $fileToDelete = $uploadDir . basename($_POST['deleteFile']);
        if (file_exists($fileToDelete) && unlink($fileToDelete)) {
            echo '文件删除成功：' . htmlspecialchars(basename($_POST['deleteFile']));
        } else {
            echo '文件删除失败！';
        }
    }

    if (isset($_POST['deleteConfigFile'])) {
        $fileToDelete = $configDir . basename($_POST['deleteConfigFile']);
        if (file_exists($fileToDelete) && unlink($fileToDelete)) {
            echo '配置文件删除成功：' . htmlspecialchars(basename($_POST['deleteConfigFile']));
        } else {
            echo '配置文件删除失败！';
        }
    }

    if (isset($_POST['oldFileName'], $_POST['newFileName'], $_POST['fileType'])) {
        $oldFileName = basename($_POST['oldFileName']);
        $newFileName = basename($_POST['newFileName']);
        $fileType = $_POST['fileType'];

        if ($fileType === 'proxy') {
            $oldFilePath = $uploadDir. $oldFileName;
            $newFilePath = $uploadDir. $newFileName;
        } elseif ($fileType === 'config') {
            $oldFilePath = $configDir . $oldFileName;
            $newFilePath = $configDir . $newFileName;
        } else {
            echo '无效的文件类型';
            exit;
        }

    if (file_exists($oldFilePath) && !file_exists($newFilePath)) {
        if (rename($oldFilePath, $newFilePath)) {
            echo '文件重命名成功：' . htmlspecialchars($oldFileName) . ' -> ' . htmlspecialchars($newFileName);
        } else {
            echo '文件重命名失败！';
        }
    } else {
        echo '文件重命名失败，文件不存在或新文件名已存在。';
        }
    }

    if (isset($_POST['saveContent'], $_POST['fileName'], $_POST['fileType'])) {
            $fileToSave = ($_POST['fileType'] === 'proxy') ? $uploadDir . basename($_POST['fileName']) : $configDir . basename($_POST['fileName']);
            $contentToSave = $_POST['saveContent'];
            file_put_contents($fileToSave, $contentToSave);
            echo '<p>文件内容已更新：' . htmlspecialchars(basename($fileToSave)) . '</p>';
        }
    }

function formatFileModificationTime($filePath) {
    if (file_exists($filePath)) {
        $fileModTime = filemtime($filePath);
        return date('Y-m-d H:i:s', $fileModTime);
    } else {
        return '文件不存在';
    }
}

$proxyFiles = scandir($uploadDir);
$configFiles = scandir($configDir);

if ($proxyFiles !== false) {
    $proxyFiles = array_diff($proxyFiles, array('.', '..'));
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
        echo '文件不存在';
        exit;
    }
}
?>

<?php
$subscriptionPath = '/etc/neko/proxy_provider/';
$subscriptionFile = $subscriptionPath . 'subscriptions.json';
$message = "";
$subscriptions = [];
$updateCompleted = false;

function outputMessage($message) {
    if (!isset($_SESSION['update_messages'])) {
        $_SESSION['update_messages'] = [];
    }
    $_SESSION['update_messages'][] = $message;
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
    $url = $_POST['subscription_url'] ?? '';
    $customFileName = $_POST['custom_file_name'] ?? "subscription_" . ($index + 1) . ".yaml";  

    $subscriptions[$index]['url'] = $url;
    $subscriptions[$index]['file_name'] = $customFileName;

    if (!empty($url)) {
        $finalPath = $subscriptionPath . $customFileName;

        $command = "wget -q --show-progress -O {$finalPath} {$url}";
        exec($command . ' 2>&1', $output, $return_var);

        if ($return_var !== 0) {
            $command = "curl -s -o {$finalPath} {$url}";
            exec($command . ' 2>&1', $output, $return_var);
        }

        if ($return_var === 0) {
            $_SESSION['update_messages'] = array();
            $_SESSION['update_messages'][] = '<div class="alert alert-warning" style="margin-bottom: 8px;">
                <strong>⚠️ 使用说明：</strong>
                <ul class="mb-0 pl-3">
                    <li>通用模板（mihomo.yaml）最多支持<strong>6个</strong>订阅链接</li>
                    <li>请勿更改默认文件名称</li>
                    <li>该模板支持所有格式订阅链接，无需额外转换</li>
                </ul>
            </div>';

            $fileContent = file_get_contents($finalPath);
            $decodedContent = base64_decode($fileContent);

            if ($decodedContent === false) {
                $_SESSION['update_messages'][] = "Base64 解码失败，请检查下载的文件内容是否有效！";
                $message = "Base64 解码失败";
            } else {
                $clashFile = $subscriptionPath . $customFileName;
                file_put_contents($clashFile, "# Clash Meta Config\n\n" . $decodedContent);
                $_SESSION['update_messages'][] = "订阅链接 {$url} 更新成功，并解码内容保存到: {$clashFile}";
                $message = '更新成功';
                $updateCompleted = true;
            }
        } else {
            $_SESSION['update_messages'][] = "配置更新失败！错误信息: " . implode("\n", $output);
            $message = '更新失败';
        }
    } else {
        $_SESSION['update_messages'][] = "第" . ($index + 1) . "个订阅链接为空！";
        $message = '更新失败';
    }

    file_put_contents($subscriptionFile, json_encode($subscriptions));
    }
?>
<?php
$shellScriptPath = '/etc/neko/core/update_mihomo.sh';
$LOG_FILE = '/tmp/update_subscription.log';
$JSON_FILE = '/etc/neko/proxy_provider/subscriptions.json';
$SAVE_DIR = '/etc/neko/proxy_provider';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['createShellScript'])) {
        $shellScriptContent = <<<EOL
#!/bin/bash

LOG_FILE="$LOG_FILE"
JSON_FILE="$JSON_FILE"
SAVE_DIR="$SAVE_DIR"

if [ ! -f "\$JSON_FILE" ]; then
    echo "\$(date): 错误: JSON 文件不存在: \$JSON_FILE" >> "\$LOG_FILE"
    exit 1
fi

echo "\$(date): 开始处理订阅链接..." >> "\$LOG_FILE"

jq -c '.[]' "\$JSON_FILE" | while read -r ITEM; do
    URL=\$(echo "\$ITEM" | jq -r '.url')         
    FILE_NAME=\$(echo "\$ITEM" | jq -r '.file_name')  

    if [ -z "\$URL" ] || [ "\$URL" == "null" ]; then
        echo "\$(date): 跳过空的 URL，文件名: \$FILE_NAME" >> "\$LOG_FILE"
        continue
    fi

    if [ -z "\$FILE_NAME" ] || [ "\$FILE_NAME" == "null" ]; then
        echo "\$(date): 错误: 文件名为空，跳过此链接: \$URL" >> "\$LOG_FILE"
        continue
    fi

    SAVE_PATH="\$SAVE_DIR/\$FILE_NAME"
    TEMP_PATH="\$SAVE_PATH.temp"  
    echo "\$(date): 正在下载链接: \$URL 到临时文件: \$TEMP_PATH" >> "\$LOG_FILE"

    wget -q -O "\$TEMP_PATH" "\$URL"

    if [ \$? -eq 0 ]; then
        echo "\$(date): 文件下载成功: \$TEMP_PATH" >> "\$LOG_FILE"
        
        base64 -d "\$TEMP_PATH" > "\$SAVE_PATH"

        if [ \$? -eq 0 ]; then
            echo "\$(date): 文件解码成功: \$SAVE_PATH" >> "\$LOG_FILE"
        else
            echo "\$(date): 错误: 文件解码失败: \$SAVE_PATH" >> "\$LOG_FILE"
        fi

        rm -f "\$TEMP_PATH"
    else
        echo "\$(date): 错误: 文件下载失败: \$URL" >> "\$LOG_FILE"
    fi
done

echo "\$(date): 所有订阅链接处理完成。" >> "\$LOG_FILE"
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

<?php
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['createCronJob'])) {
        $cronExpression = trim($_POST['cronExpression']);

        if (empty($cronExpression)) {
            echo "<div class='alert alert-warning'>Cron 表达式不能为空。</div>";
            exit;
        }

        $cronJob = "$cronExpression /etc/neko/core/update_mihomo.sh > /dev/null 2>&1";
        exec("crontab -l | grep -v '/etc/neko/core/update_mihomo.sh' | crontab -");
        exec("(crontab -l; echo '$cronJob') | crontab -");
        echo "<div class='alert alert-success'>Cron 任务已成功添加或更新！</div>";
    }
}
?>
<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme, 0, -4) ?>">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Mihomo - NekoBox</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/bootstrap/bootstrap.bundle.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/neko.js"></script>
    <?php include './ping.php'; ?>
</head>
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
<div class="position-fixed w-100 d-flex justify-content-center" style="top: 20px; z-index: 1050;">
    <div id="updateAlert" class="alert alert-success alert-dismissible fade show" role="alert" style="display: none; min-width: 300px; max-width: 600px;">
        <div class="d-flex align-items-center">
            <div class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></div>
            <strong>更新完成</strong>
        </div>
        <div id="updateMessages" class="small mt-2"></div>
        <button type="button" class="btn-close custom-btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
</div>

<style>
.alert-success {
    background-color: #4CAF50 !important; 
    border: 1px solid rgba(255, 255, 255, 0.3) !important; 
    border-radius: 8px !important;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1) !important; 
    padding: 16px 20px !important;
    position: relative;
    color: #fff !important; 
    backdrop-filter: blur(8px); 
    margin-top: 15px !important;
}

.alert .close,
.alert .btn-close {
    position: absolute !important;
    right: 10px !important;
    top: 10px !important;
    background-color: #dc3545 !important; 
    opacity: 1 !important;
    width: 24px !important;
    height: 24px !important;
    border-radius: 50% !important;
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
    font-size: 16px !important; 
    color: #fff !important;
    border: none !important;
    padding: 0 !important;
    margin: 0 !important;
    transition: all 0.2s ease !important;
    cursor: pointer !important;
}

.alert .close:hover,
.alert .btn-close:hover {
    background-color: #bd2130 !important;
    transform: rotate(90deg); 
}

#updateMessages {
    margin-top: 12px;
    padding-right: 20px;
    font-size: 14px;
    line-height: 1.5;
    color: rgba(255, 255, 255, 0.9); 
}

#updateMessages .alert-warning {
    background-color: rgba(255, 193, 7, 0.1) !important; 
    border-radius: 6px;
    padding: 12px 15px;
    border: 1px solid rgba(255, 193, 7, 0.2);
}

#updateMessages ul {
    margin-bottom: 0;
    padding-left: 20px;
}

#updateMessages li {
    margin-bottom: 6px;
    color: rgba(255, 255, 255, 0.9);
}

html {
    font-size: 16px;  
}

.container {
    padding-left: 2.4em;  
    padding-right: 2.4em; 
}

</style>

<script>
function showUpdateAlert() {
    const alert = $('#updateAlert');
    const messages = <?php echo json_encode($_SESSION['update_messages'] ?? []); ?>;
    
    if (messages.length > 0) {
        const messagesHtml = messages.map(msg => `<div>${msg}</div>`).join('');
        $('#updateMessages').html(messagesHtml);
    }
    
    alert.show().addClass('show');
    
    setTimeout(function() {
        alert.removeClass('show');
        setTimeout(function() {
            alert.hide();
            $('#updateMessages').html('');
        }, 150);
    }, 12000);
}

<?php if (!empty($message)): ?>
    $(document).ready(function() {
        showUpdateAlert();
    });
<?php endif; ?>
</script>
<div class="container-sm container-bg callout border border-3 rounded-4 col-11">
    <div class="row">
        <a href="./index.php" class="col btn btn-lg">🏠 首页</a>
        <a href="./mihomo_manager.php" class="col btn btn-lg">🗃️ 文件管理</a>
        <a href="./singbox.php" class="col btn btn-lg">🏪 模板 一</a>
        <a href="./subscription.php" class="col btn btn-lg">🏦  模板 二</a>
        <a href="./mihomo.php" class="col btn btn-lg">🏣 模板 三</a>
    </div>
    <div class="text-center">
        <h2 style="margin-top: 40px; margin-bottom: 20px;">文件管理</h2>
<div class="container">
    <div class="table-responsive">
        <table class="table table-striped table-bordered text-center">
            <thead class="thead-dark">
                <tr>
                    <th style="width: 20%;">文件名</th>
                    <th style="width: 10%;">大小</th>
                    <th style="width: 20%;">最后修改时间</th>
                    <th style="width: 10%;">文件类型</th>
                    <th style="width: 30%;">执行操作</th>
                </tr>
            </thead>
            <tbody>
                <?php
                $allFiles = array_merge($proxyFiles, $configFiles);
                $allFilePaths = array_merge(array_map(function($file) use ($uploadDir) {
                    return $uploadDir . $file;
                }, $proxyFiles), array_map(function($file) use ($configDir) {
                    return $configDir . $file;
                }, $configFiles));
                $fileTypes = array_merge(array_fill(0, count($proxyFiles), '代理文件'), array_fill(0, count($configFiles), '配置文件'));
                
                foreach ($allFiles as $index => $file) {
                    $filePath = $allFilePaths[$index];
                    $fileType = $fileTypes[$index];
                ?>
                    <tr>
                        <td class="align-middle">
                            <a href="download.php?file=<?php echo urlencode($file); ?>"><?php echo htmlspecialchars($file); ?></a>
                        </td>
                        <td class="align-middle">
                            <?php echo file_exists($filePath) ? formatSize(filesize($filePath)) : '文件不存在'; ?>
                        </td>
                        <td class="align-middle">
                            <?php echo htmlspecialchars(date('Y-m-d H:i:s', filemtime($filePath))); ?>
                        </td>
                        <td class="align-middle">
                            <?php echo htmlspecialchars($fileType); ?>
                        </td>
                        <td class="align-middle">
                            <div class="action-buttons">
                                <?php if ($fileType == '代理文件'): ?>
                                    <form action="" method="post" class="d-inline mb-1">
                                        <input type="hidden" name="deleteFile" value="<?php echo htmlspecialchars($file); ?>">
                                        <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('确定要删除这个文件吗？');"><i>🗑️</i> 删除</button>
                                    </form>
                                    <form action="" method="post" class="d-inline mb-1">
                                        <input type="hidden" name="oldFileName" value="<?php echo htmlspecialchars($file); ?>">
                                        <input type="hidden" name="fileType" value="proxy">
                                        <button type="button" class="btn btn-success btn-sm btn-rename" data-toggle="modal" data-target="#renameModal" data-filename="<?php echo htmlspecialchars($file); ?>" data-filetype="proxy"><i>✏️</i> 重命名</button>
                                    </form>
                                    <form action="" method="post" class="d-inline mb-1">
                                        <button type="button" class="btn btn-warning btn-sm" onclick="openEditModal('<?php echo htmlspecialchars($file); ?>', 'proxy')"><i>📝</i> 编辑</button>
                                    </form>
                                    <form action="" method="post" enctype="multipart/form-data" class="d-inline upload-btn mb-1">
                                        <input type="file" name="fileInput" class="form-control-file" required id="fileInput-<?php echo htmlspecialchars($file); ?>" style="display: none;" onchange="this.form.submit()">
                                        <button type="button" class="btn btn-info btn-sm" onclick="document.getElementById('fileInput-<?php echo htmlspecialchars($file); ?>').click();"><i>📤</i> 上传</button>
                                    </form>
                                <?php else: ?>
                                    <form action="" method="post" class="d-inline mb-1">
                                        <input type="hidden" name="deleteConfigFile" value="<?php echo htmlspecialchars($file); ?>">
                                        <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('确定要删除这个文件吗？');"><i>🗑️</i> 删除</button>
                                    </form>
                                    <form action="" method="post" class="d-inline mb-1">
                                        <input type="hidden" name="oldFileName" value="<?php echo htmlspecialchars($file); ?>">
                                        <input type="hidden" name="fileType" value="config">
                                        <button type="button" class="btn btn-success btn-sm btn-rename" data-toggle="modal" data-target="#renameModal" data-filename="<?php echo htmlspecialchars($file); ?>" data-filetype="config"><i>✏️</i> 重命名</button>
                                    </form>
                                    <form action="" method="post" class="d-inline mb-1">
                                        <button type="button" class="btn btn-warning btn-sm" onclick="openEditModal('<?php echo htmlspecialchars($file); ?>', 'config')"><i>📝</i> 编辑</button>
                                    </form>
                                    <form action="" method="post" enctype="multipart/form-data" class="d-inline upload-btn mb-1">
                                        <input type="file" name="configFileInput" class="form-control-file" required id="fileInput-<?php echo htmlspecialchars($file); ?>" style="display: none;" onchange="this.form.submit()">
                                        <button type="button" class="btn btn-info btn-sm" onclick="document.getElementById('fileInput-<?php echo htmlspecialchars($file); ?>').click();"><i>📤</i> 上传</button>
                                    </form>
                                <?php endif; ?>
                            </div>
                        </td>
                    </tr>
                <?php } ?>
            </tbody>
        </table>
    </div>
</div>

<div class="modal fade" id="renameModal" tabindex="-1" aria-labelledby="renameModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="renameModalLabel">重命名文件</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form id="renameForm" action="" method="post">
                    <input type="hidden" name="oldFileName" id="oldFileName">
                    <input type="hidden" name="fileType" id="fileType">

                    <div class="mb-3">
                        <label for="newFileName" class="form-label">新文件名</label>
                        <input type="text" class="form-control" id="newFileName" name="newFileName" required>
                    </div>

                    <div class="d-flex justify-content-end gap-2">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                        <button type="submit" class="btn btn-primary">确定</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/ace.js" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/js-beautify/1.14.0/beautify.min.js"></script> 
<script src="https://cdn.jsdelivr.net/npm/js-yaml@4.1.0/dist/js-yaml.min.js"></script>

<div class="modal fade" id="editModal" tabindex="-1" aria-labelledby="editModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="editModalLabel">编辑文件: <span id="editingFileName"></span></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form id="editForm" action="" method="post" onsubmit="syncEditorContent()">
                    <textarea name="saveContent" id="fileContent" class="form-control" style="height: 500px;"></textarea>
                    <input type="hidden" name="fileName" id="hiddenFileName">
                    <input type="hidden" name="fileType" id="hiddenFileType">
                    <div class="mt-3 d-flex justify-content-start gap-2">
                        <button type="submit" class="btn btn-primary">保存</button>
                        <button type="button" class="btn btn-pink" onclick="openFullScreenEditor()">高级编辑</button>
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="fullScreenEditorModal" tabindex="-1" role="dialog" aria-hidden="true" data-backdrop="static" data-keyboard="false">
    <div class="modal-dialog modal-fullscreen" role="document">
        <div class="modal-content" style="border: none;">
            <div class="modal-header d-flex justify-content-between align-items-center" style="border-bottom: none;">
                <div class="d-flex align-items-center">
                    <h5 class="modal-title mr-3">高级编辑 - 全屏模式</h5>
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

                    <button type="button" class="btn btn-success btn-sm mx-1" onclick="formatContent()">格式化缩进</button>
                    <button type="button" class="btn btn-success btn-sm mx-1" id="yamlFormatBtn" onclick="formatYamlContent()" style="display: none;">格式化 YAML</button>
                    <button type="button" class="btn btn-info btn-sm mx-1" id="jsonValidationBtn" onclick="validateJsonSyntax()">验证 JSON 语法</button>
                    <button type="button" class="btn btn-info btn-sm mx-1" id="yamlValidationBtn" onclick="validateYamlSyntax()" style="display: none;">验证 YAML 语法</button>
                    <button type="button" class="btn btn-primary btn-sm mx-1" onclick="saveFullScreenContent()">保存并关闭</button>
                    <button type="button" class="btn btn-primary btn-sm mx-1" onclick="openSearch()">搜索</button>
                    <button type="button" class="btn btn-primary btn-sm mx-1" onclick="closeFullScreenEditor()">取消</button>
                    <button type="button" class="btn btn-warning btn-sm mx-1" id="toggleFullscreenBtn" onclick="toggleFullscreen()">全屏</button>
                </div>

                <button type="button" class="close" data-dismiss="modal" aria-label="Close" onclick="closeFullScreenEditor()">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>

            <div class="d-flex justify-content-center align-items-center my-1" id="editorStatus" style="font-weight: bold; font-size: 0.9rem;">
                    <span id="lineColumnDisplay" style="color: blue; font-size: 1.1rem;">行: 1, 列: 1</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span id="charCountDisplay" style="color: blue; font-size: 1.1rem;">字符数: 0</span>
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
            alert("JSON 语法正确");
        } catch (e) {
            const line = e.lineNumber ? e.lineNumber - 1 : 0;
            annotations.push({
            row: line,
            column: 0,
            text: e.message,
            type: "error"
        });
        aceEditorInstance.session.setAnnotations(annotations);
        alert("JSON 语法错误: " + e.message);
        }
    }

    function validateYamlSyntax() {
            const content = aceEditorInstance.getValue();
            let annotations = [];
        try {
            jsyaml.load(content); 
            alert("YAML 语法正确");
        } catch (e) {
            const line = e.mark ? e.mark.line : 0;
            annotations.push({
            row: line,
            column: 0,
            text: e.message,
            type: "error"
        });
        aceEditorInstance.session.setAnnotations(annotations);
        alert("YAML 语法错误: " + e.message);
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
                alert("JSON 格式化成功");
            } else if (mode === "ace/mode/javascript") {
                formattedContent = js_beautify(content, { indent_size: 4 });
                aceEditorInstance.setValue(formattedContent, -1);
                alert("JavaScript 格式化成功");
            } else {
                alert("当前模式不支持格式化缩进");
            }
        } catch (e) {
            alert("格式化错误: " + e.message);
        }
    }


    function formatYamlContent() {
        const content = aceEditorInstance.getValue();
        
        try {
            const yamlObject = jsyaml.load(content); 
            const formattedYaml = jsyaml.dump(yamlObject, { indent: 4 }); 
            aceEditorInstance.setValue(formattedYaml, -1);
            alert("YAML 格式化成功");
        } catch (e) {
            alert("YAML 格式化错误: " + e.message);
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
            .catch(error => console.error('获取文件内容失败:', error));
    }

    function syncEditorContent() {
        document.getElementById('fileContent').value = document.getElementById('fileContent').value;
    }

    function updateEditorStatus() {
        const cursor = aceEditorInstance.getCursorPosition();
        const line = cursor.row + 1;
        const column = cursor.column + 1;
        const charCount = aceEditorInstance.getValue().length;

        document.getElementById('lineColumnDisplay').textContent = `行: ${line}, 列: ${column}`;
        document.getElementById('charCountDisplay').textContent = `字符数: ${charCount}`;
    }

    $(document).ready(function() {
        initializeAceEditor();
    });

    document.addEventListener("DOMContentLoaded", function() {
        const renameButtons = document.querySelectorAll(".btn-rename");
        renameButtons.forEach(button => {
            button.addEventListener("click", function() {
                const oldFileName = this.getAttribute("data-filename");
                const fileType = this.getAttribute("data-filetype");
                document.getElementById("oldFileName").value = oldFileName;
                document.getElementById("fileType").value = fileType;
                document.getElementById("newFileName").value = oldFileName;
                $('#renameModal').modal('show');
            });
        });
    });

    function toggleFullscreen() {
        const modal = document.getElementById('fullScreenEditorModal');
    
        if (!document.fullscreenElement) {
            modal.requestFullscreen()
                .then(() => {
                    document.getElementById('toggleFullscreenBtn').textContent = '退出全屏';
                })
                .catch((err) => console.error(`Error attempting to enable full-screen mode: ${err.message}`));
        } else {
            document.exitFullscreen()
                .then(() => {
                    document.getElementById('toggleFullscreenBtn').textContent = '全屏';
                })
                .catch((err) => console.error(`Error attempting to exit full-screen mode: ${err.message}`));
            }
       }
</script>
<h2 class="text-center mt-4 mb-4">Mihomo订阅管理</h2>

<?php if (isset($message) && $message): ?>
    <div class="alert alert-info">
        <?php echo nl2br(htmlspecialchars($message)); ?>
    </div>
<?php endif; ?>

<?php if (isset($subscriptions) && is_array($subscriptions)): ?>
    <div class="container" style="padding-left: 2.4rem; padding-right: 2.4rem;">
        <div class="row">
            <?php 
            $maxSubscriptions = 6; 
            for ($i = 0; $i < $maxSubscriptions; $i++): 
                $displayIndex = $i + 1; 
                $url = $subscriptions[$i]['url'] ?? '';
                $fileName = $subscriptions[$i]['file_name'] ?? "subscription_" . ($displayIndex) . ".yaml"; 
            ?>
                <div class="col-md-4 mb-3">
                    <form method="post" class="card shadow-sm">
                        <div class="card-body">
                            <div class="form-group">
                                <h5 for="subscription_url_<?php echo $displayIndex; ?>" class="mb-2">订阅链接 <?php echo $displayIndex; ?></h5>
                                <input type="text" name="subscription_url" id="subscription_url_<?php echo $displayIndex; ?>" value="<?php echo htmlspecialchars($url); ?>" class="form-control" placeholder="请输入订阅链接">
                            </div>
                            <div class="form-group">
                                <label for="custom_file_name_<?php echo $displayIndex; ?>">自定义文件名</label>
                                <input type="text" name="custom_file_name" id="custom_file_name_<?php echo $displayIndex; ?>" value="<?php echo htmlspecialchars($fileName); ?>" class="form-control">
                            </div>
                            <input type="hidden" name="index" value="<?php echo $i; ?>">
                            <div class="text-center mt-3"> 
                                <button type="submit" name="update" class="btn btn-info btn-block">🔄 更新订阅 <?php echo $displayIndex; ?></button>
                            </div>
                        </div>
                    </form>
                </div>

                <?php if (($displayIndex) % 3 == 0 && $displayIndex < $maxSubscriptions): ?>
                    </div><div class="row">
                <?php endif; ?>

            <?php endfor; ?>
        </div>
    </div>
<?php else: ?>
    <p>未找到订阅信息。</p>
<?php endif; ?>
<!DOCTYPE html>
<html lang="zh">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <div class="container">
        <h2 class="mt-4 mb-4 text-center">自动更新</h2>
        <form method="post" class="text-center">
            <button type="button" class="btn btn-primary mx-2" data-bs-toggle="modal" data-bs-target="#cronModal">
                设置定时任务
            </button>
            <button type="submit" name="createShellScript" value="true" class="btn btn-success mx-2">
                生成更新脚本
            </button>
             <td>
            <a class="btn btn-info btn-sm text-white" target="_blank" href="./filekit.php" style="font-size: 14px; font-weight: bold;">
                打开文件助手
            </a>
        </td>
        </form>
    </div>

<form method="POST">
    <div class="modal fade" id="cronModal" tabindex="-1" aria-labelledby="cronModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="cronModalLabel">设置 Cron 计划任务</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
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
                        </ul>
                    </div>
                </div>
                <div class="modal-footer d-flex justify-content-end gap-3">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                    <button type="submit" name="createCronJob" class="btn btn-primary">保存</button>
                </div>
            </div>
        </div>
    </div>
</form>
    </div>
<script>
    document.getElementById('pasteButton').onclick = function() {
        window.open('https://paste.gg', '_blank');
    }
    document.getElementById('base64Button').onclick = function() {
        window.open('https://base64.us', '_blank');
    }
</script>

<style>
    .btn-group {
        display: flex;
        gap: 10px; 
        justify-content: center; 
    }
    .btn {
        margin: 0; 
    }

    .table-dark {
        background-color: #6f42c1; 
        color: white; 
    }
    .table-dark th, .table-dark td {
        background-color: #5a32a3; 
    }

    #cronModal .alert {
        text-align: left; 
    }

    #cronModal code {
        white-space: pre-wrap; 
    }

</style>

</div>
      <footer class="text-center">
    <p><?php echo $footer ?></p>
</footer>
