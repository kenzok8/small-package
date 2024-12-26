<?php

$repo_owner = "Thaolga";
$repo_name = "luci-app-nekoclash";
$package_name = "sing-box";

$new_version = isset($_GET['version']) ? $_GET['version'] : "v1.11.0-alpha.10";  
$new_version_cleaned = str_replace('v', '', $new_version);

if (isset($_GET['check_version'])) {
    $api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest";
    $curl_command = "curl -s -H 'User-Agent: PHP' --connect-timeout 10 " . escapeshellarg($api_url);
    $latest_version_data = shell_exec($curl_command);
    $latest_version_info = json_decode($latest_version_data, true);

    if (isset($latest_version_info['tag_name'])) {
        $latest_version = $latest_version_info['tag_name'];
        echo "最新版本: v$latest_version";
    } else {
        echo "无法获取最新版本信息";
    }
    exit;
}

$arch = shell_exec("opkg info " . escapeshellarg($package_name) . " | grep 'Architecture'");

if (strpos($arch, 'aarch64') !== false || strpos($arch, 'arm') !== false) {
    $arch = "aarch64_generic";
    $download_url = "https://github.com/$repo_owner/$repo_name/releases/download/$new_version_cleaned/{$package_name}_{$new_version_cleaned}-1_aarch64_generic.ipk";
} elseif (strpos($arch, 'x86_64') !== false) {
    $arch = "x86_64";
    $download_url = "https://github.com/$repo_owner/$repo_name/releases/download/$new_version_cleaned/{$package_name}_{$new_version_cleaned}-1_x86_64.ipk";
} elseif (strpos($arch, 'mips') !== false) {
    $arch = "mips";
    $download_url = "https://github.com/$repo_owner/$repo_name/releases/download/$new_version_cleaned/{$package_name}_{$new_version_cleaned}-1_mips.ipk";
} else {
    die("当前设备架构不受支持");
}

$local_file = "/tmp/{$package_name}_{$new_version_cleaned}_{$arch}.ipk";

echo "<pre>最新版本: $new_version_cleaned</pre>";
echo "<pre>下载URL: $download_url</pre>";
echo "<pre id='logOutput'></pre>";

echo "<script>
        function appendLog(message) {
            document.getElementById('logOutput').innerHTML += message + '\\n';
        }
      </script>";
echo "<script>appendLog('开始下载...');</script>";

$curl_command = "curl -sL " . escapeshellarg($download_url) . " -o " . escapeshellarg($local_file);
exec($curl_command . " 2>&1", $output, $return_var);

if ($return_var !== 0 || !file_exists($local_file)) {
    echo "<pre>下载失败。输出: " . implode("\n", $output) . "</pre>";
    die("下载失败。未找到下载的文件。");
}
echo "<script>appendLog('下载完成。');</script>";

echo "<script>appendLog('更新软件包列表...');</script>";
$output = shell_exec("opkg update");
echo "<pre>$output</pre>";

echo "<script>appendLog('开始安装...');</script>";
$output = shell_exec("opkg install --force-reinstall " . escapeshellarg($local_file));
echo "<pre>$output</pre>";
echo "<script>appendLog('安装完成。');</script>";

unlink($local_file);

?>
