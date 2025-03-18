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
                        return ['version' => $version, 'type' => 'Puernya Preview'];
                    }
                    return ['version' => $version, 'type' => 'Singbox Preview'];
                } else {
                    return ['version' => $version, 'type' => 'Singbox Stable'];
                }
            }
        }
    }
    
    return ['version' => 'Not installed', 'type' => 'Unknown'];
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
                    if (preg_match('/^\d/', $version)) {
                        $version = 'v' . $version;
                    }
                    return ['version' => $version, 'type' => 'Preview'];
                }
                
                preg_match('/([0-9]+(\.[0-9]+)+)/', $line, $matches);
                if (!empty($matches)) {
                    $version = $matches[0];  
                    return ['version' => $version, 'type' => 'Stable'];
                }
            }
        }
    }

    return ['version' => 'Not installed', 'type' => 'Unknown'];
}

function getVersion($versionFile) {
    if (file_exists($versionFile)) {
        return trim(file_get_contents($versionFile));
    } else {
        return "Not installed";
    }
}

function getUiVersion() {
    return getVersion('/etc/neko/ui/zashboard/version.txt');
}

function getMetaCubexdVersion() {
    return getVersion('/etc/neko/ui/metacubexd/version.txt');
}

function getMetaVersion() {
    return getVersion('/etc/neko/ui/meta/version.txt');
}

function getRazordVersion() {
    return getVersion('/etc/neko/ui/dashboard/version.txt');
}

function getCliverVersion() {
    $versionFile = '/etc/neko/tmp/nekobox_version';
    
    if (file_exists($versionFile)) {
        $version = trim(file_get_contents($versionFile));
        
        if (preg_match('/-cn$|en$/', $version)) {
            return ['version' => $version, 'type' => 'Stable'];
        } elseif (preg_match('/-preview$|beta$/', $version)) {
            return ['version' => $version, 'type' => 'Preview'];
        } else {
            return ['version' => $version, 'type' => 'Unknown'];
        }
    } else {
        return ['version' => 'Not installed', 'type' => 'Unknown'];
    }
}

$cliverData = getCliverVersion();
$cliverVersion = $cliverData['version']; 
$cliverType = $cliverData['type']; 

$singBoxVersionInfo = getSingboxVersion();
$singBoxVersion = $singBoxVersionInfo['version'];
$singBoxType = $singBoxVersionInfo['type'];
$puernyaVersion = ($singBoxType === 'Puernya Preview') ? $singBoxVersion : 'Not installed';
$singboxPreviewVersion = ($singBoxType === 'Singbox Preview') ? $singBoxVersion : 'Not installed';
$singboxCompileVersion = ($singBoxType === 'Singbox Compiled') ? $singBoxVersion : 'Not installed';
$mihomoVersionInfo = getMihomoVersion();
$mihomoVersion = $mihomoVersionInfo['version'];
$mihomoType = $mihomoVersionInfo['type'];
$uiVersion = getUiVersion();
$metaCubexdVersion = getMetaCubexdVersion();
$metaVersion = getMetaVersion();
$razordVersion = getRazordVersion();

?>
<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'clearNekoTmpDir') {
    $nekoDir = '/tmp/neko';
    $response = [
        'success' => false,
        'message' => ''
    ];

    if (is_dir($nekoDir)) {
        if (deleteDirectory($nekoDir)) {
            $response['success'] = true;
            $response['message'] = 'Directory cleared successfully.';
        } else {
            $response['message'] = 'Failed to delete the directory.';
        }
    } else {
        $response['message'] = 'The directory does not exist.';
    }

    header('Content-Type: application/json');
    echo json_encode($response);
    exit;
}

function deleteDirectory($dir) {
    if (!file_exists($dir)) {
        return true;
    }

    if (!is_dir($dir)) {
        return unlink($dir);
    }

    foreach (scandir($dir) as $item) {
        if ($item == '.' || $item == '..') {
            continue;
        }

        if (!deleteDirectory($dir . DIRECTORY_SEPARATOR . $item)) {
            return false;
        }
    }

    return rmdir($dir);
}
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
    <link href="./assets/bootstrap/bootstrap-icons.css" rel="stylesheet">
    <link rel="stylesheet" href="styles.css?v=<?php echo time(); ?>" />
    <script src="script.js?v=<?php echo time(); ?>"></script>
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

    @media (max-width: 576px) {
        .btn-custom {
            width: 30%; 
            margin: 0 auto; 
            display: block; 
    }

        .btn-fw {
            width: 100%; 
            margin-right: 0; 
            margin-bottom: 10px; 
        }

        .container .form-select {
            margin-right: 6ch;
            width: calc(100% - 1.8ch); 
        }
    }

</style>
  <body>
    <div class="container-sm container-bg text-center callout border border-3 rounded-4 col-11">
        <div class="row">
        <a href="./index.php" class="col btn btn-lg text-nowrap"><i class="bi bi-house-door"></i> <span data-translate="home">Home</span></a>
        <a href="./dashboard.php" class="col btn btn-lg text-nowrap"><i class="bi bi-bar-chart"></i> <span data-translate="panel">Panel</span></a>
        <a href="./singbox.php" class="col btn btn-lg text-nowrap"><i class="bi bi-box"></i> <span data-translate="document">Document</span></a> 
        <a href="./settings.php" class="col btn btn-lg text-nowrap"><i class="bi bi-gear"></i> <span data-translate="settings">Settings</span></a>
<div class="container px-4">
    <h2 class="text-center p-2 mb-4" data-translate="theme_settings">Theme Settings</h2>
    <form action="settings.php" method="post">
        <div class="row justify-content-center">
            <div class="col-12 col-md-6 mb-3">
                <select class="form-select" name="themechange" aria-label="themex">
                    <option selected>Change Theme (<?php echo $neko_theme ?>)</option>
                    <?php foreach ($arrFiles as $file) echo "<option value=\"".$file.'">'.$file."</option>" ?>
                </select>
            </div>
            <div class="col-12 col-md-6 mb-3" style="padding-right: 1.3rem;" >
                <div class="d-flex justify-content-between gap-2">
                    <button class="btn btn-info btn-custom" type="submit">
                        <i class="bi bi-paint-bucket"></i> <span data-translate="change_theme_button">Change Theme</span>
                    </button>

                    <button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#colorModal" data-translate="theme_editor">
                        <i class="bi-palette"></i> Theme Editor
                    </button>
                    
                    <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#filesModal" data-translate="set_background">
                        <i class="bi-camera-video"></i> Set as Background
                    </button>
                </div>
            </div>
        </div>
    </form>

<table class="table table-borderless mb-3">
    <tbody>
        <tr>
            <td colspan="2">
                <div class="table-container">
                    <h2 class="text-center mb-3" data-translate="software_information_title">Software Information</h2>
                    <form action="settings.php" method="post">
                        <div class="btn-group d-flex justify-content-center">
                            <button type="submit" name="fw" value="enable" class="btn btn-success <?php if($fwstatus==1) echo "disabled" ?>" data-translate="enable_button">Enable</button>
                            <button type="submit" name="fw" value="disable" class="btn btn-danger <?php if($fwstatus==0) echo "disabled" ?>" data-translate="disable_button">Disable</button>
                        </div>
                    </form>
                </div>
            </td>
        </tr>
        <tr>
            <td>
                <div class="table-container">
                    <h2 data-translate="client_version_title">Client Version</h2>
                    <p id="cliver" class="text-center" style="font-family: monospace;"></p>
                    <div class="text-center">
                        <button class="btn btn-pink me-1" id="checkCliverButton"><i class="bi bi-search"></i> <span data-translate="detect_button">Detect</span></button>
                        <button class="btn btn-info" id="updateButton" title="Update to Latest Version" onclick="showUpdateVersionModal()"><i class="bi bi-arrow-repeat"></i> <span data-translate="update_button">Update</span></button>
                    </div>
                </div>
            </td>
            <td>
                <div class="table-container">
                    <h2 data-translate="ui_panel_title">Ui Panel</h2>
                    <p class="text-center"><?php echo htmlspecialchars($uiVersion); ?></p>
                    <div class="text-center">
                        <button class="btn btn-pink me-1" id="checkUiButton"><i class="bi bi-search"></i> <span data-translate="detect_button">Detect</span></button>
                        <button class="btn btn-info" id="updateUiButton" title="Update Panel" onclick="showPanelSelector()"><i class="bi bi-arrow-repeat"></i> <span data-translate="update_button">Update</span></button>
                    </div>
                </div>
            </td>
        </tr>
        <tr>
            <td>
                <div class="table-container">
                    <h2 data-translate="singbox_core_version_title">Sing-box Core Version</h2>
                    <p id="singBoxCorever" class="text-center"><?php echo htmlspecialchars($singBoxVersion); ?></p>
                    <div class="text-center">
                        <button class="btn btn-pink me-1" id="checkSingboxButton"><i class="bi bi-search"></i> <span data-translate="detect_button">Detect</span></button>
                        <button class="btn btn-info" id="singboxOptionsButton" title="Singbox Related Operations"><i class="bi bi-arrow-repeat"></i> <span data-translate="update_button">Update</span></button>
                    </div>
                </div>
            </td>
            <td>
                <div class="table-container">
                    <h2 data-translate="mihomo_core_version_title">Mihomo Core Version</h2>
                    <p class="text-center"><?php echo htmlspecialchars($mihomoVersion); ?></p>
                    <div class="text-center">
                        <button class="btn btn-pink me-1" id="checkMihomoButton"><i class="bi bi-search"></i> <span data-translate="detect_button">Detect</span></button>
                        <button class="btn btn-info" id="updateCoreButton" title="Update Mihomo Core" onclick="showMihomoVersionSelector()"><i class="bi bi-arrow-repeat"></i> <span data-translate="update_button">Update</span></button>
                    </div>
                </div>
            </td>
        </tr>
    </tbody>
</table>

<div class="modal fade" id="updateVersionModal" tabindex="-1" aria-labelledby="updateVersionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="updateVersionModalLabel" data-translate="stable">Select the updated version of the language</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <select id="languageSelect" class="form-select">
                        <option value="cn" data-translate="stable">Stable</option>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-danger" onclick="clearNekoTmpDir()" data-translate-title="delete_old_config"><i class="bi bi-trash"></i> <span data-translate="clear_config">Clear Config</span></button>
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close_button">cancel</button>
                <button type="button" class="btn btn-primary" onclick="confirmUpdateVersion()" data-translate="confirmButton">confirm</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="mihomoVersionSelectionModal" tabindex="-1" aria-labelledby="mihomoVersionSelectionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="mihomoVersionSelectionModalLabel" data-translate="mihomo_version_modal_title">Select Mihomo Kernel Version</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <select id="mihomoVersionSelect" class="form-select">
                    <option value="stable" data-translate="mihomo_version_stable">Stable</option>
                    <option value="preview" data-translate="mihomo_version_preview">Preview</option>
                </select>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close_button">cancel</button>
                <button type="button" class="btn btn-primary" onclick="confirmMihomoVersion()" data-translate="confirmButton">confirm</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="optionsModal" tabindex="-1" aria-labelledby="optionsModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="optionsModalLabel" data-translate="options_modal_title">Select Operation</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <p class="text-warning" data-translate="options_modal_note">
                    <strong>Note：</strong> Please prioritize selecting the Channel 1 version for updates to ensure compatibility. The system will first check and dynamically generate the latest version number for download. If the Channel 1 update is unavailable, you can try the Channel 2 version.
                </p>
                <div class="d-grid gap-2">
                    <button class="btn btn-info" onclick="showSingboxVersionSelector()" data-translate="singbox_channel_one">Update Singbox Core (Channel One)</button>
                    <button class="btn btn-success" onclick="showSingboxVersionSelectorForChannelTwo()" data-translate="singbox_channel_two">Update Singbox Core (Channel Two)</button>
                    <button type="button" class="btn btn-warning" id="operationOptionsButton" data-translate="other_operations">Other operations</button>
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close_button">Close</button>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="operationModal" tabindex="-1" aria-labelledby="operationModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="operationModalLabel" data-translate="operation_modal_title">Select operation</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <p class="text-warning" data-translate="operation_modal_note">
                    <strong>Note：</strong> Please select an operation based on your requirements
                </p>
                <div class="d-grid gap-2">
                    <button class="btn btn-success" onclick="selectOperation('puernya')" data-translate="switch_to_puernya">Switch to Puernya kernel</button>
                    <button class="btn btn-primary" onclick="selectOperation('rule')" data-translate="update_pcore_rule">Update P-core rule set</button>
                    <button class="btn btn-primary" onclick="selectOperation('config')" data-translate="update_config_backup">Update config file (backup)</button>
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close_button">Close</button>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="versionSelectionModal" tabindex="-1" aria-labelledby="versionSelectionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="versionSelectionModalLabel" data-translate="versionSelectionModalTitle">Select Singbox core version</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <div class="alert alert-info" data-translate="helpMessage">
                    <strong>Help:</strong> Please select an existing version or manually enter a version number, and click "Add Version" to add it to the dropdown list.
                </div>
                <select id="singboxVersionSelect" class="form-select">
                    <option value="v1.11.0-alpha.10">v1.11.0-alpha.10</option>
                    <option value="v1.11.0-alpha.15">v1.11.0-alpha.15</option>
                    <option value="v1.11.0-alpha.20">v1.11.0-alpha.20</option>
                    <option value="v1.11.0-beta.5">v1.11.0-beta.5</option>
                    <option value="v1.11.0-beta.10">v1.11.0-beta.10</option>
                    <option value="v1.11.0-beta.15">v1.11.0-beta.15</option>
                    <option value="v1.11.0-beta.20">v1.11.0-beta.20</option>
                </select>
                <input type="text" id="manualVersionInput" class="form-control mt-2" placeholder="For example: v1.11.0-beta.10">
                <button type="button" class="btn btn-secondary mt-2" onclick="addManualVersion()" data-translate="addVersionButton">Add Version</button>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancelButton">cancel</button>
                <button type="button" class="btn btn-primary" onclick="confirmSingboxVersion()" data-translate="confirmButton">confirm</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="singboxVersionModal" tabindex="-1" aria-labelledby="singboxVersionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="singboxVersionModalLabel" data-translate="singboxVersionModalTitle">Select Singbox core version (Channel 2)</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label for="singboxVersionSelectForChannelTwo" data-translate="singboxVersionModalTitle">Select version</label>
                    <select id="singboxVersionSelectForChannelTwo" class="form-select">
                        <option value="preview" selected>Preview</option>  
                        <option value="stable">Stable</option>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancelButton">cancel</button>
                <button type="button" class="btn btn-primary" onclick="confirmSingboxVersionForChannelTwo()" data-translate="confirmButton">confirm</button>
            </div>
        </div>
    </div>
</div>

<div id="panelSelectionModal" class="modal fade" tabindex="-1" aria-labelledby="panelSelectionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="panelSelectionModalLabel" data-translate="panelSelectionModalTitle">Selection Panel</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label for="panelSelect" data-translate="selectPanelLabel">Select a Panel</label>
                    <select id="panelSelect" class="form-select">
                        <option value="zashboard" data-translate="panel_zashboard_option">Zashboard Panel [Low Memory]</option>
                        <option value="Zashboard" data-translate="panel_Zashboard_option">Zashboard Panel [High Memory]</option>
                        <option value="metacubexd" data-translate="metacubexdPanel">Metacubexd Panel</option>
                        <option value="yacd-meat" data-translate="yacdMeatPanel">Yacd-Meat Panel</option>
                        <option value="dashboard" data-translate="dashboardPanel">Dashboard Panel</option>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancelButton">cancel</button>
                <button type="button" class="btn btn-primary" onclick="confirmPanelSelection()" data-translate="confirmButton">confirm</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="versionModal" tabindex="-1" aria-labelledby="versionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="versionModalLabel" data-translate="versionModalLabel">Version check results</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <div id="modalContent">
                    <p data-translate="loadingMessage">Loading...</p>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="closeButton">Close</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="updateModal" tabindex="-1" aria-labelledby="updateModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="updateModalLabel" data-translate="updateModalLabel">Update status</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body text-center">
                <div id="updateDescription" class="alert alert-info mb-3" data-translate="updateDescription"></div>
                <pre id="logOutput" style="white-space: pre-wrap; word-wrap: break-word; text-align: left; display: inline-block;" data-translate="waitingMessage">Waiting for the operation to begin...</pre>
            </div>
        </div>
    </div>
</div>

<script>
    function clearNekoTmpDir() {
        fetch('', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: 'action=clearNekoTmpDir'
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                alert(translations["tmp_neko_cleared"] || "The /tmp/neko directory has been cleared successfully.");
            } else {
                if (data.message === 'The directory does not exist.') {
                    alert(translations["tmp_neko_not_exist"] || "The /tmp/neko directory does not exist. No action was taken.");
                } else {
                    alert('Failed to clear the /tmp/neko directory: ' + data.message);
                }
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('An error occurred while trying to clear the /tmp/neko directory.');
        });
    }
</script>

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

function showUpdateVersionModal() {
    $('#updateVersionModal').modal('show');  
}

function confirmUpdateVersion() {
    selectedLanguage = document.getElementById('languageSelect').value;  
    $('#updateVersionModal').modal('hide');  
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
        alert("Please enter a version number");
        return;
    }

    var select = document.getElementById('singboxVersionSelect');

    var versionExists = Array.from(select.options).some(function(option) {
        return option.value === manualVersion;
    });

    if (versionExists) {
        alert("This version already exists");
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
            message: langData[currentLang]['singbox_message'] || 'Starting to download Singbox core update...', 
            description: langData[currentLang]['singbox_description'] || 'Updating Singbox core to the latest version'
        },
        'sing-box': {
            url: selectedSingboxVersionForChannelTwo === 'stable'  
                ? 'update_singbox_stable.php'  
                : 'update_singbox_preview.php', 
            message: langData[currentLang]['sing-box_message'] || 'Starting to download Singbox core update...',
            description: langData[currentLang]['sing-box_description'] 
                || 'Updating Singbox core to ' + selectedSingboxVersionForChannelTwo + ' version'
        },
        'puernya': {
            url: 'puernya.php',
            message: langData[currentLang]['puernya_message'] || 'Starting to switch to Puernya core...',
            description: langData[currentLang]['puernya_description'] || 'Switching to Puernya core, this action will replace the current Singbox core'
        },
        'rule': {
            url: 'update_rule.php',
            message: langData[currentLang]['rule_message'] || 'Starting to download Singbox rule set...',
            description: langData[currentLang]['rule_description'] || 'Updating Singbox rule set'
        },
        'config': {
            url: 'update_config.php',
            message: langData[currentLang]['config_message'] || 'Starting to download Mihomo configuration file...',
            description: langData[currentLang]['config_description'] || 'Updating Mihomo configuration file to the latest version'
        },
        'mihomo': {
            url: selectedMihomoVersion === 'stable' 
                ? 'update_mihomo_stable.php' 
                : 'update_mihomo_preview.php',  
            message: langData[currentLang]['mihomo_message'] || 'Starting to download Mihomo Kernel updates...',
            description: langData[currentLang]['mihomo_description'] 
                || 'Updating Mihomo Kernel to the latest version (' + selectedMihomoVersion + ')'
        },
        'client': {
            url: 'update_script.php?lang=' + selectedLanguage,  
            message: langData[currentLang]['client_message'] || 'Starting to download client updates...',
            description: langData[currentLang]['client_description'] || 'Updating the client to the latest version'
        },
        'panel': { 
            url: selectedPanel === 'zashboard' 
                ? 'update_zashboard.php?panel=zashboard&update_type=dist' 
                : selectedPanel === 'Zashboard' 
                    ? 'update_zashboard.php?panel=zashboard1&update_type=fonts' 
                        : selectedPanel === 'yacd-meat' 
                            ? 'update_meta.php' 
                            : selectedPanel === 'metacubexd' 
                                ? 'update_metacubexd.php' 
                                : selectedPanel === 'dashboard'  
                                    ? 'update_dashboard.php'  
                                    : 'unknown_panel.php', 
            message: langData[currentLang]['panel_' + selectedPanel + '_message'] || 
                (selectedPanel === 'zashboard' ? 'Starting to download Zashboard panel update (dist-cdn-fonts.zip)...' :
                selectedPanel === 'Zashboard' ? 'Starting to download Zashboard panel update (dist.zip)...' :
                selectedPanel === 'yacd-meat' ? 'Starting to download Yacd-Meat panel update...' :
                selectedPanel === 'metacubexd' ? 'Starting to download Metacubexd panel update...' :
                selectedPanel === 'dashboard' ? 'Starting to download Dashboard panel update...' : 'Unknown panel update type...'),
            description: langData[currentLang]['panel_' + selectedPanel + '_description'] || 
                (selectedPanel === 'zashboard' ? 'Updating Zashboard panel to the latest version (dist-cdn-fonts.zip)' :
                selectedPanel === 'Zashboard' ? 'Updating Zashboard panel to the latest version (dist.zip)' :
                selectedPanel === 'yacd-meat' ? 'Updating Yacd-Meat panel to the latest version' :
                selectedPanel === 'metacubexd' ? 'Updating Metacubexd panel to the latest version' :
                selectedPanel === 'dashboard' ? 'Updating Dashboard panel to the latest version' : 
                'Unrecognized panel type, unable to update.')
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
            document.getElementById('logOutput').textContent += '\n' + (translations['updateCompleted'] || '更新完成！');
            document.getElementById('logOutput').textContent += '\n' + xhr.responseText;
            setTimeout(function() {
                $('#updateModal').modal('hide');
                setTimeout(function() {
                    location.reload();
                }, 500);
            }, 10000);
        } else {
            document.getElementById('logOutput').textContent += '\n' + (translations['errorOccurred'] || '发生错误：') + xhr.statusText;
        } 
    };

    xhr.onerror = function() {
        document.getElementById('logOutput').textContent += '\n' + (translations['networkError'] || '网络错误，请稍后再试。');
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

<style>
    .custom-table {
        width: 100%;
        border-collapse: collapse; 
    }

    .custom-table th, .custom-table td {
        padding: 10px;
        text-align: center;
        border: 1px solid #ccc; 
    }

@media (max-width: 767px) {
    .custom-table {
        display: block;
        width: 100%;
    }

    .custom-table thead {
        display: none;
    }

    .custom-table tbody {
        display: block;
    }

    .custom-table tr {
        display: flex;
        flex-direction: column;
        margin-bottom: 1rem;
        border: none;
    }

    .custom-table td {
        display: block;
        width: 100%;
        padding: 0.5rem;
        border: 1px solid #ddd;
    }

    .custom-table td:first-child {
        font-weight: bold;
    }
}
</style>

<script>
function checkVersion(outputId, updateFiles, currentVersions) {
    const modalContent = document.getElementById('modalContent');
    const versionModal = new bootstrap.Modal(document.getElementById('versionModal'));
    modalContent.innerHTML = `<p>${translations['checkingVersion'] || '正在检查新版本...'}</p>`;
    let results = [];

    const requests = updateFiles.map((file) => {
        return fetch(file.url + '?check_version=true')
            .then(response => {
                if (!response.ok) {
                    throw new Error(`${translations['requestFailed'] || '请求失败'}: ${file.name}`);
                }
                return response.text();
            })
            .then(responseText => {
                const versionMatch = responseText.trim().match(/Latest version:\s*([^\s]+)/);
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
                            <td>${currentVersions[file.name] || translations['unknown']}</td>
                            <td>${translations['cannotParseVersion'] || '无法解析版本信息'}</td>
                        </tr>
                    `);
                }
            })
            .catch(error => {
                results.push(`
                    <tr class="table-danger">
                        <td>${file.name}</td>
                        <td>${currentVersions[file.name] || translations['unknown']}</td>
                        <td>${translations['networkError'] || '网络错误'}</td>
                    </tr>
                `);
            });
    });

    Promise.all(requests).then(() => {
        modalContent.innerHTML = `
            <table class="table custom-table">
                <thead>
                    <tr>
                        <th class="text-center">${translations['componentName'] || '组件名称'}</th>
                        <th class="text-center">${translations['currentVersion'] || '当前版本'}</th>
                        <th class="text-center">${translations['latestVersion'] || '最新版本'}</th>
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
    const singBoxVersion = "<?php echo htmlspecialchars(trim($singBoxVersion)); ?>";
    const singBoxType = "<?php echo htmlspecialchars($singBoxType); ?>";
    const puernyaVersion = "<?php echo htmlspecialchars($puernyaVersion); ?>";
    const singboxPreviewVersion = "<?php echo htmlspecialchars($singboxPreviewVersion); ?>";
    const singboxCompileVersion = "<?php echo htmlspecialchars($singboxCompileVersion); ?>";

    let finalPreviewVersion = langData[currentLang]['notInstalled'];  
    let finalCompileVersion = langData[currentLang]['notInstalled'];  
    let finalOfficialVersion = langData[currentLang]['notInstalled']; 
    let finalPuernyaVersion = langData[currentLang]['notInstalled']; 

    if (puernyaVersion === '1.10.0-alpha.29-067c81a7') {
        finalPuernyaVersion = puernyaVersion; 
    }

    if (singBoxVersion && /^v/.test(singBoxVersion) && /-.+/.test(singBoxVersion)) {
        finalCompileVersion = singBoxVersion;
    }

    if (singBoxVersion && /-.+/.test(singBoxVersion) && puernyaVersion !== '1.10.0-alpha.29-067c81a7' && !/^v/.test(singBoxVersion)) {
        finalPreviewVersion = singBoxVersion;  
    }

    if (singBoxVersion && !/[a-zA-Z]/.test(singBoxVersion)) {
        finalOfficialVersion = singBoxVersion;  
    }

    const currentVersions = {
        ['Singbox [' + langData[currentLang]['stable'] + ']']: finalOfficialVersion,
        ['Singbox [' + langData[currentLang]['preview'] + ']']: finalPreviewVersion,
        ['Singbox [' + langData[currentLang]['compiled'] + ']']: finalCompileVersion,
        ['Puernya [' + langData[currentLang]['preview'] + ']']: finalPuernyaVersion
    };

    const updateFiles = [
        { name: 'Singbox [' + langData[currentLang]['stable'] + ']', url: 'update_singbox_stable.php' },
        { name: 'Singbox [' + langData[currentLang]['preview'] + ']', url: 'update_singbox_preview.php' },
        { name: 'Singbox [' + langData[currentLang]['compiled'] + ']', url: 'update_singbox_core.php' },
        { name: 'Puernya [' + langData[currentLang]['preview'] + ']', url: 'puernya.php' }
    ];

    checkVersion('NewSingbox', updateFiles, currentVersions);
});

document.getElementById('checkMihomoButton').addEventListener('click', function () {
    const mihomoVersion = "<?php echo htmlspecialchars($mihomoVersion); ?>";
    const mihomoType = "<?php echo htmlspecialchars($mihomoType); ?>";

    console.log('Mihomo Version:', mihomoVersion);  
    console.log('Mihomo Type:', mihomoType);  

    const currentVersions = {
        ['Mihomo [ ' + langData[currentLang]['stable'] + ' ]']: mihomoType === 'Stable' ? mihomoVersion : langData[currentLang]['notInstalled'],
        ['Mihomo [ ' + langData[currentLang]['preview'] + ' ]']: mihomoType === 'Preview' ? mihomoVersion : langData[currentLang]['notInstalled'],
    };

    const updateFiles = [
        { name: 'Mihomo [ ' + langData[currentLang]['stable'] + ' ]', url: 'update_mihomo_stable.php' },
        { name: 'Mihomo [ ' + langData[currentLang]['preview'] + ' ]', url: 'update_mihomo_preview.php' }
    ];

    checkVersion('NewMihomo', updateFiles, currentVersions);
});

document.getElementById('checkUiButton').addEventListener('click', function () {
    const notInstalledText = langData[currentLang]?.['notInstalled'] || 'Not installed'; 

    const currentVersions = {
        'MetaCube': '<?php echo htmlspecialchars($metaCubexdVersion); ?>',
        'Zashboard': '<?php echo htmlspecialchars($uiVersion); ?>',
        'Yacd-Meat': '<?php echo htmlspecialchars($metaVersion); ?>',
        'Dashboard': '<?php echo htmlspecialchars($razordVersion); ?>',
    };

    for (const key in currentVersions) {
        if (currentVersions[key] === "Not installed") {
            currentVersions[key] = notInstalledText;
        }
    }

    const updateFiles = [
        { name: 'MetaCube', url: 'update_metacubexd.php' },
        { name: 'Zashboard', url: 'update_zashboard.php' },
        { name: 'Yacd-Meat', url: 'update_meta.php' },
        { name: 'Dashboard', url: 'update_dashboard.php' }
    ];

    checkVersion('NewUi', updateFiles, currentVersions);
});

document.getElementById('checkCliverButton').addEventListener('click', function () {
    const cliverVersion = document.getElementById('cliver').textContent.trim(); 

    const currentVersions = {
        [langData[currentLang]['client'] + ' [ ' + langData[currentLang]['stable'] + ' ]']: cliverVersion, 
    };

    const updateFiles = [
        { name: langData[currentLang]['client'] + ' [ ' + langData[currentLang]['stable'] + ' ]', url: 'update_script.php' },
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
        
        if (currentVersion === translations['notInstalled']) {
            alert(translations['notInstalledMessage']);
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
                            <h5 class="modal-title" id="versionWarningModalLabel">${translations['versionWarning']}</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body">
                            <p>${translations['versionTooLowMessage']} (${currentVersion}) ${translations['recommendedMinVersion']} (v1.10.0).</p>
                            <p>${translations['upgradeSuggestion']}</p>
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

        .container-fluid {
            max-width: 2400px;
            width: 100%;
            margin: 0 auto;
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
<div class="container-fluid mt-4">
    <h2 class="text-center mb-4" data-translate="aboutTitle"></h2>
    <div class="feature-box text-center">
        <h5 data-translate="nekoBoxTitle"></h5>
        <p data-translate="nekoBoxDescription"></p>
    </div>

    <h5 class="text-center mb-4"><i data-feather="cpu"></i><span data-translate="coreFeatures"></span></h5>
    <div class="row">
        <div class="col-md-4 mb-4 d-flex">
            <div class="feature-box text-center flex-fill">
                <h6 data-translate="simplifiedConfiguration"></h6>
                <p data-translate="simplifiedConfigurationDescription"></p>
            </div>
        </div>
        <div class="col-md-4 mb-4 d-flex">
            <div class="feature-box text-center flex-fill">
                <h6 data-translate="optimizedPerformance"></h6>
                <p data-translate="optimizedPerformanceDescription"></p>
            </div>
        </div>
        <div class="col-md-4 mb-4 d-flex">
            <div class="feature-box text-center flex-fill">
                <h6 data-translate="seamlessExperience"></h6>
                <p data-translate="seamlessExperienceDescription"></p>
            </div>
        </div>
    </div>

<h5 class="text-center mb-4"><i data-feather="tool"></i> <span data-translate="toolInfo"></span></h5>
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
                            <a href="https://github.com/SagerNet/sing-box" target="_blank"><i data-feather="codesandbox"></i>   Sing-box</a>
                        </div>
                    </td>
                    <td>
                        <div class="link-box">
                            <a href="https://github.com/MetaCubeX/mihomo" target="_blank"><i data-feather="box"></i>   Mihomo</a>
                        </div>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</div>
<h5 class="text-center mb-4"><i data-feather="paperclip"></i> <span data-translate="externalLinks"></span></h5>
        <div class="table-container">
            <table class="table table-borderless mb-5">
                <tbody>
                    <tr class="text-center">
                        <td>Github</td>
                        <td>Thaolga</td>
                    </tr>
                    <tr class="text-center">
                        <td>
                            <div class="link-box">
                                <a href="https://github.com/Thaolga/openwrt-nekobox/issues" target="_blank"><i data-feather="github"></i>   Issues</a>
                            </div>
                        </td>
                        <td>
                            <div class="link-box">
                                <a href="https://github.com/Thaolga/openwrt-nekobox" target="_blank"><i data-feather="github"></i>   NEKOBOX</a>
                            </div>
                        </td>
                    </tr>
                    <tr class="text-center">
                        <td>Telegram</td>
                        <td>Zephyruso</td>
                    </tr>
                    <tr class="text-center">
                        <td>
                            <div class="link-box">
                                <a href="https://t.me/+J55MUupktxFmMDgx" target="_blank"><i data-feather="send"></i> Telegram</a>
                            </div>
                        </td>
                        <td>
                            <div class="link-box">
                                <a href="https://github.com/Zephyruso/zashboard" target="_blank"><i data-feather="package"></i>    ZASHBOARD</a>
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






