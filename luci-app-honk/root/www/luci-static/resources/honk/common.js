'use strict';
'require baseclass';
'require rpc';
'require fs';
'require ui';
'require poll';
'require dom';
'require view';
'require form';

var callHonkStatus = rpc.declare({
	object: 'luci.honk',
	method: 'status',
	expect: { }
});

var callHonkReload = rpc.declare({
	object: 'luci.honk',
	method: 'reload',
	expect: { success: true }
});

var callHonkGetLog = rpc.declare({
	object: 'luci.honk',
	method: 'get_log',
	expect: { }
});

var callHonkClearLog = rpc.declare({
	object: 'luci.honk',
	method: 'clear_log',
	expect: { success: true }
});

var callHonkDashboardInfo = rpc.declare({
	object: 'luci.honk',
	method: 'get_dashboard_info',
	expect: { }
});

var callHonkDownloadDashboard = rpc.declare({
	object: 'luci.honk',
	method: 'download_dashboard',
	params: [ 'url' ],
	expect: { }
});

var callHonkZashboardInfo = callHonkDashboardInfo;
var callHonkDownloadZashboard = callHonkDownloadDashboard;

var callHonkDownloadStatus = rpc.declare({
	object: 'luci.honk',
	method: 'download_status',
	expect: { }
});

var callHonkEnableClashApi = rpc.declare({
	object: 'luci.honk',
	method: 'enable_clash_api',
	expect: { }
});

function readFile(path) {
	if (fs.read_direct) {
		return fs.read_direct(path).catch(function() {
			return L.resolveDefault(fs.read(path), '');
		});
	}
	return L.resolveDefault(fs.read(path), '');
}

function writeFile(path, content) {
	var clean = (content || '').replace(/\r\n/g, '\n');
	return fs.write(path, clean);
}

function loadStyle(href) {
	if (!document.querySelector('link[href="' + href + '"]')) {
		var link = document.createElement('link');
		link.rel = 'stylesheet';
		link.href = href;
		document.head.appendChild(link);
	}
}

function loadScript(src) {
	return new Promise(function(resolve, reject) {
		var existing = document.querySelector('script[src="' + src + '"]');
		if (existing) {
			resolve();
			return;
		}
		var s = document.createElement('script');
		s.src = src;
		s.async = false;
		s.onload = function() { resolve(); };
		s.onerror = function() { reject(new Error('Failed to load ' + src)); };
		document.head.appendChild(s);
	});
}

function ensureEditorStyles() {
	if (document.getElementById('honk-editor-custom-style')) return;

	var style = document.createElement('style');
	style.id = 'honk-editor-custom-style';
	style.textContent = [
		'.honk-status-field { display: inline-flex !important; align-items: center !important; justify-content: flex-start !important; gap: 16px !important; flex-wrap: wrap !important; min-height: 32px !important; }',
		'.honk-editor-toolbar { margin-bottom: 6px !important; margin-top: 0 !important; display: flex !important; align-items: center !important; justify-content: flex-start !important; }',
		'.cm-format-btn { margin: 0 !important; cursor: pointer !important; }',
		'.cbi-value:has(.CodeMirror) { align-items: flex-start !important; }',
		'.cbi-value:has(.CodeMirror) > .cbi-value-title { padding-top: 5px !important; }',
		'.cbi-value:has(.CodeMirror) .cbi-value-field { flex: 1 1 0% !important; min-width: 0 !important; width: auto !important; }',
		'.CodeMirror {',
		'	border: 1px solid var(--hairline, var(--border-color-medium, #ccc)) !important;',
		'	border-radius: var(--radius-base, 4px);',
		'	height: auto;',
		'	min-height: 480px;',
		'	font-family: var(--font-mono, monospace);',
		'	font-size: 13px;',
		'	background: var(--control-bg, var(--surface, #ffffff)) !important;',
		'	color: var(--text, inherit) !important;',
		'	box-shadow: none;',
		'}',
		'.CodeMirror-gutters {',
		'	border-right: 1px solid var(--hairline, var(--border-color-medium, #ccc)) !important;',
		'	background: var(--surface-sunken, var(--background-color-low, #f7f7f7)) !important;',
		'}',
		'.CodeMirror-linenumber { color: var(--text-muted, var(--text-color-low, #888888)) !important; }',
		'.CodeMirror-cursor { border-left: 1px solid var(--text, currentColor) !important; }',
		'[data-darkmode="true"] .CodeMirror, [data-theme="dark"] .CodeMirror, .dark .CodeMirror {',
		'	background: var(--control-bg, var(--surface, #141822)) !important;',
		'	color: var(--text, #f9fafb) !important;',
		'	border-color: var(--hairline, var(--border-color-medium, #334155)) !important;',
		'}',
		'[data-darkmode="true"] .CodeMirror-gutters, [data-theme="dark"] .CodeMirror-gutters, .dark .CodeMirror-gutters {',
		'	background: var(--surface-sunken, var(--background-color-low, #0a0e17)) !important;',
		'	border-right-color: var(--hairline, var(--border-color-medium, #334155)) !important;',
		'}'
	].join('\n');
	document.head.appendChild(style);
}

function ensureCodeMirror() {
	loadStyle(L.resource('honk/lib/codemirror.css'));
	loadStyle(L.resource('honk/addon/fold/foldgutter.css'));
	ensureEditorStyles();

	if (window.CodeMirror && window.CodeMirror.modes && window.CodeMirror.modes.dae) {
		return Promise.resolve(window.CodeMirror);
	}

	return loadScript(L.resource('honk/lib/codemirror.js'))
		.then(function() {
			return Promise.all([
				loadScript(L.resource('honk/addon/edit/matchbrackets.js')),
				loadScript(L.resource('honk/addon/edit/closebrackets.js')),
				loadScript(L.resource('honk/addon/fold/foldcode.js')),
				loadScript(L.resource('honk/addon/fold/foldgutter.js')),
				loadScript(L.resource('honk/addon/fold/indent-fold.js')),
				loadScript(L.resource('honk/mode/dae/dae.js'))
			]);
		})
		.then(function() {
			return window.CodeMirror;
		});
}

function formatEditor(ed) {
	ed.operation(function() {
		var cursor = ed.getCursor();
		var content = ed.getValue();

		var exprPrefixes = [
			'geosite', 'geoip', 'keyword', 'full', 'suffix', 'regex', 'domain',
			'pname', 'subtag', 'name', 'mac', 'dip', 'sip', 'dport', 'sport',
			'l4proto', 'ipversion_prefer', 'fallback', 'qtype', 'qname',
			'upstream', 'ip', 'tag', 'inlist'
		];
		var exprRegex = new RegExp('\\b(' + exprPrefixes.join('|') + ')\\s*:\\s*', 'g');

		var formatCodeSegment = function(str) {
			str = str.replace(/\s*->\s*/g, ' -> ');
			str = str.replace(/\s*&&\s*/g, ' && ');
			str = str.replace(/([^\s])\s*\{/g, '$1 {');
			str = str.replace(/\s*,\s*/g, ', ');
			str = str.replace(exprRegex, '$1: ');
			return str;
		};

		var formatLineCode = function(lineStr) {
			lineStr = lineStr.replace(/^(\s*[a-zA-Z0-9_-]+)\s*:\s*(\S.*)$/, '$1: $2');
			lineStr = lineStr.replace(/^(\s*[a-zA-Z0-9_-]+)\s*:\s*$/, '$1:');

			var quoteParts = lineStr.split(/(['"])/);
			var inQuote = false;
			var currentQuote = '';
			for (var j = 0; j < quoteParts.length; j++) {
				var part = quoteParts[j];
				if (part === "'" || part === '"') {
					if (!inQuote) {
						inQuote = true;
						currentQuote = part;
					} else if (part === currentQuote) {
						inQuote = false;
						currentQuote = '';
					}
				} else if (!inQuote) {
					var hashIdx = part.indexOf('#');
					if (hashIdx !== -1) {
						var codeSub = part.slice(0, hashIdx);
						var commentSub = part.slice(hashIdx);
						codeSub = formatCodeSegment(codeSub);
						if (codeSub.length > 0 && !/\s$/.test(codeSub)) {
							codeSub += ' ';
						}
						quoteParts[j] = codeSub + commentSub.trimEnd();
						quoteParts.splice(j + 1);
						break;
					} else {
						quoteParts[j] = formatCodeSegment(part);
					}
				}
			}
			return quoteParts.join('').trimEnd();
		};

		var lines = content.split('\n');
		var formattedLines = lines.map(function(line) {
			var trimmed = line.trim();
			if (!trimmed) {
				return '';
			}

			if (trimmed.startsWith('#') || trimmed.startsWith('//')) {
				var prefix = trimmed.startsWith('//') ? '//' : '#';
				var afterComment = trimmed.slice(prefix.length);

				var kvMatch = afterComment.match(/^(\s*)([a-zA-Z0-9_-]+)\s*:\s*(.*)$/);
				if (kvMatch) {
					var space = kvMatch[1];
					var key = kvMatch[2];
					var val = kvMatch[3].trim();
					return (line.match(/^\s*/)[0] + prefix + space + key + ': ' + val).trimEnd();
				}

				if (afterComment.indexOf('->') !== -1 || afterComment.indexOf('&&') !== -1) {
					var leadingWs = line.match(/^\s*/)[0];
					var formattedCommentCode = formatLineCode(afterComment);
					return (leadingWs + prefix + (afterComment.startsWith(' ') ? ' ' : '') + formattedCommentCode.trim()).trimEnd();
				}

				return line.trimEnd();
			}

			return formatLineCode(line);
		});

		ed.setValue(formattedLines.join('\n'));

		for (var i = 0; i < ed.lineCount(); i++) {
			ed.indentLine(i, 'smart');
		}
		ed.setCursor(cursor);
	});
}

function bindCodeMirrorToMap(m, onSaveCallback) {
	if (!m || m._cmHooked) return;
	m._cmHooked = true;

	var origRenderContents = m.renderContents;
	m.renderContents = function() {
		return origRenderContents.apply(this, arguments).then(function(mapNode) {
			var target = mapNode || m.root || document.getElementById('cbi-' + m.config) || document;
			target.querySelectorAll('textarea').forEach(function(ta) {
				initCodeMirror(ta, onSaveCallback).then(function(editor) {
					requestAnimationFrame(function() {
						editor.refresh();
					});
				});
			});
			return mapNode;
		});
	};
}

function initCodeMirror(textarea, onSaveCallback) {
	if (textarea.dataset.cmInitialized === 'true' || textarea._editor) {
		return Promise.resolve(textarea._editor);
	}
	textarea.dataset.cmInitialized = 'true';

	return ensureCodeMirror().then(function(CodeMirror) {
		var editor = CodeMirror.fromTextArea(textarea, {
			mode: 'dae',
			indentUnit: 4,
			tabSize: 4,
			styleActiveLine: true,
			lineNumbers: true,
			theme: 'default',
			lineWrapping: true,
			matchBrackets: true,
			autoCloseBrackets: true,
			foldGutter: true,
			gutters: ['CodeMirror-linenumbers', 'CodeMirror-foldgutter']
		});
		textarea._editor = editor;

		var syncTextarea = function() {
			textarea.value = editor.getValue();
			textarea.dispatchEvent(new Event('input', { bubbles: true }));
			textarea.dispatchEvent(new Event('change', { bubbles: true }));
			if (typeof onSaveCallback === 'function') {
				onSaveCallback(textarea.value);
			}
		};

		editor.on('change', syncTextarea);

		var formatBtn = E('button', {
			'type': 'button',
			'class': 'btn cbi-button cm-format-btn',
			'click': function() {
				try {
					formatEditor(editor);
					syncTextarea();
					formatBtn.textContent = '✓ ' + _('Formatted');
					formatBtn.classList.add('cbi-button-positive');
					clearTimeout(formatBtn._resetTimer);
					formatBtn._resetTimer = setTimeout(function() {
						formatBtn.textContent = _('Format Code');
						formatBtn.classList.remove('cbi-button-positive');
					}, 1500);
				} catch (e) {
					console.error('Format failed:', e);
					ui.addNotification(null, E('p', _('Failed to format code:') + ' ' + (e.message || e)), 'error');
				}
			}
		}, _('Format Code'));

		var toolbar = E('div', { 'class': 'honk-editor-toolbar' }, [ formatBtn ]);

		var wrapper = editor.getWrapperElement();
		if (!wrapper.previousElementSibling || !wrapper.previousElementSibling.classList.contains('honk-editor-toolbar')) {
			wrapper.parentNode.insertBefore(toolbar, wrapper);
		}

		if (window.IntersectionObserver) {
			var observer = new IntersectionObserver(function(entries) {
				for (var i = 0; i < entries.length; i++) {
					if (entries[i].isIntersecting) {
						editor.refresh();
					}
				}
			});
			observer.observe(wrapper);
		}

		var mapEl = textarea.closest('.cbi-map');
		if (mapEl) {
			var mapInst = (window.L && window.L.dom) ? window.L.dom.findClassInstance(mapEl) : null;
			if (mapInst && !mapInst._cmHooked) {
				bindCodeMirrorToMap(mapInst, onSaveCallback);
			}
		}

		return editor;
	});
}

function createConfigFileView(filePath, mapTitle, mapDesc, fieldTitle, successMsg) {
	return view.extend({
		render: function() {
			var m = new form.Map('honk', mapTitle, mapDesc);

			var s = m.section(form.NamedSection, '_status');
			s.render = function() {
				return renderStatusHeader();
			};

			s = m.section(form.TypedSection, 'honk');
			s.anonymous = true;
			s.addremove = false;

			var o = s.option(form.TextValue, '_content', fieldTitle);
			o.rows = 25;
			o.wrap = 'off';
			o.load = function(section_id) {
				return readFile(filePath);
			};
			o.write = function(section_id, formvalue) {
				return writeFile(filePath, formvalue);
			};

			bindCodeMirrorToMap(m);
			return m.render();
		},

		handleSaveApply: function(ev, mode) {
			return this.handleSave(ev).then(function() {
				return callHonkReload();
			}).then(function() {
				ui.addNotification(null, E('p', successMsg || _('Configuration applied and service reloaded.')), 'info');
			});
		}
	});
}


// Advanced-only tabs: these paths are hidden when advanced=0.
// This runs on every honk page render and reads live UCI values,
// bypassing LuCI's sessionStorage menu cache entirely.
var ADVANCED_TAB_PATHS = ['/honk/dns', '/honk/node', '/honk/route'];

function applyAdvancedTabVisibility() {
	// Use ubus directly to read the committed UCI value (not the in-memory
	// JS UCI module, which may have pending unsaved changes).
	return L.resolveDefault(
		rpc.declare({
			object: 'uci',
			method: 'get',
			params: ['config', 'section', 'option'],
			expect: { value: '' }
		})('honk', 'config', 'advanced'),
		''
	).then(function(val) {
		var isAdvanced = (val === '1');
		applyTabCss(isAdvanced);
		if (!isAdvanced) {
			var isAdvPage = (window.L && L.env && Array.isArray(L.env.dispatchpath) && ['dns', 'node', 'route'].indexOf(L.env.dispatchpath[3]) !== -1) ||
				ADVANCED_TAB_PATHS.some(function(p) { return window.location.pathname.replace(/\/+$/, '').endsWith(p); });
			if (isAdvPage) {
				window.location.href = L.url('admin/services/honk/global');
			}
		}
	}).catch(function() {
	});
}

function applyTabCss(isAdvanced) {
	// Inject a style element that hides advanced-only tab items and links.
	// This is idempotent and works seamlessly across themes (Bootstrap, Aurora, etc.).
	var styleId = 'honk-adv-tab-style';
	var existing = document.getElementById(styleId);
	if (!existing) {
		existing = document.createElement('style');
		existing.id = styleId;
		document.head.appendChild(existing);
	}
	if (isAdvanced) {
		existing.textContent = '';
	} else {
		existing.textContent = [
			'#tabmenu .tabmenu-item-dns,',
			'#tabmenu .tabmenu-item-node,',
			'#tabmenu .tabmenu-item-route,',
			'#tabmenu a[href$="/honk/dns"],',
			'#tabmenu a[href$="/honk/node"],',
			'#tabmenu a[href$="/honk/route"] { display: none !important; }'
		].join('\n');
	}
}

function renderStatusHeader() {
	var statusEl = E('span', { 'id': 'honk_status', 'style': 'font-weight: 500;' }, [
		E('em', {}, _('Collecting data...'))
	]);

	var reloadBtn = E('button', {
		'type': 'button',
		'class': 'btn cbi-button cbi-button-action',
		'click': function(ev) {
			var btn = ev.target;
			btn.disabled = true;
			btn.innerText = _('Reloading...');
			callHonkReload().then(function() {
				btn.disabled = false;
				btn.innerText = _('Reload Service');
				ui.addNotification(null, E('p', _('HONK service reload triggered successfully.')), 'info');
			}).catch(function(err) {
				btn.disabled = false;
				btn.innerText = _('Reload Service');
				ui.addNotification(null, E('p', _('Failed to reload HONK:') + ' ' + (err.message || err)), 'error');
			});
		}
	}, _('Reload Service'));

	var section = E('fieldset', { 'class': 'cbi-section' }, [
		E('legend', {}, _('Status')),
		E('div', { 'class': 'cbi-value' }, [
			E('label', { 'class': 'cbi-value-title' }, _('Running Status')),
			E('div', { 'class': 'cbi-value-field honk-status-field' }, [
				statusEl,
				reloadBtn
			])
		])
	]);

	function updateStatus(data) {
		var tb = document.getElementById('honk_status');
		if (!tb) return;
		if (data && data.running) {
			var mem = data.memory ? ' (' + _('Memory Usage') + ': ' + data.memory + ')' : '';
			dom.content(tb, [
				E('span', { 'style': 'color: var(--success, #22c55e); font-weight: bold;' }, _('HONK') + ' ' + _('RUNNING')),
				' ',
				E('span', { 'style': 'color: var(--text-muted, #888); font-size: 0.9em;' }, mem)
			]);
		} else {
			dom.content(tb, [
				E('span', { 'style': 'color: var(--danger, #ef4444); font-weight: bold;' }, _('HONK') + ' ' + _('NOT RUNNING'))
			]);
		}
	}

	callHonkStatus().then(updateStatus);

	poll.add(function() {
		return callHonkStatus().then(updateStatus);
	}, 3);

	// Apply tab visibility based on live UCI advanced value.
	// This runs asynchronously after render; the CSS injection is fast enough
	// that tabs flicker is imperceptible (tabs hide before user can click them).
	applyAdvancedTabVisibility();

	return section;
}


return baseclass.extend({
	callHonkStatus: callHonkStatus,
	callHonkReload: callHonkReload,
	callHonkGetLog: callHonkGetLog,
	callHonkClearLog: callHonkClearLog,
	callHonkDashboardInfo: callHonkDashboardInfo,
	callHonkZashboardInfo: callHonkDashboardInfo,
	callHonkDownloadDashboard: callHonkDownloadDashboard,
	callHonkDownloadZashboard: callHonkDownloadDashboard,
	callHonkDownloadStatus: callHonkDownloadStatus,
	callHonkEnableClashApi: callHonkEnableClashApi,
	readFile: readFile,
	writeFile: writeFile,
	ensureCodeMirror: ensureCodeMirror,
	formatEditor: formatEditor,
	initCodeMirror: initCodeMirror,
	bindCodeMirrorToMap: bindCodeMirrorToMap,
	renderStatusHeader: renderStatusHeader,
	createConfigFileView: createConfigFileView
});
