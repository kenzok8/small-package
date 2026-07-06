// SPDX-License-Identifier: Apache-2.0

'use strict';
'require fs';
'require uci';
'require ui';
'require view';
'require view.daede.airport-sync as airportSync';
'require view.daede.backend as backend';
'require view.daede.clash-converter as clashConverter';
'require view.daede.daed-session as daedSession';
'require view.daede.styles as styles';

const FETCHER = '/usr/share/luci-app-daede/fetch-clash-yaml.sh';
const GENERATOR = '/usr/share/luci-app-daede/gen-dae-config.sh';
const SUB_STAGE = '/tmp/daede-sub.txt';
const FETCH_CHUNK_BYTES = 16384;

function decodeHexChunks(chunks) {
	const total = chunks.reduce(function(size, chunk) { return size + chunk.length / 2; }, 0);
	const bytes = new Uint8Array(total);
	let offset = 0;
	chunks.forEach(function(chunk) {
		for (let i = 0; i < chunk.length; i += 2)
			bytes[offset++] = parseInt(chunk.slice(i, i + 2), 16);
	});
	return new TextDecoder('utf-8').decode(bytes);
}

function fetchYaml(url, userAgent) {
	let token = '';
	return fs.exec(FETCHER, [ url, userAgent, 'handle' ]).then(function(res) {
		if (!res || res.code !== 0)
			throw new Error((res && (res.stderr || res.stdout)) || _('Fetch failed'));
		const match = String(res.stdout || '').trim().match(/^([A-Za-z0-9]+)\t(\d+)$/);
		if (!match)
			throw new Error(_('Fetcher returned an invalid response'));
		token = match[1];
		const chunks = Math.ceil(Number(match[2]) / FETCH_CHUNK_BYTES);
		const values = [];
		let chain = Promise.resolve();
		for (let index = 0; index < chunks; index++) {
			chain = chain.then(function() {
				return fs.exec(FETCHER, [ 'chunk', token, String(index) ]).then(function(part) {
					if (!part || part.code !== 0)
						throw new Error((part && (part.stderr || part.stdout)) || _('Failed to read subscription data'));
					values.push(String(part.stdout || '').trim());
				});
			});
		}
		return chain.then(function() { return decodeHexChunks(values); });
	}).finally(function() {
		if (token)
			fs.exec(FETCHER, [ 'cleanup', token ]).catch(function() {});
	});
}

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
	// HTTPS page: browser blocks the plain-HTTP :2023 fetch as mixed
	// content, so relay via a same-origin CGI. HTTP: hit daed direct. #11
	if (window.location.protocol === 'https:')
		return '/cgi-bin/daede-graphql';
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

function requestDaedCredentials(mode) {
	const init = (mode === 'init');
	return new Promise(function(resolve, reject) {
		const username = E('input', { 'class': 'cbi-input-text', 'autocomplete': 'username', 'placeholder': _('Username') });
		const password = E('input', { 'class': 'cbi-input-password', 'type': 'password', 'autocomplete': init ? 'new-password' : 'current-password', 'placeholder': _('Password') });
		if (init) {
			// prefill from the config-page account so the daed admin created here
			// matches what cron subscription updates use.
			username.value = uci.get('daed', 'config', 'dashboard_username') || '';
			password.value = uci.get('daed', 'config', 'dashboard_password') || '';
		}
		const cancel = E('button', { 'class': 'btn cbi-button' }, _('Cancel'));
		const submit = E('button', { 'class': 'btn cbi-button cbi-button-positive' },
			init ? _('Initialize and import') : _('Sign in and import'));

		cancel.addEventListener('click', function() {
			password.value = '';
			ui.hideModal();
			reject(new Error(init
				? _('daed is not initialized yet. Open the daed web panel (port 2023) to create an admin account, then import again.')
				: _('Import cancelled')));
		});
		submit.addEventListener('click', function() {
			if (!username.value || !password.value)
				return;
			const result = { username: username.value, password: password.value };
			password.value = '';
			ui.hideModal();
			resolve(result);
		});

		const intro = init
			? _('daed has not been initialized yet. The account below will be created as the daed admin (password needs at least 6 characters with both letters and numbers), then used to import.')
			: _('The password is not saved. Sign-in is remembered in this browser for up to 30 days.');

		ui.showModal(init ? _('Initialize daed') : _('Sign in to daed'), [ E('div', { 'class': 'dd-daed-login' }, [
			E('p', {}, intro),
			E('div', { 'class': 'cbi-value' }, [ E('label', { 'class': 'cbi-value-title' }, _('Username')), E('div', { 'class': 'cbi-value-field' }, username) ]),
			E('div', { 'class': 'cbi-value' }, [ E('label', { 'class': 'cbi-value-title' }, _('Password')), E('div', { 'class': 'cbi-value-field' }, password) ]),
			E('div', { 'class': 'right dd-daed-login-actions' }, [ cancel, ' ', submit ])
		]) ]);
		username.focus();
	});
}

function requestDaedToken(endpoint, forceLogin) {
	const cached = forceLogin ? '' : daedSession.load(window.localStorage);
	if (cached)
		return Promise.resolve({ token: cached, cached: true });

	// numberUsers is unauthenticated; 0 means the daed panel was never
	// initialized, so log-in can never succeed — bootstrap it with createUser.
	return graphQL(endpoint, 'query Init{numberUsers}', {}).then(function(state) {
		const needInit = !state || state.numberUsers === 0;
		let credentials;
		return requestDaedCredentials(needInit ? 'init' : 'login').then(function(value) {
			credentials = value;
			if (needInit)
				return graphQL(endpoint,
					'mutation Init($username:String!,$password:String!){createUser(username:$username,password:$password)}',
					credentials).then(function(r) { return r.createUser; });
			return graphQL(endpoint,
				'query Login($username:String!,$password:String!){token(username:$username,password:$password)}',
				credentials).then(function(r) { return r.token; });
		}).then(function(token) {
			daedSession.save(window.localStorage, token);
			return { token: token, cached: false };
		}).finally(function() {
			if (credentials)
				credentials.password = '';
			credentials = null;
		});
	});
}

function applyUciChanges() {
	return uci.save().then(function() {
		return uci.changes().then(function(changes) {
			return changes && Object.keys(changes).length ? uci.apply() : null;
		});
	}).then(function() {
		// uci.apply() resolves before its rollback-confirm RPC has finished.
		// A second immediate apply is rejected, so wait for that confirmation.
		return new Promise(function(resolve) { window.setTimeout(resolve, 1800); });
	}).then(function() {
		// refresh LuCI's header indicator so the just-committed changes stop
		// showing as "Unsaved Changes".
		return ui.changes.init();
	});
}

function airportRecords() {
	return (uci.sections('daede', 'airport') || []).map(airportSync.parseAirportSection).filter(Boolean);
}

function uciSection(config, sid) {
	return (uci.sections(config) || []).find(function(section) { return section['.name'] === sid; }) || null;
}

function writeAirportRecord(existing, record) {
	const sid = existing && existing.sid ? existing.sid : uci.add('daede', 'airport');
	const values = airportSync.airportSectionValues(record);
	Object.keys(values).forEach(function(key) {
		const v = values[key];
		// uci/set rejects an empty list value; clear the option instead.
		if (Array.isArray(v) && v.length === 0)
			uci.unset('daede', sid, key);
		else
			uci.set('daede', sid, key, v);
	});
	return sid;
}

function looksLikeBase64Subscription(text) {
	const value = String(text || '').replace(/\s+/g, '');
	if (!value || !/^[A-Za-z0-9+/_=-]+$/.test(value))
		return false;
	try {
		const decoded = atob(value.replace(/-/g, '+').replace(/_/g, '/'));
		return /(?:ss|ssr|vmess|vless|trojan|tuic|hysteria2|hy2|anytls):\/\//i.test(decoded);
	} catch (e) {
		return false;
	}
}

return view.extend({
	load: function() {
		return Promise.all([
			backend.detectBackend(),
			uci.load('dae').catch(function() {}),
			uci.load('daed').catch(function() {}),
			uci.load('daede').catch(function() {}),
			loadYamlParser()
		]).then(function(values) {
			return { ctx: values[0], yaml: values[4] };
		});
	},

	render: function(data) {
		const state = {
			results: [],
			ignoredInfo: 0,
			filter: '',
			sourceHash: '',
			sourceName: '',
			selectedAirportId: '',
			target: data.ctx.installed[data.ctx.name] ? data.ctx.name : (data.ctx.installed.dae ? 'dae' : 'daed')
		};

		const urlInput = E('input', { 'class': 'dd-conv-url', 'placeholder': 'https://example.com/clash.yaml', 'autocomplete': 'off' });
		const uaSelect = E('select', { 'class': 'dd-conv-ua', 'title': _('Subscription User-Agent') }, [
			E('option', { 'value': 'auto' }, _('Auto User-Agent (recommended)')),
			E('option', { 'value': 'ClashMeta' }, 'ClashMeta'),
			E('option', { 'value': 'clash-verge/v2.4.2' }, 'clash-verge/v2.4.2'),
			E('option', { 'value': 'ClashForWindows/0.20.39' }, 'ClashForWindows/0.20.39'),
			E('option', { 'value': 'Clash' }, 'Clash'),
			E('option', { 'value': 'browser' }, _('Browser User-Agent'))
		]);
		const yamlInput = E('textarea', { 'class': 'dd-conv-yaml', 'placeholder': _('Or paste Clash YAML here'), 'spellcheck': 'false' });
		const parseUrl = E('button', { 'class': 'cbi-button cbi-button-action' }, _('Fetch and parse'));
		const parsePaste = E('button', { 'class': 'cbi-button' }, _('Parse pasted YAML'));
		const filterInput = E('input', { 'class': 'dd-conv-filter', 'placeholder': _('Filter name or protocol') });
		const selectNew = E('button', { 'class': 'cbi-button' }, _('Select compatible new nodes'));
		const clearSelection = E('button', { 'class': 'cbi-button' }, _('Clear selection'));
		const targetSelect = E('select', { 'class': 'dd-conv-target' });
		const airportName = E('input', { 'class': 'dd-conv-airport-name', 'placeholder': _('Group name'), 'autocomplete': 'off' });
		const importButton = E('button', { 'class': 'cbi-button cbi-button-positive', 'disabled': 'disabled' }, _('Import node group'));
		const importTitle = E('h4', { 'class': 'dd-card-title' });
		const airportNameLabel = E('label');
		const summary = E('div', { 'class': 'dd-conv-summary' });
		const groupSummary = E('div', { 'class': 'dd-conv-group-summary' });
		const sourceStatus = E('div', { 'class': 'dd-conv-status' }, '');
		const importStatus = E('div', { 'class': 'dd-conv-status' }, '');
		const resultBody = E('div', { 'class': 'dd-conv-results' });

		[ 'dae', 'daed' ].forEach(function(name) {
			if (data.ctx.installed[name])
				targetSelect.appendChild(E('option', { 'value': name, 'selected': state.target === name ? 'selected' : null }, name));
		});

		const setSourceStatus = function(text, kind) {
			sourceStatus.textContent = text || '';
			sourceStatus.className = 'dd-conv-status' + (kind ? ' ' + kind : '');
		};

		const setImportStatus = function(text, kind) {
			importStatus.textContent = text || '';
			importStatus.className = 'dd-conv-status' + (kind ? ' ' + kind : '');
		};

		const selectedResults = function() {
			return state.results.filter(function(item) { return item.ok && item.selected; });
		};

		const currentAirport = function() {
			return airportSync.matchAirport(airportRecords(), {
				backend: state.target,
				selectedId: state.selectedAirportId,
				name: airportName.value.trim()
			});
		};

		const classifyDaeDuplicates = function() {
			const existing = {};
			(uci.sections('dae', 'node') || []).forEach(function(section) {
				if (section.link)
					existing[clashConverter.normalizeLink(section.link)] = true;
			});
			state.results.forEach(function(item) {
				item.duplicate = !!(item.ok && existing[clashConverter.normalizeLink(item.link)]);
			});
		};

		const updateResultSummary = function() {
			const isDaed = state.target === 'daed';
			importTitle.textContent = isDaed ? _('3. Import Subscription') : _('3. Import Node Group');
			airportNameLabel.textContent = isDaed ? _('Subscription name') : _('Group name');
			const compatible = state.results.filter(function(item) { return item.ok; }).length;
			const unsupported = state.results.length - compatible;
			const duplicates = state.results.filter(function(item) { return item.duplicate; }).length;
			while (summary.firstChild)
				summary.removeChild(summary.firstChild);
			[
				[ _('Detected'), state.results.length + state.ignoredInfo ],
				[ _('Compatible'), compatible ],
				[ _('Duplicates'), duplicates ],
				[ _('Incompatible'), unsupported ],
				[ _('Ignored info'), state.ignoredInfo ]
			].forEach(function(item) {
				summary.appendChild(E('span', { 'class': 'dd-conv-summary-item' }, [
					E('span', { 'class': 'dd-conv-summary-label' }, item[0]),
					E('strong', {}, String(item[1]))
				]));
			});
			const count = selectedResults().length;
			const name = airportName.value.trim();
			const existing = currentAirport();
			const validName = airportSync.isGroupNameValid(name, state.target);
			if (!name) {
				groupSummary.textContent = isDaed
					? _('Enter a subscription name to import the selected nodes.')
					: _('Enter a group name to import the selected nodes.');
				groupSummary.className = 'dd-conv-group-summary';
			} else if (!validName) {
				groupSummary.textContent = _('dae group names may only contain letters, numbers, underscores, and hyphens, and must start with a letter or underscore.');
				groupSummary.className = 'dd-conv-group-summary err';
			} else if (isDaed && existing && count === 0) {
				groupSummary.textContent = _('Subscription "%s" is available on daed. Select nodes above to update it.').format(name);
				groupSummary.className = 'dd-conv-group-summary';
			} else if (isDaed) {
				groupSummary.textContent = existing
					? _('Update subscription "%s" with %d selected nodes in default group "proxy".').format(name, count)
					: _('Import %d selected nodes as subscription "%s" into default group "proxy".').format(count, name);
				groupSummary.className = 'dd-conv-group-summary';
			} else if (existing && count === 0) {
				groupSummary.textContent = _('Node group "%s" is available on %s. Select nodes above to update it.').format(name, state.target);
				groupSummary.className = 'dd-conv-group-summary';
			} else {
				groupSummary.textContent = existing
					? _('Update node group "%s": replace it with %d selected nodes on %s.').format(name, count, state.target)
					: _('Import %d selected nodes into group "%s" on %s.').format(count, name, state.target);
				groupSummary.className = 'dd-conv-group-summary';
			}
			importButton.textContent = isDaed
				? (existing ? _('Update subscription (%d)').format(count) : _('Import subscription (%d)').format(count))
				: (existing ? _('Update node group (%d)').format(count) : _('Import node group (%d)').format(count));
			importButton.disabled = count === 0 || !validName;
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
				checkbox.disabled = !item.ok;
				checkbox.addEventListener('change', function() {
					item.selected = checkbox.checked;
					updateResultSummary();
				});

				let resultText, resultClass;
				if (!item.ok) {
					resultText = item.error.indexOf('Unsupported protocol:') === 0
						? _('Unsupported protocol: %s').format(item.type)
						: item.error;
					resultClass = 'bad';
				} else if (item.duplicate) {
					resultText = _('Already exists, will be reused');
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
			if (!shown.length)
				resultBody.appendChild(E('div', { 'class': 'dd-conv-empty' }, _('No nodes to preview yet. Fetch or paste Clash YAML above.')));

			updateResultSummary();
		};

		const clearPreview = function() {
			state.results = [];
			state.ignoredInfo = 0;
			renderResults();
		};

		const acceptYaml = function(text, sourceValue, defaultName) {
			let documentValue;
			try {
				documentValue = data.yaml.load(text);
			} catch (e) {
				clearPreview();
				setSourceStatus(_('YAML parse failed: %s').format(e.message || e), 'err');
				return Promise.resolve();
			}
			if (!documentValue || !Array.isArray(documentValue.proxies) || documentValue.proxies.length === 0) {
				clearPreview();
				setSourceStatus(looksLikeBase64Subscription(text)
					? _('The server returned a Base64/share-link subscription, not Clash YAML. Try another subscription User-Agent or add the URL directly as a native subscription.')
					: _('No top-level proxies list was found'), 'err');
				return Promise.resolve();
			}

			const proxies = documentValue.proxies.filter(function(node) {
				return !clashConverter.isMetadataProxy(node);
			});
			state.ignoredInfo = documentValue.proxies.length - proxies.length;
			state.results = clashConverter.convertProxies(proxies).map(function(item) {
				item.selected = item.ok;
				item.duplicate = false;
				return item;
			});
			if (state.target === 'dae')
				classifyDaeDuplicates();
			setSourceStatus(state.results.some(function(item) { return item.ok; })
				? _('Conversion preview is ready')
				: _('Conversion completed, but no supported nodes were found'), state.results.some(function(item) { return item.ok; }) ? 'ok' : 'err');
			renderResults();
			return airportSync.hashSource(sourceValue || text).then(function(hash) {
				state.sourceHash = hash;
				// Pre-fill a name the third step accepts for the chosen backend,
				// so a URL hostname like sub.example.com doesn't land as an invalid
				// dae group name that the user has to fix by hand.
				const safeDefault = airportSync.sanitizeGroupName(defaultName || '', state.target);
				const matched = airportSync.matchAirport(airportRecords(), {
					backend: state.target,
					sourceHash: hash,
					name: safeDefault
				});
				state.selectedAirportId = matched ? matched.id : '';
				state.sourceName = matched ? matched.name : safeDefault;
				airportName.value = state.sourceName;
				renderResults();
			});
		};

		parseUrl.addEventListener('click', function() {
			const value = urlInput.value.trim();
			if (!/^https?:\/\//i.test(value)) {
				clearPreview();
				setSourceStatus(_('Enter an HTTP or HTTPS subscription URL'), 'err');
				return;
			}
			parseUrl.disabled = true;
			clearPreview();
			setSourceStatus(_('Fetching subscription…'));
			fetchYaml(value, uaSelect.value).then(function(text) {
				return acceptYaml(text, value, airportSync.deriveAirportName(value));
			}).catch(function(e) {
				clearPreview();
				setSourceStatus(_('Fetch failed: %s').format(String(e.message || e).trim()), 'err');
			}).finally(function() { parseUrl.disabled = false; });
		});

		parsePaste.addEventListener('click', function() {
			const value = yamlInput.value.trim();
			if (!value) {
				clearPreview();
				setSourceStatus(_('Paste Clash YAML first'), 'err');
				return;
			}
			acceptYaml(value, value, airportSync.nextPastedName(airportRecords().map(function(record) { return record.name; })))
				.catch(function(e) {
					clearPreview();
					setSourceStatus(_('YAML parse failed: %s').format(e.message || e), 'err');
				});
		});

		filterInput.addEventListener('input', function() {
			state.filter = filterInput.value;
			renderResults();
		});
		selectNew.addEventListener('click', function() {
			state.results.forEach(function(item) { item.selected = item.ok; });
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
			const matched = airportSync.matchAirport(airportRecords(), {
				backend: state.target,
				sourceHash: state.sourceHash,
				name: airportName.value.trim()
			});
			state.selectedAirportId = matched ? matched.id : '';
			if (matched)
				airportName.value = matched.name;
			renderResults();
		});
		airportName.addEventListener('input', function() {
			// Once the user edits the name, the visible group name becomes the
			// identity. Do not silently replace a source-matched old group.
			state.selectedAirportId = '';
			renderResults();
		});

		const runGenerator = function() {
			return fs.exec(GENERATOR, [ 'generate' ]).then(function(res) {
				if (res && res.code !== 0)
					throw new Error(res.stderr || res.stdout || ('exit ' + res.code));
			});
		};

		const importDae = function(items) {
			const existingAirport = currentAirport();
			const airportId = existingAirport ? existingAirport.id : airportSync.makeAirportId();
			const groupName = airportSync.backendGroupName(airportName.value, 'dae', airportId);
			// the group sources this tag; gen-dae-config slugs tag and source the
			// same way, so subtag() resolves even for CJK/hyphen names.
			const subTag = groupName;
			const subUrl = 'file://subscriptions/' + airportId + '.sub';
			const subContent = items.map(function(item) { return item.link; }).join('\n') + '\n';

			let subSid = existingAirport && existingAirport.subscription_id ? existingAirport.subscription_id : '';
			let groupSid = existingAirport && existingAirport.group_id ? existingAirport.group_id : '';
			const foundOldSub = (subSid && uciSection('dae', subSid)) || null;
			const foundOldGroup = (groupSid && uciSection('dae', groupSid)) || null;
			const oldSubSection = foundOldSub ? JSON.parse(JSON.stringify(foundOldSub)) : null;
			const oldGroupSection = foundOldGroup ? JSON.parse(JSON.stringify(foundOldGroup)) : null;
			const oldNodeIds = existingAirport ? existingAirport.node_ids : [];
			let subCreated = false;
			let groupCreated = false;

			const restoreSection = function(sid, snapshot) {
				const current = uciSection('dae', sid) || {};
				Object.keys(current).forEach(function(key) {
					if (key.charAt(0) !== '.' && !Object.prototype.hasOwnProperty.call(snapshot, key))
						uci.unset('dae', sid, key);
				});
				Object.keys(snapshot).forEach(function(key) {
					if (key.charAt(0) !== '.')
						uci.set('dae', sid, key, snapshot[key]);
				});
			};

			// 1. stage the converted links and let the backend write the local
			// .sub file (mkdir + chmod 0600 — dae rejects loose perms).
			return fs.write(SUB_STAGE, subContent).then(function() {
				return fs.exec(GENERATOR, [ 'write-sub', airportId ]);
			}).then(function(res) {
				if (res && res.code !== 0)
					throw new Error((res && (res.stderr || res.stdout)) || _('Failed to write subscription file'));

				// 2. one file:// subscription for the whole airport
				if (!foundOldSub) {
					subSid = uci.add('dae', 'subscription', airportId + '_sub');
					subCreated = true;
				}
				uci.set('dae', subSid, 'tag', subTag);
				uci.set('dae', subSid, 'url', subUrl);
				uci.set('dae', subSid, 'enabled', '1');

				// 3. group that sources the subscription
				if (!foundOldGroup) {
					const groupBase = airportId + '_group';
					groupSid = groupBase;
					let suffix = 2;
					while (uci.get('dae', groupSid))
						groupSid = groupBase + '_' + suffix++;
					uci.add('dae', 'group', groupSid);
					groupCreated = true;
				}
				uci.set('dae', groupSid, 'name', groupName);
				uci.set('dae', groupSid, 'policy', 'min_moving_avg');
				uci.set('dae', groupSid, 'source', [ subTag ]);

				return applyUciChanges().then(runGenerator).catch(function(error) {
					if (subCreated) uci.remove('dae', subSid);
					else if (oldSubSection) restoreSection(subSid, oldSubSection);
					if (groupCreated) uci.remove('dae', groupSid);
					else if (oldGroupSection) restoreSection(groupSid, oldGroupSection);
					return applyUciChanges().then(runGenerator).catch(function() {})
						.then(function() {
							if (subCreated) return fs.exec(GENERATOR, [ 'delete-sub', airportId ]).catch(function() {});
						})
						.then(function() { throw error; });
				});
			}).then(function() {
				// 4. drop this airport's legacy converted_N manual nodes
				oldNodeIds.forEach(function(sid) {
					if (uciSection('dae', sid)) uci.remove('dae', sid);
				});
				writeAirportRecord(existingAirport, {
					id: airportId,
					backend: 'dae',
					name: airportName.value.trim(),
					sourceHash: state.sourceHash,
					groupId: groupSid,
					subscriptionId: subSid,
					nodeIds: []
				});
				return applyUciChanges().then(runGenerator);
			}).then(function() {
				items.forEach(function(item) { item.duplicate = true; item.selected = false; });
				return { added: items.length, duplicates: 0, failed: 0 };
			});
		};

		const importDaed = function(items) {
			let token = '';
			let usedCachedToken = false;
			const existingAirport = currentAirport();
			const airportId = existingAirport ? existingAirport.id : airportSync.makeAirportId();
			const name = airportName.value.trim();
			const groupName = airportSync.backendGroupName(name, 'daed', airportId);
			const endpoint = daedEndpoint();
			// daed can't read file:// — it HTTP-fetches a subscription link. Stage
			// the converted links (base64) and let daed pull them from the
			// loopback-only CGI, so the import lands as ONE subscription.
			const subToken = airportSync.backendId(airportId) + Date.now().toString(36);
			const stageFile = '/tmp/daede-daedsub-' + subToken;
			const subUrl = 'http://127.0.0.1/cgi-bin/daede-sub?t=' + subToken;
			const b64 = btoa(items.map(function(item) { return item.link; }).join('\n') + '\n');

			let before;
			let newSubId = '';
			let createdGroupId = '';
			const createdNodeIds = [];
			let groupReady = false;
			const oldSubId = existingAirport ? existingAirport.subscription_id : '';
			const oldNodeIds = existingAirport ? existingAirport.node_ids : [];

			const dropStage = function() { return fs.exec('/bin/rm', [ '-f', stageFile ]).catch(function() {}); };
			const loadState = function(forceLogin) {
				return requestDaedToken(endpoint, forceLogin).then(function(auth) {
					token = auth.token;
					usedCachedToken = auth.cached;
					return graphQL(endpoint, 'query State{nodes(first:10000){edges{id link tag}} groups{id name nodes{id}}}', {}, token);
				});
			};
			const importDirectNodes = function() {
				const existing = {};
				const usedTags = {};
				(((before || {}).nodes || {}).edges || []).forEach(function(node) {
					existing[clashConverter.normalizeLink(node.link)] = node;
					if (node.tag)
						usedTags[String(node.tag)] = true;
				});
				const readableNodeTag = function(item, index) {
					const base = String(item.name || '').replace(/[\x00-\x1f\x7f]+/g, ' ').replace(/\s+/g, ' ').trim()
						|| _('Node %d').format(index + 1);
					let tag = base.slice(0, 96);
					let suffix = 2;
					while (usedTags[tag]) {
						const tail = ' ' + suffix++;
						tag = base.slice(0, 96 - tail.length) + tail;
					}
					usedTags[tag] = true;
					return tag;
				};
				const fresh = items.filter(function(item) {
					const duplicate = existing[clashConverter.normalizeLink(item.link)];
					if (duplicate)
						item.duplicate = true;
					return !duplicate;
				});
				const imported = fresh.length
					? graphQL(endpoint,
						'mutation ImportNodes($args:[ImportArgument!]!){importNodes(rollbackError:false,args:$args){link error node{id}}}',
						{ args: fresh.map(function(item, index) { return { link: item.link, tag: readableNodeTag(item, index) }; }) }, token)
					: Promise.resolve({ importNodes: [] });

				return imported.then(function(result) {
					const rows = result.importNodes || [];
					const nodeIds = [];
					const ownedIds = [];
					const rowByLink = {};
					rows.forEach(function(row) {
						rowByLink[clashConverter.normalizeLink(row.link)] = row;
					});
					let failed = rows.filter(function(row) { return !!row.error && row.error !== 'node already exists'; }).length;
					items.forEach(function(item) {
						const key = clashConverter.normalizeLink(item.link);
						const row = rowByLink[key];
						const old = existing[key];
						const id = row && row.node && row.node.id || old && old.id;
						if (id)
							nodeIds.push(id);
						if (row && !row.error && row.node) {
							ownedIds.push(row.node.id);
							createdNodeIds.push(row.node.id);
						}
						else if (existingAirport && oldNodeIds.indexOf(id) >= 0)
							ownedIds.push(id);
					});
					if (!nodeIds.length) {
						const details = rows.filter(function(row) { return !!row.error; }).map(function(row) {
							return row.error;
						}).filter(function(error, index, errors) {
							return errors.indexOf(error) === index;
						}).join('; ');
						throw new Error(details || _('No usable nodes were imported'));
					}

					const oldManagedGroup = airportSync.findManagedGroup(before.groups, existingAirport);
					const ensureGroup = oldManagedGroup
						? Promise.resolve(oldManagedGroup.id)
						: graphQL(endpoint,
							'mutation CreateGroup($name:String!,$policy:Policy!){createGroup(name:$name,policy:$policy){id}}',
							{ name: groupName, policy: 'min_moving_avg' }, token).then(function(value) {
								createdGroupId = value.createGroup.id;
								return createdGroupId;
							});
					return ensureGroup.then(function(groupId) {
						const rename = oldManagedGroup && oldManagedGroup.name !== groupName
							? graphQL(endpoint, 'mutation RenameGroup($id:ID!,$name:String!){renameGroup(id:$id,name:$name)}', { id: groupId, name: groupName }, token)
							: Promise.resolve();
						return rename.then(function() {
							return graphQL(endpoint, 'mutation SetPolicy($id:ID!,$policy:Policy!){groupSetPolicy(id:$id,policy:$policy)}', { id: groupId, policy: 'min_moving_avg' }, token);
						}).then(function() {
							return graphQL(endpoint, 'mutation AddNodes($id:ID!,$nodeIDs:[ID!]!){groupAddNodes(id:$id,nodeIDs:$nodeIDs)}', { id: groupId, nodeIDs: nodeIds }, token);
						}).then(function() {
							groupReady = true;
							const oldMembers = oldManagedGroup ? oldManagedGroup.nodes.map(function(node) { return node.id; }) : [];
							const removedMembers = oldMembers.filter(function(id) { return nodeIds.indexOf(id) < 0; });
							return (removedMembers.length
								? graphQL(endpoint, 'mutation DelNodes($id:ID!,$nodeIDs:[ID!]!){groupDelNodes(id:$id,nodeIDs:$nodeIDs)}', { id: groupId, nodeIDs: removedMembers }, token)
								: Promise.resolve()).catch(function() {
								failed++;
							}).then(function() {
								const otherAirportNodes = airportRecords().filter(function(record) {
									return record.backend === 'daed' && (!existingAirport || record.id !== existingAirport.id);
								}).map(function(record) { return record.node_ids; });
								const otherGroupNodes = before.groups.filter(function(other) {
									return other.id !== groupId;
								}).map(function(other) { return other.nodes.map(function(node) { return node.id; }); });
								const stale = airportSync.safeOldNodeIds(oldNodeIds, ownedIds, otherAirportNodes, otherGroupNodes);
								return (stale.length
									? graphQL(endpoint, 'mutation RemoveNodes($ids:[ID!]!){removeNodes(ids:$ids)}', { ids: stale }, token)
									: Promise.resolve()).catch(function() {
									failed++;
								}).then(function() {
									writeAirportRecord(existingAirport, {
										id: airportId,
										backend: 'daed',
										name: name,
										sourceHash: state.sourceHash,
										groupId: groupId,
										subscriptionId: '',
										nodeIds: ownedIds
									});
									return applyUciChanges().then(function() {
										items.forEach(function(item) { item.duplicate = true; item.selected = false; });
										return { added: ownedIds.length, duplicates: items.length - ownedIds.length, failed: failed };
									});
								});
							});
						});
					});
				});
			};

			return fs.write(stageFile, b64).then(function() {
				return loadState(false).catch(function(error) {
					if (!usedCachedToken || !daedSession.isAccessDenied(error))
						throw error;
					daedSession.clear(window.localStorage);
					return loadState(true);
				});
			}).then(function(dataValue) {
				before = dataValue;
				// drop this airport's previous subscription first: the new one
				// reuses the same tag (group name) and daed enforces unique tags.
				if (!oldSubId)
					return null;
				return graphQL(endpoint, 'mutation RmSub($ids:[ID!]!){removeSubscriptions(ids:$ids)}', { ids: [ oldSubId ] }, token).catch(function() {});
			}).then(function() {
				// import the whole converted batch as one subscription
				return graphQL(endpoint,
					'mutation Import($a:ImportArgument!){importSubscription(rollbackError:false,arg:$a){sub{id} nodeImportResult{error}}}',
					{ a: { link: subUrl, tag: groupName } }, token).then(function(result) {
						const sub = result.importSubscription && result.importSubscription.sub;
						const rows = (result.importSubscription && result.importSubscription.nodeImportResult) || [];
						const usable = rows.length
							? rows.some(function(r) { return !r.error || r.error === 'node already exists'; })
							: !!(sub && sub.id);
						if (!sub || !sub.id || !usable) {
							const details = rows.map(function(r) { return r.error; }).filter(Boolean).join('; ');
							if (sub && sub.id)
								newSubId = sub.id;
							throw new Error(details || _('No usable nodes were imported'));
						}
						return result;
					}).catch(function(error) {
						if (daedSession.isAccessDenied(error))
							throw error;
						const cleanupSub = newSubId
							? graphQL(endpoint, 'mutation Rm($ids:[ID!]!){removeSubscriptions(ids:$ids)}', { ids: [ newSubId ] }, token).catch(function() {})
							: Promise.resolve();
						newSubId = '';
						return cleanupSub.then(importDirectNodes).then(function(result) {
							return { directResult: result };
						});
					});
			}).then(function(result) {
				if (result.directResult)
					return result.directResult;

				const sub = result.importSubscription && result.importSubscription.sub;
				newSubId = sub.id;
				const rows = result.importSubscription.nodeImportResult || [];
				const failed = rows.filter(function(r) { return !!r.error && r.error !== 'node already exists'; }).length;

				const oldManagedGroup = airportSync.findManagedGroup(before.groups, existingAirport);
				const proxyGroup = airportSync.findGroupByName(before.groups, 'proxy');
				const ensureGroup = proxyGroup
					? Promise.resolve(proxyGroup.id)
					: graphQL(endpoint,
						'mutation CreateGroup($name:String!,$policy:Policy!){createGroup(name:$name,policy:$policy){id}}',
						{ name: 'proxy', policy: 'min_moving_avg' }, token).then(function(value) {
							createdGroupId = value.createGroup.id;
							return createdGroupId;
						});
				return ensureGroup.then(function(groupId) {
					return graphQL(endpoint, 'mutation AddSubs($id:ID!,$ids:[ID!]!){groupAddSubscriptions(id:$id,subscriptionIDs:$ids)}', { id: groupId, ids: [ newSubId ] }, token).then(function() {
						groupReady = true;
						const cleanup = [];
						// Migrate converter-managed airport groups to proxy, but never
						// disturb proxy's existing nodes or other subscriptions.
						if (oldManagedGroup && oldManagedGroup.id !== groupId)
							cleanup.push(graphQL(endpoint, 'mutation RmG($id:ID!){removeGroup(id:$id)}', { id: oldManagedGroup.id }, token).catch(function() {}));
						if (oldNodeIds.length)
							cleanup.push(graphQL(endpoint, 'mutation Rm($ids:[ID!]!){removeNodes(ids:$ids)}', { ids: oldNodeIds }, token).catch(function() {}));
						return Promise.all(cleanup).then(function() {
							writeAirportRecord(existingAirport, {
								id: airportId,
								backend: 'daed',
								name: name,
								sourceHash: state.sourceHash,
								groupId: groupId,
								subscriptionId: newSubId,
								nodeIds: []
							});
							return applyUciChanges().then(function() {
								items.forEach(function(item) { item.duplicate = true; item.selected = false; });
								return { added: items.length, duplicates: 0, failed: failed };
							});
						});
					});
				});
			}).catch(function(error) {
				if (daedSession.isAccessDenied(error))
					daedSession.clear(window.localStorage);
				if (groupReady || !token || (!newSubId && !createdGroupId && !createdNodeIds.length))
					throw error;
				const cleanup = [];
				if (newSubId)
					cleanup.push(graphQL(endpoint, 'mutation Rm($ids:[ID!]!){removeSubscriptions(ids:$ids)}', { ids: [ newSubId ] }, token));
				if (createdNodeIds.length)
					cleanup.push(graphQL(endpoint, 'mutation Rm($ids:[ID!]!){removeNodes(ids:$ids)}', { ids: createdNodeIds }, token));
				if (createdGroupId)
					cleanup.push(graphQL(endpoint, 'mutation RmG($id:ID!){removeGroup(id:$id)}', { id: createdGroupId }, token));
				return Promise.all(cleanup).catch(function() {}).then(function() { throw error; });
			}).finally(function() {
				token = '';
				return dropStage();
			});
		};

		importButton.addEventListener('click', function() {
			const items = selectedResults();
			if (!items.length)
				return;
			const name = airportName.value.trim();
			if (!name) {
				setImportStatus(_('Enter a group name'), 'err');
				return;
			}
			if (!airportSync.isGroupNameValid(name, state.target)) {
				setImportStatus(_('dae group names may only contain letters, numbers, underscores, and hyphens, and must start with a letter or underscore.'), 'err');
				return;
			}
			const existing = currentAirport();
			if (existing && !window.confirm(_('Replace node group "%s" with %d selected nodes?').format(existing.name, items.length)))
				return;
			importButton.disabled = true;
			setImportStatus(_('Importing node group…'));
			const action = state.target === 'dae' ? importDae(items) : importDaed(items);
			action.then(function(result) {
				setImportStatus(_('Node group imported: added %d, reused %d, failed %d')
					.format(result.added, result.duplicates, result.failed), result.failed ? 'err' : 'ok');
				renderResults();
			}).catch(function(e) {
				setImportStatus(_('Node group import failed: %s').format(e.message || e), 'err');
			}).finally(function() {
				importButton.disabled = selectedResults().length === 0;
			});
		});

		renderResults();

		return E('div', { 'class': 'dd-wrap dd-converter' }, [
			E('style', {}, styles.CSS),
			E('div', { 'class': 'dd-card dd-conv-card' }, [
				E('p', { 'class': 'dd-settings-descr' }, _('Convert Clash YAML to share links and import the nodes you pick. Nothing is saved.')),
				E('h4', { 'class': 'dd-card-title' }, _('1. Input Clash YAML')),
				E('div', { 'class': 'dd-conv-url-row' }, [ urlInput, uaSelect, parseUrl ]),
				E('div', { 'class': 'dd-conv-or' }, _('or')),
				yamlInput,
				E('div', { 'class': 'dd-actions' }, [ parsePaste ]),
				sourceStatus
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
				importTitle,
				E('div', { 'class': 'dd-conv-import dd-conv-airport' }, [
					airportNameLabel,
					airportName,
					E('label', {}, _('Target backend')),
					targetSelect
				]),
				groupSummary,
				E('div', { 'class': 'dd-conv-import dd-conv-submit' }, [ importButton ]),
				importStatus
			])
		]);
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
