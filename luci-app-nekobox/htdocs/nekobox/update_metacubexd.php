<?php

ini_set('memory_limit', '128M'); 

function getUiVersion() {
    $versionFile = '/etc/neko/ui/metacubexd/version.txt';
    
    if (file_exists($versionFile)) {
        return trim(file_get_contents($versionFile));
    } else {
        return "Version file does not exist";
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
    die("GitHub API request failed. Please check your network connection or try again later.");
}

$data = json_decode($response, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    die("Error parsing GitHub API response: " . json_last_error_msg());
}

$latest_version = $data['tag_name'] ?? '';
$install_path = '/etc/neko/ui/metacubexd';
$temp_file = '/tmp/compressed-dist.tgz';

if (!is_dir($install_path)) {
    mkdir($install_path, 0755, true);
}

$current_version = getUiVersion();

if (isset($_GET['check_version'])) {
        echo "Latest version: $latest_version";
    exit;
}

$download_url = $data['assets'][0]['browser_download_url'] ?? '';

if (empty($download_url)) {
    die("Download link not found. Please check the resources for the release version.");
}

exec("wget -O '$temp_file' '$download_url'", $output, $return_var);
if ($return_var !== 0) {
    die("Download failed!");
}

exec("tar -xzf '$temp_file' -C '$install_path'", $output, $return_var);
if ($return_var !== 0) {
    die("Extraction failed!");
}

writeVersionToFile($latest_version); 
echo "Update complete! Current version: $latest_version";

unlink($temp_file);
?>
