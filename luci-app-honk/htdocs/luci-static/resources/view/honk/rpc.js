// SPDX-License-Identifier: GPL-3.0-only

'use strict';
'require baseclass';
'require rpc';

const callStatus = rpc.declare({
	object: 'honk',
	method: 'status',
	expect: { '': {} }
});

const callCheck = rpc.declare({
	object: 'honk',
	method: 'check',
	expect: { '': {} }
});

const callInitialize = rpc.declare({
	object: 'honk',
	method: 'initialize',
	params: [ 'username', 'password' ],
	expect: { '': {} }
});

const callStart = rpc.declare({ object: 'honk', method: 'start', expect: { '': {} } });
const callStop = rpc.declare({ object: 'honk', method: 'stop', expect: { '': {} } });
const callRestart = rpc.declare({ object: 'honk', method: 'restart', expect: { '': {} } });

const callSettings = rpc.declare({
	object: 'honk',
	method: 'settings',
	params: [ 'lan_network', 'listen_port', 'clash_api_enabled', 'clash_api_port', 'clash_api_secret' ],
	expect: { '': {} }
});

const callProbeSubscription = rpc.declare({
	object: 'honk',
	method: 'probe_subscription',
	params: [ 'url' ],
	expect: { '': {} }
});
const callAddSubscription = rpc.declare({
	object: 'honk',
	method: 'add_subscription',
	params: [ 'name', 'url' ],
	expect: { '': {} }
});
const callAddNodes = rpc.declare({
	object: 'honk',
	method: 'add_nodes',
	params: [ 'links' ],
	expect: { '': {} }
});
const callImportDae = rpc.declare({
	object: 'honk',
	method: 'import_dae',
	expect: { '': {} }
});
const callConfigRead = rpc.declare({ object: 'honk', method: 'config_read', expect: { '': {} } });
const callConfigDraftRead = rpc.declare({
	object: 'honk',
	method: 'config_draft_read',
	params: [ 'source' ],
	expect: { '': {} }
});
const callLanCandidates = rpc.declare({ object: 'honk', method: 'lan_candidates', expect: { '': {} } });
const callConfigValidate = rpc.declare({ object: 'honk', method: 'config_validate', params: [ 'content' ], expect: { '': {} } });
const callConfigSave = rpc.declare({ object: 'honk', method: 'config_save', params: [ 'content' ], expect: { '': {} } });
const callConfigApply = rpc.declare({ object: 'honk', method: 'config_apply', expect: { '': {} } });
const callConfigDetach = rpc.declare({ object: 'honk', method: 'config_detach', params: [ 'dry_run' ], expect: { '': {} } });
const callRepair = rpc.declare({ object: 'honk', method: 'repair', expect: { '': {} } });
const callRecover = rpc.declare({ object: 'honk', method: 'recover', expect: { '': {} } });
const callBackup = rpc.declare({ object: 'honk', method: 'backup', expect: { '': {} } });
const callRestore = rpc.declare({ object: 'honk', method: 'restore', expect: { '': {} } });
const callRestorePrepare = rpc.declare({ object: 'honk', method: 'restore_prepare', expect: { '': {} } });
const callResetAdmin = rpc.declare({ object: 'honk', method: 'reset_admin', expect: { '': {} } });
const callReset = rpc.declare({ object: 'honk', method: 'reset', expect: { '': {} } });
const callJobStatus = rpc.declare({
	object: 'honk',
	method: 'job_status',
	params: [ 'job_id' ],
	expect: { '': {} }
});
const callLogs = rpc.declare({
	object: 'honk',
	method: 'logs',
	params: [ 'source', 'level', 'limit' ],
	expect: { '': {} }
});
const callUpdateCheck = rpc.declare({ object: 'honk', method: 'update_check', expect: { '': {} } });
const callUpdateApply = rpc.declare({ object: 'honk', method: 'update_apply', expect: { '': {} } });

let pageStylesInstalled = false;
let switchStylesInstalled = false;

/* 开关样式随 JS 注入：CSS 与 JS 分开缓存，主题又各改各的 checkbox/button。 */
const SWITCH_CSS = [
	'.honk-page .honk-switch-wrap{display:inline-flex;align-items:center;gap:6px;white-space:nowrap;vertical-align:middle;line-height:1}',
	'.honk-page .honk-switch-label{font-size:11px;font-weight:600;letter-spacing:.3px;opacity:.62}',
	'.honk-page .honk-switch{position:relative!important;flex:0 0 auto;width:42px!important;height:22px!important;min-width:0!important;min-height:0!important;margin:0!important;padding:0!important;border:0!important;border-radius:999px!important;background:rgba(128,128,128,.28)!important;background-image:none!important;box-shadow:none!important;line-height:1!important;text-transform:none!important;transform:none!important;overflow:hidden;cursor:pointer;transition:background .18s ease,opacity .18s ease}',
	'.honk-page .honk-switch .honk-switch-knob{position:absolute;top:3px;left:3px;width:16px;height:16px;border-radius:50%;background:rgba(255,255,255,.96);box-shadow:0 1px 4px rgba(0,0,0,.2);transition:left .18s ease}',
	'.honk-page .honk-switch.is-on{background:rgba(74,160,101,.65)!important}',
	'.honk-page .honk-switch:disabled{opacity:.45;cursor:not-allowed}',
	'.honk-page .honk-switch:focus-visible{outline:2px solid rgba(74,160,101,.75);outline-offset:2px}',
	/* 0,3,1 才压得过 honk.css 里那颗 46px !important 的 checkbox。 */
	'.honk-page .honk-switch-wrap>input.honk-switch-input{position:absolute!important;width:1px!important;height:1px!important;margin:0!important;padding:0!important;border:0!important;opacity:0!important;pointer-events:none!important;appearance:none!important;-webkit-appearance:none!important;box-shadow:none!important;background:none!important}'
].join('\n');

function installSwitchStyles() {
	if (switchStylesInstalled || document.getElementById('honk-switch-styles'))
		return;

	const style = document.createElement('style');
	style.id = 'honk-switch-styles';
	style.appendChild(document.createTextNode(SWITCH_CSS));
	document.head.appendChild(style);
	switchStylesInstalled = true;
}

/* 主题对 input[type=checkbox] 的处理各不相同（Argon 会放大成错位的胶囊，
   Bootstrap 干脆是原生小方框），所以开关自己画：真 input 留在表单里保证
   取值/回填逻辑不变，外面套一层可点的胶囊和 ON/OFF 文字。 */
function switchControl(input) {
	installSwitchStyles();
	input.classList.add('honk-switch-input');
	input.setAttribute('tabindex', '-1');

	const caption = E('span', { 'class': 'honk-switch-label' }, '');
	const knob = E('span', { 'class': 'honk-switch-knob' });
	const toggle = E('button', {
		'class': 'honk-switch',
		'type': 'button',
		'role': 'switch',
		'aria-checked': input.checked ? 'true' : 'false'
	}, knob);

	const sync = function() {
		toggle.classList.toggle('is-on', !!input.checked);
		toggle.setAttribute('aria-checked', input.checked ? 'true' : 'false');
		toggle.disabled = !!input.disabled;
		caption.textContent = input.checked ? 'ON' : 'OFF';
		knob.style.left = input.checked ? '23px' : '3px';
	};

	toggle.addEventListener('click', function(ev) {
		ev.preventDefault();
		if (input.disabled)
			return;
		input.checked = !input.checked;
		input.dispatchEvent(new Event('change', { bubbles: true }));
		sync();
	});
	input.addEventListener('change', sync);

	/* 表单回填（restoreFields）直接改 input.checked，不会触发 change。 */
	const wrapper = E('span', { 'class': 'honk-switch-wrap' }, [ input, caption, toggle ]);
	wrapper.syncSwitch = sync;
	sync();
	return wrapper;
}

function installStyles() {
	if (pageStylesInstalled || document.getElementById('honk-page-styles'))
		return;

	const stylesheet = document.createElement('link');
	stylesheet.id = 'honk-page-styles';
	stylesheet.rel = 'stylesheet';
	stylesheet.href = L.resource('view/honk/honk.css') + (L.env.resource_version ? '?v=' + L.env.resource_version : '');
	document.head.appendChild(stylesheet);
	pageStylesInstalled = true;
}

/* A core bound to 0.0.0.0 (or ::) reports a wildcard authority. A browser
   cannot open that, but the router is still reachable at the host LuCI was
   loaded from, so substitute that instead of hiding the panel button. */
function wildcardHost(hostname) {
	const name = String(hostname || '').replace(/^\[|\]$/g, '').toLowerCase();
	return name === '0.0.0.0' || name === '::' || name === '';
}

function urlHost(hostname) {
	const name = String(hostname || '');
	return name.indexOf(':') >= 0 ? '[' + name.replace(/^\[|\]$/g, '') + ']' : name;
}

function localWebUi(status) {
	if (!status || !status.initialized || !status.running || !status.api_ready || !status.api_url)
		return null;

	try {
		const raw = String(status.api_url);
		const authority = raw.match(/^https?:\/\/([^/?#]+)/i);
		if (!authority || authority[1].indexOf('@') >= 0)
			return null;

		const portMatch = authority[1].match(/:(\d+)$/);
		const url = new URL(raw);
		const hostname = url.hostname.replace(/^\[|\]$/g, '').toLowerCase();
		const port = portMatch ? Number(portMatch[1]) : 0;
		if (!portMatch || !Number.isInteger(port) || port < 1 || port > 65535 ||
			url.protocol !== 'http:' && url.protocol !== 'https:' ||
			url.username || url.password || url.search || url.hash)
			return null;

		if (wildcardHost(hostname) && window.location.hostname)
			return url.protocol + '//' + urlHost(window.location.hostname) + ':' + port + '/ui/';

		const octets = hostname.split('.');
		let localIPv4 = false;
		if (octets.length === 4 && octets.every(function(part) { return /^\d{1,3}$/.test(part) && Number(part) <= 255; })) {
			const ip = octets.map(Number);
			localIPv4 = ip[0] === 10 || ip[0] === 127 || ip[0] === 192 && ip[1] === 168 ||
				ip[0] === 172 && ip[1] >= 16 && ip[1] <= 31 || ip[0] === 169 && ip[1] === 254;
		}
		const localIPv6 = hostname === '::1' || /^f[cd][0-9a-f:]*$/.test(hostname) || /^fe[89ab][0-9a-f:]*$/.test(hostname);
		if (!localIPv4 && !localIPv6)
			return null;

		return url.origin.replace(/\/$/, '') + '/ui/';
	}
	catch (e) {
		return null;
	}
}

function localClashUi(status, secret) {
	if (!status || !status.clash_api_enabled || !status.clash_api_ready || !status.clash_ui_ready)
		return null;
	const base = localWebUi(Object.assign({}, status, { api_url: status.clash_api_url, api_ready: true }));
	if (!base)
		return null;
	try {
		const url = new URL(status.clash_api_url);
		const host = wildcardHost(url.hostname)
			? String(window.location.hostname || '').replace(/^\[|\]$/g, '').toLowerCase()
			: url.hostname.replace(/^\[|\]$/g, '').toLowerCase();
		const port = status.clash_api_port || url.port;
		const query = [
			'host=' + encodeURIComponent(host),
			'hostname=' + encodeURIComponent(host),
			'port=' + encodeURIComponent(port),
			'secret=' + encodeURIComponent(secret || '')
		].join('&');
		return base + '?' + query + '#/proxies';
	}
	catch (e) {
		return null;
	}
}

function tokenMessage(token) {
	const messages = {
		disabled: _('Honk is disabled.'),
		not_initialized: _('Complete initial setup before starting Honk.'),
		service_not_running: _('Honk is enabled but currently stopped.'),
		api_unavailable: _('Honk is running, but its management interface is not ready.'),
		operation_in_progress: _('Another Honk operation is in progress.'),
		stale_operation_lock: _('A previous operation did not finish cleanly.'),
		started: _('Honk started.'),
		already_running: _('Honk is already running.'),
		stopped: _('Honk stopped.'),
		restarted: _('Honk restarted.'),
		settings_saved: _('Settings saved and applied.'),
		initialized: _('Honk initialized.'),
		administrator_initialized: _('Honk initialized.'),
		system_config_healthy: _('System check passed.'),
		system_config_repaired: _('Repair completed.'),
		backup_created: _('Backup created.'),
		restored: _('Backup restored.'),
		data_reset: _('Honk data reset. The service is stopped.'),
		worker_lost: _('The maintenance worker stopped unexpectedly; check system recovery status before retrying.'),
		operation_failed: _('The maintenance operation failed.'),
	maintenance_no_result: _('The maintenance script stopped without reporting a result. Check Maintenance → Logs → Maintenance for the reason.'),
	job_runner_unavailable: _('The maintenance worker did not start at all. The panel cannot see why, so this is a packaging or permission problem on the device.'),
	job_runner_not_root: _('The maintenance worker did not run as root.'),
	honk_tree_missing: _('The /etc/honk directory is missing or is a symlink.'),
	honk_tree_has_symlink: _('There is a symlink under /etc/honk. The backup cannot carry it; remove it and try again.'),
	honk_tree_has_special_file: _('There is a non-regular file (device, socket, fifo) under /etc/honk. Remove it and try again.'),
	honk_tree_unreadable: _('A file under /etc/honk could not be read. Check the filesystem and permissions.'),
	honk_backup_file_too_large: _('A single file under /etc/honk is larger than 64 MB. The service log names it.'),
	honk_backup_tree_too_large: _('The backup would exceed 512 files or 127 MB. The service log names the entry that crossed the limit.'),
	honk_config_incomplete: _('config.dae or system.dae is missing under /etc/honk. Reinstall or repair Honk before backing up.'),
		unsupported_honk_tree_entry: _('The backup found an entry under /etc/honk it cannot archive (a symlink, a special file, or too many files).'),
		unsafe_honk_file_name: _('A file under /etc/honk has a name the backup cannot carry (spaces, wildcards or "../"). The service log names it; rename it and try again.'),
		job_timeout: _('The maintenance operation timed out.'),
		maintenance_recovery_required: _('Recovery is required. Run system recovery before starting another maintenance operation.'),
		update_recovery_required: _('The signed update did not finish. Keep Honk stopped and reinstall a complete verified package set before retrying.'),
		rollback_tuple_unavailable: _('A compatible update is available, but a complete verified rollback package set is not available yet.'),
		trusted_feed_unavailable: _('No trusted update source is configured.'),
		manifest_incompatible: _('The signed update manifest does not match this device.'),
		signed_manifest_unavailable: _('The signed update manifest could not be fetched or verified.'),
		update_available: _('A compatible update is available.'),
		no_update: _('No compatible update is available.'),
		already_current: _('Honk is already up to date.'),
		update_apply_failed: _('The update could not be installed.'),
		update_check_failed: _('The signed update could not be verified for this device.'),
		signed_manifest_missing: _('Check for updates again to refresh the signed manifest.'),
		signed_manifest_expired: _('The signed manifest expired. Check for updates again.'),
		reset_failed: _('Reset failed; the previous service state was restored.'),
		reset_failed_rollback_failed: _('Reset failed and automatic recovery did not finish. Run system recovery before retrying.'),
		restore_failed_rollback_failed: _('Restore failed and automatic recovery did not finish. Run system recovery before retrying.'),
		logs_unavailable: _('Honk logs are unavailable.'),
		unsupported_core: _('This installed core does not support the requested import operation.'),
		invalid_request: _('The import request is incomplete or invalid.'),
		import_failed: _('The core could not prepare this import preview.'),
		share_links_too_large: _('Share links exceed the 16 KiB per request limit.'),
		share_links_invalid_or_conflicting: _('A share link is invalid or conflicts with an existing node. Review the input and try again.'),
		subscription_invalid: _('The subscription could not be added: the name must be 1-64 characters without single quotes, and the URL must be a valid http(s) link.'),
		subscription_invalid_or_conflicting: _('The subscription is invalid or its name already exists.'),
		subscription_no_nodes: _('The subscription returned no usable nodes. The configuration was not changed.'),
		subscription_added: _('Subscription saved with usable nodes.'),
		nodes_added: _('Nodes saved.'),
		reload_failed_rolled_back: _('Honk could not restart. The previous configuration and service were restored.'),
		reload_and_rollback_failed: _('Honk could not restart or restore the previous service. Check its status and backup.'),
		dae_imported: _('Configuration imported and Honk reloaded.'),
		config_missing: _('The configuration file is missing.'),
		config_write_failed: _('Could not write the configuration file.'),
		dae_too_large: _('The dae file exceeds the 2 MiB limit.'),
		dae_invalid_or_unsupported: _('The dae file contains invalid sections or unsupported includes.'),
		candidate_invalid: _('Honk could not load the proposed configuration.'),
		candidate_rejected: _('The imported configuration failed core validation.'),
		source_changed: _('Honk or Doona changed the configuration during this operation. Try again.'),
		preview_expired: _('The preview expired. Create a new preview.'),
		preview_corrupt: _('The saved preview is damaged. Create a new preview.'),
		dae_upload_unavailable: _('The dae upload is missing or unavailable. Upload the file again.'),
		dae_upload_invalid: _('The uploaded dae file is invalid.'),
		dae_upload_changed: _('The uploaded dae file changed. Upload it again.'),
		upload_failed: _('Honk could not prepare the upload location. Check the upload directory permissions and try again.'),
		upload_directory_unavailable: _('Honk could not prepare a private configuration upload directory.'),
		upload_target_unavailable: _('The temporary configuration upload is unavailable. Try again.'),
		config_too_large: _('The configuration file exceeds the 2 MiB limit.'),
		config_applied: _('Configuration applied and Honk is running.'),
		config_apply_failed_rolled_back: _('Honk could not start with this configuration. The previous file was restored.'),
		config_apply_rollback_failed: _('Startup failed and the automatic rollback did not finish. The snapshot was kept; run system recovery.'),
		config_changed_concurrently: _('The configuration changed during the operation. Nothing was applied.'),
		config_write_failed_snapshot_retained: _('Could not write the configuration. The snapshot was kept.'),
		service_stop_unconfirmed: _('Could not confirm that Honk stopped. The operation was aborted and the snapshot was kept.'),
		administrator_exists_reuse_credentials_or_reset_state: _('已经初始化过了，请用原来的账号登录 Doona。忘记密码：到「维护 → 重置管理员」清掉管理员记录（不动订阅和规则），再回到本页重新初始化。'),
		administrator_setup_failed: _('创建 Doona 管理员失败，请到「维护 → 日志」查看核心日志。'),
		invalid_credentials: _('用户名只能包含字母、数字、下划线、点、连字符（不超过 64 个字符）；密码长度必须是 8 到 128 个字符，可以包含空格。'),
		disable_service_before_initialization: _('请先停止 Honk 服务再初始化。'),
		honk_resources_already_exist: _('系统里还留着 dae0 / daens 等运行痕迹，请先停止服务或执行系统恢复。'),
		core_missing: _('找不到 /usr/bin/honk-core，请重新安装 honk 包。'),
		core_already_running: _('honk-core 已经在运行，请先停止服务。'),
		jshn_unavailable: _('缺少 libubox 组件（/usr/share/libubox/jshn.sh），请检查固件是否完整。'),
		temporary_storage_unavailable: _('临时目录 /tmp 不可写或空间不足。'),
		system_config_backup_failed: _('备份现有 system.dae 失败，请检查磁盘空间。'),
		system_snapshot_failed: _('备份系统配置失败，请检查磁盘空间。'),
		uci_snapshot_failed: _('备份 UCI 配置失败，请检查磁盘空间。'),
		loopback_listener_write_failed: _('写入 system.dae 的监听地址失败，请检查文件权限。'),
		main_config_unavailable: _('/etc/honk/config.dae 不存在或不是普通文件。'),
		main_config_changed_concurrently: _('操作期间 config.dae 被其他进程改动，已中止。'),
		invalid_package_config: _('luci-app-honk 的软件包配置不完整，请重新安装。'),
		invalid_config_path: _('配置路径不是 /etc/honk/config.dae，拒绝操作。'),
		required_system_include_missing: _('当前配置没有 include { system.dae }，这些设置请到「编辑配置」里修改。'),
		native_api_setup_state_unavailable: _('读不到核心的 API 状态，请查看日志。'),
		ui_assets_missing: _('缺少 Doona 静态文件（/usr/share/doona），请重新安装 luci-app-honk。'),
		mock_core_start_failed: _('测试用核心启动失败：通常是内核缺 BTF（/sys/kernel/btf/vmlinux）或 eBPF 依赖模块。'),
		mock_core_stop_failed: _('测试用核心无法正常停止，请稍后重试。'),
		mock_core_restart_failed: _('测试用核心重启失败，请查看日志。'),
		mock_core_stop_failed_restored_loopback: _('测试核心停止失败，已恢复原来的监听配置。'),
		generated_config_invalid_restored_loopback: _('生成的配置校验不通过，已恢复原来的监听配置。'),
		uci_commit_failed_restored_loopback: _('写入 UCI 失败，已恢复原来的监听配置。'),
		lan_api_verification_failed_restored_loopback: _('用局域网地址访问 API 验证失败（网卡或 IP 可能对不上），已恢复。'),
		persistence_login_failed: _('初始化后登录验证失败，请重试或查看日志。'),
		persistence_verification_failed: _('初始化结果没有落盘（可能磁盘空间不足）。'),
		setup_verification_failed: _('初始化后的自检没通过，请查看日志。'),
		lan_ipv4_unavailable: _('选中的 LAN 网络没有 IPv4 地址。'),
		mkdir_failed: _('创建目录失败，请检查磁盘空间与权限。'),
		settings_too_large: _('提交的设置数据过大。'),
		invalid_settings_json: _('设置的请求格式不正确。'),
		invalid_boolean_settings: _('开关类设置取值不合法。'),
		invalid_log_level: _('日志级别不合法。'),
		invalid_log_limit: _('日志行数不合法。'),
		invalid_log_source: _('日志来源不合法。'),
		invalid_operation: _('未知的操作类型。'),
		unknown_method: _('未知的接口方法。'),
		settings_changed_concurrently: _('操作期间设置被改动，已中止。'),
		lan_network_changed_during_settings: _('操作期间 LAN 网络被改动，已中止。'),
		lan_network_changed_during_repair: _('操作期间 LAN 网络被改动，已中止。'),
		service_state_changed_concurrently: _('操作期间服务状态发生变化，已中止。'),
		settings_commit_failed_rolled_back: _('设置写入失败，已回滚到原值。'),
		settings_commit_and_rollback_failed_snapshot_retained: _('设置写入失败且回滚未完成，快照已保留，请执行系统恢复。'),
		service_apply_and_rollback_failed_snapshot_retained: _('应用设置失败且回滚未完成，快照已保留，请执行系统恢复。'),
		service_stop_failed_rolled_back: _('停止服务失败，已回滚。'),
		service_stop_and_rollback_failed_snapshot_retained: _('停止服务失败且回滚未完成，快照已保留。'),
		system_config_write_failed: _('写入 system.dae 失败。'),
		system_config_write_failed_rolled_back: _('写入 system.dae 失败，已回滚。'),
		system_config_write_and_rollback_failed_snapshot_retained: _('写入 system.dae 失败且回滚未完成，快照已保留。'),
		system_config_repair_failed_rolled_back: _('修复 system.dae 失败，已回滚。'),
		system_config_repair_rollback_failed_snapshot_retained: _('修复 system.dae 失败且回滚未完成，快照已保留。'),
		system_config_not_regular_file: _('system.dae 不是普通文件（可能是软链），拒绝操作。'),
		boot_link_update_failed_rolled_back: _('更新开机自启链接失败，已回滚。'),
		boot_link_update_and_rollback_failed_snapshot_retained: _('更新开机自启链接失败且回滚未完成，快照已保留。'),
		repair_restart_failed_rolled_back: _('修复后重启失败，已回滚。'),
		repair_restart_and_rollback_failed_snapshot_retained: _('修复后重启失败且回滚未完成，快照已保留。'),
		subscription_unreachable: _('抓不到这个订阅地址：网络不通、需要代理，或链接已失效。'),
		subscription_empty: _('订阅内容是空的。'),
		subscription_too_large: _('订阅内容超过 4 MiB，拒绝处理。'),
		configuration_validation_failed: _('配置没有通过静态校验。'),
		config_changed_concurrently_restart_failed: _('操作期间配置被改动且重启失败，快照已保留。'),
		invalid_job_id: _('任务编号不合法。'),
		job_id_unavailable: _('拿不到任务编号。'),
		job_not_found: _('找不到该任务。'),
		job_status_unavailable: _('读不到任务状态。'),
		job_storage_unavailable: _('任务存储不可用（/tmp 空间不足？）。'),
		prepared: _('上传目录已准备好。'),
		probe_failed: _('预检失败，请稍后重试。'),
		config_draft_missing: _('There is no saved draft to apply.'),
		config_draft_invalid: _('The saved draft is not a valid regular file.'),
		lan_candidates_unavailable: _('Could not read the list of network interfaces.'),
		config_read_failed: _('Honk could not read the current configuration.'),
		config_request_invalid: _('The configuration request is empty or invalid.'),
		config_validation_failed: _('The configuration did not pass static validation.'),
		config_validation_unavailable: _('The core validator did not return a result.'),
		config_settings_owned_by_file: _('这些设置由当前配置文件决定，请到「配置 → 编辑配置」里修改。'),
		config_detached: _('已改由面板接管，订阅和分流规则保持不变。'),
		config_not_file_owned: _('当前配置没有自带系统设置，不需要切换。'),
		detach_layout_unsupported: _('配置里的 global / experimental 写法无法自动拆出，请到「配置 → 编辑配置」手动删除。'),
		detach_validation_failed: _('拆分后的配置没有通过校验，原配置未改动。'),
		detach_failed_rolled_back: _('切换后服务没能启动，已还原原配置。'),
		detach_rollback_failed: _('切换失败且自动还原未完成，请到「维护」执行系统恢复。'),
		config_valid: _('配置通过校验。'),
		config_invalid: _('配置没有通过校验。'),
		config_saved_pending_apply: _('Configuration saved. The running service is unchanged until you apply it.'),
		quick_add_unsupported: _('当前配置不支持快捷追加，请在「编辑配置」中修改。'),
		config_loaded: _('Configuration loaded.'),
		dae_loaded: _('Configuration file loaded into the editor.'),
		upload_ready: _('Upload location ready.'),
		upload_cleared: _('Temporary upload cleared.'),
		upload_unavailable: _('A private upload location could not be prepared.'),
		settings_write_failed: _('Could not save Honk settings.'),
		curl_missing: _('The curl command is missing. Install the curl package and try again.'),
		kernel_too_old: _('内核版本过低，honk 需要 Linux 6.12 及以上，请升级固件。'),
		kernel_compat_too_old: _('The compatibility core requires Linux 6.6.40 or newer.'),
		core_capabilities_mismatch: _('The core does not match its compatibility metadata. Reinstall Honk.'),
		kernel_btf_override_invalid: _('HONK_VMLINUX_BTF 指向的 BTF 文件读不到。核心设了这个变量就只认它、不会回退默认路径，请改正路径或取消该变量。'),
		kernel_btf_missing: _('Kernel BTF is missing. Install vmlinux-btf matching your firmware, or use firmware with built-in BTF.'),
		bpffs_not_mounted: _('bpffs 没有挂到 /sys/fs/bpf，请检查固件是否完整，或手工挂载后重试。'),
		ip_full_missing: _('缺少 ip 命令，请安装 ip-full 包。'),
		kmod_missing: _('缺少 modprobe 命令，请安装 kmod 包。'),
		start_failed: _('Honk could not start.'),
		stop_failed: _('Honk could not stop.'),
		restart_failed: _('Honk could not restart.'),
		managed_service_unhealthy: _('The managed Honk service is not healthy.'),
		unmanaged_core_running: _('An unmanaged Honk core process is running.'),
		invalid_lan_network: _('The selected LAN network is invalid or unavailable.'),
		lan_network_unavailable: _('The selected LAN network is unavailable.'),
		listen_port_occupied: _('The listen port is already in use.'),
		clash_api_port_occupied: _('The Clash API port is already in use.'),
		invalid_clash_api_settings: _('Enter a different Clash API port and a secret of 6–128 letters, numbers, dots, underscores or hyphens.'),
		invalid_listen_port: _('The listen port is invalid.'),
		initialize_before_enabling_service: _('Complete initial setup before enabling Honk.'),
		system_config_unavailable: _('Honk system configuration is unavailable.'),
		package_config_unavailable: _('Honk configuration is unavailable.'),
		service_apply_failed_rolled_back: _('Settings could not be applied. The previous settings were restored.')
	};

	return messages[token] || null;
}

function statusIssue(token) {
	/* 内核模块检查会带上具体模块名，按前缀拆开再填进文案 */
	if (typeof token === 'string' && token.indexOf('kernel_module_missing:') === 0)
		return _('缺少内核模块 %s，请确认 kmod-sched-core / kmod-sched-bpf / kmod-veth / kmod-nft-queue 已安装。').format(token.slice('kernel_module_missing:'.length));

	return tokenMessage(token) || _('Honk reported a system issue: %s').format(token);
}

function resultMessage(result, fallback) {
	return result && tokenMessage(result.message) || fallback;
}

function errorMessage(error, fallback) {
	const token = error && error.message;
	/* 没映射过就把错误码原样带出来，否则用户只能看到「操作失败」，没法反馈 */
	const text = tokenMessage(token) || (token && /^[a-z0-9_]+$/.test(token)
		? _('%s (code: %s)').format(fallback || _('The operation failed.'), token)
		: fallback);
	/* 后端把 stderr 摘要放进 detail，直接给用户，省得再去翻日志。 */
	const detail = error && error.detail;
	return detail ? _('%s Reason: %s').format(text, String(detail)) : text;
}

function jobPhaseMessage(phase) {
	const messages = {
		queued: _('Waiting for the operation to start…'),
		checking_feed: _('Checking the signed update source…'),
		downloading: _('Downloading the signed package set…'),
		preparing: _('Preparing configuration apply…'),
		validating_candidate: _('Validating the candidate in an isolated runtime…'),
		stopping: _('Stopping Honk safely…'),
		applying: _('Applying the reviewed configuration…'),
		validating: _('Checking the updated configuration…'),
		starting: _('Restoring the previous service state…'),
		rolling_back: _('Restoring the previous configuration…'),
		committing: _('Finishing the transaction…'),
		recovery: _('Recovery is required before another operation.')
	};
	return messages[phase] || _('Applying configuration…');
}

function ensureOk(result) {
	if (!result || result.ok !== true)
		throw new Error(result && result.message ? result.message : _('The backend did not confirm the operation.'));

	return result;
}

function waitJob(jobId, onProgress) {
	if (!/^[0-9a-f]{32}$/.test(jobId || ''))
		return Promise.reject(new Error('invalid_job_id'));

	let attempts = 0;
	return new Promise(function(resolve, reject) {
		function poll() {
			callJobStatus(jobId).then(function(result) {
				if (!result || typeof result.state !== 'string')
					throw new Error('invalid_job_status');
				if (onProgress)
					onProgress(result);
				if (result.state === 'succeeded') {
					resolve(result);
					return;
				}
				if (result.state === 'failed' || result.state === 'rollback_required') {
					const error = new Error(result.state === 'rollback_required' ? 'maintenance_recovery_required' : result.message || 'operation_failed');
					error.recoveryRequired = result.state === 'rollback_required';
					error.detail = result.detail;
					reject(error);
					return;
				}
				if (result.state !== 'queued' && result.state !== 'running') {
					reject(new Error('invalid_job_status'));
					return;
				}
				if (++attempts >= 1800) {
					reject(new Error('job_timeout'));
					return;
				}
				setTimeout(poll, 1000);
			}).catch(reject);
		}
		poll();
	});
}

return baseclass.extend({
	status: callStatus,
	check: callCheck,
	initialize: callInitialize,
	start: callStart,
	stop: callStop,
	restart: callRestart,
	settings: callSettings,
	probeSubscription: callProbeSubscription,
	addSubscription: callAddSubscription,
	addNodes: callAddNodes,
	importDae: callImportDae,
	configRead: callConfigRead,
	configDraftRead: callConfigDraftRead,
	lanCandidates: callLanCandidates,
	configValidate: callConfigValidate,
	configSave: callConfigSave,
	configApply: callConfigApply,
	configDetach: callConfigDetach,
	repair: callRepair,
	recover: callRecover,
	backup: callBackup,
	restore: callRestore,
	restorePrepare: callRestorePrepare,
	resetAdmin: callResetAdmin,
	reset: callReset,
	logs: callLogs,
	updateCheck: callUpdateCheck,
	updateApply: callUpdateApply,
	waitJob: waitJob,
	ensureOk: ensureOk,
	localWebUi: localWebUi,
	localClashUi: localClashUi,
	statusIssue: statusIssue,
	resultMessage: resultMessage,
	errorMessage: errorMessage,
	jobPhaseMessage: jobPhaseMessage,
	switchControl: switchControl,
	installStyles: installStyles
});
