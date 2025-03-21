<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $primaryColor = $_POST['primaryColor'] ?? '#30e8dc'; 
    $secondaryColor = $_POST['secondaryColor'] ?? '#00ffff'; 
    $bodyBgColor = $_POST['bodyBgColor'] ?? '#23407e'; 
    $bodyColor = $_POST['bodyColor'] ?? '#4eedf9'; 
    $infoBgSubtle = $_POST['infoBgSubtle'] ?? '#23407e'; 
    $primaryBorderSubtle = $_POST['primaryBorderSubtle'] ?? '#1815d1'; 
    $tertiaryColor = $_POST['tertiaryColor'] ?? '#46e1ec'; 
    $tertiaryRgbColor = $_POST['tertiaryRgbColor'] ?? '#df38f5'; 
    $selectColor = $_POST['selectColor'] ?? '#23407e'; 
    $backgroundColor = $_POST['backgroundColor'] ?? '#20cdd9'; 
    $placeholderColor = $_POST['placeholderColor'] ?? '#f8f9fa';
    $logTextColor = $_POST['logTextColor'] ?? '#f8f9fa'; 
    $heading1Color = $_POST['heading1Color'] ?? '#21e4f2'; 
    $heading2Color = $_POST['heading2Color'] ?? '#65f1fb'; 
    $heading3Color = $_POST['heading3Color'] ?? '#ffcc00'; 
    $heading4Color = $_POST['heading4Color'] ?? '#00fbff'; 
    $heading5Color = $_POST['heading5Color'] ?? '#ba13f6'; 
    $heading6Color = $_POST['heading6Color'] ?? '#00ffff'; 
    $outlineColor = $_POST['outlineColor'] ?? '#0dcaf0'; 
    $successColor = $_POST['successColor'] ?? '#28a745'; 
    $infoColor = $_POST['infoColor'] ?? '#0ca2ed'; 
    $warningColor = $_POST['warningColor'] ?? '#ffc107'; 
    $pinkColor = $_POST['pinkColor'] ?? '#f82af2';
    $dangerColor = $_POST['dangerColor'] ?? '#dc3545';
    $controlColor = $_POST['controlColor'] ?? '#f8f9fa';
    $checkColor = $_POST['checkColor'] ?? '#f8f9fa';
    $labelColor = $_POST['labelColor'] ?? '#248cf5';
    $lineColor = $_POST['lineColor'] ?? '#f515f9';
    $disabledColor = $_POST['disabledColor'] ?? '#23407e';
    $radiusColor = $_POST['radiusColor'] ?? '#28edf0';
    $ipColor = $_POST['ipColor'] ?? '#09B63F';
    $ipipColor = $_POST['ipipColor'] ?? '#ff69b4';
    $detailColor = $_POST['detailColor'] ?? '#15d1bb';
    $themeName = isset($_POST['themeName']) ? $_POST['themeName'] : 'transparent';   

    $themeName = preg_replace('/[^a-zA-Z0-9_\-一-龯]/u', '', $themeName);
    if (empty($themeName)) {
        $themeName = 'transparent'; 
    }
    
    $themeFileName = $themeName . '.css';

    $uploadedImagePath = '';
    if (isset($_FILES['imageFile']) && $_FILES['imageFile']['error'] === UPLOAD_ERR_OK) {
        $targetDir = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/assets/Pictures/';
        if (!file_exists($targetDir)) {
            mkdir($targetDir, 0777, true); 
        }
        $targetFile = $targetDir . basename($_FILES['imageFile']['name']);
        if (move_uploaded_file($_FILES['imageFile']['tmp_name'], $targetFile)) {
            $uploadedImagePath = '/nekobox/assets/Pictures/' . basename($_FILES['imageFile']['name']);
        }
    }

    $backgroundImagePath = $_POST['backgroundImage'] ?? '';
    $cssContent = "
  
[data-bs-theme='$themeName'] {
	color-scheme: dark;
	--bs-primary: $primaryColor;
	--bs-secondary: $secondaryColor;
	--bs-body-bg: $bodyBgColor;
	--bs-body-color: $bodyColor;
	--bs-info-bg-subtle: $infoBgSubtle;
	--placeholder-color: $placeholderColor;
	--bs-btn-outline-bg: $outlineColor;
	--bs-btn-success-bg: $successColor;
	--bs-btn-info-bg: $infoColor;
	--bs-btn-warning-bg: $warningColor;
	--bs-btn-pink-bg: $pinkColor;
	--bs-btn-danger-bg: $dangerColor;
	--bs-controlr-bg: $controlColor;
	--bs-check-bg: $checkColor;
	--bs-label-bg: $labelColor;
	--bs-line-bg: $lineColor;
	--bs-disabled-bg: $disabledColor;
	--bs-radius-bg: $radiusColor;
	--bs-ip-bg: $ipColor;
	--bs-ipip-bg: $ipipColor;
	--bs-detail-bg: $detailColor;
	--bs-primary-border-subtle: $primaryBorderSubtle;
	--bs-tertiary: $tertiaryColor;
	--bs-tertiary-rgb: $tertiaryRgbColor;
	--bs-tertiary-color: $primaryBorderSubtle;
	--bs-tertiary-color-rgb: $backgroundColor;
	--bs-form-select: $selectColor;
	--log-text-color: $logTextColor;
	--bs-heading-1: $heading1Color;
	--bs-heading-2: $heading2Color;
	--bs-heading-3: $heading3Color;
	--bs-heading-4: $heading4Color;
	--bs-heading-5: $heading5Color;
	--bs-heading-6: $heading6Color;
	--bs-heading-font-family: 'Montserrat', sans-serif;
	--bs-heading-font-weight: 700;
	--bs-heading-letter-spacing: 0.05em;
	--bs-heading-text-transform: uppercase;
	--bs-btn-color: #fff;
	--bs-btn-hover-color: #fff;
	--bs-btn-active-color: #fff;
	--bs-btn-disabled-color: #fff;
	--bs-body-font-family: 'Avant Garde', Avantgarde, 'Century Gothic', CenturyGothic, AppleGothic, sans-serif;
}

body {
	background-color: var(--bs-body-bg);
	color: var(--bs-body-color);
	-webkit-font-smoothing: antialiased;
	-moz-osx-font-smoothing: grayscale;
	text-rendering: optimizeLegibility;
      " . ($backgroundImagePath ? "
	background-image: url('$backgroundImagePath');
	background-repeat: no-repeat;
	background-position: center center;
	background-attachment: fixed;
	background-size: cover;
" : "") . "
      " . ($uploadedImagePath && empty($backgroundImagePath) ? "
	background-image: url('$uploadedImagePath');
	background-repeat: no-repeat;
	background-position: center center;
	background-attachment: fixed;
	background-size: cover;
" : "") . "
}

h1 {
	color: var(--bs-heading-1) !important;
}

h2 {
	color: var(--bs-heading-2) !important;
}

h3 {
	color: var(--bs-heading-3) !important;
}

h4 {
	color: var(--bs-heading-4) !important;
}

h5 {
	color: var(--bs-heading-5) !important;
}

h6 {
	color: var(--bs-heading-6) !important;
}

input::placeholder {
	color: var(--log-text-color) !important;
}

.table, .form-control, .card, button, label, li, td, th, blockquote, q, code, pre {
	background-color: transparent;
	color: var(--log-text-color);
}

input::placeholder {
	color: var(--placeholder-color) !important;
	font-weight: bold;
}

input.form-control:disabled {
	background-color: var(--bs-disabled-bg) !important;
}

#lineColumnDisplay, #charCountDisplay {
	color: var(--bs-line-bg) !important;
}

#ip-address {
	color: var(--bs-ip-bg) !important;
}

#ipip {
	color: var(--bs-ipip-bg) !important;
}

#ipDetailModal .detail-value {
	color: var(--bs-detail-bg) !important;
}

#ipDetailModal .detail-label {
	color: var(--bs-detail-bg) !important;
}

#ipDetailModal .modal-title:not([class]) {
	color: var(--bs-heading-5) !important;
}

#ipDetailModal h5:not([class]) {
	color: var(--bs-heading-5) !important;
}

.form-label {
	color: var(--bs-check-bg)
}

.form-check-label {
	color: var(--bs-check-bg)
}

label {
	color: var(--bs-label-bg)
}

.form-control {
	color: var(--bs-controlr-bg)
}

form .form-control {
	color: var(--bs-controlr-bg) !important;
}

.card .card-body pre {
	color: var(--log-text-color) !important;
}

.alert-info {
	color: #FF00FF;
}

.detail-label {
	color: #FF00FF !important;
}

.detail-value {
	color: #00ff00 !important;
}

.form-select {
	background-color: var(--bs-form-select);
	color: var(--bs-radius-bg) !important;
	border: 1px solid gray;
	border-radius: 5px;
}

.form-select option {
        background-color: oklch(45% .24 277.023) !important;
	background-color: var(--bs-form-select);
	color: var(--bs-radius-bg) !important;
}

.form-control {
	background-color: transparent;
	border-color: #000000;
	box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.2), 0 4px 6px rgba(0, 0, 0, 0.1);
	color: #ffffff;
}

.table {
	--bs-table-bg: transparent;
}

.table thead th {
	color: var(--bs-tertiary-color) !important;
	background-color: var(--bs-tertiary-color-rgb) !important;
}

table td:nth-child(1) {
	color: var(--bs-tertiary) !important;
}

table td:nth-child(2) {
	color: var(--bs-tertiary-rgb) !important;
}

table td:nth-child(3) {
	color: #FF00FF !important;
}

table td:nth-child(4) {
	color: #00FFFF !important;
}

table.table tr,
    table.table td {
	background-color: transparent !important;
}

table.table tbody td:nth-child(5), 
    table.table tbody td:nth-child(6),
    table.table tbody td:nth-child(7) {
	color: white !important;
}

table.table tbody td:nth-child(2) a {
	color: #FF00FF !important;
}

.btn-outline-secondary i {
	color: white;
}

.btn-close {
	width: 15px !important;
	height: 15px !important;
	background-color: rgba(0, 0, 0, 0.08) !important;
	border-radius: 6px !important;
	border: none !important;
	position: relative !important;
	display: flex !important;
	align-items: center !important;
	justify-content: center !important;
	cursor: pointer !important;
	transition: background-color 0.2s ease, transform 0.2s ease !important;
}

.btn-close::before, 
.btn-close::after {
	content: '' !important;
	position: absolute !important;
	width: 12px !important;
	height: 2px !important;
	background-color: #ff4d4f !important;
	border-radius: 2px !important;
	transition: background-color 0.2s ease !important;
}

.btn-close::before {
	transform: rotate(45deg) !important;
}

.btn-close::after {
	transform: rotate(-45deg) !important;
}

.btn-close:hover {
	background-color: #30e8dc !important;
}

.btn-close:hover::before, 
.btn-close:hover::after {
	background-color: #d9363e !important;
}

.btn-close:active {
	transform: scale(0.9) !important;
}

button {
	background-color: var(--bs-primary);
	border: 1px solid rgba(255, 255, 255, 0.5);
	box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1), 0 1px 3px rgba(0, 0, 0, 0.08);
	color: #ffffff;
}

.btn-warning {
	color: #ffffff;
}

.btn-warning:hover, .btn-warning:focus, .btn-warning:active {
	color: #ffffff;
}

.btn-info {
	color: #ffffff;
}

.btn-info:hover, 
    .btn-info:focus, 
    .btn-info:active {
	color: #ffffff;
}

.btn-primary:hover {
	background-color: #0069d9;
}

.btn-success:hover {
	background-color: #218838;
}

.btn-info:hover {
	background-color: #17a2b8;
}

.btn-warning:hover {
	background-color: #e0a800;
}

.btn-pink:hover {
	background-color: #d6336c;
}

.btn-primary {
	background-color: var(--bs-btn-outline-bg) !important;
	border-color: var(--bs-btn-outline-bg) !important;
}

.btn-success {
	background-color: var(--bs-btn-success-bg) !important;
	border-color: var(--bs-btn-success-bg) !important;
}

.btn-info {
	background-color: var(--bs-btn-info-bg) !important;
	border-color: var(--bs-btn-info-bg) !important;
}

.btn-warning {
	background-color: var(--bs-btn-warning-bg) !important;
	border-color: var(--bs-btn-warning-bg) !important;
}

.btn-pink {
	background-color: var(--bs-btn-pink-bg) !important;
	border-color: var(--bs-btn-pink-bg) !important;
}

.btn-danger {
	background-color: var(--bs-btn-danger-bg) !important;
	border-color: var(--bs-btn-danger-bg) !important;
}

.container-bg {
	border-radius: 12px;
	box-shadow: none;
	padding: 2rem;
	margin-top: 2rem;
	margin-bottom: 2rem;
}


::-webkit-scrollbar {
	width: 8px;
	height: 8px;
}

::-webkit-scrollbar-thumb {
	background: rgba(0, 0, 0, 0.5);
	border-radius: 4px;
	transition: background 0.3s ease;
}

::-webkit-scrollbar-thumb:hover {
	background: rgba(0, 0, 0, 0.7);
}

::-webkit-scrollbar-track {
	background: transparent;
}

.scrollable-container {
	overflow: hidden;
	position: relative;
}

.scrollable-container:hover {
	overflow: auto;
}

button, .btn-warning, .btn-info, .card, .modal-content {
	transition: transform 0.2s ease, box-shadow 0.2s ease;
}

button:active, .btn-warning:active, .btn-info:active, .card:active, .modal-content:active {
	transform: translateY(-6px);
	box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
}

button:hover, .btn-warning:hover, .btn-info:hover, .card:hover, .modal-content:hover {
	transform: translateY(-6px);
	box-shadow: 0 6px 12px rgba(0, 0, 0, 0.1);
}

a.btn {
	transition: transform 0.2s ease, box-shadow 0.2s ease;
}

a.btn:active {
	transform: translateY(-5px);
	box-shadow: 0 12px 24px rgba(0, 0, 0, 0.3);
}

a.btn:hover {
	transform: translateY(-3px);
	box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
}

a.btn i {
	margin-right: 8px;
}

button:hover {
	background-color: var(--bs-primary);
}

button:disabled {
	background-color: rgba(128, 128, 128, 0.5);
	color: rgba(255, 255, 255, 0.5);
}

.card {
	box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1), 0 6px 20px rgba(0, 0, 0, 0.1);
}

.modal-content {
	color: #fff;
	border: 1px solid #ddd;
	border-radius: 8px;
	box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}

.modal-header {
	color: #fff;
	border-bottom: 1px solid #ccc;
}

.modal-title {
	font-size: 1.25rem;
	font-weight: 700;
	letter-spacing: 0.05em;
	text-transform: uppercase;
}

.modal-body {
	color: #fff;
}


.form-group button {
	box-shadow: 0 2px 8px rgba(0, 123, 255, 0.2);
}

.form-group button:hover {
	transform: translateY(-2px);
	box-shadow: 0 4px 12px rgba(0, 123, 255, 0.3);
}

.container-sm.container-bg.callout a {
	color: var(--bs-primary);
	font-weight: 500;
	text-transform: uppercase;
	letter-spacing: 0.5px;
	padding: 0.5rem 1rem;
	margin: 0 0.25rem;
	position: relative;
	transition: all var(--bs-transition-speed);
	text-decoration: none;
}

.container-sm.container-bg.callout a::after {
	content: '';
	position: absolute;
	bottom: 0;
	left: 0;
	width: 100%;
	height: 2px;
	background-color: var(--bs-primary);
	transform: scaleX(0);
	transition: transform var(--bs-transition-speed);
}

.container-sm.container-bg.callout a:hover, .container-sm.container-bg.callout a:focus, .container-sm.container-bg.callout a.active {
	color: var(--bs-secondary);
}

.container-sm.container-bg.callout a:hover::after, .container-sm.container-bg.callout a:focus::after, .container-sm.container-bg.callout a.active::after {
	transform: scaleX(1);
}

.royal-style {
	font-family: 'Cinzel Decorative', cursive !important;
	font-weight: 900 !important;
	font-size: 80px !important;
	letter-spacing: 4px !important;
	text-align: center !important;
	margin-top: 20px !important;
	transition: all var(--   bs-transition-speed);
}

.royal-style:hover {
	transform: skew(-5deg);
}

@media (max-width: 991.98px) {
	.container-sm.container-bg.callout {
		flex-direction: column;
		align-items: center;
	}

	.container-sm.container-bg.callout a {
		margin: 0.5rem 0;
	}
}

h1 {
	color: var(--bs-heading-1);
	font-size: 2.5rem;
}

h2 {
	color: var(--bs-heading-2);
	font-size: 2rem;
}

h3 {
	color: var(--bs-heading-3);
	font-size: 1.75rem;
}

h4 {
	color: var(--bs-heading-4);
	font-size: 1.5rem;
}

h5 {
	color: var(--bs-heading-5);
	font-size: 1.25rem;
}

h6 {
	color: var(--bs-heading-6);
	font-size: 1rem;
}

h1:hover, h2:hover, h3:hover, h4:hover, h5:hover, h6:hover {
	text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
	transition: all 0.3s ease;
}

.text-3d {
	display: inline-block;
	transition: transform 0.5s, text-shadow 0.5s;
	text-shadow: 1px 1px 1px rgba(0, 0, 0, 0.2), 2px 2px 1px rgba(0, 0, 0, 0.15), 3px 3px 1px rgba(0, 0, 0, 0.1);
}

.text-3d:hover {
	transform: rotateY(15deg) rotateX(15deg);
	text-shadow: 3px 3px 1px rgba(0, 0, 0, 0.3), 4px 4px 2px rgba(0, 0, 0, 0.25), 5px 5px 3px rgba(0, 0, 0, 0.2);
}

.card {
	border-radius: 12px;
	overflow: hidden;
	box-shadow: var(--bs-shadow-medium);
}

.card-header {
	background-color: var(--bs-primary);
	color: #fff;
}

.royal-style {
	font-family: 'Cinzel Decorative', cursive !important;
	font-weight: 900 !important;
	font-size: 80px !important;
	letter-spacing: 4px !important;
	text-align: center !important;
	margin-top: 20px !important;
	transition: all var(--   bs-transition-speed);
}

.royal-style:hover {
	transform: skew(-5deg);
	text-shadow: 3px 3px 6px rgba(0,0,0,0.2);
}

@media (max-width: 991.98px) {
	.container-sm.container-bg.callout {
		flex-direction: column;
		align-items: center;
	}

	.container-sm.container-bg.callout a {
		margin: 0.5rem 0;
	}
}

h1, h2, h3, h4, h5, h6 {
	font-family: var(--bs-heading-font-family);
	font-weight: var(--bs-heading-font-weight);
	letter-spacing: var(--bs-heading-letter-spacing);
	text-transform: var(--bs-heading-text-transform);
	margin-bottom: 1rem;
}

h1 {
	color: var(--bs-heading-1);
	font-size: 2.5rem;
}

h2 {
	color: var(--bs-secondary);
	font-size: 2rem;
}

h3 {
	color: #9c27b0;
	font-size: 1.75rem;
}

h4 {
	color: #9c27b0;
	font-size: 1.5rem;
}

h5 {
	color: #673ab7;
	font-size: 1.25rem;
}

h6 {
	color: #e91e63;
	font-size: 1rem;
}

h1:hover, h2:hover, h3:hover, h4:hover, h5:hover, h6:hover {
	text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
	transition: all 0.3s ease;
}

.text-3d {
	display: inline-block;
	transition: transform 0.5s, text-shadow 0.5s;
	text-shadow: 1px 1px 1px rgba(0, 0, 0, 0.2),
        2px 2px 1px rgba(0, 0, 0, 0.15),
        3px 3px 1px rgba(0, 0, 0, 0.1);
}

.text-3d:hover {
	transform: rotateY(15deg) rotateX(15deg);
	text-shadow: 3px 3px 1px rgba(0, 0, 0, 0.3),
        4px 4px 2px rgba(0, 0, 0, 0.25),
        5px 5px 3px rgba(0, 0, 0, 0.2);
}

.card {
	border-radius: 12px;
	overflow: hidden;
	box-shadow: var(--bs-shadow-medium);
}

.card-header {
	background-color: var(--bs-primary);
	color: #fff;
}

.royal-style {
	font-family: 'Cinzel Decorative', cursive;
	font-weight: 900;
	font-size: 80px;
	letter-spacing: 4px;
	text-align: center;
	margin-top: 20px;
	transition: all var(--bs-transition-speed);
}

.royal-style:hover {
	transform: skew(-5deg);
	text-shadow: 3px 3px 6px rgba(0,0,0,0.2);
}

@media (max-width: 767px) {
	body {
		font-size: 14px;
	}

	h1 {
		font-size: 2rem;
	}

	h2 {
		font-size: 1.75rem;
	}

	h3 {
		font-size: 1.5rem;
	}

	h4 {
		font-size: 1.25rem;
	}

	h5 {
		font-size: 1.1rem;
	}

	h6 {
		font-size: 1rem;
	}

	.royal-style {
		font-size: 40px;
	}

	.btn {
		padding: 8px 16px;
		font-size: 14px;
	}

	.table-3d {
		font-size: 14px;
	}

	.table-3d td,
      .table-3d th {
		padding: 10px;
	}

	.container-bg {
		padding: 1rem;
		margin-top: 1rem;
		margin-bottom: 1rem;
	}

    @	media (max-width: 575px) {
		.container-sm.container-bg.callout {
        flex-direction: column;
		align-items: stretch;
	}

	.container-sm.container-bg.callout a {
		margin: 0.25rem 0;
		display: block;
		text-align: center;
	}
}

@media (min-width: 992px) {
	.container-sm.container-bg.callout {
		display: flex;
		justify-content: center;
		align-items: center;
	}

	.container-sm.container-bg.callout a {
		margin: 0 0.5rem;
	}
}

@media (max-width: 767px) {
	.row.justify-content-md-center .col.input-group.mb-3.justify-content-md-center {
		display: flex;
		justify-content: center;
	}

	.row.justify-content-md-center .col.input-group.mb-3.justify-content-md-center .btn-info {
		width: auto;
		min-width: 200px;
	}
}

.btn-info,
    .btn-success,
    .btn-danger {
	color: #fff !important;
}

.btn-info:hover,
    .btn-success:hover,
    .btn-danger:hover,
    .btn-info:focus,
    .btn-success:focus,
    .btn-danger:focus {
	color: #fff !important;
}

@media (max-width: 767px) {
	.btn {
		font-size: 10px;
	}
}
    ";

    $filePath = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/assets/theme/' . $themeFileName;
    file_put_contents($filePath, $cssContent);
    echo "<script>
            alert('The custom theme has been updated, and the name is $themeName.css ！');
            window.location.href = 'settings.php';
          </script>";
} else {
    echo "<script>alert('No data received');</script>";
}

if (isset($_GET['delete'])) {
    $fileToDelete = $_GET['delete'];
    $filePath = $picturesDir . $fileToDelete;
    if (file_exists($filePath)) {
        unlink($filePath);

        $cssFilePath = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/assets/theme/transparent.css';
        if (file_exists($cssFilePath)) {
            $cssContent = file_get_contents($cssFilePath);
            $cssContent = preg_replace('/background-image: url\(.*?\);.*?background-size: cover;/', '', $cssContent);
            file_put_contents($cssFilePath, $cssContent);
        }

        echo "<script>
                alert('The image has been deleted');
                window.location.href = 'settings.php';
              </script>";
        exit;
    }
}
?>

