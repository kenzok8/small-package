<?php
$repo_owner = "Thaolga";
$repo_name = "openwrt-nekobox";
$package_name = "luci-app-nekobox";

$api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest";
$local_api_response = "/tmp/api_response.json";

$curl_command = "curl -H 'User-Agent: PHP' -s " . escapeshellarg($api_url) . " -o " . escapeshellarg($local_api_response);
exec($curl_command . " 2>&1", $output, $return_var);

if ($return_var !== 0 || !file_exists($local_api_response)) {
    echo "<script>appendLog('curl failed to fetch version information, attempting to use wget...');</script>";
    $wget_command = "wget -q --no-check-certificate " . escapeshellarg($api_url) . " -O " . escapeshellarg($local_api_response);
    exec($wget_command . " 2>&1", $output, $return_var);

    if ($return_var !== 0 || !file_exists($local_api_response)) {
        die("Unable to access GitHub API. Please check the URL or network connection. Output: " . implode("\n", $output));
    }

    echo "<script>appendLog('wget has completed fetching version information');</script>";
}

$response = file_get_contents($local_api_response);
$data = json_decode($response, true);
unlink($local_api_response);

$tag_name = $data['tag_name'] ?? '';

$new_version = '';
$asset_file_name = '';

if (isset($data['assets']) && is_array($data['assets'])) {
    foreach ($data['assets'] as $asset) {
        if (strpos($asset['name'], $package_name) !== false) {
            preg_match('/' . preg_quote($package_name, '/') . '_(v?\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?)_all\.ipk$/', $asset['name'], $matches);
            if (!empty($matches[1])) {
                $new_version = $matches[1];
                $asset_file_name = $asset['name'];
                break;
            }
        }
    }
}

if (empty($new_version)) {
    die("No latest version found or version information is empty");
}

if (isset($_GET['check_version'])) {
    echo "Latest version: v" . $new_version;
    exit;
}

$download_url = "https://github.com/$repo_owner/$repo_name/releases/download/{$tag_name}/{$asset_file_name}";

echo "<pre>Latest version: $new_version</pre>";
echo "<pre>Tag name: $tag_name</pre>";
echo "<pre>Asset file: $asset_file_name</pre>";
echo "<pre>Download URL: $download_url</pre>";
echo "<pre id='logOutput'></pre>";

echo "<script>
        function appendLog(message) {
            document.getElementById('logOutput').innerHTML += message + '\\n';
        }
      </script>";

echo "<script>appendLog('Start downloading updates...');</script>";

$local_file = "/tmp/{$asset_file_name}";

$curl_command = "curl -sL " . escapeshellarg($download_url) . " -o " . escapeshellarg($local_file);
exec($curl_command . " 2>&1", $output, $return_var);

if ($return_var !== 0 || !file_exists($local_file)) {
    echo "<script>appendLog('curl download failed, trying to use wget...');</script>";
    $wget_command = "wget -q --show-progress --no-check-certificate " . escapeshellarg($download_url) . " -O " . escapeshellarg($local_file);
    exec($wget_command . " 2>&1", $output, $return_var);

    if ($return_var !== 0 || !file_exists($local_file)) {
        echo "<pre>Download failed. Command output: " . implode("\n", $output) . "</pre>";
        die("Download failed. The downloaded file was not found");
    }

    echo "<script>appendLog('wget download complete');</script>";
} else {
    echo "<script>appendLog('curl download complete');</script>";
}

echo "<script>appendLog('Update the list of software packages...');</script>";
$output = shell_exec("opkg update");
echo "<pre>$output</pre>";

echo "<script>appendLog('Start installation...');</script>";

$output = shell_exec("opkg install --force-reinstall " . escapeshellarg($local_file));
echo "<pre>$output</pre>";
echo "<script>appendLog('Installation complete。');</script>";

unlink($local_file);
?>