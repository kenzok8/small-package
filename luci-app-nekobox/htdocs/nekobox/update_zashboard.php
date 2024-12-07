<?php

ini_set('memory_limit', '128M');

function getUiVersion() {
    $versionFile = '/etc/neko/ui/zashboard/version.txt';

    if (file_exists($versionFile)) {
        return trim(file_get_contents($versionFile));
    } else {
        return "版本文件不存在";
    }
}

function writeVersionToFile($version) {
    $versionFile = '/etc/neko/ui/zashboard/version.txt';
    file_put_contents($versionFile, $version);
}

$repo_owner = "Zephyruso";
$repo_name = "zashboard";
$api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest";

$curl_command = "curl -s -H 'User-Agent: PHP' --connect-timeout 10 " . escapeshellarg($api_url);
$response = shell_exec($curl_command);

if ($response === false || empty($response)) {
    die("GitHub API 请求失败，请检查网络连接或稍后再试。");
}

$data = json_decode($response, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    die("解析 GitHub API 响应失败: " . json_last_error_msg());
}

$latest_version = $data['tag_name'] ?? '';
$install_path = '/etc/neko/ui/zashboard';
$temp_file = '/tmp/dist.zip';

if (!is_dir($install_path)) {
    mkdir($install_path, 0755, true);
}

$current_version = getUiVersion();

if (isset($_GET['check_version'])) {
    echo "最新版本: $latest_version";
    exit;
}

$download_url = $data['assets'][0]['browser_download_url'] ?? '';

if (empty($download_url)) {
    die("未找到下载链接，请检查发布版本的资源。");
}

exec("wget -O '$temp_file' '$download_url'", $output, $return_var);
if ($return_var !== 0) {
    die("下载失败");
}

if (!file_exists($temp_file)) {
    die("下载的文件不存在");
}

echo "开始解压文件...\n";

$temp_extract_dir = '/tmp/dist_extract';
exec("unzip '$temp_file' -d '$temp_extract_dir'", $output, $return_var);
if ($return_var !== 0) {
    echo "解压失败，错误信息: " . implode("\n", $output);
    die("解压失败");
}
echo "解压成功\n";

$extracted_dir = "$temp_extract_dir/dist";
if (is_dir($extracted_dir)) {
    exec("mv $extracted_dir/* $install_path/", $output, $return_var);
    if ($return_var !== 0) {
        echo "移动提取的文件失败，错误信息: " . implode("\n", $output);
        die("移动提取的文件失败");
    }
    echo "已将提取的文件移动到安装目录。\n";

    exec("rm -rf $extracted_dir", $output, $return_var);
    if ($return_var !== 0) {
        echo "删除多余的 'dist' 文件夹失败，错误信息: " . implode("\n", $output);
    }
} else {
    echo "未找到 'dist' 目录。\n";
}

exec("chown -R root:root '$install_path' 2>&1", $output, $return_var);
if ($return_var !== 0) {
    echo "修改文件所有者失败，错误信息: " . implode("\n", $output) . "\n";
    die();
}
echo "文件所有者已更改为 root。\n";

writeVersionToFile($latest_version);
echo "更新完成！当前版本: $latest_version";

unlink($temp_file);
?>
