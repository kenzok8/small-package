<?php
if (isset($_POST['enableSnowEffect'])) {
    $enableSnowEffect = $_POST['enableSnowEffect'] == '1' ? true : false;

    $pingFile = 'ping.php'; 

    $fileContent = file_get_contents($pingFile);

    if ($enableSnowEffect) {
        if (strpos($fileContent, '<div id="snow-container"></div>') === false) {
            $fileContent .= '<div id="snow-container"></div>';
            file_put_contents($pingFile, $fileContent);
        }
    } else {
        if (strpos($fileContent, '<div id="snow-container"></div>') !== false) {
            $fileContent = str_replace('<div id="snow-container"></div>', '', $fileContent);
            file_put_contents($pingFile, $fileContent);
        }
    }
}
?>
