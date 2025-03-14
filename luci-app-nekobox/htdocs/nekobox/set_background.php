<?php
$action = $_POST['action'] ?? '';
$filename = $_POST['filename'] ?? '';
$type = $_POST['type'] ?? '';

$pingFile = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/ping.php';
$currentBgFile = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/current_background.txt';
$backgroundHistoryFile = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/background_history.txt'; 

$pingContent = file_get_contents($pingFile);
$audioElement = "";
$backgroundStyle = "";

if (!file_exists($backgroundHistoryFile)) {
    file_put_contents($backgroundHistoryFile, "");
}

$backgroundFiles = file($backgroundHistoryFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [];

$filename = htmlspecialchars($filename, ENT_QUOTES, 'UTF-8');

if ($action === 'set' && !empty($filename)) {
    if ($type !== 'audio') {
        $pingContent = preg_replace('/<!-- BG_START -->.*<!-- BG_END -->/s', '', $pingContent);
    }

    if ($type === 'image') {
        $backgroundStyle = "\n<style>
            body {
                background-image: url('/nekobox/assets/Pictures/$filename');
                background-repeat: no-repeat;
                background-position: center center;
                background-attachment: fixed;
                background-size: cover;
            }
        </style>\n";
    } elseif ($type === 'video') {
        $backgroundStyle = "\n<style>
            body {
                background: transparent;
                position: relative;
                margin: 0;
                padding: 0;
                height: 100vh;
            }

            .video-background {
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                object-fit: contain;
                z-index: -1;
            }

        </style>

        <video class=\"video-background\" autoplay loop id=\"background-video\">
            <source src='/nekobox/assets/Pictures/$filename' type='video/mp4'>
            Your browser does not support the video tag.
        </video>";
    } elseif ($type === 'audio') {
        $audioElement = "
        <audio id=\"background-video\" autoplay loop>
            <source src='/nekobox/assets/Pictures/$filename' type='audio/mp3'>
            Your browser does not support audio playback.
        </audio>";
    }

    if (strpos($pingContent, '<!-- BG_START -->') !== false && strpos($pingContent, '<!-- BG_END -->') !== false) {
        $pingContent = preg_replace('/<!-- BG_START -->.*<!-- BG_END -->/s', "<!-- BG_START -->$backgroundStyle$audioElement<!-- BG_END -->", $pingContent);
    } else {
        $pingContent .= "\n<!-- BG_START -->$backgroundStyle$audioElement<!-- BG_END -->\n";
    }

    file_put_contents($pingFile, $pingContent); 
    file_put_contents($currentBgFile, $filename); 

    $backgroundFiles = array_filter(array_map('trim', file($backgroundHistoryFile)));

    if (($key = array_search($filename, $backgroundFiles)) !== false) {
        unset($backgroundFiles[$key]);
    }

    array_unshift($backgroundFiles, $filename);

    $backgroundFiles = array_slice($backgroundFiles, 0, 20);

    file_put_contents($backgroundHistoryFile, implode("\n", $backgroundFiles));

    echo "Background has been successfully set!";
} elseif ($action === 'remove') {
    $pingContent = preg_replace('/<!-- BG_START -->.*<!-- BG_END -->/s', '', $pingContent);
    file_put_contents($pingFile, $pingContent); 
    file_put_contents($currentBgFile, '');  

    echo "Background has been successfully removed!";
}
?>