<?php
include './cfg.php';
$dirPath = "$neko_dir/config";
$tmpPath = "$neko_www/lib/selected_config.txt";
$arrFiles = array();
$arrFiles = glob("$dirPath/*.yaml"); 
$error = "";

if (isset($_POST['clashconfig'])) {
    $dt = $_POST['clashconfig'];
    
    if (pathinfo($dt, PATHINFO_EXTENSION) === 'yaml') {
        shell_exec("echo $dt > $tmpPath");
        $selected_config = $dt;
    } else {
        $error = "请选择一个 YAML 格式的配置文件。"; 
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
    <title>Configs - Neko</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/bootstrap.min.js"></script>
    <?php include './ping.php'; ?>
  </head>
  <body>
    <div class="container-sm container-bg text-center callout border border-3 rounded-4 col-11">
        <div class="row">
            <a href="./" class="col btn btn-lg">🏠 首页</a>
            <a href="./dashboard.php" class="col btn btn-lg">📊 面板</a>
            <a href="#" class="col btn btn-lg">⚙️ 配置</a>
           <a href="/nekobox/mon.php" class="col btn btn-lg d-flex align-items-center justify-content-center"></i>📦 订阅</a> 
            <a href="./settings.php" class="col btn btn-lg">🛠️ 设定</a>
    <h2 class="text-center p-2">配置</h2>
    <form action="configs.php" method="post">
        <div class="container text-center justify-content-md-center">
            <div class="row justify-content-md-center">
                <div class="col input-group mb-3 justify-content-md-center">
                    <select class="form-select" name="clashconfig" aria-label="themex">
                        <option selected><?php echo $selected_config; ?></option>
                        <?php foreach ($arrFiles as $file) echo "<option value=\"" . $file . '">' . $file . "</option>"; ?>
                    </select>
                </div>
                <div class="row justify-content-md-center">
                    <div class="btn-group d-grid d-md-flex justify-content-md-center mb-5" role="group">
                        <input class="btn btn-info" type="submit" value="更改配置">
                        <button name="neko" type="submit" value="应用" class="btn btn-warning d-grid">应用</button>
                    </div>
                </div>
            </div>
        </div>
    </form>
<div class="container   rounded-4 col-12 mb-4">
    <ul class="nav d-flex justify-content-between w-100 text-center">
        <li class="nav-item flex-grow-1">
            <a class="btn btn-lg w-100 active" data-bs-toggle="tab" href="#info">配置</a>
        </li>
        <li class="nav-item flex-grow-1">
            <a class="btn btn-lg w-100" data-bs-toggle="tab" href="#proxy">代理</a>
        </li>
        <li class="nav-item flex-grow-1">
            <a class="btn btn-lg w-100" data-bs-toggle="tab" href="#rules">规则</a>
        </li>
        <li class="nav-item flex-grow-1">
            <a class="btn btn-lg w-100" data-bs-toggle="tab" href="#converter">转换</a>
        </li>
        <li class="nav-item flex-grow-1">
            <a class="btn btn-lg w-100" data-bs-toggle="tab" href="#upload">订阅</a>
        </li>
        <li class="nav-item flex-grow-1">
            <a class="btn btn-lg w-100" data-bs-toggle="tab" href="#tip">提示</a>
        </li>
    </ul>
</div>

   <div class="container rounded-4 col-12 mb-4">
    <div class="tab-content">
        <div id="info" class="tab-pane fade show active">
            <h2 class="text-center p-2">配置资讯</h2>
            <table class="table table-borderless callout mb-5">
                <tbody>
                    <tr class="text-center">
                        <td class="col-2">HTTP 端口</td>
                        <td class="col-2">Redir 端口</td>
                        <td class="col-2">Socks 端口</td>
                    </tr>
                    <tr class="text-center">
                        <td class="col-2">
                            <input class="form-control text-center" name="port" type="text" placeholder="<?php echo $neko_cfg['port']; ?>" disabled>
                        </td>
                        <td class="col-2">
                            <input class="form-control text-center" name="redir" type="text" placeholder="<?php echo $neko_cfg['redir']; ?>" disabled>
                        </td>
                        <td class="col-2">
                            <input class="form-control text-center" name="socks" type="text" placeholder="<?php echo $neko_cfg['socks']; ?>" disabled>
                        </td>
                    </tr>
                    <tr class="text-center">
                        <td class="col-2">混合 端口</td>
                        <td class="col-2">TProxy 端口</td>
                        <td class="col-2">模式</td>
                    </tr>
                    <tr class="text-center">
                        <td class="col-2">
                            <input class="form-control text-center" name="mixed" type="text" placeholder="<?php echo $neko_cfg['mixed']; ?>" disabled>
                        </td>
                        <td class="col-2">
                            <input class="form-control text-center" name="tproxy" type="text" placeholder="<?php echo $neko_cfg['tproxy']; ?>" disabled>
                        </td>
                        <td class="col-2">
                            <input class="form-control text-center" name="mode" type="text" placeholder="<?php echo $neko_cfg['mode']; ?>" disabled>
                        </td>
                    </tr>
                    <tr class="text-center">
                        <td class="col-2">增强型</td>
                        <td class="col-2">密钥</td>
                        <td class="col-2">控制器</td>
                    </tr>
                    <tr class="text-center">
                        <td class="col-2">
                            <input class="form-control text-center" name="ech" type="text" placeholder="<?php echo $neko_cfg['echanced']; ?>" disabled>
                        </td>
                        <td class="col-2">
                            <input class="form-control text-center" name="sec" type="text" placeholder="<?php echo $neko_cfg['secret']; ?>" disabled>
                        </td>
                        <td class="col-2">
                            <input class="form-control text-center" name="ext" type="text" placeholder="<?php echo $neko_cfg['ext_controller']; ?>" disabled>
                        </td>
                    </tr>
                </tbody>
            </table>
            <h2 class="text-center p-2">配置</h2>
            <div class="container h-100 mb-5">
                <iframe class="rounded-4 w-100" scrolling="no" height="700" src="./configconf.php" title="yacd" allowfullscreen></iframe>
            </div>
        </div>

        <div id="proxy" class="tab-pane fade">
            <h2 class="text-center p-2">代理编辑器</h2>
            <div class="container h-100 mb-5">
                <iframe class="rounded-4 w-100" scrolling="no" height="700" src="./proxyconf.php" title="yacd" allowfullscreen></iframe>
            </div>
        </div>

        <div id="rules" class="tab-pane fade">
            <h2 class="text-center p-2">规则编辑器</h2>
            <div class="container h-100 mb-5">
                <iframe class="rounded-4 w-100" scrolling="no" height="700" src="./rulesconf.php" title="yacd" allowfullscreen></iframe>
            </div>
        </div>

        <div id="converter" class="tab-pane fade">
            <h2 class="text-center p-2 mb-5">转换器</h2>
            <div class="container h-100">
                <iframe class="rounded-4 w-100" scrolling="no" height="700" src="./yamlconv.php" title="yacd" allowfullscreen></iframe>
            </div>
        </div>

        <div id="upload" class="tab-pane fade">
            <div class="container h-100">
                <iframe class="rounded-4 w-100" scrolling="no" height="700" src="./mo.php" title="yacd" allowfullscreen></iframe>
            </div>
        </div>

        <div id="tip" class="tab-pane fade">
            <h2 class="text-center p-2 mb-3">小提示</h2>
            <div class="container text-center border border-3 rounded-4 col-10 mb-4">
                <p style="color: #87CEEB; text-align: left;">
         <h1 style="font-size: 24px; color: #87CEEB; margin-bottom: 20px;"><strong>播放器功能说明</strong></h1>
        <div style="text-align: left; display: inline-block; margin-bottom: 20px;">
            <strong>1. 歌曲推送和控制：</strong><br>
            &emsp; 1 播放器通过 GitHub 歌单推送歌曲。<br>
            &emsp; 2 使用键盘方向键可以切换歌曲。<br>
            &emsp; 3 终端输入 <code>nekobox</code> 可以更新客户端和核心。<br><br>

            <strong>2. 播放功能：</strong><br>
            &emsp; 1 自动播放下一首歌曲：如果启用了播放功能，自动播放下一首歌曲。歌曲列表到达末尾时，会循环到第一首歌曲。<br>
            &emsp; 2 启用/禁用播放：通过点击或按下 Escape 键，可以启用或禁用播放功能。当禁用时，当前播放将被停止，并且无法选择或播放新歌曲。<br><br>

            <strong>3. 键盘控制：</strong><br>
            &emsp; 1 提供了箭头 ⇦ ⇨ 键和空格键的快捷控制，支持上下首切换和播放/暂停。<br><br>

            <strong>4. 播放模式：</strong><br>
            &emsp; 1 循环播放和顺序播放：可以通过按钮和键盘快捷 ⇧ 键切换循环播放和顺序播放的模式。<br><br>
            
        </div>

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
                echo '<div style="text-align: center; margin-top: 20px;"><span style="color: #87CEEB;">独立控制面板地址:</span> <a href="' . $controlPanelUrl . '" style="color: red;" target="_blank"><code>' . $controlPanelUrl . '</code></a></div>';
            } else {
                echo "<div style='text-align: center; margin-top: 20px;'>无法获取路由器的 IP 地址。错误信息: $routerIp</div>";
            }
        ?>
    </div>

    <footer style="text-align: center; margin-top: 20px;">
        <p><?php echo $footer ?></p>
    </footer>
</body>
</html>
