<?php
$repo_owner = "Thaolga";
$repo_name = "openwrt-nekobox";
$package_name = "luci-app-nekobox";

$api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest";
$local_api_response = "/tmp/api_response.json";

$curl_command = "curl -H 'User-Agent: PHP' -s " . escapeshellarg($api_url) . " -o " . escapeshellarg($local_api_response);
exec($curl_command . " 2>&1", $output, $return_var);

if (!file_exists($local_api_response)) {
    die("无法访问GitHub API。请检查URL或网络连接。输出: " . implode("\n", $output));
}

$response = file_get_contents($local_api_response);
$data = json_decode($response, true);
unlink($local_api_response);

$new_version = $data['tag_name'] ?? '';

if (empty($new_version)) {
    die("未找到最新版本或版本信息为空。");
}

if (isset($_GET['check_version'])) {
    echo "最新版本: V" . $new_version; 
    exit;
}

$installed_package_info = shell_exec("opkg status " . escapeshellarg($package_name));
$installed_lang = 'cn';

if (strpos($installed_package_info, '-cn') !== false) {
    $installed_lang = 'cn'; 
} elseif (strpos($installed_package_info, '-en') !== false) {
    $installed_lang = 'en';
}

$download_url = "https://github.com/$repo_owner/$repo_name/releases/download/$new_version/{$package_name}_{$new_version}-{$installed_lang}_all.ipk";

echo "<pre>最新版本: $new_version</pre>";
echo "<pre>下载URL: $download_url</pre>";
echo "<pre id='logOutput'></pre>";

echo "<script>
        function appendLog(message) {
            document.getElementById('logOutput').innerHTML += message + '\\n';
        }
      </script>";

echo "<script>appendLog('开始下载更新...');</script>";

$local_file = "/tmp/{$package_name}_{$new_version}-{$installed_lang}_all.ipk";
$curl_command = "curl -sL " . escapeshellarg($download_url) . " -o " . escapeshellarg($local_file);
exec($curl_command . " 2>&1", $output, $return_var);

if ($return_var !== 0 || !file_exists($local_file)) {
    echo "<pre>下载失败。命令输出: " . implode("\n", $output) . "</pre>";
    die("下载失败。未找到下载的文件。");
}

echo "<script>appendLog('下载完成。');</script>";

$output = shell_exec("opkg install --force-reinstall " . escapeshellarg($local_file));
echo "<pre>$output</pre>";
echo "<script>appendLog('安装完成。');</script>";

unlink($local_file);
?>
