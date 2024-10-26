<?php

include './cfg.php';

$neko_cfg['ctrl_host'] = $_SERVER['SERVER_NAME'];

$command = "cat $selected_config | grep external-c | awk '{print $2}' | cut -d: -f2";
$port_output = shell_exec($command);

if ($port_output === null) {
    $neko_cfg['ctrl_port'] = 'default_port'; 
} else {
    $neko_cfg['ctrl_port'] = trim($port_output);
}

$yacd_link = $neko_cfg['ctrl_host'] . ':' . $neko_cfg['ctrl_port'] . '/ui/meta?hostname=' . $neko_cfg['ctrl_host'] . '&port=' . $neko_cfg['ctrl_port'] . '&secret=' . $neko_cfg['secret'];
$meta_link = $neko_cfg['ctrl_host'] . ':' . $neko_cfg['ctrl_port'] . '/ui/metacubexd?hostname=' . $neko_cfg['ctrl_host'] . '&port=' . $neko_cfg['ctrl_port'] . '&secret=' . $neko_cfg['secret'];
$dashboard_link = $neko_cfg['ctrl_host'] . ':' . $neko_cfg['ctrl_port'] . '/ui/dashboard?hostname=' . $neko_cfg['ctrl_host'] . '&port=' . $neko_cfg['ctrl_port'] . '&secret=' . $neko_cfg['secret'];

?>
<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme,0,-4) ?>">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Dashboard - Neko</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
  </head>
  <body>
<head>
<div class="container-sm container-bg text-center callout border border-3 rounded-4 col-11">
    <div class="row">
        <a href="./" class="col btn btn-lg">🏠 首页</a>
        <a href="#" class="col btn btn-lg">📊 面板</a>
        <a href="./configs.php" class="col btn btn-lg">⚙️ 配置</a>
        <a href="/nekobox/mon.php" class="col btn btn-lg d-flex align-items-center justify-content-center">📦 订阅</a> 
        <a href="./settings.php" class="col btn btn-lg">🛠️ 设定</a>
    </div>

<div class="container text-left p-3">
        <div class="container h-100 mb-5">
            <h2 class="text-center p-2">Meta 面板</h2>
            <iframe class="border border-3 rounded-4 w-100" style="height: 70vh;" src="http://<?php echo $yacd_link; ?>" title="yacd" allowfullscreen></iframe>
            <table class="table table-borderless callout mb-2">
                <tbody>
                    <tr class="text-center d-flex flex-wrap justify-content-center">
                        <td><a class="btn btn-info btn-sm text-white" target="_blank" href="http://<?php echo $yacd_link; ?>">YACD-META 面板</a></td>
                        <td><a class="btn btn-info btn-sm text-white" target="_blank" href="http://<?php echo $dashboard_link; ?>">DASHBOARD 面板</a></td>
                        <td><a class="btn btn-info btn-sm text-white" target="_blank" href="http://<?php echo $meta_link; ?>">METACUBEXD 面板</a></td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <footer class="text-center">
        <p><?php echo $footer; ?></p>
    </footer>
</div>
</body>
</html>

