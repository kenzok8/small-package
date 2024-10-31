<?php
ob_start();
include './cfg.php';
$proxyDir  = '/www/nekobox/proxy/';
$configDir = '/etc/neko/config/';

ini_set('memory_limit', '256M');

if (!is_dir($proxyDir)) {
    mkdir($proxyDir, 0755, true);
}

if (!is_dir($configDir)) {
    mkdir($configDir, 0755, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_FILES['fileInput'])) {
        $file = $_FILES['fileInput'];
        $uploadFilePath = $proxyDir . basename($file['name']);

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
        $fileToDelete = $proxyDir . basename($_POST['deleteFile']);
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
        $oldFilePath = $proxyDir . $oldFileName;
        $newFilePath = $proxyDir . $newFileName;
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
        $fileToSave = ($_POST['fileType'] === 'proxy') ? $proxyDir . basename($_POST['fileName']) : $configDir . basename($_POST['fileName']);
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

$proxyFiles = scandir($proxyDir);
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
    $filePath = ($_GET['fileType'] === 'proxy') ? $proxyDir . basename($_GET['editFile']) : $configDir . basename($_GET['editFile']);
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
$configPath = '/www/nekobox/proxy/';
$configFile = $configPath . 'subscriptions.json';
$subscriptionList = [];

while (ob_get_level() > 0) {
    ob_end_flush();
}

function outputMessage($message) {
    if (!isset($_SESSION['notification_messages'])) {
        $_SESSION['notification_messages'] = [];
    }
    $_SESSION['notification_messages'][] = $message;
}

if (!isset($_SESSION['help_message'])) {
    $_SESSION['help_message'] = '<div class="text-warning" style="margin-bottom: 8px;">
        <strong>⚠️ 注意：</strong> 当前配置文件必须配合 <strong>Puernya</strong> 内核使用，不支持其他内核！
    </div>';
}

if (!file_exists($configPath)) {
    mkdir($configPath, 0755, true);
}

if (!file_exists($configFile)) {
    file_put_contents($configFile, json_encode([]));
}

$subscriptionList = json_decode(file_get_contents($configFile), true);
if (!$subscriptionList || !is_array($subscriptionList)) {
    $subscriptionList = [];
    for ($i = 1; $i <= 3; $i++) {
        $subscriptionList[$i - 1] = [
            'url' => '',
            'file_name' => "subscription_{$i}.yaml",
        ];
    }
}

if (isset($_POST['saveSubscription'])) {
    $index = intval($_POST['index']);
    if ($index >= 0 && $index < 3) {
        $url = $_POST['subscription_url'] ?? '';
        $customFileName = $_POST['custom_file_name'] ?? "subscription_{$index}.yaml";
        $subscriptionList[$index]['url'] = $url;
        $subscriptionList[$index]['file_name'] = $customFileName;

        if (!empty($url)) {
            $finalPath = $configPath . $customFileName;
            $command = sprintf(
                "curl -fsSL -o %s %s",
                escapeshellarg($finalPath),
                escapeshellarg($url)
            );

            exec($command . ' 2>&1', $output, $return_var);

            if ($return_var === 0) {
                outputMessage("订阅链接 {$url} 更新成功！文件已保存到: {$finalPath}");
            } else {
                outputMessage("配置更新失败！错误信息: " . implode("\n", $output));
            }
        } else {
            outputMessage("第" . ($index + 1) . "个订阅链接为空！");
        }

        file_put_contents($configFile, json_encode($subscriptionList));
    }
}
$updateCompleted = isset($_POST['saveSubscription']);
?>

<?php
$subscriptionPath = '/etc/neko/config/';
$dataFile = $subscriptionPath . 'subscription_data.json';

$message = "";
$defaultSubscriptions = [
    [
        'url' => '',
        'file_name' => 'config.json',
    ],
    [
        'url' => '',
        'file_name' => '',
    ],
    [
        'url' => '',
        'file_name' => '',
    ]
];

if (!file_exists($subscriptionPath)) {
    mkdir($subscriptionPath, 0755, true);
}

if (!file_exists($dataFile)) {
    file_put_contents($dataFile, json_encode(['subscriptions' => $defaultSubscriptions], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
}

$subscriptionData = json_decode(file_get_contents($dataFile), true);

if (!isset($subscriptionData['subscriptions']) || !is_array($subscriptionData['subscriptions'])) {
    $subscriptionData['subscriptions'] = $defaultSubscriptions;
}

if (isset($_POST['update_index'])) {
    $index = intval($_POST['update_index']);
    $subscriptionUrl = $_POST["subscription_url_$index"] ?? '';
    $customFileName = ($_POST["custom_file_name_$index"] ?? '') ?: 'config.json';

    if ($index < 0 || $index >= count($subscriptionData['subscriptions'])) {
        $message = "无效的订阅索引！";
    } elseif (empty($subscriptionUrl)) {
        $message = "订阅 $index 的链接为空！";
    } else {
        $subscriptionData['subscriptions'][$index]['url'] = $subscriptionUrl;
        $subscriptionData['subscriptions'][$index]['file_name'] = $customFileName;
        $finalPath = $subscriptionPath . $customFileName;

        $originalContent = file_exists($finalPath) ? file_get_contents($finalPath) : '';

        $ch = curl_init($subscriptionUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
        $fileContent = curl_exec($ch);
        $error = curl_error($ch);
        curl_close($ch);

        if ($fileContent === false) {
            $message = "订阅 $index 无法下载文件。cURL 错误信息: " . $error;
        } else {
            $fileContent = str_replace("\xEF\xBB\xBF", '', $fileContent);

            $parsedData = json_decode($fileContent, true);
            if ($parsedData === null && json_last_error() !== JSON_ERROR_NONE) {
                file_put_contents($finalPath, $originalContent);
                $message = "订阅 $index 解析 JSON 数据失败！错误信息: " . json_last_error_msg();
            } else {
                if (isset($parsedData['inbounds'])) {
                    $newInbounds = [];

                    foreach ($parsedData['inbounds'] as $inbound) {
                        if (isset($inbound['type']) && $inbound['type'] === 'mixed' && $inbound['tag'] === 'mixed-in') {
                            $newInbounds[] = $inbound;
                        } elseif (isset($inbound['type']) && $inbound['type'] === 'tun') {
                            continue;
                        }
                    }

                    $newInbounds[] = [
                      "tag" => "tun",
                      "type" => "tun",
                      "inet4_address" => "172.19.0.0/30",
                      "inet6_address" => "fdfe:dcba:9876::0/126",
                      "stack" => "system",
                      "auto_route" => true,
                      "strict_route" => true,
                      "sniff" => true,
                      "platform" => [
                        "http_proxy" => [
                          "enabled" => true,
                          "server" => "0.0.0.0",
                          "server_port" => 7890
                        ]
                      ]
                    ];

                    $newInbounds[] = [
                      "tag" => "mixed",
                      "type" => "mixed",
                      "listen" => "0.0.0.0",
                      "listen_port" => 7890,
                      "sniff" => true
                    ];

                    $parsedData['inbounds'] = $newInbounds;
                }

                if (isset($parsedData['experimental']['clash_api'])) {
                    $parsedData['experimental']['clash_api'] = [
                        "external_ui" => "/etc/neko/ui/",
                        "external_controller" => "0.0.0.0:9090",
                        "secret" => "Akun"
                    ];
                }

                $fileContent = json_encode($parsedData, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

                if (file_put_contents($finalPath, $fileContent) === false) {
                    $message = "订阅 $index 无法保存文件到: $finalPath";
                } else {
                    $message = "订阅 $index 更新成功！文件已保存到: {$finalPath}，并成功解析和替换 JSON 数据。";
                }
            }
        }

        file_put_contents($dataFile, json_encode($subscriptionData, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
    }
}
?>

<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme, 0, -4) ?>">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sing-box - Neko</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script src="./assets/js/feather.min.js"></script>
    <script src="./assets/js/jquery-2.1.3.min.js"></script>
    <script src="./assets/js/neko.js"></script>
    <script src="./assets/bootstrap/popper.min.js"></script>
    <script src="./assets/bootstrap/bootstrap.min.js"></script>
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
<div class="position-fixed w-100 d-flex justify-content-center" style="top: 20px; z-index: 1050">
    <div id="updateAlert" class="alert alert-success alert-dismissible fade" role="alert" 
         style="display: none; min-width: 300px; max-width: 600px; box-shadow: 0 2px 8px rgba(0,0,0,0.2);">
        <div class="d-flex align-items-center mb-2">
            <span class="spinner-border spinner-border-sm mr-2" role="status" aria-hidden="true"></span>
            <strong>更新完成</strong>
        </div>
        <div id="helpMessage" class="small" style="word-break: break-all;"></div>
        <div id="updateMessages" class="small mt-2" style="word-break: break-all;"></div>
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
            <span aria-hidden="true">×</span>
        </button>
    </div>
</div>

<div class="position-fixed w-100 d-flex justify-content-center" style="top: 60px; z-index: 1050">
    <div id="updateAlertSub" class="alert alert-success alert-dismissible fade" role="alert" style="display: none; min-width: 300px; max-width: 600px; box-shadow: 0 2px 8px rgba(0,0,0,0.2);">
        <div class="d-flex align-items-center mb-2">
            <span class="spinner-border spinner-border-sm mr-2" role="status" aria-hidden="true"></span>
            <strong>订阅更新完成</strong>
        </div>
        <div id="updateMessagesSub" class="small" style="word-break: break-all;">
        </div>
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
            <span aria-hidden="true">×</span>
        </button>
    </div>
</div>

<script>
function showUpdateAlert() {
    const alert = $('#updateAlert');
    const helpMessage = <?php echo json_encode($_SESSION['help_message'] ?? ''); ?>;
    const messages = <?php echo json_encode($_SESSION['notification_messages'] ?? []); ?>;
    $('#helpMessage').html(helpMessage);

    if (messages.length > 0) {
        const messagesHtml = messages.map(msg => `<div>${msg}</div>`).join('');
        $('#updateMessages').html(messagesHtml);
    }

    alert.show().addClass('show');
    setTimeout(function () {
        alert.removeClass('show');
        setTimeout(function () {
            alert.hide();
            $('#updateMessages').html('');
        }, 150);
    }, 18000);
}

<?php if ($updateCompleted): ?>
    $(document).ready(function () {
        showUpdateAlert();
    });
<?php endif; ?>
</script>
<style>
#updateAlert .close {
    color: white;
    opacity: 0.8;
    text-shadow: none;
    padding: 0;
    margin: 0;
    position: absolute;
    right: 10px;
    top: 10px;
    font-size: 1.2rem;
    width: 24px;
    height: 24px;
    line-height: 24px;
    text-align: center;
    border-radius: 50%;
    background-color: rgba(255, 255, 255, 0.2);
    transition: all 0.2s ease;
}

#updateAlert .close:hover {
    opacity: 1;
    background-color: rgba(255, 255, 255, 0.3);
    transform: rotate(90deg);
}

#updateAlert .close span {
    position: relative;
    top: -1px;
}

@media (max-width: 767px) {
    .row a {
        font-size: 9px; 
    }
}

.table-responsive {
    width: 100%;
}

.table th, .table td {
    vertical-align: middle;
    text-align: center;
    padding: 8px;
}

.btn-group .btn {
    flex: 1 1 auto;
    font-size: 12px;
    padding: 6px 8px;
}

@media (max-width: 767px) {
    .table th,
    .table td {
        padding: 6px 8px; 
        font-size: 14px;
    }

    .table th:nth-child(1), .table td:nth-child(1) {
        width: 25%; 
    }
    .table th:nth-child(2), .table td:nth-child(2) {
        width: 20%; 
    }
    .table th:nth-child(3), .table td:nth-child(3) {
        width: 25%; 
    }
    .table th:nth-child(4), .table td:nth-child(4) {
        width: 100%; 
    }

.btn-group, .d-flex {
    display: flex;
    flex-wrap: wrap; 
    justify-content: center;
    gap: 5px;
}

.btn-group .btn {
    flex: 1 1 auto; 
    font-size: 12px;
    padding: 6px 8px;
}

.btn-group .btn:last-child {
    margin-right: 0;
  }
}

@media (max-width: 767px) {
    .btn-rename {
    width: 70px !important; 
    font-size: 0.6rem; 
    white-space: nowrap; 
    overflow: hidden; 
    text-overflow: ellipsis; 
    display: inline-block;
    text-align: center; 
}

.btn-group {
    display: flex;
    gap: 10px; 
    justify-content: center; 
}

.btn {
    margin: 0; 
}

td {
    vertical-align: middle;
}

.action-btn {
    padding: 6px 12px; 
    font-size: 0.85rem; 
    display: inline-block;
}

.btn-group.d-flex {
    flex-wrap: wrap;
}
</style>

<div class="container-sm container-bg callout border border-3 rounded-4 col-11">
    <div class="row">
        <a href="./index.php" class="col btn btn-lg">🏠 首页</a>
        <a href="./mihomo_manager.php" class="col btn btn-lg">📂 Mihomo</a>
        <a href="./singbox_manager.php" class="col btn btn-lg">🗂️ Sing-box</a>
        <a href="./box.php" class="col btn btn-lg">💹 订阅转换</a>
        <a href="./filekit.php" class="col btn btn-lg">📦 文件助手</a>
    <div class="text-center">
      <h1 style="margin-top: 40px; margin-bottom: 20px;">Sing-box 文件管理</h1>
       <div class="card mb-4">
    <div class="card-body"> 
<div class="container">
    <h5>代理文件管理 ➤ p核专用</h5>
    <div class="table-responsive">
        <table class="table table-striped table-bordered text-center">
            <thead class="thead-dark">
                <tr>
                    <th style="width: 30%;">文件名</th>
                    <th style="width: 10%;">大小</th>
                    <th style="width: 20%;">修改时间</th>
                    <th style="width: 40%;">执行操作</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($proxyFiles as $file): ?>
                    <?php $filePath = $proxyDir . $file; ?>
                    <tr>
                        <td class="align-middle"><a href="download.php?file=<?php echo urlencode($file); ?>"><?php echo htmlspecialchars($file); ?></a></td>
                        <td class="align-middle"><?php echo file_exists($filePath) ? formatSize(filesize($filePath)) : '文件不存在'; ?></td>
                        <td class="align-middle"><?php echo htmlspecialchars(date('Y-m-d H:i:s', filemtime($filePath) + 8 * 60 * 60)); ?></td>
                        <td>
                            <div class="d-flex justify-content-center">
                                <form action="" method="post" class="d-inline">
                                    <input type="hidden" name="deleteFile" value="<?php echo htmlspecialchars($file); ?>">
                                    <button type="submit" class="btn btn-danger btn-sm mx-1" onclick="return confirm('确定要删除这个文件吗？');"><i>🗑️</i> 删除</button>
                                </form>
                                <form action="" method="post" class="d-inline">
                                    <input type="hidden" name="oldFileName" value="<?php echo htmlspecialchars($file); ?>">
                                    <input type="hidden" name="fileType" value="proxy">
                                    <button type="button" class="btn btn-success btn-sm mx-1 btn-rename" data-toggle="modal" data-target="#renameModal" data-filename="<?php echo htmlspecialchars($file); ?>" data-filetype="proxy"><i>✏️</i> 重命名</button>
                                </form>
                                 <form action="" method="post" class="d-inline">
                                    <button type="button" class="btn btn-warning btn-sm mx-1" onclick="openEditModal('<?php echo htmlspecialchars($file); ?>', 'proxy')"><i>📝</i> 编辑</button>
                                </form>
                                <form action="" method="post" enctype="multipart/form-data" class="d-inline upload-btn">
                                    <input type="file" name="fileInput" class="form-control-file" required id="fileInput-<?php echo htmlspecialchars($file); ?>" style="display: none;" onchange="this.form.submit()">
                                    <button type="button" class="btn btn-info btn-sm mx-1" onclick="document.getElementById('fileInput-<?php echo htmlspecialchars($file); ?>').click();"><i>📤</i> 上传</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<div class="container">
    <h5 class="text-center">配置文件管理</h5>
    <div class="table-responsive">
        <table class="table table-striped table-bordered text-center">
            <thead class="thead-dark">
                <tr>
                    <th style="width: 30%;">文件名</th>
                    <th style="width: 10%;">大小</th>
                    <th style="width: 20%;">修改时间</th>
                    <th style="width: 40%;">执行操作</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($configFiles as $file): ?>
                    <?php $filePath = $configDir . $file; ?>
                    <tr>
                        <td class="align-middle"><a href="download.php?file=<?php echo urlencode($file); ?>"><?php echo htmlspecialchars($file); ?></a></td>
                        <td class="align-middle"><?php echo file_exists($filePath) ? formatSize(filesize($filePath)) : '文件不存在'; ?></td>
                        <td class="align-middle"><?php echo htmlspecialchars(date('Y-m-d H:i:s', filemtime($filePath) + 8 * 60 * 60)); ?></td>
                        <td>
                            <div class="d-flex justify-content-center">
                                <form action="" method="post" class="d-inline">
                                    <input type="hidden" name="deleteConfigFile" value="<?php echo htmlspecialchars($file); ?>">
                                    <button type="submit" class="btn btn-danger btn-sm mx-1" onclick="return confirm('确定要删除这个文件吗？');"><i>🗑️</i> 删除</button>
                                </form>
                                <form action="" method="post" class="d-inline">
                                    <input type="hidden" name="oldFileName" value="<?php echo htmlspecialchars($file); ?>">
                                    <input type="hidden" name="fileType" value="config">
                                    <button type="button" class="btn btn-success btn-sm mx-1 btn-rename" data-toggle="modal" data-target="#renameModal" data-filename="<?php echo htmlspecialchars($file); ?>" data-filetype="config"><i>✏️</i> 重命名</button>
                                </form>
                                <form action="" method="post" class="d-inline">
                                   <button type="button" class="btn btn-warning btn-sm mx-1" onclick="openEditModal('<?php echo htmlspecialchars($file); ?>', 'config')"><i>📝</i> 编辑</button>
                                   </form>
                                <form action="" method="post" enctype="multipart/form-data" class="d-inline upload-btn">
                                    <input type="file" name="configFileInput" class="form-control-file" required id="fileInput-<?php echo htmlspecialchars($file); ?>" style="display: none;" onchange="this.form.submit()">
                                    <button type="button" class="btn btn-info btn-sm mx-1" onclick="document.getElementById('fileInput-<?php echo htmlspecialchars($file); ?>').click();"><i>📤</i> 上传</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<div class="modal fade" id="renameModal" tabindex="-1" role="dialog" aria-labelledby="renameModalLabel" aria-hidden="true">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="renameModalLabel">重命名文件</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <form id="renameForm" action="" method="post">
                    <input type="hidden" name="oldFileName" id="oldFileName">
                    <input type="hidden" name="fileType" id="fileType">
                    <div class="form-group">
                        <label for="newFileName">新文件名</label>
                        <input type="text" class="form-control" id="newFileName" name="newFileName" required>
                    </div>
                    <div class="form-group text-right">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">取消</button>
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

<div class="modal fade" id="editModal" tabindex="-1" role="dialog" aria-labelledby="editModalLabel" aria-hidden="true" data-backdrop="static" data-keyboard="false">
    <div class="modal-dialog modal-xl" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="editModalLabel">编辑文件: <span id="editingFileName"></span></h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <form id="editForm" action="" method="post" onsubmit="syncEditorContent()">
                    <textarea name="saveContent" id="fileContent" class="form-control" style="height: 500px;"></textarea>
                    <input type="hidden" name="fileName" id="hiddenFileName">
                    <input type="hidden" name="fileType" id="hiddenFileType">
                    <div class="mt-3">
                        <button type="submit" class="btn btn-primary">保存</button>
                        <button type="button" class="btn btn-pink" onclick="openFullScreenEditor()">高级编辑</button>
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
<h1 style="margin-top: 20px; margin-bottom: 20px;" title="只支持Sing-box格式的订阅">Sing-box 订阅</h1>

<style>
    #updateAlert .close,
    #updateAlertSub .close {
        color: white;
        opacity: 0.8;
        text-shadow: none;
        padding: 0;
        margin: 0;
        position: absolute;
        top: 10px;
        right: 10px;
        font-size: 1.2rem;
        width: 24px;
        height: 24px;
        line-height: 24px;
        text-align: center;
        border-radius: 50%;
        background-color: rgba(255, 255, 255, 0.2);
        transition: all 0.2s ease;
    }

    #updateAlert .close:hover,
    #updateAlertSub .close:hover {
        opacity: 1;
        background-color: rgba(255, 255, 255, 0.3);
        transform: rotate(90deg);
    }

    #updateAlert .close span,
    #updateAlertSub .close span {
        position: relative;
        top: -1px;
    }
    
 </style>
</head>
<body>
        <?php if ($message): ?>
            <p><?php echo nl2br(htmlspecialchars($message)); ?></p>
        <?php endif; ?>
<form method="post">
    <div class="row">
        <?php for ($i = 0; $i < 3; $i++): ?>
            <div class="col-md-4 mb-3">
                <div class="card subscription-card p-2">
                    <div class="card-body p-2">
                        <h6 class="card-title text-primary">订阅链接 <?php echo $i + 1; ?></h6>
                        <div class="form-group mb-2">
                            <input type="text" name="subscription_url_<?php echo $i; ?>" id="subscription_url_<?php echo $i; ?>" class="form-control form-control-sm white-text" placeholder="订阅链接" value="<?php echo htmlspecialchars($subscriptionData['subscriptions'][$i]['url'] ?? ''); ?>">
                        </div>
                        <div class="form-group mb-2">
                            <label for="custom_file_name_<?php echo $i; ?>" class="text-primary">自定义文件名 <?php echo ($i === 0) ? '(固定为 config.json)' : ''; ?></label>
                            <input type="text" name="custom_file_name_<?php echo $i; ?>" id="custom_file_name_<?php echo $i; ?>" class="form-control form-control-sm white-text" value="<?php echo htmlspecialchars($subscriptionData['subscriptions'][$i]['file_name'] ?? ($i === 0 ? 'config.json' : '')); ?>" <?php echo ($i === 0) ? 'readonly' : ''; ?>>
                        </div>
                        <button type="submit" name="update_index" value="<?php echo $i; ?>" class="btn btn-info btn-sm"><i>🔄</i> 更新订阅 <?php echo $i + 1; ?></button>
                    </div>
                </div>
            </div>
        <?php endfor; ?>
    </div>
</form>

<h2 class="text-success text-center mt-4 mb-4">订阅管理 ➤ p核专用</h2>
<div class="help-text mb-3 text-start">
    <strong>1. 对于首次使用 Sing-box 的用户，必须将核心更新至版本 v1.10.0 或更高版本。我们建议使用 P 核心。确保将出站和入站防火墙规则都设置为“接受”并启用它们。
</div>
<div class="help-text mb-3 text-start">
    <strong>2. 注意：</strong> 通用模板（<code>puernya.json</code>）最多支持<strong>3个</strong>订阅链接，请勿更改默认名称。
</div>
<div class="help-text mb-3 text-start"> 
    <strong>3. 支持通用格式订阅，无需转换。
</div>
<div class="help-text mb-3 text-start"> 
    <strong>4. 保存与更新：</strong> 填写完毕后，请点击"更新配置"按钮进行保存。
</div>
<div class="row">
    <?php for ($i = 0; $i < 3; $i++): ?>
        <div class="col-md-4 mb-4">
            <div class="card">
                <div class="card-body">
                    <h5 class="card-title">订阅链接 <?php echo ($i + 1); ?></h5>
                    <form method="post">
                        <div class="input-group mb-3">
                            <input type="text" name="subscription_url" id="subscriptionurl<?php echo $i; ?>" 
                                   value="<?php echo htmlspecialchars($subscriptionList[$i]['url']); ?>" 
                                   required class="form-control" placeholder="输入链接">
                            <input type="text" name="custom_file_name" id="custom_filename<?php echo $i; ?>" 
                                   value="<?php echo htmlspecialchars($subscriptionList[$i]['file_name']); ?>" 
                                   class="form-control" placeholder="自定义文件名">
                            <input type="hidden" name="index" value="<?php echo $i; ?>">
                            <button type="submit" name="saveSubscription" class="btn btn-success ml-2">
                                <i>🔄</i> 更新
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    <?php endfor; ?>
</div>









