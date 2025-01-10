<?php

ini_set('memory_limit', '256M'); 

header('Content-Type: text/plain');

$allowed_files = [
    'plugin_log' => '/etc/neko/tmp/log.txt',
    'mihomo_log' => '/etc/neko/tmp/neko_log.txt',
    'singbox_log' => '/var/log/singbox_log.txt',
];

$file = $_GET['file'] ?? '';
$max_chars = 1000000; 
$max_line_length = 160; 

function remove_ansi_colors($string) {
    $pattern = '/\033\[[0-9;]*m/';
    if (@preg_match($pattern, '') === false) {
        error_log("Invalid regex pattern: $pattern");
        return $string; 
    }
    return preg_replace($pattern, '', $string);
}

function format_datetime($line) {
    $pattern = '/^\[\w{3} \w{3}\s+\d{1,2} (\d{2}:\d{2}:\d{2}) [A-Z]+ \d{4}\] (.*)$/';
    
    if (preg_match($pattern, $line, $matches)) {
        return sprintf('[ %s ] %s', $matches[1], $matches[2]);
    }

    $pattern_standard = '/^(\+?\d{4}\s)(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})/';
    if (preg_match($pattern_standard, $line, $matches)) {
        return preg_replace($pattern_standard, '[ \3 ]', $line);
    }

    return $line;
}

function is_bang_line($line) {
    return preg_match('/^\[\!\]/', $line);
}

function filter_unwanted_lines($lines) {
    return array_filter($lines, function($line) {
        return !preg_match('/^(Environment|Tags|CGO):/', $line);
    });
}

if (array_key_exists($file, $allowed_files)) {
    $file_path = $allowed_files[$file];

    if (file_exists($file_path)) {
        $lines = file($file_path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);       
        $lines = array_map('remove_ansi_colors', $lines);        
        $lines = array_map('format_datetime', $lines);
        $lines = filter_unwanted_lines($lines);
        $lines = array_filter($lines, function($line) use ($max_line_length) {
            return strlen($line) <= $max_line_length && !is_bang_line($line);
        });

        $lines = array_values($lines);

        $lines_with_numbers = array_map(function($line, $index) {
            return sprintf("%d %s", $index + 1, $line);  
        }, $lines, array_keys($lines));

        $content = implode(PHP_EOL, $lines_with_numbers);

        if (strlen($content) > $max_chars) {
            file_put_contents($file_path, ''); 
            echo "Log file has been cleared, exceeding the character limit.";
            return;
        }

        echo htmlspecialchars($content); 
    } else {
        http_response_code(404);
        echo "File not found.";
    }
} else {
    http_response_code(403);
    echo "Forbidden.";
}
?>
