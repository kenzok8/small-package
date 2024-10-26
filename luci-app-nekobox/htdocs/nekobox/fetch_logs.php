<?php

ini_set('memory_limit', '128M'); 

header('Content-Type: text/plain');

$allowed_files = [
    'plugin_log' => '/etc/neko/tmp/log.txt',
    'mihomo_log' => '/etc/neko/tmp/neko_log.txt',
    'singbox_log' => '/var/log/singbox_log.txt',
];

$file = $_GET['file'] ?? '';
$max_lines = 100; 
$max_chars = 1000000; 

if (array_key_exists($file, $allowed_files)) {
    $file_path = $allowed_files[$file];

    if (file_exists($file_path)) {
        $lines = file($file_path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        
        $content = implode(PHP_EOL, $lines);
        
        if (strlen($content) > $max_chars) {
            file_put_contents($file_path, ''); 
            echo "Log file has been cleared, exceeding the character limit.";
            return;
        }

        if (count($lines) > $max_lines) {
            $lines = array_slice($lines, -$max_lines); 
            file_put_contents($file_path, implode(PHP_EOL, $lines)); 
        }

        echo htmlspecialchars(implode(PHP_EOL, $lines));
    } else {
        http_response_code(404);
        echo "File not found.";
    }
} else {
    http_response_code(403);
    echo "Forbidden.";
}
