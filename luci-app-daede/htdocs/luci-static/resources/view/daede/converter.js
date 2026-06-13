// SPDX-License-Identifier: Apache-2.0

'use strict';
'require fs';
'require uci';
'require ui';
'require view';
'require view.daede.backend as backend';
'require view.daede.clash-converter as clashConverter';
'require view.daede.styles as styles';

const FETCHER = '/usr/share/luci-app-daede/fetch-clash-yaml.sh';
const GENERATOR = '/usr/share/luci-app-daede/gen-dae-config.sh';

function loadYamlParser() {
	if (window.jsyaml && window.jsyaml.load)
		return Promise.resolve(window.jsyaml);

	return new Promise(function(resolve, reject) {
		const script = document.createElement('script');
		script.src = L.resource('view/daede/vendor/js-yaml.min.js');
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

function daedEndpoint() {
	const listen = uci.get('daed', 'config', 'listen_addr') || '0.0.0.0:2023';
	const match = String(listen).match(/:(\d+)$/);
	const port = match ? match[1] : '2023';
	const host = window.location.hostname.indexOf(':') >= 0 ? '[' + window.location.hostname + ']' : window.location.hostname;
	return 'http://' + host + ':' + port + '/graphql';
}

function graphQL(endpoint, query, variables, token) {
	const headers = { 'Content-Type': 'application/json' };
	if (token)
		headers.Authorization = 'Bearer ' + token;

	return fetch(endpoint, {
		method: 'POST',
		headers: headers,
		body: JSON.stringify({ query: query, variables: variables || {} })
	}).then(function(response) {
		if (!response.ok)
			throw new Error(_('daed returned HTTP %s').format(response.status));
		return response.json();
	}).then(function(body) {
		if (body.errors && body.errors.length)
			throw new Error(body.errors.map(function(e) { return e.message; }).join('; '));
		return body.data;
	});
}

function requestDaedCredentials() {
	return new Promise(function(resolve, reject) {
		const username = E('input', { 'class': 'cbi-input-text', 'autocomplete': 'username', 'placeholder': _('Username') });
		const password = E('input', { 'class': 'cbi-input-password', 'type': 'password', 'autocomplete': 'current-password', 'placeholder': _('Password') });
		const cancel = E('button', { 'class': 'btn cbi-button' }, _('Cancel'));
		const login = E('button', { 'class': 'btn cbi-button cbi-button-positive' }, _('Sign in and import'));

		cancel.addEventListener('click', function() {
			password.value = '';
			ui.hideModal();
			reject(new Error(_('Import cancelled')));
		});
		login.addEventListener('click', function() {
			if (!username.value || !password.value)
				return;
			const result = { username: username.value, password: password.value };
			password.value = '';
			ui.hideModal();
			resolve(result);
		});

		ui.showModal(_('Sign in to daed'), [
			E('p', {}, _('Credentials are used only for this import and are not saved.')),
			E('div', { 'class': 'cbi-value' }, [ E('label', { 'class': 'cbi-value-title' }, _('Username')), E('div', { 'class': 'cbi-value-field' }, username) ]),
			E('div', { 'class': 'cbi-value' }, [ E('label', { 'class': 'cbi-value-title' }, _('Password')), E('div', { 'class': 'cbi-value-field' }, password) ]),
			E('div', { 'class': 'right' }, [ cancel, ' ', login ])
		]);
		username.focus();
	});
}

function uniqueNodeTag(existing, index) {
	let n = index + 1;
	let tag = 'converted_' + n;
	while (existing[tag]) {
		n++;
		tag = 'converted_' + n;
	}
	existing[tag] = true;
	return tag;
}

return view.extend({
	load: function() {
		return Promise.all([
			backend.detectBackend(),
			uci.load('dae').catch(function() {}),
			uci.load('daed').catch(function() {}),
			loadYamlParser()
		]).then(function(values) {
			return { ctx: values[0], yaml: values[3] };
		});
	},

	render: function(data) {
		const state = {
			results: [],
			filter: '',
			target: data.ctx.installed[data.ctx.name] ? data.ctx.name : (data.ctx.installed.dae ? 'dae' : 'daed')
		};

		const urlInput = E('input', { 'class': 'dd-conv-url', 'placeholder': 'https://example.com/clash.yaml', 'autocomplete': 'off' });
		const yamlInput = E('textarea', { 'class': 'dd-conv-yaml', 'placeholder': _('Or paste Clash YAML here'), 'spellcheck': 'false' });
		const parseUrl = E('button', { 'class': 'cbi-button cbi-button-action' }, _('Fetch and parse'));
		const parsePaste = E('button', { 'class': 'cbi-button' }, _('Parse pasted YAML'));
		const filterInput = E('input', { 'class': 'dd-conv-filter', 'placeholder': _('Filter name or protocol') });
		const selectNew = E('button', { 'class': 'cbi-button' }, _('Select compatible new nodes'));
		const clearSelection = E('button', { 'class': 'cbi-button' }, _('Clear selection'));
		const targetSelect = E('select', { 'class': 'dd-conv-target' });
		const importButton = E('button', { 'class': 'cbi-button cbi-button-positive', 'disabled': 'disabled' }, _('Import selected nodes'));
		const summary = E('span', { 'class': 'dd-meta' }, _('No YAML parsed yet'));
		const status = E('div', { 'class': 'dd-conv-status' }, '');
		const resultBody = E('div', { 'class': 'dd-conv-results' });

		[ 'dae', 'daed' ].forEach(function(name) {
			if (data.ctx.installed[name])
				targetSelect.appendChild(E('option', { 'value': name, 'selected': state.target === name ? 'selected' : null }, name));
		});

		const setStatus = function(text, kind) {
			status.textContent = text || '';
			status.className = 'dd-conv-status' + (kind ? ' ' + kind : '');
		};

		const selectedResults = function() {
			return state.results.filter(function(item) { return item.ok && item.selected && !item.duplicate; });
		};

		const classifyDaeDuplicates = function() {
			const existing = {};
			(uci.sections('dae', 'node') || []).forEach(function(section) {
				if (section.link)
					existing[clashConverter.normalizeLink(section.link)] = true;
			});
			state.results.forEach(function(item) {
				item.duplicate = !!(item.ok && existing[clashConverter.normalizeLink(item.link)]);
				if (item.duplicate)
					item.selected = false;
			});
		};

		const renderResults = function() {
			while (resultBody.firstChild)
				resultBody.removeChild(resultBody.firstChild);

			const filter = state.filter.toLowerCase();
			const shown = state.results.filter(function(item) {
				return !filter || item.name.toLowerCase().indexOf(filter) >= 0 || item.type.toLowerCase().indexOf(filter) >= 0;
			});

			shown.forEach(function(item) {
				const checkbox = E('input', { 'type': 'checkbox' });
				checkbox.checked = !!item.selected;
				checkbox.disabled = !item.ok || item.duplicate;
				checkbox.addEventListener('change', function() {
					item.selected = checkbox.checked;
					renderResults();
				});

				let resultText, resultClass;
				if (!item.ok) {
					resultText = item.error;
					resultClass = 'bad';
				} else if (item.duplicate) {
					resultText = _('Already exists, skipped');
					resultClass = 'dup';
				} else {
					resultText = _('Ready to import');
					resultClass = 'good';
				}

				resultBody.appendChild(E('div', { 'class': 'dd-conv-result' }, [
					checkbox,
					E('span', { 'class': 'dd-conv-name', 'title': item.name }, item.name),
					E('span', { 'class': 'dd-conv-proto' }, item.type.toUpperCase()),
					E('span', { 'class': 'dd-conv-result-state ' + resultClass, 'title': resultText }, resultText)
				]));
			});

			const compatible = state.results.filter(function(item) { return item.ok; }).length;
			const unsupported = state.results.length - compatible;
			const duplicates = state.results.filter(function(item) { return item.duplicate; }).length;
			summary.textContent = _('Detected %d · compatible %d · duplicates %d · incompatible %d')
				.format(state.results.length, compatible, duplicates, unsupported);
			importButton.textContent = _('Import selected nodes (%d)').format(selectedResults().length);
			importButton.disabled = selectedResults().length === 0;
		};

		const acceptYaml = function(text) {
			let documentValue;
			try {
				documentValue = data.yaml.load(text);
			} catch (e) {
				setStatus(_('YAML parse failed: %s').format(e.message || e), 'err');
				return;
			}
			if (!documentValue || !Array.isArray(documentValue.proxies) || documentValue.proxies.length === 0) {
				setStatus(_('No top-level proxies list was found'), 'err');
				return;
			}

			state.results = clashConverter.convertProxies(documentValue.proxies).map(function(item) {
				item.selected = item.ok;
				item.duplicate = false;
				return item;
			});
			if (state.target === 'dae')
				classifyDaeDuplicates();
			setStatus(_('Conversion preview is ready'), 'ok');
			renderResults();
		};

		parseUrl.addEventListener('click', function() {
			const value = urlInput.value.trim();
			if (!/^https?:\/\//i.test(value)) {
				setStatus(_('Enter an HTTP or HTTPS subscription URL'), 'err');
				return;
			}
			parseUrl.disabled = true;
			setStatus(_('Fetching subscription…'));
			fs.exec(FETCHER, [ value ]).then(function(res) {
				if (!res || res.code !== 0)
					throw new Error((res && (res.stderr || res.stdout)) || _('Fetch failed'));
				acceptYaml(res.stdout || '');
			}).catch(function(e) {
				setStatus(_('Fetch failed: %s').format(String(e.message || e).trim()), 'err');
			}).finally(function() { parseUrl.disabled = false; });
		});

		parsePaste.addEventListener('click', function() {
			const value = yamlInput.value.trim();
			if (!value) {
				setStatus(_('Paste Clash YAML first'), 'err');
				return;
			}
			acceptYaml(value);
		});

		filterInput.addEventListener('input', function() {
			state.filter = filterInput.value;
			renderResults();
		});
		selectNew.addEventListener('click', function() {
			state.results.forEach(function(item) { item.selected = item.ok && !item.duplicate; });
			renderResults();
		});
		clearSelection.addEventListener('click', function() {
			state.results.forEach(function(item) { item.selected = false; });
			renderResults();
		});
		targetSelect.addEventListener('change', function() {
			state.target = targetSelect.value;
			state.results.forEach(function(item) { item.duplicate = false; });
			if (state.target === 'dae')
				classifyDaeDuplicates();
			renderResults();
		});

		const importDae = function(items) {
			const usedTags = {};
			(uci.sections('dae', 'node') || []).forEach(function(section) {
				if (section.tag)
					usedTags[section.tag] = true;
			});
			items.forEach(function(item, index) {
				const sid = uci.add('dae', 'node');
				uci.set('dae', sid, 'tag', uniqueNodeTag(usedTags, index));
				uci.set('dae', sid, 'link', item.link);
				uci.set('dae', sid, 'enabled', '1');
			});

			return uci.save().then(function() {
				return uci.changes().then(function(changes) {
					return changes && Object.keys(changes).length ? uci.apply() : null;
				});
			}).then(function() {
				return fs.exec(GENERATOR, [ 'generate' ]);
			}).then(function(res) {
				if (res && res.code !== 0)
					throw new Error(res.stderr || res.stdout || ('exit ' + res.code));
				items.forEach(function(item) { item.duplicate = true; item.selected = false; });
				return { added: items.length, duplicates: 0, failed: 0 };
			});
		};

		const importDaed = function(items) {
			let credentials;
			let token = '';
			const endpoint = daedEndpoint();
			return requestDaedCredentials().then(function(value) {
				credentials = value;
				return graphQL(endpoint,
					'query Login($username:String!,$password:String!){token(username:$username,password:$password)}',
					credentials);
			}).then(function(login) {
				token = login.token;
				credentials.password = '';
				credentials = null;
				return graphQL(endpoint, 'query ExistingNodes{nodes(first:10000){edges{link}}}', {}, token);
			}).then(function(existingData) {
				const existing = {};
				(existingData.nodes.edges || []).forEach(function(node) {
					existing[clashConverter.normalizeLink(node.link)] = true;
				});
				const fresh = items.filter(function(item) {
					const duplicate = !!existing[clashConverter.normalizeLink(item.link)];
					if (duplicate) {
						item.duplicate = true;
						item.selected = false;
					}
					return !duplicate;
				});
				if (!fresh.length)
					return { importNodes: [], preDuplicates: items.length };
				return graphQL(endpoint,
					'mutation ImportNodes($args:[ImportArgument!]!){importNodes(rollbackError:false,args:$args){link error node{id}}}',
					{ args: fresh.map(function(item) { return { link: item.link }; }) }, token)
					.then(function(value) { value.preDuplicates = items.length - fresh.length; return value; });
			}).then(function(result) {
				const rows = result.importNodes || [];
				const importedItems = {};
				items.forEach(function(item) { importedItems[clashConverter.normalizeLink(item.link)] = item; });
				rows.forEach(function(row) {
					if (!row.error || row.error === 'node already exists') {
						const item = importedItems[clashConverter.normalizeLink(row.link)];
						if (item) {
							item.duplicate = true;
							item.selected = false;
						}
					}
				});
				const failed = rows.filter(function(row) { return !!row.error && row.error !== 'node already exists'; }).length;
				const apiDuplicates = rows.filter(function(row) { return row.error === 'node already exists'; }).length;
				const duplicates = (result.preDuplicates || 0) + apiDuplicates;
				const added = rows.filter(function(row) { return !row.error; }).length;
				return { added: added, duplicates: duplicates, failed: failed };
			}).finally(function() {
				if (credentials)
					credentials.password = '';
				credentials = null;
				token = '';
			});
		};

		importButton.addEventListener('click', function() {
			const items = selectedResults();
			if (!items.length)
				return;
			importButton.disabled = true;
			setStatus(_('Importing selected nodes…'));
			const action = state.target === 'dae' ? importDae(items) : importDaed(items);
			action.then(function(result) {
				setStatus(_('Import complete: added %d, duplicates %d, failed %d')
					.format(result.added, result.duplicates, result.failed), result.failed ? 'err' : 'ok');
				renderResults();
			}).catch(function(e) {
				setStatus(_('Import failed: %s').format(e.message || e), 'err');
			}).finally(function() {
				importButton.disabled = selectedResults().length === 0;
			});
		});

		renderResults();

		return E('div', { 'class': 'dd-wrap dd-converter' }, [
			E('style', {}, styles.CSS),
			E('div', { 'class': 'dd-card dd-conv-card' }, [
				E('h3', {}, _('Subscription Converter')),
				E('p', { 'class': 'dd-settings-descr' }, _('Convert Clash YAML into share links, preview the result, then import selected nodes into dae or daed. Inputs and credentials are not saved.')),
				E('h4', { 'class': 'dd-card-title' }, _('1. Input Clash YAML')),
				E('div', { 'class': 'dd-conv-url-row' }, [ urlInput, parseUrl ]),
				E('div', { 'class': 'dd-conv-or' }, _('or')),
				yamlInput,
				E('div', { 'class': 'dd-actions' }, [ parsePaste ])
			]),
			E('div', { 'class': 'dd-card dd-conv-card' }, [
				E('div', { 'class': 'dd-conv-heading' }, [
					E('h4', { 'class': 'dd-card-title' }, _('2. Conversion Preview')),
					summary
				]),
				E('div', { 'class': 'dd-conv-toolbar' }, [ selectNew, clearSelection, filterInput ]),
				resultBody
			]),
			E('div', { 'class': 'dd-card dd-conv-card' }, [
				E('h4', { 'class': 'dd-card-title' }, _('3. Import Selected Nodes')),
				E('div', { 'class': 'dd-conv-import' }, [
					E('label', {}, _('Target backend')),
					targetSelect,
					importButton
				]),
				status
			])
		]);
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
