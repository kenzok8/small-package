<?php
function getCurrentVersion() {
    $packageName = 'luci-app-nekobox';
    $command = "opkg list-installed | grep $packageName";
    $output = shell_exec($command . ' 2>&1');

    if ($output === null || empty($output)) {
        error_log("Error executing opkg command or package not found");
        return "Error";
    }

    $parts = explode(' - ', $output);
    if (count($parts) < 2) {
        error_log("Unexpected opkg output format: " . $output);
        return "Error";
    }

    return preg_replace('/(-cn|-en)$/', '', trim($parts[1]));
}

function getLatestVersion() {
    $url = "https://raw.githubusercontent.com/Thaolga/openwrt-nekobox/main/nekobox_version";
    $newVersion = shell_exec("curl -m 5 -f -s $url");

    if ($newVersion === null || empty(trim($newVersion))) {
        error_log("Error fetching the latest version from $url");
        return "Error";
    }

    return trim($newVersion);
}

$currentVersion = getCurrentVersion();
$latestVersion = getLatestVersion();

$hasUpdate = (version_compare($currentVersion, $latestVersion, '<')) ? true : false;

$response = [
    'currentVersion' => "V." . $currentVersion,
    'latestVersion' => "V." . $latestVersion,
    'hasUpdate' => $hasUpdate
];

error_log("Current Version: V." . $currentVersion);
error_log("Latest Version: V." . $latestVersion);
error_log("Has Update: " . ($hasUpdate ? "Yes" : "No"));

header('Content-Type: application/json');
echo json_encode($response);
?>
