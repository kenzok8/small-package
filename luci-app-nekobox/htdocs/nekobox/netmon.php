<?php
if (!function_exists('formatBytes')) {
    function formatBytes($bytes, $precision = 2) {
        if ($bytes <= 0) return "0 B";
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $pow = floor(log($bytes, 1024));
        $pow = min($pow, count($units) - 1);
        $bytes /= pow(1024, $pow);
        return round($bytes, $precision) . ' ' . $units[$pow];
    }
}

function getOpenWrtTraffic() {
    $result = [
        'upload_speed' => '0 B/S',
        'download_speed' => '0 B/S',
        'upload_total' => '0 B',
        'download_total' => '0 B',
        'status' => 'success',
        'method' => 'unknown',
        'debug' => [],
        'interfaces' => []
    ];

    if (file_exists('/proc/net/dev')) {
        $result['debug'][] = 'Found /proc/net/dev';
        try {
            $traffic = parseNetDev();
            if ($traffic['rx'] > 0 || $traffic['tx'] > 0) {
                $result['method'] = 'proc_net_dev';
                $result['selected_interface'] = $traffic['selected_interface'] ?? 'unknown';
                return calculateTrafficSpeed($result, $traffic['rx'], $traffic['tx']);
            }
        } catch (Exception $e) {
            $result['debug'][] = '/proc/net/dev error: ' . $e->getMessage();
        }
    }

    if (is_dir('/sys/class/net/')) {
        $result['debug'][] = 'Found /sys/class/net/';
        try {
            $traffic = parseSysClassNet();
            if ($traffic['rx'] > 0 || $traffic['tx'] > 0) {
                $result['method'] = 'sys_class_net';
                return calculateTrafficSpeed($result, $traffic['rx'], $traffic['tx']);
            }
        } catch (Exception $e) {
            $result['debug'][] = '/sys/class/net/ error: ' . $e->getMessage();
        }
    }

    try {
        $traffic = parseWithCat();
        if ($traffic['rx'] > 0 || $traffic['tx'] > 0) {
            $result['method'] = 'cat_command';
            return calculateTrafficSpeed($result, $traffic['rx'], $traffic['tx']);
        }
    } catch (Exception $e) {
        $result['debug'][] = 'cat command error: ' . $e->getMessage();
    }

    try {
        $traffic = parseIpCommand();
        if ($traffic['rx'] > 0 || $traffic['tx'] > 0) {
            $result['method'] = 'ip_command';
            return calculateTrafficSpeed($result, $traffic['rx'], $traffic['tx']);
        }
    } catch (Exception $e) {
        $result['debug'][] = 'ip command error: ' . $e->getMessage();
    }

    $result['status'] = 'error';
    $result['error'] = 'No working method found for traffic monitoring';
    return $result;
}

function parseNetDev() {
    $netDev = '/proc/net/dev';
    $rx = 0;
    $tx = 0;
    $interfaces = [];

    if (!file_exists($netDev) || !is_readable($netDev)) {
        throw new Exception("Cannot read $netDev");
    }

    $content = file_get_contents($netDev);
    if ($content === false) {
        throw new Exception("Failed to read $netDev content");
    }

    $lines = explode("\n", $content);

    $interfacePriority = [
        'eth0'    => 100,
        'wlan0'   => 90,
        'wlan1'   => 89,
        'pppoe'   => 80,
        'br-lan'  => 70,
        'tun0'    => 60,
        'tun1'    => 59,
    ];
    
    $foundInterfaces = [];
    
    foreach ($lines as $line) {
        if (strpos($line, ':') !== false) {
            list($iface, $data) = explode(':', $line, 2);
            $iface = trim($iface);
            
            if (in_array($iface, ['lo', 'sit0', 'ip6tnl0', 'dummy0', 'docker0']) || 
                strpos($iface, 'veth') === 0 || strpos($iface, 'dheth') === 0) {
                continue;
            }
            
            $stats = preg_split('/\s+/', trim($data));
            if (count($stats) >= 9) {
                $iface_rx = intval($stats[0]);
                $iface_tx = intval($stats[8]);
                
                $foundInterfaces[$iface] = [
                    'rx' => $iface_rx, 
                    'tx' => $iface_tx,
                    'priority' => $interfacePriority[$iface] ?? 1
                ];
            }
        }
    }
    
    $hasWanInterface = false;
    $wanInterfaces = ['eth0', 'pppoe-wan', 'wan'];
    
    foreach ($wanInterfaces as $wan) {
        if (isset($foundInterfaces[$wan]) && 
            ($foundInterfaces[$wan]['rx'] > 0 || $foundInterfaces[$wan]['tx'] > 0)) {
            $hasWanInterface = true;
            break;
        }
    }
    
    $selectedInterface = null;
    $hasWanInterface = false;
    $wanInterfaces = ['eth0', 'pppoe-wan', 'wan'];
    
    foreach ($wanInterfaces as $wan) {
        if (isset($foundInterfaces[$wan]) && 
            ($foundInterfaces[$wan]['rx'] > 0 || $foundInterfaces[$wan]['tx'] > 0)) {
            $hasWanInterface = true;
            $selectedInterface = $wan;
            $rx = $foundInterfaces[$wan]['rx'];
            $tx = $foundInterfaces[$wan]['tx'];
            $interfaces[$wan] = $foundInterfaces[$wan];
            break;
        }
    }
    
    if (!$hasWanInterface && !empty($foundInterfaces)) {
        uasort($foundInterfaces, function($a, $b) {
            return $b['priority'] - $a['priority'];
        });
        
        $selectedInterface = key($foundInterfaces);
        $topInterface = reset($foundInterfaces);
        if ($topInterface) {
            $rx = $topInterface['rx'];
            $tx = $topInterface['tx'];
            $interfaces[$selectedInterface] = $topInterface;
        }
    }

    return [
        'rx' => $rx, 
        'tx' => $tx, 
        'interfaces' => $interfaces,
        'selected_interface' => $selectedInterface
    ];
}

function parseSysClassNet() {
    $rx = 0;
    $tx = 0;
    $interfaces = [];
    $netDir = '/sys/class/net/';

    if (!is_dir($netDir)) {
        throw new Exception("$netDir not found");
    }

    $dirs = scandir($netDir);
    foreach ($dirs as $iface) {
        if ($iface === '.' || $iface === '..') continue;
        
        if (in_array($iface, ['lo', 'sit0', 'ip6tnl0'])) continue;
        
        $rxFile = $netDir . $iface . '/statistics/rx_bytes';
        $txFile = $netDir . $iface . '/statistics/tx_bytes';
        
        if (file_exists($rxFile) && file_exists($txFile)) {
            $iface_rx = intval(trim(file_get_contents($rxFile)));
            $iface_tx = intval(trim(file_get_contents($txFile)));
            $rx += $iface_rx;
            $tx += $iface_tx;
            $interfaces[$iface] = ['rx' => $iface_rx, 'tx' => $iface_tx];
        }
    }

    return ['rx' => $rx, 'tx' => $tx, 'interfaces' => $interfaces];
}

function parseWithCat() {
    $rx = 0;
    $tx = 0;
    
    $output = shell_exec('cat /proc/net/dev 2>/dev/null');
    if (!$output) {
        throw new Exception("cat command failed");
    }

    $lines = explode("\n", $output);
    foreach ($lines as $line) {
        if (strpos($line, ':') !== false) {
            list($iface, $data) = explode(':', $line, 2);
            $iface = trim($iface);
            
            if (in_array($iface, ['lo', 'sit0', 'ip6tnl0'])) continue;
            
            $stats = preg_split('/\s+/', trim($data));
            if (count($stats) >= 9) {
                $rx += intval($stats[0]);
                $tx += intval($stats[8]);
            }
        }
    }

    return ['rx' => $rx, 'tx' => $tx];
}

function parseIpCommand() {
    $rx = 0;
    $tx = 0;
    
    $output = shell_exec('ip -s link 2>/dev/null');
    if (!$output) {
        throw new Exception("ip command not available");
    }

    $lines = explode("\n", $output);
    $currentInterface = null;
    
    for ($i = 0; $i < count($lines); $i++) {
        $line = trim($lines[$i]);
        
        if (preg_match('/^\d+:\s+(\w+):/', $line, $matches)) {
            $currentInterface = $matches[1];
        }
        
        if ($currentInterface && !in_array($currentInterface, ['lo', 'sit0', 'ip6tnl0'])) {
            if (preg_match('/RX:\s+bytes\s+packets\s+errors/', $line)) {
                if (isset($lines[$i + 1])) {
                    $stats = preg_split('/\s+/', trim($lines[$i + 1]));
                    if (count($stats) >= 1) {
                        $rx += intval($stats[0]);
                    }
                }
            }
            
            if (preg_match('/TX:\s+bytes\s+packets\s+errors/', $line)) {
                if (isset($lines[$i + 1])) {
                    $stats = preg_split('/\s+/', trim($lines[$i + 1]));
                    if (count($stats) >= 1) {
                        $tx += intval($stats[0]);
                    }
                }
            }
        }
    }

    return ['rx' => $rx, 'tx' => $tx];
}

function calculateTrafficSpeed($result, $rx, $tx) {
    $result['upload_total'] = formatBytes($tx);
    $result['download_total'] = formatBytes($rx);

    $trafficFile = '/tmp/openwrt_traffic_stats.json';
    $now = microtime(true);
    
    if (file_exists($trafficFile) && is_readable($trafficFile)) {
        $content = file_get_contents($trafficFile);
        $savedData = json_decode($content, true);
        
        if ($savedData && isset($savedData['samples']) && is_array($savedData['samples'])) {
            $savedData['samples'][] = [
                'rx' => $rx,
                'tx' => $tx,
                'time' => $now
            ];
            
            if (count($savedData['samples']) > 8) {
                $savedData['samples'] = array_slice($savedData['samples'], -8);
            }
            
            if (count($savedData['samples']) >= 2) {
                $samples = $savedData['samples'];
                $lastSample = end($samples);
                $prevSample = $samples[count($samples) - 2];
                
                $delta_t = $lastSample['time'] - $prevSample['time'];
                
                if ($delta_t > 0) {
                    $rx_diff = $lastSample['rx'] - $prevSample['rx'];
                    $tx_diff = $lastSample['tx'] - $prevSample['tx'];
                    
                    $download_speed = max(0, $rx_diff / $delta_t);
                    $upload_speed = max(0, $tx_diff / $delta_t);
                    
                    $result['upload_speed'] = formatBytes($upload_speed) . '/S';
                    $result['download_speed'] = formatBytes($download_speed) . '/S';
                    $result['upload_speed_bytes'] = $upload_speed;
                    $result['download_speed_bytes'] = $download_speed;
                    
                    if (isset($_GET['_ajax']) && isset($_GET['debug_speed'])) {
                        $result['debug_speed'] = [
                            'delta_t' => round($delta_t, 3),
                            'rx_diff' => $rx_diff,
                            'tx_diff' => $tx_diff,
                            'rx_current' => $lastSample['rx'],
                            'tx_current' => $lastSample['tx'],
                            'rx_previous' => $prevSample['rx'],
                            'tx_previous' => $prevSample['tx'],
                            'download_speed_bytes' => $download_speed,
                            'upload_speed_bytes' => $upload_speed
                        ];
                    }
                }
            }
        } else {
            $savedData = ['samples' => [[
                'rx' => $rx,
                'tx' => $tx,
                'time' => $now
            ]]];
        }
    } else {
        $savedData = ['samples' => [[
            'rx' => $rx,
            'tx' => $tx,
            'time' => $now
        ]]];
    }
    
    if (is_writable('/tmp/') || is_writable(dirname($trafficFile))) {
        file_put_contents($trafficFile, json_encode($savedData));
    }

    return $result;
}

if (isset($_GET['_ajax'])) {
    error_reporting(0);
    ini_set('display_errors', 0);
    
    if (ob_get_level()) {
        ob_clean();
    }
    
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-cache, must-revalidate');
    header('Expires: Sat, 26 Jul 1997 05:00:00 GMT');
    
    try {
        $traffic = getOpenWrtTraffic();
        echo json_encode($traffic, JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        echo json_encode([
            'status' => 'error',
            'error' => 'Exception: ' . $e->getMessage(),
            'upload_speed' => '0 B/S',
            'download_speed' => '0 B/S',
            'upload_total' => '0 B',
            'download_total' => '0 B',
            'method' => 'error'
        ], JSON_UNESCAPED_UNICODE);
    }
    exit;
}

if (isset($_GET['debug'])) {
    header('Content-Type: application/json');
    $traffic = getOpenWrtTraffic();
    
    if (file_exists('/proc/net/dev')) {
        $lines = file('/proc/net/dev', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        $traffic['raw_interfaces'] = [];
        
        foreach ($lines as $line) {
            if (strpos($line, ':') !== false) {
                list($iface, $data) = explode(':', $line, 2);
                $iface = trim($iface);
                $stats = preg_split('/\s+/', trim($data));
                
                if (count($stats) >= 9) {
                    $traffic['raw_interfaces'][$iface] = [
                        'rx_bytes' => intval($stats[0]),
                        'tx_bytes' => intval($stats[8]),
                        'rx_formatted' => formatBytes(intval($stats[0])),
                        'tx_formatted' => formatBytes(intval($stats[8])),
                        'note' => 'rx=download, tx=upload'
                    ];
                }
            }
        }
    }
    
    echo json_encode($traffic, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit;
}

$traffic = getOpenWrtTraffic();
?>

<meta charset="UTF-8">
<title>OpenWrt Real-time Traffic Monitor</title>
<?php include './ping.php'; ?>
<script src="./assets/js/chart.umd.js"></script>
<style>
:root {
    --primary-color: #007bff;
    --success-color: #28a745;
    --danger-color: #dc3545;
    --warning-color: #ffc107;
    --info-color: #17a2b8;
    --light-color: #f8f9fa;
    --dark-color: #343a40;
    --secondary-color: #000;
    
    --gradient-primary: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    --gradient-success: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
    --gradient-danger: linear-gradient(135deg, #ee0979 0%, #ff6a00 100%);
    --gradient-info: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    
    --shadow-light: 0 2px 10px rgba(0,0,0,0.08);
    --shadow-medium: 0 4px 20px rgba(0,0,0,0.12);
    --shadow-heavy: 0 8px 40px rgba(0,0,0,0.16);
    
    --border-radius: 12px;
    --transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.header-section {
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(20px);
    border-radius: var(--border-radius);
    padding: 30px;
    margin-bottom: 30px;
    box-shadow: var(--shadow-medium);
    text-align: center;
    position: relative;
    overflow: hidden;
}

.header-section::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: var(--gradient-primary);
}

.header-section h2 {
    font-size: 2.5em;
    font-weight: 700;
    margin-bottom: 15px;
    background: var(--gradient-primary);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
}

.header-section h2 .icon {
    font-size: 0.8em;
}

.system-info {
    font-size: 1.1em;
    color: var(--secondary-color);
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 20px;
    flex-wrap: wrap;
}

.info-item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 16px;
    background: rgba(108, 117, 125, 0.1);
    border-radius: 20px;
    font-weight: 500;
}

.status-indicator {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    animation: pulse 2s infinite;
    position: relative;
}

.status-indicator::after {
    content: '';
    position: absolute;
    top: -2px;
    left: -2px;
    right: -2px;
    bottom: -2px;
    border-radius: 50%;
    border: 2px solid currentColor;
    opacity: 0;
    animation: ripple 2s infinite;
}

.status-online {
    background-color: var(--success-color);
    color: var(--success-color);
}

.status-offline {
    background-color: var(--danger-color);
    color: var(--danger-color);
}

@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.6; }
}

@keyframes ripple {
    0% { transform: scale(1); opacity: 0.6; }
    100% { transform: scale(1.5); opacity: 0; }
}

.stats-section {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 20px;
    margin-bottom: 30px;
}

.stat-card {
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(20px);
    border-radius: var(--border-radius);
    padding: 25px;
    box-shadow: var(--shadow-light);
    transition: var(--transition);
    position: relative;
    overflow: hidden;
}

.stat-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    transition: var(--transition);
}

.stat-card.upload::before {
    background: var(--gradient-danger);
}

.stat-card.download::before {
    background: var(--gradient-success);
}

.stat-card.total::before {
    background: var(--gradient-info);
}

.stat-card:hover {
    transform: translateY(-5px);
    box-shadow: var(--shadow-medium);
}

.stat-label {
    font-size: 0.9em;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 1px;
    margin-bottom: 12px;
    color: var(--secondary-color);
    display: flex;
    align-items: center;
    gap: 8px;
}

.stat-value {
    font-size: 2.2em;
    font-weight: 700;
    margin-bottom: 8px;
    display: block;
    transition: var(--transition);
}

.stat-card.upload .stat-value {
    color: #dc3545;
}

.stat-card.download .stat-value {
    color: #28a745;
}

.stat-card.total .stat-value {
    color: #17a2b8;
}

.stat-description {
    font-size: 0.95em;
    color: var(--secondary-color);
    font-weight: 500;
}

.chart-section {
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(20px);
    border-radius: var(--border-radius);
    padding: 30px;
    margin-bottom: 30px;
    box-shadow: var(--shadow-medium);
    position: relative;
}

.chart-section::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: var(--gradient-primary);
}

.chart-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 25px;
    flex-wrap: wrap;
    gap: 15px;
}

.chart-title {
    font-size: 1.5em;
    font-weight: 700;
    color: var(--dark-color);
    display: flex;
    align-items: center;
    gap: 10px;
}

.chart-controls {
    display: flex;
    gap: 10px;
    align-items: center;
}

.chart-toggle {
    padding: 8px 16px;
    border: none;
    border-radius: 20px;
    font-weight: 600;
    cursor: pointer;
    transition: var(--transition);
    font-size: 0.85em;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.chart-toggle.active {
    background: var(--gradient-primary);
    color: white;
    box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
}

.chart-toggle:not(.active) {
    background: rgba(108, 117, 125, 0.1);
    color: var(--secondary-color);
}

.chart-toggle:hover:not(.active) {
    background: rgba(108, 117, 125, 0.2);
}

.chart-container {
    position: relative;
    height: 400px;
    width: 100%;
}

.legend-container {
    display: flex;
    justify-content: center;
    gap: 30px;
    margin-top: 20px;
    flex-wrap: wrap;
}

.legend-item {
    display: flex;
    align-items: center;
    gap: 8px;
    font-weight: 600;
    color: var(--dark-color);
}

.legend-color {
    width: 16px;
    height: 16px;
    border-radius: 3px;
}

.legend-color.upload {
    background: linear-gradient(135deg, #ff6b6b, #ee5a52);
}

.legend-color.download {
    background: linear-gradient(135deg, #51cf66, #40c057);
}

.footer-section {
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(20px);
    border-radius: var(--border-radius);
    padding: 20px;
    box-shadow: var(--shadow-light);
    text-align: center;
}

.last-update {
    color: var(--secondary-color);
    font-weight: 500;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
}

.error-message {
    background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%);
    color: #721c24;
    padding: 20px;
    border-radius: var(--border-radius);
    margin-bottom: 20px;
    text-align: center;
    font-weight: 600;
    box-shadow: var(--shadow-light);
    border: 1px solid rgba(220, 53, 69, 0.2);
}

.debug-info {
    background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%);
    color: #0c5460;
    padding: 15px;
    border-radius: var(--border-radius);
    margin-top: 20px;
    font-size: 0.9em;
    box-shadow: var(--shadow-light);
}

.icon {
    width: 20px;
    height: 20px;
    display: inline-block;
}

@media (max-width: 768px) {
    body {
        padding: 10px;
    }
    
    .header-section {
        padding: 20px;
    }
    
    .header-section h2 {
        font-size: 2em;
    }
    
    .system-info {
        font-size: 1em;
        gap: 15px;
    }
    
    .stats-section {
        grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
        gap: 15px;
    }
    
    .stat-card {
        padding: 20px;
    }
    
    .stat-value {
        font-size: 1.8em;
    }
    
    .chart-section {
        padding: 20px;
    }
    
    .chart-header {
        flex-direction: column;
        align-items: flex-start;
    }
    
    .chart-container {
        height: 300px;
    }
    
    .legend-container {
        gap: 20px;
    }
}

@media (max-width: 480px) {
    .stats-section {
        grid-template-columns: 1fr;
    }
    
    .chart-container {
        height: 250px;
    }
    
    .system-info {
        flex-direction: column;
        align-items: center;
    }
}

.loading-spinner {
    display: inline-block;
    width: 20px;
    height: 20px;
    border: 2px solid rgba(0,0,0,0.1);
    border-radius: 50%;
    border-top-color: var(--primary-color);
    animation: spin 1s ease-in-out infinite;
}

@keyframes spin {
    to { transform: rotate(360deg); }
}

.stat-value {
    transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
}

.chart-section {
    transition: var(--transition);
}

.tooltip {
    background: rgba(0, 0, 0, 0.8);
    color: white;
    padding: 8px 12px;
    border-radius: 6px;
    font-size: 0.85em;
    font-weight: 500;
}
</style>
<div class="container-sm container-bg px-0 px-sm-4 mt-4">
<nav class="navbar navbar-expand-lg sticky-top">
    <div class="container-sm container px-4 px-sm-3 px-md-4">
        <a class="navbar-brand d-flex align-items-center" href="#">
            <?= $iconHtml ?>
            <span style="color: var(--accent-color); letter-spacing: 1px;"><?= htmlspecialchars($title) ?></span>
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarContent">
            <i class="bi bi-list" style="color: #ffcc00; font-size: 1.8rem;"></i>
        </button>
        <div class="collapse navbar-collapse" id="navbarContent">
            <ul class="navbar-nav me-auto mb-2 mb-lg-0" style="font-size: 18px;">
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'index.php' ? 'active' : '' ?>" href="./index.php"><i class="bi bi-house-door"></i> <span data-translate="home">Home</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'mihomo_manager.php' ? 'active' : '' ?>" href="./mihomo_manager.php"><i class="bi bi-folder"></i> <span data-translate="manager">Manager</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'singbox.php' ? 'active' : '' ?>" href="./singbox.php"><i class="bi bi-shop"></i> <span data-translate="template_i">Template I</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'subscription.php' ? 'active' : '' ?>" href="./subscription.php"><i class="bi bi-bank"></i> <span data-translate="template_ii">Template II</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'mihomo.php' ? 'active' : '' ?>" href="./mihomo.php"><i class="bi bi-building"></i> <span data-translate="template_iii">Template III</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'netmon.php' ? 'active' : '' ?>" href="./netmon.php"><i class="bi bi-activity"></i> <span data-translate="traffic_monitor">Traffic Monitor</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'monaco.php' ? 'active' : '' ?>" href="./monaco.php"><i class="bi bi-bank"></i> <span data-translate="pageTitle">File Assistant</span></a>
                </li>
            </ul>
            <div class="d-flex align-items-center">
                <div class="me-3 d-block">
                    <button type="button" class="btn btn-primary icon-btn me-2" onclick="toggleControlPanel()" data-tooltip="control_panel"><i class="bi bi-gear"> </i></button>
                    <button type="button" class="btn btn-danger icon-btn me-2" data-bs-toggle="modal" data-bs-target="#langModal" data-tooltip="set_language"><i class="bi bi-translate"></i></button>
                    <button type="button" class="btn btn-success icon-btn me-2" data-bs-toggle="modal" data-bs-target="#musicModal" data-tooltip="music_player"><i class="bi bi-music-note-beamed"></i></button>
                    <button type="button" id="toggleIpStatusBtn" class="btn btn-warning icon-btn me-2" onclick="toggleIpStatusBar()" data-tooltip="hide_ip_info"><i class="bi bi-eye-slash"> </i></button>
                    <button type="button" class="btn btn-pink icon-btn me-2" data-bs-toggle="modal" data-bs-target="#portModal" data-tooltip="viewPortInfoButton"><i class="bi bi-plug"></i></button>
                    <button type="button" class="btn-refresh-page btn btn-orange icon-btn me-2 d-none d-sm-inline"><i class="fas fa-sync-alt"></i></button>
                    <button type="button" class="btn btn-info icon-btn me-2" onclick="document.getElementById('colorPicker').click()" data-tooltip="component_bg_color"><i class="bi bi-palette"></i></button>
                    <input type="color" id="colorPicker" value="#0f3460" style="display: none;">
            </div>
        </div>
    </div>
</nav>
<div class="container-sm px-4">
    <div class="header-section">
        <h2>
            <i class="bi bi-globe2"></i>
            <span data-translate="traffic_monitor_title">OpenWrt Real-time Traffic Monitor</span>
            <span id="status-indicator" class="status-indicator status-online"></span>
        </h2>
        <div class="system-info">
            <div class="info-item">
                <i class="bi bi-gear"></i>
                <span data-translate="detection_method">Detection Method</span>: 
                <span id="detection-method"><?php echo $traffic['method']; ?></span>
            </div>
            <div class="info-item">
                <i class="bi bi-plug"></i>
                <span data-translate="main_interface">Main Interface</span>: 
                <span id="main-interface"><?php echo $traffic['selected_interface'] ?? 'unknown'; ?></span>
            </div>
            <div class="info-item">
                <a href="?debug=1" target="_blank" style="color: #007bff; text-decoration: none; font-weight: 600;">
                    <i class="bi bi-search"></i>
                    <span data-translate="debug_info">Debug Info</span>
                </a>
            </div>
        </div>
    </div>
    
    <div id="error-container">
        <?php if ($traffic['status'] === 'error'): ?>
            <div class="error-message">
                <i class="bi bi-exclamation-triangle"></i>
                <?php echo htmlspecialchars($traffic['error'] ?? 'Unknown error'); ?>
            </div>
        <?php endif; ?>
    </div>
    
    <div class="stats-section">
        <div class="stat-card upload">
            <div class="stat-label">
                <i class="bi bi-upload"></i>
                <span data-translate="upload_speed">Upload Speed</span>
            </div>
            <span id="upload_speed" class="stat-value"><?php echo $traffic['upload_speed']; ?></span>
            <div class="stat-description" data-translate="upload_bandwidth">Real-time Upload Bandwidth</div>
        </div>
        
        <div class="stat-card download">
            <div class="stat-label">
                <i class="bi bi-download"></i>
                <span data-translate="download_speed">Download Speed</span>
            </div>
            <span id="download_speed" class="stat-value"><?php echo $traffic['download_speed']; ?></span>
            <div class="stat-description" data-translate="download_bandwidth">Real-time Download Bandwidth</div>
        </div>
        
        <div class="stat-card total">
            <div class="stat-label">
                <i class="bi bi-bar-chart-line"></i>
                <span data-translate="upload_total">Total Upload</span>
            </div>
            <span id="upload_total" class="stat-value"><?php echo $traffic['upload_total']; ?></span>
            <div class="stat-description" data-translate="upload_total_desc">Cumulative Sent Traffic</div>
        </div>
        
        <div class="stat-card total">
            <div class="stat-label">
                <i class="bi bi-graph-up-arrow"></i>
                <span data-translate="download_total">Total Download</span>
            </div>
            <span id="download_total" class="stat-value"><?php echo $traffic['download_total']; ?></span>
            <div class="stat-description" data-translate="download_total_desc">Cumulative Received Traffic</div>
        </div>
    </div>
    
    <div class="chart-section">
        <div class="chart-header">
            <div class="chart-title">
                <i class="bi bi-graph-up"></i>
                <span data-translate="realtime_chart">Realtime Traffic Chart</span>
            </div>
            <div class="chart-controls">
                <button class="chart-toggle active" data-range="60" data-translate="range_1min">1 Minute</button>
                <button class="chart-toggle" data-range="300" data-translate="range_5min">5 Minutes</button>
                <button class="chart-toggle" data-range="900" data-translate="range_15min">15 Minutes</button>
                <button class="chart-toggle" data-range="1800" data-translate="range_30min">30 Minutes</button>
            </div>
        </div>
        
        <div class="chart-container">
            <canvas id="trafficChart"></canvas>
        </div>
        
        <div class="legend-container">
            <div class="legend-item">
                <div class="legend-color upload"></div>
                <span data-translate="upload_speed">Upload Speed</span>
            </div>
            <div class="legend-item">
                <div class="legend-color download"></div>
                <span data-translate="download_speed">Download Speed</span>
            </div>
        </div>
    </div>
    
    <div class="footer-section">
        <div class="last-update">
            <i class="bi bi-clock"></i>
            <span data-translate="last_update">Last Update</span>: 
            <span id="last-update" data-translate="just_now"></span>
        </div>
    </div>
</div>

<script>
let updateInterval;
let errorCount = 0;
const maxErrors = 3;
let chart = null;
let chartData = {
    labels: [],
    uploadData: [],
    downloadData: []
};
let currentRange = 60;

function initChart() {
    const ctx = document.getElementById('trafficChart').getContext('2d');
    
    chart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: chartData.labels,
            datasets: [{
                label: translations['upload_speed'] || 'Upload Speed',
                data: chartData.uploadData,
                borderColor: 'rgba(220, 53, 69, 1)',
                backgroundColor: 'rgba(220, 53, 69, 0.1)',
                borderWidth: 3,
                fill: true,
                tension: 0.4,
                pointBackgroundColor: 'rgba(220, 53, 69, 1)',
                pointBorderColor: '#fff',
                pointBorderWidth: 2,
                pointRadius: 4,
                pointHoverRadius: 6,
                pointHoverBackgroundColor: 'rgba(220, 53, 69, 1)',
                pointHoverBorderColor: '#fff',
                pointHoverBorderWidth: 3
            }, {
                label: translations['download_speed'] || 'Download Speed',
                data: chartData.downloadData,
                borderColor: 'rgba(40, 167, 69, 1)',
                backgroundColor: 'rgba(40, 167, 69, 0.1)',
                borderWidth: 3,
                fill: true,
                tension: 0.4,
                pointBackgroundColor: 'rgba(40, 167, 69, 1)',
                pointBorderColor: '#fff',
                pointBorderWidth: 2,
                pointRadius: 4,
                pointHoverRadius: 6,
                pointHoverBackgroundColor: 'rgba(40, 167, 69, 1)',
                pointHoverBorderColor: '#fff',
                pointHoverBorderWidth: 3
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: {
                intersect: false,
                mode: 'index'
            },
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                    titleColor: '#fff',
                    bodyColor: '#fff',
                    borderColor: 'rgba(255, 255, 255, 0.2)',
                    borderWidth: 1,
                    cornerRadius: 8,
                    displayColors: true,
                    callbacks: {
                        label: function(context) {
                            return context.dataset.label + ': ' + formatBytesForChart(context.parsed.y) + '/S';
                        }
                    }
                }
            },
            scales: {
                x: {
                    display: true,
                    title: {
                        display: true,
                        text: translations['time'] || 'Time',
                        color: '#666',
                        font: {
                            size: 14,
                            weight: 'bold'
                        }
                    },
                    grid: {
                        color: 'rgba(0, 0, 0, 0.1)',
                        drawBorder: false
                    },
                    ticks: {
                        color: '#666',
                        font: {
                            size: 12
                        },
                        maxRotation: 45
                    }
                },
                y: {
                    display: true,
                    title: {
                        display: true,
                        text: translations['speed_bytes'] || 'Speed (Bytes/s)',
                        color: '#666',
                        font: {
                            size: 14,
                            weight: 'bold'
                        }
                    },
                    grid: {
                        color: 'rgba(0, 0, 0, 0.1)',
                        drawBorder: false
                    },
                    ticks: {
                        color: '#666',
                        font: {
                            size: 12
                        },
                        callback: function(value) {
                            return formatBytesForChart(value) + '/S';
                        }
                    },
                    beginAtZero: true
                }
            },
            elements: {
                line: {
                    borderJoinStyle: 'round'
                }
            },
            animation: {
                duration: 750,
                easing: 'easeInOutQuart'
            }
        }
    });
}

function formatBytesForChart(bytes) {
    if (bytes <= 0) return "0 B";
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    const pow = Math.floor(Math.log(bytes) / Math.log(1024));
    const adjustedPow = Math.min(pow, units.length - 1);
    const adjustedBytes = bytes / Math.pow(1024, adjustedPow);
    return (adjustedBytes < 10 ? adjustedBytes.toFixed(1) : Math.round(adjustedBytes)) + ' ' + units[adjustedPow];
}

function updateChart(uploadSpeedBytes, downloadSpeedBytes) {
    const now = new Date();
    const timeLabel = now.getHours().toString().padStart(2, '0') + ':' + 
                     now.getMinutes().toString().padStart(2, '0') + ':' +
                     now.getSeconds().toString().padStart(2, '0');
    
    chartData.labels.push(timeLabel);
    chartData.uploadData.push(uploadSpeedBytes || 0);
    chartData.downloadData.push(downloadSpeedBytes || 0);
    
    const maxDataPoints = Math.floor(currentRange / 1.5);
    if (chartData.labels.length > maxDataPoints) {
        chartData.labels.shift();
        chartData.uploadData.shift();
        chartData.downloadData.shift();
    }
    
    if (chart) {
        chart.data.labels = chartData.labels;
        chart.data.datasets[0].data = chartData.uploadData;
        chart.data.datasets[1].data = chartData.downloadData;
        chart.update('none');
    }
}

function updateTrafficData() {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);    
    fetch(window.location.href + '?_ajax=1&t=' + Date.now(), {
        signal: controller.signal,
        method: 'GET',
        headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
        }
    })
        .then(response => {
            clearTimeout(timeoutId);
            
            if (!response.ok) {
                throw new Error('HTTP ' + response.status + ' ' + response.statusText);
            }
            
            const contentType = response.headers.get('content-type');
            if (!contentType || !contentType.includes('application/json')) {
                throw new Error(translations['error_invalid_format'] || 'Invalid data format');
            }
            
            return response.text();
        })
        .then(text => {
            let data;
            try {
                data = JSON.parse(text);
            } catch (parseError) {
                throw new Error(translations['error_parse_failed'] || 'Failed to parse data');
            }
            
            errorCount = 0;
            
            const statusIndicator = document.getElementById('status-indicator');
            statusIndicator.className = 'status-indicator status-online';
            
            if (document.getElementById('detection-method')) {
                document.getElementById('detection-method').textContent = data.method || 'unknown';
            }
            if (document.getElementById('main-interface')) {
                document.getElementById('main-interface').textContent = data.selected_interface || 'unknown';
            }
            
            const errorContainer = document.getElementById('error-container');
            if (data.status === 'error') {
                errorContainer.innerHTML = '<div class="error-message"><i class="bi bi-exclamation-triangle"></i> ' + 
                    (data.error || (translations['error_fetch_failed'] || 'Failed to fetch traffic data')) + '</div>';
                statusIndicator.className = 'status-indicator status-offline';
                return;
            } else {
                errorContainer.innerHTML = '';
            }
            
            updateStatValue('upload_speed', data.upload_speed || '0 B/S');
            updateStatValue('download_speed', data.download_speed || '0 B/S');
            updateStatValue('upload_total', data.upload_total || '0 B');
            updateStatValue('download_total', data.download_total || '0 B');
            
            updateChart(data.upload_speed_bytes, data.download_speed_bytes);
            
            const now = new Date();
            document.getElementById('last-update').textContent = 
                now.getHours().toString().padStart(2, '0') + ':' +
                now.getMinutes().toString().padStart(2, '0') + ':' +
                now.getSeconds().toString().padStart(2, '0');
        })
        .catch(error => {
            clearTimeout(timeoutId);
            errorCount++;
            
            const statusIndicator = document.getElementById('status-indicator');
            statusIndicator.className = 'status-indicator status-offline';
            
            let errorMessage = translations['error_network'] || 'Network connection failed';
            if (error.name === 'AbortError') {
                errorMessage = translations['error_timeout'] || 'Request timed out';
            }
            
            if (errorCount >= maxErrors) {
                document.getElementById('error-container').innerHTML = 
                    '<div class="error-message"><i class="bi bi-exclamation-triangle"></i> ' + errorMessage + 
                    '<br>' + (translations['error_debug_info'] || 'Please visit the debug page for details') + 
                    ' <a href="?debug=1" target="_blank" style="color: #721c24; font-weight: 600;">' + 
                    (translations['debug_page'] || 'Debug Page') + '</a></div>';
                
                clearInterval(updateInterval);
                
                setTimeout(() => {
                    errorCount = 0;
                    startUpdating();
                }, 15000);
            }
        });
}

function updateStatValue(elementId, newValue) {
    const element = document.getElementById(elementId);
    if (element && element.textContent !== newValue) {
        element.style.transform = 'scale(0.95)';
        element.style.opacity = '0.7';
        
        setTimeout(() => {
            element.textContent = newValue;
            element.style.transform = 'scale(1)';
            element.style.opacity = '1';
        }, 150);
    }
}

function startUpdating() {
    updateTrafficData();
    updateInterval = setInterval(updateTrafficData, 1500);
}

document.addEventListener('DOMContentLoaded', function() {
    initChart();
    startUpdating();
    
    document.querySelectorAll('.chart-toggle').forEach(button => {
        button.addEventListener('click', function() {
            document.querySelectorAll('.chart-toggle').forEach(btn => btn.classList.remove('active'));
            this.classList.add('active');
            
            currentRange = parseInt(this.dataset.range);
            
            chartData.labels = [];
            chartData.uploadData = [];
            chartData.downloadData = [];
            
            if (chart) {
                chart.data.labels = chartData.labels;
                chart.data.datasets[0].data = chartData.uploadData;
                chart.data.datasets[1].data = chartData.downloadData;
                chart.update();
            }
        });
    });
});

document.addEventListener('visibilitychange', function() {
    if (document.hidden) {
        clearInterval(updateInterval);
    } else {
        startUpdating();
    }
});

window.addEventListener('beforeunload', function() {
    clearInterval(updateInterval);
    if (chart) {
        chart.destroy();
    }
});

window.addEventListener('resize', function() {
    if (chart) {
        chart.resize();
    }
});
</script>
<footer class="text-center"><p><?php echo $footer ?></p></footer>
