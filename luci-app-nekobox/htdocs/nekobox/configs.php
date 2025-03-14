<?php
include './cfg.php';
$dirPath = "$neko_dir/config";
$tmpPath = "$neko_www/lib/selected_config.txt";
$arrFiles = array();
$arrFiles = glob("$dirPath/*.yaml"); 
$error = "";
$logMessage = "";  
$selected_config = trim(file_get_contents($tmpPath));

if (empty($selected_config) || !file_exists($selected_config)) {
    $selected_config = "$dirPath/default_config.yaml";
    file_put_contents($tmpPath, $selected_config);
}

if (isset($_POST['clashconfig'])) {
    $dt = $_POST['clashconfig'];
    $full_path = "$dirPath/$dt";
    if (pathinfo($dt, PATHINFO_EXTENSION) === 'yaml' && file_exists($full_path)) {
        shell_exec("echo $full_path > $tmpPath");  
        $selected_config = $full_path;
    } else {
        $error = "Please select a valid YAML configuration file"; 
    }
}

if (isset($_POST['neko'])) {
    $dt = $_POST['neko'];
    if ($dt == 'apply') shell_exec("$neko_dir/core/neko -r");
}

include './cfg.php';
?>
<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme, 0, -4); ?>">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Configs - Nekobox</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/bootstrap.min.js"></script>
  </head>
  <body>
    <div class="container-sm container-bg text-center callout border border-3 rounded-4 col-11">
        <div class="row">
    <h2 class="text-center p-2">Configs</h2>
    <form action="configs.php" method="post">
        <div class="container text-center justify-content-md-center">
            <div class="row justify-content-md-center">
                <div class="col input-group mb-3 justify-content-md-center">
                    <select class="form-select" name="clashconfig" aria-label="themex">
                        <option selected><?php echo basename($selected_config); ?></option>
                        <?php foreach ($arrFiles as $file) echo "<option value=\"" . basename($file) . '">' . basename($file) . "</option>"; ?>
                    </select>
                </div>
                <div class="row justify-content-md-center">
                    <div class="btn-group d-grid d-md-flex justify-content-md-center mb-5" role="group">
                        <input class="btn btn-info" type="submit" value="Change Configs">
                        <button name="neko" type="submit" value="apply" class="btn btn-warning d-grid">Apply</button>
                    </div>
                </div>
            </div>
        </div>
    </form>
    <div class="container mt-4">
        <?php if ($logMessage): ?>
            <div class="alert alert-info" role="alert">
                <?php echo htmlspecialchars($logMessage); ?>
            </div>
        <?php endif; ?>
    </div>
<div class="container   rounded-4 col-12 mb-4">
    <ul class="nav d-flex justify-content-between w-100 text-center">
        <li class="nav-item flex-grow-1">
            <a class="btn btn-lg w-100 active" data-bs-toggle="tab" href="#info">Info</a>
        </li>
        <li class="nav-item flex-grow-1">
            <a class="btn btn-lg w-100" data-bs-toggle="tab" href="#proxy">Proxy</a>
        </li>
        <li class="nav-item flex-grow-1">
            <a class="btn btn-lg w-100" data-bs-toggle="tab" href="#rules">Rules</a>
        </li>
        <li class="nav-item flex-grow-1">
            <a class="btn btn-lg w-100" data-bs-toggle="tab" href="#converter">Converter</a>
        </li>
        <li class="nav-item flex-grow-1">
            <a class="btn btn-lg w-100" data-bs-toggle="tab" href="#tip">Tips</a>
        </li>
    </ul>
</div>
   <div class="container rounded-4 col-12 mb-4">
    <div class="tab-content">
        <div id="info" class="tab-pane fade show active">
                    <h2 class="text-center p-2">Config Information</h2>
                    <table class="table table-borderless callout mb-5">
                        <tbody>
                            <tr class="text-center">
                                <td class="col-2">PORT</td>
                                <td class="col-2">REDIR</td>
                                <td class="col-2">SOCKS</td>
                            </tr>
                            <tr class="text-center">
                                <td class="col-2">
                                    <input class="form-control text-center" name="port" type="text" placeholder="<?php echo $neko_cfg['port'] ?>" disabled>
                                </td>
                                <td class="col-2">
                                    <input class="form-control text-center" name="redir" type="text" placeholder="<?php echo $neko_cfg['redir'] ?>" disabled>
                                </td>
                                <td class="col-2">
                                    <input class="form-control text-center" name="socks" type="text" placeholder="<?php echo $neko_cfg['socks'] ?>" disabled>
                                </td>
                            </tr>
                            <tr class="text-center">
                                <td class="col-2">MIXED</td>
                                <td class="col-2">TPROXY</td>
                                <td class="col-2">MODE</td>
                            </tr>
                            <tr class="text-center">
                                <td class="col-2">
                                    <input class="form-control text-center" name="mixed" type="text" placeholder="<?php echo $neko_cfg['mixed'] ?>" disabled>
                                </td>
                                <td class="col-2">
                                    <input class="form-control text-center" name="tproxy" type="text" placeholder="<?php echo $neko_cfg['tproxy'] ?>" disabled>
                                </td>
                                <td class="col-2">
                                    <input class="form-control text-center" name="mode" type="text" placeholder="<?php echo $neko_cfg['mode'] ?>" disabled>
                                </td>
                            </tr>
                            <tr class="text-center">
                                <td class="col-2">ENHANCED</td>
                                <td class="col-2">SECRET</td>
                                <td class="col-2">CONTROLLER</td>
                            </tr>
                            <tr class="text-center">
                                <td class="col-2">
                                    <input class="form-control text-center" name="ech" type="text" placeholder="<?php echo $neko_cfg['echanced'] ?>" disabled>
                                </td>
                                <td class="col-2">
                                    <input class="form-control text-center" name="sec" type="text" placeholder="<?php echo $neko_cfg['secret'] ?>" disabled>
                                </td>
                                <td class="col-2">
                                    <input class="form-control text-center" name="ext" type="text" placeholder="<?php echo $neko_cfg['ext_controller'] ?>" disabled>
                                </td>
                            </tr>
                         </tbody>
                      </table>
                    <h2 class="text-center p-2">Configs</h2>
                 <div class="container h-100 mb-5">
                <iframe class="rounded-4 w-100" scrolling="no" height="700" src="./configconf.php" title="yacd" allowfullscreen></iframe>
            </div>
        </div>

        <div id="proxy" class="tab-pane fade">
            <h2 class="text-center p-2">Proxy Editor</h2>
            <div class="container h-100 mb-5">
                <iframe class="rounded-4 w-100" scrolling="no" height="700" src="./proxyconf.php" title="yacd" allowfullscreen></iframe>
            </div>
        </div>

        <div id="rules" class="tab-pane fade">
            <h2 class="text-center p-2">Rules Editor</h2>
            <div class="container h-100 mb-5">
                <iframe class="rounded-4 w-100" scrolling="no" height="700" src="./rulesconf.php" title="yacd" allowfullscreen></iframe>
            </div>
        </div>

        <div id="converter" class="tab-pane fade">
            <h2 class="text-center p-2 mb-5">Converter</h2>
            <div class="container h-100">
                <iframe class="rounded-4 w-100" scrolling="no" height="700" src="./yamlconv.php" title="yacd" allowfullscreen></iframe>
            </div>
        </div>

        <div id="tip" class="tab-pane fade">
            <h2 class="text-center p-2 mb-3">Tips</h2>
            <div class="container text-center border border-3 rounded-4 col-10 mb-4">
                <p style="color: #87CEEB; text-align: left;">
                    <h1 style="font-size: 24px; color: #87CEEB; margin-bottom: 20px;"><strong>Player Function Description</strong></h1>
                    <div style="text-align: left; display: inline-block; margin-bottom: 20px;">
                        <strong>1. Song Push and Control:</strong><br>
                        &emsp; 1 The player pushes songs via GitHub playlists.<br>
                        &emsp; 2 Use the keyboard arrow keys to switch songs.<br>
                        &emsp; 3 Enter <code>nekobox</code> in the terminal to update the client and core.<br><br>

                        <strong>2. Playback Function:</strong><br>
                        &emsp; 1 Auto-play the next song: If playback is enabled, the next song will automatically play. When the song list reaches the end, it will loop back to the first song.<br>
                        &emsp; 2 Enable/Disable Playback: Click or press the Escape key to enable or disable playback. When disabled, the current playback will stop, and no new songs can be selected or played.<br><br>

                        <strong>3. Keyboard Control:</strong><br>
                        &emsp; 1 Provides quick control with the arrow keys ⇦ ⇨ and spacebar, supporting switching between previous and next songs, and play/pause.<br><br>

                        <strong>4. Playback Modes:</strong><br>
                        &emsp; 1 Loop and Sequential Playback: You can switch between loop and sequential playback modes using buttons and the keyboard shortcut ⇧.<br><br>

                    </div>
                </p>

                <?php
                    error_reporting(E_ALL);
                    ini_set('display_errors', 1);

                    $output = [];
                    $return_var = 0;
                    exec('uci get network.lan.ipaddr 2>&1', $output, $return_var);
                    $routerIp = trim(implode("\n", $output));

                    function isValidIp($ip) {
                        $parts = explode('.', $ip);
                        if (count($parts) !== 4) return false;
                        foreach ($parts as $part) {
                            if (!is_numeric($part) || (int)$part < 0 or (int)$part > 255) return false;
                        }
                        return true;
                    }

                    if (isValidIp($routerIp) && !in_array($routerIp, ['0.0.0.0', '255.255.255.255'])) {
                        $controlPanelUrl = "http://$routerIp/nekobox";
                        echo '<div style="text-align: center; margin-top: 20px;"><span style="color: #87CEEB;">Standalone Control Panel Address:</span> <a href="' . $controlPanelUrl . '" style="color: red;" target="_blank"><code>' . $controlPanelUrl . '</code></a></div>';
                    } else {
                        echo "<div style='text-align: center; margin-top: 20px;'>Unable to retrieve the router IP address. Error message: $routerIp</div>";
                    }
                ?>
            </div>
        </div>
    </div>

    <footer style="text-align: center; margin-top: 20px;">
        <p><?php echo $footer ?></p>
    </footer>
</body>
</html>
