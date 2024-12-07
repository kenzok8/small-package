<?php

ini_set('memory_limit', '128M'); 

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

function getApiResponseWithCurl($api_url) {
    $response = shell_exec("curl -s -H 'User-Agent: PHP' --connect-timeout 10 " . escapeshellarg($api_url));
    return $response;
}

function getApiResponseWithWget($api_url) {
    $response = shell_exec("wget -qO- '$api_url'");
    return $response;
}

$response = getApiResponseWithCurl($api_url);

if ($response === false || empty($response)) {
    $response = getApiResponseWithWget($api_url);
    if ($response === false || empty($response)) {
        die("GitHub API 请求失败。请检查网络连接或稍后重试。");
    }
}

$data = json_decode($response, true);

if (json_last_error() !== JSON_ERROR_NONE) {
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
    echo "最新版本: $latest_version";  
    exit;
}

$download_url = $data['assets'][0]['browser_download_url'] ?? '';

if (empty($download_url)) {
    die("未找到下载链接，请检查发布版本的资源。");
}

echo "开始下载文件...\n";
$download_success = false;

if (shell_exec("which wget")) {
    exec("wget -O '$temp_file' '$download_url'", $output, $return_var);
    if ($return_var === 0) {
        $download_success = true;
    }
}

if (!$download_success && shell_exec("which curl")) {
    exec("curl -s -L -o '$temp_file' '$download_url'", $output, $return_var);
    if ($return_var === 0) {
        $download_success = true;
    }
}

if (!$download_success) {
    die("下载失败！请检查网络连接或稍后重试。");
}

if (!file_exists($temp_file)) {
    die("下载的文件不存在！");
}

echo "开始解压文件...\n";
exec("tar -xzf '$temp_file' -C '$install_path'", $output, $return_var);
if ($return_var !== 0) {
    echo "解压失败，错误信息: " . implode("\n", $output);
    die("解压失败！");
}

exec("chown -R root:root '$install_path' 2>&1", $output, $return_var);
if ($return_var !== 0) {
    echo "更改文件所有者失败，错误信息: " . implode("\n", $output);
    die();
}

writeVersionToFile($latest_version); 
echo "更新完成！当前版本: $latest_version";

unlink($temp_file);

?>
