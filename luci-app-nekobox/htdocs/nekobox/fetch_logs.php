<?php

ini_set('memory_limit', '256M'); 

header('Content-Type: text/plain');

$allowed_files = [
    'plugin_log' => '/etc/neko/tmp/log.txt',
    'mihomo_log' => '/etc/neko/tmp/neko_log.txt',
    'singbox_log' => '/var/log/singbox_log.txt',
];

$file = $_GET['file'] ?? '';
$max_lines = 100; 
$max_chars = 1000000; 
$max_line_length = 300; 

function remove_ansi_colors($string) {
    $pattern = '/\033\[[0-9;]*m/';
    if (@preg_match($pattern, '') === false) {
        error_log("Invalid regex pattern: $pattern");
        return $string; 
    }
    return preg_replace($pattern, '', $string);
}

function format_datetime($line) {
    $pattern = '/^(\+?\d{4}\s)(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})/';   
    if (@preg_match($pattern, '') === false) {
        error_log("Invalid regex pattern: $pattern");
        return $line; 
    }
    return preg_replace($pattern, '[ \3 ]', $line);
}

if (array_key_exists($file, $allowed_files)) {
    $file_path = $allowed_files[$file];

    if (file_exists($file_path)) {
        $lines = file($file_path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);       
        $lines = array_map('remove_ansi_colors', $lines);        
        $lines = array_map('format_datetime', $lines);
        $lines = array_filter($lines, function($line) use ($max_line_length) {
            return strlen($line) <= $max_line_length;
        });
        
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
?>
