<?php

$singbox_log = '/var/log/singbox_log.txt';  
$maxSize = 1048576;
$maxOldLogs = 5;

function rotateLogs($logFile, $maxSize = 1048576, $maxOldLogs = 5) {
    if (file_exists($logFile) && filesize($logFile) > $maxSize) {
        $oldLogFile = $logFile . '.old';
        rename($logFile, $oldLogFile);
        shell_exec("gzip $oldLogFile");
        $oldLogs = glob($logFile . '.old.gz');
        if (count($oldLogs) > $maxOldLogs) {
            array_multisort(array_map('filemtime', $oldLogs), SORT_ASC, $oldLogs);  
            $logsToDelete = array_slice($oldLogs, 0, count($oldLogs) - $maxOldLogs);
            foreach ($logsToDelete as $logToDelete) {
                unlink($logToDelete);  
            }
        }

        touch($logFile);
        chmod($logFile, 0644);
        file_put_contents($logFile, '');
    }
}

rotateLogs($singbox_log);
?>
