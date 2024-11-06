<?php

include './cfg.php';

$themeDir = "$neko_www/assets/theme";
$tmpPath = "$neko_www/lib/selected_config.txt";
$arrFiles = array();
$arrFiles = glob("$themeDir/*.css");

for($x=0;$x<count($arrFiles);$x++) $arrFiles[$x] = substr($arrFiles[$x], strlen($themeDir)+1);

if(isset($_POST['themechange'])){
    $dt = $_POST['themechange'];
    shell_exec("echo $dt > $neko_www/lib/theme.txt");
    $neko_theme = $dt;
}
if(isset($_POST['fw'])){
    $dt = $_POST['fw'];
    if ($dt == 'enable') shell_exec("uci set neko.cfg.new_interface='1' && uci commit neko");
    if ($dt == 'disable') shell_exec("uci set neko.cfg.new_interface='0' && uci commit neko");
}
$fwstatus=shell_exec("uci get neko.cfg.new_interface");
?>
<?php
function getSingboxVersion() {
    $singBoxPath = '/usr/bin/sing-box'; 
    $command = "$singBoxPath version 2>&1";
    exec($command, $output, $returnVar);
    
    if ($returnVar === 0) {
        foreach ($output as $line) {
            if (strpos($line, 'version') !== false) {
                $parts = explode(' ', $line);
                return end($parts);
            }
        }
    }
    
    return '未知版本';
}

$singBoxVersion = getSingboxVersion();
?>

<?php

function getUiVersion() {
    $versionFile = '/etc/neko/ui/metacubexd/version.txt';
    
    if (file_exists($versionFile)) {
        return trim(file_get_contents($versionFile));
    } else {
        return "版本文件不存在";
    }
}

$uiVersion = getUiVersion();
?>

<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme,0,-4) ?>">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Settings - Neko</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/bootstrap/bootstrap.bundle.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/neko.js"></script>
    <?php include './ping.php'; ?>
  </head>
  <body>
    <div class="container-sm container-bg text-center callout border border-3 rounded-4 col-11">
        <div class="row">
            <a href="./" class="col btn btn-lg">🏠 首页</a>
            <a href="./dashboard.php" class="col btn btn-lg">📊 面板</a>
            <a href="./configs.php" class="col btn btn-lg">⚙️ 配置</a>
            <a href="/nekobox/mon.php" class="col btn btn-lg d-flex align-items-center justify-content-center"></i>📦 订阅</a> 
            <a href="#" class="col btn btn-lg">🛠️ 设定</a>
         <div class="container px-4">
    <h2 class="text-center p-2 mb-3">主题设定</h2>
    <form action="settings.php" method="post">
        <div class="text-center justify-content-md-center">
            <div class="row justify-content-md-center">
                <div class="col mb-3 justify-content-md-center">
                    <select class="form-select" name="themechange" aria-label="themex">
                        <option selected>Change Theme (<?php echo $neko_theme ?>)</option>
                        <?php foreach ($arrFiles as $file) echo "<option value=\"".$file.'">'.$file."</option>" ?>
                    </select>
                </div>
                <div class="row justify-content-md-center">
                    <div class="col justify-content-md-center mb-3">
                        <input class="btn btn-info" type="submit" value="🖫 更改主题">
                    </div>
                </div>
            </div>
        </div>
    </form>   
    <div class="card mb-4">
    <div class="card-body"> 
    <table class="table table-borderless mb-3">
        <tbody>
            <tr>
                <td colspan="2">
                    <h2 class="text-center mb-3">自动重载防火墙</h2>
                    <form action="settings.php" method="post">
                        <div class="btn-group d-flex justify-content-center">
                            <button type="submit" name="fw" value="enable" class="btn btn<?php if($fwstatus==1) echo "-outline" ?>-success <?php if($fwstatus==1) echo "disabled" ?>">启用</button>
                            <button type="submit" name="fw" value="disable" class="btn btn<?php if($fwstatus==0) echo "-outline" ?>-danger <?php if($fwstatus==0) echo "disabled" ?>">停用</button>
                        </div>
                    </form>
                </td>
            </tr>
            <tr>
                <td colspan="2">
                    <div class="row g-4">
                        <div class="col-md-6 mb-3">
                            <div class="text-center">
                                <h3>客户端版本</h3>
                                <div class="form-control text-center" style="font-family: monospace; text-align: center;">
                                    <span id="cliver"></span>&nbsp;<span id="NewCliver"> </span>
                                </div>
                                <div class="text-center mt-2">
                                    <button class="btn btn-pink" id="checkCliverButton">🔍 检测版本</button>
                                    <button class="btn btn-info" id="updateButton" title="更新到最新版本">🔄 更新版本</button>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6 mb-3">
                            <div class="text-center">
                                <h3>Metacubexd 面板</h3>
                                <div class="form-control text-center">
                                    <?php echo htmlspecialchars($uiVersion); ?>&nbsp;<span id="NewUi"> </span>
                                </div>
                                <div class="text-center mt-2">
                                    <button class="btn btn-pink" id="checkUiButton">🔍 检测版本</button> 
                                    <button class="btn btn-info" id="updateUiButton" title="更新 Metacubexd 面板">🔄 更新版本</button>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6 mb-3">
                            <div class="text-center">
                                <h3>Sing-box 核心版本</h3>
                                <div class="form-control text-center">
                                    <div id="singBoxCorever">
                                        <?php echo htmlspecialchars($singBoxVersion); ?>&nbsp;<span id="NewSingbox"></span>
                                    </div>
                                </div>
                                <div class="text-center mt-2">
                                    <button class="btn btn-pink" id="checkSingboxButton">🔍 检测版本</button>
                                    <button class="btn btn-info" id="singboxOptionsButton" title="Singbox 相关操作">🔄 更新版本</button>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6 mb-3">
                            <div class="text-center">
                                <h3>Mihomo 核心版本</h3>
                                <div class="form-control text-center">
                                    <span id="corever"></span>&nbsp;<span id="NewMihomo"> </span>
                                </div>
                                <div class="text-center mt-2">
                                    <button class="btn btn-pink" id="checkMihomoButton">🔍 检测版本</button> 
                                    <button class="btn btn-info" id="updateCoreButton" title="更新 Mihomo 内核">🔄 更新版本</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </td>
            </tr>
        </tbody>
    </table>

<div class="modal fade" id="optionsModal" tabindex="-1" aria-labelledby="optionsModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="optionsModalLabel">选择操作</h5>
                <button type="button" class="close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <div class="d-grid gap-2">
                    <button class="btn btn-info" onclick="selectOperation('singbox')">更新 Singbox 内核（官方稳定版）</button>
                    <button class="btn btn-success" onclick="selectOperation('sing-box')">更新 Singbox 内核（未编译版本）</button>
                    <button class="btn btn-success" onclick="selectOperation('puernya')">切换 Puernya 内核</button>
                    <button class="btn btn-primary" onclick="selectOperation('rule')">更新 Singbox 规则集</button>
                    <button class="btn btn-primary" onclick="selectOperation('config')">更新 Mihomo 配置文件</button>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="updateModal" tabindex="-1" aria-labelledby="updateModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="updateModalLabel">更新状态</h5>
                <button type="button" class="close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body text-center">
                <div id="updateDescription" class="alert alert-info mb-3"></div>
                <pre id="logOutput" style="white-space: pre-wrap; word-wrap: break-word; text-align: left; display: inline-block;">等待操作开始...</pre>
                <div class="alert alert-info mt-3" role="alert">
                    提示: 如遇到更新失败，请在终端输入 <code>nekobox</code> 进行更新！
                </div>
            </div>
        </div>
    </div>
</div>

<div id="logOutput" class="mt-3"></div>

<style>
    .table-container {
        overflow-x: auto;
    }

    .table {
        width: 100%;
        border-collapse: collapse;
    }

    .table td {
        padding: 10px;
        word-wrap: break-word;
    }

    .form-control {
        width: 100%;
    }

    .btn {
        white-space: nowrap;
        flex: 1;
    }

    @media (max-width: 767px) {
        .table td {
            display: block;
            width: 100%;
        }

        .form-control {
            display: flex;
            flex-direction: column;
        }

        .btn-group {
            flex-direction: column;
        }
    }

</style>

<script>
document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('singboxOptionsButton').addEventListener('click', function() {
        $('#optionsModal').modal('show');
    });

    document.getElementById('updateButton').addEventListener('click', function() {
        initiateUpdate('update_script.php', '开始下载客户端更新...', '正在更新客户端到最新版本');
    });

    document.getElementById('updateUiButton').addEventListener('click', function() {
        initiateUpdate('ui.php', '开始下载 UI 面板更新...', '正在更新 Metacubexd 面板到最新版本');
    });

    document.getElementById('updateCoreButton').addEventListener('click', function() {
        initiateUpdate('core.php', '开始下载 Mihomo 核心更新...', '正在更新 Mihomo 核心到最新版本');
    });
});

function selectOperation(type) {
    $('#optionsModal').modal('hide');
    
    const operations = {
        'singbox': {
            url: 'update_singbox_core.php',
            message: '开始下载 Singbox 核心更新...',
            description: '正在更新 Singbox 核心到最新版本'
        },
        'sing-box': {
            url: 'singbox.php',
            message: '开始下载 Singbox 核心更新...',
            description: '正在更新 Singbox 核心到最新版本'
        },
        'puernya': {
            url: 'puernya.php',
            message: '开始切换 Puernya 核心...',
            description: '正在切换到 Puernya 内核，此操作将替换当前的 Singbox 核心'
        },
        'rule': {
            url: 'update_rule.php',
            message: '开始下载 Singbox 规则集...',
            description: '正在更新 Singbox 规则集，配合 Puernya 内核可以使用 Singbox 的配置文件和本地规则集'
        },
        'config': {
            url: 'update_config.php',
            message: '开始下载 Mihomo 配置文件...',
            description: '正在更新 Mihomo 配置文件到最新版本'
        }
    };

    const operation = operations[type];
    if (operation) {
        setTimeout(function() {
            initiateUpdate(operation.url, operation.message, operation.description);
        }, 500);
    }
}

function initiateUpdate(url, logMessage, description) {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', url, true);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');

    $('#updateModal').modal('show');
    document.getElementById('updateDescription').textContent = description;
    document.getElementById('logOutput').textContent = logMessage;

    xhr.onload = function() {
        if (xhr.status === 200) {
            document.getElementById('logOutput').textContent += '\n更新完成！';
            document.getElementById('logOutput').textContent += '\n' + xhr.responseText;

            setTimeout(function() {
                $('#updateModal').modal('hide');
                setTimeout(function() {
                    location.reload();
                }, 500);
            }, 10000);
        } else {
            document.getElementById('logOutput').textContent += '\n发生错误：' + xhr.statusText;
        }
    };

    xhr.onerror = function() {
        document.getElementById('logOutput').textContent += '\n网络错误，请稍后再试。';
    };

    xhr.send();
}
</script>

<script>
    function checkVersion(buttonId, outputId, url) {
        document.getElementById(outputId).innerHTML = '正在检查新版本...';

        var xhr = new XMLHttpRequest();
        xhr.open('GET', url + '?check_version=true', true);
        xhr.onload = function() {
            if (xhr.status === 200) {
                document.getElementById(outputId).innerHTML = xhr.responseText;
            } else {
                document.getElementById(outputId).innerHTML = '版本检测失败，请稍后重试。';
            }
        };
        xhr.onerror = function() {
            document.getElementById(outputId).innerHTML = '网络错误，请稍后重试';
        };
        xhr.send();
    }

    document.getElementById('checkCliverButton').addEventListener('click', function() {
        checkVersion('checkCliverButton', 'NewCliver', 'update_script.php');
    });

    document.getElementById('checkMihomoButton').addEventListener('click', function() {
        checkVersion('checkMihomoButton', 'NewMihomo', 'core.php');
    });

    document.getElementById('checkSingboxButton').addEventListener('click', function() {
        checkVersion('checkSingboxButton', 'NewSingbox', 'singbox.php');
    });

    document.getElementById('checkUiButton').addEventListener('click', function() {
        checkVersion('checkUiButton', 'NewUi', 'ui.php');
    });
</script>

<script>
    function compareVersions(v1, v2) {
        const v1parts = v1.split(/[-.]/).filter(x => !isNaN(x)); 
        const v2parts = v2.split(/[-.]/).filter(x => !isNaN(x)); 
        
        for (let i = 0; i < Math.max(v1parts.length, v2parts.length); ++i) {
            const v1part = parseInt(v1parts[i]) || 0;  
            const v2part = parseInt(v2parts[i]) || 0;  
            
            if (v1part > v2part) return 1;
            if (v1part < v2part) return -1;
        }
        
        return 0; 
    }

    function checkSingboxVersion() {
        var currentVersion = '<?php echo getSingboxVersion(); ?>';
        var minVersion = '1.10.0'; 
        
        if (compareVersions(currentVersion, minVersion) >= 0) {
            return;
        }

        var modalHtml = `
            <div class="modal fade" id="versionWarningModal" tabindex="-1" aria-labelledby="versionWarningModalLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title" id="versionWarningModalLabel">版本警告</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body">
                            <p>您的 Sing-box 版本 (${currentVersion}) 低于推荐的最低版本 (v1.10.0)。</p>
                            <p>请考虑升级到更高版本以获得最佳性能。</p>
                        </div>
                    </div>
                </div>
            </div>
        `;
        document.body.insertAdjacentHTML('beforeend', modalHtml);
        var modal = new bootstrap.Modal(document.getElementById('versionWarningModal'));
        modal.show();
        
        setTimeout(function() {
            modal.hide();
        }, 5000);
    }

    document.addEventListener('DOMContentLoaded', checkSingboxVersion);
</script>

<!DOCTYPE html>
<html lang="zh">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NekoBox</title>
    <link rel="stylesheet" href="/www/nekobox/assets/css/bootstrap.min.css">
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
        }
        .feature-box {
            padding: 15px;
            margin-bottom: 20px;
            border: 1px solid #000000;
            border-radius: 8px;
        }
        .feature-box h6 {
            margin-bottom: 15px;
        }
        .table-container {
            padding: 15px;
            margin-bottom: 20px;
            border: 1px solid #000000;
            border-radius: 8px;
        }
        .table {
            table-layout: fixed;
            width: 100%;
        }
        .table td, .table th {
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .table thead th {
            background-color: transparent;
            color: #000000;
        }
        .btn-outline-secondary {
            border-color: transparent;
            color: #000000;
        }
        .btn-outline-secondary:hover {
            background-color: transparent;
            color: #000000;
        }
        .footer {
            padding: 15px 0;
            background-color: transparent;
            color: #000000;
        }
        .footer p {
            margin: 0;
        }
        .link-box {
            border: 1px solid #000000;
            border-radius: 8px;
            padding: 10px;
            display: block;
            text-align: center;
            width: 100%;
            box-sizing: border-box; 
            transition: background-color 0.3s ease; 
        }
        .link-box a {
            display: block;
            padding: 10px;
            text-decoration: none;
            color: #000000;
        }
        .container {
            padding-left: 10px;
            padding-right: 10px;
        }
    </style>
</head>
<body>
    <div class="container mt-4">
        <h2 class="text-center mb-4">关于 NekoBox</h2>
        <div class="feature-box text-center">
            <h5>NekoBox</h5>
            <p>NekoBox是一款精心设计的 Sing-box 代理工具，专为家庭用户打造，旨在提供简洁而强大的代理解决方案。基于 PHP 和 BASH 技术，NekoBox 将复杂的代理配置简化为直观的操作体验，让每个用户都能轻松享受高效、安全的网络环境。</p>
        </div>

        <h5 class="text-center mb-4">核心特点</h5>
        <div class="row">
            <div class="col-md-4 mb-4 d-flex">
                <div class="feature-box text-center flex-fill">
                    <h6>简化配置</h6>
                    <p>采用用户友好的界面和智能配置功能，轻松实现 Sing-box 代理的设置与管理。</p>
                </div>
            </div>
            <div class="col-md-4 mb-4 d-flex">
                <div class="feature-box text-center flex-fill">
                    <h6>优化性能</h6>
                    <p>通过高效的脚本和自动化处理，确保最佳的代理性能和稳定性。</p>
                </div>
            </div>
            <div class="col-md-4 mb-4 d-flex">
                <div class="feature-box text-center flex-fill">
                    <h6>无缝体验</h6>
                    <p>专为家庭用户设计，兼顾易用性与功能性，确保每个家庭成员都能便捷地使用代理服务。</p>
                </div>
            </div>
        </div>

<h5 class="text-center mb-4">工具信息</h5>
<div class="d-flex justify-content-center">
    <div class="table-container">
        <table class="table table-borderless mb-5">
            <tbody>
                <tr class="text-center">
                    <td>SagerNet</td>
                    <td>MetaCubeX</td>
                </tr>
                <tr class="text-center">
                    <td>
                        <div class="link-box">
                            <a href="https://github.com/SagerNet/sing-box" target="_blank">Sing-box</a>
                        </div>
                    </td>
                    <td>
                        <div class="link-box">
                            <a href="https://github.com/MetaCubeX/mihomo" target="_blank">Mihomo</a>
                        </div>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</div>
    <h5 class="text-center mb-4">外部链接</h5>
        <div class="table-container">
            <table class="table table-borderless mb-5">
                <tbody>
                    <tr class="text-center">
                        <td>Github</td>
                        <td>Github</td>
                    </tr>
                    <tr class="text-center">
                        <td>
                            <div class="link-box">
                                <a href="https://github.com/Thaolga/openwrt-nekobox/issues" target="_blank">Issues</a>
                            </div>
                        </td>
                        <td>
                            <div class="link-box">
                                <a href="https://github.com/Thaolga/openwrt-nekobox" target="_blank">Thaolga</a>
                            </div>
                        </td>
                    </tr>
                    <tr class="text-center">
                        <td>Telegram</td>
                        <td>MetaCubeX</td>
                    </tr>
                    <tr class="text-center">
                        <td>
                            <div class="link-box">
                                <a href="https://t.me/+J55MUupktxFmMDgx" target="_blank">Telegram</a>
                            </div>
                        </td>
                        <td>
                            <div class="link-box">
                                <a href="https://github.com/MetaCubeX" target="_blank">METACUBEX</a>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
      <footer class="text-center">
    <p><?php echo $footer ?></p>
</footer>
    </div>

    <script src="/www/nekobox/assets/js/bootstrap.bundle.min.js"></script>
</body>
</html>
