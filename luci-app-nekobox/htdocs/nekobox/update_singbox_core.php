<?php
$repo_owner = "Thaolga";
$repo_name = "openwrt-nekobox";
$package_name = "sing-box";
$new_version = "1.11.0-alpha.6";
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
$arch = shell_exec("opkg info " . escapeshellarg($package_name) . " | grep 'Architecture'");
if (strpos($arch, 'aarch64') !== false || strpos($arch, 'arm') !== false) {
    $arch = "aarch64_generic";
    $download_url = "https://github.com/$repo_owner/$repo_name/releases/download/$new_version/{$package_name}_1.11.0-alpha.6-1_aarch64_generic.ipk";
} elseif (strpos($arch, 'x86_64') !== false) {
    $arch = "x86_64";
    $download_url = "https://github.com/$repo_owner/$repo_name/releases/download/$new_version/{$package_name}_1.11.0-alpha.6-1_x86_64.ipk";
} elseif (strpos($arch, 'mips') !== false) {
    $arch = "mips";
    $download_url = "https://github.com/$repo_owner/$repo_name/releases/download/$new_version/{$package_name}_1.11.0-alpha.6-1_mips.ipk";
} else {
    die("当前设备架构不受支持");
}
$local_file = "/tmp/{$package_name}_{$new_version}_{$arch}.ipk";
echo "<pre>最新版本: $new_version</pre>";
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
echo "<script>appendLog('开始安装...');</script>";
$output = shell_exec("opkg install --force-reinstall " . escapeshellarg($local_file));
echo "<pre>$output</pre>";
echo "<script>appendLog('安装完成。');</script>";
unlink($local_file);
?>