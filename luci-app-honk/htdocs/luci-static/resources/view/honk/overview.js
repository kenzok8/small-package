// SPDX-License-Identifier: GPL-3.0-only

'use strict';
'require network';
'require poll';
'require ui';
'require view';
'require view.honk.rpc as honk';

function getNetworkNames(networks) {
	if (!networks)
		return [];

	const list = Array.isArray(networks) ? networks : Object.keys(networks).map(function(key) { return networks[key]; });
	return list.map(function(net) {
		if (net && typeof net.getName === 'function')
			return net.getName();
		if (net && typeof net.name === 'string')
			return net.name;
		return typeof net === 'string' ? net : '';
	}).filter(function(name, index, names) {
		return !!name && names.indexOf(name) === index;
	}).sort();
}

function metaItem(label, value) {
	return E('span', { 'class': 'honk-meta-item' }, [
		E('span', { 'class': 'honk-meta-label' }, label),
		value == null || value === '' ? '—' : String(value)
	]);
}

function field(label, control, help) {
	/* 说明文字放进控件列下方，两栏布局时才不会挤到右边去 */
	const controlId = control.id || (control.querySelector && control.querySelector('input, select, textarea') || {}).id;
	const cell = E('div', { 'class': 'cbi-value-field' }, [ control ]);
	if (help)
		cell.appendChild(E('div', { 'class': 'cbi-value-description honk-note' }, help));
	return E('div', { 'class': 'cbi-value' }, [
		E('label', { 'class': 'cbi-value-title', 'for': controlId || null }, label),
		cell
	]);
}

function captureFields(root) {
	const values = {};
	Array.prototype.forEach.call(root.querySelectorAll('input, select, textarea'), function(input) {
		const key = input.id || input.name;
		if (!key)
			return;

		values[key] = {
			value: input.value,
			checked: input.checked,
			focused: document.activeElement === input,
			selectionStart: typeof input.selectionStart === 'number' ? input.selectionStart : null,
			selectionEnd: typeof input.selectionEnd === 'number' ? input.selectionEnd : null
		};
	});
	return values;
}

function restoreFields(root, values) {
	Object.keys(values).forEach(function(key) {
		const input = root.querySelector('#%s'.format(key));
		if (!input || input.type === 'file')
			return;

		input.value = values[key].value;
		input.checked = values[key].checked;
		/* 自绘开关听的是 change，回填不会自己触发。 */
		if (input.classList.contains('honk-switch-input'))
			input.dispatchEvent(new Event('change'));
		if (values[key].focused) {
			input.focus();
			if (values[key].selectionStart !== null && typeof input.setSelectionRange === 'function')
				input.setSelectionRange(values[key].selectionStart, values[key].selectionEnd);
		}
	});
}

return view.extend({
	handleSave: null,
	handleSaveApply: null,
	handleReset: null,

	load: function() {
		return Promise.all([
			honk.status().then(function(status) { return { status: status }; }).catch(function(error) { return { error: error.message || String(error) }; }),
			honk.lanCandidates().then(function(result) { return { candidates: (result && result.candidates) || [] }; }).catch(function() { return { candidates: [] }; })
		]).then(function(results) {
			return Object.assign({}, results[0], results[1]);
		});
	},

	render: function(data) {
		honk.installStyles();
		const page = E('div', { 'class': 'cbi-map honk-page' });
		const statusArea = E('div');
		const actionMessage = E('p', { 'class': 'honk-status-msg', 'role': 'status' }, '');
		const setupArea = E('div');
		let currentStatus = data.status;
		/* 表单加载时的配置摘要；自动刷新后仍用它，避免拿新 SHA 提交旧表单值。 */
		let formSnapshotSha = null;
		let busy = false;
		let setupBusy = false;
		let settingsBusy = false;
		let setupState = null;

		function renderStatus(status, error) {
			const fields = captureFields(statusArea);
			const focusedAction = statusArea.contains(document.activeElement) && document.activeElement.dataset.action;
			while (statusArea.firstChild)
				statusArea.removeChild(statusArea.firstChild);

			if (error) {
				statusArea.appendChild(E('div', { 'class': 'alert-message' }, _('Could not read Honk status.')));
				restoreFields(statusArea, fields);
				return;
			}

			currentStatus = status;
			const running = status.running === true;

			/* Status card */
			const badge = E('span', {
				'class': 'honk-badge %s'.format(running ? 'honk-badge--run' : 'honk-badge--stop')
			}, running ? _('Running') : _('Stopped'));

			const webUi = honk.localWebUi(status);
			const openDoona = E(webUi ? 'a' : 'button', {
				'class': 'cbi-button cbi-button-action',
				'href': webUi || null,
				'target': webUi ? '_blank' : null,
				'rel': webUi ? 'noopener noreferrer' : null,
				'type': webUi ? null : 'button',
				'disabled': webUi ? null : true
			}, _('Open Doona'));
			const clashUi = honk.localClashUi(status);
			const openClash = E(clashUi ? 'a' : 'button', {
				'class': 'cbi-button cbi-button-action',
				'href': clashUi || null,
				'target': clashUi ? '_blank' : null,
				'rel': clashUi ? 'noopener noreferrer' : null,
				'type': clashUi ? null : 'button',
				'disabled': clashUi ? null : true
			}, _('Open Clash panel'));

			const toggle = E('button', {
				'class': 'cbi-button cbi-button-action',
				'type': 'button',
				'data-action': running ? 'stop' : 'start'
			}, running ? _('Stop') : _('Start'));
			toggle.disabled = busy || !status.initialized;
			if (!status.initialized)
				toggle.title = _('Finish the first setup first: Honk does not start without an administrator.');
			toggle.addEventListener('click', function(ev) {
				ev.preventDefault();
				runAction(running ? 'stop' : 'start');
			});

			const actions = [ openDoona, openClash, toggle ];
			if (running) {
				const restart = E('button', { 'class': 'cbi-button', 'type': 'button', 'data-action': 'restart' }, _('Restart'));
				restart.disabled = busy;
				restart.addEventListener('click', function(ev) {
					ev.preventDefault();
					runAction('restart');
				});
				actions.push(restart);
			}

			const statusCard = E('section', { 'class': 'honk-card' }, [
				E('div', { 'class': 'honk-card-head' }, [
					E('div', {}, [
						E('h3', { 'class': 'honk-card-title' }, _('Status')),
						badge
					]),
					E('div', { 'class': 'honk-actions' }, actions)
				]),
				E('div', { 'class': 'honk-meta' }, [
					metaItem(_('Core version'), status.core_version),
					metaItem(_('Doona version'), status.doona_version),
					metaItem(_('Kernel'), status.kernel)
				])
			]);

			if (status.clash_api_enabled && running && !clashUi)
				statusCard.appendChild(E('p', { 'class': 'honk-note', 'role': 'status' }, status.clash_api_ready ? _('Zashboard is still downloading or unavailable.') : _('The Clash API listener is unavailable. Check the service logs.')));

			const errors = (Array.isArray(status.errors) ? status.errors : []).filter(function(token) {
				return token !== 'disabled' && token !== 'not_initialized' && token !== 'service_not_running';
			});
			if (errors.length)
				statusCard.appendChild(E('ul', { 'class': 'alert-message' }, errors.map(function(token) {
					return E('li', {}, honk.statusIssue(token));
				})));

			if (!status.initialized)
				statusCard.appendChild(E('p', { 'class': 'honk-note', 'role': 'status' }, _('Not initialized yet. Finish the first setup below, then Honk can be started.')));

			statusArea.appendChild(statusCard);
			statusArea.appendChild(renderServiceSettings(status));

			if (focusedAction) {
				const replacement = statusArea.querySelector('[data-action="%s"]'.format(focusedAction));
				if (replacement)
					replacement.focus();
			}
			restoreFields(statusArea, fields);
		}

		function splitAddress(value) {
			value = String(value || '');
			const at = value.lastIndexOf(':');
			if (at <= 0)
				return [ value, '' ];
			return [ value.slice(0, at), value.slice(at + 1) ];
		}

		function renderServiceSettings(status) {
			const card = E('section', { 'class': 'honk-card' });
			const form = E('form');
			const candidates = data.candidates || [];
			if (formSnapshotSha === null)
				formSnapshotSha = status.config_sha256 || '';
			const currentDevice = status.runtime_lan || status.lan_network || '';
			const listenParts = splitAddress(status.runtime_listen);
			const clashParts = splitAddress(status.clash_listen_addr);

			/* LAN 下拉按设备去重，值提交设备名；网络名只作说明。 */
			const lanSelect = E('select', { 'class': 'cbi-input-select', 'name': 'lan_device', 'id': 'honk-lan-device' });
			const seenDevice = {};
			candidates.forEach(function(c) {
				const dev = c.l3_device || c.device || '';
				if (!dev || seenDevice[dev])
					return;
				seenDevice[dev] = 1;
				/* 下拉只显示网络名，设备名和地址放 title，避免一行三段太挤。 */
				lanSelect.appendChild(E('option', { 'value': dev, 'title': '%s · %s'.format(dev, c.ipv4 || '—') }, c.network || dev));
			});
			if (currentDevice && !seenDevice[currentDevice])
				lanSelect.appendChild(E('option', { 'value': currentDevice }, currentDevice));
			if (currentDevice)
				lanSelect.value = currentDevice;
			if (!lanSelect.children.length)
				lanSelect.appendChild(E('option', { 'value': '' }, _('No network interfaces found')));

			const listenPortInput = E('input', { 'class': 'cbi-input-text', 'type': 'number', 'name': 'listen_port', 'id': 'honk-listen-port', 'min': '1', 'max': '65535', 'step': '1' });
			listenPortInput.value = listenParts[1] || (status.listen_port ? String(status.listen_port) : '9527');

			const clashEnabledInput = E('input', { 'type': 'checkbox', 'name': 'clash_api_enabled', 'id': 'honk-clash-enabled' });
			clashEnabledInput.checked = status.clash_api_enabled === true;
			const clashSwitch = honk.switchControl(clashEnabledInput);
			const clashPortInput = E('input', { 'class': 'cbi-input-text', 'type': 'number', 'name': 'clash_api_port', 'id': 'honk-clash-port', 'min': '1', 'max': '65535', 'step': '1' });
			clashPortInput.value = clashParts[1] || (status.clash_api_port ? String(status.clash_api_port) : '9090');
			const clashSecretInput = E('input', { 'class': 'cbi-input-password', 'type': 'password', 'name': 'clash_api_secret', 'id': 'honk-clash-secret', 'autocomplete': 'new-password', 'readonly': 'readonly' });
			clashSecretInput.addEventListener('focus', function() { clashSecretInput.removeAttribute('readonly'); });
			const clashClearInput = E('input', { 'type': 'checkbox', 'id': 'honk-clash-clear' });
			const clashClearSwitch = honk.switchControl(clashClearInput);
			const message = E('p', { 'class': 'honk-status-msg', 'role': 'status' }, '');
			const save = E('button', { 'class': 'cbi-button cbi-button-positive', 'type': 'submit' }, _('Save service settings'));

			/* 关闭时不丢绑定地址，只是禁用；重新打开仍用用户填过的值。 */
			function syncClashFields() {
				const on = clashEnabledInput.checked;
				clashPortInput.disabled = !on;
				clashSecretInput.disabled = !on;
				clashClearInput.disabled = !on;
			}
			clashEnabledInput.addEventListener('change', syncClashFields);
			syncClashFields();

			card.appendChild(E('h3', { 'class': 'honk-card-title' }, _('Service settings')));
			if (status.settings_owner !== 'file')
				card.appendChild(E('p', { 'class': 'honk-note' }, _('This configuration is managed by the panel. Saving keeps the previous layout.')));
			form.appendChild(field(_('LAN interface'), lanSelect));
			form.appendChild(field(_('Listen port'), listenPortInput));
			form.appendChild(field(_('Enable Clash API'), clashSwitch));
			form.appendChild(field(_('Clash API port'), clashPortInput));
			form.appendChild(field(_('Clash API secret'), clashSecretInput,
				status.clash_api_secret_set ? _('A secret is already set. Leave blank to keep it.') : _('Optional. Used by Clash API clients.')));
			form.appendChild(field(_('Clear saved secret'), clashClearSwitch));
			form.appendChild(E('p', { 'class': 'honk-note' }, _('Leave the secret blank to keep the saved one. Use your existing HTTPS reverse proxy for external access.')));
			form.appendChild(E('div', { 'class': 'cbi-page-actions' }, [ save ]));
			form.appendChild(message);

			form.addEventListener('submit', function(ev) {
				ev.preventDefault();
				const device = lanSelect.value;
				const listenPort = Number(listenPortInput.value);
				const clashOn = clashEnabledInput.checked;
				const clashPort = Number(clashPortInput.value);
				const secret = clashSecretInput.value;
				const mode = clashClearInput.checked ? 'clear' : (secret ? 'set' : 'keep');

				if (!device) { message.textContent = _('Choose a LAN interface.'); return; }
				if (!Number.isInteger(listenPort) || listenPort < 1 || listenPort > 65535) { message.textContent = _('The listen port must be between 1 and 65535.'); return; }
				if (clashOn) {
					if (!Number.isInteger(clashPort) || clashPort < 1 || clashPort > 65535) { message.textContent = _('The Clash API port must be between 1 and 65535.'); return; }
					if (clashPort === listenPort) { message.textContent = _('The Clash API port must differ from the listen port.'); return; }
				}
				if (mode === 'set' && /['\\\n\r\t]/.test(secret)) { message.textContent = _('The secret cannot contain quotes, backslashes or line breaks.'); return; }

				save.disabled = true;
				settingsBusy = true;
				message.textContent = _('Saving…');
				const matched = candidates.find(function(c) { return (c.l3_device || c.device) === device; });
				honk.settings({
					lan_network: matched ? matched.network : status.lan_network,
					lan_device: device,
					listen_port: listenPort,
					clash_api_enabled: clashOn,
					clash_api_port: clashPort,
					clash_api_secret: secret,
					clash_api_secret_mode: mode,
					expect_sha256: formSnapshotSha
				}).then(honk.ensureOk).then(function(result) {
					formSnapshotSha = null;
					clashSecretInput.value = '';
					clashClearInput.checked = false;
					message.textContent = honk.resultMessage(result, _('Service settings saved.'));
				}).catch(function(error) {
					message.textContent = honk.errorMessage(error, _('Settings could not be applied.'));
				}).finally(function() {
					settingsBusy = false;
					save.disabled = false;
					refresh();
				});
			});
			card.appendChild(form);
			return card;
		}

		function renderSetup(status) {
			if (setupBusy)
				return;
			if (!status)
				return;
			const initialized = status.initialized === true;
			if (setupState === initialized)
				return;
			setupState = initialized;
			const fields = captureFields(setupArea);
			while (setupArea.firstChild)
				setupArea.removeChild(setupArea.firstChild);

			if (initialized)
				return;

			const form = E('form', { 'class': 'honk-card' });
			const username = E('input', { 'type': 'text', 'name': 'username', 'id': 'honk-init-username', 'autocomplete': 'username', 'required': true, 'class': 'cbi-input-text' });
			const password = E('input', { 'type': 'password', 'name': 'password', 'id': 'honk-init-password', 'autocomplete': 'new-password', 'required': true, 'class': 'cbi-input-password' });
			const message = E('p', { 'class': 'honk-status-msg', 'role': 'status' }, '');
			const submit = E('button', { 'class': 'cbi-button cbi-button-positive', 'type': 'submit' }, _('Initialize Honk'));
			form.appendChild(E('h3', { 'class': 'honk-card-title' }, _('Initial setup')));
			form.appendChild(E('p', { 'class': 'honk-note' }, _('Create the Honk administrator account. The password is sent only for this request and is not saved by this page.')));
			form.appendChild(E('p', { 'class': 'honk-note' }, _('Username: letters, digits, underscore, dot or hyphen (max 64 characters). Password: 8 to 128 characters.')));
			form.appendChild(field(_('Username'), username));
			form.appendChild(field(_('Password'), password));
			form.appendChild(E('div', { 'class': 'cbi-page-actions' }, submit));
			form.appendChild(message);
			form.addEventListener('submit', function(ev) {
				ev.preventDefault();
				const user = username.value.trim();
				const secret = password.value;
				if (!user || !secret) {
					message.textContent = _('Enter both a username and password.');
					return;
				}
				/* 和后端 read_credentials 的规则保持一致，避免"看着合法却提交失败" */
				if (!/^[A-Za-z0-9_.-]{1,64}$/.test(user)) {
					message.textContent = _('Username may only contain letters, digits, underscore, dot or hyphen (max 64 characters).');
					return;
				}
				/* 内核 auth.rs 规定密码 8–128 个字符（按 Unicode 码点计），这里先拦一道 */
				const secretLength = Array.from(secret).length;
				if (secretLength < 8 || secretLength > 128) {
					message.textContent = _('The password must be between 8 and 128 characters.');
					return;
				}

				submit.disabled = true;
				setupBusy = true;
				message.textContent = _('Initializing…');
				honk.initialize(user, secret).then(honk.ensureOk).then(function(result) {
					username.value = '';
					password.value = '';
					message.textContent = honk.resultMessage(result, _('Honk initialized.'));
					return honk.status();
				}).then(function(updatedStatus) {
					setupBusy = false;
					currentStatus = updatedStatus;
					renderSetup(updatedStatus);
					renderStatus(updatedStatus, null);
				}).catch(function(error) {
					password.value = '';
					/* 以前这里把错误整个吞掉，用户只看到「初始化失败」。现在先给出
					   具体错误码的中文说明，再顺手跑一遍系统检查，把缺什么列出来。 */
					message.textContent = honk.errorMessage(error, _('Initialization failed.'));
					/* 三态：查出问题 / 检查通过 / 检查根本没跑完。以前 check() 失败被当成"没问题"。 */
					return honk.check().then(function(check) {
						const issues = (check && Array.isArray(check.errors)) ? check.errors : [];
						if (issues.length)
							message.textContent += ' ' + _('System check: %s').format(issues.map(honk.statusIssue).join('; '));
						else if (check && check.ok === true)
							message.textContent += ' ' + _('The system check passed. If it keeps failing, check the core log under Maintenance → Logs and report the code above.');
						else
							message.textContent += ' ' + _('The system check did not finish. Retry, or check the core log under Maintenance → Logs.');
					}, function() {
						message.textContent += ' ' + _('The system check did not finish (interface timeout or error). Retry, or check the core log under Maintenance → Logs.');
					});
				}).finally(function() {
					setupBusy = false;
					submit.disabled = false;
				});
			});
			setupArea.appendChild(form);
			restoreFields(setupArea, fields);
		}

		function refresh() {
			if (busy || setupBusy || settingsBusy)
				return Promise.resolve();
			return honk.status().then(function(status) {
				renderStatus(status, null);
				renderSetup(status);
			}).catch(function() {
				renderStatus(null, true);
			});
		}

		function runAction(method) {
			if (busy)
				return;
			busy = true;
			actionMessage.textContent = _('Working…');
			renderStatus(currentStatus, null);
			honk[method]().then(honk.ensureOk).then(function(result) {
				actionMessage.textContent = honk.resultMessage(result, _('Operation completed.'));
			}).catch(function(error) {
				actionMessage.textContent = honk.errorMessage(error, _('Operation failed. Check Honk status.'));
			}).finally(function() {
				busy = false;
				refresh();
			});
		}

		page.appendChild(E('div', { 'class': 'honk-header' }, [
			E('img', { 'class': 'honk-header-logo', 'src': L.resource('view/honk/logo.png'), 'alt': '' }),
			E('div', { 'class': 'honk-header-text' }, [
				E('h2', {}, _('Honk')),
				E('p', { 'class': 'honk-header-sub' }, _('Transparent proxy core for OpenWrt. Start, stop and manage the Honk service.'))
			])
		]));
		page.appendChild(statusArea);
		page.appendChild(actionMessage);
		page.appendChild(setupArea);
		renderStatus(data.status, data.error);
		if (data.status)
			renderSetup(data.status);
		poll.add(refresh, 5);
		return page;
	}
});
