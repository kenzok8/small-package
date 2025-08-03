<?php
$file = './mihomo_manager.php';
$aceScript = '<script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/ace.js"></script>';
$action = $_GET['action'] ?? '';

if (!file_exists($file) || !is_writable($file)) {
    http_response_code(500);
    exit;
}

$content = file_get_contents($file);

if ($action === 'check') {
    echo strpos($content, $aceScript) !== false ? '1' : '0';
    exit;
}

if ($action === 'add') {
    if (strpos($content, $aceScript) === false) {
        file_put_contents($file, $content . "\n" . $aceScript . "\n");
    }
    exit;
}

if ($action === 'remove') {
    if (strpos($content, $aceScript) !== false) {
        file_put_contents($file, str_replace($aceScript, '', $content));
    }
    exit;
}

http_response_code(400);
exit;
