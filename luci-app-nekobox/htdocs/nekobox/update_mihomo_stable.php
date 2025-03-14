<?php
function logMessage($message) {
    $logFile = '/var/log/mihomo_update.log'; 
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($logFile, "[$timestamp] $message\n", FILE_APPEND);
}

function writeVersionToFile($version) {
    $versionFile = '/etc/neko/core/mihomo_version.txt';
    $result = file_put_contents($versionFile, $version);
    if ($result === false) {
       logMessage("Unable to write version file: $versionFile");
    }
}

$repo_owner = "MetaCubeX";
$repo_name = "mihomo";
$api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest";

if (isset($_GET['check_version'])) {
    $curl_command = "curl -s -H 'User-Agent: PHP' " . escapeshellarg($api_url);
    $response = shell_exec($curl_command);

    if ($response === false || empty($response)) {
        echo "GitHub API request failed.";
        exit;
    }

    $data = json_decode($response, true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        echo "Error parsing GitHub API response: " . json_last_error_msg();
        exit;
    }

    $latest_version = $data['tag_name'] ?? '';

    if (empty($latest_version)) {
        echo "Latest version information not found.";
        exit;
    }

    echo "Latest version: " . htmlspecialchars($latest_version);
    exit;
}

$curl_command = "curl -s -H 'User-Agent: PHP' " . escapeshellarg($api_url);
$response = shell_exec($curl_command);

if ($response === false || empty($response)) {
    die("GitHub API request failed. Please check your network connection or try again later.");
}

$data = json_decode($response, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    die("Error parsing GitHub API response: " . json_last_error_msg());
}

$latest_version = $data['tag_name'] ?? '';

$current_version = ''; 
$install_path = '/usr/bin/mihomo'; 
$temp_file = '/tmp/mihomo.gz'; 

if (file_exists($install_path)) {
    $current_version = trim(shell_exec("{$install_path} --version"));
} 

$current_arch = trim(shell_exec("uname -m"));

$download_url = '';
$base_version = ltrim($latest_version, 'v'); 
switch ($current_arch) {
    case 'aarch64':
        $download_url = "https://github.com/MetaCubeX/mihomo/releases/download/$latest_version/mihomo-linux-arm64-v$base_version.gz";
        break;
    case 'armv7l':
        $download_url = "https://github.com/MetaCubeX/mihomo/releases/download/$latest_version/mihomo-linux-armv7l-v$base_version.gz";
        break;
    case 'x86_64':
        $download_url = "https://github.com/MetaCubeX/mihomo/releases/download/$latest_version/mihomo-linux-amd64-v$base_version.gz";
        break;
    default:
        echo "Download link for architecture not found: $current_arch";
        exit;
}

if (trim($current_version) === trim($latest_version)) {
    echo "Current version is up to date. No update needed.";
    exit;
}

exec("wget -O '$temp_file' '$download_url'", $output, $return_var);

if ($return_var === 0) {
    exec("gzip -d -c '$temp_file' > '/tmp/mihomo-linux-arm64'", $output, $return_var);

    if ($return_var === 0) {
        exec("mv '/tmp/mihomo-linux-arm64' '$install_path'", $output, $return_var);

        if ($return_var === 0) {
            exec("chmod 0755 '$install_path'", $output, $return_var);

            if ($return_var === 0) {
                writeVersionToFile($latest_version); 
                echo "Update completed! Current version: $latest_version";
            } else {
                echo "Failed to set permissions!";
            }
        } else {
            echo "Failed to move file!";
        }
    } else {
        echo "Extraction failed!";
    }
} else {
    echo "Download failed!";
}

if (file_exists($temp_file)) {
    unlink($temp_file);
}
?>
