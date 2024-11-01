<?php
ini_set('memory_limit', '256M');
ob_start();
include './cfg.php';
$root_dir = "/";
$current_dir = isset($_GET['dir']) ? $_GET['dir'] : '';
$current_dir = '/' . trim($current_dir, '/') . '/';
if ($current_dir == '//') $current_dir = '/';
$current_path = $root_dir . ltrim($current_dir, '/');

if (strpos(realpath($current_path), realpath($root_dir)) !== 0) {
    $current_dir = '/';
    $current_path = $root_dir;
}

if (isset($_GET['preview']) && isset($_GET['path'])) {
    $preview_path = realpath($root_dir . '/' . $_GET['path']);
    if ($preview_path && strpos($preview_path, realpath($root_dir)) === 0) {
        $mime_type = mime_content_type($preview_path);
        header('Content-Type: ' . $mime_type);
        readfile($preview_path);
        exit;
    }
    header('HTTP/1.0 404 Not Found');
    exit;
}

if (isset($_GET['action']) && $_GET['action'] === 'refresh') {
    $contents = getDirectoryContents($current_path);
    echo json_encode($contents);
    exit;
}

if (isset($_GET['action']) && $_GET['action'] === 'get_content' && isset($_GET['path'])) {
    $file_path = $current_path . $_GET['path'];
    if (file_exists($file_path) && is_readable($file_path)) {
        $content = file_get_contents($file_path);
        header('Content-Type: text/plain; charset=utf-8');
        echo $content;
        exit;
    } else {
        http_response_code(404);
        echo '文件不存在或不可读。';
        exit;
    }
}

if (isset($_GET['download'])) {
    downloadFile($current_path . $_GET['download']);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'rename':
                $new_name = basename($_POST['new_path']);
                $old_path = $current_path . $_POST['old_path'];
                $new_path = dirname($old_path) . '/' . $new_name;
                renameItem($old_path, $new_path);
                break;
            case 'edit':
                $content = $_POST['content'];
                $encoding = $_POST['encoding'];
                $result = editFile($current_path . $_POST['path'], $content, $encoding);
                if (!$result) {
                    echo "<script>alert('错误: 无法保存文件。');</script>";
                }
                break;
            case 'delete':
                deleteItem($current_path . $_POST['path']);
                break;
            case 'chmod':
                chmodItem($current_path . $_POST['path'], $_POST['permissions']);
                break;
            case 'create_folder':
                $new_folder_name = $_POST['new_folder_name'];
                $new_folder_path = $current_path . '/' . $new_folder_name;
                if (!file_exists($new_folder_path)) {
                    mkdir($new_folder_path);
                }
                break;
            case 'create_file':
                $new_file_name = $_POST['new_file_name'];
                $new_file_path = $current_path . '/' . $new_file_name;
                if (!file_exists($new_file_path)) {
                    file_put_contents($new_file_path, '');
                }
                break;
            case 'delete_selected':
                if (isset($_POST['selected_paths']) && is_array($_POST['selected_paths'])) {
                    foreach ($_POST['selected_paths'] as $path) {
                        deleteItem($current_path . $path);
                    }
                }
                break;
        }
    } elseif (isset($_FILES['upload'])) {
        uploadFile($current_path);
    }
}

function deleteItem($path) {
    $path = rtrim(str_replace('//', '/', $path), '/');
    
    if (!file_exists($path)) {
        error_log("Attempted to delete non-existent item: $path");
        return false; 
    }

    if (is_dir($path)) {
        return deleteDirectory($path);
    } else {
        if (@unlink($path)) {
            return true;
        } else {
            error_log("Failed to delete file: $path");
            return false;
        }
    }
}

function deleteDirectory($dir) {
    if (!is_dir($dir)) {
        return false;
    }
    $files = array_diff(scandir($dir), array('.', '..'));
    foreach ($files as $file) {
        $path = $dir . '/' . $file;
        is_dir($path) ? deleteDirectory($path) : @unlink($path);
    }
    return @rmdir($dir);
}

function readFileWithEncoding($path) {
    $content = file_get_contents($path);
    $encoding = mb_detect_encoding($content, ['UTF-8', 'ASCII', 'ISO-8859-1', 'Windows-1252', 'GBK', 'Big5', 'Shift_JIS', 'EUC-KR'], true);
    return json_encode([
        'content' => mb_convert_encoding($content, 'UTF-8', $encoding),
        'encoding' => $encoding
    ]);
}

function renameItem($old_path, $new_path) {
    $old_path = rtrim(str_replace('//', '/', $old_path), '/');
    $new_path = rtrim(str_replace('//', '/', $new_path), '/');

    $new_name = basename($new_path);
    $dir = dirname($old_path);
    $new_full_path = $dir . '/' . $new_name;
    
    if (!file_exists($old_path)) {
        error_log("Source file does not exist before rename: $old_path");
        if (file_exists($new_full_path)) {
            error_log("But new file already exists: $new_full_path. Rename might have succeeded.");
            return true;
        }
        return false;
    }
    
    $result = rename($old_path, $new_full_path);
    
    if (!$result) {
        error_log("Rename function returned false for: $old_path to $new_full_path");
        if (file_exists($new_full_path) && !file_exists($old_path)) {
            error_log("However, new file exists and old file doesn't. Consider rename successful.");
            return true;
        }
    }
    
    if (file_exists($new_full_path)) {
        error_log("New file exists after rename: $new_full_path");
    } else {
        error_log("New file does not exist after rename attempt: $new_full_path");
    }
    
    if (file_exists($old_path)) {
        error_log("Old file still exists after rename attempt: $old_path");
    } else {
        error_log("Old file no longer exists after rename attempt: $old_path");
    }
    
    return $result;
}

function editFile($path, $content, $encoding) {
    if (file_exists($path) && is_writable($path)) {
        return file_put_contents($path, $content) !== false;
    }
    return false;
}

function chmodItem($path, $permissions) {
    chmod($path, octdec($permissions));
}

function uploadFile($destination) {
    $uploaded_files = [];
    $errors = [];
    foreach ($_FILES["upload"]["error"] as $key => $error) {
        if ($error == UPLOAD_ERR_OK) {
            $tmp_name = $_FILES["upload"]["tmp_name"][$key];
            $name = basename($_FILES["upload"]["name"][$key]);
            $target_file = rtrim($destination, '/') . '/' . $name;
            
            if (move_uploaded_file($tmp_name, $target_file)) {
                $uploaded_files[] = $name;
            } else {
                $errors[] = "上传 $name 失败";
            }
        } else {
            $errors[] = "文件 $key 上传错误: " . $error;
        }
    }
    
    $result = [];
    if (!empty($errors)) {
        $result['error'] = implode("\n", $errors);
    }
    if (!empty($uploaded_files)) {
        $result['success'] = implode(", ", $uploaded_files);
    }
    
    return $result;
}

if (!function_exists('deleteDirectory')) {
    function deleteDirectory($dir) {
        if (!file_exists($dir)) return true;
        if (!is_dir($dir)) return unlink($dir);
        foreach (scandir($dir) as $item) {
            if ($item == '.' || $item == '..') continue;
            if (!deleteDirectory($dir . DIRECTORY_SEPARATOR . $item)) return false;
        }
        return rmdir($dir);
    }
}

function downloadFile($file) {
    if (file_exists($file)) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="'.basename($file).'"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($file));
        readfile($file);
        exit;
    }
}

function getDirectoryContents($dir) {
    $contents = array();
    foreach (scandir($dir) as $item) {
        if ($item != "." && $item != "..") {
            $path = $dir . DIRECTORY_SEPARATOR . $item;
            $perms = '----';
            $size = '-';
            $mtime = '-';
            $owner = '-';
            if (file_exists($path) && is_readable($path)) {
                $perms = substr(sprintf('%o', fileperms($path)), -4);
                if (!is_dir($path)) {
                    $size = formatSize(filesize($path));
                }
                $mtime = date("Y-m-d H:i:s", filemtime($path) + 8 * 60 * 60);
                $owner = function_exists('posix_getpwuid') ? posix_getpwuid(fileowner($path))['name'] : fileowner($path);
            }
            $contents[] = array(
                'name' => $item,
                'path' => str_replace($dir, '', $path),
                'is_dir' => is_dir($path),
                'permissions' => $perms,
                'size' => $size,
                'mtime' => $mtime,
                'owner' => $owner,
                'extension' => pathinfo($path, PATHINFO_EXTENSION)
            );
        }
    }
    return $contents;
}

function formatSize($bytes) {
    $units = array('B', 'KB', 'MB', 'GB', 'TB');
    $bytes = max($bytes, 0);
    $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
    $pow = min($pow, count($units) - 1);
    $bytes /= (1 << (10 * $pow));
    return round($bytes, 2) . ' ' . $units[$pow];
}

$contents = getDirectoryContents($current_path);

$breadcrumbs = array();
$path_parts = explode('/', trim($current_dir, '/'));
$cumulative_path = '';
foreach ($path_parts as $part) {
    $cumulative_path .= $part . '/';
    $breadcrumbs[] = array('name' => $part, 'path' => $cumulative_path);
}

if (isset($_GET['action']) && $_GET['action'] === 'search' && isset($_GET['term'])) {
    $searchTerm = $_GET['term'];
    $searchResults = searchFiles($current_path, $searchTerm);
    echo json_encode($searchResults);
    exit;
}

function searchFiles($dir, $term) {
    $results = array();
    $files = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($dir),
        RecursiveIteratorIterator::SELF_FIRST
    );

    $webRoot = $_SERVER['DOCUMENT_ROOT'];
    $tmpDir = sys_get_temp_dir();

    foreach ($files as $file) {
        if ($file->isDir()) continue;
        if (stripos($file->getFilename(), $term) !== false) {
            $fullPath = $file->getPathname();
            if (strpos($fullPath, $webRoot) === 0) {
                $relativePath = substr($fullPath, strlen($webRoot));
            } elseif (strpos($fullPath, $tmpDir) === 0) {
                $relativePath = 'tmp' . substr($fullPath, strlen($tmpDir));
            } else {
                $relativePath = $fullPath;
            }
            $relativePath = ltrim($relativePath, '/');
            $results[] = array(
                'path' => $relativePath,
                'dir' => dirname($relativePath),
                'name' => $file->getFilename()
            );
        }
    }

    return $results;
}

?>

<!DOCTYPE html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme, 0, -4) ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NeKobox文件助手</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script src="./assets/js/feather.min.js"></script>
    <script src="./assets/js/jquery-2.1.3.min.js"></script>
    <script src="./assets/js/neko.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/ace.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/mode-json.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/mode-yaml.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.0.0/dist/js/bootstrap.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/js-beautify/1.14.0/beautify.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/js-beautify/1.14.0/beautify-css.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/js-beautify/1.14.0/beautify-html.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/js-beautify/1.14.0/beautify.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/js-yaml/4.1.0/js-yaml.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/ext-language_tools.js"></script>

    <style>
        .folder-icon::before{content:"📁";}.file-icon::before{content:"📄";}.file-icon.file-pdf::before{content:"📕";}.file-icon.file-doc::before,.file-icon.file-docx::before{content:"📘";}.file-icon.file-xls::before,.file-icon.file-xlsx::before{content:"📗";}.file-icon.file-ppt::before,.file-icon.file-pptx::before{content:"📙";}.file-icon.file-zip::before,.file-icon.file-rar::before,.file-icon.file-7z::before{content:"🗜️";}.file-icon.file-mp3::before,.file-icon.file-wav::before,.file-icon.file-ogg::before,.file-icon.file-flac::before{content:"🎵";}.file-icon.file-mp4::before,.file-icon.file-avi::before,.file-icon.file-mov::before,.file-icon.file-wmv::before,.file-icon.file-flv::before{content:"🎞️";}.file-icon.file-jpg::before,.file-icon.file-jpeg::before,.file-icon.file-png::before,.file-icon.file-gif::before,.file-icon.file-bmp::before,.file-icon.file-tiff::before{content:"🖼️";}.file-icon.file-txt::before{content:"📝";}.file-icon.file-rtf::before{content:"📄";}.file-icon.file-md::before,.file-icon.file-markdown::before{content:"📑";}.file-icon.file-exe::before,.file-icon.file-msi::before{content:"⚙️";}.file-icon.file-bat::before,.file-icon.file-sh::before,.file-icon.file-command::before{content:"📜";}.file-icon.file-iso::before,.file-icon.file-img::before{content:"💿";}.file-icon.file-sql::before,.file-icon.file-db::before,.file-icon.file-dbf::before{content:"🗃️";}.file-icon.file-font::before,.file-icon.file-ttf::before,.file-icon.file-otf::before,.file-icon.file-woff::before,.file-icon.file-woff2::before{content:"🔤";}.file-icon.file-cfg::before,.file-icon.file-conf::before,.file-icon.file-ini::before{content:"🔧";}.file-icon.file-psd::before,.file-icon.file-ai::before,.file-icon.file-eps::before,.file-icon.file-svg::before{content:"🎨";}.file-icon.file-dll::before,.file-icon.file-so::before{content:"🧩";}.file-icon.file-css::before{content:"🎨";}.file-icon.file-js::before{content:"🟨";}.file-icon.file-php::before{content:"🐘";}.file-icon.file-json::before{content:"📊";}.file-icon.file-html::before,.file-icon.file-htm::before{content:"🌐";}.file-icon.file-bin::before{content:"👾";}
        #previewModal .modal-content { width: 90%; max-width: 1200px; height: 90vh; overflow: auto; }
        #previewContainer { text-align: center; padding: 20px; }
        #previewContainer img { max-width: 100%; max-height: 70vh; object-fit: contain; }
        #previewContainer audio, #previewContainer video { max-width: 100%; }
        #previewContainer svg { max-width: 100%; max-height: 70vh; }
        .theme-toggle {
              position: absolute;
              top: 20px;
              right: 20px;
          }
          
        #themeToggle {
              background: none;
              border: none;
              cursor: pointer;
              transition: color 0.3s ease;
          }
              
        body.dark-mode {
              background-color: #333;
              color: #fff;
          }
              body.dark-mode table,
              body.dark-mode th,
              body.dark-mode td,
              body.dark-mode .modal,
              body.dark-mode .modal-content,
              body.dark-mode .modal h2,
              body.dark-mode .modal label,
              body.dark-mode .modal input[type="text"] {
              color: #fff;
          }
          
        .header {
              display: flex;
              justify-content: space-between;
              align-items: center;
              margin-bottom: 20px;
          }

        .header img {
              height: 100px;
          }
          
        body.dark-mode th {
              background-color: #444;
          }
          
        body.dark-mode td {
              background-color: #555;
          }
        body.dark-mode .modal-content {
              background-color: #444;
          }

        body.dark-mode #editModal .btn {
              color: #ffffff;
              background-color: #555;
              border-color: #555;
          }

        body.dark-mode #editModal .btn:hover {
              background-color: #666;
              border-color: #666;
          }

        .table tbody tr:nth-child(odd) {
              background-color: #444;
          }
          
        .table tbody tr:nth-child(even) {
              background-color: #333;
          }

        .table tbody tr:hover {
              background-color: #555;
          }

        .btn:hover {
              background-color: #555;
              transition: background-color 0.3s ease;
          }

        .table {
              color: #ddd;
          }

        body.dark-mode .container-sm.callout .row a.btn.custom-btn-color {
              color: white !important;
          }

        body.dark-mode .container-sm.callout .row a.btn.custom-btn-color * {
              color: white !important;
          }

        body.dark-mode .container-sm.callout .row a.btn.custom-btn-color {
              filter: invert(1) hue-rotate(180deg);
          }
        body.dark-mode .container-sm.callout .row a.btn.custom-btn-color i {
              color: white !important;
          }

        body.dark-mode .container-sm.callout .row a.btn.custom-btn-color span {
              color: white !important;
          }

        body.dark-mode .navbar .fas,
        body.dark-mode .navbar .far,
        body.dark-mode .navbar .fab {
              color: white; 
          }

        body.dark-mode .btn-outline-secondary {
              color: white;
              border-color: white;
          }

        body.dark-mode .btn-outline-secondary:hover {
              background-color: white;
              color: #333;
          }

        body.dark-mode .form-select {
              background-color: #444;
              color: white;
              border-color: #666;
          }

        body.dark-mode table {
              color: white;
          }

        body.dark-mode th {
              background-color: #444;
          }

        body.dark-mode td {
              background-color: #333;
          }

        .modal {
              display: none;
              position: fixed;
              z-index: 1000;
              left: 0;
              top: 0;
              width: 100%;
              height: 100%;
              overflow: auto;
              background-color: rgba(0,0,0,0.4);
          }
          
        .modal-content {
              background-color: #fefefe;
              margin: 15% auto;
              padding: 20px;
              border: 1px solid #888;
              width: 80%;
              max-width: 500px;
              border-radius: 10px;
              box-shadow: 0 4px 8px rgba(0,0,0,0.1);
          }
          
        .close {
              color: #aaa;
              float: right;
              font-size: 28px;
              font-weight: bold;
              cursor: pointer;
              transition: 0.3s;
          }
          
        .close:hover,
        .close:focus {
              color: #000;
              text-decoration: none;
              cursor: pointer;
          }
          
        .modal h2 {
              margin-top: 0;
              color: #333;
          }
          
        .modal form {
              margin-top: 20px;
          }
          
        .modal label {
              display: block;
              margin-bottom: 5px;
              color: #666;
          }
          
        .modal input[type="text"] {
              width: 100%;
              padding: 8px;
              margin-bottom: 20px;
              border: 1px solid #ddd;
              border-radius: 4px;
          }
          
        .btn {
              padding: 10px 20px;
              border: none;
              border-radius: 4px;
              cursor: pointer;
              font-size: 16px;
              transition: background-color 0.3s;
          }
          
        .btn-primary {
              background-color: #007bff;
              color: white;
          }
          
        .btn-primary:hover {
              background-color: #0056b3;
          }
          
        .btn-secondary {
              background-color: #6c757d;
              color: white;
          }
          
        .btn-secondary:hover {
              background-color: #545b62;
          }
          
        .mb-2 {
              margin-bottom: 10px;
          }
          
        .btn-group {
              display: flex;
              justify-content: space-between;
          }
          
        #editModal {
              display: none;
              position: fixed;
              z-index: 1000;
              left: 0;
              top: 0;
              width: 100%;
              height: 100%;
              overflow: auto;
              background-color: rgba(0, 0, 0, 0.5);
          }
          
        .modal-content {
              background-color: #fefefe;
              margin: 15% auto;
              padding: 20px;
              position: relative;
              border: 1px solid #888;
              width: 80%;
              max-width: 1000px;
              border-radius: 8px;
              box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
          }
          
        textarea {
              width: 100%;
              height: 500px;
              padding: 10px;
              border: 1px solid #ccc;
              border-radius: 4px;
              resize: vertical;
              font-family: monospace;
          }
          
        .close {
              color: #aaa;
              position: absolute;
              right: 20px;
              top: 15px;
              font-size: 28px;
              font-weight: bold;
              cursor: pointer;
          }
          
        .close:hover,
        .close:focus {
              color: black;
              text-decoration: none;
          }
          
        body {
              overflow-x: hidden;
          }
          
        #searchModal {
              z-index: 1060 !important;
          }
          
        .modal-backdrop {
              z-index: 1050 !important;
          } 
          
        .modal-content {
              background-color: var(--bs-body-bg);
              color: var(--bs-body-color);
          }
          
        #searchModal .modal-dialog {
              max-width: 90% !important;
              width: 800px !important;
          }
          
        #searchResults {
              max-height: 400px;
              overflow-y: auto;
          }
          
        #searchResults .list-group-item {
              display: flex;
              justify-content: space-between;
              align-items: center;
          }
          
        #searchResults .list-group-item span {
              word-break: break-all;
              margin-right: 10px;
          }
          
        #aceEditor {
              position: fixed;
              top: 0;
              right: 0;
              bottom: 0;
              left: 0;
              z-index: 1000;
              display: none;
              color: #333;
          }
          
        #aceEditorContainer {
              position: absolute;
              top: 40px;
              right: 0;
              bottom: 40px;
              left: 0;
              overflow-x: auto;
          }
          
        #editorStatusBar {
              position: absolute;
              left: 0;
              right: 0;
              bottom: 0;
              height: 40px;
              background-color: #000;
              color: #fff;
              display: flex;
              justify-content: space-between;
              align-items: center;
              padding: 0 20px;
              font-size: 16px;
              z-index: 1001;
              white-space: nowrap;
              overflow: hidden;
              text-overflow: ellipsis;
          }
          
        #editorControls {
              position: absolute;
              left: 0;
              right: 0;
              top: 0;
              height: 40px;
              background-color: #000;
              color: #fff;
              display: flex;
              justify-content: center;
              align-items: center;
              padding: 0 10px;
              overflow-x: auto;
        }
          
          #editorControls select,
          #editorControls button {
              margin: 0 10px;
              height: 30px;
              padding: 5px 10px;
              font-size: 12px;
              background-color: #000;
              color: #fff;
              border: none;
              display: flex;
              justify-content: center;
              align-items: center;
          }
          
        body.editing {
              overflow: hidden;
          }

        #aceEditor {
              position: fixed;
              top: 0;
              left: 0;
              right: 0;
              bottom: 0;
              z-index: 1000;
          }

        #aceEditorContainer {
              position: absolute;
              top: 40px; 
              left: 0;
              right: 0;
              bottom: 40px; 
              overflow: auto;
          }

        #editorControls {
              position: fixed;
              top: 0;
              left: 0;
              right: 0;
              height: 40px;
              z-index: 1001;
          }

        #editorStatusBar {
              position: fixed;
              bottom: 0;
              left: 0;
              right: 0;
              height: 40px;
              z-index: 1001;
          }
          
        .ace_search {
              background-color: #f8f9fa;
              border: 1px solid #ced4da;
              border-radius: 4px;
              padding: 10px;
              box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          
        .ace_search_form,
        .ace_replace_form {
              display: flex;
              align-items: center;
              margin-bottom: 5px;
          }
          
        .ace_search_field {
              flex-grow: 1;
              border: 1px solid #ced4da;
              border-radius: 4px;
              padding: 4px;
          }
          
        .ace_searchbtn,
        .ace_replacebtn {
              background-color: #007bff;
              color: white;
              border: none;
              border-radius: 4px;
              padding: 4px 8px;
              margin-left: 5px;
              cursor: pointer;
          }
          
        .ace_searchbtn:hover,
        .ace_replacebtn:hover {
              background-color: #0056b3;
          }
          
        .ace_search_options {
              margin-top: 5px;
          }
          
        .ace_button {
              background-color: #6c757d;
              color: white;
              border: none;
              border-radius: 4px;
              padding: 4px 8px;
              margin-right: 5px;
              cursor: pointer;
          }
          
        .ace_button:hover {
              background-color: #5a6268;
          }
          
        body.dark-mode #editorStatusBar {
              background-color: #2d3238;
              color: #e0e0e0;
          }
          
        body.dark-mode .ace_search {
              background-color: #2d3238;
              border-color: #495057;
          }
          
        body.dark-mode .ace_search_field {
              background-color: #343a40;
              color: #f8f9fa;
              border-color: #495057;
          }
          
        body.dark-mode .ace_searchbtn,
        body.dark-mode .ace_replacebtn {
              background-color: #0056b3;
          }
          
        body.dark-mode .ace_searchbtn:hover,
        body.dark-mode .ace_replacebtn:hover {
              background-color: #004494;
          }
          
        body.dark-mode .ace_button {
              background-color: #495057;
          }
          
        body.dark-mode .ace_button:hover {
              background-color: #3d4349;
          }

        #aceEditor .btn:hover {
              background-color: #4682b4;
              transform: translateY(-2px);
              box-shadow: 0 4px 12px rgba(0,0,0,0.15);
          }
          
        #aceEditor .btn:focus {
              outline: none;
          }
          
        #editorStatusBar {
              position: absolute;
              left: 0;
              right: 0;
              bottom: 0;
              height: 40px;
              background-color: #000;
              color: #fff;
              display: flex;
              justify-content: space-between;
              align-items: center;
              padding: 0 20px;
              font-size: 16px;
          }
          
        #cursorPosition {
              margin-right: 20px;
          }

        #characterCount {
              margin-left: auto;
          }
          
        ::-webkit-scrollbar {
              width: 12px;
              height: 12px;
          }
          
        ::-webkit-scrollbar-track {
              background-color: #f1f1f1;
          }
          
        ::-webkit-scrollbar-thumb {
              background-color: #888;
              border-radius: 6px;
          }
          
        ::-webkit-scrollbar-thumb:hover {
              background-color: #555;
          }

        .upload-container {
              margin-bottom: 20px;
          }

        .upload-area {
              margin-top: 10px;
          }

        .upload-drop-zone {
              border: 2px dashed #ccc;
              border-radius: 8px;
              padding: 25px;
              text-align: center;
              background: #f8f9fa;
              transition: all 0.3s ease;
              cursor: pointer;
              min-height: 150px;
              display: flex;
              align-items: center;
              justify-content: center;
                        
          }

        .upload-drop-zone.drag-over {
              background: #e9ecef;
              border-color: #0d6efd;
          }

        .upload-icon {
              font-size: 50px;
              color: #6c757d;
              transition: all 0.3s ease;
          }

        .upload-drop-zone:hover .upload-icon {
              color: #0d6efd;
              transform: scale(1.1);
          }

          td {
              vertical-align: middle;
          }

        .btn-outline-primary:hover i,
        .btn-outline-info:hover i,
        .btn-outline-warning:hover i,
        .btn-outline-danger:hover i {
              color: #fff; 
         }

        .table tbody tr {
              transition: all 0.2s ease;
              position: relative;
              cursor: pointer;
          }

        .table tbody tr:hover {
              transform: translateY(-2px);
              box-shadow: 0 3px 10px rgba(0,0,0,0.1);
              z-index: 2;
              background-color: rgba(0, 123, 255, 0.05);
          }

        .table tbody tr:hover td {
              color: #007bff;
          }

        body.dark-mode .table tbody tr:hover {
              background-color: rgba(0, 123, 255, 0.1);
          }

        body.dark-mode .table tbody tr:hover td {
              color: #4da3ff;
          }

        .close {
              position: absolute;
              right: 15px;
              top: 15px;
              width: 32px;
              height: 32px;
              opacity: 0.7;
              cursor: pointer;
              transition: all 0.3s ease;
              border: 2px solid rgba(0, 0, 0, 0.3);
              border-radius: 50%;
              display: flex;
              align-items: center;
              justify-content: center;
              font-size: 20px;
              color: #333;
              text-decoration: none;
        }

        .close:hover {
              opacity: 1;
              transform: rotate(90deg);
              border-color: rgba(0, 0, 0, 0.5);
              color: #007bff;
        }

        body.dark-mode .close {
              border-color: rgba(255, 255, 255, 0.3);
              color: #fff;
        }

        body.dark-mode .close:hover {
              border-color: rgba(255, 255, 255, 0.5);
              color: #4da3ff;
        }

        #searchModal .modal-dialog.modal-lg {
              max-width: 90% !important;
              width: 1200px !important;
        }

        .container-sm.callout .row a.btn.custom-btn-color {
              color: #000000; 
              background-color: transparent; 
              border-color: #ced4da;
              margin: 5px;
              transition: all 0.3s ease;
        }

        .container-sm.callout .row a.btn.custom-btn-color:hover {
              color: #007bff;
              background-color: rgba(0, 123, 255, 0.1); 
        }

        body.dark-mode .container-sm.callout .row a.btn.custom-btn-color {
              color: #ffffff; 
              background-color: #495057;
              border-color: #6c757d;
        }

        body.dark-mode .container-sm.callout .row a.btn.custom-btn-color:hover {
              color: #ffffff;
              background-color: #007bff;
              border-color: #007bff;
        }

        body.dark-mode .container-sm.callout .row a.btn.custom-btn-color i,
              body.dark-mode .container-sm.callout .row a.btn.custom-btn-color span {
              color: #ffffff; 
        }
        
        .custom-btn-color, .custom-btn-color i {
              color: #000000;
              background-color: transparent;
              border-color: #ced4da;
              margin: 5px;
              transition: all 0.3s ease;
        }

        .custom-btn-color:hover, .custom-btn-color:hover i {
              color: #007bff;
              background-color: rgba(0, 123, 255, 0.1);
        }

        body.dark-mode .custom-btn-color, 
        body.dark-mode .custom-btn-color i {
              color: #ffffff;
              background-color: #495057;
              border-color: #6c757d;
        }

        body.dark-mode .custom-btn-color:hover, 
        body.dark-mode .custom-btn-color:hover i {
              color: #ffffff;
              background-color: #007bff;
              border-color: #007bff;
        }
        .container-sm {
              padding-top: 10px;    
              padding-bottom: 10px; 
              margin-bottom: 15px;
        }

       .container-sm.container-bg .row .btn:hover {
              transform: scale(1.05);
              background-color: transparent !important;
        }

       body #themeToggle:hover {
              background-color: black !important;
              color: white !important;
        }

        body.dark-mode #themeToggle:hover {
              background-color: white !important;
              color: black !important;
        }

        @media (max-width: 767px) {
              .row a {
              font-size: 9px; 
        }
      }
        .table-responsive {
              width: 100%;
        }

        .btn-outline-info i {
              font-size: 15px; 
        }
     </style>
  </head>
<body>
<div class="container-sm container-bg callout  border border-3 rounded-4 col-11">
    <div class="row">
        <a href="./index.php" class="col btn btn-lg" data-translate="home"><i class="fas fa-home"></i> Home</a>
        <a href="./mihomo_manager.php" class="col btn btn-lg"><i class="fas fa-folder"></i> Mihomo</a>
        <a href="./singbox_manager.php" class="col btn btn-lg"><i class="fas fa-folder-open"></i> Sing-box</a>
        <a href="./box.php" class="col btn btn-lg" data-translate="convert"><i class="fas fa-exchange-alt"></i> Convert</a>
        <a href="./filekit.php" class="col btn btn-lg" data-translate="fileAssistant"><i class="fas fa-file-alt"></i> File Assistant</a>
    </div>
</div>
<div class="row">
    <div class="col-12">  
        <div class="container container-bg border border-3 rounded-4 p-3">
            <div class="row align-items-center mb-3">
                <div class="col-md-3 text-center text-md-start">
                    <img src="./assets/img/nekobox.png" alt="Neko Box" class="img-fluid" style="max-height: 100px;">
                </div>
                <div class="col-md-6 text-center"> 
                    <h1 class="mb-0" id="pageTitle">NeKoBox File Assistant</h1>
                </div>
                <div class="col-md-3">
                </div>
            </div>
            
            <div class="row mb-3">
                <div class="col-12">
                    <div class="btn-toolbar justify-content-between">
                        <div class="btn-group">
                            <button type="button" class="btn btn-outline-secondary" onclick="goToParentDirectory()" title="Go Back" data-translate-title="goToParentDirectoryTitle">
                                <i class="fas fa-arrow-left"></i>
                            </button>
                            <button type="button" class="btn btn-outline-secondary" onclick="location.href='?dir=/'" title="Return to Root Directory"  data-translate-title="rootDirectoryTitle">
                                <i class="fas fa-home"></i> 
                            </button>
                            <button type="button" class="btn btn-outline-secondary" onclick="location.href='?dir=/root'" title="Return to Home Directory"  data-translate-title="homeDirectoryTitle">
                                <i class="fas fa-user"></i>
                            </button>
                            <button type="button" class="btn btn-outline-secondary" onclick="location.reload()" title="Refresh Directory Content"  data-translate-title="refreshDirectoryTitle">
                                <i class="fas fa-sync-alt"></i>
                            </button>
                        </div>
                        
                        <div class="btn-group">
                            <button type="button" class="btn btn-outline-secondary" onclick="selectAll()" id="selectAllBtn" title="Select All"  data-translate-title="selectAll">
                                <i class="fas fa-check-square"></i>
                            </button>
                            <button type="button" class="btn btn-outline-secondary" onclick="reverseSelection()" id="reverseSelectionBtn" title="Invert Selection"  data-translate-title="invertSelection">
                                <i class="fas fa-exchange-alt"></i>
                            </button>
                            <button type="button" class="btn btn-outline-secondary" onclick="deleteSelected()" id="deleteSelectedBtn" title="Delete Selected"  data-translate-title="deleteSelected">
                                <i class="fas fa-trash-alt"></i>
                            </button>
                        </div>
                        
                        <div class="btn-group">
                            <button type="button" class="btn btn-outline-secondary" onclick="showSearchModal()" id="searchBtn" title="Search" data-translate-title="searchTitle">
                                <i class="fas fa-search"></i>
                            </button>
                            <button type="button" class="btn btn-outline-secondary" onclick="showCreateModal()" id="createBtn" title="Create New"  data-translate-title="createTitle">    
                                <i class="fas fa-plus"></i> 
                            </button>
                            <button type="button" class="btn btn-outline-secondary" onclick="showUploadArea()" id="uploadBtn" title="Upload"  data-translate-title="uploadTitle">
                                <i class="fas fa-upload"></i>
                            </button>
                            <button id="themeToggle" class="btn btn-outline-secondary" title="Toggle Theme"  data-translate-title="themeToggleTitle">
                                <i class="fas fa-moon"></i>
                            </button>
                        </div>
                        <div class="btn-group">
                            <select id="languageSwitcher" class="form-select">
                                <option value="en" data-translate="english">English</option>
                                <option value="zh" data-translate="chinese">chinese</option>
                                <option value="zh-tw" data-translate="traditionalChinese">traditionalChinese</option>
                                <option value="vi" data-translate="vietnamese">Tiếng Việt</option> 
                                <option value="ko" data-translate="korean">한국어</option> 
                                <option value="ar" data-translate="arabic">العربية</option>   
                                <option value="ru" data-translate="russian">Русский</option>
                                <option value="de" data-translate="german">Deutsch</option>         
                            </select>
                        </div>
                  </div>
            </div>
     </div>
 <nav aria-label="breadcrumb">
    <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="?dir=">root</a></li>
        <?php
        $path = '';
        $breadcrumbs = explode('/', trim($current_dir, '/'));
        foreach ($breadcrumbs as $crumb) {
            if (!empty($crumb)) {
                $path .= '/' . $crumb;
                echo '<li class="breadcrumb-item"><a href="?dir=' . urlencode($path) . '">' . htmlspecialchars($crumb) . '</a></li>';
            }
        }
        ?>
    </ol>
</nav>

<div class="upload-container">
    <div class="upload-area" id="uploadArea" style="display: none;">
        <p class="upload-instructions">
            <span data-translate="dragHint">请将文件拖拽至此处或点击选择文件上传</span>
        </p>
        <form action="" method="post" enctype="multipart/form-data" id="uploadForm">
            <input type="file" name="upload[]" id="fileInput" style="display: none;" multiple required>
            <div class="upload-drop-zone" id="dropZone">
                <i class="fas fa-cloud-upload-alt upload-icon"></i>
            </div>
        </form>
        <button type="button" class="btn btn-secondary mt-2" onclick="hideUploadArea()" data-translate="cancel">Cancel</button>
    </div>
</div>

<div class="container text-center">
    <table class="table table-striped table-bordered">
        <thead class="thead-dark">
            <tr>
                <th><input type="checkbox" id="selectAllCheckbox"></th>
                <th data-translate="name">Name</th>
                <th data-translate="type">Type</th>
                <th data-translate="size">Size</th>
                <th data-translate="modifiedTime">Modified Time</th>
                <th data-translate="permissions">Permissions</th>
                <th data-translate="owner">Owner</th>
                <th data-translate="actions">Actions</th>
            </tr>
        </thead>
        <tbody>
            <?php if ($current_dir != ''): ?>
                <tr>
                    <td></td>
                    <td class="folder-icon"><a href="?dir=<?php echo urlencode(dirname($current_dir)); ?>">..</a></td>
                    <td data-translate="directory">Directory</td>
                    <td>-</td>
                    <td>-</td>
                    <td>-</td>
                    <td>-</td>
                    <td></td>
                </tr>
            <?php endif; ?>
            <?php foreach ($contents as $item): ?>
                <tr>
                    <td><input type="checkbox" class="file-checkbox" data-path="<?php echo htmlspecialchars($item['path']); ?>"></td>
                    <?php
                    $icon_class = $item['is_dir'] ? 'folder-icon' : 'file-icon';
                    if (!$item['is_dir']) {
                        $ext = strtolower(pathinfo($item['name'], PATHINFO_EXTENSION));
                        $icon_class .= ' file-' . $ext;
                    }
                    ?>
                    <td class="<?php echo $icon_class; ?>">
                        <?php if ($item['is_dir']): ?>
                            <a href="?dir=<?php echo urlencode($current_dir . $item['path']); ?>"><?php echo htmlspecialchars($item['name']); ?></a>
                        <?php else: ?>
                            <?php 
                            $ext = strtolower(pathinfo($item['name'], PATHINFO_EXTENSION));
                            if (in_array($ext, ['jpg', 'jpeg', 'png', 'gif', 'svg', 'mp3', 'mp4'])): 
                                $clean_path = ltrim(str_replace('//', '/', $item['path']), '/');
                            ?>
                                <a href="#" onclick="previewFile('<?php echo htmlspecialchars($clean_path); ?>', '<?php echo $ext; ?>')"><?php echo htmlspecialchars($item['name']); ?></a>
                            <?php else: ?>
                                <a href="#" onclick="showEditModal('<?php echo htmlspecialchars(addslashes($item['path'])); ?>')"><?php echo htmlspecialchars($item['name']); ?></a>
                            <?php endif; ?>
                        <?php endif; ?>
                    </td>
                    <td data-translate="<?php echo $item['is_dir'] ? 'directory' : 'file'; ?>"><?php echo $item['is_dir'] ? 'Directory' : 'File'; ?></td>
                    <td><?php echo $item['size']; ?></td>
                    <td><?php echo $item['mtime']; ?></td>
                    <td><?php echo $item['permissions']; ?></td>
                    <td><?php echo htmlspecialchars($item['owner']); ?></td>
                    <td>
                        <div style="display: flex; gap: 5px;">
                            <button onclick="showRenameModal('<?php echo htmlspecialchars($item['name']); ?>', '<?php echo htmlspecialchars($item['path']); ?>')" class="btn btn-outline-primary btn-sm" title="✏️ Rename" data-translate-title="rename">
                                <i class="fas fa-edit"></i>
                            </button>
                            <?php if (!$item['is_dir']): ?>
                                <a href="?dir=<?php echo urlencode($current_dir); ?>&download=<?php echo urlencode($item['path']); ?>" class="btn btn-outline-info btn-sm" title="⬇️ Download" data-translate-title="download">
                                    <i class="fas fa-download"></i>
                                </a>
                            <?php endif; ?>
                            <button onclick="showChmodModal('<?php echo htmlspecialchars($item['path']); ?>', '<?php echo $item['permissions']; ?>')" class="btn btn-outline-warning btn-sm" title="🔒 Set Permissions" data-translate-title="setPermissions">
                                <i class="fas fa-lock"></i>
                            </button>
                            <form method="post" style="display:inline;" onsubmit="return confirmDelete('<?php echo htmlspecialchars($item['name']); ?>');">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="path" value="<?php echo htmlspecialchars($item['path']); ?>">
                                <button type="submit" class="btn btn-outline-danger btn-sm" title="🗑️ Delete" data-translate-title="delete">
                                    <i class="fas fa-trash-alt"></i>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>

<div id="renameModal" class="modal">
        <div class="modal-content">
            <span class="close" onclick="closeModal('renameModal')">&times;</span>
                <h2 data-translate="rename">✏️ Rename</h2>
                    <form method="post" onsubmit="return validateRename()">
                        <input type="hidden" name="action" value="rename">
                        <input type="hidden" name="old_path" id="oldPath">
                        <div class="form-group">
                            <label for="newPath" data-translate="newName">New name</label>
                            <input type="text" name="new_path" id="newPath" class="form-control" autocomplete="off" data-translate-placeholder="enterNewName">
                        </div>
                        <div class="btn-group">
                            <button type="button" class="btn btn-secondary" onclick="closeModal('renameModal')" data-translate="cancel">Close</button>
                            <button type="submit" class="btn btn-primary" data-translate="confirmRename">Confirm Rename</button>
                        </div>
                    </form>
                </div>
            </div>

        <div id="createModal" class="modal">
                <div class="modal-content">
                    <span class="close" onclick="closeModal('createModal')">&times;</span>
                    <h2 data-translate="create">Create</h2>
                    <div class="d-grid gap-2">
                    <button onclick="showNewFolderModal()" class="btn btn-primary mb-2" data-translate="newFolder">
                        <i class="fas fa-folder-plus"></i> New Folder
                    </button>
                    <button onclick="showNewFileModal()" class="btn btn-primary" data-translate="newFile">
                        <i class="fas fa-file-plus"></i> New File
                    </button>
                </div>
            </div>
        </div>

        <div id="newFolderModal" class="modal">
                <div class="modal-content">
                    <span class="close" onclick="closeModal('newFolderModal')">&times;</span>
                    <h2 data-translate="newFolder">New Folder</h2>
                    <form method="post" onsubmit="return createNewFolder()">
                        <input type="hidden" name="action" value="create_folder">
                        <div class="form-group mb-3">
                        <label for="newFolderName" class="form-label" data-translate="folderName">Folder name:</label>
                        <input type="text" name="new_folder_name" id="newFolderName" 
                           class="form-control" required 
                           data-translate-placeholder="enterFolderName">
                    </div>
                <div class="text-end mt-3">
                    <button type="button" class="btn btn-secondary me-2" onclick="closeModal('newFolderModal')" data-translate="cancel">Cancel</button>
                    <input type="submit" class="btn btn-primary" data-translate="create" data-translate-value="create">
                </div>
            </form>
         </div>
      </div>
      
        <div id="newFileModal" class="modal">
                <div class="modal-content">
                    <span class="close" onclick="closeModal('newFileModal')">&times;</span>
                    <h2 data-translate="newFile">New File</h2>
                    <form method="post" onsubmit="return createNewFile()">
                        <input type="hidden" name="action" value="create_file">
                        <div class="form-group mb-3">
                        <label for="newFileName" class="form-label" data-translate="fileName">File name:</label>
                        <input type="text" name="new_file_name" id="newFileName" 
                           class="form-control" required 
                           data-translate-placeholder="enterFileName">
                        </div>
                <div class="text-end mt-3">
                    <button type="button" class="btn btn-secondary me-2" onclick="closeModal('newFileModal')" data-translate="cancel">Cancel</button>
                    <input type="submit" class="btn btn-primary" data-translate="create" data-translate-value="create">
                </div>
            </form>
         </div>
      </div>
      
        <div id="searchModal" class="modal" tabindex="-1">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title" data-translate="searchFiles">Search Files</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body">
                            <form id="searchForm">
                                <div class="input-group mb-3">
                                    <input type="text" id="searchInput" class="form-control" data-translate="searchInputPlaceholder" data-translate-placeholder="searchInputPlaceholder" placeholder="Enter file name" required>
                                    <button type="submit" class="btn btn-primary" data-translate="search">Search</button>
                                </div>
                            </form>
                            <div id="searchResults"></div>
                        </div>
                    </div>
                </div>
            </div>

            <div id="editModal" class="modal">
                <div class="modal-content">
                    <span class="close" onclick="closeModal('editModal')">&times;</span>
                    <h2 data-translate="editFile">Edit File</h2>
                    <form method="post" id="editForm" onsubmit="return saveEdit()">
                        <input type="hidden" name="action" value="edit">
                        <input type="hidden" name="path" id="editPath">
                        <input type="hidden" name="encoding" id="editEncoding">
                        <textarea name="content" id="editContent" rows="10" cols="50"></textarea>
                    <div class="mt-3">
                        <input type="submit" class="btn btn-primary" data-translate="save" data-translate-value="save">
                        <button type="button" onclick="openAceEditor()" class="btn btn-secondary" data-translate="advancedEdit">Advanced Edit</button>
                    </div>
               </form>
            </div>
       </div>
            <div id="aceEditor">
                <div id="aceEditorContainer"></div>
                <div id="editorStatusBar">
                    <span id="cursorPosition"><span data-translate="line">Line</span>: <span id="currentLine">1</span>, <span data-translate="column">Column</span>: <span id="currentColumn">1</span></span>
                    <span id="characterCount"><span data-translate="characterCount">Character Count</span>: <span id="charCount">0</span></span>
                </div>
                <div id="editorControls">
                    <select id="fontSize" onchange="changeFontSize()">
                        <option value="18px">18px</option>
                        <option value="20px" selected>20px</option>
                        <option value="22px">22px</option>
                        <option value="24px">24px</option>
                        <option value="26px">26px</option>
                        <option value="28px">28px</option>
                        <option value="30px">30px</option>
                        <option value="32px">32px</option>
                        <option value="34px">34px</option>
                        <option value="36px">36px</option>
                        <option value="38px">38px</option>
                        <option value="40px">40px</option>
                    </select>
                    <select id="editorTheme" onchange="changeEditorTheme()">
                        <option value="ace/theme/vibrant_ink">Vibrant Ink</option>
                        <option value="ace/theme/monokai">Monokai</option>
                        <option value="ace/theme/github">GitHub</option>
                        <option value="ace/theme/tomorrow">Tomorrow</option>
                        <option value="ace/theme/twilight">Twilight</option>
                        <option value="ace/theme/solarized_dark">Solarized Dark</option>
                        <option value="ace/theme/solarized_light">Solarized Light</option>
                        <option value="ace/theme/textmate">TextMate</option>
                        <option value="ace/theme/terminal">Terminal</option>
                        <option value="ace/theme/chrome">Chrome</option>
                        <option value="ace/theme/eclipse">Eclipse</option>
                        <option value="ace/theme/dreamweaver">Dreamweaver</option>
                        <option value="ace/theme/xcode">Xcode</option>
                        <option value="ace/theme/kuroir">Kuroir</option>
                        <option value="ace/theme/katzenmilch">KatzenMilch</option>
                        <option value="ace/theme/sqlserver">SQL Server</option>
                        <option value="ace/theme/ambiance">Ambiance</option>
                        <option value="ace/theme/chaos">Chaos</option>
                        <option value="ace/theme/clouds_midnight">Clouds Midnight</option>
                        <option value="ace/theme/cobalt">Cobalt</option>
                        <option value="ace/theme/gruvbox">Gruvbox</option>
                        <option value="ace/theme/idle_fingers">Idle Fingers</option>
                        <option value="ace/theme/kr_theme">krTheme</option>
                        <option value="ace/theme/merbivore">Merbivore</option>
                        <option value="ace/theme/mono_industrial">Mono Industrial</option>
                        <option value="ace/theme/pastel_on_dark">Pastel on Dark</option>
                    </select>
                    <select id="encoding" onchange="changeEncoding()">
                        <option value="UTF-8">UTF-8</option>
                        <option value="ASCII">ASCII</option>
                        <option value="ISO-8859-1">ISO-8859-1 (Latin-1)</option>
                        <option value="Windows-1252">Windows-1252</option>
                        <option value="GBK" data-translate="gbk">GBK (Simplified Chinese)</option>
                        <option value="Big5" data-translate="big5">Big5 (Traditional Chinese)</option>
                        <option value="Shift_JIS" data-translate="shiftJIS">Shift_JIS (Japanese)</option>
                        <option value="EUC-KR" data-translate="eucKR">EUC-KR (Korean)</option>
                    </select>
                    <button onclick="toggleSearch()" class="btn" data-translate="search" data-translate-title="search_title"><i class="fas fa-search"></i></button>
                    <button onclick="formatCode()" class="btn" data-translate="format">Format</button>
                    <button onclick="formatJSON()" class="btn" id="formatJSONBtn" style="display: none;" data-translate="formatJSON">Format JSON</button>
                    <button onclick="validateJSON()" class="btn" id="validateJSONBtn" style="display: none;" data-translate="validateJSON">Validate JSON</button>
                    <button onclick="validateYAML()" class="btn" id="validateYAMLBtn" style="display: none;" data-translate="validateYAML">Validate YAML</button>
                    <button onclick="saveAceContent()" class="btn" data-translate="save">Save</button>
                    <button onclick="closeAceEditor()" class="btn" data-translate="close">Close</button>
                </div>
            </div>

            <div id="aceEditor">
                <div id="aceEditorContainer"></div>
                <div style="position: absolute; top: 10px; right: 10px;">
                    <button onclick="saveAceContent()" class="btn" data-translate="save">Save</button>
                    <button onclick="closeAceEditor()" class="btn" style="margin-left: 10px;" data-translate="close">Close</button>
                </div>
            </div>
            
            <div id="chmodModal" class="modal">
                 <div class="modal-content">
                     <span class="close" onclick="closeModal('chmodModal')">&times;</span>
                     <h2 data-translate="setPermissions">🔒 Set Permissions</h2>
                     <form method="post" onsubmit="return validateChmod()">
                       <input type="hidden" name="action" value="chmod">
                       <input type="hidden" name="path" id="chmodPath">
                       <div class="form-group mb-3">
                         <label for="permissions" class="form-label" data-translate="permissionValue">
                         Permission value (e.g.: 0644)
                </label>
                <input type="text" 
                       name="permissions" 
                       id="permissions" 
                       class="form-control" 
                       maxlength="4" 
                       data-translate-placeholder="permissionPlaceholder" 
                       placeholder="0644" 
                       autocomplete="off">
                <small class="form-text text-muted mt-2" data-translate="permissionHelp">
                    Please enter a valid permission value (three or four octal digits, e.g.: 644 or 0755)
                </small>
            </div>
            <div class="text-end mt-3">
                <button type="button" 
                        class="btn btn-secondary me-2" 
                        onclick="closeModal('chmodModal')" 
                        data-translate="cancel">Cancel</button>
                <button type="submit" 
                        class="btn btn-primary" 
                        data-translate="confirmChange">Confirm Change</button>
                        </div>
                    </form>
                </div>
            </div>
            <div id="previewModal" class="modal">
                <div class="modal-content">
                    <span class="close" onclick="closeModal('previewModal')">&times;</span>
                    <h2 data-translate="filePreview">File Preview</h2>
                    <div id="previewContainer">
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const saveLanguageBtn = document.getElementById('saveLanguage');
    const pageTitle = document.getElementById('pageTitle');
    const uploadBtn = document.getElementById('uploadBtn');

const translations = {
    zh: {
        pageTitle: "NeKoBox 文件助手",
        chinese: '简体中文',
        traditionalChinese: '繁體中文',
        english: 'English',
        uploadBtn: "上传文件",
        rootDirectory: "根目录",
        name: "名称",
        type: "类型",
        size: "大小",
        permissions: "权限",
        actions: "操作",
        directory: "目录",
        file: "文件",
        rename: "✏️ 重命名",
        edit: "📝 编辑",
        download: "📥 下载",
        delete: "🗑️ 删除",
        confirmDelete: "确定要删除 {0} 吗？这个操作不可撤销。",
        newName: "新名称:",
        close: "关闭",
        setPermissions: "🔒 设置权限",
        saveLanguage: "保存语言设置",
        languageSaved: "语言设置已保存",
        modifiedTime: "修改时间",
        owner: "拥有者",
        create: "新建",
        newFolder: "新建文件夹",
        newFile: "新建文件",
        folderName: "文件夹名称:",
        fileName: "文件名称:",
        search: "搜索",
        searchFiles: "搜索文件",
        noMatchingFiles: "没有找到匹配的文件。",
        moveTo: "移至",
        cancel: "取消",
        confirm: "确认",
        goBack: "返回上一级",
        refreshDirectory: "刷新目录内容",
        switchTheme: "切换主题",
        lightMode: "浅色模式",
        darkMode: "深色模式",
        filePreview: "文件预览",
        unableToLoadImage: "无法加载图片:",
        unableToLoadSVG: "无法加载SVG文件:",
        unableToLoadAudio: "无法加载音频:",
        unableToLoadVideo: "无法加载视频:",
        home: "🏠 首页",
        mihomo: "Mihomo",
        singBox: "Sing-box",
        convert: "💹 订阅转换",
        fileAssistant: "📦 文件助手",
        errorSavingFile: "错误: 无法保存文件。",
        uploadFailed: "上传失败",
        fileNotExistOrNotReadable: "文件不存在或不可读。",
        inputFileName: "输入文件名",
        search: "搜索",
        permissionValue: "权限值（例如：0644）",
        inputThreeOrFourDigits: "输入三位或四位数字，例如：0644 或 0755",
        fontSizeL: "字体大小",
        encodingL: "编码",
        confirmCloseEditor: "确定要关闭编辑器吗？请确保已保存更改。",
        newNameCannotBeEmpty: "新名称不能为空",
        fileNameCannotContainChars: "文件名不能包含以下字符: < > : \" / \\ | ? *",
        folderNameCannotBeEmpty: "文件夹名称不能为空",
        fileNameCannotBeEmpty: "文件名称不能为空",
        searchError: "搜索时出错: ",
        encodingChanged: "编码已更改为 {0}。实际转换将在保存时在服务器端进行。",
        errorLoadingFileContent: "加载文件内容时出错: ",
        permissionHelp: "请输入有效的权限值（三位或四位八进制数字，例如：644 或 0755）",
        permissionValueCannotExceed: "权限值不能超过 0777",
        goBackTitle: "返回上一级",
        rootDirectoryTitle: "返回根目录",
        homeDirectoryTitle: "返回主目录",
        refreshDirectoryTitle: "刷新目录内容",
        selectAll: "全选",
        invertSelection: "反选",
        deleteSelected: "删除所选",
        searchTitle: "搜索",
        createTitle: "新建",
        uploadTitle: "上传",
        dragHint: "请将文件拖拽至此处或点击选择文件上传",
        searchInputPlaceholder: "输入文件名",
        moveTo: "移至",
        confirmRename: "确认重命名",
        create: "创建",
        confirmChange: "确认修改",
        themeToggleTitle: "切换主题",
        editFile: "编辑文件",
        save: "保存",
        advancedEdit: "高级编辑",
        line: "行",
        column: "列",
        characterCount: "字符数",
        fontSizeL: "字体大小",
        encodingL: "编码",
        gbk: "GBK (简体中文)",
        big5: "Big5 (繁体中文)",
        shiftJIS: "Shift_JIS (日文)",
        eucKR: "EUC-KR (韩文)",
        search: "搜索",
        format: "格式化",
        validateJSON: "验证 JSON",
        validateYAML: "验证 YAML",
        formatJSON: "格式化 JSON",
        goToParentDirectoryTitle: "返回上一级目录",
        alreadyAtRootDirectory: "已经在根目录，无法返回上一级。",
        close: "关闭",
        fullscreen: "全屏",
        exitFullscreen: "退出全屏",
        search_title: "搜索文件内容",
        jsonFormatSuccess: "JSON 已成功格式化",
        unableToFormatJSON: "无法格式化：无效的 JSON 格式",
        codeFormatSuccess: "代码已成功格式化",
        errorFormattingCode: "格式化时发生错误：",
        selectAtLeastOneFile: "请至少选择一个文件或文件夹进行删除。",
        confirmDeleteSelected: "确定要删除选中的 {0} 个文件或文件夹吗？这个操作不可撤销。"
    },

    "vi": {
        "pageTitle": "NeKoBox Trợ lý tệp",
        "chinese": "Tiếng Trung giản thể",
        "traditionalChinese": "Tiếng Trung phồn thể",
        "english": "Tiếng Anh",
        "uploadBtn": "Tải tệp lên",
        "rootDirectory": "Thư mục gốc",
        "name": "Tên",
        "type": "Loại",
        "size": "Kích thước",
        "permissions": "Quyền",
        "actions": "Hành động",
        "directory": "Thư mục",
        "file": "Tệp",
        "rename": "✏️ Đổi tên",
        "edit": "📝 Chỉnh sửa",
        "download": "📥 Tải xuống",
        "delete": "🗑️ Xóa",
        "confirmDelete": "Bạn có chắc chắn muốn xóa {0}? Hành động này không thể hoàn tác.",
        "newName": "Tên mới:",
        "close": "Đóng",
        "setPermissions": "🔒 Cài đặt quyền",
        "saveLanguage": "Lưu cài đặt ngôn ngữ",
        "languageSaved": "Cài đặt ngôn ngữ đã được lưu",
        "modifiedTime": "Thời gian sửa đổi",
        "owner": "Chủ sở hữu",
        "create": "Tạo mới",
        "newFolder": "Thư mục mới",
        "newFile": "Tệp mới",
        "folderName": "Tên thư mục:",
        "fileName": "Tên tệp:",
        "search": "Tìm kiếm",
        "searchFiles": "Tìm kiếm tệp",
        "noMatchingFiles": "Không tìm thấy tệp phù hợp.",
        "moveTo": "Di chuyển tới",
        "cancel": "Hủy",
        "confirm": "Xác nhận",
        "goBack": "Quay lại",
        "refreshDirectory": "Làm mới nội dung thư mục",
        "switchTheme": "Chuyển đổi chủ đề",
        "lightMode": "Chế độ sáng",
        "darkMode": "Chế độ tối",
        "filePreview": "Xem trước tệp",
        "unableToLoadImage": "Không thể tải hình ảnh:",
        "unableToLoadSVG": "Không thể tải tệp SVG:",
        "unableToLoadAudio": "Không thể tải âm thanh:",
        "unableToLoadVideo": "Không thể tải video:",
        "home": "🏠 Trang chủ",
        "mihomo": "Mihomo",
        "singBox": "Sing-box",
        "convert": "💹 Chuyển đổi đăng ký",
        "fileAssistant": "📦 Trợ lý tệp",
        "errorSavingFile": "Lỗi: Không thể lưu tệp.",
        "uploadFailed": "Tải lên thất bại",
        "fileNotExistOrNotReadable": "Tệp không tồn tại hoặc không thể đọc.",
        "inputFileName": "Nhập tên tệp",
        "permissionValue": "Giá trị quyền (ví dụ: 0644)",
        "inputThreeOrFourDigits": "Nhập ba hoặc bốn chữ số, ví dụ: 0644 hoặc 0755",
        "fontSizeL": "Kích thước phông chữ",
        "encodingL": "Mã hóa",
        "confirmCloseEditor": "Bạn có chắc chắn muốn đóng trình chỉnh sửa không? Hãy chắc chắn rằng bạn đã lưu các thay đổi.",
        "newNameCannotBeEmpty": "Tên mới không được để trống",
        "fileNameCannotContainChars": "Tên tệp không được chứa các ký tự sau: < > : \" / \\ | ? *",
        "folderNameCannotBeEmpty": "Tên thư mục không được để trống",
        "fileNameCannotBeEmpty": "Tên tệp không được để trống",
        "searchError": "Lỗi khi tìm kiếm: ",
        "encodingChanged": "Mã hóa đã được thay đổi thành {0}. Việc chuyển đổi thực tế sẽ được thực hiện khi lưu trên máy chủ.",
        "errorLoadingFileContent": "Lỗi khi tải nội dung tệp: ",
        "permissionHelp": "Vui lòng nhập giá trị quyền hợp lệ (ba hoặc bốn chữ số bát phân, ví dụ: 644 hoặc 0755)",
        "permissionValueCannotExceed": "Giá trị quyền không được vượt quá 0777",
        "goBackTitle": "Quay lại cấp trên",
        "rootDirectoryTitle": "Quay lại thư mục gốc",
        "homeDirectoryTitle": "Quay lại thư mục chính",
        "refreshDirectoryTitle": "Làm mới nội dung thư mục",
        "selectAll": "Chọn tất cả",
        "invertSelection": "Đảo ngược lựa chọn",
        "deleteSelected": "Xóa đã chọn",
        "searchTitle": "Tìm kiếm",
        "createTitle": "Tạo mới",
        "uploadTitle": "Tải lên",
        "dragHint": "Kéo tệp vào đây hoặc nhấp để chọn tệp để tải lên",
        "searchInputPlaceholder": "Nhập tên tệp",
        "confirmRename": "Xác nhận đổi tên",
        "create": "Tạo",
        "confirmChange": "Xác nhận thay đổi",
        "themeToggleTitle": "Chuyển đổi chủ đề",
        "editFile": "Chỉnh sửa tệp",
        "save": "Lưu",
        "advancedEdit": "Chỉnh sửa nâng cao",
        "line": "Dòng",
        "column": "Cột",
        "characterCount": "Số ký tự",
        "fontSizeL": "Kích thước phông chữ",
        "encodingL": "Mã hóa",
        "gbk": "GBK (Tiếng Trung giản thể)",
        "big5": "Big5 (Tiếng Trung phồn thể)",
        "shiftJIS": "Shift_JIS (Tiếng Nhật)",
        "eucKR": "EUC-KR (Tiếng Hàn)",
        "search": "Tìm kiếm",
        "format": "Định dạng",
        "validateJSON": "Xác nhận JSON",
        "validateYAML": "Xác nhận YAML",
        "formatJSON": "Định dạng JSON",
        "goToParentDirectoryTitle": "Quay lại thư mục cha",
        "alreadyAtRootDirectory": "Đã ở thư mục gốc, không thể quay lại.",
        "close": "Đóng",
        "fullscreen": "Toàn màn hình",
        "exitFullscreen": "Thoát toàn màn hình",
        "search_title": "Tìm kiếm nội dung tệp",
        "jsonFormatSuccess": "JSON đã được định dạng thành công",
        "unableToFormatJSON": "Không thể định dạng: JSON không hợp lệ",
        "codeFormatSuccess": "Mã đã được định dạng thành công",
        "errorFormattingCode": "Đã xảy ra lỗi khi định dạng mã:",
        "selectAtLeastOneFile": "Vui lòng chọn ít nhất một tệp hoặc thư mục để xóa.",
        "confirmDeleteSelected": "Bạn có chắc chắn muốn xóa {0} tệp hoặc thư mục đã chọn không? Hành động này không thể hoàn tác."
    },

    "ko": {
        "pageTitle": "NeKoBox 파일 도우미",
        "chinese": "중국어 간체",
        "traditionalChinese": "중국어 번체",
        "english": "영어",
        "uploadBtn": "파일 업로드",
        "rootDirectory": "루트 디렉토리",
        "name": "이름",
        "type": "유형",
        "size": "크기",
        "permissions": "권한",
        "actions": "작업",
        "directory": "디렉토리",
        "file": "파일",
        "rename": "✏️ 이름 변경",
        "edit": "📝 편집",
        "download": "📥 다운로드",
        "delete": "🗑️ 삭제",
        "confirmDelete": "{0}을(를) 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
        "newName": "새 이름:",
        "close": "닫기",
        "setPermissions": "🔒 권한 설정",
        "saveLanguage": "언어 설정 저장",
        "languageSaved": "언어 설정이 저장되었습니다",
        "modifiedTime": "수정 시간",
        "owner": "소유자",
        "create": "생성",
        "newFolder": "새 폴더",
        "newFile": "새 파일",
        "folderName": "폴더 이름:",
        "fileName": "파일 이름:",
        "search": "검색",
        "searchFiles": "파일 검색",
        "noMatchingFiles": "일치하는 파일을 찾을 수 없습니다.",
        "moveTo": "이동",
        "cancel": "취소",
        "confirm": "확인",
        "goBack": "뒤로가기",
        "refreshDirectory": "디렉토리 새로고침",
        "switchTheme": "테마 전환",
        "lightMode": "라이트 모드",
        "darkMode": "다크 모드",
        "filePreview": "파일 미리보기",
        "unableToLoadImage": "이미지를 불러올 수 없습니다:",
        "unableToLoadSVG": "SVG 파일을 불러올 수 없습니다:",
        "unableToLoadAudio": "오디오를 불러올 수 없습니다:",
        "unableToLoadVideo": "비디오를 불러올 수 없습니다:",
        "home": "🏠 홈",
        "mihomo": "Mihomo",
        "singBox": "Sing-box",
        "convert": "💹 구독 변환",
        "fileAssistant": "📦 파일 도우미",
        "errorSavingFile": "오류: 파일을 저장할 수 없습니다.",
        "uploadFailed": "업로드 실패",
        "fileNotExistOrNotReadable": "파일이 없거나 읽을 수 없습니다.",
        "inputFileName": "파일 이름 입력",
        "permissionValue": "권한 값 (예: 0644)",
        "inputThreeOrFourDigits": "세 자리 또는 네 자리 숫자를 입력하세요, 예: 0644 또는 0755",
        "fontSizeL": "글꼴 크기",
        "encodingL": "인코딩",
        "confirmCloseEditor": "편집기를 닫으시겠습니까? 변경 사항이 저장되었는지 확인하세요.",
        "newNameCannotBeEmpty": "새 이름은 비워둘 수 없습니다",
        "fileNameCannotContainChars": "파일 이름에는 다음 문자를 포함할 수 없습니다: < > : \" / \\ | ? *",
        "folderNameCannotBeEmpty": "폴더 이름은 비워둘 수 없습니다",
        "fileNameCannotBeEmpty": "파일 이름은 비워둘 수 없습니다",
        "searchError": "검색 중 오류 발생: ",
        "encodingChanged": "인코딩이 {0}으로 변경되었습니다. 실제 변환은 저장 시 서버에서 이루어집니다.",
        "errorLoadingFileContent": "파일 내용을 로드하는 중 오류 발생: ",
        "permissionHelp": "유효한 권한 값을 입력하세요 (세 자리 또는 네 자리 8진수 숫자, 예: 644 또는 0755)",
        "permissionValueCannotExceed": "권한 값은 0777을 초과할 수 없습니다",
        "goBackTitle": "상위 디렉토리로 돌아가기",
        "rootDirectoryTitle": "루트 디렉토리로 돌아가기",
        "homeDirectoryTitle": "홈 디렉토리로 돌아가기",
        "refreshDirectoryTitle": "디렉토리 새로고침",
        "selectAll": "모두 선택",
        "invertSelection": "선택 반전",
        "deleteSelected": "선택된 항목 삭제",
        "searchTitle": "검색",
        "createTitle": "생성",
        "uploadTitle": "업로드",
        "dragHint": "파일을 여기에 드래그하거나 클릭하여 업로드할 파일을 선택하세요",
        "searchInputPlaceholder": "파일 이름 입력",
        "confirmRename": "이름 변경 확인",
        "create": "생성",
        "confirmChange": "변경 확인",
        "themeToggleTitle": "테마 전환",
        "editFile": "파일 편집",
        "save": "저장",
        "advancedEdit": "고급 편집",
        "line": "라인",
        "column": "열",
        "characterCount": "문자 수",
        "fontSizeL": "글꼴 크기",
        "encodingL": "인코딩",
        "gbk": "GBK (중국어 간체)",
        "big5": "Big5 (중국어 번체)",
        "shiftJIS": "Shift_JIS (일본어)",
        "eucKR": "EUC-KR (한국어)",
        "search": "검색",
        "format": "포맷",
        "validateJSON": "JSON 유효성 검사",
        "validateYAML": "YAML 유효성 검사",
        "formatJSON": "JSON 포맷",
        "goToParentDirectoryTitle": "상위 디렉토리로 이동",
        "alreadyAtRootDirectory": "이미 루트 디렉토리에 있습니다, 상위로 이동할 수 없습니다.",
        "close": "닫기",
        "fullscreen": "전체 화면",
        "exitFullscreen": "전체 화면 종료",
        "search_title": "파일 내용 검색",
        "jsonFormatSuccess": "JSON이 성공적으로 포맷되었습니다",
        "unableToFormatJSON": "포맷할 수 없습니다: 잘못된 JSON 형식",
        "codeFormatSuccess": "코드가 성공적으로 포맷되었습니다",
        "errorFormattingCode": "코드 포맷 중 오류 발생:",
        "selectAtLeastOneFile": "삭제할 파일이나 폴더를 최소 하나 선택하세요.",
        "confirmDeleteSelected": "선택한 {0}개의 파일이나 폴더를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."
    },

    "ar": {
        "pageTitle": "مساعد الملفات NeKoBox",
        "chinese": "الصينية المبسطة",
        "traditionalChinese": "الصينية التقليدية",
        "english": "الإنجليزية",
        "uploadBtn": "تحميل الملفات",
        "rootDirectory": "الدليل الرئيسي",
        "name": "الاسم",
        "type": "النوع",
        "size": "الحجم",
        "permissions": "الأذونات",
        "actions": "الإجراءات",
        "directory": "دليل",
        "file": "ملف",
        "rename": "✏️ إعادة تسمية",
        "edit": "📝 تحرير",
        "download": "📥 تحميل",
        "delete": "🗑️ حذف",
        "confirmDelete": "هل أنت متأكد من حذف {0}؟ هذا الإجراء لا يمكن التراجع عنه.",
        "newName": "الاسم الجديد:",
        "close": "إغلاق",
        "setPermissions": "🔒 تعيين الأذونات",
        "saveLanguage": "حفظ إعدادات اللغة",
        "languageSaved": "تم حفظ إعدادات اللغة",
        "modifiedTime": "وقت التعديل",
        "owner": "المالك",
        "create": "إنشاء",
        "newFolder": "مجلد جديد",
        "newFile": "ملف جديد",
        "folderName": "اسم المجلد:",
        "fileName": "اسم الملف:",
        "search": "بحث",
        "searchFiles": "بحث في الملفات",
        "noMatchingFiles": "لم يتم العثور على ملفات مطابقة.",
        "moveTo": "نقل إلى",
        "cancel": "إلغاء",
        "confirm": "تأكيد",
        "goBack": "العودة",
        "refreshDirectory": "تحديث محتويات الدليل",
        "switchTheme": "تبديل المظهر",
        "lightMode": "الوضع الفاتح",
        "darkMode": "الوضع الداكن",
        "filePreview": "معاينة الملف",
        "unableToLoadImage": "تعذر تحميل الصورة:",
        "unableToLoadSVG": "تعذر تحميل ملف SVG:",
        "unableToLoadAudio": "تعذر تحميل الصوت:",
        "unableToLoadVideo": "تعذر تحميل الفيديو:",
        "home": "🏠 الصفحة الرئيسية",
        "mihomo": "Mihomo",
        "singBox": "Sing-box",
        "convert": "💹 تحويل الاشتراك",
        "fileAssistant": "📦 مساعد الملفات",
        "errorSavingFile": "خطأ: تعذر حفظ الملف.",
        "uploadFailed": "فشل التحميل",
        "fileNotExistOrNotReadable": "الملف غير موجود أو غير قابل للقراءة.",
        "inputFileName": "أدخل اسم الملف",
        "permissionValue": "قيمة الأذونات (مثال: 0644)",
        "inputThreeOrFourDigits": "أدخل ثلاث أو أربع أرقام، مثال: 0644 أو 0755",
        "fontSizeL": "حجم الخط",
        "encodingL": "الترميز",
        "confirmCloseEditor": "هل أنت متأكد أنك تريد إغلاق المحرر؟ تأكد من حفظ التغييرات.",
        "newNameCannotBeEmpty": "الاسم الجديد لا يمكن أن يكون فارغًا",
        "fileNameCannotContainChars": "اسم الملف لا يمكن أن يحتوي على الأحرف التالية: < > : \" / \\ | ? *",
        "folderNameCannotBeEmpty": "اسم المجلد لا يمكن أن يكون فارغًا",
        "fileNameCannotBeEmpty": "اسم الملف لا يمكن أن يكون فارغًا",
        "searchError": "حدث خطأ أثناء البحث: ",
        "encodingChanged": "تم تغيير الترميز إلى {0}. سيتم تطبيق التغيير فعليًا عند الحفظ على الخادم.",
        "errorLoadingFileContent": "حدث خطأ أثناء تحميل محتويات الملف: ",
        "permissionHelp": "الرجاء إدخال قيمة أذونات صالحة (ثلاث أو أربع أرقام بنظام الأوكتال، مثال: 644 أو 0755)",
        "permissionValueCannotExceed": "قيمة الأذونات لا يمكن أن تتجاوز 0777",
        "goBackTitle": "العودة إلى الدليل العلوي",
        "rootDirectoryTitle": "العودة إلى الدليل الرئيسي",
        "homeDirectoryTitle": "العودة إلى الدليل الشخصي",
        "refreshDirectoryTitle": "تحديث محتويات الدليل",
        "selectAll": "تحديد الكل",
        "invertSelection": "عكس التحديد",
        "deleteSelected": "حذف المحدد",
        "searchTitle": "بحث",
        "createTitle": "إنشاء",
        "uploadTitle": "تحميل",
        "dragHint": "اسحب الملفات هنا أو انقر لاختيار الملفات لتحميلها",
        "searchInputPlaceholder": "أدخل اسم الملف",
        "confirmRename": "تأكيد إعادة التسمية",
        "create": "إنشاء",
        "confirmChange": "تأكيد التغيير",
        "themeToggleTitle": "تبديل المظهر",
        "editFile": "تحرير الملف",
        "save": "حفظ",
        "advancedEdit": "تحرير متقدم",
        "line": "سطر",
        "column": "عمود",
        "characterCount": "عدد الأحرف",
        "fontSizeL": "حجم الخط",
        "encodingL": "الترميز",
        "gbk": "GBK (الصينية المبسطة)",
        "big5": "Big5 (الصينية التقليدية)",
        "shiftJIS": "Shift_JIS (اليابانية)",
        "eucKR": "EUC-KR (الكورية)",
        "search": "بحث",
        "format": "تنسيق",
        "validateJSON": "التحقق من صحة JSON",
        "validateYAML": "التحقق من صحة YAML",
        "formatJSON": "تنسيق JSON",
        "goToParentDirectoryTitle": "الانتقال إلى الدليل العلوي",
        "alreadyAtRootDirectory": "أنت بالفعل في الدليل الرئيسي، لا يمكنك الرجوع.",
        "close": "إغلاق",
        "fullscreen": "ملء الشاشة",
        "exitFullscreen": "الخروج من ملء الشاشة",
        "search_title": "بحث في محتويات الملف",
        "jsonFormatSuccess": "تم تنسيق JSON بنجاح",
        "unableToFormatJSON": "تعذر التنسيق: JSON غير صالح",
        "codeFormatSuccess": "تم تنسيق الكود بنجاح",
        "errorFormattingCode": "حدث خطأ أثناء تنسيق الكود:",
        "selectAtLeastOneFile": "الرجاء تحديد ملف أو مجلد واحد على الأقل للحذف.",
        "confirmDeleteSelected": "هل أنت متأكد أنك تريد حذف {0} ملف أو مجلد محدد؟ لا يمكن التراجع عن هذا الإجراء."
    },

    "ru": {
        "pageTitle": "Помощник файлов NeKoBox",
        "chinese": "Упрощённый китайский",
        "traditionalChinese": "Традиционный китайский",
        "english": "Английский",
        "uploadBtn": "Загрузить файл",
        "rootDirectory": "Корневой каталог",
        "name": "Имя",
        "type": "Тип",
        "size": "Размер",
        "permissions": "Разрешения",
        "actions": "Действия",
        "directory": "Каталог",
        "file": "Файл",
        "rename": "✏️ Переименовать",
        "edit": "📝 Редактировать",
        "download": "📥 Скачать",
        "delete": "🗑️ Удалить",
        "confirmDelete": "Вы уверены, что хотите удалить {0}? Это действие невозможно отменить.",
        "newName": "Новое имя:",
        "close": "Закрыть",
        "setPermissions": "🔒 Установить разрешения",
        "saveLanguage": "Сохранить настройки языка",
        "languageSaved": "Настройки языка сохранены",
        "modifiedTime": "Время изменения",
        "owner": "Владелец",
        "create": "Создать",
        "newFolder": "Новая папка",
        "newFile": "Новый файл",
        "folderName": "Имя папки:",
        "fileName": "Имя файла:",
        "search": "Поиск",
        "searchFiles": "Поиск файлов",
        "noMatchingFiles": "Совпадающие файлы не найдены.",
        "moveTo": "Переместить в",
        "cancel": "Отменить",
        "confirm": "Подтвердить",
        "goBack": "Вернуться назад",
        "refreshDirectory": "Обновить содержимое каталога",
        "switchTheme": "Сменить тему",
        "lightMode": "Светлый режим",
        "darkMode": "Тёмный режим",
        "filePreview": "Предварительный просмотр файла",
        "unableToLoadImage": "Не удалось загрузить изображение:",
        "unableToLoadSVG": "Не удалось загрузить SVG файл:",
        "unableToLoadAudio": "Не удалось загрузить аудио:",
        "unableToLoadVideo": "Не удалось загрузить видео:",
        "home": "🏠 Домашняя страница",
        "mihomo": "Mihomo",
        "singBox": "Sing-box",
        "convert": "💹 Конвертация подписки",
        "fileAssistant": "📦 Помощник файлов",
        "errorSavingFile": "Ошибка: не удалось сохранить файл.",
        "uploadFailed": "Не удалось загрузить",
        "fileNotExistOrNotReadable": "Файл не существует или недоступен для чтения.",
        "inputFileName": "Введите имя файла",
        "permissionValue": "Значение разрешений (например: 0644)",
        "inputThreeOrFourDigits": "Введите три или четыре цифры, например: 0644 или 0755",
        "fontSizeL": "Размер шрифта",
        "encodingL": "Кодировка",
        "confirmCloseEditor": "Вы уверены, что хотите закрыть редактор? Убедитесь, что изменения сохранены.",
        "newNameCannotBeEmpty": "Новое имя не может быть пустым",
        "fileNameCannotContainChars": "Имя файла не может содержать следующие символы: < > : \" / \\ | ? *",
        "folderNameCannotBeEmpty": "Имя папки не может быть пустым",
        "fileNameCannotBeEmpty": "Имя файла не может быть пустым",
        "searchError": "Ошибка при поиске: ",
        "encodingChanged": "Кодировка изменена на {0}. Преобразование будет выполнено при сохранении на сервере.",
        "errorLoadingFileContent": "Ошибка при загрузке содержимого файла: ",
        "permissionHelp": "Введите допустимое значение разрешений (три или четыре восьмеричные цифры, например: 644 или 0755)",
        "permissionValueCannotExceed": "Значение разрешений не может превышать 0777",
        "goBackTitle": "Вернуться в родительский каталог",
        "rootDirectoryTitle": "Вернуться в корневой каталог",
        "homeDirectoryTitle": "Вернуться в домашний каталог",
        "refreshDirectoryTitle": "Обновить содержимое каталога",
        "selectAll": "Выбрать всё",
        "invertSelection": "Инвертировать выбор",
        "deleteSelected": "Удалить выбранное",
        "searchTitle": "Поиск",
        "createTitle": "Создать",
        "uploadTitle": "Загрузить",
        "dragHint": "Перетащите файлы сюда или нажмите, чтобы выбрать файлы для загрузки",
        "searchInputPlaceholder": "Введите имя файла",
        "confirmRename": "Подтвердить переименование",
        "create": "Создать",
        "confirmChange": "Подтвердить изменение",
        "themeToggleTitle": "Сменить тему",
        "editFile": "Редактировать файл",
        "save": "Сохранить",
        "advancedEdit": "Расширенное редактирование",
        "line": "Строка",
        "column": "Колонка",
        "characterCount": "Количество символов",
        "fontSizeL": "Размер шрифта",
        "encodingL": "Кодировка",
        "gbk": "GBK (упрощённый китайский)",
        "big5": "Big5 (традиционный китайский)",
        "shiftJIS": "Shift_JIS (японский)",
        "eucKR": "EUC-KR (корейский)",
        "search": "Поиск",
        "format": "Формат",
        "validateJSON": "Проверить JSON",
        "validateYAML": "Проверить YAML",
        "formatJSON": "Форматировать JSON",
        "goToParentDirectoryTitle": "Перейти в родительский каталог",
        "alreadyAtRootDirectory": "Вы уже находитесь в корневом каталоге, возврат невозможен.",
        "close": "Закрыть",
        "fullscreen": "Полноэкранный режим",
        "exitFullscreen": "Выйти из полноэкранного режима",
        "search_title": "Поиск по содержимому файла",
        "jsonFormatSuccess": "JSON успешно отформатирован",
        "unableToFormatJSON": "Не удалось отформатировать: неверный формат JSON",
        "codeFormatSuccess": "Код успешно отформатирован",
        "errorFormattingCode": "Ошибка при форматировании кода:",
        "selectAtLeastOneFile": "Выберите хотя бы один файл или папку для удаления.",
        "confirmDeleteSelected": "Вы уверены, что хотите удалить выбранные {0} файлов или папок? Это действие невозможно отменить."
    },

    "de": {
        "pageTitle": "NeKoBox Dateimanager",
        "chinese": "Vereinfachtes Chinesisch",
        "traditionalChinese": "Traditionelles Chinesisch",
        "english": "Englisch",
        "uploadBtn": "Datei hochladen",
        "rootDirectory": "Stammverzeichnis",
        "name": "Name",
        "type": "Typ",
        "size": "Größe",
        "permissions": "Berechtigungen",
        "actions": "Aktionen",
        "directory": "Verzeichnis",
        "file": "Datei",
        "rename": "✏️ Umbenennen",
        "edit": "📝 Bearbeiten",
        "download": "📥 Herunterladen",
        "delete": "🗑️ Löschen",
        "confirmDelete": "Möchten Sie {0} wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.",
        "newName": "Neuer Name:",
        "close": "Schließen",
        "setPermissions": "🔒 Berechtigungen festlegen",
        "saveLanguage": "Spracheinstellungen speichern",
        "languageSaved": "Spracheinstellungen wurden gespeichert",
        "modifiedTime": "Geänderte Zeit",
        "owner": "Eigentümer",
        "create": "Erstellen",
        "newFolder": "Neuer Ordner",
        "newFile": "Neue Datei",
        "folderName": "Ordnername:",
        "fileName": "Dateiname:",
        "search": "Suche",
        "searchFiles": "Dateien durchsuchen",
        "noMatchingFiles": "Keine passenden Dateien gefunden.",
        "moveTo": "Verschieben nach",
        "cancel": "Abbrechen",
        "confirm": "Bestätigen",
        "goBack": "Zurück",
        "refreshDirectory": "Verzeichnisinhalt aktualisieren",
        "switchTheme": "Thema wechseln",
        "lightMode": "Heller Modus",
        "darkMode": "Dunkler Modus",
        "filePreview": "Dateivorschau",
        "unableToLoadImage": "Bild konnte nicht geladen werden:",
        "unableToLoadSVG": "SVG-Datei konnte nicht geladen werden:",
        "unableToLoadAudio": "Audio konnte nicht geladen werden:",
        "unableToLoadVideo": "Video konnte nicht geladen werden:",
        "home": "🏠 Startseite",
        "mihomo": "Mihomo",
        "singBox": "Sing-box",
        "convert": "💹 Abonnement konvertieren",
        "fileAssistant": "📦 Dateimanager",
        "errorSavingFile": "Fehler: Datei konnte nicht gespeichert werden.",
        "uploadFailed": "Upload fehlgeschlagen",
        "fileNotExistOrNotReadable": "Datei existiert nicht oder ist nicht lesbar.",
        "inputFileName": "Dateinamen eingeben",
        "permissionValue": "Berechtigungswert (z.B. 0644)",
        "inputThreeOrFourDigits": "Geben Sie drei oder vier Ziffern ein, z.B. 0644 oder 0755",
        "fontSizeL": "Schriftgröße",
        "encodingL": "Kodierung",
        "confirmCloseEditor": "Möchten Sie den Editor wirklich schließen? Stellen Sie sicher, dass Ihre Änderungen gespeichert wurden.",
        "newNameCannotBeEmpty": "Neuer Name darf nicht leer sein",
        "fileNameCannotContainChars": "Der Dateiname darf die folgenden Zeichen nicht enthalten: < > : \" / \\ | ? *",
        "folderNameCannotBeEmpty": "Der Ordnername darf nicht leer sein",
        "fileNameCannotBeEmpty": "Der Dateiname darf nicht leer sein",
        "searchError": "Fehler bei der Suche: ",
        "encodingChanged": "Die Kodierung wurde auf {0} geändert. Die tatsächliche Umwandlung erfolgt beim Speichern auf dem Server.",
        "errorLoadingFileContent": "Fehler beim Laden des Dateiinhalts: ",
        "permissionHelp": "Bitte geben Sie einen gültigen Berechtigungswert ein (drei oder vier Ziffern im Oktalsystem, z.B. 644 oder 0755)",
        "permissionValueCannotExceed": "Berechtigungswert darf 0777 nicht überschreiten",
        "goBackTitle": "Zurück zum übergeordneten Verzeichnis",
        "rootDirectoryTitle": "Zurück zum Stammverzeichnis",
        "homeDirectoryTitle": "Zurück zum Home-Verzeichnis",
        "refreshDirectoryTitle": "Verzeichnisinhalt aktualisieren",
        "selectAll": "Alles auswählen",
        "invertSelection": "Auswahl umkehren",
        "deleteSelected": "Ausgewählte löschen",
        "searchTitle": "Suche",
        "createTitle": "Erstellen",
        "uploadTitle": "Hochladen",
        "dragHint": "Ziehen Sie Dateien hierher oder klicken Sie, um Dateien zum Hochladen auszuwählen",
        "searchInputPlaceholder": "Dateinamen eingeben",
        "confirmRename": "Umbenennung bestätigen",
        "create": "Erstellen",
        "confirmChange": "Änderung bestätigen",
        "themeToggleTitle": "Thema wechseln",
        "editFile": "Datei bearbeiten",
        "save": "Speichern",
        "advancedEdit": "Erweiterte Bearbeitung",
        "line": "Zeile",
        "column": "Spalte",
        "characterCount": "Anzahl der Zeichen",
        "fontSizeL": "Schriftgröße",
        "encodingL": "Kodierung",
        "gbk": "GBK (Vereinfachtes Chinesisch)",
        "big5": "Big5 (Traditionelles Chinesisch)",
        "shiftJIS": "Shift_JIS (Japanisch)",
        "eucKR": "EUC-KR (Koreanisch)",
        "search": "Suche",
        "format": "Formatieren",
        "validateJSON": "JSON validieren",
        "validateYAML": "YAML validieren",
        "formatJSON": "JSON formatieren",
        "goToParentDirectoryTitle": "Zum übergeordneten Verzeichnis wechseln",
        "alreadyAtRootDirectory": "Sie befinden sich bereits im Stammverzeichnis, ein Zurückgehen ist nicht möglich.",
        "close": "Schließen",
        "fullscreen": "Vollbild",
        "exitFullscreen": "Vollbildmodus beenden",
        "search_title": "Dateiinhalte durchsuchen",
        "jsonFormatSuccess": "JSON erfolgreich formatiert",
        "unableToFormatJSON": "Formatierung nicht möglich: Ungültiges JSON-Format",
        "codeFormatSuccess": "Code erfolgreich formatiert",
        "errorFormattingCode": "Fehler beim Formatieren des Codes:",
        "selectAtLeastOneFile": "Bitte wählen Sie mindestens eine Datei oder einen Ordner zum Löschen aus.",
        "confirmDeleteSelected": "Möchten Sie die ausgewählten {0} Dateien oder Ordner wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden."
    },

    en: {
        pageTitle: "NeKoBox File Assistant",
        chinese: 'Simplified Chinese',
        traditionalChinese: 'Traditional Chinese',
        english: 'English',
        uploadBtn: "Upload File",
        rootDirectory: "root",
        name: "Name",
        type: "Type",
        size: "Size",
        permissions: "Permissions",
        actions: "Actions",
        directory: "Directory",
        file: "File",
        rename: "✏️ Rename",
        edit: "📝 Edit",
        download: "📥 Download",
        delete: "🗑️ Delete",
        confirmDelete: "Are you sure you want to delete {0}? This action cannot be undone.",
        newName: "New name:",
        close: "Close",
        setPermissions: "🔒 Set Permissions",
        saveLanguage: "Save Language Setting",
        languageSaved: "Language setting has been saved",
        modifiedTime: "Modified Time",
        owner: "Owner",
        create: "Create",
        newFolder: "New Folder",
        newFile: "New File",
        folderName: "Folder name:",
        fileName: "File name:",
        search: "Search",
        searchFiles: "Search Files",
        noMatchingFiles: "No matching files found.",
        moveTo: "Move to",
        cancel: "Cancel",
        confirm: "Confirm",
        goBack: "Go Back",
        refreshDirectory: "Refresh Directory",
        switchTheme: "Switch Theme",
        lightMode: "Light Mode",
        darkMode: "Dark Mode",
        filePreview: "File Preview",
        unableToLoadImage: "Unable to load image:",
        unableToLoadSVG: "Unable to load SVG file:",
        unableToLoadAudio: "Unable to load audio:",
        unableToLoadVideo: "Unable to load video:",
        home: "🏠 Home",
        mihomo: "Mihomo",
        singBox: "Sing-box",
        convert: "💹 Convert",
        fileAssistant: "📦 File Assistant",
        errorSavingFile: "Error: Unable to save file.",
        uploadFailed: "Upload failed",
        dragHint: "Drag and drop files here or click to upload",
        fileNotExistOrNotReadable: "File does not exist or is not readable.",
        inputFileName: "Input file name",
        search: "Search",
        permissionValue: "Permission value (e.g.: 0644)",
        inputThreeOrFourDigits: "Enter three or four digits, e.g.: 0644 or 0755",
        fontSizeL: "Font Size",
        encodingL: "Encoding",
        save: "Save",
        closeL: "Close",
        confirmCloseEditor: "Are you sure you want to close the editor? Please make sure you have saved your changes.",
        newNameCannotBeEmpty: "New name cannot be empty",
        fileNameCannotContainChars: "File name cannot contain the following characters: < > : \" / \\ | ? *",
        folderNameCannotBeEmpty: "Folder name cannot be empty",
        fileNameCannotBeEmpty: "File name cannot be empty",
        searchError: "Error searching: ",
        encodingChanged: "Encoding changed to {0}. Actual conversion will be done on the server side when saving.",
        errorLoadingFileContent: "Error loading file content: ",
        permissionHelp: "Please enter a valid permission value (three or four octal digits, e.g.: 644 or 0755)",
        permissionValueCannotExceed: "Permission value cannot exceed 0777",
        goBackTitle: "Go Back",
        rootDirectoryTitle: "Return to Root Directory",
        homeDirectoryTitle: "Return to Home Directory",
        refreshDirectoryTitle: "Refresh Directory Content",
        selectAll: "Select All",
        invertSelection: "Invert Selection",
        deleteSelected: "Delete Selected",
        searchTitle: "Search",
        createTitle: "Create New",
        uploadTitle: "Upload",
        searchInputPlaceholder: "Enter file name",
        confirmRename: "Confirm Rename",
        create: "Create",
        moveTo: "Move to",
        confirmChange: "Confirm Change",
        themeToggleTitle: "Toggle Theme",
        editFile: "Edit File",
        save: "Save",
        advancedEdit: "Advanced Edit",
        line: "Line",
        column: "Column",
        characterCount: "Character Count",
        fontSizeL: "Font Size",
        encodingL: "Encoding",
        gbk: "GBK (Simplified Chinese)",
        big5: "Big5 (Traditional Chinese)",
        shiftJIS: "Shift_JIS (Japanese)",
        eucKR: "EUC-KR (Korean)",
        search: "Search",
        format: "Format",
        validateJSON: "Validate JSON",
        validateYAML: "Validate YAML",
        formatJSON: "Format JSON",
        goToParentDirectoryTitle: "Go to parent directory",
        alreadyAtRootDirectory: "Already at the root directory, cannot go back.",
        close: "Close",
        search_title: "Search File Content",
        fullscreen: "Fullscreen",
        exitFullscreen: "Exit Fullscreen",
        jsonFormatSuccess: "JSON has been successfully formatted",
        unableToFormatJSON: "Unable to format: Invalid JSON format",
        codeFormatSuccess: "Code has been successfully formatted",
        errorFormattingCode: "Error formatting code: ",
        selectAtLeastOneFile: "Please select at least one file or folder to delete.",
        confirmDeleteSelected: "Are you sure you want to delete the selected {0} files or folders? This action cannot be undone."
    },
    "zh-tw": {
        pageTitle: "NeKoBox 檔案助手",
        chinese: '简體中文',
        traditionalChinese: '繁體中文',
        english: 'English',
        uploadBtn: "上傳檔案",
        rootDirectory: "根目錄",
        name: "名稱",
        type: "類型", 
        size: "大小",
        permissions: "權限",
        actions: "操作",
        directory: "目錄",
        file: "檔案",
        rename: "✏️ 重新命名",
        edit: "📝 編輯",
        download: "📥 下載",
        delete: "🗑️ 刪除",
        confirmDelete: "確定要刪除 {0} 嗎？此操作無法撤銷。",
        newName: "新名稱:",
        close: "關閉",
        setPermissions: "🔒 設定權限",
        saveLanguage: "儲存語言設定",
        languageSaved: "語言設定已儲存",
        modifiedTime: "修改時間",
        owner: "擁有者",
        create: "新建",
        newFolder: "新建資料夾",
        newFile: "新建檔案",
        folderName: "資料夾名稱:",
        fileName: "檔案名稱:", 
        search: "搜尋",
        searchFiles: "搜尋檔案",
        noMatchingFiles: "沒有找到符合的檔案。",
        moveTo: "移至",
        cancel: "取消",
        confirm: "確認",
        goBack: "返回上一層",
        refreshDirectory: "重新整理目錄內容",
        switchTheme: "切換主題",
        lightMode: "淺色模式",
        darkMode: "深色模式",
        filePreview: "檔案預覽",
        unableToLoadImage: "無法載入圖片:",
        unableToLoadSVG: "無法載入SVG檔案:",
        unableToLoadAudio: "無法載入音訊:",
        unableToLoadVideo: "無法載入視訊:",
        home: "🏠 首頁",
        mihomo: "Mihomo",
        singBox: "Sing-box", 
        convert: "💹 訂閱轉換",
        fileAssistant: "📦 檔案助手",
        errorSavingFile: "錯誤: 無法儲存檔案。",
        uploadFailed: "上傳失敗",
        fileNotExistOrNotReadable: "檔案不存在或無法讀取。",
        inputFileName: "輸入檔案名稱",
        permissionValue: "權限值（例如：0644）",
        inputThreeOrFourDigits: "輸入三位或四位數字，例如：0644 或 0755",
        fontSizeL: "字型大小",
        encodingL: "編碼",
        save: "儲存",
        closeL: "關閉",
        confirmCloseEditor: "確定要關閉編輯器嗎？請確保已儲存更改。",
        newNameCannotBeEmpty: "新名稱不能為空",
        fileNameCannotContainChars: "檔案名稱不能包含以下字元: < > : \" / \\ | ? *",
        folderNameCannotBeEmpty: "資料夾名稱不能為空",
        fileNameCannotBeEmpty: "檔案名稱不能為空",
        searchError: "搜尋時出錯: ",
        encodingChanged: "編碼已更改為 {0}。實際轉換將在儲存時在伺服器端進行。",
        errorLoadingFileContent: "載入檔案內容時出錯: ",
        permissionHelp: "請輸入有效的權限值（三位或四位八進位數字，例如：644 或 0755）",
        permissionValueCannotExceed: "權限值不能超過 0777",
        goBackTitle: "返回上一層",
        rootDirectoryTitle: "返回根目錄",
        homeDirectoryTitle: "返回主目錄", 
        refreshDirectoryTitle: "重新整理目錄內容",
        selectAll: "全選",
        invertSelection: "反選",
        deleteSelected: "刪除所選",
        searchTitle: "搜尋",
        createTitle: "新建",
        uploadTitle: "上傳",
        dragHint: "請將文件拖曳至此處或點擊選擇文件上傳",
        searchInputPlaceholder: "輸入檔案名稱",
        confirmRename: "確認重新命名",
        create: "建立",
        confirmChange: "確認修改",
        themeToggleTitle: "切換主題",
        editFile: "編輯檔案",
        advancedEdit: "進階編輯",
        line: "行",
        column: "列",
        characterCount: "字元數",
        gbk: "GBK (簡體中文)",
        big5: "Big5 (繁體中文)",
        shiftJIS: "Shift_JIS (日文)",
        eucKR: "EUC-KR (韓文)",
        format: "格式化",
        validateJSON: "驗證 JSON",
        validateYAML: "驗證 YAML", 
        formatJSON: "格式化 JSON",
        goToParentDirectoryTitle: "返回上一層目錄",
        alreadyAtRootDirectory: "已在根目錄，無法返回上一層。",
        close: "關閉",
        fullscreen: "全螢幕",
        exitFullscreen: "退出全螢幕",
        search_title: "搜尋檔案內容",
        jsonFormatSuccess: "JSON 已成功格式化",
        unableToFormatJSON: "無法格式化：無效的 JSON 格式",
        codeFormatSuccess: "程式碼已成功格式化",
        errorFormattingCode: "格式化時發生錯誤：",
        selectAtLeastOneFile: "請至少選擇一個檔案或資料夾進行刪除。",
        confirmDeleteSelected: "確定要刪除選中的 {0} 個檔案或資料夾嗎？此操作無法撤銷。"
    }
};

let currentLang = localStorage.getItem('preferred_language') || 'en';

function updateLanguage(lang) {
    document.documentElement.lang = lang;
    pageTitle.textContent = translations[lang].pageTitle;
    uploadBtn.title = translations[lang].uploadBtn;

    document.querySelectorAll('th').forEach((th) => {
        const key = th.getAttribute('data-translate');
        if (key && translations[lang][key]) {
            th.textContent = translations[lang][key];
        }
    });

    document.querySelectorAll('[data-translate-value]').forEach(el => {
        const key = el.getAttribute('data-translate-value');
        if (translations[lang][key]) {
            el.value = translations[lang][key];
        }
    });

    document.querySelectorAll('[data-translate], [data-translate-title], [data-translate-placeholder]').forEach(el => {
        const translateKey = el.getAttribute('data-translate');
        const titleKey = el.getAttribute('data-translate-title');
        const placeholderKey = el.getAttribute('data-translate-placeholder');

        if (translateKey && translations[lang][translateKey]) {
            if (el.tagName === 'INPUT' && el.type === 'text') {
                el.placeholder = translations[lang][translateKey];
            } else {
                el.textContent = translations[lang][translateKey];
            }
        }

        if (titleKey && translations[lang][titleKey]) {
            el.title = translations[lang][titleKey];
        }

        if (placeholderKey && translations[lang][placeholderKey]) {
            el.placeholder = translations[lang][placeholderKey];
        }
    });

    document.querySelector('.breadcrumb a').textContent = translations[lang].rootDirectory;
    document.querySelector('#renameModal h2').textContent = translations[lang].rename;
    document.querySelector('#editModal h2').textContent = translations[lang].edit;
    document.querySelector('#chmodModal h2').textContent = translations[lang].setPermissions;

    document.getElementById('languageSwitcher').value = lang;
    }

    updateLanguage(currentLang);

    document.getElementById('languageSwitcher').addEventListener('change', function() {
        currentLang = this.value;
        updateLanguage(currentLang);
        localStorage.setItem('preferred_language', currentLang);
    });

    window.confirmDelete = function(name) {
        return confirm(translations[currentLang].confirmDelete.replace('{0}', name));
    }

    window.showRenameModal = function(oldName, oldPath) {
        document.getElementById('oldPath').value = oldPath;
        document.getElementById('newPath').value = oldName;
        document.querySelector('#renameModal label').textContent = translations[currentLang].newName;
        showModal('renameModal');
    }
    });
    
const DEFAULT_FONT_SIZE = '20px';

let aceEditor;

function showModal(modalId) {
    document.getElementById(modalId).style.display = "block";
}

function goBack() {
    window.history.back();
}

function refreshDirectory() {
    location.reload();
}

function showCreateModal() {
    showModal('createModal');
}

function showNewFolderModal() {
    closeModal('createModal');
    showModal('newFolderModal');
}

function showNewFileModal() {
    closeModal('createModal');
    showModal('newFileModal');
}

function goToParentDirectory() {
    const currentPath = '<?php echo $current_dir; ?>';
    let parentPath = currentPath.split('/').filter(Boolean);
    parentPath.pop();
    parentPath = '/' + parentPath.join('/');

    if (parentPath === '') {
        parentPath = '/';
    }
    
    window.location.href = '?dir=' + encodeURIComponent(parentPath);
}

window.addEventListener("load", function() {
    aceEditor = ace.edit("aceEditorContainer");
    aceEditor.setTheme("ace/theme/monokai");
    aceEditor.setFontSize(20);

    aceEditor.getSession().selection.on('changeCursor', updateCursorPosition);
    aceEditor.getSession().on('change', updateCharacterCount);
});

function updateCursorPosition() {
    var cursorPosition = aceEditor.getCursorPosition();
    document.getElementById('currentLine').textContent = cursorPosition.row + 1;
    document.getElementById('currentColumn').textContent = cursorPosition.column + 1;
}

function updateCharacterCount() {
    var characterCount = aceEditor.getValue().length;
    document.getElementById('charCount').textContent = characterCount;
}

function refreshDirectory() {
    fetch('?action=refresh&dir=' + encodeURIComponent(currentDir))
        .then(response => response.json())
        .then(data => {
            updateDirectoryView(data);
        })
        .catch(error => console.error('Error:', error));
}

function updateDirectoryView(contents) {

}

function createNewFolder() {
    let folderName = document.getElementById('newFolderName').value.trim();
    if (folderName === '') {
        alert('文件夹名称不能为空');
        return false;
    }
    return true;
}

function createNewFile() {
    let fileName = document.getElementById('newFileName').value.trim();
    if (fileName === '') {
        alert('文件名称不能为空');
        return false;
    }
    return true;
}

function showSearchModal() {
    const searchModal = new bootstrap.Modal(document.getElementById('searchModal'), {
        backdrop: 'static',
        keyboard: false
    });
    searchModal.show();
}

function searchFiles(event) {
   event.preventDefault();
   const currentLang = localStorage.getItem('preferred_language') || 'en';
   
   let noResultsMessage = '没有找到匹配的文件。';
   let moveButtonText = '移至';
   let searchErrorText = '搜索出错:';
   let errorMessage = '搜索时出错: ';
   
   if (currentLang === 'en') {
       noResultsMessage = 'No matching files found.';
       moveButtonText = 'Move to';
       searchErrorText = 'Search error:';
       errorMessage = 'Error searching: ';
   } else if (currentLang === 'zh-tw') {
       noResultsMessage = '沒有找到匹配的檔案。';
       moveButtonText = '移至';
       searchErrorText = '搜尋出錯:';
       errorMessage = '搜尋時出錯: ';
   }

   const searchTerm = document.getElementById('searchInput').value;
   const currentDir = '<?php echo $current_dir; ?>';

   fetch(`?action=search&dir=${encodeURIComponent(currentDir)}&term=${encodeURIComponent(searchTerm)}`)
       .then(response => response.json())
       .then(data => {
           const resultsDiv = document.getElementById('searchResults');
           resultsDiv.innerHTML = '';

           if (data.length === 0) {
               resultsDiv.innerHTML = `<p>${noResultsMessage}</p>`;
           } else {
               const ul = document.createElement('ul');
               ul.className = 'list-group';
               data.forEach(file => {
                   const li = document.createElement('li');
                   li.className = 'list-group-item d-flex justify-content-between align-items-center';
                   const fileSpan = document.createElement('span');
                   fileSpan.textContent = `${file.name} (${file.path})`;
                   li.appendChild(fileSpan);

                   const moveButton = document.createElement('button');
                   moveButton.className = 'btn btn-sm btn-primary';
                   moveButton.textContent = moveButtonText;
                   moveButton.onclick = function() {
                       let targetDir = file.dir || '/';
                       window.location.href = `?dir=${encodeURIComponent(targetDir)}`;
                       bootstrap.Modal.getInstance(document.getElementById('searchModal')).hide();
                   };
                   li.appendChild(moveButton);
                   ul.appendChild(li);
               });
               resultsDiv.appendChild(ul);
           }
       })
       .catch(error => {
           console.error(searchErrorText, error);
           alert(errorMessage + error.message);
       });
}

function closeModal(modalId) {
    if (modalId === 'editModal' && document.getElementById('aceEditor').style.display === 'block') {
        return;
    }
    document.getElementById(modalId).style.display = "none";
}

function changeEncoding() {
   const currentLang = localStorage.getItem('preferred_language') || 'en';
   let encoding = document.getElementById('encoding').value;
   let content = aceEditor.getValue();
 
   let encodingChangeMessage = '编码已更改为 {encoding}。实际转换将在保存时在服务器端进行。';

   if (currentLang === 'en') {
       encodingChangeMessage = 'Encoding changed to {encoding}. Actual conversion will be done on the server side when saving.';
   } else if (currentLang === 'zh-tw') {
       encodingChangeMessage = '編碼已更改為 {encoding}。實際轉換將在儲存時在伺服器端進行。';
   }

   if (encoding === 'ASCII') {
       content = content.replace(/[^\x00-\x7F]/g, "");
   } else if (encoding !== 'UTF-8') {
       let message = encodingChangeMessage.replace('{encoding}', encoding);
       alert(message);
   }

   aceEditor.setValue(content, -1);
}

function showEditModal(path) {
    document.getElementById('editPath').value = path;

    fetch('?action=get_content&dir=' + encodeURIComponent('<?php echo $current_dir; ?>') + '&path=' + encodeURIComponent(path))
        .then(response => {
            if (!response.ok) {
                throw new Error('无法获取文件内容: ' + response.statusText);
            }
            return response.text();
        })
        .then(data => {
            let content, encoding;
            try {
                const parsedData = JSON.parse(data);
                content = parsedData.content;
                encoding = parsedData.encoding;
            } catch (e) {
                content = data;
                encoding = 'Unknown';
            }

            document.getElementById('editContent').value = content;
            document.getElementById('editEncoding').value = encoding;

            if (!aceEditor) {
                aceEditor = ace.edit("aceEditorContainer");
                aceEditor.setTheme("ace/theme/monokai");
                aceEditor.setFontSize(DEFAULT_FONT_SIZE);
            } else {
                aceEditor.setFontSize(DEFAULT_FONT_SIZE);
            }

            aceEditor.setValue(content, -1);

            let fileExtension = path.split('.').pop().toLowerCase();
            let mode = getAceMode(fileExtension);
            aceEditor.session.setMode("ace/mode/" + mode);

            document.getElementById('encoding').value = encoding;
            document.getElementById('fontSize').value = DEFAULT_FONT_SIZE;

            showModal('editModal');
        })
        .catch(error => {
            console.error('编辑文件时出错:', error);
            alert('加载文件内容时出错: ' + error.message);
        });
    }

function setAceEditorTheme() {
    if (document.body.classList.contains('dark-mode')) {
        aceEditor.setTheme("ace/theme/monokai");
        document.getElementById('editorTheme').value = "ace/theme/monokai";
    } else {
        aceEditor.setTheme("ace/theme/github");
        document.getElementById('editorTheme').value = "ace/theme/github";
        }
    }

function changeFontSize() {
    let fontSize = document.getElementById('fontSize').value;
    aceEditor.setFontSize(fontSize);
    }

function changeEditorTheme() {
    let theme = document.getElementById('editorTheme').value;
    aceEditor.setTheme(theme);
    localStorage.setItem('preferredAceTheme', theme); 
    }

function formatCode() {
    let session = aceEditor.getSession();
    let beautify = ace.require("ace/ext/beautify");
    beautify.beautify(session);
}


function showChmodModal(path, currentPermissions) {
    document.getElementById('chmodPath').value = path;
    const permInput = document.getElementById('permissions');
    permInput.value = currentPermissions;
    
    setTimeout(() => {
        permInput.select();
        permInput.focus();
    }, 100);
    
    showModal('chmodModal');
}

function validateChmod() {
    const permissions = document.getElementById('permissions').value.trim();
    if (!/^[0-7]{3,4}$/.test(permissions)) {
        alert('请输入有效的权限值（三位或四位八进制数字，例如：644 或 0755）');
        return false;
    }
    
    const permNum = parseInt(permissions, 8);
    if (permNum > 0777) {
        alert('权限值不能超过 0777');
        return false;
    }
    
    return true;
}

document.getElementById('permissions').addEventListener('input', function(e) {
    this.value = this.value.replace(/[^0-7]/g, '');
    if (this.value.length > 4) {
        this.value = this.value.slice(0, 4);
    }
});

function getAceMode(extension) {
    const modeMap = {
        'js': 'javascript',
        'json': 'json',
        'py': 'python',
        'php': 'php',
        'html': 'html',
        'css': 'css',
        'json': 'json',
        'xml': 'xml',
        'md': 'markdown',
        'txt': 'text',
        'yaml': 'yaml',
        'yml': 'yaml'
    };
    return modeMap[extension] || 'text';
}

function saveEdit() {
    if (document.getElementById('aceEditor').style.display === 'block') {
        saveAceContent();
    }
    else {
        let content = document.getElementById('editContent').value;
        let encoding = document.getElementById('editEncoding').value;
        document.getElementById('editForm').submit();
    }
    return false;
}

function showEditModal(path) {
    document.getElementById('editPath').value = path;

    fetch('?action=get_content&dir=' + encodeURIComponent('<?php echo $current_dir; ?>') + '&path=' + encodeURIComponent(path))
        .then(response => {
            if (!response.ok) {
                throw new Error('无法获取文件内容: ' + response.statusText);
            }
            return response.text();
        })
        .then(content => {
            document.getElementById('editContent').value = content;

            if (!aceEditor) {
                aceEditor = ace.edit("aceEditorContainer");
                aceEditor.setTheme("ace/theme/monokai");
                aceEditor.setFontSize(DEFAULT_FONT_SIZE);
            } else {
                aceEditor.setFontSize(DEFAULT_FONT_SIZE);
            }

            aceEditor.setValue(content, -1);

            let fileExtension = path.split('.').pop().toLowerCase();
            let mode = getAceMode(fileExtension);
            aceEditor.session.setMode("ace/mode/" + mode);

            const formatJSONBtn = document.getElementById('formatJSONBtn');
            if (mode === 'json') {
                formatJSONBtn.style.display = 'inline-block';
            } else {
                formatJSONBtn.style.display = 'none';
            }

            document.getElementById('fontSize').value = DEFAULT_FONT_SIZE;

            showModal('editModal');
        })
        .catch(error => {
            console.error('编辑文件时出错:', error);
            alert('加载文件内容时出错: ' + error.message);
        });
}

function saveAceContent() {
    let content = aceEditor.getValue();
    let encoding = document.getElementById('encoding').value;
    document.getElementById('editContent').value = content;
    document.getElementById('editEncoding').value = encoding;
    document.getElementById('editContent').value = content;
}

function toggleSearch() {
    aceEditor.execCommand("find");
}

function setupSearchBox() {
    var searchBox = document.querySelector('.ace_search');
    if (!searchBox) return;

    searchBox.style.fontFamily = 'Arial, sans-serif';
    searchBox.style.fontSize = '14px';

    var buttons = searchBox.querySelectorAll('.ace_button');
    buttons.forEach(function(button) {
        button.style.padding = '4px 8px';
        button.style.marginLeft = '5px';
    });

    var inputs = searchBox.querySelectorAll('input');
    inputs.forEach(function(input) {
        input.style.padding = '4px';
        input.style.marginRight = '5px';
    });
}

function saveAceContent() {
    let content = aceEditor.getValue();
    let encoding = document.getElementById('encoding').value;
    document.getElementById('editContent').value = content;

    let encodingField = document.createElement('input');
    encodingField.type = 'hidden';
    encodingField.name = 'encoding';
    encodingField.value = encoding;
    document.getElementById('editModal').querySelector('form').appendChild(encodingField);
    document.getElementById('editModal').querySelector('form').submit();

}

function openAceEditor() {
    closeModal('editModal');
    document.body.classList.add('editing');
    document.getElementById('aceEditor').style.display = 'block';
    let content = document.getElementById('editContent').value;

    let fileExtension = document.getElementById('editPath').value.split('.').pop().toLowerCase();
    let mode = getAceMode(fileExtension);
    let session = aceEditor.getSession();
    session.setMode("ace/mode/" + mode);

    aceEditor.setOptions({
        enableBasicAutocompletion: true,
        enableLiveAutocompletion: true,
        enableSnippets: true
    });

    document.getElementById('validateJSONBtn').style.display = (mode === 'json') ? 'inline-block' : 'none';
    document.getElementById('validateYAMLBtn').style.display = (mode === 'yaml') ? 'inline-block' : 'none';

    if (mode === 'yaml') {
        session.setTabSize(2);
        session.setUseSoftTabs(true);
    }

    if (mode === 'json' || mode === 'yaml') {
        session.setOption("useWorker", false);
        if (session.$customWorker) {
            session.$customWorker.terminate();
        }
        session.$customWorker = createCustomWorker(session, mode);
        session.on("change", function() {
            session.$customWorker.postMessage({
                content: session.getValue(),
                mode: mode
            });
        });
        
        setupCustomIndent(session, mode);
    }
    setupCustomCompletion(session, mode);

    let savedTheme = localStorage.getItem('preferredAceTheme');
    if (savedTheme) {
        aceEditor.setTheme(savedTheme);
        document.getElementById('editorTheme').value = savedTheme;
    }

    aceEditor.setOptions({
        enableBasicAutocompletion: true,
        enableLiveAutocompletion: true,
        enableSnippets: true,
        showFoldWidgets: true,
        foldStyle: 'markbegin'
    });

    aceEditor.on("changeSelection", function() {
        setupSearchBox();
    });
    
    if (!aceEditor) {
        aceEditor = ace.edit("aceEditorContainer");
        aceEditor.setTheme("ace/theme/monokai");

        aceEditor.session.setUseWrapMode(true);
        aceEditor.setOption("wrap", true);
        aceEditor.getSession().setUseWrapMode(true);
       
    }
    
    aceEditor.setValue(content, -1);
    aceEditor.resize();
    aceEditor.setFontSize(DEFAULT_FONT_SIZE);
    document.getElementById('fontSize').value = DEFAULT_FONT_SIZE;
    aceEditor.focus();
    
    updateCursorPosition();
    updateCharacterCount();
    
    if (!document.getElementById('editorStatusBar')) {
        const statusBar = document.createElement('div');
        statusBar.id = 'editorStatusBar';
        statusBar.innerHTML = `
            <span id="cursorPosition">行: 1, 列: 1</span>
            <span id="characterCount">字符数: 0</span>
        `;
        document.getElementById('aceEditor').appendChild(statusBar);
    }
}

function updateCharacterCount() {
    var characterCount = aceEditor.getValue().length;
    document.getElementById('characterCount').textContent = '字符数: ' + characterCount;
}

editor.on("change", function() {
    updateCursorPosition();
});

function updateCursorPosition() {
    var cursorPosition = aceEditor.getCursorPosition();
    document.getElementById('cursorPosition').textContent = '行: ' + (cursorPosition.row + 1) + ', 列: ' + (cursorPosition.column + 1);
}

function validateJSON() {
    const currentLang = localStorage.getItem('preferred_language') || 'en';
    const editor = aceEditor;
    const content = editor.getValue();
    
    let validMessage = 'JSON 格式有效';
    let invalidMessage = '无效的 JSON 格式: ';
    
    if (currentLang === 'en') {
        validMessage = 'JSON format is valid';
        invalidMessage = 'Invalid JSON format: ';
    } else if (currentLang === 'zh-tw') {
        validMessage = 'JSON 格式有效';
        invalidMessage = '無效的 JSON 格式: ';
    }

    try {
        JSON.parse(content);
        alert(validMessage);
    } catch (e) {
        alert(invalidMessage + e.message);
    }
}

function validateYAML() {
    const currentLang = localStorage.getItem('preferred_language') || 'en';
    
    let validMessage = 'YAML 格式有效';
    let invalidMessage = '无效的 YAML 格式: ';
    let editorNotInitMessage = '编辑器未初始化';
    
    if (currentLang === 'en') {
        validMessage = 'YAML format is valid';
        invalidMessage = 'Invalid YAML format: ';
        editorNotInitMessage = 'Editor not initialized';
    } else if (currentLang === 'zh-tw') {
        validMessage = 'YAML 格式有效';
        invalidMessage = '無效的 YAML 格式: ';
        editorNotInitMessage = '編輯器未初始化';
    }

    if (aceEditor) {
        const content = aceEditor.getValue();
        try {
            jsyaml.load(content);
            alert(validMessage);
        } catch (e) {
            alert(invalidMessage + e.message);
        }
    } else {
        alert(editorNotInitMessage);
    }
}

function addErrorMarker(session, line, message) {
    var Range = ace.require("ace/range").Range;
    var marker = session.addMarker(new Range(line, 0, line, 1), "ace_error-marker", "fullLine");
    session.setAnnotations([{
        row: line,
        type: "error",
        text: message
    }]);
    return marker;
}

function closeAceEditor() {
    const currentLang = localStorage.getItem('preferred_language') || 'en';
    
    let confirmMessage = '确定要关闭编辑器吗？请确保已保存更改。'; 
    if (currentLang === 'en') {
        confirmMessage = 'Are you sure you want to close the editor? Please make sure you have saved your changes.';
    } else if (currentLang === 'zh-tw') {
        confirmMessage = '確定要關閉編輯器嗎？請確保已儲存更改。';
    } else if (currentLang === 'ko') {
        confirmMessage = '편집기를 닫으시겠습니까? 변경 사항이 저장되었는지 확인하세요.';
    } else if (currentLang === 'ar') {
        confirmMessage = 'هل أنت متأكد أنك تريد إغلاق المحرر؟ يرجى التأكد من حفظ التغييرات.';
    } else if (currentLang === 'ru') {
        confirmMessage = 'Вы уверены, что хотите закрыть редактор? Убедитесь, что вы сохранили изменения.';
    } else if (currentLang === 'de') {
        confirmMessage = 'Möchten Sie den Editor wirklich schließen? Bitte stellen Sie sicher, dass Sie Ihre Änderungen gespeichert haben.';
    } else if (currentLang === 'vi') {
        confirmMessage = 'Bạn có chắc chắn muốn đóng trình chỉnh sửa không? Hãy chắc chắn rằng bạn đã lưu các thay đổi của mình.';
    }
    
    if (confirm(confirmMessage)) {
        document.body.classList.remove('editing');
        document.getElementById('editContent').value = aceEditor.getValue();
        document.getElementById('aceEditor').style.display = 'none';
        showModal('editModal');
    }
}

function showRenameModal(oldName, oldPath) {
    document.getElementById('oldPath').value = oldPath;
    document.getElementById('newPath').value = oldName;
    
    const input = document.getElementById('newPath');
    const lastDotIndex = oldName.lastIndexOf('.');
    if(lastDotIndex > 0) {
        setTimeout(() => {
            input.setSelectionRange(0, lastDotIndex);
            input.focus();
        }, 100);
    } else {
        setTimeout(() => {
            input.select();
            input.focus();
        }, 100);
    }
    
    showModal('renameModal');
}

function validateRename() {
    const newPath = document.getElementById('newPath').value.trim();
    if (newPath === '') {
        alert('新名称不能为空');
        return false;
    }
    
    const invalidChars = /[<>:"/\\|?*]/g;
    if (invalidChars.test(newPath)) {
        alert('文件名不能包含以下字符: < > : " / \\ | ? *');
        return false;
    }
    
    return true;
}

</script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/ext-beautify.min.js"></script>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.4.12/ext-spellcheck.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0/dist/js/bootstrap.bundle.min.js"></script>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const dropZone = document.getElementById('dropZone');
    const fileInput = document.getElementById('fileInput');
    const uploadForm = document.getElementById('uploadForm');

    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        dropZone.addEventListener(eventName, preventDefaults, false);
        document.body.addEventListener(eventName, preventDefaults, false);
        document.getElementById('searchForm').addEventListener('submit', searchFiles);
    });

function preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
}
    ['dragenter', 'dragover'].forEach(eventName => {
        dropZone.addEventListener(eventName, highlight, false);
});

    ['dragleave', 'drop'].forEach(eventName => {
        dropZone.addEventListener(eventName, unhighlight, false);
});

function highlight(e) {
    dropZone.classList.add('drag-over');
}

function unhighlight(e) {
    dropZone.classList.remove('drag-over');
}
    dropZone.addEventListener('drop', handleDrop, false);

function handleDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;

    if (files.length > 0) {
        fileInput.files = files;
        uploadForm.submit();
    }
}

fileInput.addEventListener('change', function() {
    if (this.files.length > 0) {
        uploadForm.submit();
    }
});

dropZone.addEventListener('click', function() {
    fileInput.click();
    });
});

function showUploadArea() {
    document.getElementById('uploadArea').style.display = 'block';
}

function hideUploadArea() {
    document.getElementById('uploadArea').style.display = 'none';
}

document.addEventListener('DOMContentLoaded', (event) => {
    const themeToggle = document.getElementById('themeToggle');
    const body = document.body;
    const icon = themeToggle.querySelector('i');

    const currentTheme = localStorage.getItem('theme');
    if (currentTheme) {
        body.classList.add(currentTheme);
        if (currentTheme === 'dark-mode') {
            icon.classList.replace('fa-moon', 'fa-sun');
        }
    }

    themeToggle.addEventListener('click', () => {
        if (body.classList.contains('dark-mode')) {
            body.classList.remove('dark-mode');
            icon.classList.replace('fa-sun', 'fa-moon');
            localStorage.setItem('theme', 'light-mode');
        } else {
            body.classList.add('dark-mode');
            icon.classList.replace('fa-moon', 'fa-sun');
            localStorage.setItem('theme', 'dark-mode');
        }
    });
});

function previewFile(path, extension) {
    const previewContainer = document.getElementById('previewContainer');
    previewContainer.innerHTML = '';
    
    let cleanPath = path.replace(/\/+/g, '/');
    if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
    }
    
    const fullPath = `?preview=1&path=${encodeURIComponent(cleanPath)}`;
    console.log('Original path:', path);
    console.log('Cleaned path:', cleanPath);
    console.log('Full path:', fullPath);
    
    switch(extension.toLowerCase()) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
            const img = document.createElement('img');
            img.src = fullPath;
            img.onerror = function() {
                previewContainer.innerHTML = '无法加载图片: ' + cleanPath;
            };
            previewContainer.appendChild(img);
            break;
            
        case 'svg':
            fetch(fullPath)
                .then(response => {
                    if (!response.ok) {
                        throw new Error('HTTP error! status: ' + response.status);
                    }
                    return response.text();
                })
                .then(svgContent => {
                    previewContainer.innerHTML = svgContent;
                })
                .catch(error => {
                    previewContainer.innerHTML = '无法加载SVG文件: ' + error.message;
                    console.error('加载SVG失败:', error);
                });
            break;
            
        case 'mp3':
            const audio = document.createElement('audio');
            audio.controls = true;
            audio.src = fullPath;
            audio.onerror = function() {
                previewContainer.innerHTML = '无法加载音频: ' + cleanPath;
            };
            previewContainer.appendChild(audio);
            break;
            
        case 'mp4':
            const video = document.createElement('video');
            video.controls = true;
            video.style.maxWidth = '100%';
            video.src = fullPath;
            video.onerror = function() {
                previewContainer.innerHTML = '无法加载视频: ' + cleanPath;
            };
            previewContainer.appendChild(video);
            break;
    }
    
    showModal('previewModal');
}

function setupCustomIndent(session, mode) {
   session.setTabSize(2);
   session.setUseSoftTabs(true);
   
   session.on("change", function(delta) {
       if (delta.action === "insert" && delta.lines.length === 1 && delta.lines[0] === "") {
           var cursor = session.selection.getCursor();
           var line = session.getLine(cursor.row - 1);
           var indent = line.match(/^\s*/)[0];

           if (mode === 'yaml') {
               if (line.trim().startsWith('- ')) {
                   setTimeout(function() {
                       session.insert({row: cursor.row, column: 0}, indent + "- ");
                   }, 0);
                   return;
               } else if (line.trim().endsWith(':')) {
                   indent += "  ";
               } else if (line.trim().match(/^-\s*\w+/)) {
                   indent = line.match(/^\s*/)[0];
               }
           } else if (mode === 'json') {
               if (line.trim().endsWith('{') || line.trim().endsWith('[')) {
                   indent += "  ";
               }
           }

           session.insert({row: cursor.row, column: 0}, indent);

           if (mode === 'yaml' && line.trim().startsWith('- ')) {
               var newPosition = session.selection.getCursor();
               session.selection.moveTo(newPosition.row, indent.length + 2);
           }
       }
   });

   if (mode === 'yaml') {
       var langTools = ace.require("ace/ext/language_tools");
       var yamlCompleter = {
           getCompletions: function(editor, session, pos, prefix, callback) {
               var line = session.getLine(pos.row);
               var completions = [];

               if (line.trim().length === 0) {
                   completions = [
                       {
                           caption: "- list item",
                           snippet: "- ",
                           meta: "list item"
                       },
                       {
                           caption: "key: value",
                           snippet: "${1:key}: ${2:value}",
                           meta: "key value"
                       }
                   ];
               }

               callback(null, completions);
           }
       };
       langTools.addCompleter(yamlCompleter);
   }
}

if (!aceEditor) {
   aceEditor = ace.edit("aceEditorContainer");
   aceEditor.setTheme("ace/theme/monokai");
   aceEditor.setFontSize(DEFAULT_FONT_SIZE);-

   aceEditor.setOptions({
       enableBasicAutocompletion: true,
       enableLiveAutocompletion: true,
       enableSnippets: true
   });

   var session = aceEditor.getSession();
   var mode = session.getMode().$id;
   
   if (mode.includes('yaml')) {
       setupCustomIndent(session, 'yaml');
   } else if (mode.includes('json')) {
       setupCustomIndent(session, 'json');
   }
}

function setupCustomCompletion(session, mode) {
    var langTools = ace.require("ace/ext/language_tools");
    var customCompleter = {
        getCompletions: function(editor, session, pos, prefix, callback) {
            var line = session.getLine(pos.row);
            var completions = [];

            if (mode === 'json') {
                if (line.trim().length === 0 || line.trim().endsWith(',')) {
                    completions = [
                        {caption: "\"\":", snippet: "\"${1:key}\": ${2:value}", meta: "key-value pair"},
                        {caption: "{}", snippet: "{\n  $0\n}", meta: "object"},
                        {caption: "[]", snippet: "[\n  $0\n]", meta: "array"}
                    ];
                }
            } else if (mode === 'yaml') {
                if (line.trim().length === 0) {
                    completions = [
                        {caption: "key:", snippet: "${1:key}: ${2:value}", meta: "key-value pair"},
                        {caption: "- ", snippet: "- ${1:item}", meta: "list item"},
                        {caption: "---", snippet: "---\n$0", meta: "document start"}
                    ];
                }
            }

            callback(null, completions);
        }
    };

    langTools.addCompleter(customCompleter);
}

function createJsonWorker(session) {
    var worker = new Worker(URL.createObjectURL(new Blob([`
        self.onmessage = function(e) {
            var value = e.data;
            try {
                JSON.parse(value);
                self.postMessage({
                    isValid: true
                });
            } catch (e) {
                var match = e.message.match(/at position (\\d+)/);
                var pos = match ? parseInt(match[1], 10) : 0;
                var lines = value.split(/\\n/);
                var total = 0;
                var line = 0;
                var ch;
                for (var i = 0; i < lines.length; i++) {
                    total += lines[i].length + 1;
                    if (total > pos) {
                        line = i;
                        ch = pos - (total - lines[i].length - 1);
                        break;
                    }
                }
                self.postMessage({
                    isValid: false,
                    line: line,
                    ch: ch,
                    message: e.message
                });
            }
        };
    `], { type: "text/javascript" })));

    worker.onmessage = function(e) {
        session.clearAnnotations();
        if (session.$errorMarker) {
            session.removeMarker(session.$errorMarker);
        }
        if (!e.data.isValid) {
            session.$errorMarker = addErrorMarker(session, e.data.line, e.data.message);
        }
    };

    return worker;
}

function addErrorMarker(session, line, message) {
    var Range = ace.require("ace/range").Range;
    var marker = session.addMarker(new Range(line, 0, line, 1), "ace_error-marker", "fullLine");
    session.setAnnotations([{
        row: line,
        column: 0,
        text: message,
        type: "error"
    }]);
    return marker;
}

function addErrorMarker(session, line, message) {
    var Range = ace.require("ace/range").Range;
    var marker = session.addMarker(new Range(line, 0, line, 1), "ace_error-marker", "fullLine");
    session.setAnnotations([{
        row: line,
        column: 0,
        text: message,
        type: "error"
    }]);
    return marker;
}

function createCustomWorker(session, mode) {
    var worker = new Worker(URL.createObjectURL(new Blob([`
        importScripts('https://cdnjs.cloudflare.com/ajax/libs/js-yaml/4.1.0/js-yaml.min.js');
        self.onmessage = function(e) {
            var content = e.data.content;
            var mode = e.data.mode;
            try {
                if (mode === 'json') {
                    JSON.parse(content);
                } else if (mode === 'yaml') {
                    jsyaml.load(content);
                }
                self.postMessage({
                    isValid: true
                });
            } catch (e) {
                var line = 0;
                var column = 0;
                var message = e.message;

                if (mode === 'json') {
                    var match = e.message.match(/at position (\\d+)/);
                    if (match) {
                        var position = parseInt(match[1], 10);
                        var lines = content.split('\\n');
                        var currentLength = 0;
                        for (var i = 0; i < lines.length; i++) {
                            currentLength += lines[i].length + 1; // +1 for newline
                            if (currentLength >= position) {
                                line = i;
                                column = position - (currentLength - lines[i].length - 1);
                                break;
                            }
                        }
                    }
                } else if (mode === 'yaml') {
                    if (e.mark) {
                        line = e.mark.line;
                        column = e.mark.column;
                    }
                }

                self.postMessage({
                    isValid: false,
                    line: line,
                    column: column,
                    message: message
                });
            }
        };
    `], { type: "text/javascript" })));

    worker.onmessage = function(e) {
        session.clearAnnotations();
        if (session.$errorMarker) {
            session.removeMarker(session.$errorMarker);
        }
        if (!e.data.isValid) {
            session.$errorMarker = addErrorMarker(session, e.data.line, e.data.column, e.data.message);
        }
    };

    return worker;
}

function formatCode() {
   const currentLang = localStorage.getItem('preferred_language') || 'en';
   const editor = aceEditor;
   const session = editor.getSession();
   const cursorPosition = editor.getCursorPosition();
   
   let content = editor.getValue();
   let formatted;
   
   const mode = session.getMode().$id;
   
   let successMessage = '代码已成功格式化';
   let jsonErrorMessage = '无法格式化：无效的 JSON 格式';
   let yamlErrorMessage = '无法格式化：无效的 YAML 格式'; 
   let formatErrorMessage = '格式化时发生错误：';

   if (currentLang === 'en') {
       successMessage = 'Code has been successfully formatted';
       jsonErrorMessage = 'Unable to format: Invalid JSON format';
       yamlErrorMessage = 'Unable to format: Invalid YAML format';
       formatErrorMessage = 'Error formatting code: ';
   } else if (currentLang === 'zh-tw') {
       successMessage = '程式碼已成功格式化';
       jsonErrorMessage = '無法格式化：無效的 JSON 格式';
       yamlErrorMessage = '無法格式化：無效的 YAML 格式';
       formatErrorMessage = '格式化時發生錯誤：';
   }

   try {
       if (mode.includes('javascript')) {
           formatted = js_beautify(content, {
               indent_size: 2,
               space_in_empty_paren: true
           });
       } else if (mode.includes('json')) {
           JSON.parse(content); 
           formatted = JSON.stringify(JSON.parse(content), null, 2);
       } else if (mode.includes('yaml')) {
           const obj = jsyaml.load(content); 
           formatted = jsyaml.dump(obj, {
               indent: 2,
               lineWidth: -1,
               noRefs: true,
               sortKeys: false
           });
       } else {
           formatted = js_beautify(content, {
               indent_size: 2,
               space_in_empty_paren: true
           });
       }
       
       editor.setValue(formatted);
       editor.clearSelection();
       editor.moveCursorToPosition(cursorPosition);
       editor.focus();
       
       session.clearAnnotations();
       if (session.$errorMarker) {
           session.removeMarker(session.$errorMarker);
       }
       
       showNotification(successMessage, 'success');
   } catch (e) {
       let errorMessage;
       if (mode.includes('json')) {
           errorMessage = jsonErrorMessage;
       } else if (mode.includes('yaml')) {
           errorMessage = yamlErrorMessage;
       } else {
           errorMessage = formatErrorMessage + e.message;
       }
       showNotification(errorMessage, 'error');
       
       if (e.mark) {
           session.$errorMarker = addErrorMarker(session, e.mark.line, e.message);
       }
   }
}

function addErrorMarker(session, line, column, message) {
    var Range = ace.require("ace/range").Range;
    var marker = session.addMarker(new Range(line, 0, line, 1), "ace_error-marker", "fullLine");
    session.setAnnotations([{
        row: line,
        column: column,
        text: message,
        type: "error"
    }]);
    return marker;
}

function showNotification(message, type) {
   const currentLang = localStorage.getItem('preferred_language') || 'en';
   
   let errorPrefix = '错误: ';
   
   if (currentLang === 'en') {
       errorPrefix = 'Error: ';
   } else if (currentLang === 'zh-tw') {
       errorPrefix = '錯誤: ';
   }
   
   if (type === 'error') {
       alert(errorPrefix + message);
   } else {
       alert(message);
   }
}

document.getElementById('selectAllCheckbox').addEventListener('change', function() {
    var checkboxes = document.getElementsByClassName('file-checkbox');
    for (var i = 0; i < checkboxes.length; i++) {
        checkboxes[i].checked = this.checked;
    }
});

function selectAll() {
    var checkboxes = document.getElementsByClassName('file-checkbox');
    for (var i = 0; i < checkboxes.length; i++) {
        checkboxes[i].checked = true;
    }
    document.getElementById('selectAllCheckbox').checked = true;
}

function reverseSelection() {
    var checkboxes = document.getElementsByClassName('file-checkbox');
    for (var i = 0; i < checkboxes.length; i++) {
        checkboxes[i].checked = !checkboxes[i].checked;
    }
    updateSelectAllCheckbox();
}

function updateSelectAllCheckbox() {
    var checkboxes = document.getElementsByClassName('file-checkbox');
    var allChecked = true;
    for (var i = 0; i < checkboxes.length; i++) {
        if (!checkboxes[i].checked) {
            allChecked = false;
            break;
        }
    }
    document.getElementById('selectAllCheckbox').checked = allChecked;
}

function deleteSelected() {
   const currentLang = localStorage.getItem('preferred_language') || 'en';
   
   let selectMessage = '请至少选择一个文件或文件夹进行删除。';
   let confirmMessage = '确定要删除选中的 {count} 个文件或文件夹吗？这个操作不可撤销。';
   
   if (currentLang === 'en') {
       selectMessage = 'Please select at least one file or folder to delete.';
       confirmMessage = 'Are you sure you want to delete the selected {count} files or folders? This action cannot be undone.';
   } else if (currentLang === 'zh-tw') {
       selectMessage = '請至少選擇一個檔案或資料夾進行刪除。';
       confirmMessage = '確定要刪除選中的 {count} 個檔案或資料夾嗎？此操作無法撤銷。';
   }

   var selectedPaths = [];
   var checkboxes = document.getElementsByClassName('file-checkbox');
   for (var i = 0; i < checkboxes.length; i++) {
       if (checkboxes[i].checked) {
           selectedPaths.push(checkboxes[i].dataset.path);
       }
   }

   if (selectedPaths.length === 0) {
       alert(selectMessage);
       return;
   }

   confirmMessage = confirmMessage.replace('{count}', selectedPaths.length);

   if (confirm(confirmMessage)) {
       var form = document.createElement('form');
       form.method = 'post';
       form.style.display = 'none';

       var actionInput = document.createElement('input');
       actionInput.type = 'hidden';
       actionInput.name = 'action';
       actionInput.value = 'delete_selected';
       form.appendChild(actionInput);

       for (var i = 0; i < selectedPaths.length; i++) {
           var pathInput = document.createElement('input');
           pathInput.type = 'hidden';
           pathInput.name = 'selected_paths[]';
           pathInput.value = selectedPaths[i];
           form.appendChild(pathInput);
       }

       document.body.appendChild(form);
       form.submit();
   }
}

window.addEventListener("load", function() {
    aceEditor = ace.edit("aceEditorContainer");
    aceEditor.setTheme("ace/theme/monokai");
    aceEditor.setFontSize(20);

    aceEditor.getSession().selection.on('changeCursor', updateCursorPosition);
    aceEditor.getSession().on('change', updateCharacterCount);

    aceEditor.spellcheck = true;
    aceEditor.commands.addCommand({
        name: "spellcheck",
        bindKey: { win: "Ctrl-.", mac: "Command-." },
        exec: function(editor) {
            editor.execCommand("showSpellCheckDialog");
        }
    });
});

aceEditor.on("spell_check", function(errors) {
    errors.forEach(function(error) {
        var Range = ace.require("ace/range").Range;
        var marker = aceEditor.getSession().addMarker(
            new Range(error.line, error.column, error.line, error.column + error.length),
            "ace_error-marker",
            "typo"
        );
        aceEditor.getSession().setAnnotations([{
            row: error.line,
            column: error.column,
            text: error.message,
            type: "error"
        }]);

        var suggestions = error.suggestions;
        if (suggestions.length > 0) {
            var correctSpelling = suggestions[0];
            aceEditor.getSession().replace(
                new Range(error.line, error.column, error.line, error.column + error.length),
                correctSpelling
            );
        }
    });
});

function formatJSON() {
    const editor = aceEditor;
    const session = editor.getSession();
    const cursorPosition = editor.getCursorPosition();
    
    let content = editor.getValue();
    
    try {
        JSON.parse(content);
        
        let formatted = JSON.stringify(JSON.parse(content), null, 2);
        
        editor.setValue(formatted);
        editor.clearSelection();
        editor.moveCursorToPosition(cursorPosition);
        editor.focus();

        session.clearAnnotations();
        if (session.$errorMarker) {
            session.removeMarker(session.$errorMarker);
        }

        showNotification('JSON 已成功格式化', 'success');
    } catch (e) {
        let errorMessage = '无法格式化：无效的 JSON 格式';
        showNotification(errorMessage, 'error');

        if (e.message.includes('at position')) {
            let position = parseInt(e.message.match(/at position (\d+)/)[1]);
            let lines = content.substr(0, position).split('\n');
            let line = lines.length - 1;
            let column = lines[lines.length - 1].length;
            session.$errorMarker = addErrorMarker(session, line, column, e.message);
        }
    }
}

aceEditor.getSession().on("change", function(delta) {
    if (delta.action === "insert" && delta.lines.length === 1 && delta.lines[0] === "") {
        var cursor = aceEditor.getCursorPosition();
        var line = aceEditor.getSession().getLine(cursor.row - 1);
        var indent = line.match(/^\s*/)[0];
        aceEditor.getSession().insert({ row: cursor.row, column: 0 }, indent);
    }
});

aceEditor.on("copy", function() {
    var selectedText = aceEditor.getSelectedText();
    if (selectedText) {
        var formattedText = formatAllText(aceEditor.getValue());
        navigator.clipboard.writeText(formattedText);
    }
});

function formatAllText(text) {
    var lines = text.split("\n");
    var longestLine = 0;
    for (var i = 0; i < lines.length; i++) {
        if (lines[i].length > longestLine) {
            longestLine = lines[i].length;
        }
    }

    var formattedLines = [];
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        var padding = longestLine - line.length;
        formattedLines.push(" ".repeat(padding) + line);
    }

    return formattedLines.join("\n");
}

</script>
<style>
#fullscreenToggle {
    position: fixed;
    top: 10px;
    right: 10px;
    z-index: 1000;
    background-color: #007bff;
    color: white;
    border: none;
    padding: 3px 10px;
    border-radius: 5px;
    cursor: pointer;
}
</style>

<script>
document.addEventListener("DOMContentLoaded", function() {
    const fullscreenToggle = document.createElement('button');
    fullscreenToggle.id = 'fullscreenToggle';
   
    const currentLang = localStorage.getItem('preferred_language') || 'en';
   
    if(currentLang === 'zh') {
        fullscreenToggle.textContent = '全屏';
    } else if(currentLang === 'zh-tw') {
        fullscreenToggle.textContent = '全螢幕';
    } else if(currentLang === 'ko') {
        fullscreenToggle.textContent = '전체 화면';
    } else if(currentLang === 'ar') {
        fullscreenToggle.textContent = 'شاشة كاملة';
    } else if(currentLang === 'ru') {
        fullscreenToggle.textContent = 'Полный экран';
    } else if(currentLang === 'de') {
        fullscreenToggle.textContent = 'Vollbild';
    } else if(currentLang === 'vi') {
        fullscreenToggle.textContent = 'Toàn màn hình';
    } else {
        fullscreenToggle.textContent = 'Fullscreen';
    }
   
    document.body.appendChild(fullscreenToggle);

    fullscreenToggle.onclick = function() {
        if (!document.fullscreenElement) {
            document.documentElement.requestFullscreen();
        } else {
            if (document.exitFullscreen) {
                document.exitFullscreen();
            }
        }
    };

    const languageSwitcher = document.getElementById('languageSwitcher');
    if(languageSwitcher) {
        languageSwitcher.value = currentLang;
       
        languageSwitcher.addEventListener('change', function() {
            const lang = this.value;
            localStorage.setItem('preferred_language', lang);
           
            if(lang === 'zh') {
                fullscreenToggle.textContent = '全屏';
            } else if(lang === 'zh-tw') {
                fullscreenToggle.textContent = '全螢幕';
            } else if(lang === 'ko') {
                fullscreenToggle.textContent = '전체 화면';
            } else if(lang === 'ar') {
                fullscreenToggle.textContent = 'شاشة كاملة';
            } else if(lang === 'ru') {
                fullscreenToggle.textContent = 'Полный экран';
            } else if(lang === 'de') {
                fullscreenToggle.textContent = 'Vollbild';
            } else if(lang === 'vi') {
                fullscreenToggle.textContent = 'Toàn màn hình';
            } else {
                fullscreenToggle.textContent = 'Fullscreen';
            }
        });
    }
});
</script>

</body>
</html>
