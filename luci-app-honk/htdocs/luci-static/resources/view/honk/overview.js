// SPDX-License-Identifier: GPL-3.0-only

'use strict';
'require network';
'require poll';
'require view';
'require view.honk.rpc as honk';
'require uci';

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

function field(label, input, help) {
	/* 说明文字放进控件列下方，两栏布局时才不会挤到右边去 */
	const cell = E('div', { 'class': 'cbi-value-field' }, [ input ]);
	if (help)
		cell.appendChild(E('div', { 'class': 'cbi-value-description honk-note' }, help));
	return E('div', { 'class': 'cbi-value' }, [
		E('label', { 'class': 'cbi-value-title', 'for': input.id }, label),
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
			network.getNetworks().then(getNetworkNames).then(function(networks) { return { networks: networks }; }).catch(function() { return { networks: [] }; }),
			uci.load('honk').then(function() { return { clash_secret: uci.get('honk', 'main', 'clash_api_secret') || '' }; }).catch(function() { return { clash_secret: '' }; })
		]).then(function(results) {
			return Object.assign({}, results[0], results[1], results[2]);
		});
	},

	render: function(data) {
		honk.installStyles();
		const page = E('div', { 'class': 'cbi-map honk-page' });
		const statusArea = E('div');
		const actionMessage = E('p', { 'class': 'honk-status-msg', 'role': 'status' }, '');
		const setupArea = E('div');
		let currentStatus = data.status;
		const clashSecret = data.clash_secret || '';
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
			const clashUi = honk.localClashUi(status, clashSecret);
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

		function renderServiceSettings(status) {
			const card = E('section', { 'class': 'honk-card' });
			const form = E('form');
			const networkSelect = E('select', { 'class': 'cbi-input-select', 'name': 'lan_network', 'id': 'honk-lan-network' });
			const portInput = E('input', { 'class': 'cbi-input-text', 'type': 'number', 'name': 'listen_port', 'id': 'honk-listen-port', 'min': '1024', 'max': '65535', 'step': '1' });
						const clashEnabledInput = E('input', { 'type': 'checkbox', 'name': 'clash_api_enabled', 'id': 'honk-clash-enabled' });
			const clashPortInput = E('input', { 'class': 'cbi-input-text', 'type': 'number', 'name': 'clash_api_port', 'id': 'honk-clash-port', 'min': '1024', 'max': '65535', 'step': '1' });
			const clashSecretInput = E('input', { 'class': 'cbi-input-password', 'type': 'password', 'name': 'clash_api_secret', 'id': 'honk-clash-secret', 'autocomplete': 'new-password', 'readonly': 'readonly' });
			clashSecretInput.addEventListener('focus', function() { clashSecretInput.removeAttribute('readonly'); });
			const message = E('p', { 'class': 'honk-status-msg', 'role': 'status' }, '');
			const save = E('button', { 'class': 'cbi-button cbi-button-positive', 'type': 'submit' }, _('Save service settings'));

			(data.networks || []).forEach(function(name) {
				networkSelect.appendChild(E('option', { 'value': name }, name));
			});
			if (status.lan_network && !(data.networks || []).includes(status.lan_network))
				networkSelect.appendChild(E('option', { 'value': status.lan_network }, status.lan_network));
			if (status.lan_network)
				networkSelect.value = status.lan_network;
			portInput.value = status.listen_port ? String(status.listen_port) : '9527';
						clashEnabledInput.checked = status.clash_api_enabled === true;
			clashPortInput.value = status.clash_api_port ? String(status.clash_api_port) : '9090';

			card.appendChild(E('h3', { 'class': 'honk-card-title' }, _('Service settings')));
			/* Manual mode owns the whole runtime from config.dae, so the backend
			   rejects these settings. Disable them here instead of failing on save. */
			const manualMode = status.config_mode === 'manual';
			if (manualMode) {
				[ networkSelect, portInput, clashEnabledInput, clashPortInput, clashSecretInput ].forEach(function(input) {
					input.disabled = true;
				});
				save.disabled = true;
				card.appendChild(E('p', { 'class': 'honk-note honk-mode-hint' }, _('Manual mode: these settings belong to config.dae, so they are read-only here. Restore managed mode on the Configuration page to change them.')));
			}
			if (!(data.networks || []).length)
				networkSelect.appendChild(E('option', { 'value': '' }, _('No network interfaces found')));
			form.appendChild(field(_('LAN network'), networkSelect));
			form.appendChild(field(_('Listen port'), portInput));
						form.appendChild(field(_('Enable Clash API and Zashboard'), clashEnabledInput));
			form.appendChild(field(_('Clash API port'), clashPortInput));
			form.appendChild(field(_('Clash API secret'), clashSecretInput, status.clash_api_secret_set ? _('A secret is set. Leave blank to keep it.') : _('Required when enabling. Use 8–128 letters, numbers, dots, underscores or hyphens.')));
			form.appendChild(E('p', { 'class': 'honk-note' }, _('Use your existing HTTPS reverse proxy for external access. Enter the secret in Zashboard when connecting.')));
			form.appendChild(E('div', { 'class': 'cbi-page-actions' }, save));
			form.appendChild(message);
			form.addEventListener('submit', function(ev) {
				ev.preventDefault();
				const port = Number(portInput.value);
				const clashPort = Number(clashPortInput.value);
				const clashSecret = clashSecretInput.value;
				if (!networkSelect.value || !Number.isInteger(port) || port < 1024 || port > 65535) {
					message.textContent = _('Choose a LAN network and a port from 1024 to 65535.');
					return;
				}
				if (!Number.isInteger(clashPort) || clashPort < 1024 || clashPort > 65535) {
					message.textContent = _('Clash API port must be between 1024 and 65535.');
					return;
				}
				if (clashEnabledInput.checked && clashPort === port) {
					message.textContent = _('The Clash API port must differ from the listen port.');
					return;
				}
				if (clashEnabledInput.checked && !status.clash_api_secret_set && !clashSecret) {
					message.textContent = _('A secret is required when enabling Clash API.');
					return;
				}
				if (clashEnabledInput.checked && clashSecret && !/^[A-Za-z0-9._-]{6,128}$/.test(clashSecret)) {
					message.textContent = _('The secret must be 8-128 letters, numbers, dots, underscores or hyphens.');
					return;
				}

				save.disabled = true;
				settingsBusy = true;
				message.textContent = _('Saving…');
				honk.settings(networkSelect.value, port, clashEnabledInput.checked, clashPort, clashSecret).then(honk.ensureOk).then(function(result) {
					clashSecretInput.value = '';
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
			E('h2', {}, _('Honk')),
			E('p', { 'class': 'honk-header-sub' }, _('Transparent proxy core for OpenWrt. Start, stop and manage the Honk service.'))
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
