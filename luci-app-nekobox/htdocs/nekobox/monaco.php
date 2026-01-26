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
    $path = preg_replace('/\/+/', '/', $_GET['path']);
    $preview_path = realpath($root_dir . '/' . $path);
    if ($preview_path && strpos($preview_path, realpath($root_dir)) === 0) {
        if (!file_exists($preview_path)) {
            header('HTTP/1.0 404 Not Found');
            echo "File not found.";
            exit;
        }
        $ext = strtolower(pathinfo($preview_path, PATHINFO_EXTENSION));
        $mime_types = [
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png' => 'image/png',
            'gif' => 'image/gif',
            'svg' => 'image/svg+xml',
            'bmp' => 'image/bmp',
            'webp' => 'image/webp',
            'mp3' => 'audio/mpeg',
            'wav' => 'audio/wav',
            'ogg' => 'audio/ogg',
            'flac' => 'audio/flac',
            'mp4' => 'video/mp4',
            'webm' => 'video/webm',
            'avi' => 'video/x-msvideo',
            'mkv' => 'video/x-matroska'
        ];
        $mime_type = isset($mime_types[$ext]) ? $mime_types[$ext] : 'application/octet-stream';
        header('Content-Type: ' . $mime_type);
        header('Content-Length: ' . filesize($preview_path));
        readfile($preview_path);
        exit;
    } else {
        header('HTTP/1.0 404 Not Found');
        echo "Invalid path.";
        exit;
    }
}

if (isset($_GET['action']) && $_GET['action'] === 'refresh') {
    $contents = getDirectoryContents($current_path);
    echo json_encode($contents);
    exit;
}

if (isset($_POST['action']) && $_POST['action'] === 'delete_selected') {
    if (isset($_POST['selected_paths']) && is_array($_POST['selected_paths'])) {
        foreach ($_POST['selected_paths'] as $path) {
            deleteItem($current_path . $path);
        }
        header("Location: ?dir=" . urlencode($current_dir));
        exit;
    }
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
        echo 'File does not exist or is not readable.';
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
                    echo "<script>alert('Error: Unable to save the file.');</script>";
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
                    chmod($new_file_path, 0644);
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
    
    if (!is_dir($destination)) {
        @mkdir($destination, 0755, true);
    }
    
    if (!empty($_FILES["upload"])) {
        foreach ($_FILES["upload"]["error"] as $key => $error) {
            if ($error == UPLOAD_ERR_OK) {
                $tmp_name = $_FILES["upload"]["tmp_name"][$key];
                $name = basename($_FILES["upload"]["name"][$key]);
                $target_file = rtrim($destination, '/') . '/' . $name;
                
                if (move_uploaded_file($tmp_name, $target_file)) {
                    $uploaded_files[] = $name;
                    chmod($target_file, 0644);
                } else {
                    $errors[] = "Failed to upload $name.";
                }
            } else {
                $errors[] = "Upload error for file $key: " . getUploadError($error);
            }
        }
    }
    
    if (!empty($errors)) {
        return ['error' => implode("\n", $errors)];
    }
    if (!empty($uploaded_files)) {
        return ['success' => implode(", ", $uploaded_files)];
    }
    return ['error' => 'No files were uploaded'];
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
                $mtime = date("Y-m-d H:i:s", filemtime($path));
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
                'dir' => dirname($relativePath) === '.' ? '' : dirname($relativePath),
                'name' => $file->getFilename()
            );
        }
    }

    return $results;
}
?>

<title>Monaco - Nekobox</title>
<?php include './ping.php'; ?>
<link rel="icon" href="./assets/img/nekobox.png">
<script src="./assets/js/js-yaml.min.js"></script>

<style>
#monacoEditor {
	position: fixed;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	display: none;
	flex-direction: column;
	box-sizing: border-box;
	background-color: var(--card-bg);
	z-index: 1100;
}

#monacoEditorContainer {
	flex: 1;
	width: 90%;
	margin: 0 auto;
	min-height: 0;
	border-radius: 4px;
	overflow: hidden;
	margin-top: 40px;
	z-index: 1100;
}

#editorControls {
	display: flex;
	align-items: center;
	padding: 8px 16px;
	background-color: var(--card-bg);
	width: 100%;
	position: fixed;
	top: 0;
	z-index: 1101;
	box-sizing: border-box;
	border-bottom: 1px solid #ccc;
}

#fontSize, #editorTheme {
	display: inline-block;
	width: auto;
	cursor: pointer;
	font-family: inherit;
	font-size: 0.875rem;
	font-weight: 500;
	color: #ffffff !important;
	background-color: var(--accent-color) !important;
        border-radius: var(--radius);
	border: 1px solid var(--border-color);
	border-radius: 0.25rem;
	padding: 0.375rem 1.75rem 0.375rem 0.75rem;
	box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
	transition: all 0.2s ease;
}

.editor-widget.find-widget {
	display: flex !important;
	flex-direction: column !important;
	height: auto !important;
	padding: 6px !important;
	gap: 6px !important;
}

.editor-widget.find-widget .find-part {
	display: flex !important;
	flex-direction: column !important;
	gap: 4px !important;
}

.editor-widget.find-widget .monaco-findInput {
	order: 1 !important;
	width: 100% !important;
}

.editor-widget.find-widget .replace-part {
	order: 2 !important;
	display: flex !important;
	flex-direction: column !important;
	gap: 4px !important;
}

.editor-widget.find-widget .replace-part .monaco-findInput {
	width: 100% !important;
}

.editor-widget.find-widget .controls {
	order: 3 !important;
	display: flex !important;
	gap: 6px !important;
	margin-top: 4px !important;
	flex-wrap: wrap !important;
}

.editor-widget.find-widget .find-actions {
	order: 4 !important;
	display: flex !important;
	gap: 8px !important;
	margin-top: 4px !important;
	align-items: center !important;
}

.editor-widget.find-widget .replace-actions {
	order: 5 !important;
	display: flex !important;
	gap: 8px !important;
	margin-top: 4px !important;
	align-items: center !important;
}

.editor-widget.find-widget .toggle.left {
	order: -1 !important;
	display: inline-flex !important;
	margin-right: 8px !important;
	align-self: flex-start !important;
}

.editor-widget.find-widget .matchesCount {
	display: inline-block !important;
	margin-right: 8px !important;
}

.editor-widget.find-widget .button {
	display: inline-flex !important;
}

.editor-widget.find-widget:not(.replaceToggled) .replace-part .monaco-findInput {
	display: none !important;
}

.editor-widget.find-widget.replaceToggled .replace-part .monaco-findInput {
	display: block !important;
}

.editor-widget.find-widget .replace-actions {
	display: flex !important;
	gap: 8px !important;
	margin-top: 4px !important;
}

.find-actions {
	display: flex !important;
	align-items: center !important;
	gap: 8px !important;
}

.find-actions .codicon-widget-close {
	order: 1 !important;
}

.find-actions .codicon-find-replace {
	order: 2 !important;
	margin-left: 8px !important;
}

.find-actions .codicon-find-replace-all {
	order: 3 !important;
}

.replace-actions {
	display: none !important;
}

.find-actions .button.disabled {
	opacity: 0.5 !important;
	pointer-events: none !important;
} 

#leftControls {
	display: flex;
	align-items: center;
	gap: 8px;
	flex: 1;
	overflow-x: auto;
	white-space: nowrap;
}

#statusInfo {
	display: flex;
	align-items: center;
	gap: 12px;
	font-size: 16px;
	color: var(--text-primary);
	margin-left: auto;
	padding-left: 20px;
	font-weight: bold;
}

#currentLine, 
#currentColumn, 
#charCount {
	font-size: 17px;
	color: var(--text-primary);
	font-weight: bolder;
}

.ace_editor {
	width: 100% !important;
	height: 100% !important;
}

@media (max-width: 768px) {
	#aceEditorContainer {
		width: 98%;
		margin-top: 40px;
		margin-bottom: 0;
	}

	#editorControls {
		width: 100%;
		padding: 6px 10px;
		flex-wrap: nowrap;
		overflow-x: auto;
	}

	#editorControls select,
        #editorControls button {
		height: 28px;
		font-size: 12px;
		padding: 4px 8px;
		margin-right: 8px;
		min-width: 55px;
	}

	#statusInfo {
		gap: 8px;
		font-size: 11px;
		flex-shrink: 0;
	}
}

.action-grid {
	display: grid;
	grid-template-columns: repeat(5, 36px);
	column-gap: 15px;
	overflow: visible;
	justify-content: start;
}

.action-btn {
	width: 36px;
	height: 36px;
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 0;
	border: none;
	border-radius: 6px;
	transition: background-color 0.2s ease, box-shadow 0.2s ease;
}

.placeholder {
	width: 36px;
	height: 0;
}

.ace_error_line {
	background-color: rgba(255, 0, 0, 0.2) !important;
	position: absolute;
	z-index: 1;
}

.upload-container {
	margin-bottom: 20px;
}

.upload-area {
	margin-top: 10px;
}

.upload-drop-zone {
	display: flex;
	flex-direction: column;
	justify-content: center;
	align-items: stretch;
	border: 2px dashed #ccc !important;
	border-radius: 8px;
	padding: 25px;
	background: #f8f9fa;
	transition: all 0.3s ease;
	cursor: pointer;
	min-height: 150px;
	text-align: center;
}

.upload-drop-zone .upload-icon {
	align-self: center;
	margin-bottom: 1rem;
	font-size: 50px;
	color: #6c757d;
	transition: all 0.3s ease;
}

.upload-drop-zone.drag-over {
	background: #e9ecef;
	border-color: #0d6efd;
}

.upload-drop-zone:hover .upload-icon {
	color: #0d6efd;
	transform: scale(1.1);
}

.table td:nth-child(3),  
.table td:nth-child(4),  
.table td:nth-child(5),
.table td:nth-child(6),  
.table td:nth-child(7) {
	color: var(--text-primary);
}

.btn-toolbar .btn-group .btn.btn-outline-secondary {
	color: var(--text-primary);
	border-color: var(--text-primary);
}

.btn-toolbar .btn-group .btn.btn-outline-secondary i {
	color: var(--text-primary) !important;
}

.upload-instructions,
.form-text[data-translate],
label.form-label[data-translate] {
	color: var(--text-primary) !important;
}

.table th, .table td {
	text-align: center !important;
}

.container-sm {
	max-width: 100%;
	margin: 0 auto;
}

table.table tbody tr:nth-child(odd) td {
	color: var(--text-primary) !important;
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

#statusInfo {
	display: flex;
	align-items: center;
	gap: 1.5rem;
}

#lineColumnDisplay,
#charCountDisplay {
	color: var(--text-primary);
	font-size: 1.1rem;
}

#lineColumnDisplay::before,
#charCountDisplay::before {
	font-size: 1.3rem;
}

#lineColumnDisplay .number,
#charCountDisplay .number {
	font-size: 1.3rem;
}

table.table tbody tr td.folder-icon,
table.table tbody tr td.file-icon {
	text-align: left !important;
}

.section-wrapper {
	padding-left: 1rem;
	padding-right: 1rem;
}

#siteLogo {
        max-height: 50px;
        height: auto;
        margin-top: -25px;
}

#previewModal .modal-content {
	padding: 0;
	border: none;
	overflow: hidden;
}

#previewModal .modal-header {
	border: none;
}

#previewModal .modal-footer {
	border: none;
	padding: 0.75rem 1rem;
	margin: 0;
}

#previewModal .modal-body {
	background-color: #000;
	padding: 0;
	margin: 0;
	width: 100%;
	display: block;
	min-height: 0;
}

#previewModal .modal-body img {
	max-width: 100%;
	max-height: 80vh;
	display: block;
	margin: 0 auto;
}

#previewModal .modal-body video {
	width: 100%;
	height: auto;
	max-height: 80vh;
	margin: 0;
	padding: 0;
	border: none;
	display: block;
	background-color: #000;
}

#previewModal .modal-body audio {
	width: 100%;
	max-width: 600px;
	display: block;
	margin: 0 auto;
	margin-top: 40px;
	margin-bottom: 40px;
}

#previewModal .modal-body p {
	text-align: center;
	margin: 0;
}

#fileConfirmation .alert {
	border: 2px dashed #ccc !important;
	padding: 1rem;
	border-radius: 0.5rem;
	box-shadow: 0 2px 6px rgba(0,0,0,0.08);
	background-color: #f8f9fa;
	text-align: left;
}

#fileConfirmation #fileList {
	max-height: 180px;
	overflow-y: auto;
}

#fileConfirmation #fileList span.text-truncate {
	width: auto;
	overflow: visible;
	text-overflow: unset;
	white-space: nowrap;
	font-weight: 500;
	margin-right: 1rem;
}

#fileConfirmation #fileList small.text-muted {
	margin-left: auto;
	margin-right: 0.5rem;
	width: 60px;
	text-align: center;
	flex-shrink: 0;
}

#fileConfirmation #fileList > div {
	display: flex;
	align-items: center;
	padding: 0.5rem 0.75rem;
	border-bottom: 1px solid #e9ecef;
}

#fileConfirmation #fileList i {
	margin-right: 0.5rem;
	animation: pulse 1s infinite alternate;
}

#fileConfirmation #fileList button {
	border: none;
	background: transparent;
	color: #dc3545;
	padding: 0.2rem 0.4rem;
	cursor: pointer;
}

#confirmUploadBtn {
	width: auto;
	padding: 0.375rem 0.75rem;
	margin-top: 1rem;
	display: inline-block;
}

#fileConfirmation #fileList i {
	animation: icon-pulse 1s infinite alternate;
}

@keyframes icon-pulse {
	0% {
		transform: scale(1);
	}

	50% {
		transform: scale(1.2);
	}

	100% {
		transform: scale(1);
	}
}

#fileConfirmation #fileList button i {
	animation: x-pulse 1s infinite alternate;
}

@keyframes x-pulse {
	0% {
		transform: scale(1);
	}

	50% {
		transform: scale(1.2);
	}

	100% {
		transform: scale(1);
	}
}

.table td i.folder-icon {
        color: #FFA726;
        font-size: 1.1em;
}

.table td i.file-icon {
        color: #4285F4;
        font-size: 1.1em;
}

.table td i.file-icon:hover,
.table td i.folder-icon:hover {
        opacity: 0.8;
        transform: scale(1.1);
        transition: all 0.3s;
}

.table td i.file-icon.fa-file-pdf { color: #FF4136; }
.table td i.file-icon.fa-file-word { color: #2B579A; }
.table td i.file-icon.fa-file-excel { color: #217346; }
.table td i.file-icon.fa-file-powerpoint { color: #D24726; }
.table td i.file-icon.fa-file-archive { color: #795548; }
.table td i.file-icon.fa-file-image { color: #9C27B0; }
.table td i.file-icon.fa-music { color: #673AB7; }
.table td i.file-icon.fa-file-video { color: #E91E63; }
.table td i.file-icon.fa-file-code { color: #607D8B; }
.table td i.file-icon.fa-file-alt { color: #757575; }
.table td i.file-icon.fa-cog { color: #555; }
.table td i.file-icon.fa-file-csv { color: #4CAF50; }
.table td i.file-icon.fa-html5 { color: #E44D26; }
.table td i.file-icon.fa-js { color: #E0A800; }
.table td i.file-icon.fa-terminal { color: #28a745; }
.table td i.file-icon.fa-list-alt { color: #007bff; }
.table td i.file-icon.fa-apple { color: #343a40; }
.table td i.file-icon.fa-android { color: #28a745; }
@media (max-width: 768px) {
	#siteLogo {
		display: none;
	}

	.row.mb-3.px-2.mt-5 {
		margin-top: 1.5rem !important;
	}

	.btn i.fas,
    .btn i.bi {
		font-size: 1.2rem;
	}
}
</style>

<div class="container-sm container-bg px-2 px-sm-4 mt-4">
<nav class="navbar navbar-expand-lg sticky-top">
    <div class="container-sm container px-4 px-sm-3 px-md-4">
        <a class="navbar-brand d-flex align-items-center" href="#">
            <?= $iconHtml ?>
            <span style="color: var(--accent-color); letter-spacing: 1px;"><?= htmlspecialchars($title) ?></span>
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarContent">
            <i class="bi bi-list" style="color: var(--accent-color); font-size: 1.8rem;"></i>
        </button>
        <div class="collapse navbar-collapse" id="navbarContent">
            <ul class="navbar-nav me-auto mb-2 mb-lg-0" style="font-size: 18px;">
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'index.php' ? 'active' : '' ?>" href="./index.php"><i class="bi bi-house-door"></i> <span data-translate="home">Home</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'mihomo_manager.php' ? 'active' : '' ?>" href="./mihomo_manager.php"><i class="bi bi-folder"></i> <span data-translate="manager">Manager</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'singbox.php' ? 'active' : '' ?>" href="./singbox.php"><i class="bi bi-shop"></i> <span data-translate="template_i">Template I</span></a>
                </li>
                <li class="nav-item d-none">
                    <a class="nav-link <?= $current == 'subscription.php' ? 'active' : '' ?>" href="./subscription.php"><i class="bi bi-bank"></i> <span data-translate="template_ii">Template II</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'mihomo.php' ? 'active' : '' ?>" href="./mihomo.php"><i class="bi bi-building"></i> <span data-translate="template_iii">Template III</span></a>
                </li>
                <li class="nav-item d-none">
                    <a class="nav-link <?= $current == 'netmon.php' ? 'active' : '' ?>" href="./netmon.php"><i class="bi bi-activity"></i> <span data-translate="traffic_monitor">Traffic Monitor</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'monaco.php' ? 'active' : '' ?>" href="./monaco.php"><i class="bi bi-bank"></i> <span data-translate="pageTitle">File Assistant</span></a>
                </li>
            </ul>
            <div class="d-flex align-items-center">
                <div class="me-3 d-block">
                    <button type="button" class="btn btn-primary icon-btn me-2" onclick="toggleControlPanel()" data-tooltip="control_panel"><i class="bi bi-gear"> </i></button>
                    <button type="button" class="btn btn-danger icon-btn me-2" data-bs-toggle="modal" data-bs-target="#langModal" data-tooltip="set_language"><i class="bi bi-translate"></i></button>
                    <button type="button" class="btn btn-success icon-btn me-2" data-bs-toggle="modal" data-bs-target="#musicModal" data-tooltip="music_player"><i class="bi bi-music-note-beamed"></i></button>
                    <button type="button" id="toggleIpStatusBtn" class="btn btn-warning icon-btn me-2" onclick="toggleIpStatusBar()" data-tooltip="hide_ip_info"><i class="bi bi-eye-slash"> </i></button>
                    <button type="button" class="btn btn-pink icon-btn me-2" data-bs-toggle="modal" data-bs-target="#portModal" data-tooltip="viewPortInfoButton"><i class="bi bi-plug"></i></button>
                    <button type="button" class="btn-refresh-page btn btn-orange icon-btn me-2 d-none d-sm-inline"><i class="fas fa-sync-alt"></i></button>
                    <button type="button" class="btn btn-info icon-btn me-2" onclick="document.getElementById('colorPicker').click()" data-tooltip="component_bg_color"><i class="bi bi-palette"></i></button>
                    <input type="color" id="colorPicker" value="#0f3460" style="display: none;">
            </div>
        </div>
    </div>
</nav>
    <div class="row align-items-center mb-4 p-3">
        <div class="col-md-3 text-center  text-md-start">
            <img src="./assets/img/nekobox.png" id="siteLogo" alt="Neko Box" class="img-fluid" style="max-height: 100px;">
        </div>
        <div class="col-md-6 text-center">
            <h2 class="mb-0" id="pageTitle" data-translate="pageTitle">File Assistant</h2>
        </div>
        <div class="col-md-3"></div>
    </div>

    <div class="row mb-3 px-2 mt-5">
        <div class="col-12">
            <div class="btn-toolbar justify-content-between">
                <div class="btn-group">
                    <button type="button" class="btn btn-outline-secondary" onclick="goToParentDirectory()" title="Go Back" data-translate-title="goToParentDirectoryTitle">
                        <i class="fas fa-arrow-left"></i>
                    </button>
                    <button type="button" class="btn btn-outline-secondary" onclick="location.href='?dir=/'" title="Return to Root Directory" data-translate-title="rootDirectoryTitle">
                        <i class="fas fa-home"></i>
                    </button>
                    <button type="button" class="btn btn-outline-secondary" onclick="location.href='?dir=/root'" title="Return to Home Directory" data-translate-title="homeDirectoryTitle">
                        <i class="fas fa-user"></i>
                    </button>
                    <button type="button" class="btn btn-outline-secondary" onclick="location.reload()" title="Refresh Directory Content" data-translate-title="refreshDirectoryTitle">
                        <i class="fas fa-sync-alt"></i>
                    </button>
                </div>

                <div class="btn-group">
                    <button type="button" class="btn btn-outline-secondary" data-bs-toggle="modal" data-bs-target="#searchModal" id="searchBtn" title="Search" data-translate-title="searchTitle">
                        <i class="fas fa-search"></i>
                    </button>
                    <button type="button" class="btn btn-outline-secondary" data-bs-toggle="modal" data-bs-target="#createModal" id="createBtn" title="Create New" data-translate-title="createTitle">
                        <i class="fas fa-plus"></i>
                    </button>
                    <button type="button" class="btn btn-outline-secondary" onclick="showUploadArea()" id="uploadBtn" title="Upload" data-translate-title="uploadTitle">
                        <i class="fas fa-upload"></i>
                    </button>
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

<div class="section-wrapper">
  <div class="upload-container">
    <div class="upload-area" id="uploadArea" style="display: none;">
      <div class="d-flex justify-content-between align-items-center mb-2">
        <p class="upload-instructions mb-0">
          <span data-translate="dragHint">Drag files here or click to select files to upload</span>
        </p>
        <button type="button" class="btn btn-secondary btn-sm ms-2" onclick="event.stopPropagation(); hideUploadArea()" data-translate="cancel">Cancel</button>
      </div>
      <input type="file" name="upload[]" id="fileInput" style="display: none;" multiple>
      <div class="upload-drop-zone p-4 border rounded bg-light" id="dropZone">
        <i class="fas fa-cloud-upload-alt upload-icon"></i>
        <div id="fileConfirmation" class="mt-3" style="display: none;">
          <div class="alert alert-light border text-center">
            <div id="fileList" style="max-height: 120px; overflow-y: auto;"></div>
            <button id="confirmUploadBtn"
                    class="btn btn-primary mt-2"
                    onclick="event.stopPropagation();">
              <i class="fas fa-upload me-1"></i>
              <span data-translate="uploadBtn">Confirm Upload</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="section-wrapper">
  <div class="alert alert-secondary d-none mb-3" id="toolbar">
    <div class="d-flex justify-content-between flex-column flex-sm-row align-items-center">
      <div class="mb-2 mb-sm-0">
        <button class="btn btn-outline-primary btn-sm me-2" id="selectAllBtn" data-translate="select_all">Deselect All</button>
        <span id="selectedInfo" class="text-muted small" data-translate="selected_info">{0} item(s) selected</span>
      </div>
      <button class="btn btn-danger btn-sm" id="batchDeleteBtn"><i class="fas fa-trash-alt me-1"></i><span data-translate="batch_delete">Batch Delete</span></button>
    </div>
  </div>
</div>

<form id="batchDeleteForm" method="post" action="?dir=<?php echo urlencode($current_dir); ?>" style="display: none;"></form>

<div class="container-fluid text-center"  style="min-height: 70vh;">
    <div class="table-responsive">
        <table class="table table-striped table-bordered align-middle">
            <thead class="table-light">
                <tr>
                    <th scope="col">
                        <input type="checkbox" id="selectAllCheckbox">
                    </th>
                    <th scope="col" data-translate="fileName">Name</th>
                    <th scope="col" data-translate="fileType">Type</th>
                    <th scope="col" data-translate="fileSize">Size</th>
                    <th scope="col" data-translate="modifiedTime">Modified Time</th>
                    <th scope="col" data-translate="permissions">Permissions</th>
                    <th scope="col" data-translate="owner">Owner</th>
                    <th scope="col" data-translate="actions">Actions</th>
                </tr>
            </thead>

            <tbody>
                <?php if ($current_dir != ''): ?>
                    <tr>
                        <td></td>
                        <td class="folder-icon">
                            <a href="?dir=<?php echo urlencode(dirname($current_dir)); ?>">..</a>
                        </td>
                        <td data-translate="directory">Directory</td>
                        <td>-</td>
                        <td>-</td>
                        <td>-</td>
                        <td>-</td>
                        <td></td>
                    </tr>
                <?php endif; ?>

                <?php foreach ($contents as $item): ?>
                    <?php
                        $full_path = $current_path . $item['path'];
                        $file_size = $item['is_dir']
                            ? 0
                            : (file_exists($full_path) ? filesize($full_path) : 0);
                    ?>

                    <tr>
                        <td>
                            <input type="checkbox"
                                   class="file-checkbox"
                                   data-path="<?php echo htmlspecialchars($item['path']); ?>"
                                   data-size="<?php echo $file_size; ?>">
                        </td>

                        <?php
                            if ($item['is_dir']) {
                                $icon_class = 'fas fa-folder';
                            } else {
                                $ext = strtolower(pathinfo($item['name'], PATHINFO_EXTENSION));
                                switch ($ext) {
                                    case 'pdf': $icon_class = 'fas fa-file-pdf'; break;
                                    case 'doc':
                                    case 'docx': $icon_class = 'fas fa-file-word'; break;
                                    case 'xls':
                                    case 'xlsx': $icon_class = 'fas fa-file-excel'; break;
                                    case 'ppt':
                                    case 'pptx': $icon_class = 'fas fa-file-powerpoint'; break;
                                    case 'txt': $icon_class = 'fas fa-file-alt'; break;
                                    case 'rtf': $icon_class = 'fas fa-file-word'; break;
                                    case 'md':
                                    case 'markdown': $icon_class = 'fas fa-file-code'; break;

                                    case 'zip':
                                    case 'rar':
                                    case '7z':
                                    case 'tar':
                                    case 'gz': $icon_class = 'fas fa-file-archive'; break;

                                    case 'mp3':
                                    case 'wav':
                                    case 'ogg':
                                    case 'flac':
                                    case 'aac': $icon_class = 'fas fa-music'; break;

                                    case 'mp4':
                                    case 'avi':
                                    case 'mov':
                                    case 'wmv':
                                    case 'flv':
                                    case 'mkv':
                                    case 'webm': $icon_class = 'fas fa-file-video'; break;

                                    case 'jpg':
                                    case 'jpeg':
                                    case 'png':
                                    case 'gif':
                                    case 'bmp':
                                    case 'tiff':
                                    case 'webp':
                                    case 'svg':
                                    case 'ico': $icon_class = 'fas fa-file-image'; break;

                                    case 'exe':
                                    case 'msi': $icon_class = 'fas fa-cogs'; break;
                                    case 'sh':
                                    case 'bash':
                                    case 'zsh': $icon_class = 'fas fa-terminal'; break;

                                    case 'bat':
                                    case 'cmd': $icon_class = 'fas fa-list-alt'; break;

                                    case 'ps1': $icon_class = 'fab fa-microsoft'; break;
                                    case 'dll':
                                    case 'so': $icon_class = 'fas fa-cube'; break;
                                    case 'apk': $icon_class = 'fab fa-android'; break;
                                    case 'ipa': $icon_class = 'fab fa-apple'; break;

                                    case 'iso':
                                    case 'img':
                                    case 'dmg': $icon_class = 'fas fa-compact-disc'; break;

                                    case 'sql':
                                    case 'db':
                                    case 'dbf':
                                    case 'sqlite': $icon_class = 'fas fa-database'; break;

                                    case 'ttf':
                                    case 'otf':
                                    case 'woff':
                                    case 'woff2': $icon_class = 'fas fa-font'; break;

                                    case 'cfg':
                                    case 'conf':
                                    case 'ini':
                                    case 'yaml':
                                    case 'yml': $icon_class = 'fas fa-cog'; break;

                                    case 'psd':
                                    case 'ai':
                                    case 'eps': $icon_class = 'fas fa-paint-brush'; break;
                                    case 'css': $icon_class = 'fab fa-css3-alt'; break;
                                    case 'js': $icon_class = 'fab fa-js'; break;
                                    case 'php': $icon_class = 'fab fa-php'; break;
                                    case 'html':
                                    case 'htm': $icon_class = 'fab fa-html5'; break;
                                    case 'json': $icon_class = 'fas fa-file-code'; break;
                                    case 'xml': $icon_class = 'fas fa-file-code'; break;
                                    case 'py': $icon_class = 'fab fa-python'; break;
                                    case 'java': $icon_class = 'fab fa-java'; break;
                                    case 'c':
                                    case 'cpp':
                                    case 'h': $icon_class = 'fas fa-file-code'; break;

                                    case 'bin': $icon_class = 'fas fa-microchip'; break;
                                    case 'log': $icon_class = 'fas fa-scroll'; break;
                                    case 'csv': $icon_class = 'fas fa-file-csv'; break;
                                    case 'torrent': $icon_class = 'fas fa-magnet'; break;
                                    case 'bak': $icon_class = 'fas fa-history'; break;

                                    default: $icon_class = 'fas fa-file'; break;
                                }
                            }

                        ?>

                        <td>
                            <?php if ($item['is_dir']): ?>
                                <i class="<?php echo $icon_class; ?> folder-icon me-2"></i>
                                <a href="?dir=<?php echo urlencode($current_dir . $item['path']); ?>">
                                    <?php echo htmlspecialchars($item['name']); ?>
                                </a>
                            <?php else: ?>
                                <?php
                                    $ext = strtolower(pathinfo($item['name'], PATHINFO_EXTENSION));
                                    $clean_path = ltrim(str_replace('//', '/', $item['path']), '/');
                                ?>
                                <i class="<?php echo $icon_class; ?> file-icon me-2"></i>
                                <?php if (in_array($ext, ['jpg','jpeg','png','gif','svg','bmp','webp','mp3','wav','ogg','flac','mp4','webm','avi','mkv'])): ?>
                                    <a href="#"
                                       onclick="previewFile('<?php echo htmlspecialchars($clean_path); ?>', '<?php echo $ext; ?>')">
                                        <?php echo htmlspecialchars($item['name']); ?>
                                    </a>
                                <?php else: ?>
                                    <a href="#"
                                       onclick="openEditDialog('<?php echo urlencode($item['path']); ?>')">
                                        <?php echo htmlspecialchars($item['name']); ?>
                                    </a>
                                <?php endif; ?>
                            <?php endif; ?>
                        </td>

                        <td data-translate="<?php echo $item['is_dir'] ? 'directory' : 'file'; ?>">
                            <?php echo $item['is_dir'] ? 'Directory' : 'File'; ?>
                        </td>
                        <td><?php echo $item['size']; ?></td>
                        <td><?php echo $item['mtime']; ?></td>
                        <td><?php echo $item['permissions']; ?></td>
                        <td><?php echo htmlspecialchars($item['owner']); ?></td>

                        <td>
                            <div class="btn-group" role="group" aria-label="Actions">
                                <div class="action-grid mt-3">
                                    <button type="button"
                                            class="btn btn-outline-primary btn-sm action-btn"
                                            data-bs-toggle="modal"
                                            data-bs-target="#renameModal"
                                            onclick="showRenameModal('<?php echo htmlspecialchars($item['name']); ?>',
                                                                     '<?php echo htmlspecialchars($item['path']); ?>')"
                                            data-translate-title="rename">
                                        <i class="fas fa-edit"></i>
                                    </button>

                                    <?php if (!$item['is_dir']): ?>
                                        <a href="?dir=<?php echo urlencode($current_dir); ?>&download=<?php echo urlencode($item['path']); ?>"
                                           class="btn btn-outline-info btn-sm action-btn"
                                           data-translate-title="download">
                                            <i class="fas fa-download"></i>
                                        </a>
                                    <?php endif; ?>

                                    <button type="button"
                                            onclick="showChmodModal('<?php echo htmlspecialchars($item['path']); ?>',
                                                                    '<?php echo $item['permissions']; ?>')"
                                            class="btn btn-outline-warning btn-sm action-btn"
                                            data-translate-title="setPermissions">
                                        <i class="fas fa-lock"></i>
                                    </button>

                                    <form method="post"
                                          style="display:inline;"
                                          onsubmit="return uniqueConfirmDelete(event, '<?= addslashes(htmlspecialchars($item['name'])) ?>')"
                                          class="no-loader">
                                        <input type="hidden" name="action" value="delete">
                                        <input type="hidden" name="path" value="<?= htmlspecialchars($item['path']) ?>">
                                        <button type="submit"
                                                class="btn btn-outline-danger btn-sm action-btn"
                                                data-translate-title="delete">
                                            <i class="fas fa-trash-alt"></i>
                                        </button>
                                    </form>
                                </div>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<div class="modal fade" id="renameModal" tabindex="-1" aria-labelledby="renameModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered">
    <form method="post" class="modal-content" onsubmit="return validateRename()">
      <div class="modal-header">
        <h5 class="modal-title" id="renameModalLabel" data-translate="rename">✏️ Rename</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <input type="hidden" name="action" value="rename">
      <input type="hidden" name="old_path" id="oldPath">
      <div class="modal-body">
        <div class="mb-3">
          <label for="newPath" class="form-label" data-translate="newName">New name</label>
          <input type="text" class="form-control" id="newPath" name="new_path" autocomplete="off"
            data-translate-placeholder="enterNewName">
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancel">Close</button>
        <button type="submit" class="btn btn-primary" data-translate="saveButton">Save</button>
      </div>
    </form>
  </div>
</div>

<div class="modal fade" id="createModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" data-translate="create">Create</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body d-flex gap-2">
        <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#newFolderModal" data-bs-dismiss="modal" data-translate="newFolder">
          <i class="fas fa-folder-plus"></i> New Folder
        </button>
        <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#newFileModal" data-bs-dismiss="modal" data-translate="newFile">
          <i class="fas fa-file-plus"></i> New File
        </button>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close">Close</button>
      </div>
    </div>
  </div>
</div>

<div class="modal fade" id="newFolderModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered">
    <form method="post" class="modal-content" onsubmit="return createNewFolder()">
      <div class="modal-header">
        <h5 class="modal-title" data-translate="newFolder">New Folder</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <input type="hidden" name="action" value="create_folder">
        <div class="mb-3">
          <label for="newFolderName" class="form-label" data-translate="folderName">Folder name:</label>
          <input type="text" name="new_folder_name" id="newFolderName" class="form-control" required data-translate-placeholder="enterFolderName" placeholder="Enter folder name">
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancel">Cancel</button>
        <button type="submit" class="btn btn-primary" data-translate="create">Create</button>
      </div>
    </form>
  </div>
</div>

<div class="modal fade" id="newFileModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered">
    <form method="post" class="modal-content" onsubmit="return createNewFile()">
      <div class="modal-header">
        <h5 class="modal-title" data-translate="newFile">New File</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <input type="hidden" name="action" value="create_file">
        <div class="mb-3">
          <label for="newFileName" class="form-label" data-translate="fileName">File name:</label>
          <input type="text" name="new_file_name" id="newFileName" class="form-control" required data-translate-placeholder="enterFileName" placeholder="Enter file name">
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancel">Cancel</button>
        <button type="submit" class="btn btn-primary" data-translate="create">Create</button>
      </div>
    </form>
  </div>
</div>
      
<div class="modal fade" id="searchModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-xl modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" data-translate="searchFiles">Search Files</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form id="searchForm" onsubmit="searchFiles(event)"  class="no-loader">
                    <div class="input-group mb-3">
                        <input type="text" id="searchInput" class="form-control" data-translate-placeholder="search_placeholder" required>
                        <button class="btn btn-primary" type="submit" data-translate="search">
                            <i class="fas fa-search"></i> Search
                        </button>
                    </div>
                </form>
                <div id="searchResults" class="mt-3" style="max-height: 60vh; overflow-y: auto;"></div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close">Close</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="editModal" tabindex="-1" aria-labelledby="editModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered">
    <form method="post" id="editForm" onsubmit="return saveEdit()" class="modal-content no-loader">
      <div class="modal-header">
        <h5 class="modal-title" id="editModalLabel" data-translate="editFile">Edit File</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>

      <input type="hidden" name="action" value="edit">
      <input type="hidden" name="path" id="editPath">
      <input type="hidden" name="encoding" id="editEncoding">

      <div class="modal-body">
        <textarea name="content" id="editContent" class="form-control" rows="25" spellcheck="false"></textarea>
      </div>

      <div class="modal-footer">
        <button type="submit" class="btn btn-primary" data-translate="save">Save</button>
        <button type="button" onclick="openMonacoEditor()" class="btn btn-danger" data-translate="advancedEdit">Advanced Edit</button>
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close">Close</button>
      </div>
    </form>
  </div>
</div>

<div id="monacoEditor">
    <div id="editorControls">
        <div id="leftControls">
            <select id="fontSize" onchange="changeFontSize()">
                <option value="18px">18px</option>
                <option value="20px">20px</option>
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
                <option value="vs-dark">VS Dark</option>
                <option value="vs">VS Light</option>
                <option value="hc-black">High Contrast Black</option>
                <option value="hc-light">High Contrast Light</option>
                <option value="my-hc-light">My High Contrast Light</option> 
                <option value="my-custom-theme">My Custom Theme</option>
            </select>
            <button type="button" class="btn btn-sm btn-primary" onclick="openSearch()" data-translate="search"></button>
            <button type="button" class="btn btn-sm btn-rose-gold" onclick="toggleComment()" data-translate="toggleComment">Toggle Comment</button>
            <button type="button" class="btn btn-sm btn-teal" onclick="openDiffEditorPrompt()" data-translate="compare">Compare</button>
            <button type="button" class="btn btn-sm btn-danger" id="toggleFullscreenBtn" onclick="toggleFullscreen()" data-translate="toggleFullscreen">Fullscreen</button>
            <button type="button" class="btn btn-sm btn-info" onclick="formatContent()" data-translate="format">Format</button>
            <button type="button" class="btn btn-sm btn-fuchsia" id="jsonValidationBtn" onclick="validateJsonSyntax()" style="display:none;" data-translate="validateJson">Validate JSON</button>
            <button type="button" class="btn btn-sm btn-pink" id="yamlValidationBtn" onclick="validateYamlSyntax()" style="display:none;" data-translate="validateYaml">Validate YAML</button>
            <button type="button" class="btn btn-sm btn-warning" id="yamlFormatBtn" onclick="formatYamlContent()" style="display:none;" data-translate="formatYaml">Format YAML</button>
            <button type="button" class="btn btn-sm btn-success" onclick="saveFullScreenContent()" data-translate="saveButton">Save</button>
            <button type="button" class="btn btn-sm btn-secondary" onclick="closeMonacoEditor()" data-translate="close">Close</button>
        </div>        
        <div id="statusInfo">
            <span id="lineColumnDisplay" data-translate="lineColumnDisplay"></span>
            <span id="charCountDisplay" data-translate="charCountDisplay"></span>
        </div>
    </div>
</div>
       
<div class="modal fade" id="chmodModal" tabindex="-1" aria-labelledby="chmodModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered">
    <form method="post" onsubmit="return validateChmod()" class="modal-content no-loader">
      <div class="modal-header">
        <h5 class="modal-title" id="chmodModalLabel" data-translate="setPermissions">🔒 Set Permissions</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <input type="hidden" name="action" value="chmod">
        <input type="hidden" name="path" id="chmodPath">

        <div class="mb-3">
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
          <div class="form-text mt-1" data-translate="permissionHelp">
            Please enter a valid permission value (three or four octal digits, e.g.: 644 or 0755)
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button"
                class="btn btn-secondary"
                data-bs-dismiss="modal"
                data-translate="cancel">Cancel</button>
        <button type="submit"
                class="btn btn-primary"
                data-translate="saveButton">Save</button>
      </div>
    </form>
  </div>
</div>

<div class="modal fade" id="previewModal" tabindex="-1" aria-labelledby="previewModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="previewModalLabel" data-translate="filePreview">File Preview</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body" id="previewContainer">
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancel">Cancel</button>
      </div>
    </div>
  </div>
</div>

<script>
let selectedFiles = [];
let pendingFiles = [];
let selectedFilesSize = 0;
let monacoEditorInstance = null;
let diffEditorInstance = null; 
let currentEncoding = 'UTF-8';

document.addEventListener('DOMContentLoaded', function() {
    initFileSelection();
    initDragAndDrop();
    initEventListeners();
    initSearch();
});

function initDragAndDrop() {
    const dropZone = document.getElementById('dropZone');
    const fileInput = document.getElementById('fileInput');
    
    dropZone.addEventListener('click', () => fileInput.click());
    
    fileInput.addEventListener('change', function(e) {
        if (this.files.length > 0) {
            processFiles(this.files);
        }
    });
    
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        dropZone.addEventListener(eventName, preventDefaults, false);
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
    
    function highlight() {
        dropZone.classList.add('drag-over');
    }
    
    function unhighlight() {
        dropZone.classList.remove('drag-over');
    }
    
    dropZone.addEventListener('drop', function(e) {
        const dt = e.dataTransfer;
        processFiles(dt.files);
    });

    document.getElementById('confirmUploadBtn').addEventListener('click', function() {
        if (pendingFiles.length === 0) return;
        uploadPendingFiles();
    });
}

function processFiles(files) {
    pendingFiles = Array.from(files);
    updateFileList();
    document.getElementById('fileConfirmation').style.display = 'block';
}

function updateFileList() {
    const fileList = document.getElementById('fileList');
    fileList.innerHTML = '';
    
    pendingFiles.forEach((file, index) => {
        const fileItem = document.createElement('div');
        fileItem.className = 'd-flex justify-content-between align-items-center py-1';

        const ext = file.name.split('.').pop().toLowerCase();
        let iconClass = 'fas fa-file';
        if(['jpg','jpeg','png','gif','bmp','webp'].includes(ext)) iconClass = 'fas fa-file-image';
        else if(['mp4','webm','avi','mkv','mov'].includes(ext)) iconClass = 'fas fa-file-video';
        else if(['mp3','wav','flac','aac'].includes(ext)) iconClass = 'fas fa-file-audio';
        else if(['zip','rar','7z','tar','gz'].includes(ext)) iconClass = 'fas fa-file-archive';
        else if(ext === 'pdf') iconClass = 'fas fa-file-pdf';
        else if(['doc','docx','txt','md','rtf'].includes(ext)) iconClass = 'fas fa-file-alt';

        fileItem.innerHTML = `
            <span class="text-truncate" style="max-width: 60%;">
                <i class="${iconClass} me-2 text-secondary"></i>
                ${file.name}
            </span>
            <small class="text-muted me-2">${formatSize(file.size)}</small>
            <button class="btn btn-sm btn-link text-danger p-0"
                    onclick="event.stopPropagation(); removeFile(${index})">
                <i class="fas fa-times"></i>
            </button>
        `;
        fileList.appendChild(fileItem);
    });
}

function removeFile(index) {
    pendingFiles.splice(index, 1);
    if (pendingFiles.length === 0) {
        document.getElementById('fileConfirmation').style.display = 'none';
    } else {
        updateFileList();
    }
}

function uploadPendingFiles() {
    const formData = new FormData();    
    formData.append('dir', '<?php echo $current_dir; ?>');
    
    pendingFiles.forEach(file => {
        formData.append('upload[]', file);
    });
    
    const progressContainer = document.createElement('div');
    progressContainer.className = 'upload-progress-container mt-3';
    document.getElementById('uploadArea').appendChild(progressContainer);
    
    const progressBar = document.createElement('div');
    progressBar.className = 'progress';
    progressBar.innerHTML = `
        <div class="progress-bar progress-bar-striped progress-bar-animated" 
             role="progressbar" 
             style="width: 0%">
            <span class="upload-progress-text">0%</span>
        </div>
    `;
    progressContainer.appendChild(progressBar);
    
    fetch(window.location.href, {
        method: 'POST',
        body: formData
    })
    .then(response => {
        if (response.ok) {
            return response.text();
        }
        throw new Error('Upload failed');
    })
    .then(() => {
        location.reload();
    })
    .catch(error => {
        alert('Error uploading files: ' + error.message);
    })
    .finally(() => {
        progressContainer.remove();
    });
}

function handleFiles(files) {
    const formData = new FormData();
    
    for (let i = 0; i < files.length; i++) {
        formData.append('upload[]', files[i]);
    }
    
    const uploadArea = document.getElementById('uploadArea');
    const progressContainer = document.createElement('div');
    progressContainer.className = 'upload-progress-container mt-3';
    uploadArea.appendChild(progressContainer);
    
    const progressBar = document.createElement('div');
    progressBar.className = 'progress';
    progressBar.innerHTML = `
        <div class="progress-bar progress-bar-striped progress-bar-animated" 
             role="progressbar" 
             style="width: 0%">
            <span class="upload-progress-text">0%</span>
        </div>
    `;
    progressContainer.appendChild(progressBar);
    
    fetch(window.location.href, {
        method: 'POST',
        body: formData,
        onUploadProgress: function(progressEvent) {
            if (progressEvent.lengthComputable) {
                const percentComplete = Math.round((progressEvent.loaded * 100) / progressEvent.total);
                const progressBarInner = progressBar.querySelector('.progress-bar');
                progressBarInner.style.width = percentComplete + '%';
                progressBarInner.querySelector('.upload-progress-text').textContent = percentComplete + '%';
            }
        }
    })
    .then(response => {
        if (response.ok) {
            return response.text();
        }
        throw new Error('Upload failed');
    })
    .then(() => {
        location.reload();
    })
    .catch(error => {
        alert('Error uploading files: ' + error.message);
    })
    .finally(() => {
        progressContainer.remove();
    });
}

function initEventListeners() {
    document.getElementById('uploadBtn').addEventListener('click', showUploadArea);
    document.getElementById('editForm').addEventListener('submit', saveEdit);
    document.getElementById('searchForm').addEventListener('submit', performSearch);

}

function initFileSelection() {
    const selectAllCheckbox = document.getElementById('selectAllCheckbox');
    const fileCheckboxes = document.querySelectorAll('.file-checkbox');
    const toolbar = document.getElementById('toolbar');
    const selectedInfo = document.getElementById('selectedInfo');
    const batchDeleteBtn = document.getElementById('batchDeleteBtn');
    const selectAllBtn = document.getElementById('selectAllBtn');

    selectAllCheckbox.addEventListener('change', function() {
        fileCheckboxes.forEach(checkbox => {
            checkbox.checked = this.checked;
        });
        updateSelection(toolbar, selectedInfo, fileCheckboxes, selectAllCheckbox);
    });

    fileCheckboxes.forEach(checkbox => {
        checkbox.addEventListener('change', function() {
            updateSelection(toolbar, selectedInfo, fileCheckboxes, selectAllCheckbox);
        });
    });

    selectAllBtn.addEventListener('click', function() {
        const isAllSelected = selectedFiles.length === fileCheckboxes.length && fileCheckboxes.length > 0;
        fileCheckboxes.forEach(checkbox => {
            checkbox.checked = !isAllSelected;
        });
        selectAllCheckbox.checked = !isAllSelected;
        updateSelection(toolbar, selectedInfo, fileCheckboxes, selectAllCheckbox);
        if (isAllSelected) {
            toolbar.classList.add('d-none');
        }
    });

    batchDeleteBtn.addEventListener('click', function() {
        if (selectedFiles.length > 0) {
            let confirmMessage = translations['batch_delete_confirm'] || 'Are you sure you want to delete {count} selected files/folders? This action cannot be undone!';
            confirmMessage = confirmMessage.replace('{count}', selectedFiles.length);
            showConfirmation(encodeURIComponent(confirmMessage), function () {
                const batchDeleteForm = document.getElementById('batchDeleteForm');
                batchDeleteForm.innerHTML = '<input type="hidden" name="action" value="delete_selected">';
                selectedFiles.forEach(path => {
                    const input = document.createElement('input');
                    input.type = 'hidden';
                    input.name = 'selected_paths[]';
                    input.value = path;
                    batchDeleteForm.appendChild(input);
                });
                batchDeleteForm.submit();
            });
        } else {
            alert(translations['batch_delete_no_selection'] || 'Please select files to delete first!');
        }
    });

    updateSelection(toolbar, selectedInfo, fileCheckboxes, selectAllCheckbox);
}

function updateSelection(toolbar, selectedInfo, fileCheckboxes, selectAllCheckbox) {
    selectedFiles = [];
    selectedFilesSize = 0;
    
    fileCheckboxes.forEach(checkbox => {
        if (checkbox.checked) {
            selectedFiles.push(checkbox.dataset.path);
            const sizeBytes = parseInt(checkbox.dataset.size) || 0;
            selectedFilesSize += sizeBytes;
        }
    });

    const allChecked = selectedFiles.length === fileCheckboxes.length && fileCheckboxes.length > 0;
    const someChecked = selectedFiles.length > 0 && !allChecked;
    selectAllCheckbox.checked = allChecked;
    selectAllCheckbox.indeterminate = someChecked;

    if (selectedFiles.length > 0) {
        const formattedSize = formatSize(selectedFilesSize);
        let selectedMessage = translations['selected_info'] || 'Selected {count} files, total {size}';
        selectedMessage = selectedMessage.replace('{count}', selectedFiles.length).replace('{size}', formattedSize);
        selectedInfo.textContent = selectedMessage;
        toolbar.classList.remove('d-none');
    } else {
        toolbar.classList.add('d-none');
        selectedInfo.textContent = translations['selected_info_none'] || 'Selected 0 items';
    }
}

function formatSize(bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    bytes = Math.max(bytes, 0);
    const pow = Math.floor((bytes ? Math.log(bytes) : 0) / Math.log(1024));
    const unit = units[Math.min(pow, units.length - 1)];
    bytes /= (1 << (10 * pow));
    return bytes.toFixed(2) + ' ' + unit;
}

function showUploadArea() {
    document.getElementById('uploadArea').style.display = 'block';
}

function hideUploadArea() {
    document.getElementById('uploadArea').style.display = 'none';
}

function goToParentDirectory() {
    const currentDir = '<?php echo $current_dir; ?>';
    const parentDir = currentDir.split('/').slice(0, -2).join('/') + '/';
    window.location.href = `?dir=${encodeURIComponent(parentDir)}`;
}

function showRenameModal(name, path) {
    document.getElementById('oldPath').value = path;
    document.getElementById('newPath').value = name;
    const input = document.getElementById('newPath');
    input.focus();
    const dotIndex = name.lastIndexOf('.');
    if (dotIndex > 0) {
        input.setSelectionRange(0, dotIndex);
    } else {
        input.select();
    }
}

function validateRename() {
    const newName = document.getElementById('newPath').value.trim();
    if (!newName) {
        alert('Please enter a new name');
        return false;
    }
    return true;
}

function showChmodModal(path, permissions) {
    document.getElementById('chmodPath').value = path;
    document.getElementById('permissions').value = permissions;
    const modal = new bootstrap.Modal(document.getElementById('chmodModal'));
    modal.show();
}

function validateChmod() {
    const permissions = document.getElementById('permissions').value.trim();
    if (!/^[0-7]{3,4}$/.test(permissions)) {
        showConfirmation(encodeURIComponent(translations['chmod_invalid_input'] || 'Please enter a valid permission value (3 or 4 digit octal number, e.g., 644 or 0755).'));
        return false;
    }
    return true;
}

function createNewFolder() {
    const folderName = document.getElementById('newFolderName').value.trim();
    if (!folderName) {
        alert('Please enter a folder name');
        return false;
    }
    return true;
}

function createNewFile() {
    const fileName = document.getElementById('newFileName').value.trim();
    if (!fileName) {
        alert('Please enter a file name');
        return false;
    }
    return true;
}

function initSearch() {
    const searchInput = document.getElementById('searchInput');
    searchInput.addEventListener('keyup', function(e) {
        if (e.key === 'Enter') {
            performSearch(e);
        }
    });
}

function searchFiles(event) {
    event.preventDefault();
    const searchTerm = document.getElementById('searchInput').value.trim();
    
    if (!searchTerm) {
        alert(translations['search_empty_input'] || 'Please enter a search keyword');
        return;
    }

    fetch(`?action=search&term=${encodeURIComponent(searchTerm)}`)
        .then(response => response.json())
        .then(results => {
            const resultsContainer = document.getElementById('searchResults');
            resultsContainer.innerHTML = '';
            
            if (results.length === 0) {
                resultsContainer.innerHTML = `<div class="alert alert-info">${translations['search_no_results'] || 'No matching files found'}</div>`;
                return;
            }
            
            const table = document.createElement('table');
            table.className = 'table table-striped';
            
            const thead = document.createElement('thead');
            thead.innerHTML = `
                <tr>
                    <th>${translations['search_filename'] || 'File Name'}</th>
                    <th>${translations['search_path'] || 'Path'}</th>
                    <th>${translations['search_action'] || 'Action'}</th>
                </tr>
            `;
            table.appendChild(thead);
            
            const tbody = document.createElement('tbody');
            
            results.forEach(file => {
                const tr = document.createElement('tr');               
                const tdName = document.createElement('td');
                tdName.textContent = file.name;
                tr.appendChild(tdName);

                const tdPath = document.createElement('td');
                tdPath.textContent = file.path;
                tr.appendChild(tdPath);
                
                const tdAction = document.createElement('td');
                const moveBtn = document.createElement('button');
                moveBtn.className = 'btn btn-sm btn-primary';
                moveBtn.innerHTML = `<i class="fas fa-folder-open"></i> ${translations['search_move_to'] || 'Move To'}`;
                moveBtn.onclick = function() {
                    const modal = bootstrap.Modal.getInstance(document.getElementById('searchModal'));
                    if (modal) modal.hide();

                    const targetDir = file.dir === '' ? '/' : file.dir;
                    window.location.href = `?dir=${encodeURIComponent(targetDir)}`;
                };
                tdAction.appendChild(moveBtn);
                tr.appendChild(tdAction);
                
                tbody.appendChild(tr);
            });
            
            table.appendChild(tbody);
            resultsContainer.appendChild(table);
        })
        .catch(error => {
            console.error('Search error:', error);
            let errorMessage = translations['search_error'] || 'Search error: {message}';
            errorMessage = errorMessage.replace('{message}', error.message);
            document.getElementById('searchResults').innerHTML = `
                <div class="alert alert-danger">
                    ${errorMessage}
                </div>
            `;
        });
}

function openEditDialog(path) {
    currentFilePath = decodeURIComponent(path);
    
    fetch(`?action=get_content&dir=<?php echo urlencode($current_dir); ?>&path=${encodeURIComponent(currentFilePath)}`)
    .then(response => {
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.text();
    })
    .then(content => {
        document.getElementById('editPath').value = currentFilePath;
        document.getElementById('editContent').value = content;
        let title = translations['edit_file_title'] || 'Edit File: {filename}';
        title = title.replace('{filename}', currentFilePath.split('/').pop());
        document.getElementById('editModalLabel').textContent = title;
        
        const modal = new bootstrap.Modal(document.getElementById('editModal'));
        modal.show();
    })
    .catch(error => {
        console.error('Error fetching file content:', error);
        let errorMessage = translations['fetch_content_error'] || 'Unable to fetch file content: {message}';
        errorMessage = errorMessage.replace('{message}', error.message);
        speakMessage(errorMessage);
        showLogMessage(errorMessage);
        console.log('Request URL:', `?action=get_content&dir=<?php echo urlencode($current_dir); ?>&path=${encodeURIComponent(currentFilePath)}`);
    });
}

function saveEdit() {
    const content = document.getElementById('editContent').value;
    const path = document.getElementById('editPath').value;
    const encoding = document.getElementById('editEncoding').value;
    
    const formData = new FormData();
    formData.append('action', 'edit');
    formData.append('path', path);
    formData.append('content', content);
    formData.append('encoding', encoding);
    
    fetch(window.location.href, {
        method: 'POST',
        body: formData
    })
    .then(response => {
        if (response.ok) {
            return response.text();
        }
        throw new Error('Save failed');
    })
    .then(() => {
        const modal = bootstrap.Modal.getInstance(document.getElementById('editModal'));
        modal.hide();
        let successMessage = translations['save_file_success'] || 'File saved successfully';
        speakMessage(successMessage);
        showLogMessage(successMessage);
        setTimeout(() => {
            location.reload();
        }, 3000);
    })
    .catch(error => {
        console.error('Error saving file:', error);
        let errorMessage = translations['save_file_error'] || 'Error saving file: {message}';
        errorMessage = errorMessage.replace('{message}', error.message);
        //speakMessage(errorMessage);
       // showLogMessage(errorMessage);
    });
    
    return false;
}

const monacoScript = document.createElement('script');
monacoScript.src = 'https://cdn.jsdelivr.net/npm/monaco-editor@0.52.2/min/vs/loader.min.js';
document.head.appendChild(monacoScript);

monacoScript.onload = function() {
    require.config({ paths: { 'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.52.2/min/vs' } });
};

function openMonacoEditor() {
    const editModal = bootstrap.Modal.getInstance(document.getElementById('editModal'));
    if (editModal) {
        editModal.hide();
    }

    document.querySelectorAll('.modal-backdrop').forEach(backdrop => backdrop.remove());

    const content = document.getElementById('editContent').value;
    const path = document.getElementById('editPath').value;
    
    const editorContainer = document.createElement('div');
    editorContainer.id = 'monacoEditorContainer';
    editorContainer.style.width = '100%';
    editorContainer.style.height = 'calc(100% - 40px)';
    
    document.getElementById('monacoEditor').style.display = 'flex';
    document.getElementById('monacoEditor').appendChild(editorContainer);
    
    require(['vs/editor/editor.main'], function() {
        monaco.editor.defineTheme('my-custom-theme', {
            base: 'vs-dark',
            inherit: true,
            rules: [
                { token: 'comment', foreground: 'ffa500', fontStyle: 'italic' },
                { token: 'keyword', foreground: 'ff79c6' },
                { token: 'string', foreground: '8be9fd' },
                { token: 'keyword.php', foreground: 'ff79c6' },
                { token: 'string.php', foreground: '8be9fd' },
                { token: 'variable.php', foreground: '50fa7b' }
            ],
            colors: {
                'editor.foreground': '#f8f8f2',
                'editor.background': '#282a36',
                'editorCursor.foreground': '#f8f8f0',
                'editor.lineHighlightBackground': '#44475a',
                'editorLineNumber.foreground': '#6272a4'
            }
        });

        monaco.editor.defineTheme('my-hc-light', {
            base: 'hc-light',
            inherit: true,
            rules: [
                { token: 'keyword', foreground: '2A7AB0', fontStyle: 'bold' },
                { token: 'string', foreground: 'C62828', fontStyle: 'italic' },
                { token: 'comment', foreground: '6B6B6B', fontStyle: 'italic' },
                { token: 'number', foreground: '2E7D32', fontStyle: 'bold' },
                { token: 'identifier', foreground: '333333', fontStyle: 'normal' },
                { token: 'function', foreground: '5F867A', fontStyle: 'bold' },
                { token: 'operator', foreground: '9C27B0', fontStyle: 'normal' },
                { token: 'delimiter', foreground: '757575', fontStyle: 'normal' },
                { token: 'type', foreground: '0277BD', fontStyle: 'italic' },
                { token: 'keyword.php', foreground: '2A7AB0', fontStyle: 'bold' },
                { token: 'variable.php', foreground: 'D32F2F', fontStyle: 'normal' }
            ],
            colors: {
                'editor.background': '#F2F9FC',
                'editor.foreground': '#333333',
                'editorCursor.foreground': '#2A7AB0',
                'editor.lineHighlightBackground': '#E0F2F7',
                'editorLineNumber.foreground': '#6B6B6B',
                'editor.selectionBackground': '#B3E5FC',
                'editor.inactiveSelectionBackground': '#E1F5FE',
                'editorSuggestWidget.background': '#F9FCFE',
                'editorSuggestWidget.foreground': '#333333',
                'editorSuggestWidget.selectedBackground': '#E0F2F7',
                'editorHoverWidget.background': '#F9FCFE',
                'editorHoverWidget.foreground': '#333333',
            }
        });

        const defaultFontSize = '20px';
        const defaultTheme = 'vs-dark';

        let savedFontSize = localStorage.getItem('editorFontSize') || defaultFontSize;
        let savedTheme = localStorage.getItem('editorTheme') || defaultTheme;

        const fontSizeSelect = document.getElementById('fontSize');
        const themeSelect = document.getElementById('editorTheme');

        if (fontSizeSelect) {
            fontSizeSelect.value = savedFontSize;
            if (!fontSizeSelect.value || fontSizeSelect.value !== savedFontSize) {
                savedFontSize = defaultFontSize;
                fontSizeSelect.value = defaultFontSize;
                localStorage.setItem('editorFontSize', defaultFontSize);
            }
        } else {
            console.error('Font size select element not found!');
        }

        if (themeSelect) {
            themeSelect.value = savedTheme;
            if (!themeSelect.value || themeSelect.value !== savedTheme) {
                savedTheme = defaultTheme;
                themeSelect.value = defaultTheme;
                localStorage.setItem('editorTheme', defaultTheme);
            }
        } else {
            console.error('Theme select element not found!');
        }

        console.log('Loaded Font Size:', savedFontSize, 'Select Value:', fontSizeSelect ? fontSizeSelect.value : 'N/A');
        console.log('Loaded Theme:', savedTheme, 'Select Value:', themeSelect ? themeSelect.value : 'N/A');

        monacoEditorInstance = monaco.editor.create(document.getElementById('monacoEditorContainer'), {
            value: content,
            language: 'text',
            theme: savedTheme,
            fontSize: parseInt(savedFontSize.replace('px', '')),
            wordWrap: 'on',
            automaticLayout: true,
            folding: true,
            foldingStrategy: 'indentation',
            multiCursorModifier: 'alt',
            minimap: {
                enabled: true
            }
        });

        const ext = path.split('.').pop().toLowerCase();
        setEditorMode(ext);
        
        updateEditorStatus();
        
        monacoEditorInstance.onDidChangeModelContent(function() {
            document.getElementById('editContent').value = monacoEditorInstance.getValue();
            updateEditorStatus();
            detectContentFormat();
        });

        monacoEditorInstance.onDidChangeCursorPosition(updateEditorStatus);
        
        detectContentFormat();
        
        registerCompletionProviders();
        
        setTimeout(() => {
            monacoEditorInstance.focus();
        }, 100);
    });
    
    document.getElementById('monacoEditor').onclick = function(e) {
        if (e.target === this) {
            closeMonacoEditor();
        }
    };
}

function setEditorMode(ext) {
    const modes = {
        'js': 'javascript',
        'json': 'json',
        'php': 'php',
        'html': 'html',
        'css': 'css',
        'md': 'markdown',
        'yaml': 'yaml',
        'yml': 'yaml',
        'xml': 'xml',
        'sh': 'shell',
        'py': 'python',
        'ts': 'typescript',
        'java': 'java',
        'cs': 'csharp',
        'cpp': 'cpp',
        'c': 'c',
        'go': 'go',
        'rs': 'rust',
        'rb': 'ruby',
        'sql': 'sql',
        'swift': 'swift',
        'kt': 'kotlin',
        'dart': 'dart',
        'scala': 'scala',
        'pl': 'perl',
        'groovy': 'groovy',
        'docker': 'dockerfile',
        'ini': 'ini',
        'bat': 'bat',
        'lua': 'lua',
        'r': 'r',
        'fs': 'fsharp',
        'vb': 'vb',
        'ps1': 'powershell',
        'm': 'objective-c',
        'txt': 'plaintext'
    };
    const language = modes[ext] || 'plaintext';
    if (monacoEditorInstance) {
        monaco.editor.setModelLanguage(monacoEditorInstance.getModel(), language);
    }
}

function closeMonacoEditor() {
    if (monacoEditorInstance) {
        document.getElementById('editContent').value = monacoEditorInstance.getValue();
        monacoEditorInstance.dispose();
        monacoEditorInstance = null;
    }
    if (diffEditorInstance) {
        diffEditorInstance.dispose();
        diffEditorInstance = null;
        const diffContainer = document.getElementById('diffEditorContainer');
        if (diffContainer) {
            diffContainer.remove();
        }
    }
    document.getElementById('monacoEditor').style.display = 'none';
    const container = document.getElementById('monacoEditorContainer');
    if (container) {
        container.remove();
    }
}

function saveFullScreenContent() {
    if (monacoEditorInstance) {
        document.getElementById('editContent').value = monacoEditorInstance.getValue();
        closeMonacoEditor();
        document.getElementById('editForm').submit();
        showLogMessage(translations['save_success'] || 'Saved successfully');
    }
}

function toggleComment() {
    if (monacoEditorInstance) {
        monacoEditorInstance.getAction('editor.action.commentLine').run();
    }
}

function openDiffEditorPrompt() {
    if (!monacoEditorInstance) return;
    const originalContent = monacoEditorInstance.getValue();
    const modifiedContent = prompt(translations['enterModifiedContent'] || 'Enter modified content for comparison:', originalContent);
    if (modifiedContent !== null) {
        openDiffEditor(originalContent, modifiedContent);
    }
}

function openDiffEditor(originalContent, modifiedContent) {
    const editorContainer = document.getElementById('monacoEditorContainer');
    if (editorContainer) {
        editorContainer.style.display = 'none';
    }

    const diffContainer = document.createElement('div');
    diffContainer.id = 'diffEditorContainer';
    diffContainer.style.width = '100%';
    diffContainer.style.height = 'calc(100% - 40px)';
    diffContainer.style.marginTop = '50px';  
    document.getElementById('monacoEditor').appendChild(diffContainer);

    diffEditorInstance = monaco.editor.createDiffEditor(diffContainer, {
        theme: localStorage.getItem('editorTheme') || 'vs-dark',
        automaticLayout: true
    });

    const originalModel = monaco.editor.createModel(modifiedContent, 'text');
    const modifiedModel = monaco.editor.createModel(originalContent, 'text');

    diffEditorInstance.setModel({
        original: originalModel,
        modified: modifiedModel
    });

    originalModel.updateOptions({ readOnly: true });
    modifiedModel.updateOptions({ readOnly: false });

    const existingCloseDiffBtn = document.querySelector('#leftControls button[data-role="closeDiff"]');
    if (existingCloseDiffBtn) {
        existingCloseDiffBtn.remove();
    }

    const closeDiffBtn = document.createElement('button');
    closeDiffBtn.type = 'button';
    closeDiffBtn.className = 'btn btn-sm btn-secondary';
    closeDiffBtn.textContent = translations['closeDiff'] || 'Close Diff View';
    closeDiffBtn.setAttribute('data-role', 'closeDiff');
    closeDiffBtn.onclick = closeDiffEditor;
    document.getElementById('leftControls').appendChild(closeDiffBtn);
}

function closeDiffEditor() {
    if (diffEditorInstance) {
        diffEditorInstance.dispose();
        diffEditorInstance = null;
        const diffContainer = document.getElementById('diffEditorContainer');
        if (diffContainer) {
            diffContainer.remove();
        }
        const closeDiffBtn = document.querySelector('#leftControls button[data-role="closeDiff"]');
        if (closeDiffBtn) {
            closeDiffBtn.remove();
        }
        const editorContainer = document.getElementById('monacoEditorContainer');
        if (editorContainer) {
            editorContainer.style.display = 'block';
        }
    }
}

function detectContentFormat() {
    if (!monacoEditorInstance) return;
    
    const content = monacoEditorInstance.getValue().trim();
    const jsonBtn = document.getElementById('jsonValidationBtn');
    const yamlBtn = document.getElementById('yamlValidationBtn');
    const yamlFormatBtn = document.getElementById('yamlFormatBtn');
    
    try {
        JSON.parse(content);
        jsonBtn.style.display = 'inline-block';
        yamlBtn.style.display = 'none';
        yamlFormatBtn.style.display = 'none';
        return;
    } catch (e) {}
    
    if (content.match(/^(---|\w+:\s)/m)) {
        jsonBtn.style.display = 'none';
        yamlBtn.style.display = 'inline-block';
        yamlFormatBtn.style.display = 'inline-block';
    } else {
        jsonBtn.style.display = 'none';
        yamlBtn.style.display = 'none';
        yamlFormatBtn.style.display = 'none';
    }
}

function updateEditorStatus() {
    if (!monacoEditorInstance) return;
    const position = monacoEditorInstance.getPosition();
    const line = position.lineNumber;
    const column = position.column;
    const charCount = monacoEditorInstance.getValue().length;

    const lineColumnText = langData[currentLang]['lineColumnDisplay'].replace("{line}", line).replace("{column}", column);
    const charCountText = langData[currentLang]['charCountDisplay'].replace("{charCount}", charCount);

    document.getElementById('lineColumnDisplay').textContent = lineColumnText;
    document.getElementById('charCountDisplay').textContent = charCountText;
}

function formatContent() {
    if (!monacoEditorInstance) return;

    const content = monacoEditorInstance.getValue();
    const language = monacoEditorInstance.getModel().getLanguageId();

    const autoFormatSupported = [
        'javascript', 'typescript', 'html', 'css', 'json'
    ];

    const tryFormat = [
        'scss', 'less', 'java', 'csharp', 'cpp', 'c', 'go', 'rust',
        'swift', 'kotlin', 'dart', 'scala', 'sql', 'xml'
    ];

    const unsupportedLanguages = [
        'php', 'markdown', 'shell', 'python', 'ruby', 'perl', 'groovy',
        'dockerfile', 'ini', 'bat', 'lua', 'r', 'fsharp', 'vb',
        'powershell', 'objective-c', 'plaintext'
    ];

    try {
        if (autoFormatSupported.includes(language)) {
            if (language === 'json') {
                const formatted = JSON.stringify(JSON.parse(content), null, 4);
                monacoEditorInstance.setValue(formatted);
            } else {
                monacoEditorInstance.getAction('editor.action.formatDocument')
                    .run()
                    .catch(() => {
                        alert(translations['format_unsupported'] || 'Formatting is not supported.');
                    });
            }
            alert(translations['format_success'] || 'Formatted successfully');
        } else if (language === 'yaml') {
            const obj = jsyaml.load(content);
            const formatted = jsyaml.dump(obj, { indent: 4 });
            monacoEditorInstance.setValue(formatted);
            alert(translations['format_success'] || 'Formatted successfully');
        } else if (tryFormat.includes(language)) {
            monacoEditorInstance.getAction('editor.action.formatDocument').run()
                .then(() => {
                    alert(translations['format_success'] || 'Formatted successfully');
                })
                .catch(() => {
                    alert(translations['format_unsupported'] || 'Formatting is not supported.');
                });
        } else if (unsupportedLanguages.includes(language)) {
            alert(translations['format_unsupported'] || 'Formatting is not supported.');
        } else {
            alert(translations['unsupported_format'] || 'Current mode does not support formatting');
        }
    } catch (e) {
        let errorMessage = translations['format_error'] || 'Formatting error: {message}';
        errorMessage = errorMessage.replace('{message}', e.message);
        alert(errorMessage);
    }
}

function validateJsonSyntax() {
    if (!monacoEditorInstance) return;
    
    const content = monacoEditorInstance.getValue();
    
    try {
        JSON.parse(content);
        alert(translations['json_syntax_valid'] || 'JSON syntax is valid');
    } catch (e) {
        let errorMessage = translations['json_syntax_error'] || 'JSON syntax error: {message}';
        errorMessage = errorMessage.replace('{message}', e.message);
        alert(errorMessage);
    }
}

function validateYamlSyntax() {
    if (!monacoEditorInstance) return;
    
    const content = monacoEditorInstance.getValue();
    
    try {
        jsyaml.load(content);
        alert(translations['yaml_syntax_valid'] || 'YAML syntax is valid');
    } catch (e) {
        let errorMessage = translations['yaml_syntax_error'] || 'YAML syntax error: {message}';
        errorMessage = errorMessage.replace('{message}', e.message);
        alert(errorMessage);
    }
}

function formatYamlContent() {
    if (!monacoEditorInstance) return;
    
    const content = monacoEditorInstance.getValue();
    
    try {
        const obj = jsyaml.load(content);
        const formatted = jsyaml.dump(obj, { indent: 4 });
        monacoEditorInstance.setValue(formatted);
        alert(translations['yaml_format_success'] || 'YAML formatted successfully');
    } catch (e) {
        let errorMessage = translations['yaml_format_error'] || 'YAML formatting error: {message}';
        errorMessage = errorMessage.replace('{message}', e.message);
        alert(errorMessage);
    }
}

function changeFontSize() {
    if (!monacoEditorInstance) return;
    const fontSizeSelect = document.getElementById('fontSize');
    if (fontSizeSelect) {
        const size = fontSizeSelect.value;
        console.log('Changing Font Size to:', size);
        monacoEditorInstance.updateOptions({ fontSize: parseInt(size.replace('px', '')) });
        localStorage.setItem('editorFontSize', size);
    } else {
        console.error('Font size select element not found during change!');
    }
}

function changeEditorTheme() {
    if (!monacoEditorInstance) return;
    const themeSelect = document.getElementById('editorTheme');
    if (themeSelect) {
        const theme = themeSelect.value;
        console.log('Changing Theme to:', theme);
        monaco.editor.setTheme(theme);
        localStorage.setItem('editorTheme', theme);
    } else {
        console.error('Theme select element not found during change!');
    }
}

function openSearch() {
    if (monacoEditorInstance) {
        monacoEditorInstance.trigger('custom', 'actions.find');
        setTimeout(localizeSearchWidget, 100);
    } else {
        console.error("Monaco Editor instance not initialized.");
    }
}

function localizeSearchWidget() {
    const matchesCountElement = document.querySelector('.find-actions .matchesCount');
    if (matchesCountElement) {
        if (matchesCountElement.textContent === 'No results') {
            matchesCountElement.textContent = translations['search.noResults'] || 'No results';
        }
    }

    const buttons = document.querySelectorAll('.find-actions .button, .monaco-custom-toggle, .replace-actions .button');
    buttons.forEach(button => {
        let title = button.getAttribute('title');
        let ariaLabel = button.getAttribute('aria-label');
        let textToCheck = title || ariaLabel || '';

        let clean = textToCheck.replace(/\(.*?\)/g, '').trim();

        if (clean.includes('Previous Match')) {
            let v = translations['search.previousMatch'] || 'Previous Match (Shift+Enter)';
            button.setAttribute('title', v);
            button.setAttribute('aria-label', v);
        } else if (clean.includes('Next Match')) {
            let v = translations['search.nextMatch'] || 'Next Match (Enter)';
            button.setAttribute('title', v);
            button.setAttribute('aria-label', v);
        } else if (clean.includes('Match Case')) {
            let v = translations['search.matchCase'] || 'Match Case (Alt+C)';
            button.setAttribute('title', v);
            button.setAttribute('aria-label', v);
        } else if (clean.includes('Match Whole Word')) {
            let v = translations['search.matchWholeWord'] || 'Match Whole Word (Alt+W)';
            button.setAttribute('title', v);
            button.setAttribute('aria-label', v);
        } else if (clean.includes('Use Regular Expression')) {
            let v = translations['search.useRegex'] || 'Use Regular Expression (Alt+R)';
            button.setAttribute('title', v);
            button.setAttribute('aria-label', v);
        } else if (clean.includes('Find in Selection')) {
            let v = translations['search.findInSelection'] || 'Find in Selection (Alt+L)';
            button.setAttribute('title', v);
            button.setAttribute('aria-label', v);
        } else if (clean.includes('Close')) {
            let v = translations['search.close'] || 'Close (Escape)';
            button.setAttribute('title', v);
            button.setAttribute('aria-label', v);
        } else if (clean.includes('Toggle Replace')) {
            let v = translations['search.toggleReplace'] || 'Toggle Replace';
            button.setAttribute('title', v);
            button.setAttribute('aria-label', v);
        } else if (clean.includes('Preserve Case')) {
            let v = translations['search.preserveCase'] || 'Preserve Case (Alt+P)';
            button.setAttribute('title', v);
            button.setAttribute('aria-label', v);
        } else if (clean.includes('Replace All')) {
            let v = translations['search.replaceAll'] || 'Replace All (Ctrl+Alt+Enter)';
            button.setAttribute('title', v);
            button.setAttribute('aria-label', v);
        } else if (clean.includes('Replace')) {
            let v = translations['search.replace'] || 'Replace (Enter)';
            button.setAttribute('title', v);
            button.setAttribute('aria-label', v);
        }
    });

    const findInput = document.querySelector('.find-part .monaco-inputbox textarea');
    if (findInput) {
        const v = translations['search.find'] || 'Find';
        findInput.setAttribute('placeholder', v);
        findInput.setAttribute('title', v);
        findInput.setAttribute('aria-label', v);
    }

    const replaceInput = document.querySelector('.replace-part .monaco-inputbox textarea');
    if (replaceInput) {
        const v = translations['search.replace'] || 'Replace';
        replaceInput.setAttribute('placeholder', v);
        replaceInput.setAttribute('title', v);
        replaceInput.setAttribute('aria-label', v);
    }
}

function toggleFullscreen() {
    const editor = document.getElementById('monacoEditor');
    
    if (!document.fullscreenElement) {
        editor.requestFullscreen().catch(err => {
            alert(`Fullscreen error: ${err.message}`);
        });
    } else {
        document.exitFullscreen();
    }
}

function previewFile(path, type) {
    const currentDir = decodeURIComponent(new URLSearchParams(window.location.search).get('dir') || '');
    const fullPath = currentDir + (currentDir.endsWith('/') ? '' : '/') + path;

    const previewContainer = document.getElementById('previewContainer');
    previewContainer.innerHTML = '<div class="text-center"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>';
    
    const modal = new bootstrap.Modal(document.getElementById('previewModal'));
    modal.show();
    
    if (type === 'mp3' || type === 'wav' || type === 'ogg' || type === 'flac') {
        previewContainer.innerHTML = `<audio controls><source src="?preview=1&path=${encodeURIComponent(fullPath)}" type="${getAudioMimeType(type)}">Your browser does not support audio playback.</audio>`;
    } else if (type === 'mp4' || type === 'webm' || type === 'avi' || type === 'mkv') {
        previewContainer.innerHTML = `<video controls><source src="?preview=1&path=${encodeURIComponent(fullPath)}" type="${getVideoMimeType(type)}">Your browser does not support video playback.</video>`;
    } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].includes(type)) {
        previewContainer.innerHTML = `<img src="?preview=1&path=${encodeURIComponent(fullPath)}" onerror="this.alt='Failed to load image.'">`;
    } else {
        previewContainer.innerHTML = `<p>Preview not supported for this file type (${type}). <a href="?preview=1&path=${encodeURIComponent(fullPath)}" download="${path.split('/').pop()}">Click here to download</a>.</p>`;
    }
}

function getAudioMimeType(type) {
    const mimeTypes = {
        'mp3': 'audio/mpeg',
        'wav': 'audio/wav',
        'ogg': 'audio/ogg',
        'flac': 'audio/flac'
    };
    return mimeTypes[type] || 'audio/mpeg';
}

function getVideoMimeType(type) {
    const mimeTypes = {
        'mp4': 'video/mp4',
        'webm': 'video/webm',
        'avi': 'video/x-msvideo',
        'mkv': 'video/x-matroska'
    };
    return mimeTypes[type] || 'video/mp4';
}

function uniqueConfirmDelete(event, name) {
    let confirmMessage = translations['delete_confirm'] || '⚠️ Are you sure you want to delete "{name}"? This action cannot be undone!';
    
    confirmMessage = confirmMessage.replace('{name}', name);
    
    showConfirmation(encodeURIComponent(confirmMessage), () => {
        event.target.submit();
    });
    return false;
}

</script>
