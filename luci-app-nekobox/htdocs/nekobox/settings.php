
<?php
include './cfg.php';
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
    $output = shell_exec("opkg list-installed luci-app-nekobox 2>/dev/null");

    if ($output) {
        $lines = explode("\n", trim($output));
        foreach ($lines as $line) {
            if (preg_match('/luci-app-nekobox\s*-\s*([^\s]+)/', $line, $matches)) {
                $version = 'v' . $matches[1];
                return ['version' => $version, 'type' => 'Installed'];
            }
        }
    }

    return ['version' => 'Not installed', 'type' => 'Unknown'];
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

<title>Settings - Nekobox</title>
<?php include './ping.php'; ?>

<div class="container-sm container-bg px-0 px-sm-4 mt-4">
<?php include 'navbar.php'; ?>
<div class="container-sm container px-4 theme-settings-container text-center">
  <h2 class="text-center p-2 mb-2" data-translate="component_update">Component Update</h2>
  <div class="row g-4">
    <div class="col-md-6">
      <div class="card">
        <div class="card-body text-center">
          <h5 class="card-title" data-translate="client_version_title">Client Version</h5>
          <p id="cliverVersion" class="card-text" style="font-family: monospace;"><?php echo htmlspecialchars($cliverVersion); ?></p>
          <div class="d-flex justify-content-center gap-2 mt-3">
            <button class="btn btn-pink" id="checkCliverButton">
              <i class="bi bi-search"></i> <span data-translate="detect_button">Detect</span>
            </button>
            <button class="btn btn-info" id="updateButton" onclick="showUpdateVersionModal()">
              <i class="bi bi-arrow-repeat"></i> <span data-translate="update_button">Update</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="col-md-6">
      <div class="card">
        <div class="card-body text-center">
          <h5 class="card-title" data-translate="ui_panel_title">Ui Panel</h5>
          <p id="uiVersion" class="card-text"><?php echo htmlspecialchars($uiVersion); ?></p>
          <div class="d-flex justify-content-center gap-2 mt-3">
            <button class="btn btn-pink" id="checkUiButton">
              <i class="bi bi-search"></i> <span data-translate="detect_button">Detect</span>
            </button>
            <button class="btn btn-info" id="updateUiButton" onclick="showPanelSelector()">
              <i class="bi bi-arrow-repeat"></i> <span data-translate="update_button">Update</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="col-md-6">
      <div class="card">
        <div class="card-body text-center">
          <h5 class="card-title" data-translate="singbox_core_version_title">Sing-box Core Version</h5>
          <p id="singBoxCorever" class="card-text"><?php echo htmlspecialchars($singBoxVersion); ?></p>
          <div class="d-flex justify-content-center gap-2 mt-3">
            <button class="btn btn-pink" id="checkSingboxButton">
              <i class="bi bi-search"></i> <span data-translate="detect_button">Detect</span>
            </button>
            <button class="btn btn-info" id="singboxOptionsButton">
              <i class="bi bi-arrow-repeat"></i> <span data-translate="update_button">Update</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="col-md-6">
      <div class="card">
        <div class="card-body text-center">
          <h5 class="card-title" data-translate="mihomo_core_version_title">Mihomo Core Version</h5>
          <p id="mihomoVersion" class="card-text"><?php echo htmlspecialchars($mihomoVersion); ?></p>
          <div class="d-flex justify-content-center gap-2 mt-3">
            <button class="btn btn-pink" id="checkMihomoButton">
              <i class="bi bi-search"></i> <span data-translate="detect_button">Detect</span>
            </button>
            <button class="btn btn-info" id="updateCoreButton" onclick="showMihomoVersionSelector()">
              <i class="bi bi-arrow-repeat"></i> <span data-translate="update_button">Update</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="container-sm container px-4 theme-settings-container">
  <h2 class="text-center mb-4 mt-4" data-translate="aboutTitle"></h2>
  <div class="card mb-5">
    <div class="card-body text-center feature-box">
      <h5 data-translate="nekoBoxTitle"></h5>
      <p data-translate="nekoBoxDescription"></p>
    </div>
  </div>

  <div class="row g-4 mb-5">
    <div class="col-md-4 d-flex">
      <div class="card flex-fill">
        <div class="card-body text-center">
          <h6 data-translate="simplifiedConfiguration"></h6>
          <p data-translate="simplifiedConfigurationDescription"></p>
        </div>
      </div>
    </div>
    <div class="col-md-4 d-flex">
      <div class="card flex-fill">
        <div class="card-body text-center">
          <h6 data-translate="optimizedPerformance"></h6>
          <p data-translate="optimizedPerformanceDescription"></p>
        </div>
      </div>
    </div>
    <div class="col-md-4 d-flex">
      <div class="card flex-fill">
        <div class="card-body text-center">
          <h6 data-translate="seamlessExperience"></h6>
          <p data-translate="seamlessExperienceDescription"></p>
        </div>
      </div>
    </div>
  </div>

  <div class="row g-4 mb-5">
    <div class="col-md-6 d-flex flex-column">
      <div class="card flex-fill">
        <div class="card-body">
          <h5 class="mb-4 text-center">
            <i data-feather="tool"></i> <span data-translate="toolInfo"></span>
          </h5>
          <div class="card">
            <div class="card-body p-3">
              <div class="table-responsive">
                <table class="table table-borderless text-center mb-0">
                  <tbody>
                    <tr>
                      <td>SagerNet</td>
                      <td>MetaCubeX</td>
                    </tr>
                    <tr>
                      <td>
                        <a href="https://github.com/SagerNet/sing-box" target="_blank" class="d-inline-flex align-items-center gap-2 link-primary">
                          <i data-feather="codesandbox"></i> Sing-box
                        </a>
                      </td>
                      <td>
                        <a href="https://github.com/MetaCubeX/mihomo" target="_blank" class="d-inline-flex align-items-center gap-2 link-primary">
                          <i data-feather="box"></i> Mihomo
                        </a>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col-md-6 d-flex flex-column">
      <div class="card flex-fill">
        <div class="card-body">
          <h5 class="mb-4 text-center">
            <i data-feather="paperclip"></i> <span data-translate="externalLinks"></span>
          </h5>
          <div class="card">
            <div class="card-body p-3">
              <div class="table-responsive">
                <table class="table table-borderless text-center mb-0">
                  <tbody>
                    <tr>
                      <td>Github</td>
                      <td>Thaolga</td>
                    </tr>
                    <tr>
                      <td>
                        <a href="https://github.com/Thaolga/openwrt-nekobox/issues" target="_blank" class="d-inline-flex align-items-center gap-2 link-primary">
                          <i data-feather="github"></i> Issues
                        </a>
                      </td>
                      <td>
                        <a href="https://github.com/Thaolga/openwrt-nekobox" target="_blank" class="d-inline-flex align-items-center gap-2 link-primary">
                          <i data-feather="github"></i> NEKOBOX
                        </a>
                      </td>
                    </tr>
                    <tr>
                      <td>Telegram</td>
                      <td>Zephyruso</td>
                    </tr>
                    <tr>
                      <td>
                        <a href="https://t.me/+J55MUupktxFmMDgx" target="_blank" class="d-inline-flex align-items-center gap-2 link-primary">
                          <i data-feather="send"></i> Telegram
                        </a>
                      </td>
                      <td>
                        <a href="https://github.com/Zephyruso/zashboard" target="_blank" class="d-inline-flex align-items-center gap-2 link-primary">
                          <i data-feather="package"></i> ZASHBOARD
                        </a>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="modal fade" id="updateVersionModal" tabindex="-1" aria-labelledby="updateVersionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
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
                <button type="button" class="btn btn-danger" onclick="clearNekoTmpDir()" data-tooltip="delete_old_config"><i class="bi bi-trash"></i> <span data-translate="clear_config">Clear Config</span></button>
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close_button">cancel</button>
                <button type="button" class="btn btn-primary" onclick="confirmUpdateVersion()" data-translate="confirmButton">confirm</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="mihomoVersionSelectionModal" tabindex="-1" aria-labelledby="mihomoVersionSelectionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="mihomoVersionSelectionModalLabel" data-translate="mihomo_version_modal_title">Select Mihomo Kernel Version</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <select id="mihomoVersionSelect" class="form-select">
                    <option value="preview" data-translate="mihomo_version_preview">Preview</option>
                    <option value="stable" data-translate="mihomo_version_stable">Stable</option>
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
    <div class="modal-dialog modal-xl modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="optionsModalLabel" data-translate="options_modal_title">Select Operation</h5>
                <button type="button" class="btn-close ms-auto" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-md-4 d-none">
                        <div class="card h-100 text-center">
                            <div class="card-body d-flex flex-column">
                                <h5 class="card-title" data-translate="singbox_channel_one">Singbox Core (Channel One)</h5>
                                <p class="card-text flex-grow-1" data-translate="channel_one_desc">Backup channel</p>
                                <button class="btn btn-info mt-auto" onclick="showSingboxVersionSelector()"><i class="bi bi-arrow-repeat"></i> <span data-translate="update_button">Update</span></button>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="card h-100 text-center">
                            <div class="card-body d-flex flex-column">
                                <h5 class="card-title" data-translate="singbox_channel_two">Singbox Core (Channel Two)</h5>
                                <p class="card-text flex-grow-1" data-translate="channel_two_desc">Official preferred channel</p>
                                <button class="btn btn-info mt-auto" onclick="showSingboxVersionSelectorForChannelTwo()"><i class="bi bi-arrow-repeat"></i> <span data-translate="update_button">Update</span></button>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="card h-100 text-center">
                            <div class="card-body d-flex flex-column">
                                <h5 class="card-title" data-translate="other_operations">Other Operations</h5>
                                <p class="card-text flex-grow-1" data-translate="other_operations_desc">Additional management options</p>
                                <button class="btn btn-info mt-auto" id="operationOptionsButton"><i class="bi bi-arrow-repeat"></i> <span data-translate="update_button">Update</span></button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close_button">
                    Close
                </button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="operationModal" tabindex="-1" aria-labelledby="operationModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="operationModalLabel" data-translate="operation_modal_title">Select operation</h5>
                <button type="button" class="btn-close ms-auto" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="alert alert-warning text-start" role="alert">
                    <strong data-translate="note_label"></strong>
                    <span data-translate="operation_modal_note" class="text-black">
                        Please select an operation based on your requirements
                    </span>
                </div>
                <div class="d-flex flex-wrap justify-content-end gap-2 mt-3">
                    <button class="btn btn-success btn-lg flex-fill" style="max-width: 240px;" onclick="selectOperation('puernya')" data-translate="switch_to_puernya">
                        Switch to Puernya kernel
                    </button>
                    <button class="btn btn-primary btn-lg flex-fill" style="max-width: 240px;" onclick="selectOperation('rule')" data-translate="update_pcore_rule">
                        Update P-core rule set
                    </button>
                    <button class="btn btn-primary btn-lg flex-fill" style="max-width: 240px;" onclick="selectOperation('config')" data-translate="update_config_backup">
                        Update config file (backup)
                    </button>
                </div>
            </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close_button">
                        Close
                    </button>
                </div>
            </div>
        </div>
    </div>

<div class="modal fade" id="versionSelectionModal" tabindex="-1" aria-labelledby="versionSelectionModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
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
                    <option value="v1.12.0-rc.3">v1.12.0-rc.3</option>
                    <option value="v1.12.0-rc.4">v1.12.0-rc.4</option>
                    <option value="v1.13.0-alpha.1">v1.13.0-alpha.1</option>
                </select>
                <input type="text" id="manualVersionInput" class="form-control mt-2" placeholder="For example: v1.12.0-rc.3">
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
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="singboxVersionModalLabel" data-translate="singboxVersionModalTitle">Select Singbox core version (Channel 2)</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <select id="singboxVersionSelectForChannelTwo" class="form-select">
                        <option value="preview" data-translate="preview">Preview</option>  
                        <option value="stable" data-translate="stable">Stable</option>
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
    <div class="modal-dialog modal-lg">
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
    <div class="modal-dialog modal-lg">
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
    <div class="modal-dialog modal-lg">
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
<style>
.version-indicator {
    position: absolute;
    top: 15px;
    right: 20px;
    width: 12px;
    height: 12px;
    border-radius: 50%;
    cursor: pointer;
    display: inline-block;
}

.version-indicator.success {
    background-color: #28a745;
    animation: pulse-success 2s infinite;
    box-shadow: 0 0 0 0 rgba(40, 167, 69, 0.7);
}

.version-indicator.warning {
    background-color: #ffc107;
    animation: pulse-warning 2s infinite;
    box-shadow: 0 0 0 0 rgba(255, 193, 7, 0.7);
}

.version-indicator.error {
    background-color: #dc3545;
    animation: pulse-error 2s infinite;
    box-shadow: 0 0 0 0 rgba(220, 53, 69, 0.7);
}

.version-indicator::after {
    content: attr(data-text);
    position: absolute;
    bottom: -28px;
    right: 100%;
    margin-right: 6px;
    background: rgba(0,0,0,0.75);
    color: #fff;
    padding: 2px 6px;
    border-radius: 4px;
    white-space: nowrap;
    font-size: 0.75rem;
    pointer-events: none;
    opacity: 0;
    transition: opacity 0.2s ease;
    z-index: 99999;
}

.version-indicator:hover::after {
    opacity: 1;
}

@keyframes pulse-success {
    0%   { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(40, 167, 69, 0.7); }
    70%  { transform: scale(1);    box-shadow: 0 0 0 8px rgba(40, 167, 69, 0); }
    100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(40, 167, 69, 0); }
}

@keyframes pulse-warning {
    0%   { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(255, 193, 7, 0.7); }
    70%  { transform: scale(1);    box-shadow: 0 0 0 8px rgba(255, 193, 7, 0); }
    100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(255, 193, 7, 0); }
}

@keyframes pulse-error {
    0%   { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(220, 53, 69, 0.7); }
    70%  { transform: scale(1);    box-shadow: 0 0 0 8px rgba(220, 53, 69, 0); }
    100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(220, 53, 69, 0); }
}

.card-body {
    position: relative;
}

@media (max-width: 768px) {
    .navbar-toggler {
        margin-left: auto;
        margin-right: 15px;
    }
    
    .navbar-brand {
        margin-left: 15px !important;
    }
    
    .navbar .d-flex.align-items-center {
        margin-left: 15px !important;
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
            document.getElementById('logOutput').textContent += '\n' + (translations['updateCompleted'] || 'Update completed!');
            document.getElementById('logOutput').textContent += '\n' + xhr.responseText;
            setTimeout(function() {
                $('#updateModal').modal('hide');
                setTimeout(function() {
                    location.reload();
                }, 500);
            }, 10000);
        } else {
            document.getElementById('logOutput').textContent += '\n' + (translations['errorOccurred'] || 'Error occurred: ') + xhr.statusText;
        } 
    };

    xhr.onerror = function() {
        document.getElementById('logOutput').textContent += '\n' + (translations['networkError'] || 'Network error');
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

document.addEventListener('DOMContentLoaded', () => {
    const addIndicator = (el, text, status = 'warning') => {
        if (!el) return;

        let indicator = el.querySelector('.version-indicator');
        if (!indicator) {
            indicator = document.createElement('span');
            indicator.className = 'version-indicator';
            el.appendChild(indicator);
        }

        indicator.className = `version-indicator ${status}`;
        indicator.setAttribute('data-text', text);
    };

    const compareVersions = (current, latest) => {
        if (!current || !latest) return null;
        
        try {
            const clean = v => v.replace(/^v\.?/i, '').trim();
            const curVer = clean(current);
            const latVer = clean(latest);
            
            if (curVer === latVer) return 0;
            
            const parseVersion = version => {
                const parts = version.split('-');
                const mainVersion = parts[0].split('.').map(part => {
                    const num = parseInt(part, 10);
                    return isNaN(num) ? part : num;
                });
                const preRelease = parts[1] || '';
                let preReleaseNum = preRelease.includes('alpha') ? 1 :
                                    preRelease.includes('beta') ? 2 :
                                    /^r\d+$/i.test(preRelease) ? 3 :
                                    preRelease.includes('rc') ? 4 :
                                    preRelease.includes('preview') ? 5 : 
                                    /^[a-f0-9]{7,}$/.test(preRelease) ? 0 :
                                    Infinity;
                return { main: mainVersion, preRelease, preReleaseNum };
            };

            const curParsed = parseVersion(curVer);
            const latParsed = parseVersion(latVer);

            const len = Math.max(curParsed.main.length, latParsed.main.length);
            for (let i = 0; i < len; i++) {
                const cur = curParsed.main[i] || 0;
                const lat = latParsed.main[i] || 0;
                
                if (cur > lat) return 1;
                if (cur < lat) return -1;
            }

            if (curParsed.preReleaseNum > latParsed.preReleaseNum) return 1;
            if (curParsed.preReleaseNum < latParsed.preReleaseNum) return -1;

            if (
                /^(alpha|beta|preview)(\.?\d+)?$/i.test(curParsed.preRelease) &&
                /^(alpha|beta|preview)(\.?\d+)?$/i.test(latParsed.preRelease)
            ) {
                const curNum = parseInt(curParsed.preRelease.replace(/\D+/g, ''), 10) || 0;
                const latNum = parseInt(latParsed.preRelease.replace(/\D+/g, ''), 10) || 0;
                if (curNum > latNum) return 1;
                if (curNum < latNum) return -1;
            }

            if (/^r\d+$/i.test(curParsed.preRelease) && /^r\d+$/i.test(latParsed.preRelease)) {
                const curNum = parseInt(curParsed.preRelease.replace(/\D+/g, ''), 10) || 0;
                const latNum = parseInt(latParsed.preRelease.replace(/\D+/g, ''), 10) || 0;
                if (curNum > latNum) return 1;
                if (curNum < latNum) return -1;
            }

            if (/^rc\d+$/i.test(curParsed.preRelease) && /^rc\d+$/i.test(latParsed.preRelease)) {
                const curNum = parseInt(curParsed.preRelease.replace(/\D+/g, ''), 10) || 0;
                const latNum = parseInt(latParsed.preRelease.replace(/\D+/g, ''), 10) || 0;
                if (curNum > latNum) return 1;
                if (curNum < latNum) return -1;
            }

            return 0;           
        } catch (error) {
            return null;
        }
    };

    const checkVersion = async (elementId, currentVersion, updateUrl) => {
        const element = document.getElementById(elementId);
        if (!element || !currentVersion || !updateUrl) return;

        addIndicator(element, "<?php echo $translations['checkingVersion'] ?? 'Checking version...'; ?>", 'info');

        try {
            const res = await fetch(updateUrl + '?check_version=true');
            if (!res.ok) throw new Error(`HTTP ${res.status}`);
            
            const text = await res.text();
            const match = text.trim().match(/Latest version:\s*([^\s]+)/);
            if (!match?.[1]) throw new Error('Parse failed');
            
            const latest = match[1];
            const comparison = compareVersions(currentVersion, latest);
            
            let statusText, status;
            if (comparison === null) {
                statusText = "<?php echo $translations['versionCheckFailed'] ?? 'Version check failed'; ?>";
                status = 'error';
            } else if (comparison >= 0) {
                statusText = "<?php echo $translations['upToDate'] ?? 'Up-to-date'; ?>";
                status = 'success';
            } else {
                statusText = "<?php echo $translations['updateAvailable'] ?? 'Update Available'; ?>: " + latest;
                status = 'warning';
            }
            addIndicator(element, statusText, status);

        } catch (error) {
            let errorMessage = "<?php echo $translations['versionCheckFailed'] ?? 'Version check failed'; ?>";
            if (error.message.includes('Failed to fetch')) {
                errorMessage += " (<?php echo $translations['networkError'] ?? 'Network error'; ?>)";
            } else {
                errorMessage += ` (${error.message})`;
            }
            addIndicator(element, errorMessage, 'error');
        }
    };

    const singBoxCurrent = "<?php echo htmlspecialchars($singBoxVersion); ?>";
    let singBoxUrl = '';
    if (singBoxCurrent) {
        if (/^v/.test(singBoxCurrent) && /-.+/.test(singBoxCurrent)) {
            singBoxUrl = 'update_singbox_core.php';
        } else if (/-.+/.test(singBoxCurrent)) {
            singBoxUrl = 'update_singbox_preview.php';
        } else {
            singBoxUrl = 'update_singbox_stable.php';
        }
    }

    const mihomoCurrent = "<?php echo htmlspecialchars($mihomoVersion); ?>";
    const mihomoType = "<?php echo htmlspecialchars($mihomoType); ?>";
    const mihomoUrl = mihomoType === 'Stable' ? 'update_mihomo_stable.php' : 
                     mihomoType === 'Preview' ? 'update_mihomo_preview.php' : '';

    if (singBoxUrl) checkVersion('singBoxCorever', singBoxCurrent, singBoxUrl);
    if (mihomoUrl) checkVersion('mihomoVersion', mihomoCurrent, mihomoUrl);
    
    const zashboardCurrent = "<?php echo htmlspecialchars($uiVersion); ?>";
    checkVersion('uiVersion', zashboardCurrent, 'update_zashboard.php');

    const cliverCurrent = "<?php echo htmlspecialchars(trim($cliverVersion)); ?>";
    checkVersion('cliverVersion', cliverCurrent, 'update_script.php');
});
</script>

<script>
function checkVersion(outputId, updateFiles, currentVersions) {
    const modalContent = document.getElementById('modalContent');
    const versionModal = new bootstrap.Modal(document.getElementById('versionModal'));

    modalContent.innerHTML = `
        <div class="text-center py-4">
            <div class="spinner-border text-info mb-3" role="status"></div>
            <div>${translations['checkingVersion'] || 'Checking for new version...'}</div>
        </div>
    `;

    let rows = [];

    const requests = updateFiles.map((file) => {
        return fetch(file.url + '?check_version=true')
            .then(response => {
                if (!response.ok) {
                    throw new Error(`${translations['requestFailed'] || 'Request failed'}: ${file.name}`);
                }
                return response.text();
            })
            .then(responseText => {
                const versionMatch = responseText.trim().match(/Latest version:\s*([^\s]+)/);
                if (versionMatch && versionMatch[1]) {
                    const newVersion = versionMatch[1];
                    rows.push(`
                        <tr>
                            <td class="text-center align-middle">${file.name}</td>
                            <td class="text-center align-middle">${currentVersions[file.name] || translations['unknown'] || 'Unknown'}</td>
                            <td class="text-center align-middle">${newVersion}</td>
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
                    rows.push(`
                        <tr>
                            <td class="text-center align-middle">${file.name}</td>
                            <td class="text-center align-middle">${currentVersions[file.name] || translations['unknown'] || 'Unknown'}</td>
                            <td class="text-center align-middle text-warning">${translations['cannotParseVersion'] || 'Unable to parse version information'}</td>
                        </tr>
                    `);
                }
            })
            .catch(() => {
                rows.push(`
                    <tr>
                        <td class="text-center align-middle">${file.name}</td>
                        <td class="text-center align-middle">${currentVersions[file.name] || translations['unknown'] || 'Unknown'}</td>
                        <td class="text-center align-middle text-danger">${translations['networkError'] || 'Network error'}</td>
                    </tr>
                `);
            });
    });

    Promise.all(requests).then(() => {
        modalContent.innerHTML = `
            <div class="card">
                <div class="card-body p-3">
                    <table class="table table-light mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="text-center">${translations['componentName'] || 'Component name'}</th>
                                <th class="text-center">${translations['currentVersion'] || 'Current version'}</th>
                                <th class="text-center">${translations['latestVersion'] || 'Latest version'}</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${rows.join('')}
                        </tbody>
                    </table>
                </div>
            </div>
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
    const cliverVersion = document.getElementById('cliverVersion').textContent.trim(); 

    const currentVersions = {
        [langData[currentLang]['client'] + ' [ ' + langData[currentLang]['stable'] + ' ]']: cliverVersion, 
    };

    const updateFiles = [
        { name: langData[currentLang]['client'] + ' [ ' + langData[currentLang]['stable'] + ' ]', url: 'update_script.php?check_version=true' },
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
        var modalTitle = '';
        var modalBody = '';

        if (currentVersion === translations['notInstalled']) {
            modalTitle = translations['versionWarning'];
            modalBody = `
                <p>${translations['notInstalledMessage']}</p>
                <p>${translations['upgradeSuggestion']}</p>
            `;
        } else if (compareVersions(currentVersion, minVersion) < 0) {
            modalTitle = translations['versionWarning'];
            modalBody = `
                <p>${translations['versionTooLowMessage']} (${currentVersion}) ${translations['recommendedMinVersion']} (v${minVersion}).</p>
                <p>${translations['upgradeSuggestion']}</p>
            `;
        } else {
            return;
        }

        const storageKey = 'singboxVersionWarning';
        let lastData = localStorage.getItem(storageKey);
        let lastInfo = lastData ? JSON.parse(lastData) : null;
        const now = Date.now();
        const DAY_24 = 24 * 60 * 60 * 1000;

        if (lastInfo && lastInfo.version === currentVersion && (now - lastInfo.timestamp < DAY_24)) {
            return;
        }

        var modalHtml = `
            <div class="modal fade" id="versionWarningModal" tabindex="-1" aria-labelledby="versionWarningModalLabel" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title" id="versionWarningModalLabel">${modalTitle}</h5>
                            <button type="button" class="btn-close ms-auto" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body">
                            ${modalBody}
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">${translations['close_button']}</button>
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

        localStorage.setItem(storageKey, JSON.stringify({
            version: currentVersion,
            timestamp: now
        }));

        setTimeout(function() {
            modal.hide();
        }, 5000);
    }

    document.addEventListener('DOMContentLoaded', checkSingboxVersion);
</script>
<footer class="text-center"><p><?php echo $footer ?></p></footer>
