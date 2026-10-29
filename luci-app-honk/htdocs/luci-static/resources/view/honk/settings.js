// SPDX-License-Identifier: GPL-3.0-only

'use strict';
'require network';
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

function field(label, input) {
	return E('div', { 'class': 'cbi-value' }, [
		E('label', { 'class': 'cbi-value-title', 'for': input.id }, label),
		E('div', { 'class': 'cbi-value-field' }, input)
	]);
}

return view.extend({
	handleSave: null,
	handleSaveApply: null,
	handleReset: null,

	load: function() {
		return Promise.all([
			honk.status().then(function(status) { return { status: status }; }).catch(function(error) { return { statusError: error.message || String(error) }; }),
			network.getNetworks().then(getNetworkNames).then(function(names) { return { networks: names }; }).catch(function(error) { return { networkError: error.message || String(error), networks: [] }; })
		]).then(function(results) {
			return Object.assign({}, results[0], results[1]);
		});
	},

	render: function(data) {
		honk.installStyles();
		const page = E('div', { 'class': 'cbi-map honk-page' });
		const section = E('form', { 'class': 'honk-card' });
		const networkSelect = E('select', { 'class': 'cbi-input-select', 'name': 'lan_network', 'id': 'honk-lan-network' });
		const portInput = E('input', { 'class': 'cbi-input-text', 'type': 'number', 'name': 'listen_port', 'id': 'honk-listen-port', 'min': '1024', 'max': '65535', 'step': '1' });
		const bootEnabledInput = E('input', { 'type': 'checkbox', 'name': 'boot_enabled', 'id': 'honk-boot-enabled' });
		const clashEnabledInput = E('input', { 'type': 'checkbox', 'name': 'clash_api_enabled', 'id': 'honk-clash-enabled' });
		const clashPortInput = E('input', { 'class': 'cbi-input-text', 'type': 'number', 'name': 'clash_api_port', 'id': 'honk-clash-port', 'min': '1024', 'max': '65535', 'step': '1' });
		const clashSecretInput = E('input', { 'class': 'cbi-input-password', 'type': 'password', 'name': 'clash_api_secret', 'id': 'honk-clash-secret', 'autocomplete': 'new-password', 'readonly': 'readonly' });
		clashSecretInput.addEventListener('focus', function() { clashSecretInput.removeAttribute('readonly'); });
		const message = E('p', { 'class': 'honk-status-msg', 'role': 'status' }, '');
		const save = E('button', { 'class': 'cbi-button cbi-button-positive', 'type': 'submit' }, _('Save settings'));
		save.disabled = !!data.statusError;

		(data.networks || []).forEach(function(name) {
			networkSelect.appendChild(E('option', { 'value': name }, name));
		});
		if (data.status && data.status.lan_network && !(data.networks || []).includes(data.status.lan_network))
			networkSelect.appendChild(E('option', { 'value': data.status.lan_network }, data.status.lan_network));
		if (data.status && data.status.lan_network)
			networkSelect.value = data.status.lan_network;
		portInput.value = data.status && data.status.listen_port ? String(data.status.listen_port) : '9527';
		bootEnabledInput.checked = !!(data.status && data.status.boot_enabled === true);
		clashEnabledInput.checked = !!(data.status && data.status.clash_api_enabled === true);
		clashPortInput.value = data.status && data.status.clash_api_port ? String(data.status.clash_api_port) : '9090';

		section.appendChild(E('h3', { 'class': 'honk-card-title' }, _('Honk settings')));

		/* In manual mode the whole runtime comes from config.dae, so the backend
		   refuses these settings. Disable them instead of letting the save fail
		   with an error the user cannot act on. */
		const manualMode = !!(data.status && data.status.config_mode === 'manual');
		if (manualMode) {
			[ networkSelect, portInput, bootEnabledInput, clashEnabledInput, clashPortInput, clashSecretInput ].forEach(function(input) {
				input.disabled = true;
			});
			save.disabled = true;
			section.appendChild(E('p', { 'class': 'honk-note honk-mode-hint' }, _('Manual mode: these settings belong to config.dae, so they are read-only here. Restore managed mode on the Configuration page to change them.')));
		}
		if (data.statusError)
			section.appendChild(E('div', { 'class': 'alert-message' }, _('Could not read current settings: %s').format(data.statusError)));
		if (data.networkError)
			section.appendChild(E('div', { 'class': 'alert-message' }, _('Could not load LAN networks: %s').format(data.networkError)));
		if (!(data.networks || []).length)
			networkSelect.appendChild(E('option', { 'value': '' }, _('No network interfaces found')));
		section.appendChild(field(_('LAN network'), networkSelect));
		section.appendChild(field(_('Listen port'), portInput));
		section.appendChild(field(_('Start Honk at boot'), bootEnabledInput));
		section.appendChild(field(_('Enable Clash API and Zashboard'), clashEnabledInput));
		section.appendChild(field(_('Clash API port'), clashPortInput));
		section.appendChild(field(_('Clash API secret'), clashSecretInput));
		section.appendChild(E('p', { 'class': 'honk-note' }, data.status && data.status.clash_api_secret_set ? _('A secret is set. Leave blank to keep it. Use your existing HTTPS reverse proxy for external access.') : _('A secret is required when enabling Clash API. Use 6–128 letters, numbers, dots, underscores or hyphens.')));
		section.appendChild(E('div', { 'class': 'cbi-page-actions' }, save));
		section.appendChild(message);
		section.addEventListener('submit', function(ev) {
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
			if (clashEnabledInput.checked && !(data.status && data.status.clash_api_secret_set) && !clashSecret) {
				message.textContent = _('A secret is required when enabling Clash API.');
				return;
			}
			if (clashEnabledInput.checked && clashSecret && !/^[A-Za-z0-9._-]{6,128}$/.test(clashSecret)) {
				message.textContent = _('The secret must be 6-128 letters, numbers, dots, underscores or hyphens.');
				return;
			}

			save.disabled = true;
			message.textContent = _('Saving…');
			honk.settings(networkSelect.value, port, bootEnabledInput.checked, clashEnabledInput.checked, clashPort, clashSecret).then(honk.ensureOk).then(function(result) {
				clashSecretInput.value = '';
				message.textContent = honk.resultMessage(result, _('Settings saved and applied.'));
			}).catch(function(error) {
				message.textContent = honk.errorMessage(error, _('Save failed. Check the settings and system status.'));
			}).finally(function() {
				save.disabled = false;
			});
		});

		page.appendChild(E('div', { 'class': 'honk-header' }, [
			E('h2', {}, _('Settings')),
			E('p', { 'class': 'honk-header-sub' }, _('Network interface, listen port and boot behaviour for the Honk service.'))
		]));
		page.appendChild(section);
		return page;
	}
});
