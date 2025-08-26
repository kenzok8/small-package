<?php
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $configFile = "/etc/php.ini"; 

    $configChanges = [
        'upload_max_filesize' => '2048M',
        'post_max_size' => '2048M',
        'max_file_uploads' => '100',
        'memory_limit' => '2048M',
        'max_execution_time' => '3600',
        'max_input_time' => '3600'
    ];

    $configData = file_get_contents($configFile);

    foreach ($configChanges as $key => $value) {
        $configData = preg_replace("/^$key\s*=\s*.*/m", "$key = $value", $configData);
    }

    if (file_put_contents($configFile, $configData) !== false) {
        shell_exec("/etc/init.d/uhttpd restart > /dev/null 2>&1 &");
        shell_exec("/etc/init.d/nginx restart > /dev/null 2>&1 &");

        echo json_encode(["status" => "success", "message" => "PHP configuration updated and restarted successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Update failed, please check permissions!"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid request"]);
}
?>