<?php
$uploadDir = '/etc/neko/proxy_provider/';
$configDir = '/etc/neko/config/';

if (isset($_GET['file'])) {
    $file = basename($_GET['file']);
    
    // 检查代理文件
    $filePath = $uploadDir . $file;
    if (file_exists($filePath)) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . $file . '"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($filePath));
        readfile($filePath);
        exit;
    }

    // 检查配置文件
    $configPath = $configDir . $file;
    if (file_exists($configPath)) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . $file . '"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($configPath));
        readfile($configPath);
        exit;
    }

    echo '文件不存在！';
}
