<?php
$neko_dir="/etc/neko";
$neko_www="/www/nekobox";
$neko_bin="/usr/bin/mihomo";
$neko_status=exec("uci -q get neko.cfg.enabled");
$current = basename($_SERVER['PHP_SELF']);
$selected_config= exec("cat $neko_www/lib/selected_config.txt");
$neko_cfg = array();
$neko_cfg['redir']=exec("cat $selected_config | grep redir-port | awk '{print $2}'");
$neko_cfg['port'] = trim(exec("grep '^port:' $selected_config | awk '{print $2}'"));
$neko_cfg['socks']=exec("cat $selected_config | grep socks-port | awk '{print $2}'");
$neko_cfg['mixed']=exec("cat $selected_config | grep mixed-port | awk '{print $2}'");
$neko_cfg['tproxy']=exec("cat $selected_config | grep tproxy-port | awk '{print $2}'");
$neko_cfg['mode']=strtoupper(exec("cat $selected_config | grep mode | head -1 | awk '{print $2}'"));
$neko_cfg['echanced']=strtoupper(exec("cat $selected_config | grep enhanced-mode | awk '{print $2}'"));
$neko_cfg['secret'] = trim(exec("grep '^secret:' $selected_config | awk -F': ' '{print $2}'"));
$neko_cfg['ext_controller']=shell_exec("cat $selected_config | grep external-ui | awk '{print $2}'");

$singbox_path_file = "$neko_www/lib/singbox.txt";
$singbox_config_path = trim(exec("cat $singbox_path_file"));

$http_port = "Not obtained";
$mixed_port = "Not obtained";

if (file_exists($singbox_config_path)) {
    $json_content = file_get_contents($singbox_config_path);
    $config = json_decode($json_content, true);

    if (is_array($config) && isset($config['inbounds'])) {
        foreach ($config['inbounds'] as $inbound) {
            if (
                isset($inbound['type']) && $inbound['type'] === 'mixed' &&
                isset($inbound['tag']) && $inbound['tag'] === 'mixed' &&
                isset($inbound['listen_port'])
            ) {
                $mixed_port = $inbound['listen_port'];
            }

            if (
                isset($inbound['type']) && $inbound['type'] === 'http' &&
                isset($inbound['listen_port'])
            ) {
                $http_port = $inbound['listen_port'];
            }
        }
    }
} else {
    $http_port = "Config file not found";
    $mixed_port = "Config file not found";
}

$title = "Nekobox";
$titleLink = "#";

$configFile = '/etc/config/neko';
$enabled = null;
$singbox_enabled = null;
$iconHtml = '';

if (file_exists($configFile)) {
    $lines = file($configFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $line = trim($line);
        if (strpos($line, '#') === 0 || strpos($line, '//') === 0) {
            continue;
        }
        if (preg_match("/option\s+enabled\s+'(\d+)'/", $line, $matches)) {
            $enabled = intval($matches[1]);
        }
        if (preg_match("/option\s+singbox_enabled\s+'(\d+)'/", $line, $matches)) {
            $singbox_enabled = intval($matches[1]);
        }
    }
}

if ($singbox_enabled === 1) {
    $title .= " - Singbox";
    $titleLink = "https://github.com/SagerNet/sing-box";
    $iconHtml = '<img src="./assets/img/singbox.svg" alt="Singbox" class="me-2" style="width: 1.8rem; height: 1.8rem;">';
} elseif ($enabled === 1) {
    $title .= " - Mihomo";
    $titleLink = "https://github.com/MetaCubeX/mihomo";
    $iconHtml = '<img src="./assets/img/mihomo.png" alt="Mihomo" class="me-1" style="width: 2.8rem; height: 2.8rem;">';
} else {
    $iconHtml = '<i class="bi bi-palette-fill me-2" style="color: var(--accent-color); font-size: 1.8rem;"></i>';
}
$footer = '<span class="footer-text">©2025 <b>Thaolga</b></span>';
?>
