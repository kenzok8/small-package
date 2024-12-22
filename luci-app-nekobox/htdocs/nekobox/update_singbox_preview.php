<?php
ini_set('memory_limit', '128M'); 

function logMessage($message) {
    $logFile = '/var/log/sing-box_update.log'; 
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($logFile, "[$timestamp] $message\n", FILE_APPEND);
}

function writeVersionToFile($version) {
    $versionFile = '/etc/neko/core/version.txt';
    file_put_contents($versionFile, $version);
}

$repo_owner = "SagerNet";
$repo_name = "sing-box";
$api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases";

$curl_command = "curl -s -H 'User-Agent: PHP' --connect-timeout 10 " . escapeshellarg($api_url);
$response = shell_exec($curl_command);

if ($response === false || empty($response)) {
    logMessage("GitHub API request using curl failed, trying wget...");
    $wget_command = "wget -q --no-check-certificate --timeout=10 " . escapeshellarg($api_url) . " -O /tmp/api_response.json";
    exec($wget_command, $output, $return_var);

    if ($return_var !== 0 || !file_exists('/tmp/api_response.json')) {
        logMessage("GitHub API request using wget failed.");
        die("GitHub API request failed. Please check your network connection or try again later.");
    }

    $response = file_get_contents('/tmp/api_response.json');
    unlink('/tmp/api_response.json');
}

logMessage("GitHub API response: " . substr($response, 0, 200) . "...");

$data = json_decode($response, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    logMessage("Error parsing GitHub API response: " . json_last_error_msg());
    die("Error parsing GitHub API response: " . json_last_error_msg());
}

$latest_version = '';
if (is_array($data)) {
    foreach ($data as $release) {
        if (isset($release['tag_name'])) {
            $tag_name = $release['tag_name'];

            if (preg_match('/^v[\d\.]+-[a-zA-Z]+/', $tag_name)) {
                $latest_version = $tag_name;
                break; 
            }
        }
    }
}

if (empty($latest_version)) {
    logMessage("No version information found.");
    die("No version information found.");
}

$current_version = ''; 
$install_path = '/usr/bin/sing-box'; 
$temp_file = '/tmp/sing-box.tar.gz'; 
$temp_dir = '/tmp/singbox_temp'; 

if (file_exists($install_path)) {
    $current_version = trim(shell_exec("{$install_path} --version"));
}

$current_arch = trim(shell_exec("uname -m"));
$base_version = ltrim($latest_version, 'v');
$download_url = '';

switch ($current_arch) {
    case 'aarch64':
        $download_url = "https://github.com/SagerNet/sing-box/releases/download/$latest_version/sing-box-$base_version-linux-arm64.tar.gz";
        break;
    case 'x86_64':
        $download_url = "https://github.com/SagerNet/sing-box/releases/download/$latest_version/sing-box-$base_version-linux-amd64.tar.gz";
        break;
    default:
        die("No download link found for architecture: $current_arch");
}

if (isset($_GET['check_version'])) {
    if (trim($current_version) === trim($latest_version)) {
        echo "当前版本已是最新: v$current_version";
    } else {
        echo "最新版本: $latest_version";
    }
    exit; 
}

if (trim($current_version) === trim($latest_version)) {
    die("Current version is already the latest.");
}

$curl_command = "curl -sL " . escapeshellarg($download_url) . " -o " . escapeshellarg($temp_file);
exec($curl_command, $output, $return_var);

if ($return_var !== 0 || !file_exists($temp_file)) {
    logMessage("Download failed using curl, trying wget...");
    $wget_command = "wget -q --show-progress --no-check-certificate " . escapeshellarg($download_url) . " -O " . escapeshellarg($temp_file);
    exec($wget_command, $output, $return_var);

    if ($return_var !== 0 || !file_exists($temp_file)) {
        logMessage("Download failed using wget.");
        die("Download failed!");
    }
}

if (!is_dir($temp_dir)) {
    mkdir($temp_dir, 0755, true);
}

exec("tar -xzf '$temp_file' -C '$temp_dir'", $output, $return_var);
if ($return_var !== 0) {
    logMessage("Extraction failed.");
    die("Extraction failed!");
}

$extracted_file = glob("$temp_dir/sing-box-*/*sing-box")[0] ?? '';
if ($extracted_file && file_exists($extracted_file)) {
    exec("cp -f '$extracted_file' '$install_path'");
    exec("chmod 0755 '$install_path'");
    writeVersionToFile($latest_version); 
    logMessage("Update completed! Current version: $latest_version");
    echo "更新完成! 当前版本: $latest_version";
} else {
    logMessage("Extracted file 'sing-box' does not exist.");
    die("Extracted file 'sing-box' does not exist.");
}

unlink($temp_file);
exec("rm -r '$temp_dir'");
?>