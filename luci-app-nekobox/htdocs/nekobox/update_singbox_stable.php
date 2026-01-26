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

logMessage("Latest stable version found: $latest_version");

exec("opkg list-installed | grep -q '^sing-box'", $output, $opkg_check_return);

$current_version = ''; 
$install_path = '/usr/bin/sing-box'; 

if (file_exists($install_path)) {
    $current_version = trim(shell_exec("{$install_path} --version"));
    logMessage("Current version: $current_version");
}

$current_arch = trim(shell_exec("uname -m"));
logMessage("Architecture: $current_arch");

$base_version = ltrim($latest_version, 'v');
$download_url = '';
$ipk_filename = '';

switch ($current_arch) {
    case 'aarch64':
    case 'arm64':
        $ipk_filename = "sing-box_{$base_version}_openwrt_aarch64_generic.ipk";
        $download_url = "https://github.com/SagerNet/sing-box/releases/download/{$latest_version}/{$ipk_filename}";
        break;
    case 'x86_64':
        $ipk_filename = "sing-box_{$base_version}_openwrt_x86_64.ipk";
        $download_url = "https://github.com/SagerNet/sing-box/releases/download/{$latest_version}/{$ipk_filename}";
        break;
    default:
        logMessage("Unsupported architecture: $current_arch");
        die("No download link found for architecture: $current_arch");
}

logMessage("IPK filename: $ipk_filename");
logMessage("Download URL: $download_url");

if (isset($_GET['check_version'])) {
    if (trim($current_version) === trim($latest_version)) {
        echo "Current version is already the latest: v$current_version";
    } else {
        echo "Latest version: $latest_version";
    }
    exit; 
}

if (trim($current_version) === trim($latest_version)) {
    logMessage("Current version is already the latest. Skipping update.");
    die("Current version is already the latest.");
}

if ($opkg_check_return !== 0) {
    logMessage("Sing-box is not installed via opkg. Running opkg update...");
    exec("opkg update 2>&1", $update_output, $update_return);
    if ($update_return !== 0) {
        logMessage("opkg update failed: " . implode("\n", $update_output));
    } else {
        logMessage("opkg update completed");
    }
} else {
    logMessage("Sing-box is already installed via opkg. Skipping opkg update.");
}

$temp_file = "/tmp/{$ipk_filename}";
logMessage("Downloading IPK file to: $temp_file");

exec("wget -O '$temp_file' '$download_url' 2>&1", $output, $return_var);
if ($return_var !== 0) {
    logMessage("Download failed! Return code: $return_var, Output: " . implode("\n", $output));
    die("Download failed!");
}
logMessage("Download completed. File size: " . filesize($temp_file) . " bytes");

logMessage("Installing IPK package...");
exec("opkg install --force-depends --force-reinstall --force-overwrite '$temp_file' 2>&1", $install_output, $install_return);

if ($install_return !== 0) {
    logMessage("Installation failed! Return code: $install_return, Output: " . implode("\n", $install_output));
    die("Installation failed!");
}

logMessage("Installation completed successfully");
writeVersionToFile($latest_version); 
logMessage("Version written to file: $latest_version");

echo "Update completed! Current version: $latest_version";

if (file_exists($temp_file)) {
    unlink($temp_file);
    logMessage("Temporary file cleaned: $temp_file");
}

logMessage("Update process completed");
?>
