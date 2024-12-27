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
                $version = end($parts);
                
                if (strpos($version, 'alpha') !== false || strpos($version, 'beta') !== false) {
                    if (strpos($version, '1.10.0-alpha.29-067c81a7') !== false) {
                        return ['version' => $version, 'type' => 'Puernya 预览版'];
                    }
                    return ['version' => $version, 'type' => 'Singbox 预览版'];
                } else {
                    return ['version' => $version, 'type' => 'Singbox 正式版'];
                }
            }
        }
    }
    
    return ['version' => '未安装', 'type' => '未知'];
}

function getMihomoVersion() {
    $mihomoPath = '/usr/bin/mihomo';
    $command = "$mihomoPath -v 2>&1";  
    exec($command, $output, $returnVar);

    if ($returnVar === 0) {
        foreach ($output as $line) {
            if (strpos($line, 'Mihomo') !== false) {
                preg_match('/alpha-[a-z0-9]+/', $line, $matches);
                if (!empty($matches)) {
                    $version = $matches[0];  
                    return ['version' => $version, 'type' => '预览版'];
                }
                
                preg_match('/([0-9]+(\.[0-9]+)+)/', $line, $matches);
                if (!empty($matches)) {
                    $version = $matches[0];  
                    return ['version' => $version, 'type' => '正式版'];
                }
            }
        }
    }

    return ['version' => '未安装', 'type' => '未知']; 
}

function getUiVersion() {
    $versionFile = '/etc/neko/ui/zashboard/version.txt';
    
    if (file_exists($versionFile)) {
        return trim(file_get_contents($versionFile));
    } else {
        return "未安装";
    }
}

function getMetaCubexdVersion() {
    $versionFile = '/etc/neko/ui/metacubexd/version.txt';
    
    if (file_exists($versionFile)) {
        return trim(file_get_contents($versionFile));
    } else {
        return "未安装";
    }
}

function getMetaVersion() {
    $versionFile = '/etc/neko/ui/meta/version.txt';
    
    if (file_exists($versionFile)) {
        return trim(file_get_contents($versionFile));
    } else {
        return "未安装";
    }
}

function getRazordVersion() {
    $versionFile = '/etc/neko/ui/dashboard/version.txt';
    
    if (file_exists($versionFile)) {
        return trim(file_get_contents($versionFile));
    } else {
        return "未安装";
    }
}

function getCliverVersion() {
    $versionFile = '/etc/neko/tmp/nekobox_version';
    
    if (file_exists($versionFile)) {
        $version = trim(file_get_contents($versionFile));
        
        if (preg_match('/-cn$|en$/', $version)) {
            return ['version' => $version, 'type' => '正式版'];
        } elseif (preg_match('/-preview$|beta$/', $version)) {
            return ['version' => $version, 'type' => '预览版'];
        } else {
            return ['version' => $version, 'type' => '未知'];
        }
    } else {
        return ['version' => '未安装', 'type' => '未知'];
    }
}

$cliverData = getCliverVersion();
$cliverVersion = $cliverData['version']; 
$cliverType = $cliverData['type']; 
$singBoxVersionInfo = getSingboxVersion();
$singBoxVersion = $singBoxVersionInfo['version'];
$singBoxType = $singBoxVersionInfo['type'];
$puernyaVersion = ($singBoxType === 'Puernya 预览版') ? $singBoxVersion : '未安装';
$singboxPreviewVersion = ($singBoxType === 'Singbox 预览版') ? $singBoxVersion : '未安装';
$mihomoVersionInfo = getMihomoVersion();
$mihomoVersion = $mihomoVersionInfo['version'];
$mihomoType = $mihomoVersionInfo['type'];
$uiVersion = getUiVersion();
$metaCubexdVersion = getMetaCubexdVersion();
$metaVersion = getMetaVersion();
$razordVersion = getRazordVersion();

?>

<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme,0,-4) ?>">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Settings - Nekobox</title>
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
<style>
    .form-select {
        margin-left: 10px;
        margin-right: 16px;
    }
</style>
  <body>
    <div class="container-sm container-bg text-center callout border border-3 rounded-4 col-11">
        <div class="row">
            <a href="./index.php" class="col btn btn-lg">🏠 首页</a>
            <a href="./dashboard.php" class="col btn btn-lg">📊 面板</a>
            <a href="./configs.php" class="col btn btn-lg">⚙️ 配置</a>
            <a href="./singbox.php" class="col btn btn-lg"></i>📦 订阅</a> 
            <a href="./settings.php" class="col btn btn-lg">🛠️ 设定</a>
<div class="container px-4">
    <h2 class="text-center p-2 mb-4">主题设定</h2>
    <form action="settings.php" method="post">
        <div class="row justify-content-center">
            <div class="col-12 col-md-6 mb-3">
                <select class="form-select" name="themechange" aria-label="themex">
                    <option selected>Change Theme (<?php echo $neko_theme ?>)</option>
                    <?php foreach ($arrFiles as $file) echo "<option value=\"".$file.'">'.$file."</option>" ?>
                </select>
            </div>
            <div class="col-12 col-md-6 mb-3" style="padding-right: 1.3rem;" >
                <div class="d-grid">
                    <input class="btn btn-info" type="submit" value="🖫 更改主题">
                </div>
            </div>
        </div>
    </form>
    <table class="table table-borderless mb-3">
        <tbody>
            <tr>
                <td colspan="2">
                    <h2 class="text-center mb-3">自动重载防火墙</h2>
                    <form action="settings.php" method="post">
                        <div class="btn-group d-flex justify-content-center">
                            <button type="submit" name="fw" value="enable" class="btn btn<?php if($fwstatus==1) echo "-outline" ?>-success <?php if($fwstatus==1) echo "disabled" ?>" style="margin-right: 20px;">启用</button>
                            <button type="submit" name="fw" value="disable" class="btn btn<?php if($fwstatus==0) echo "-outline" ?>-danger <?php if($fwstatus==0) echo "disabled" ?>">停用</button>
                         </div>
                     </form>
                 </td>
             </tr>
         <tr>
     <tr>
    <td>
        <table class="table">
            <thead>
                <tr>
                    <th>客户端版本</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td class="text-center" style="font-family: monospace;">
                        <span id="cliver"></span><span id="NewCliver"> </span>
                    </td>
                </tr>
                <tr>
                    <td class="text-center">
                        <button class="btn btn-pink" id="checkCliverButton">🔍 检测版本</button>
                        <button class="btn btn-info" id="updateButton" title="更新到最新版本" onclick="showVersionTypeModal()">🔄 更新版本</button>
                    </td>
                </tr>
            </tbody>
        </table>
    </td>
    <td>
        <table class="table">
            <thead>
                <tr>
                    <th>UI 控制面板</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td class="text-center">
                        <?php echo htmlspecialchars($uiVersion); ?><span id="NewUi"> </span>
                    </td>
                </tr>
                <tr>
                    <td class="text-center">
                        <button class="btn btn-pink" id="checkUiButton">🔍 检测版本</button>
                        <button class="btn btn-info" id="updateUiButton" title="更新面板" onclick="showPanelSelector()">🔄 更新版本</button>
                    </td>
                </tr>
            </tbody>
        </table>
    </td>
</tr>
<tr>
    <td>
        <table class="table">
            <thead>
                <tr>
                    <th>Sing-box 核心版本</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td class="text-center">
                        <div id="singBoxCorever">
                            <?php echo htmlspecialchars($singBoxVersion); ?><span id="NewSingbox"></span>
                        </div>
                    </td>
                </tr>
                <tr>
                    <td class="text-center">
                        <button class="btn btn-pink" id="checkSingboxButton">🔍 检测版本</button>
                        <button class="btn btn-info" id="singboxOptionsButton" title="Singbox 相关操作">🔄 更新版本</button>
                    </td>
                </tr>
            </tbody>
        </table>
    </td>
    <td>
        <table class="table">
            <thead>
                <tr>
                    <th>Mihomo 核心版本</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td class="text-center">
                        <span id="corever"></span><span id="NewMihomo"> </span>
                    </td>
                </tr>
                <tr>
                    <td class="text-center">
                        <button class="btn btn-pink" id="checkMihomoButton">🔍 检测版本</button>
                        <button class="btn btn-info" id="updateCoreButton" title="更新 Mihomo 内核" onclick="showMihomoVersionSelector()">🔄 更新版本</button>
                    </td>
                </tr>
            </tbody>
        </table>
    </td>
</tr>
</tbody>
</table>
<div class="modal fade" id="updateVersionTypeModal" tabindex="-1" aria-labelledby="updateVersionTypeModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="updateVersionTypeModalLabel">选择更新版本类型</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="form-group text-center">
                    <button id="stableBtn" class="btn btn-success btn-lg" style="margin: 10px;" onclick="selectVersionType('stable')">正式版</button>
                    <button id="previewBtn" class="btn btn-warning btn-lg" style="margin: 10px;" onclick="selectVersionType('preview')">预览版</button>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="updateLanguageModal" tabindex="-1" aria-labelledby="updateLanguageModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="updateLanguageModalLabel">选择语言</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label for="languageSelect">选择语言</label>
                    <select id="languageSelect" class="form-select">
                        <option value="cn">中文版</option>
                        <option value="en">英文版</option> 
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-primary" onclick="confirmLanguageSelection()">确认</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="previewLanguageModal" tabindex="-1" aria-labelledby="previewLanguageModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="previewLanguageModalLabel">选择预览版语言</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label for="previewLanguageSelect">选择语言</label>
                    <select id="previewLanguageSelect" class="form-select">
                        <option value="cn">中文预览版</option>
                        <option value="en">英文预览版</option>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-primary" onclick="confirmPreviewLanguageSelection()">确认</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="mihomoVersionSelectionModal" tabindex="-1" aria-labelledby="mihomoVersionSelectionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="mihomoVersionSelectionModalLabel">选择 Mihomo 内核版本</h5>
                <button type="button" class="close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <select id="mihomoVersionSelect" class="form-select">
                    <option value="stable">正式版</option>
                    <option value="preview">预览版</option>
                </select>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-primary" onclick="confirmMihomoVersion()">确认</button>
            </div>
        </div>
    </div>
</div>

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
                <p class="text-warning">
                    <strong>说明：</strong> 请优先选择通道一编译版本进行更新，以确保兼容性。系统会先检测并动态生成最新版本号供选择下载。 如果通道一更新不可用，可以尝试通道二版本。
                </p>
                <div class="d-grid gap-2">
                    <button class="btn btn-info" onclick="showSingboxVersionSelector()">更新 Singbox 内核（通道一）</button>
                    <button class="btn btn-success" onclick="showSingboxVersionSelectorForChannelTwo()">更新 Singbox 内核（通道二）</button>
                    <button type="button" class="btn btn-warning" id="operationOptionsButton">其他操作</button>
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="operationModal" tabindex="-1" aria-labelledby="operationModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="operationModalLabel">选择操作</h5>
                <button type="button" class="close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <p class="text-warning">
                    <strong>说明：</strong> 请根据需求选择操作。
                </p>
                <div class="d-grid gap-2">
                    <button class="btn btn-success" onclick="selectOperation('puernya')">切换 Puernya 内核</button>
                    <button class="btn btn-primary" onclick="selectOperation('rule')">更新 P核 规则集</button>
                    <button class="btn btn-primary" onclick="selectOperation('config')">更新配置文件（备用）</button>
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="versionSelectionModal" tabindex="-1" aria-labelledby="versionSelectionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="versionSelectionModalLabel">选择 Singbox 内核版本 （编译通道一）</h5>
                <button type="button" class="close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <div class="mb-3">
                    <select id="singboxVersionSelect" class="form-select w-100" style="transform: translateX(-10px);"> 
                        <option value="v1.11.0-alpha.10">v1.11.0-alpha.10</option>
                        <option value="v1.11.0-alpha.15">v1.11.0-alpha.15</option>
                        <option value="v1.11.0-alpha.20">v1.11.0-alpha.20</option>
                        <option value="v1.11.0-beta.5">v1.11.0-beta.5</option>
                        <option value="v1.11.0-beta.10">v1.11.0-beta.10</option>
                    </select>
                </div>
                <div class="mb-3">
                    <label for="manualVersionInput" class="form-label">输入自定义版本</label> 
                    <input type="text" id="manualVersionInput" class="form-control w-100" value="例如：v1.11.0-beta.12">
                </div>
                <button type="button" class="btn btn-secondary mt-2" onclick="addManualVersion()">添加版本</button>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-primary" onclick="confirmSingboxVersion()">确认</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="singboxVersionModal" tabindex="-1" aria-labelledby="singboxVersionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="singboxVersionModalLabel">选择 Singbox 核心版本（官方通道二）</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label for="singboxVersionSelectForChannelTwo">选择版本</label>
                    <select id="singboxVersionSelectForChannelTwo" class="form-select">
                        <option value="preview" selected>预览版</option>  
                        <option value="stable">正式版</option>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
                <button type="button" class="btn btn-primary" onclick="confirmSingboxVersionForChannelTwo()">确认</button>
            </div>
        </div>
    </div>
</div>

<div id="panelSelectionModal" class="modal fade" tabindex="-1" aria-labelledby="panelSelectionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="panelSelectionModalLabel">选择面板</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label for="panelSelect">选择一个面板</label>
                    <select id="panelSelect" class="form-select">
                        <option value="zashboard">Zashboard 面板</option>
                        <option value="metacubexd">Metacubexd 面板</option>
                        <option value="yacd-meat">Yacd-Meat 面板</option>
                        <option value="dashboard">Dashboard 面板</option>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-primary" onclick="confirmPanelSelection()">确认</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="versionModal" tabindex="-1" aria-labelledby="versionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="versionModalLabel">版本检测结果</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div id="modalContent">
                    <p>正在加载...</p>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
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
<style>
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
let selectedSingboxVersion = 'v1.11.0-alpha.10';  
let selectedMihomoVersion = 'stable';  
let selectedLanguage = 'cn';  
let selectedSingboxVersionForChannelTwo = 'preview'; 
let selectedPanel = 'zashboard';
let selectedVersionType = 'stable';

function showPanelSelector() {
    $('#panelSelectionModal').modal('show');
}

function confirmPanelSelection() {
    selectedPanel = document.getElementById('panelSelect').value;
    $('#panelSelectionModal').modal('hide'); 
    selectOperation('panel');
}

function showVersionTypeModal() {
    $('#updateVersionTypeModal').modal('show');  
}

function confirmVersionTypeSelection() {
    selectedVersionType = document.getElementById('versionTypeSelect').value;  
    $('#updateVersionTypeModal').modal('hide');  

    if (selectedVersionType === 'stable') {
        $('#updateLanguageModal').modal('show');  
    } else {
        selectOperation('client');
    }
}

function selectVersionType(type) {
    selectedVersionType = type; 
    
    if (type === 'stable') {
        document.getElementById('stableBtn').classList.add('btn-success');
        document.getElementById('previewBtn').classList.remove('btn-warning');
        document.getElementById('previewBtn').classList.add('btn-light');
    } else {
        document.getElementById('previewBtn').classList.add('btn-warning');
        document.getElementById('stableBtn').classList.remove('btn-success');
        document.getElementById('stableBtn').classList.add('btn-light');
    }

    handleVersionSelection();
}

function handleVersionSelection() {
    $('#updateVersionTypeModal').modal('hide');  

    if (selectedVersionType === 'stable') {
        $('#updateLanguageModal').modal('show');  
    } else {
        $('#previewLanguageModal').modal('show');  
    }
}

function confirmLanguageSelection() {
    selectedLanguage = document.getElementById('languageSelect').value; 
    $('#updateLanguageModal').modal('hide');  
    selectOperation('client');  
}

function confirmPreviewLanguageSelection() {
    selectedLanguage = document.getElementById('previewLanguageSelect').value; 
    $('#previewLanguageModal').modal('hide');  
    selectOperation('client');  
}

function showSingboxVersionSelector() {
    $('#optionsModal').modal('hide');  
    $('#versionSelectionModal').modal('show');  
}

function showSingboxVersionSelectorForChannelTwo() {
    $('#optionsModal').modal('hide');  
    $('#singboxVersionModal').modal('show');  
}

function confirmSingboxVersionForChannelTwo() {
    selectedSingboxVersionForChannelTwo = document.getElementById('singboxVersionSelectForChannelTwo').value; 
    $('#singboxVersionModal').modal('hide'); 
    selectOperation('sing-box');
} 

function showMihomoVersionSelector() {
    $('#mihomoVersionSelectionModal').modal('show');
}

function confirmMihomoVersion() {
    selectedMihomoVersion = document.getElementById('mihomoVersionSelect').value;
    $('#mihomoVersionSelectionModal').modal('hide');  
    selectOperation('mihomo');
}

function addManualVersion() {
    var manualVersion = document.getElementById('manualVersionInput').value;

    if (manualVersion.trim() === "") {
        alert("请输入版本号！");
        return;
    }

    var select = document.getElementById('singboxVersionSelect');

    var versionExists = Array.from(select.options).some(function(option) {
        return option.value === manualVersion;
    });

    if (versionExists) {
        alert("该版本已存在！");
        return;
    }

    var newOption = document.createElement("option");
    newOption.value = manualVersion;
    newOption.textContent = manualVersion;

    select.innerHTML = '';

    select.appendChild(newOption);

    var options = [
        "v1.11.0-alpha.10", 
        "v1.11.0-alpha.15", 
        "v1.11.0-alpha.20", 
        "v1.11.0-beta.5", 
        "v1.11.0-beta.10"
    ];

    options.forEach(function(version) {
        var option = document.createElement("option");
        option.value = version;
        option.textContent = version;
        select.appendChild(option);
    });

    document.getElementById('manualVersionInput').value = '';
}

function confirmSingboxVersion() {
    selectedSingboxVersion = document.getElementById('singboxVersionSelect').value;
    $('#versionSelectionModal').modal('hide');  

    selectOperation('singbox');
}

document.getElementById('singboxOptionsButton').addEventListener('click', function() {
    $('#optionsModal').modal('show');
});

function selectOperation(type) {
    $('#optionsModal').modal('hide'); 

    const operations = {
        'singbox': {
            url: 'update_singbox_core.php?version=' + selectedSingboxVersion,  
            message: '开始下载 Singbox 核心更新...',
            description: '正在更新 Singbox 核心到最新版本'
        },
        'sing-box': {
            url: selectedSingboxVersionForChannelTwo === 'stable'  
                ? 'update_singbox_stable.php'  
                : 'update_singbox_preview.php', 
            message: '开始下载 Singbox 核心更新...',
            description: '正在更新 Singbox 核心到 ' + selectedSingboxVersionForChannelTwo + ' 版本'
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
        },
        'mihomo': {
            url: selectedMihomoVersion === 'stable' 
                ? 'update_mihomo_stable.php' 
                : 'update_mihomo_preview.php',  
            message: '开始下载 Mihomo 内核更新...',
            description: '正在更新 Mihomo 内核到最新版本 (' + selectedMihomoVersion + ')'
        },
        'client': {
            url: selectedVersionType === 'stable' 
                ? 'update_script.php?lang=' + selectedLanguage  
                : 'update_preview.php?lang=' + selectedLanguage,
            message: selectedVersionType === 'stable' 
                ? '开始下载客户端更新...' 
                : '开始下载客户端预览版更新...',
            description: selectedVersionType === 'stable' 
                ? '正在更新客户端到最新正式版' 
                : '正在更新客户端到最新预览版'
        },
        'panel': { 
            url: selectedPanel === 'zashboard' 
                ? 'update_zashboard.php' 
                : selectedPanel === 'yacd-meat' 
                    ? 'update_meta.php' 
                    : selectedPanel === 'metacubexd' 
                        ? 'update_metacubexd.php' 
                        : selectedPanel === 'dashboard'  
                            ? 'update_dashboard.php'  
                            : 'unknown_panel.php', 
            message: selectedPanel === 'zashboard' 
                ? '开始下载 Zashboard 面板更新...' 
                : selectedPanel === 'yacd-meat' 
                    ? '开始下载 Yacd-Meat 面板更新...' 
                    : selectedPanel === 'metacubexd' 
                        ? '开始下载 Metacubexd 面板更新...' 
                         : selectedPanel === 'dashboard'  
                            ? '开始下载 Dashboard 面板更新...'  
                            : '未知面板更新类型...',
            description: selectedPanel === 'zashboard' 
                ? '正在更新 Zashboard 面板到最新版本,如遇无法显示清除浏览器缓存。' 
                : selectedPanel === 'yacd-meat' 
                    ? '正在更新 Yacd-Meat 面板到最新版本，如遇无法显示清除浏览器缓存。' 
                    : selectedPanel === 'metacubexd' 
                        ? '正在更新 Metacubexd 面板到最新版本' 
                        : selectedPanel === 'dashboard'  
                            ? '正在更新 Dashboard 面板到最新版本'  
                            : '无法识别的面板类型，无法更新。'
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

document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('singboxOptionsButton').addEventListener('click', function() {
        $('#optionsModal').modal('hide');
        
        $('#optionsModal').modal('show');
    });

    document.getElementById('operationOptionsButton').addEventListener('click', function() {
        $('#optionsModal').modal('hide');
        
        $('#operationModal').modal('show');
    });

    document.getElementById('updateUiButton').addEventListener('click', function() {
        showPanelSelector();  
    });
});
</script>

<script>
function checkVersion(outputId, updateFiles, currentVersions) {
    const modalContent = document.getElementById('modalContent');
    const versionModal = new bootstrap.Modal(document.getElementById('versionModal'));
    modalContent.innerHTML = '<p>正在检查新版本...</p>';
    let results = [];

    const requests = updateFiles.map((file) => {
        return fetch(file.url + '?check_version=true')
            .then(response => {
                if (!response.ok) {
                    throw new Error(`请求失败: ${file.name}`);
                }
                return response.text();
            })
            .then(responseText => {
                const versionMatch = responseText.trim().match(/最新版本:\s*([^\s]+)/);
                if (versionMatch && versionMatch[1]) {
                    const newVersion = versionMatch[1];
                    results.push(`
                        <tr class="table-success">
                            <td>${file.name}</td>
                            <td>${currentVersions[file.name] || '未知'}</td>
                            <td>${newVersion}</td>
                        </tr>
                    `);

                    if (file.url === 'update_singbox_core.php') {
                        const select = document.getElementById('singboxVersionSelect');
                        let versionExists = Array.from(select.options).some(option => option.value === newVersion);

                        if (!versionExists) {
                            const newOption = document.createElement('option');
                            newOption.value = newVersion;
                            newOption.textContent = newVersion;
                            select.appendChild(newOption);
                        }
                    }
                } else {
                    results.push(`
                        <tr class="table-warning">
                            <td>${file.name}</td>
                            <td>${currentVersions[file.name] || '未知'}</td>
                            <td>无法解析版本信息</td>
                        </tr>
                    `);
                }
            })
            .catch(error => {
                results.push(`
                    <tr class="table-danger">
                        <td>${file.name}</td>
                        <td>${currentVersions[file.name] || '未知'}</td>
                        <td>网络错误</td>
                    </tr>
                `);
            });
    });

    Promise.all(requests).then(() => {
        modalContent.innerHTML = `
            <table class="table table-striped table-bordered">
                <thead>
                    <tr>
                        <th class="text-center">组件名称</th>
                        <th class="text-center">当前版本</th>
                        <th class="text-center">最新版本</th>
                    </tr>
                </thead>
                <tbody>
                    ${results.join('')}
                </tbody>
            </table>
        `;
        versionModal.show();
    });
}

document.getElementById('checkSingboxButton').addEventListener('click', function () {
    const singBoxVersion = "<?php echo htmlspecialchars($singBoxVersion); ?>";
    const singBoxType = "<?php echo htmlspecialchars($singBoxType); ?>";
    const puernyaVersion = "<?php echo htmlspecialchars($puernyaVersion); ?>";
    const singboxPreviewVersion = "<?php echo htmlspecialchars($singboxPreviewVersion); ?>";
    const currentVersions = {
        'Singbox [ 正式版 ]': singBoxType === 'Singbox 正式版' ? singBoxVersion : '未安装',
        'Singbox [ 预览版 ]': singboxPreviewVersion,
        'Singbox [ 编译版 ]': singboxPreviewVersion,
        'Puernya [ 预览版 ]': puernyaVersion 
    };
    const updateFiles = [
        { name: 'Singbox [ 正式版 ]', url: 'update_singbox_stable.php' },
        { name: 'Singbox [ 预览版 ]', url: 'update_singbox_preview.php' },
        { name: 'Singbox [ 编译版 ]', url: 'update_singbox_core.php' },
        { name: 'Puernya [ 预览版 ]', url: 'puernya.php' }
    ];
    checkVersion('NewSingbox', updateFiles, currentVersions);
});

document.getElementById('checkMihomoButton').addEventListener('click', function () {
    const mihomoVersion = "<?php echo htmlspecialchars($mihomoVersion); ?>";
    const mihomoType = "<?php echo htmlspecialchars($mihomoType); ?>";

    console.log('Mihomo Version:', mihomoVersion);  
    console.log('Mihomo Type:', mihomoType);  

    const currentVersions = {
        'Mihomo [ 正式版 ]': mihomoType === '正式版' ? mihomoVersion : '未安装',
        'Mihomo [ 预览版 ]': mihomoType === '预览版' ? mihomoVersion : '未安装',
    };

    const updateFiles = [
        { name: 'Mihomo [ 正式版 ]', url: 'update_mihomo_stable.php' },
        { name: 'Mihomo [ 预览版 ]', url: 'update_mihomo_preview.php' }
    ];

    checkVersion('NewMihomo', updateFiles, currentVersions);
});


document.getElementById('checkUiButton').addEventListener('click', function () {
    const currentVersions = {
        'MetaCube': '<?php echo htmlspecialchars($metaCubexdVersion); ?>',
        'Zashboard': '<?php echo htmlspecialchars($uiVersion); ?>',
        'Yacd-Meat': '<?php echo htmlspecialchars($metaVersion); ?>',
        'Dashboard': '<?php echo htmlspecialchars($razordVersion); ?>',
    };
    const updateFiles = [
        { name: 'MetaCube', url: 'update_metacubexd.php' },
        { name: 'Zashboard', url: 'update_zashboard.php' },
        { name: 'Yacd-Meat', url: 'update_meta.php' },
        { name: 'Dashboard', url: 'update_dashboard.php' }
    ];
    checkVersion('NewUi', updateFiles, currentVersions);
});

document.getElementById('checkCliverButton').addEventListener('click', function () {
    const cliverVersion = "<?php echo htmlspecialchars($cliverVersion); ?>";
    const cliverType = "<?php echo htmlspecialchars($cliverType); ?>";

    const currentVersions = {
        '客户端 [ 正式版 ]': cliverType === '正式版' ? cliverVersion : '未安装',
        '客户端 [ 预览版 ]': cliverType === '预览版' ? cliverVersion : '未安装',
    };

    const updateFiles = [
        { name: '客户端 [ 正式版 ]', url: 'update_script.php' },
        { name: '客户端 [ 预览版 ]', url: 'update_preview.php' }
    ];

    checkVersion('NewCliver', updateFiles, currentVersions);
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
        var currentVersion = '<?php echo $singBoxVersion; ?>'; 
        var minVersion = '1.10.0'; 
        
        if (currentVersion === '未安装') {
            alert('未检测到 Sing-box 安装，请检查系统配置。');
            return;
        }

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

        if (!document.getElementById('versionWarningModal')) {
            document.body.insertAdjacentHTML('beforeend', modalHtml);
        }

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
</body>
</html>
