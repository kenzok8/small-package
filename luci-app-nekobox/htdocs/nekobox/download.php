<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $dfOutput = [];
    exec('df /', $dfOutput);

    $availableSpace = 0;
    if (isset($dfOutput[1])) {
        $dfData = preg_split('/\s+/', $dfOutput[1]);
        $availableSpace = $dfData[3] * 1024;
    }

    $availableSpaceInMB = $availableSpace / 1024 / 1024;

    $threshold = 50 * 1024 * 1024;

    echo "<script>alert('OpenWRT 剩余空间: " . round($availableSpaceInMB, 2) . " MB');</script>";

    if ($availableSpace < $threshold) {
        echo "<script>alert('空间不足，上传操作已停止！');</script>";
        exit;
    }

    if (isset($_FILES['imageFile']) && is_array($_FILES['imageFile']['error'])) {
        $targetDir = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/assets/Pictures/';

        if (!file_exists($targetDir)) {
            mkdir($targetDir, 0777, true);
        }

        $maxFileSize = 1024 * 1024 * 1024; 

        $uploadedFiles = [];
        $fileErrors = [];

        function cleanFilename($filename) {
            $filename = preg_replace('/[^a-zA-Z0-9\-_\.]/', '', $filename); 
            return $filename; 
        }

        foreach ($_FILES['imageFile']['name'] as $key => $fileName) {
            $fileTmpName = $_FILES['imageFile']['tmp_name'][$key];
            $fileSize = $_FILES['imageFile']['size'][$key];
            $fileError = $_FILES['imageFile']['error'][$key];
            $fileType = $_FILES['imageFile']['type'][$key];

            $cleanFileName = cleanFilename($fileName);

            if ($fileError === UPLOAD_ERR_OK) {
                if ($fileSize > $maxFileSize) {
                    $fileErrors[] = "文件 '$fileName' 大小超出限制！";
                    continue;
                }

                $uniqueFileName = uniqid() . '-' . basename($cleanFileName);
                $targetFile = $targetDir . $uniqueFileName;
                $uploadedFilePath = '/nekobox/assets/Pictures/' . $uniqueFileName;

                if (move_uploaded_file($fileTmpName, $targetFile)) {
                    $uploadedFiles[] = $uploadedFilePath;
                } else {
                    $fileErrors[] = "文件 '$fileName' 上传失败！";
                }
            } else {
                $fileErrors[] = "文件 '$fileName' 上传出错，错误代码: $fileError";
            }
        }

        if (count($uploadedFiles) > 0) {
            echo "<script>
                    alert('文件上传成功！');
                    window.location.href = 'settings.php'; 
                  </script>";
        } else {
            if (count($fileErrors) > 0) {
                foreach ($fileErrors as $error) {
                    echo "<script>alert('$error');</script>";
                }
            } else {
                echo "<script>alert('没有文件上传或上传出错！');</script>";
            }
        }
    } else {
        echo "<script>alert('没有文件上传或上传出错！');</script>";
    }
} else {
    echo "<script>alert('没有接收到数据。');</script>";
}
?>

<?php
$proxyDir = '/www/nekobox/proxy/'; 
$uploadDir = '/etc/neko/proxy_provider/';
$configDir = '/etc/neko/config/';

if (isset($_GET['file'])) {
    $file = basename($_GET['file']);
    
    $filePath = $proxyDir . $file;
    if (file_exists($filePath)) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . $file . '"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($filePath));
        readfile($filePath);
        exit;
    }
    
    $filePath = $uploadDir . $file;
    if (file_exists($filePath)) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . $file . '"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($filePath));
        readfile($filePath);
        exit;
    }

    $configPath = $configDir . $file;
    if (file_exists($configPath)) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . $file . '"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($configPath));
        readfile($configPath);
        exit;
    }

    echo '文件不存在！';
}
