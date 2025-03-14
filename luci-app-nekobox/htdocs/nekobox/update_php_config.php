<?php
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $configFile = "/etc/php.ini"; 

    $configChanges = [
        'upload_max_filesize' => '1024M',
        'post_max_size' => '1024M',
        'max_file_uploads' => '50',
        'memory_limit' => '1024M',
        'max_execution_time' => '1800',
        'max_input_time' => '1800'
    ];

    $configData = file_get_contents($configFile);

    foreach ($configChanges as $key => $value) {
        $configData = preg_replace("/^$key\s*=\s*.*/m", "$key = $value", $configData);
    }

    if (file_put_contents($configFile, $configData) !== false) {
        shell_exec("/etc/init.d/uhttpd restart > /dev/null 2>&1 &");
        shell_exec("/etc/init.d/nginx restart > /dev/null 2>&1 &");

        echo json_encode(["status" => "success", "message" => "PHP configuration has been updated and restarted"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Update failed, check permissions!"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid request"]);
}
?>
