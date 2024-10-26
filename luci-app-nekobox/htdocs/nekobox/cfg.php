<?php

// NEKO CONFIGURATION
$neko_dir="/etc/neko";
$neko_www="/www/nekobox";
$neko_bin="$neko_dir/core/mihomo";
$neko_theme= exec("cat $neko_www/lib/theme.txt");
$neko_status=exec("uci -q get neko.cfg.enabled");

$selected_config= exec("cat $neko_www/lib/selected_config.txt");
$neko_cfg = array();
$neko_cfg['redir']=exec("cat $selected_config | grep redir-port | awk '{print $2}'");
$neko_cfg['port']=exec("cat $selected_config | grep port: | awk '{print $2}'");
$neko_cfg['socks']=exec("cat $selected_config | grep socks-port | awk '{print $2}'");
$neko_cfg['mixed']=exec("cat $selected_config | grep mixed-port | awk '{print $2}'");
$neko_cfg['tproxy']=exec("cat $selected_config | grep tproxy-port | awk '{print $2}'");
$neko_cfg['mode']=strtoupper(exec("cat $selected_config | grep mode | head -1 | awk '{print $2}'"));
$neko_cfg['echanced']=strtoupper(exec("cat $selected_config | grep enhanced-mode | awk '{print $2}'"));
$neko_cfg['secret']=exec("cat $selected_config | grep secret | awk '{print $2}'");
$neko_cfg['ext_controller']=shell_exec("cat $selected_config | grep external-ui | awk '{print $2}'");

$footer = '<span style="color: red;">©2024 <b>Thaolga</b></span>';
?>
