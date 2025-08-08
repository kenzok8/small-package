<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $mihomo_ports = [
        'socks-port'  => (int)$_POST['mihomo_socks'],
        'mixed-port'  => (int)$_POST['mihomo_mixed'],
        'redir-port'  => (int)$_POST['mihomo_redir'],
        'port'        => (int)$_POST['mihomo_port'],
        'tproxy-port' => (int)$_POST['mihomo_tproxy'],
    ];

    $singbox_ports = [
        'http_proxy' => (int)$_POST['singbox_http'],
        'mixed'      => (int)$_POST['singbox_mixed']
    ];

    $selected_config_path = './lib/selected_config.txt';
    if (file_exists($selected_config_path)) {
        $cfg_file = trim(file_get_contents($selected_config_path));
        if (file_exists($cfg_file)) {
            foreach ($mihomo_ports as $key => $port) {
                shell_exec("sed -i 's/^$key:.*/$key: $port/' \"$cfg_file\"");
            }
        }
    }

    $singbox_config_path = './lib/singbox.txt';
    if (file_exists($singbox_config_path)) {
        $singbox_file = trim(file_get_contents($singbox_config_path));
        if (file_exists($singbox_file)) {
            $json = file_get_contents($singbox_file);
            $config = json_decode($json, true);
            if ($config && isset($config['inbounds'])) {
                foreach ($config['inbounds'] as &$inbound) {
                    if ($inbound['type'] === 'mixed' && (!isset($inbound['tag']) || $inbound['tag'] !== 'mixed-in')) {
                        $inbound['listen_port'] = $singbox_ports['mixed'];
                    }

                    if ($inbound['type'] === 'http' && isset($inbound['tag']) && $inbound['tag'] === 'http-in') {
                        $inbound['listen_port'] = $singbox_ports['http_proxy'];
                    }
                }

                file_put_contents(
                    $singbox_file,
                    json_encode($config, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE)
                );
            }
        }
    }

    header('Location: index.php?port_updated=1');
    exit;
}
?>
