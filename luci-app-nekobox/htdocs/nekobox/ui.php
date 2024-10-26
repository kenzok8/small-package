<?php

ini_set('memory_limit', '128M'); 

function logMessage($message) {
    $logFile = '/var/log/sing-box_update.log'; 
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($logFile, "[$timestamp] $message\n", FILE_APPEND);
}

function getUiVersion() {
    $versionFile = '/etc/neko/ui/metacubexd/version.txt';
    
    if (file_exists($versionFile)) {
        return trim(file_get_contents($versionFile));
    } else {
        return "版本文件不存在";
    }
}

function writeVersionToFile($version) {
    $versionFile = '/etc/neko/ui/metacubexd/version.txt';
    file_put_contents($versionFile, $version);
}

$repo_owner = "MetaCubeX";
$repo_name = "metacubexd";
$api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest";

$curl_command = "curl -s -H 'User-Agent: PHP' --connect-timeout 10 " . escapeshellarg($api_url);
$response = shell_exec($curl_command);

if ($response === false || empty($response)) {
    logMessage("GitHub API 请求失败，可能是网络问题或 GitHub API 限制。");
    die("GitHub API 请求失败。请检查网络连接或稍后重试。");
}

$data = json_decode($response, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    logMessage("解析 GitHub API 响应时出错: " . json_last_error_msg());
    die("解析 GitHub API 响应时出错: " . json_last_error_msg());
}

$latest_version = $data['tag_name'] ?? '';
$install_path = '/etc/neko/ui/metacubexd';
$temp_file = '/tmp/compressed-dist.tgz';

if (!is_dir($install_path)) {
    mkdir($install_path, 0755, true);
}

$current_version = getUiVersion();

if (isset($_GET['check_version'])) {
    if (trim($current_version) === trim($latest_version)) {
        echo "当前版本已是最新: $current_version";
    } else {
        echo "最新版本: $latest_version";
    }
    exit;
}

$download_url = $data['assets'][0]['browser_download_url'] ?? '';

if (empty($download_url)) {
    die("未找到下载链接，请检查发布版本的资源。");
}

exec("wget -O '$temp_file' '$download_url'", $output, $return_var);
if ($return_var !== 0) {
    die("下载失败！");
}

exec("tar -xzf '$temp_file' -C '$install_path'", $output, $return_var);
if ($return_var !== 0) {
    die("解压失败！");
}

writeVersionToFile($latest_version); 
echo "更新完成！当前版本: $latest_version";

unlink($temp_file);
?>
