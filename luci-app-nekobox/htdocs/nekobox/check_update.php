<?php
$repo_owner = "Thaolga";
$repo_name = "openwrt-nekobox";
$package_name = "luci-app-nekobox";
$json_file = __DIR__ . "/version_debug.json";

function getCurrentVersion($package_name) {
    $output = shell_exec("opkg list-installed | grep " . escapeshellarg($package_name) . " 2>&1");
    if (!$output) return "Error";
    foreach (explode("\n", $output) as $line) {
        if (preg_match('/' . preg_quote($package_name, '/') . '\s*-\s*([^\s]+)/', $line, $m)) {
            return $m[1];
        }
    }
    return "Error";
}

function getLatestVersionFromAssets($repo_owner, $repo_name, $package_name) {
    $api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest";
    $json = shell_exec("curl -H 'User-Agent: PHP' -s " . escapeshellarg($api_url) . " 2>/dev/null");
    if (!$json) return "Error";
    $data = json_decode($json, true);
    if (!isset($data['assets'])) return "Error";
    foreach ($data['assets'] as $asset) {
        $name = $asset['name'] ?? '';
        if (strpos($name, $package_name) !== false) {
            if (preg_match('/' . preg_quote($package_name, '/') . '[_-]v?(\d+\.\d+\.\d+(?:-(?:r|rc)\d+)?)/i', $name, $m)) {
                return $m[1];
            }
        }
    }
    return "Error";
}

$current = getCurrentVersion($package_name);
$latest  = getLatestVersionFromAssets($repo_owner, $repo_name, $package_name);

$result = [
    'currentVersion' => $current,
    'latestVersion'  => $latest,
    'timestamp'      => time()
];

file_put_contents($json_file, json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

header("Content-Type: application/json");
echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
?>