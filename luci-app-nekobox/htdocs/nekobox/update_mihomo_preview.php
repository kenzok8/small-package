<?php

ini_set('memory_limit', '256M');

function logMessage($message) {
    $logFile = '/tmp/mihomo_prerelease_update.log';  
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($logFile, "[$timestamp] $message\n", FILE_APPEND);
}

function writeVersionToFile($version) {
    $versionFile = '/etc/neko/core/mihomo_version.txt';
    $result = file_put_contents($versionFile, $version);
    if ($result === false) {
        logMessage("Unable to write to version file: $versionFile");
    }
}

$repo_owner = "MetaCubeX";
$repo_name = "mihomo";
$api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases";

$curl_command = "curl -s -H 'User-Agent: PHP' " . escapeshellarg($api_url);
$response = shell_exec($curl_command);

if ($response === false || empty($response)) {
    logMessage("curl request failed, try using wget...");
    $wget_command = "wget -q --no-check-certificate --timeout=10 " . escapeshellarg($api_url) . " -O /tmp/api_response.json";
    exec($wget_command, $output, $return_var);

    if ($return_var !== 0 || !file_exists('/tmp/api_response.json')) {
        logMessage("GitHub API request failed, both curl and wget failed");
        die("GitHub API request failed. Please check your network connection or try again later");
    }

    $response = file_get_contents('/tmp/api_response.json');
    unlink('/tmp/api_response.json');
}

$data = json_decode($response, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    die("Error occurred while parsing GitHub API response: " . json_last_error_msg());
}

$latest_prerelease = null;
foreach ($data as $release) {
    if (isset($release['prerelease']) && $release['prerelease'] == true) {
        $latest_prerelease = $release;
        break;
    }
}

if ($latest_prerelease === null) {
    die("No latest preview version found");
}

$latest_version = $latest_prerelease['tag_name'] ?? ''; 

$assets = $latest_prerelease['assets'] ?? [];

if (empty($latest_version)) {
    die("No latest version information found");
}

$download_url = '';
$asset_found = false;
$current_arch = trim(shell_exec("uname -m"));

foreach ($assets as $asset) {
    if ($current_arch === 'x86_64' && strpos($asset['name'], 'linux-amd64-alpha') !== false && strpos($asset['name'], '.gz') !== false) {
        $download_url = $asset['browser_download_url'];
        $asset_found = true;
        break;
    }
    if ($current_arch === 'aarch64' && strpos($asset['name'], 'linux-arm64-alpha') !== false && strpos($asset['name'], '.gz') !== false) {
        $download_url = $asset['browser_download_url'];
        $asset_found = true;
        break;
    }
    if ($current_arch === 'armv7l' && strpos($asset['name'], 'linux-armv7l-alpha') !== false && strpos($asset['name'], '.gz') !== false) {
        $download_url = $asset['browser_download_url'];
        $asset_found = true;
        break;
    }
}

if (!$asset_found) {
    die("No suitable architecture preview download link found");
}

$filename = basename($download_url); 
preg_match('/alpha-[\w-]+/', $filename, $matches); 
$version_from_filename = $matches[0] ?? 'Unknown version'; 

$latest_version = $version_from_filename; 

echo "Latest version: " . htmlspecialchars($latest_version) . "\n";

$temp_file = '/tmp/mihomo_prerelease.gz';
$curl_command = "curl -sL " . escapeshellarg($download_url) . " -o " . escapeshellarg($temp_file);
exec($curl_command, $output, $return_var);

if ($return_var !== 0 || !file_exists($temp_file)) {
    logMessage("Download failed, try using wget...");
    $wget_command = "wget -q --show-progress --no-check-certificate " . escapeshellarg($download_url) . " -O " . escapeshellarg($temp_file);
    exec($wget_command, $output, $return_var);

    if ($return_var !== 0 || !file_exists($temp_file)) {
        logMessage("Download failed, both curl and wget have failed");
        die("Download failed");
    }
}

exec("gzip -d -c '$temp_file' > '/tmp/mihomo-linux-$current_arch'", $output, $return_var);

if ($return_var === 0) {
    $install_path = '/usr/bin/mihomo';
    exec("mv '/tmp/mihomo-linux-$current_arch' '$install_path'", $output, $return_var);

    if ($return_var === 0) {
        exec("chmod 0755 '$install_path'", $output, $return_var);

        if ($return_var === 0) {
            logMessage("Update complete! Current version: $latest_version");
            echo "Update complete! Current version: $latest_version";
            writeVersionToFile($latest_version);
        } else {
            logMessage("Failed to set permissions");
            echo "Failed to set permissions";
        }
    } else {
        logMessage("Failed to move the file");
        echo "Failed to move the file";
    }
} else {
    logMessage("Failed to unzip");
    echo "Failed to unzip";
}

if (file_exists($temp_file)) {
    unlink($temp_file);
}

?>
