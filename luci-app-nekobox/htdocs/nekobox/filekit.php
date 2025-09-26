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
    
    foreach ($_FILES["upload"]["error"] as $key => $error) {
        if ($error == UPLOAD_ERR_OK) {
            $tmp_name = $_FILES["upload"]["tmp_name"][$key];
            $name = basename($_FILES["upload"]["name"][$key]);
            $target_file = rtrim($destination, '/') . '/' . $name;
            
            if (file_exists($target_file)) {
                $errors[] = "The file $name already exists.";
                continue;
            }
            
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

<title>Filekit - Nekobox</title>
<?php include './ping.php'; ?>
<link rel="icon" href="./assets/img/nekobox.png">
<script src="https://cdnjs.cloudflare.com/ajax/libs/ace/1.32.6/ace.js"></script>
<script src="./assets/js/js-yaml.min.js"></script>
<script src="./assets/js/ext-language_tools.js"></script>
<script src="./assets/js/mode-json.min.js"></script>
<script src="./assets/js/mode-yaml.min.js"></script>
<script src="./assets/js/beautify.min.js"></script>
<script src="./assets/js/beautify-css.min.js"></script>
<script src="./assets/js/beautify-html.min.js"></script>
<script src="./assets/js/beautify.min.js"></script>
<script src="./assets/js/ext-beautify.min.js"></script>
<script src="./assets/js/ext-spellcheck.min.js"></script>

<style>
.folder-icon::before{content:"📁";}.file-icon::before{content:"📄";}.file-icon.file-pdf::before{content:"📕";}.file-icon.file-doc::before,.file-icon.file-docx::before{content:"📘";}.file-icon.file-xls::before,.file-icon.file-xlsx::before{content:"📗";}.file-icon.file-ppt::before,.file-icon.file-pptx::before{content:"📙";}.file-icon.file-zip::before,.file-icon.file-rar::before,.file-icon.file-7z::before{content:"🗜️";}.file-icon.file-mp3::before,.file-icon.file-wav::before,.file-icon.file-ogg::before,.file-icon.file-flac::before{content:"🎵";}.file-icon.file-mp4::before,.file-icon.file-avi::before,.file-icon.file-mov::before,.file-icon.file-wmv::before,.file-icon.file-flv::before{content:"🎞️";}.file-icon.file-jpg::before,.file-icon.file-jpeg::before,.file-icon.file-png::before,.file-icon.file-gif::before,.file-icon.file-bmp::before,.file-icon.file-tiff::before{content:"🖼️";}.file-icon.file-txt::before{content:"📝";}.file-icon.file-rtf::before{content:"📄";}.file-icon.file-md::before,.file-icon.file-markdown::before{content:"📑";}.file-icon.file-exe::before,.file-icon.file-msi::before{content:"⚙️";}.file-icon.file-bat::before,.file-icon.file-sh::before,.file-icon.file-command::before{content:"📜";}.file-icon.file-iso::before,.file-icon.file-img::before{content:"💿";}.file-icon.file-sql::before,.file-icon.file-db::before,.file-icon.file-dbf::before{content:"🗃️";}.file-icon.file-font::before,.file-icon.file-ttf::before,.file-icon.file-otf::before,.file-icon.file-woff::before,.file-icon.file-woff2::before{content:"🔤";}.file-icon.file-cfg::before,.file-icon.file-conf::before,.file-icon.file-ini::before{content:"🔧";}.file-icon.file-psd::before,.file-icon.file-ai::before,.file-icon.file-eps::before,.file-icon.file-svg::before{content:"🎨";}.file-icon.file-dll::before,.file-icon.file-so::before{content:"🧩";}.file-icon.file-css::before{content:"🎨";}.file-icon.file-js::before{content:"🟨";}.file-icon.file-php::before{content:"🐘";}.file-icon.file-json::before{content:"📊";}.file-icon.file-html::before,.file-icon.file-htm::before{content:"🌐";}.file-icon.file-bin::before{content:"👾";}

#aceEditor {
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

#aceEditorContainer {
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

#encoding, #editorTheme, #fontSize {
	background-color: var(--header-bg) !important;
	color: #ffffff !important;
	border: 1px solid #ccc !important;
	padding: 5px !important;
	border-radius: 4px !important;
	appearance: none !important;
}

#encoding option,
#editorTheme option,
#fontSize option {
	background-color: #ffffff !important;
	color: #000000 !important
}

#encoding option:checked,
#editorTheme option:checked,
#fontSize option:checked {
	background-color: #cce5ff !important;
}

button.editor-btn {
	background-color: var(--header-bg) !important;
	color: #ffffff !important;
	border: 1px solid var(--header-bg) !important;
	border-radius: 4px !important;
}

button.editor-btn:hover {
	background-color: var(--header-bg) !important;
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

#editorControls select,
#editorControls button {
	padding: 5px 10px;
	font-size: 13px;
	height: 30px;
	border: 1px solid #ccc;
	border-radius: 4px;
	background-color: #fff;
	cursor: pointer;
	flex-shrink: 0;
}

#editorControls button:hover {
	background-color: #e8e8e8;
}

#editorControls select:hover {
	background-color: #f2f2f2;
}

.ace_editor {
	width: 100% !important;
	height: 100% !important;
}

@media (max-width: 768px) {
	#fontSize,
        #editorTheme {
		display: none !important;
	}

	#statusInfo {
		position: fixed !important;
		bottom: 10% !important;
		left: 0;
		width: 100%;
		background-color: var(--header-bg);
		border-top: 1px solid #ddd;
		padding: 5px 10px;
		text-align: center;
		z-index: 1050;
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
	border: 2px dashed #ccc !important;
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

.ace_search {
	background: var(--bg-container) !important;
	border: 1px solid var(--border-color) !important;
	border-radius: var(--radius);
	box-shadow: var(--item-hover-shadow);
	padding: 8px 12px !important;
	color: var(--text-primary);
	backdrop-filter: var(--glass-blur);
	transition: var(--transition);
}

.ace_search_form, .ace_replace_form {
	display: flex;
	align-items: center;
	gap: 8px;
	margin-bottom: 8px;
}

.ace_search_field {
	background: var(--card-bg) !important;
	border: 1px solid var(--border-color) !important;
	color: var(--text-primary) !important;
	padding: 6px 12px !important;
	border-radius: calc(var(--radius) - 4px) !important;
	font-size: 14px !important;
	min-width: 200px;
	transition: var(--transition);
}

.ace_search_field:focus {
	border-color: var(--accent-color) !important;
	outline: none;
	box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent-color), transparent 70%);
}

.ace_searchbtn {
	background: var(--btn-primary-bg) !important;
	color: white !important;
	border: none !important;
	border-radius: calc(var(--radius) - 4px) !important;
	background-image: none !important;
	padding: 6px 12px !important;
	font-size: 13px !important;
	cursor: pointer;
	transition: var(--transition);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	min-width: 60px;
	filter: contrast(1.2) brightness(1.1);
}

.ace_searchbtn:hover {
	background: var(--btn-primary-hover) !important;
	color: white !important;
}

.ace_searchbtn.prev,
.ace_searchbtn.next {
	position: relative;
}

.ace_searchbtn.prev::before,
.ace_searchbtn.next::before {
	content: "";
	font-size: 14px;
	color: white !important;
	filter: contrast(1.3);
	display: inline-block;
	line-height: 1;
}

.ace_searchbtn.prev::before {
	content: "↑";
}

.ace_searchbtn.next::before {
	content: "↓";
}

.ace_searchbtn .ace_icon,
.ace_searchbtn::after {
	display: none !important;
	opacity: 0 !important;
}

.ace_searchbtn_close {
	background: transparent !important;
	color: var(--text-secondary) !important;
	position: absolute;
	right: 12px;
	top: 12px;
	cursor: pointer;
	font-size: 16px;
	transition: var(--transition);
	width: 20px;
	height: 20px;
	display: flex;
	align-items: center;
	justify-content: center;
	border-radius: 3px;
}

.ace_searchbtn_close:hover {
	color: white !important;
	background: var(--btn-primary-bg) !important;
}

.ace_searchbtn_close::before {
	content: "×";
}

.ace_search_options {
	display: flex;
	align-items: center;
	gap: 8px;
	margin-top: 8px;
}

.ace_button {
	background: var(--btn-primary-bg) !important;
	color: white !important;
	border: none !important;
	border-radius: calc(var(--radius) - 4px) !important;
	padding: 4px 8px !important;
	font-size: 12px !important;
	cursor: pointer;
	transition: var(--transition);
	filter: contrast(1.2);
}

.ace_button:hover {
	background: var(--btn-primary-hover) !important;
	color: white !important;
}

.ace_search_counter {
	color: var(--text-secondary);
	font-size: 12px;
	margin-right: auto;
}

[action="toggleRegexpMode"] {
	background: var(--btn-info-bg) !important;
	color: white !important;
}
[action="toggleCaseSensitive"] {
	background: var(--btn-warning-bg) !important;
	color: white !important;
}
[action="toggleWholeWords"] {
	background: var(--btn-success-bg) !important;
	color: white !important;
}
[action="searchInSelection"] {
	background: var(--ocean-bg) !important;
	color: white !important;
}
[action="toggleReplace"] {
	background: var(--lavender-bg) !important;
	color: white !important;
}

.ace_searchbtn,
.ace_button,
.ace_searchbtn_close:hover {
	text-shadow: 0 1px 1px rgba(0, 0, 0, 0.3);
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
<div class="container-sm container-bg px-1 px-sm-4 mt-4">
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
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'subscription.php' ? 'active' : '' ?>" href="./subscription.php"><i class="bi bi-bank"></i> <span data-translate="template_ii">Template II</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'mihomo.php' ? 'active' : '' ?>" href="./mihomo.php"><i class="bi bi-building"></i> <span data-translate="template_iii">Template III</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'netmon.php' ? 'active' : '' ?>" href="./netmon.php"><i class="bi bi-activity"></i> <span data-translate="traffic_monitor">Traffic Monitor</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'filekit.php' ? 'active' : '' ?>" href="./filekit.php"><i class="bi bi-bank"></i> <span data-translate="pageTitle">File Assistant</span></a>
                </li>
            </ul>
            <div class="d-flex align-items-center">
                <div class="me-3 d-block">
                    <button type="button" class="btn btn-primary icon-btn me-2" onclick="toggleControlPanel()" data-translate-title="control_panel"><i class="bi bi-gear"> </i></button>
                    <button type="button" class="btn btn-danger icon-btn me-2" data-bs-toggle="modal" data-bs-target="#langModal"  data-translate-title="set_language"><i class="bi bi-translate"></i></button>
                    <button type="button" class="btn btn-success icon-btn me-2" data-bs-toggle="modal" data-bs-target="#musicModal" data-translate-title="music_player"><i class="bi bi-music-note-beamed"></i></button>
                    <button type="button" id="toggleIpStatusBtn" class="btn btn-warning icon-btn me-2" onclick="toggleIpStatusBar()" data-translate-title="hide_ip_info"><i class="bi bi-eye-slash"> </i></button>
                    <button type="button" class="btn btn-pink icon-btn me-2" data-bs-toggle="modal" data-bs-target="#portModal" data-translate-title="viewPortInfoButton"><i class="bi bi-plug"></i></button>
                    <button type="button" class="btn btn-info icon-btn me-2" onclick="document.getElementById('colorPicker').click()" data-translate-title="component_bg_color"><i class="bi bi-palette"></i></button>
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
        <button type="button" class="btn btn-secondary btn-sm ms-2" onclick="hideUploadArea()" data-translate="cancel">Cancel</button>
      </div>

      <form action="" method="post" enctype="multipart/form-data" id="uploadForm">
        <input type="file" name="upload[]" id="fileInput" style="display: none;" multiple required>
        <div class="upload-drop-zone p-4 border rounded bg-light" id="dropZone">
          <i class="fas fa-cloud-upload-alt upload-icon"></i>
        </div>
      </form>
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

<div class="container-fluid text-center">
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
                            $icon_class = $item['is_dir'] ? 'folder-icon' : 'file-icon';
                            if (!$item['is_dir']) {
                                $ext = strtolower(pathinfo($item['name'], PATHINFO_EXTENSION));
                                $icon_class .= ' file-' . $ext;
                            }
                        ?>

                        <td class="<?php echo $icon_class; ?>">
                            <?php if ($item['is_dir']): ?>
                                <a href="?dir=<?php echo urlencode($current_dir . $item['path']); ?>">
                                    <?php echo htmlspecialchars($item['name']); ?>
                                </a>
                            <?php else: ?>
                                <?php
                                    $ext = strtolower(pathinfo($item['name'], PATHINFO_EXTENSION));
                                    if (in_array($ext, ['jpg','jpeg','png','gif','svg','mp3','mp4'])):
                                        $clean_path = ltrim(str_replace('//', '/', $item['path']), '/');
                                ?>
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
        <button type="button" onclick="openAceEditor()" class="btn btn-danger" data-translate="advancedEdit">Advanced Edit</button>
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close">Close</button>
      </div>
    </form>
  </div>
</div>

<div id="aceEditor">
    <div id="editorControls">
    <div id="leftControls">
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

            <button type="button" class="btn btn-sm editor-btn" onclick="openSearch()" data-translate="search"></button>
            <button type="button" class="btn btn-sm editor-btn d-none d-sm-inline" id="toggleFullscreenBtn" onclick="toggleFullscreen()" data-translate="toggleFullscreen"></button>
            <button type="button" class="btn btn-sm editor-btn" onclick="formatContent()" data-translate="format">Format</button>
            <button type="button" class="btn btn-sm editor-btn" id="jsonValidationBtn" onclick="validateJsonSyntax()" style="display:none;" data-translate="validateJson">Validate JSON</button>
            <button type="button" class="btn btn-sm editor-btn" id="yamlValidationBtn" onclick="validateYamlSyntax()" style="display:none;" data-translate="validateYaml">Validate YAML</button>
            <button type="button" class="btn btn-sm editor-btn" id="yamlFormatBtn" onclick="formatYamlContent()" style="display:none;" data-translate="formatYaml">Format YAML</button>
            <button type="button" class="btn btn-sm editor-btn" onclick="saveFullScreenContent()" data-translate="saveButton">Save</button>
            <button type="button" class="btn btn-sm editor-btn" onclick="closeAceEditor()" data-translate="close">Close</button>
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
    </div>
  </div>
</div>

<script>
let selectedFiles = [];
let editor = null;
let currentFilePath = '';
let currentFileContent = '';
let selectedFilesSize = 0;

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
            handleFiles(this.files);
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
    
    dropZone.addEventListener('drop', handleDrop, false);
    
    function handleDrop(e) {
        const dt = e.dataTransfer;
        const files = dt.files;
        handleFiles(files);
    }
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

function openAceEditor() {
    const editModal = bootstrap.Modal.getInstance(document.getElementById('editModal'));
    if (editModal) {
        editModal.hide();
    }

    document.querySelectorAll('.modal-backdrop').forEach(backdrop => backdrop.remove());

    const content = document.getElementById('editContent').value;
    const path = document.getElementById('editPath').value;
    
    const editorContainer = document.createElement('div');
    editorContainer.id = 'aceEditorContainer';
    editorContainer.style.width = '100%';
    editorContainer.style.height = 'calc(100% - 40px)';
    
    document.getElementById('aceEditor').style.display = 'flex';
    document.getElementById('aceEditor').appendChild(editorContainer);
    
    aceEditorInstance = ace.edit('aceEditorContainer');
    aceEditorInstance.setTheme("ace/theme/vibrant_ink");
    aceEditorInstance.session.setMode("ace/mode/yaml"); 
    aceEditorInstance.session.setMode("ace/mode/text");
    aceEditorInstance.setValue(content, -1);
    aceEditorInstance.setOptions({
        fontSize: "20px",
        wrap: true,
        enableBasicAutocompletion: true,
        enableLiveAutocompletion: true
    });
    
    const ext = path.split('.').pop().toLowerCase();
    setEditorMode(ext);
    
    updateEditorStatus();
    
    aceEditorInstance.getSession().on('change', function() {
        document.getElementById('editContent').value = aceEditorInstance.getValue();
        updateEditorStatus();
        detectContentFormat();
        aceEditorInstance.resize();
        aceEditorInstance.getSession().bgTokenizer.start(0);
    });
    
    aceEditorInstance.selection.on('changeCursor', updateEditorStatus);
    
    detectContentFormat();
    
    setTimeout(() => {
        aceEditorInstance.focus();
    }, 100);
    
    document.getElementById('aceEditor').onclick = function(e) {
        if (e.target === this) {
            closeAceEditor();
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
        'sh': 'sh',
        'py': 'python'
    };
    
    if (modes[ext]) {
        aceEditorInstance.session.setMode(`ace/mode/${modes[ext]}`);
    } else {
        aceEditorInstance.session.setMode('ace/mode/text');
    }
}

function closeAceEditor() {
    if (aceEditorInstance) {

        document.getElementById('editContent').value = aceEditorInstance.getValue();
        aceEditorInstance.destroy();
        aceEditorInstance = null;
    }
    document.getElementById('aceEditor').style.display = 'none';
    const container = document.getElementById('aceEditorContainer');
    if (container) {
        container.remove();
    }

    // const editModal = new bootstrap.Modal(document.getElementById('editModal'));
    // editModal.show();
}

function saveFullScreenContent() {
    if (aceEditorInstance) {
        document.getElementById('editContent').value = aceEditorInstance.getValue();
        closeAceEditor();
        document.getElementById('editForm').submit();
    }
}

function detectContentFormat() {
    if (!aceEditorInstance) return;
    
    const content = aceEditorInstance.getValue().trim();
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
    const cursor = aceEditorInstance.getCursorPosition();
    const line = cursor.row + 1;
    const column = cursor.column + 1;
    const charCount = aceEditorInstance.getValue().length;

    const lineColumnText = langData[currentLang]['lineColumnDisplay'].replace("{line}", line).replace("{column}", column);
    const charCountText = langData[currentLang]['charCountDisplay'].replace("{charCount}", charCount);

    document.getElementById('lineColumnDisplay').textContent = lineColumnText;
    document.getElementById('charCountDisplay').textContent = charCountText;
}
$(document).ready(function() {
    initializeAceEditor();
});

function formatContent() {
    if (!aceEditorInstance) return;
    
    const content = aceEditorInstance.getValue();
    const mode = aceEditorInstance.session.getMode().$id;
    
    try {
        if (mode === 'ace/mode/json') {
            const formatted = JSON.stringify(JSON.parse(content), null, 4);
            aceEditorInstance.setValue(formatted, -1);
            alert(translations['json_format_success'] || 'JSON formatted successfully');
        } else if (mode === 'ace/mode/javascript') {
            const formatted = js_beautify(content);
            aceEditorInstance.setValue(formatted, -1);
            alert(translations['js_format_success'] || 'JavaScript formatted successfully');
        } else {
            alert(translations['format_not_supported'] || 'Current mode does not support formatting');
        }
    } catch (e) {
        alert((translations['format_error'] || 'Formatting error: ') + e.message);
    }
}

function validateJsonSyntax() {
    if (!aceEditorInstance) return;
    
    const content = aceEditorInstance.getValue();
    
    try {
        JSON.parse(content);
        alert(translations['json_syntax_valid'] || 'JSON syntax is valid');
    } catch (e) {
        alert((translations['json_syntax_error'] || 'JSON syntax error: ') + e.message);
    }
}

function validateYamlSyntax() {
    if (!aceEditorInstance) return;
    
    const content = aceEditorInstance.getValue();
    
    try {
        jsyaml.load(content);
        alert(translations['yaml_syntax_valid'] || 'YAML syntax is valid');
    } catch (e) {
        alert((translations['yaml_syntax_error'] || 'YAML syntax error: ') + e.message);
    }
}

function formatYamlContent() {
    if (!aceEditorInstance) return;
    
    const content = aceEditorInstance.getValue();
    
    try {
        const obj = jsyaml.load(content);
        const formatted = jsyaml.dump(obj, {indent: 4});
        aceEditorInstance.setValue(formatted, -1);
        alert(translations['yaml_format_success'] || 'YAML formatted successfully');
    } catch (e) {
        alert((translations['yaml_format_error'] || 'YAML formatting error: ') + e.message);
    }
}

function changeFontSize() {
    if (!aceEditorInstance) return;
    const size = document.getElementById('fontSize').value;
    aceEditorInstance.setFontSize(size);
}

function changeEditorTheme() {
    if (!aceEditorInstance) return;
    const theme = document.getElementById('editorTheme').value;
    aceEditorInstance.setTheme(theme);
}

function openSearch() {
    if (aceEditorInstance) {
        aceEditorInstance.execCommand("find");
        setTimeout(function() {
            const searchBox = document.querySelector(".ace_search");
            if (searchBox) {
                const searchInput = searchBox.querySelector(".ace_search_form .ace_search_field");
                if (searchInput) {
                    searchInput.placeholder = translations['search_placeholder'] || 'Search...';
                }

                const replaceInput = searchBox.querySelector(".ace_replace_form .ace_search_field");
                if (replaceInput) {
                    replaceInput.placeholder = translations['replace_placeholder'] || 'Replace with...';
                }

                const buttons = searchBox.querySelectorAll(".ace_searchbtn");
                buttons.forEach(button => {
                    const action = button.getAttribute("action");
                    if (action === "findPrev") {
                        button.textContent = "";
                        button.onclick = function() {
                            aceEditorInstance.execCommand("findprevious");
                            aceEditorInstance.scrollToLine(aceEditorInstance.getCursorPosition().row, true, true);
                        };
                    } else if (action === "findNext") {
                        button.textContent = "";
                        button.onclick = function() {
                            aceEditorInstance.execCommand("findnext");
                            aceEditorInstance.scrollToLine(aceEditorInstance.getCursorPosition().row, true, true);
                        };
                    } else if (action === "findAll") {
                        button.textContent = translations['find_all'] || 'All';
                    } else if (action === "replaceAndFindNext") {
                        button.textContent = translations['replace'] || 'Replace';
                    } else if (action === "replaceAll") {
                        button.textContent = translations['replace_all'] || 'Replace All';
                    }
                });

                const optionButtons = searchBox.querySelectorAll(".ace_button");
                optionButtons.forEach(button => {
                    const action = button.getAttribute("action");
                    if (action === "toggleReplace") {
                        button.title = translations['toggle_replace_mode'] || 'Toggle Replace Mode';
                    } else if (action === "toggleRegexpMode") {
                        button.title = translations['toggle_regexp_mode'] || 'Regular Expression Search';
                    } else if (action === "toggleCaseSensitive") {
                        button.title = translations['toggle_case_sensitive'] || 'Case-Sensitive Search';
                    } else if (action === "toggleWholeWords") {
                        button.title = translations['toggle_whole_words'] || 'Whole Word Search';
                    } else if (action === "searchInSelection") {
                        button.title = translations['search_in_selection'] || 'Search in Selection';
                    }
                });

                const counter = searchBox.querySelector(".ace_search_counter");
                if (counter && counter.textContent.includes("of")) {
                    counter.textContent = counter.textContent.replace("of", translations['search_counter_of'] || 'of');
                }
            }
        }, 100);
    } else {
        console.error("Ace Editor instance not initialized.");
    }
}

function toggleFullscreen() {
    const editor = document.getElementById('aceEditor');
    
    if (!document.fullscreenElement) {
        editor.requestFullscreen().catch(err => {
            alert(`Fullscreen error: ${err.message}`);
        });
    } else {
        document.exitFullscreen();
    }
}

function previewFile(path, type) {
    const previewContainer = document.getElementById('previewContainer');
    previewContainer.innerHTML = '<div class="text-center"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>';
    
    const modal = new bootstrap.Modal(document.getElementById('previewModal'));
    modal.show();
    
    if (type === 'mp3') {
        previewContainer.innerHTML = `<audio controls style="width: 100%"><source src="?preview=1&path=${encodeURIComponent(path)}" type="audio/mpeg">Your browser does not support audio playback.</audio>`;
    } else if (type === 'mp4') {
        previewContainer.innerHTML = `<video controls style="width: 100%"><source src="?preview=1&path=${encodeURIComponent(path)}" type="video/mp4">Your browser does not support video playback.</video>`;
    } else {
        previewContainer.innerHTML = `<img src="?preview=1&path=${encodeURIComponent(path)}" style="max-width: 100%; max-height: 80vh;" class="img-fluid">`;
    }
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




