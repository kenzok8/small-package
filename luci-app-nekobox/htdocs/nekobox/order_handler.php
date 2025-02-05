<?php
$backgroundHistoryFile = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/background_history.txt';

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['order'])) {
    $order = $_POST['order'];

    if (file_exists($backgroundHistoryFile)) {
        $backgroundFiles = array_filter(array_map('trim', file($backgroundHistoryFile)));

        $newOrder = [];
        foreach ($order as $file) {
            $newOrder[] = basename($file); 
        }

        file_put_contents($backgroundHistoryFile, implode(PHP_EOL, $newOrder));
        echo '排序已保存';
    } else {
        echo '背景历史文件不存在';
    }
} elseif ($_SERVER['REQUEST_METHOD'] == 'GET') {
    if (file_exists($backgroundHistoryFile)) {
        $backgroundFiles = array_filter(array_map('trim', file($backgroundHistoryFile)));
        echo json_encode(array_values($backgroundFiles));
    } else {
        echo json_encode([]);
    }
} else {
    echo '无效的请求';
}
?>