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
        return cleanCurrentVersion($parts[1]);
    }

    return "Error";
}

function cleanCurrentVersion($version) {
    $version = explode('-', $version);
    
    if (count($version) >= 2) {
        $cleanVersion = $version[0] . '-' . $version[1];
    } else {
        $cleanVersion = $version[0];
    }
    
    return preg_replace('/[^0-9\.rRcC\-]/', '', $cleanVersion);
}

function getLatestVersionWithFallback() {
    $version = getFastestVersion();
    if ($version !== "Error") {
        return $version;
    }
    
    return "Error";
}

function getFastestVersion() {
    $sources = [
        [
            'type' => 'api',
            'url' => 'https://api.github.com/repos/Thaolga/openwrt-nekobox/releases/latest',
            'name' => 'GitHub API'
        ],
        [
            'type' => 'api',
            'url' => 'https://ghproxy.com/https://api.github.com/repos/Thaolga/openwrt-nekobox/releases/latest',
            'name' => 'ghproxy API'
        ],
        [
            'type' => 'html',
            'url' => 'https://ghproxy.com/https://github.com/Thaolga/openwrt-nekobox/releases',
            'name' => 'ghproxy HTML'
        ],
        [
            'type' => 'api',
            'url' => 'https://mirror.ghproxy.com/https://api.github.com/repos/Thaolga/openwrt-nekobox/releases/latest',
            'name' => 'mirror.ghproxy API'
        ],
        [
            'type' => 'html',
            'url' => 'https://mirror.ghproxy.com/https://github.com/Thaolga/openwrt-nekobox/releases',
            'name' => 'mirror.ghproxy HTML'
        ],
        [
            'type' => 'api',
            'url' => 'https://github.moeyy.xyz/https://api.github.com/repos/Thaolga/openwrt-nekobox/releases/latest',
            'name' => 'moeyy API'
        ],
        [
            'type' => 'html',
            'url' => 'https://github.moeyy.xyz/https://github.com/Thaolga/openwrt-nekobox/releases',
            'name' => 'moeyy HTML'
        ]
    ];

    foreach ($sources as $source) {
        $version = fetchVersionFromSource($source);
        if ($version !== "Error") {
            return $version;
        }
    }
    
    return "Error";
}

function fetchVersionFromSource($source) {
    $timeout = 5;
    
    if ($source['type'] === 'api') {
        $command = "curl -m {$timeout} -s -H 'Accept: application/vnd.github.v3+json' " . escapeshellarg($source['url']);
    } else {
        $command = "curl -m {$timeout} -s -L " . escapeshellarg($source['url']);
    }
    
    $response = shell_exec($command);
    
    if (!$response || empty($response)) {
        return "Error";
    }
    
    if ($source['type'] === 'api') {
        $data = json_decode($response, true);
        if (isset($data['tag_name'])) {
            return cleanLatestVersion($data['tag_name']);
        }
    } else {
        if (preg_match('/luci-app-nekobox_([\d\.]+-(?:r|rc)[\d]+)/i', $response, $matches)) {
            return cleanLatestVersion($matches[1]);
        }
        
        if (preg_match('/\/releases\/tag\/([\d\.]+(?:-(?:r|rc)[\d]+)?)/i', $response, $matches)) {
            return cleanLatestVersion($matches[1]);
        }
    }
    
    return "Error";
}

function cleanLatestVersion($version) {
    return preg_replace('/[^0-9\.rRcC\-]/', '', $version);
}

function compareVersions($ver1, $ver2) {
    if ($ver1 === $ver2) {
        return 0;
    }
    
    $parts1 = explode('-', $ver1, 2);
    $parts2 = explode('-', $ver2, 2);
    
    $mainVer1 = $parts1[0];
    $mainVer2 = $parts2[0];
    
    $release1 = count($parts1) > 1 ? $parts1[1] : '';
    $release2 = count($parts2) > 1 ? $parts2[1] : '';
    
    $mainCompare = version_compare($mainVer1, $mainVer2);
    if ($mainCompare !== 0) {
        return $mainCompare;
    }
    
    return compareReleaseIdentifiers($release1, $release2);
}

function compareReleaseIdentifiers($rel1, $rel2) {
    if (empty($rel1) && empty($rel2)) {
        return 0;
    }
    
    if (empty($rel1) && !empty($rel2)) {
        return 1;
    }
    if (!empty($rel1) && empty($rel2)) {
        return -1;
    }
    
    preg_match('/^(r|rc)(\d+)$/i', $rel1, $matches1);
    preg_match('/^(r|rc)(\d+)$/i', $rel2, $matches2);
    
    $type1 = isset($matches1[1]) ? strtolower($matches1[1]) : '';
    $type2 = isset($matches2[1]) ? strtolower($matches2[1]) : '';
    
    $num1 = isset($matches1[2]) ? intval($matches1[2]) : 0;
    $num2 = isset($matches2[2]) ? intval($matches2[2]) : 0;
    
    $typePriority = ['r' => 1, 'rc' => 2];
    $priority1 = isset($typePriority[$type1]) ? $typePriority[$type1] : 0;
    $priority2 = isset($typePriority[$type2]) ? $typePriority[$type2] : 0;
    
    if ($priority1 !== $priority2) {
        return $priority1 - $priority2;
    }
    
    if ($num1 !== $num2) {
        return $num1 - $num2;
    }
    
    return 0;
}

$currentVersion = getCurrentVersion();
$latestVersion = getLatestVersionWithFallback();

if ($currentVersion === "Error" || $latestVersion === "Error") {
    $response = [
        'currentVersion' => $currentVersion,
        'latestVersion' => $latestVersion,
        'hasUpdate' => false,
        'error' => 'Failed to fetch version information'
    ];
} else {
    $versionCompare = compareVersions($currentVersion, $latestVersion);
    $hasUpdate = ($versionCompare < 0);

    $response = [
        'currentVersion' => $currentVersion,
        'latestVersion' => $latestVersion,
        'hasUpdate' => $hasUpdate,
        'compareResult' => $versionCompare
    ];
}

header('Content-Type: application/json');
echo json_encode($response);
?>