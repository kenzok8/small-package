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
        logMessage("无法写入版本文件: $versionFile");
    }
}

$repo_owner = "MetaCubeX";
$repo_name = "mihomo";
$api_url = "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest";

if (isset($_GET['check_version'])) {
    $curl_command = "curl -s -H 'User-Agent: PHP' " . escapeshellarg($api_url);
    $response = shell_exec($curl_command);

    if ($response === false || empty($response)) {
        logMessage("GitHub API 请求失败，尝试使用 wget...");
        $wget_command = "wget -q --no-check-certificate --timeout=10 " . escapeshellarg($api_url) . " -O /tmp/api_response.json";
        exec($wget_command, $output, $return_var);

        if ($return_var !== 0 || !file_exists('/tmp/api_response.json')) {
            logMessage("GitHub API 请求失败，curl 和 wget 都失败了。");
            echo "GitHub API 请求失败。";
            exit;
        }

        $response = file_get_contents('/tmp/api_response.json');
        unlink('/tmp/api_response.json');
    }

    $data = json_decode($response, true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        echo "解析 GitHub API 响应时出错: " . json_last_error_msg();
        exit;
    }

    $latest_version = $data['tag_name'] ?? '';

    if (empty($latest_version)) {
        echo "未找到最新版本信息。";
        exit;
    }

    echo "最新版本: " . htmlspecialchars($latest_version);
    exit;
}

$curl_command = "curl -s -H 'User-Agent: PHP' " . escapeshellarg($api_url);
$response = shell_exec($curl_command);

if ($response === false || empty($response)) {
    logMessage("GitHub API 请求失败，尝试使用 wget...");
    $wget_command = "wget -q --no-check-certificate --timeout=10 " . escapeshellarg($api_url) . " -O /tmp/api_response.json";
    exec($wget_command, $output, $return_var);

    if ($return_var !== 0 || !file_exists('/tmp/api_response.json')) {
        logMessage("GitHub API 请求失败，curl 和 wget 都失败了。");
        die("GitHub API 请求失败。请检查网络连接或稍后重试。");
    }

    $response = file_get_contents('/tmp/api_response.json');
    unlink('/tmp/api_response.json');
}

$data = json_decode($response, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    die("解析 GitHub API 响应时出错: " . json_last_error_msg());
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
        die("未找到适合架构的下载链接: $current_arch");
}

if (trim($current_version) === trim($latest_version)) {
    echo "当前版本已是最新版本，无需更新。";
    exit;
}

$curl_command = "curl -sL " . escapeshellarg($download_url) . " -o " . escapeshellarg($temp_file);
exec($curl_command, $output, $return_var);

if ($return_var !== 0 || !file_exists($temp_file)) {
    logMessage("下载失败，尝试使用 wget...");
    $wget_command = "wget -q --show-progress --no-check-certificate " . escapeshellarg($download_url) . " -O " . escapeshellarg($temp_file);
    exec($wget_command, $output, $return_var);

    if ($return_var !== 0 || !file_exists($temp_file)) {
        logMessage("下载失败，curl 和 wget 都失败了。");
        die("下载失败！");
    }
}

exec("gzip -d -c '$temp_file' > '/tmp/mihomo-linux-arm64'", $output, $return_var);

if ($return_var === 0) {
    exec("mv '/tmp/mihomo-linux-arm64' '$install_path'", $output, $return_var);

    if ($return_var === 0) {
        exec("chmod 0755 '$install_path'", $output, $return_var);

        if ($return_var === 0) {
            writeVersionToFile($latest_version); 
            logMessage("更新完成！当前版本: $latest_version");
            echo "更新完成！当前版本: $latest_version";
        } else {
            logMessage("设置权限失败！");
            echo "设置权限失败！";
        }
    } else {
        logMessage("移动文件失败！");
        echo "移动文件失败！";
    }
} else {
    logMessage("解压失败！");
    echo "解压失败！";
}

if (file_exists($temp_file)) {
    unlink($temp_file);
}
?>
