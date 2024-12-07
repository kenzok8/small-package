<?php

ini_set('memory_limit', '128M');

function getUiVersion() {
    $versionFile = '/etc/neko/ui/zashboard/version.txt';
    return file_exists($versionFile) ? trim(file_get_contents($versionFile)) : "版本文件不存在";
}

function writeVersionToFile($version) {
    file_put_contents('/etc/neko/ui/zashboard/version.txt', $version);
}

$repo_owner = "Zephyruso";
$repo_name = "zashboard";
$api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest";

$response = shell_exec("curl -s -H 'User-Agent: PHP' --connect-timeout 10 " . escapeshellarg($api_url));

if ($response === false || empty($response)) {
    die("GitHub API 请求失败");
}

$data = json_decode($response, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    die("解析 GitHub API 响应失败");
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
    die("未找到下载链接");
}

exec("wget -O '$temp_file' '$download_url'", $output, $return_var);
if ($return_var !== 0) {
    die("下载失败");
}

if (!file_exists($temp_file)) {
    die("下载的文件不存在");
}

exec("rm -rf /tmp/dist_extract", $output, $return_var);
if ($return_var !== 0) {
    die("清理临时解压目录失败");
}

exec("unzip -o '$temp_file' -d '/tmp/dist_extract'", $output, $return_var);
if ($return_var !== 0) {
    die("解压失败");
}

$extracted_dist_dir = "/tmp/dist_extract/dist";
if (is_dir($extracted_dist_dir)) {
    exec("rm -rf $install_path/*", $output, $return_var);
    if ($return_var !== 0) {
        die("删除旧文件失败");
    }

    exec("mv $extracted_dist_dir/* $install_path/", $output, $return_var);
    if ($return_var !== 0) {
        die("移动提取的文件失败");
    }

    exec("rm -rf /tmp/dist_extract", $output, $return_var);
    if ($return_var !== 0) {
        die("删除临时解压目录失败");
    }
} else {
    die("未找到 'dist' 目录，解压失败");
}

exec("chown -R root:root '$install_path' 2>&1", $output, $return_var);
if ($return_var !== 0) {
    die("修改文件所有者失败");
}

writeVersionToFile($latest_version);
echo "更新完成！当前版本: $latest_version";

unlink($temp_file);
?>
