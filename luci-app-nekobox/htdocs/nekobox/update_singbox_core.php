<?php

$repo_owner = "Thaolga";
$repo_name = "luci-app-nekoclash";
$package_name = "sing-box";

$new_version = isset($_GET['version']) ? $_GET['version'] : "v1.11.0-alpha.10";  
$new_version_cleaned = str_replace('v', '', $new_version);

if (isset($_GET['check_version'])) {
    $api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest";
    $curl_command = "curl -s -H 'User-Agent: PHP' --connect-timeout 10 " . escapeshellarg($api_url);
    $latest_version_data = shell_exec($curl_command);
    $latest_version_info = json_decode($latest_version_data, true);

    if (isset($latest_version_info['tag_name'])) {
        $latest_version = $latest_version_info['tag_name'];
        echo "Latest version: v$latest_version";
    } else {
        echo "Unable to retrieve the latest version information";
    }
    exit;
}

$arch = shell_exec("opkg info " . escapeshellarg($package_name) . " | grep 'Architecture'");

if (strpos($arch, 'aarch64') !== false || strpos($arch, 'arm') !== false) {
    $arch = "aarch64_generic";
    $download_url = "https://github.com/$repo_owner/$repo_name/releases/download/$new_version_cleaned/{$package_name}_{$new_version_cleaned}-1_aarch64_generic.ipk";
} elseif (strpos($arch, 'x86_64') !== false) {
    $arch = "x86_64";
    $download_url = "https://github.com/$repo_owner/$repo_name/releases/download/$new_version_cleaned/{$package_name}_{$new_version_cleaned}-1_x86_64.ipk";
} elseif (strpos($arch, 'mips') !== false) {
    $arch = "mips";
    $download_url = "https://github.com/$repo_owner/$repo_name/releases/download/$new_version_cleaned/{$package_name}_{$new_version_cleaned}-1_mips.ipk";
} else {
    die("The current device architecture is not supported");
}

$local_file = "/tmp/{$package_name}_{$new_version_cleaned}_{$arch}.ipk";

echo "<pre>Latest version: $new_version_cleaned</pre>";
echo "<pre>Download URL: $download_url</pre>";
echo "<pre id='logOutput'></pre>";

echo "<script>
        function appendLog(message) {
            document.getElementById('logOutput').innerHTML += message + '\\n';
        }
      </script>";
echo "<script>appendLog('Start downloading...');</script>";

$curl_command = "curl -sL " . escapeshellarg($download_url) . " -o " . escapeshellarg($local_file);
exec($curl_command . " 2>&1", $output, $return_var);

if ($return_var !== 0 || !file_exists($local_file)) {
    echo "<pre>Download failed. Output: " . implode("\n", $output) . "</pre>";
    die("Download failed. File not found");
}
echo "<script>appendLog('Download completed。');</script>";

echo "<script>appendLog('Updating package list...');</script>";
$output = shell_exec("opkg update");
echo "<pre>$output</pre>";

echo "<script>appendLog('Starting installation...');</script>";
$output = shell_exec("opkg install --force-reinstall " . escapeshellarg($local_file));
echo "<pre>$output</pre>";
echo "<script>appendLog('Installation completed。');</script>";

unlink($local_file);

?>
