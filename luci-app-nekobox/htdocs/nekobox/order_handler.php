<?php
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['fileOrder'])) {
    $fileOrder = json_decode($_POST['fileOrder'], true);
    $backgroundHistoryFile = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/background_history.txt';
    
    $existingData = [];
    if (file_exists($backgroundHistoryFile)) {
        $existingData = array_filter(array_map('trim', file($backgroundHistoryFile)));
    }

    $mergedData = array_merge($existingData, $fileOrder);

    $uniqueData = [];
    foreach ($fileOrder as $file) {
        if (!in_array($file, $uniqueData)) {
            $uniqueData[] = $file;  
        }
    }

    file_put_contents($backgroundHistoryFile, implode("\n", $uniqueData) . "\n");

    echo "文件顺序更新成功";
}
?>
