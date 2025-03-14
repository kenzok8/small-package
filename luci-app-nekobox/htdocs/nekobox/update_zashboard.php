<?php

ini_set('memory_limit', '128M');

function getUiVersion() {
    $versionFile = '/etc/neko/ui/zashboard/version.txt';
    return file_exists($versionFile) ? trim(file_get_contents($versionFile)) : "Version file not found";
}

function writeVersionToFile($version) {
    file_put_contents('/etc/neko/ui/zashboard/version.txt', $version);
}

$repo_owner = "Zephyruso";
$repo_name = "zashboard";
$api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest";

$response = shell_exec("curl -s -H 'User-Agent: PHP' --connect-timeout 10 " . escapeshellarg($api_url));

if ($response === false || empty($response)) {
    die("GitHub API request failed");
}

$data = json_decode($response, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    die("Failed to parse GitHub API response");
}

$latest_version = $data['tag_name'] ?? '';
$install_path = '/etc/neko/ui/zashboard';
$temp_file = '/tmp/dist.zip';

$dist_url = $data['assets'][0]['browser_download_url'] ?? ''; 
$fonts_url = $data['assets'][1]['browser_download_url'] ?? ''; 

if (empty($dist_url) || empty($fonts_url)) {
    die("Download link not found");
}

if (!is_dir($install_path)) {
    mkdir($install_path, 0755, true);
}

$current_version = getUiVersion();

if (isset($_GET['check_version'])) {
    echo "Latest version: $latest_version";
    exit;
}

$update_type = $_GET['update_type'] ?? 'dist';

$download_url = ($update_type === 'fonts') ? $fonts_url : $dist_url;

exec("wget -O '$temp_file' '$download_url'", $output, $return_var);
if ($return_var !== 0) {
    die("Download failed");
}

if (!file_exists($temp_file)) {
    die("Downloaded file not found");
}

exec("rm -rf /tmp/dist_extract", $output, $return_var);
if ($return_var !== 0) {
    die("Failed to clean temporary extraction directory");
}

exec("unzip -o '$temp_file' -d '/tmp/dist_extract'", $output, $return_var);
if ($return_var !== 0) {
    die("Extraction failed");
}

$extracted_dist_dir = "/tmp/dist_extract/dist";
if (is_dir($extracted_dist_dir)) {
    exec("rm -rf $install_path/*", $output, $return_var);
    if ($return_var !== 0) {
        die("Failed to delete old files");
    }

    exec("mv $extracted_dist_dir/* $install_path/", $output, $return_var);
    if ($return_var !== 0) {
        die("Failed to move extracted files");
    }

    exec("rm -rf /tmp/dist_extract", $output, $return_var);
    if ($return_var !== 0) {
        die("Failed to remove temporary extraction directory");
    }
} else {
    die("'dist' directory not found, extraction failed");
}

exec("chown -R root:root '$install_path' 2>&1", $output, $return_var);
if ($return_var !== 0) {
    die("Failed to change file ownership");
}

writeVersionToFile($latest_version);
echo "Update complete! Current version: $latest_version";

unlink($temp_file);
?>
