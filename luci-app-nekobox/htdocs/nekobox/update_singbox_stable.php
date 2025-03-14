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
    logMessage("GitHub API request failed, possibly due to network issues or GitHub API restrictions.");
    die("GitHub API request failed. Please check your network connection or try again later.");
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
        if (isset($release['tag_name']) && isset($release['prerelease']) && !$release['prerelease']) {
            $latest_version = $release['tag_name'];  
            break;
        }
    }
}

if (empty($latest_version)) {
    logMessage("No stable version found.");
    die("No stable version found.");
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
        echo "Current version is already the latest: v$current_version";
    } else {
        echo "Latest version: $latest_version";
    }
    exit; 
}

if (trim($current_version) === trim($latest_version)) {
    die("Current version is already the latest.");
}

exec("wget -O '$temp_file' '$download_url'", $output, $return_var);
if ($return_var !== 0) {
    die("Download failed!");
}

if (!is_dir($temp_dir)) {
    mkdir($temp_dir, 0755, true);
}

exec("tar -xzf '$temp_file' -C '$temp_dir'", $output, $return_var);
if ($return_var !== 0) {
    die("Extraction failed!");
}

$extracted_file = glob("$temp_dir/sing-box-*/*sing-box")[0] ?? '';
if ($extracted_file && file_exists($extracted_file)) {
    exec("cp -f '$extracted_file' '$install_path'");
    exec("chmod 0755 '$install_path'");
    writeVersionToFile($latest_version); 
    echo "Update completed! Current version: $latest_version";
} else {
    die("Extracted file 'sing-box' does not exist.");
}

unlink($temp_file);
exec("rm -r '$temp_dir'");
?>
