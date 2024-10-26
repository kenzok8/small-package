<?php
if (isset($_POST['action']) && $_POST['action'] === 'update_config') {
    $configFilePath = '/etc/neko/config/mihomo.yaml'; 
    $url = 'https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/nekobox/luci-app-nekobox/root/etc/neko/config/mihomo.yaml';

    $ch = curl_init($url);
    $fp = fopen($configFilePath, 'w');

    curl_setopt($ch, CURLOPT_FILE, $fp);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); 

    $success = curl_exec($ch);
    curl_close($ch);
    fclose($fp);

    if ($success) {
        echo "<script>alert('Mihomo 配置文件已更新成功！');</script>";
        error_log("Mihomo 配置文件已更新成功！");
    } else {
        echo "<script>alert('配置文件更新失败！');</script>";
        error_log("配置文件更新失败！");
    }
}
?>
