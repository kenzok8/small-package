// SPDX-License-Identifier: GPL-3.0-only

'use strict';
'require rpc';
'require view';
'require view.honk.rpc as honk';
'require view.honk.converter as converter';
'require ui';

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

		const modeText = E('span', {}, '');
		const modeNote = E('p', { 'class': 'honk-note honk-mode-note' }, [ modeText ]);
		page.appendChild(modeNote);

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
			preflightSubscription(url, subStatus).then(function(proceed) {
				if (!proceed)
					return null;
				subStatus.textContent = _('Adding subscription…');
				return withLongTimeout(function() {
					return honk.addSubscription(name, url).then(honk.ensureOk);
				}).then(function(result) {
					subStatus.textContent = honk.resultMessage(result, _('Subscription saved with usable nodes.'));
					nameInput.value = '';
					urlInput.value = '';
				}).catch(function(error) {
					subStatus.textContent = honk.errorMessage(error, _('Could not add the subscription.'));
				});
			}).finally(function() { subBtn.disabled = false; });
		});

		const subModeHint = E('p', { 'class': 'honk-note honk-mode-hint' }, _('Manual mode: this tool is disabled until you restore managed mode (link at the top).'));
		subModeHint.hidden = true;
		const subSection = E('section', { 'class': 'honk-card' }, [
			E('p', { 'class': 'honk-note' }, _('Enter a name and subscription URL. Honk checks for usable nodes before saving.')),
			subModeHint,
			E('div', { 'class': 'honk-subscription-add' }, [ nameInput, urlInput, subBtn ]),
			subStatus
		]);

		/* LuCI 的 rpc 默认 20s 超时；核心校验节点、重启服务都可能超过它，
		   期间客户端一断，服务端处理器会被杀掉（留下半完成状态）。 */
		function withLongTimeout(fn) {
			const previous = L.env.rpctimeout;
			L.env.rpctimeout = 180;
			return Promise.resolve().then(fn).finally(function() {
				L.env.rpctimeout = previous;
			});
		}

		/* honk 内核支持的节点类型（见 core 的 clash.rs protocol_from_name）：
		   ssr / snell / 带插件的 ss / 小众协议都会被内核判为不支持。 */
		const SUPPORTED_PROTOCOLS = {
			'socks': 1, 'socks5': 1, 'ss': 1, 'shadowsocks': 1, 'trojan': 1,
			'vmess': 1, 'vless': 1, 'hysteria': 1, 'hysteria2': 1, 'hy2': 1,
			'tuic': 1, 'juicity': 1, 'anytls': 1
		};
		/* JSON 订阅里 outbounds 会混进这些非节点类型，不能算作节点。 */
		const NON_NODE_TYPES = {
			'direct': 1, 'block': 1, 'dns': 1, 'selector': 1, 'urltest': 1,
			'url-test': 1, 'fallback': 1, 'load-balance': 1, 'relay': 1, 'reject': 1
		};

		function analyzeProbe(probe) {
			const counts = {};
			let total = 0;
			let usable = 0;
			let unsupported = 0;
			const bump = function(type) {
				const name = String(type || '').toLowerCase();
				if (!name || NON_NODE_TYPES[name])
					return;
				counts[name] = (counts[name] || 0) + 1;
				total++;
				if (SUPPORTED_PROTOCOLS[name])
					usable++;
				else
					unsupported++;
			};

			if (probe.format === 'base64' && probe.content) {
				const decoded = converter.tryBase64Decode(probe.content) || '';
				(decoded.match(/^[A-Za-z0-9+.-]+:\/\//gim) || []).forEach(function(scheme) {
					bump(scheme.replace(/:\/\/$/, ''));
				});
			}
			else if (probe.types) {
				String(probe.types).trim().split(/\s+/).forEach(function(pair) {
					const parts = pair.split(':');
					if (parts.length === 2) {
						const n = parseInt(parts[1], 10);
						for (let i = 0; i < (isNaN(n) ? 0 : n); i++)
							bump(parts[0]);
					}
				});
			}

			const labels = {
				clash: 'Clash / mihomo YAML',
				json: 'JSON（sing-box 等）',
				records: 'Surge / Loon 记录式 INI',
				uri: 'URI 列表',
				base64: 'Base64'
			};
			const label = labels[probe.format] || _('unknown format');
			const detail = Object.keys(counts).sort().map(function(type) {
				return type + ' ×' + counts[type] + (SUPPORTED_PROTOCOLS[type] ? '' : ' ' + _('unsupported'));
			}).join(', ');
			const text = total
				? _('Detected %s · %d node(s): %s').format(label, total, detail)
				: _('Detected %s.').format(label);

			return { text: text, total: total, usable: usable, unsupported: unsupported };
		}

		/* 保存前预检：能全部用就直接保存；全不可用就拦下；部分可用问一句。
		   预检本身失败（网络抖动等）不拦保存，退回原来的行为。 */
		function preflightSubscription(url, status) {
			status.textContent = _('Checking the subscription before saving…');
			return honk.probeSubscription(url).then(function(probe) {
				const verdict = analyzeProbe(probe);
				if (!verdict.total)
					return true;
				status.textContent = verdict.text;
				if (verdict.usable === 0) {
					status.textContent = verdict.text + ' ' + _('This core cannot use any of these nodes, so the subscription was not saved.');
					return false;
				}
				if (verdict.unsupported && !confirm(verdict.text + '\n\n' + _('Save the subscription anyway?')))
					return false;
				return true;
			}).catch(function() {
				return true;
			});
		}

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

		const pasteModeHint = E('p', { 'class': 'honk-note honk-mode-hint' }, _('Manual mode: this tool is disabled until you restore managed mode (link at the top).'));
		pasteModeHint.hidden = true;
		const pasteSection = E('section', { 'class': 'honk-card' }, [
			E('p', { 'class': 'honk-note' }, _('Paste Clash YAML, Surge INI, Base64 or share links. They are parsed locally into nodes and appended to /etc/honk/config.dae.')),
			pasteModeHint,
			pasteInput,
			E('div', { 'class': 'honk-actions' }, [ pasteBtn ]),
			pasteStatus
		]);

		/* --- Import a complete configuration and start Honk with it --- */
		const importStatus = E('p', { 'class': 'honk-note', 'role': 'status', 'aria-live': 'polite' }, '');
		/* 原生 file 控件在各主题下都被拉成一个大盒子、内嵌按钮贴着左上角，
		   和右边的按钮对不齐。改成隐藏原生控件、用 label 当按钮。 */
		const fileInput = E('input', { 'type': 'file', 'name': 'dae', 'accept': '.dae,text/plain', 'hidden': 'hidden' });
		const fileName = E('span', { 'class': 'honk-file-name' }, _('No file chosen'));
		const filePick = E('label', { 'class': 'cbi-button honk-file-pick' }, [ _('Choose file'), fileInput ]);
		fileInput.addEventListener('change', function() {
			const picked = fileInput.files && fileInput.files[0];
			fileName.textContent = picked ? picked.name : _('No file chosen');
		});
		const importBtn = E('button', { 'class': 'cbi-button cbi-button-apply', 'type': 'button' }, [ _('Import and start') ]);

		const importSection = E('section', { 'class': 'honk-card' }, [
			E('p', { 'class': 'honk-note' }, _('Upload a complete dae file (subscriptions, nodes and routing included) and Honk starts with it: the file is validated, written to /etc/honk/config.dae and the service is restarted. To hand-edit or paste instead, use the editor below.')),
			E('div', { 'class': 'honk-file-row' }, [ filePick, fileName, importBtn ]),
			importStatus
		]);

		/* --- Direct configuration --- */
		const editorStatus = E('p', { 'class': 'honk-note', 'role': 'status', 'aria-live': 'polite' }, '');
		const editor = E('textarea', {
			'class': 'cbi-input-textarea honk-config-editor', 'rows': '26',
			'spellcheck': 'false', 'wrap': 'off', 'aria-label': _('Full dae configuration')
		});
		const saveBtn = E('button', { 'class': 'cbi-button cbi-button-positive', 'type': 'button' }, [ _('Save and apply') ]);
		const reloadBtn = E('button', { 'class': 'cbi-button', 'type': 'button' }, [ _('Reload from disk') ]);
		const validateBtn = E('button', { 'class': 'cbi-button cbi-button-link', 'type': 'button' }, [ _('Check configuration') ]);
		const managedBtn = E('a', { 'href': '#', 'class': 'honk-inline-link', 'role': 'button' }, [ _('Restore managed mode') ]);
		managedBtn.hidden = true;
		modeNote.appendChild(managedBtn);

		let editorBaseline = '';

		function setEditorContent(content, message) {
			editor.value = content || '';
			editorBaseline = editor.value;
			editorStatus.textContent = message || '';
		}

		function confirmEditorReplace() {
			return editor.value === editorBaseline || confirm(_('Discard the unsaved editor changes?'));
		}

		function isOk(result) {
			return !!result && (result.ok === true || result.ok === 1);
		}

		/* Validation result -> one readable line. Valid configs also report the
		   runtime facts the core derived from the file, which is what users
		   actually want to confirm before touching a live router. */
		function validationText(result) {
			if (isOk(result)) {
				const runtime = result.runtime || {};
				const facts = [];
				if (Array.isArray(runtime.lan_interfaces) && runtime.lan_interfaces.length)
					facts.push(_('LAN %s').format(runtime.lan_interfaces.join(', ')));
				if (runtime.native_api_enabled)
					facts.push(_('Doona %s').format(runtime.native_api_listen || '—'));
				if (runtime.clash_api_listen)
					facts.push(_('Clash API %s').format(runtime.clash_api_listen));
				return facts.length
					? _('Configuration is valid: %s').format(facts.join(' · '))
					: _('Configuration is valid.');
			}
			const diagnostics = Array.isArray(result && result.diagnostics) ? result.diagnostics : [];
			if (!diagnostics.length)
				return honk.resultMessage(result, _('Configuration validation failed.'));
			return diagnostics.map(function(item) {
				const line = Number.isInteger(item.line) ? _('Line %d').format(item.line) : '';
				const setting = item.setting ? String(item.setting) : String(item.code || '');
				const message = String(item.message || '');
				return [ line, setting, message ].filter(Boolean).join(' · ');
			}).join(' | ');
		}

		/* 本机事实：LuCI 的 Doona 端口、活跃 L3 候选（含所属 netifd 网络）。取一次复用。 */
		let runtimeFacts = null;
		function runtimeContext() {
			if (!runtimeFacts)
				runtimeFacts = Promise.all([
					honk.status().catch(function() { return {}; }),
					honk.lanCandidates().catch(function() { return {}; })
				]).then(function(results) {
					const status = results[0] || {};
					const candidates = ((results[1] && results[1].candidates) || []).filter(function(item) {
						return item && item.l3_device;
					});
					return {
						listenPort: String(status.listen_port || 9527),
						lanNetwork: status.lan_network || 'lan',
						candidates: candidates,
						devices: candidates.map(function(item) { return item.l3_device; })
					};
				});
			return runtimeFacts;
		}

		/* 只在 native_api 块里改 ui，而且值必须**正好**是 embedded（embedded-custom 不算）。 */
		function fixNativeUi(text) {
			const lines = text.split('\n');
			const start = lines.findIndex(function(line) { return /^[ \t]*native_api[ \t]*\{/.test(line); });
			if (start < 0)
				return null;
			const baseIndent = lines[start].match(/^[ \t]*/)[0].length;
			for (let i = start + 1; i < lines.length; i++) {
				const line = lines[i];
				if (!line.trim())
					continue;
				const indent = line.match(/^[ \t]*/)[0].length;
				if (indent <= baseIndent && /^[ \t]*\}/.test(line))
					break;
				const match = /^([ \t]*ui[ \t]*:[ \t]*)(['"]?)embedded\2[ \t]*(#.*)?$/.exec(line);
				if (match) {
					lines[i] = match[1] + "'/usr/share/doona'" + (match[3] ? ' ' + match[3] : '');
					return { text: lines.join('\n') };
				}
			}
			return null;
		}

		function locateLanInterface(text) {
			const lines = text.split('\n');
			for (let i = 0; i < lines.length; i++) {
				const match = /^([ \t]*)lan_interface[ \t]*:[ \t]*([^\n#]+?)[ \t]*(#.*)?$/.exec(lines[i]);
				if (match)
					return { index: i, indent: match[1], value: match[2], comment: match[3] };
			}
			return null;
		}

		/* 优先 netifd 里配置的 LAN 网络；不做「取第一个活跃设备」，那可能是 WAN / VPN。 */
		function preferredLanDevice(ctx) {
			const order = [ ctx.lanNetwork, 'lan' ];
			for (let i = 0; i < order.length; i++) {
				const hit = ctx.candidates.find(function(item) { return item.network === order[i]; });
				if (hit)
					return { device: hit.l3_device, source: hit.network };
			}
			return null;
		}

		/* 多候选且无法确定时让用户挑；取消返回 null（表示不改这一项）。
		   ui.showModal() 返回的是 DOM 元素、不是 Promise，所以只能靠按钮回调
		   resolve；Esc 会被 LuCI 转成点击 .right 里第一个按钮（即取消）。 */
		function chooseLanDevice(ctx) {
			return new Promise(function(resolve) {
				const select = E('select', { 'class': 'cbi-input-select' }, ctx.candidates.map(function(item) {
					const label = [ item.network, item.l3_device, item.ipv4 ].filter(Boolean).join(' · ');
					return E('option', { 'value': item.l3_device }, label);
				}));
				ui.showModal(_('Choose the LAN interface'), [
					E('div', {}, [
						E('p', {}, _('None of the active interfaces belongs to the configured LAN network. Pick the one Honk should see as LAN:')),
						select
					]),
					E('div', { 'class': 'right' }, [
						E('button', { 'class': 'cbi-button', 'click': function(ev) {
							ev.preventDefault();
							ui.hideModal();
							resolve(null);
						} }, [ _('Cancel') ]),
						' ',
						E('button', { 'class': 'cbi-button cbi-button-positive', 'click': function(ev) {
							ev.preventDefault();
							ui.hideModal();
							resolve(select.value || null);
						} }, [ _('Use this interface') ])
					])
				]);
			});
		}

		/* 本机适配计划：算出「要改哪几处」和「改完的文本」，但**不落盘**。
		   allowPrompt = true 时才会弹选择框（校验时不要弹）。 */
		function planAdaptations(text, allowPrompt) {
			return runtimeContext().then(function(ctx) {
				const notes = [];
				const warnings = [];
				let next = text;

				const uiFix = fixNativeUi(next);
				if (uiFix) {
					next = uiFix.text;
					notes.push("native_api.ui: embedded → '/usr/share/doona'");
				}

				const lan = locateLanInterface(next);
				if (!lan)
					return { notes: notes, warnings: warnings, text: next };

				const named = lan.value.split(',').map(function(item) {
					return item.trim().replace(/^['"]|['"]$/g, '');
				}).filter(Boolean);
				if (!named.length || !ctx.devices.length || named.some(function(name) { return ctx.devices.indexOf(name) >= 0; }))
					return { notes: notes, warnings: warnings, text: next };

				const preferred = preferredLanDevice(ctx);
				let pick;
				if (preferred)
					pick = Promise.resolve(preferred.device);
				else if (ctx.candidates.length === 1)
					pick = Promise.resolve(ctx.candidates[0].l3_device);
				else if (allowPrompt)
					pick = chooseLanDevice(ctx);
				else
					pick = Promise.resolve(null);

				return pick.then(function(device) {
					if (!device) {
						/* 用户在选择框里按了取消：直接中止这次保存，不要再问一遍。 */
						if (allowPrompt && ctx.candidates.length > 1)
							return { notes: notes, warnings: warnings, text: next, cancelled: true };
						warnings.push(_('lan_interface: cannot tell which interface is the LAN here (candidates: %s); set it yourself').format(ctx.devices.join(', ') || '—'));
						return { notes: notes, warnings: warnings, text: next };
					}
					const lines = next.split('\n');
					lines[lan.index] = lan.indent + "lan_interface: '" + device + "'" + (lan.comment ? ' ' + lan.comment : '');
					notes.push('lan_interface: ' + named.join(',') + ' → ' + device);
					return { notes: notes, warnings: warnings, text: lines.join('\n') };
				});
			});
		}

		/* 保存前把适配写进编辑器。返回 false 表示用户拒绝或内容已变，调用方应中止。 */
		function adaptEditor() {
			const snapshot = editor.value;
			return planAdaptations(snapshot, true).then(function(plan) {
				if (plan.cancelled) {
					editorStatus.textContent = _('Save cancelled.');
					return false;
				}
				if (!plan.notes.length && !plan.warnings.length)
					return true;
				const blocks = [];
				if (plan.notes.length)
					blocks.push(_('These lines will be changed for this router:') + '\n' + plan.notes.join('\n'));
				if (plan.warnings.length)
					blocks.push(_('Needs your attention:') + '\n' + plan.warnings.join('\n'));
				blocks.push(_('Apply them in the editor now?'));
				if (!confirm(blocks.join('\n\n')))
					return false;
				/* 等设备查询 / 用户选择期间编辑器可能被改过，别用旧结果覆盖。 */
				if (editor.value !== snapshot) {
					editorStatus.textContent = _('The editor changed while checking. Nothing was applied; check again.');
					return false;
				}
				if (plan.notes.length) {
					editor.value = plan.text;
					editor.dispatchEvent(new Event('input'));
					editorStatus.textContent = _('Adapted in the editor: %s').format(plan.notes.join('; '));
				}
				return true;
			});
		}

		function withNotes(text) {
			return planAdaptations(editor.value, false).then(function(plan) {
				const parts = [];
				if (plan.notes.length)
					parts.push(_('Saving will adapt for this router: %s').format(plan.notes.join(', ')));
				if (plan.warnings.length)
					parts.push(plan.warnings.join(' '));
				return parts.length ? text + ' ' + parts.join(' ') : text;
			});
		}

		function reportValidation(result, target) {
			return withNotes(validationText(result)).then(function(text) {
				target.textContent = text;
			});
		}

		function pollStatus() {
			return honk.status().catch(function() { return null; });
		}

		/* Validate -> confirm -> write -> start, shared by the file import and the
		   editor. `target` is the status line the caller wants the outcome in. */
		function applyContent(content, target) {
			target.textContent = _('Checking the configuration…');
			return honk.configValidate(content).then(function(result) {
				if (!isOk(result)) {
					target.textContent = validationText(result);
					return;
				}
				return Promise.resolve().then(function() {
					const question = _('Write this configuration to /etc/honk/config.dae and start Honk? The previous file is restored if startup fails.');
					if (!confirm(question))
						return;
					return commitContent(content, target);
				});
			}).catch(function(error) {
				target.textContent = honk.errorMessage(error, _('Configuration validation failed.'));
			});
		}

		function commitContent(content, target) {
			target.textContent = _('Writing the configuration…');
			return withLongTimeout(function() { return honk.configSave(content); }).then(function(result) {
				if (!isOk(result)) {
					target.textContent = validationText(result);
					return;
				}
				if (content === editor.value)
					editorBaseline = editor.value;
				target.textContent = _('Starting Honk…');
				return withLongTimeout(function() { return honk.configApply().then(honk.ensureOk); }).then(function(applied) {
					target.textContent = honk.resultMessage(applied, _('Configuration applied.'));
					return pollStatus().then(function(status) {
						if (status && status.running)
							target.textContent = _('Configuration applied and Honk is running.');
						else
							target.textContent = _('Configuration was written, but Honk is not running: %s').format(
								((status && status.errors) || []).map(honk.statusIssue).join('; ') || _('unknown reason'));
					});
				}).catch(function(error) {
					target.textContent = honk.errorMessage(error, _('Could not apply the configuration.'));
				});
			}).catch(function(error) {
				target.textContent = honk.errorMessage(error, _('Could not save the configuration.'));
			}).then(function() {
				/* A failed apply rolls the file back, so reload what is really on
				   disk — but keep the outcome message the user needs to read. */
				const outcome = target.textContent;
				return refreshMode().then(function() {
					return loadCurrent(outcome === editorStatus.textContent ? outcome : '', true).catch(function() {});
				});
			});
		}

		function refreshMode() {
			return honk.status().then(function(status) {
				const manual = !!status && status.config_mode === 'manual';
				managedBtn.hidden = !manual;
				const tabState = page._honkTabs;
				if (tabState) {
					tabState.tabs.forEach(function(tab) {
						const disabled = manual && tab.managedOnly;
						tab.button.disabled = disabled;
						tab.panel.hidden = tab.id !== tabState.getActive();
					});
					if (manual && ['sub', 'nodes'].indexOf(tabState.getActive()) >= 0)
						tabState.select('edit');
				}
				subModeHint.hidden = !manual;
				pasteModeHint.hidden = !manual;
				subBtn.disabled = manual;
				pasteBtn.disabled = manual;
				nameInput.disabled = manual;
				urlInput.disabled = manual;
				pasteInput.disabled = manual;
				modeText.textContent = manual
					? _('Manual mode: the file below owns nodes, groups, routing and DNS.')
					: _('Managed mode: the subscription and paste-nodes tools are active. Saving here switches Honk to manual mode.');
				return status;
			}).catch(function() {
				modeText.textContent = '';
			});
		}

		/* force = false 用于页面初次载入：如果用户已经抢先开始输入，不要用磁盘内容
		   把他的编辑冲掉（异步回填比手速快）。apply 之后要的是磁盘真身，用 force。 */
		function loadCurrent(message, force) {
			return honk.configRead().then(honk.ensureOk).then(function(result) {
				if (!force && editor.value !== editorBaseline && editor.value !== '')
					return result;
				setEditorContent(result.content || '', message || _('Current configuration loaded from /etc/honk/config.dae.'));
				return result;
			});
		}

		importBtn.addEventListener('click', function(ev) {
			ev.preventDefault();
			const file = fileInput.files && fileInput.files[0];
			if (!file) { importStatus.textContent = _('Choose a .dae file first.'); return; }
			if (file.size > DAE_LIMIT) { importStatus.textContent = _('The dae file exceeds the 2 MiB limit.'); return; }
			importBtn.disabled = true;
			importStatus.textContent = _('Reading %s…').format(file.name);
			file.text().then(function(content) {
				if (!String(content || '').trim())
					throw new Error(_('The file is empty.'));
				fileInput.value = '';
				setEditorContent(content, _('Loaded %s into the editor.').format(file.name));
				const snapshot = editor.value;
				return planAdaptations(content, true).then(function(plan) {
					if (plan.cancelled) {
						importStatus.textContent = _('Import cancelled.');
						return null;
					}
					const blocks = [];
					if (plan.notes.length)
						blocks.push(_('These lines will be changed for this router:') + '\n' + plan.notes.join('\n'));
					if (plan.warnings.length)
						blocks.push(_('Needs your attention:') + '\n' + plan.warnings.join('\n'));
					if (blocks.length) {
						blocks.push(_('Apply them in the editor now?'));
						if (!confirm(blocks.join('\n\n')))
							return null;
					}
					if (editor.value !== snapshot) {
						importStatus.textContent = _('The editor changed while checking. Nothing was applied; import the file again.');
						return null;
					}
					if (plan.notes.length)
						setEditorContent(plan.text, _('Adapted in the editor: %s').format(plan.notes.join('; ')));
					return applyContent(editor.value, importStatus).then(function() {
						if (importStatus.textContent === _('Configuration applied and Honk is running.'))
							importStatus.textContent = _('%s imported and Honk is running.').format(file.name);
					});
				});
			}).catch(function(error) {
				importStatus.textContent = honk.errorMessage(error, _('Could not read the configuration file.'));
			}).finally(function() { importBtn.disabled = false; });
		});

		reloadBtn.addEventListener('click', function(ev) {
			ev.preventDefault();
			if (!confirmEditorReplace()) return;
			reloadBtn.disabled = true;
			loadCurrent(null, true).catch(function(error) {
				editorStatus.textContent = honk.errorMessage(error, _('Could not read the saved configuration.'));
			}).finally(function() { reloadBtn.disabled = false; });
		});

		validateBtn.addEventListener('click', function(ev) {
			ev.preventDefault();
			if (!editor.value.trim()) { editorStatus.textContent = _('The editor is empty.'); return; }
			validateBtn.disabled = true;
			editorStatus.textContent = _('Checking the configuration…');
			honk.configValidate(editor.value).then(function(result) {
				return reportValidation(result, editorStatus);
			}).catch(function(error) {
				editorStatus.textContent = honk.errorMessage(error, _('Configuration validation failed.'));
			}).finally(function() { validateBtn.disabled = false; });
		});

		saveBtn.addEventListener('click', function(ev) {
			ev.preventDefault();
			if (!editor.value.trim()) { editorStatus.textContent = _('The editor is empty.'); return; }
			saveBtn.disabled = true;
			adaptEditor().then(function(proceed) {
				if (!proceed) { editorStatus.textContent = _('Save cancelled.'); return null; }
				return applyContent(editor.value, editorStatus);
			}).finally(function() { saveBtn.disabled = false; });
		});

		managedBtn.addEventListener('click', function(ev) {
			ev.preventDefault();
			if (!confirm(_('Restore the managed configuration and return to the subscription tools? Honk restarts if it is running.'))) return;
			managedBtn.disabled = true;
			editorStatus.textContent = _('Restoring the managed configuration…');
			withLongTimeout(function() { return honk.configUseManaged().then(honk.ensureOk); }).then(function(result) {
				editorStatus.textContent = honk.resultMessage(result, _('Managed mode restored.'));
				return refreshMode().then(function() { return loadCurrent(null, true); });
			}).catch(function(error) {
				editorStatus.textContent = honk.errorMessage(error, _('Could not restore managed mode.'));
			}).finally(function() { managedBtn.disabled = false; });
		});

		const editorSection = E('section', { 'class': 'honk-card' }, [
			E('p', { 'class': 'honk-note' }, _('Edit or paste a complete dae file. Check configuration only parses the text; Save and apply writes /etc/honk/config.dae, restarts Honk, and rolls back if startup fails.')),
			E('div', { 'class': 'honk-subscription-add' }, [ saveBtn, reloadBtn, validateBtn ]),
			editor,
			editorStatus
		]);

		loadCurrent().catch(function(error) {
			editorStatus.textContent = honk.errorMessage(error, _('Could not read the saved configuration.'));
		});
		refreshMode();

		/* 一排标签页，只显示当前板块：四张卡片竖着堆太占屏，也不好一眼看出"有几种做法"。 */
		const tabs = [
			{ id: 'sub', label: _('Add subscription'), panel: subSection, managedOnly: true },
			{ id: 'nodes', label: _('Add nodes'), panel: pasteSection, managedOnly: true },
			{ id: 'import', label: _('Import config'), panel: importSection, managedOnly: false },
			{ id: 'edit', label: _('Edit config'), panel: editorSection, managedOnly: false }
		];
		let activeTab = 'sub';
		const tabBar = E('div', { 'class': 'honk-seg honk-tabs', 'role': 'tablist' });
		function selectTab(id) {
			activeTab = id;
			tabs.forEach(function(tab) {
				const active = tab.id === id;
				tab.panel.hidden = !active;
				tab.button.setAttribute('aria-selected', active ? 'true' : 'false');
				tab.button.classList.toggle('is-active', active);
			});
		}
		tabs.forEach(function(tab) {
			tab.button = E('button', {
				'class': 'honk-seg-btn', 'type': 'button', 'role': 'tab',
				'aria-selected': 'false'
			}, [ tab.label ]);
			tab.button.addEventListener('click', function(ev) {
				ev.preventDefault();
				if (tab.button.disabled)
					return;
				selectTab(tab.id);
			});
			tab.panel.hidden = true;
			tabBar.appendChild(tab.button);
		});
		page.appendChild(E('div', { 'class': 'honk-tabs-wrap' }, [ tabBar ]));
		tabs.forEach(function(tab) { page.appendChild(tab.panel); });
		selectTab(activeTab);

		/* 曝光给 refreshMode：手动模式下订阅/节点两个标签不可用，自动切到编辑配置。 */
		page._honkTabs = { tabs: tabs, select: selectTab, getActive: function() { return activeTab; } };
		return page;
	}
});
