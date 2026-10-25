// SPDX-License-Identifier: GPL-3.0-only

'use strict';
'require rpc';
'require view';
'require view.honk.rpc as honk';
'require view.honk.converter as converter';

const DAE_UPLOAD_PATH = '/tmp/honk-v2-upload/import.dae';
const DAE_LIMIT = 2 * 1024 * 1024;
const PASTE_LIMIT = 2 * 1024 * 1024;

function utf8Length(value) {
	return new TextEncoder().encode(value).length;
}

function isHttpUrl(value) {
	try {
		const url = new URL(value);
		return (url.protocol === 'http:' || url.protocol === 'https:') && !!url.hostname;
	}
	catch (e) {
		return false;
	}
}

function loadYamlParser() {
	if (window.jsyaml && window.jsyaml.load)
		return Promise.resolve(window.jsyaml);

	return new Promise(function(resolve, reject) {
		const script = document.createElement('script');
		script.src = L.resource('view/honk/vendor/js-yaml.min.js');
		script.onload = function() {
			if (window.jsyaml && window.jsyaml.load)
				resolve(window.jsyaml);
			else
				reject(new Error(_('YAML parser failed to load')));
		};
		script.onerror = function() { reject(new Error(_('YAML parser failed to load'))); };
		document.head.appendChild(script);
	});
}

function parsePasted(content) {
	let text = String(content || '').trim();
	if (!text)
		return Promise.resolve({ links: [], rejected: 1 });

	if (!converter.looksLikeNodeList(text)) {
		const decoded = converter.tryBase64Decode(text);
		if (decoded && (converter.looksLikeNodeList(decoded) ||
			converter.looksLikeClashYaml(decoded) || converter.looksLikeSurge(decoded)))
			text = decoded;
	}

	if (converter.looksLikeMihomoJson(text))
		return Promise.resolve(converter.parseMihomoJson(text));

	if (converter.looksLikeClashYaml(text)) {
		return loadYamlParser().then(function(yaml) {
			const doc = yaml.load(text);
			const proxies = (doc && doc.proxies) || [];
			const links = [];
			let rejected = 0;
			proxies.forEach(function(node) {
				if (converter.isMetadataProxy(node)) {
					rejected++;
					return;
				}
				const result = converter.convertProxy(node);
				if (result.ok) links.push(result.link);
				else rejected++;
			});
			return { links: links, rejected: rejected };
		});
	}

	if (converter.looksLikeSurge(text))
		return Promise.resolve(converter.parseSurgeProxies(text));

	return Promise.resolve(converter.parseUriList(text));
}

function uploadDae(file) {
	const form = new FormData();
	form.append('sessionid', rpc.getSessionID());
	form.append('filename', DAE_UPLOAD_PATH);
	form.append('filedata', file, file.name);
	return fetch(L.env.cgi_base + '/cgi-upload', {
		method: 'POST',
		credentials: 'same-origin',
		body: form
	}).then(function(response) {
		return response.json();
	}).then(function(result) {
		if (!result || result.failure)
			throw new Error('upload_failed');
		return result;
	});
}

return view.extend({
	handleSave: null,
	handleSaveApply: null,
	handleReset: null,

	render: function() {
		honk.installStyles();

		const page = E('div', { 'class': 'cbi-map honk-page' });
		page.appendChild(E('div', { 'class': 'honk-header' }, [
			E('h2', {}, _('Configuration')),
			E('p', { 'class': 'honk-header-sub' }, _('Honk reads its nodes, subscriptions and routing from /etc/honk/config.dae.'))
		]));

		/* --- Add subscription --- */
		const subStatus = E('p', { 'class': 'honk-note', 'role': 'status', 'aria-live': 'polite' }, '');
		const nameInput = E('input', {
			'class': 'cbi-input-text', 'name': 'sub_name',
			'placeholder': _('Name, e.g. MyAirport'), 'maxlength': '256'
		});
		const urlInput = E('input', {
			'class': 'cbi-input-text', 'name': 'sub_url',
			'placeholder': 'https://…', 'inputmode': 'url'
		});
		const subBtn = E('button', { 'class': 'cbi-button cbi-button-apply', 'type': 'button' }, [ _('Add subscription') ]);

		subBtn.addEventListener('click', function(ev) {
			ev.preventDefault();
			const name = nameInput.value.trim();
			const url = urlInput.value.trim();
			if (!name) { subStatus.textContent = _('Name is required.'); nameInput.focus(); return; }
			if (!isHttpUrl(url)) { subStatus.textContent = _('A valid HTTP or HTTPS URL is required.'); urlInput.focus(); return; }
			subBtn.disabled = true;
			subStatus.textContent = _('Adding subscription…');
			honk.addSubscription(name, url).then(honk.ensureOk).then(function(result) {
				subStatus.textContent = honk.resultMessage(result, _('Subscription saved with usable nodes.'));
				nameInput.value = '';
				urlInput.value = '';
			}).catch(function(error) {
				subStatus.textContent = honk.errorMessage(error, _('Could not add the subscription.'));
			}).finally(function() { subBtn.disabled = false; });
		});

		const subSection = E('section', { 'class': 'honk-card' }, [
			E('h3', { 'class': 'honk-card-title' }, _('Add subscription')),
			E('p', { 'class': 'honk-note' }, _('Enter a name and subscription URL. Honk checks for usable nodes before saving.')),
			E('div', { 'class': 'honk-subscription-add' }, [ nameInput, urlInput, subBtn ]),
			subStatus
		]);

		/* --- Paste nodes --- */
		const pasteStatus = E('p', { 'class': 'honk-note', 'role': 'status', 'aria-live': 'polite' }, '');
		const pasteInput = E('textarea', {
			'class': 'cbi-input-textarea', 'name': 'paste',
			'rows': '10', 'spellcheck': 'false',
			'placeholder': _('Paste Clash YAML, Surge INI, Base64 or share links.')
		});
		const pasteBtn = E('button', { 'class': 'cbi-button cbi-button-apply', 'type': 'button' }, [ _('Import nodes') ]);

		pasteBtn.addEventListener('click', function(ev) {
			ev.preventDefault();
			const content = pasteInput.value.trim();
			if (!content) { pasteStatus.textContent = _('Paste nodes or subscription content first.'); pasteInput.focus(); return; }
			if (utf8Length(content) > PASTE_LIMIT) { pasteStatus.textContent = _('The pasted content is too large.'); return; }
			pasteBtn.disabled = true;
			pasteStatus.textContent = _('Parsing nodes…');
			parsePasted(content).then(function(parsed) {
				const links = (parsed && parsed.links) || [];
				if (!links.length) {
					pasteStatus.textContent = _('No nodes could be parsed from the input.');
					return;
				}
				pasteStatus.textContent = _('Importing %d node(s)…').format(links.length);
				return honk.addNodes(links.join('\n')).then(honk.ensureOk).then(function(result) {
					pasteStatus.textContent = honk.resultMessage(result, _('%d node(s) imported.').format(links.length));
					pasteInput.value = '';
				});
			}).catch(function(error) {
				pasteStatus.textContent = honk.errorMessage(error, _('Could not import nodes.'));
			}).finally(function() { pasteBtn.disabled = false; });
		});

		const pasteSection = E('section', { 'class': 'honk-card' }, [
			E('h3', { 'class': 'honk-card-title' }, _('Paste nodes')),
			E('p', { 'class': 'honk-note' }, _('Paste Clash YAML, Surge INI, Base64 or share links; they are parsed locally into nodes and written to /etc/honk/config.dae.')),
			pasteInput,
			E('div', { 'class': 'honk-actions' }, [ pasteBtn ]),
			pasteStatus
		]);

		/* --- Import dae config --- */
		const daeStatus = E('p', { 'class': 'honk-note', 'role': 'status', 'aria-live': 'polite' }, '');
		const daeInput = E('input', { 'type': 'file', 'name': 'dae', 'accept': '.dae,text/plain' });
		const daeBtn = E('button', { 'class': 'cbi-button cbi-button-apply', 'type': 'button' }, [ _('Import configuration') ]);

		daeBtn.addEventListener('click', function(ev) {
			ev.preventDefault();
			const file = daeInput.files && daeInput.files[0];
			if (!file) { daeStatus.textContent = _('Choose a .dae file first.'); return; }
			if (file.size > DAE_LIMIT) { daeStatus.textContent = _('The dae file exceeds the 2 MiB limit.'); return; }
			daeBtn.disabled = true;
			daeStatus.textContent = _('Uploading configuration…');
			uploadDae(file).then(function() {
				daeStatus.textContent = _('Importing configuration…');
				return honk.importDae().then(honk.ensureOk);
			}).then(function(result) {
				daeStatus.textContent = honk.resultMessage(result, _('Configuration imported and Honk reloaded.'));
				daeInput.value = '';
			}).catch(function(error) {
				daeStatus.textContent = honk.errorMessage(error, _('Could not import the configuration.'));
			}).finally(function() { daeBtn.disabled = false; });
		});

		const daeSection = E('section', { 'class': 'honk-card' }, [
			E('h3', { 'class': 'honk-card-title' }, _('Import configuration')),
			E('p', { 'class': 'honk-note' }, _('Import a native dae config.dae (e.g. exported from Tower). Its node block is merged into /etc/honk/config.dae.')),
			E('div', { 'class': 'honk-subscription-add' }, [ daeInput, daeBtn ]),
			daeStatus
		]);

		/* --- Direct configuration note --- */
		const note = E('section', { 'class': 'honk-card' }, [
			E('h3', { 'class': 'honk-card-title' }, _('Direct configuration')),
			E('p', { 'class': 'honk-note' }, _('After the first valid subscription or node import, the fresh-install policy sends local and Chinese traffic direct and other traffic through the proxy group. You can adjust it in Doona.'))
		]);

		page.appendChild(subSection);
		page.appendChild(pasteSection);
		page.appendChild(daeSection);
		page.appendChild(note);
		return page;
	}
});
