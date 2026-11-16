<?php
// Validates LuCI session via ubus on every request.
// Auto-login when accessed from LuCI menu (luci_sid passed in URL).
// Forces logout when LuCI session expires.

if (!defined('FM_SESSION_ID')) define('FM_SESSION_ID', 'filemanager');
session_name('filemanager');
session_start();

function luci_validate_sid($sid) {
	if (empty($sid) || !preg_match('/^[a-f0-9]{32}$/', $sid)) return false;
	$out = shell_exec('ubus call session get \'{"ubus_rpc_session":"' . $sid . '"}\' 2>/dev/null');
	return $out && strpos($out, '"username"') !== false;
}

// Step 1: luci_sid in URL → validate and auto-login
if (!empty($_GET['luci_sid'])) {
	$sid = preg_replace('/[^a-f0-9]/', '', $_GET['luci_sid']);
	if (luci_validate_sid($sid)) {
		$_SESSION['filemanager']['logged'] = $luci_autologin_user;
		$_SESSION['filemanager']['luci_sid'] = $sid;
		session_write_close();
		header('Location: /tinyfilemanager/');
		exit;
	} else {
		unset($_SESSION['filemanager']['logged']);
		unset($_SESSION['filemanager']['luci_sid']);
		session_write_close();
		http_response_code(403);
		die('LuCI session invalid or expired.');
	}
}

// Step 2: On every request, re-validate stored LuCI session
if (!empty($_SESSION['filemanager']['logged'])) {
	$sid = $_SESSION['filemanager']['luci_sid'] ?? '';
	if (!luci_validate_sid($sid)) {
		// LuCI session expired → force logout
		unset($_SESSION['filemanager']['logged']);
		unset($_SESSION['filemanager']['luci_sid']);
		session_write_close();
		header('Location: /tinyfilemanager/');
		exit;
	}
}

session_write_close();

?>
