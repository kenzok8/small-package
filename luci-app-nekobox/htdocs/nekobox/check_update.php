<?php
function getCurrentVersion() {
    $packageName = 'luci-app-nekobox';
    $command = "opkg list-installed | grep $packageName";
    $output = shell_exec($command . ' 2>&1');

    if ($output === null || empty($output)) {
        return "Error";
    }

    $parts = explode(' - ', $output);
    if (count($parts) >= 2) {
        return cleanVersion($parts[1]);
    }

    return "Error";
}

function getLatestVersion() {
    $url = "https://github.com/Thaolga/openwrt-nekobox/releases";
    $html = shell_exec("curl -m 10 -s $url");

    if ($html === null || empty($html)) {
        return "Error";
    }

    preg_match('/\/releases\/tag\/([\d\.]+)/', $html, $matches);
    if (isset($matches[1])) {
        return cleanVersion($matches[1]);
    }

    return "Error";
}

function cleanVersion($version) {
    $version = explode('-', $version)[0];
    return preg_replace('/[^0-9\.]/', '', $version);
}

$currentVersion = getCurrentVersion();
$latestVersion = getLatestVersion();

if ($currentVersion === "Error" || $latestVersion === "Error") {
    $response = [
        'currentVersion' => $currentVersion,
        'latestVersion' => $latestVersion,
        'hasUpdate' => false,
        'error' => 'Failed to fetch version information'
    ];
} else {
    $hasUpdate = (version_compare($currentVersion, $latestVersion, '<')) ? true : false;

    $response = [
        'currentVersion' => $currentVersion,
        'latestVersion' => $latestVersion,
        'hasUpdate' => $hasUpdate
    ];
}

header('Content-Type: application/json');
echo json_encode($response);
?>
