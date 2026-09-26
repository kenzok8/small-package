'use strict';
'require view';
'require ui';
'require poll';
'require uci';
'require honk.common as honk';

return view.extend({
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,

	load: function() {
		return Promise.all([
			uci.load('honk')
		]);
	},

	render: function() {
		if (honk && honk.applyAdvancedTabVisibility) {
			honk.applyAdvancedTabVisibility();
		}
		var sec = (uci.sections('honk', 'honk')[0] || {});
		var sid = sec['.name'] || 'config';
		var dashType = uci.get('honk', sid, 'dashboard') || 'doona';

		var DASHBOARD_PROFILES = {
			zashboard: {
				name: 'Zashboard',
				label: 'Zashboard',
				apiName: 'Clash API',
				defaultPort: '9090',
				defaultDir: '/etc/honk/zashboard',
				exampleConfig: "experimental {\n    clash_api {\n        external_controller: '0.0.0.0:9090'\n        external_ui: '/etc/honk/zashboard'\n        secret: ''\n        default_mode: 'Rule'\n    }\n}",
				buildUrl: function(info, targetHost, port, secret, protocol, forceFresh) {
					var hostPart = (targetHost.indexOf(':') !== -1 && targetHost.charAt(0) !== '[') ? '[' + targetHost + ']' : targetHost;
					var query = 'hostname=' + encodeURIComponent(targetHost) +
						'&port=' + encodeURIComponent(port) +
						'&protocol=' + encodeURIComponent(protocol);
					if (secret) {
						query += '&secret=' + encodeURIComponent(secret);
					}
					var uiQuery = query;
					if (forceFresh) {
						uiQuery += '&_t=' + Date.now();
					}
					return protocol + '://' + hostPart + ':' + port + '/ui/?' + uiQuery + '#/setup?' + query;
				},
				githubRelease: 'https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip',
				ghfastMirror: 'https://ghfast.top/https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip',
				ghproxyMirror: 'https://ghproxy.net/https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip',
				pkgName: 'dist-no-fonts.zip'
			},
			doona: {
				name: 'Doona',
				label: _('Doona'),
				apiName: 'Native API',
				defaultPort: '9527',
				defaultDir: '/etc/honk/dashboard',
				exampleConfig: "experimental {\n    native_api {\n        enabled: true\n        listen: '0.0.0.0:9527'\n        secret: 'honk'\n        ui: '/etc/honk/dashboard'\n    }\n}",
				buildUrl: function(info, targetHost, port, secret, protocol, forceFresh) {
					var hostPart = (targetHost.indexOf(':') !== -1 && targetHost.charAt(0) !== '[') ? '[' + targetHost + ']' : targetHost;
					var url = protocol + '://' + hostPart + ':' + port + '/ui/';
					if (secret) {
						url += '?token=' + encodeURIComponent(secret);
					}
					return url;
				},
				githubRelease: 'https://github.com/Zakkaus/doona/releases/download/v0.1.0-beta.3/doona-v0.1.0-beta.3.tar.gz',
				ghfastMirror: 'https://ghfast.top/https://github.com/Zakkaus/doona/releases/download/v0.1.0-beta.3/doona-v0.1.0-beta.3.tar.gz',
				ghproxyMirror: 'https://ghproxy.net/https://github.com/Zakkaus/doona/releases/download/v0.1.0-beta.3/doona-v0.1.0-beta.3.tar.gz',
				pkgName: 'doona-*.tar.gz'
			}
		};

		var profile = DASHBOARD_PROFILES[dashType] || DASHBOARD_PROFILES.zashboard;
		var currentInfo = null;
		var downloadPollFn = null;
		var iframeLoaded = false;

		function createDashboardSelect() {
			var sel = E('select', { 
				'class': 'cbi-input-select',
				'style': 'margin-right: 10px;',
				'change': function(ev) {
					var newType = ev.target.value;
					uci.set('honk', sid, 'dashboard', newType);
					uci.save().then(function() {
						return uci.apply();
					}).then(function() {
						return honk.callHonkSwitchDashboardApi(newType);
					}).then(function() {
						window.location.reload();
					});
				}
			});
			Object.keys(DASHBOARD_PROFILES).forEach(function(k) {
				var opt = E('option', { 'value': k }, DASHBOARD_PROFILES[k].label || DASHBOARD_PROFILES[k].name);
				if (k === dashType) opt.selected = true;
				sel.appendChild(opt);
			});
			return sel;
		}

		function getTargetHost(configHost) {
			if (!configHost || configHost === '0.0.0.0' || configHost === '::' || configHost === '[::]') {
				return window.location.hostname;
			}
			return configHost;
		}

		function buildDashboardUrl(info, forceFresh) {
			var targetHost = getTargetHost(info.host);
			var port = info.port || '9090';
			var secret = info.secret || '';
			var protocol = 'http';
			return profile.buildUrl(info, targetHost, port, secret, protocol, forceFresh);
		}

		function reloadIframe(forceFresh) {
			if (!currentInfo) return;
			var url = buildDashboardUrl(currentInfo, forceFresh);
			iframe.src = 'about:blank';
			setTimeout(function() {
				iframe.src = url;
				iframeLoaded = true;
			}, 60);
		}

		// Create HTML elements
		var style = E('style', {}, [
			'#dash_iframe {',
			'	width: 100%;',
			'	height: calc(100vh - 210px);',
			'	min-height: 650px;',
			'	border: 1px solid var(--hairline, var(--border-color-medium, #ccc));',
			'	border-radius: var(--radius-base, 4px);',
			'	display: block;',
			'}',
			'#dash_iframe.fullscreen {',
			'	position: fixed !important; top: 0 !important; left: 0 !important;',
			'	width: 100vw !important; height: 100vh !important; z-index: 999999 !important;',
			'	border: none !important; border-radius: 0 !important;',
			'}',
			'#dash_iframe_wrap { display: flex; align-items: stretch; }',
			'#dash_scroll_handle { display: none; }',
			'.dash-toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; flex-wrap: wrap; gap: 8px; }',
			'.dash-toolbar-info { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }',
			'.dash-toolbar-actions { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }',
			'.dash-toolbar-actions > * { white-space: nowrap !important; flex-shrink: 0; }',
			'@media (max-width: 768px) {',
			'	#dash_iframe { border-right: none; border-radius: var(--radius-base,4px) 0 0 var(--radius-base,4px); }',
			'	#dash_scroll_handle { display: flex; align-items: center; justify-content: center; width: 14px; flex-shrink: 0; touch-action: none; user-select: none; border: 1px solid var(--hairline,var(--border-color-medium,#ccc)); border-radius: 0 var(--radius-base,4px) var(--radius-base,4px) 0; }',
			'	.dash-toolbar-actions { width: 100%; display: flex; flex-wrap: wrap; gap: 6px; }',
			'	.dash-toolbar-actions select { flex: 1 1 auto; min-width: 90px; margin-right: 0 !important; }',
			'	.dash-toolbar-actions .btn, .dash-toolbar-actions .cbi-button { padding: 4px 8px !important; font-size: 12px !important; white-space: nowrap !important; flex: 0 0 auto; }',
			'}',
			'.dash-log-box {',
			'	max-height: 150px; overflow-y: auto; font-family: var(--font-mono, monospace);',
			'	font-size: 12px; line-height: 1.4; padding: 8px; margin: 8px 0;',
			'	background: var(--surface-sunken, var(--background-color-low, transparent));',
			'	border: 1px solid var(--hairline, var(--border-color-medium, #ccc));',
			'	border-radius: var(--radius-base, 3px); white-space: pre-wrap; word-break: break-all;',
			'}'
		].join('\n'));

		// State 0: Loading
		var stateLoading = E('div', { 'class': 'cbi-section', 'style': 'text-align: center; padding: 30px;' }, [
			E('p', {}, E('em', {}, _('Checking Dashboard and API configuration...')))
		]);

		// State 1: Unconfigured
		var quickEnableMsg = E('span', { 'style': 'margin-left: 8px;' });
		var enableBtnText = (dashType === 'doona') ? _('One-click Enable Default Native API') : _('One-click Enable Default Clash API');
		var btnQuickEnable = E('button', {
			'type': 'button',
			'class': 'cbi-button cbi-button-apply',
			'click': function() {
				btnQuickEnable.disabled = true;
				btnQuickEnable.innerText = (dashType === 'doona') ? _('Enabling Native API and restarting HONK...') : _('Enabling Clash API and restarting HONK...');
				honk.callHonkSwitchDashboardApi(dashType).then(function(resp) {
					btnQuickEnable.disabled = false;
					btnQuickEnable.innerText = enableBtnText;
					if (resp && resp.success) {
						quickEnableMsg.innerText = _('Successfully enabled! Restarting service and initializing dashboard...');
						setTimeout(loadInfo, 2500);
					} else {
						honk.showNotification(null, E('p', _('Failed to enable:') + ' ' + (resp ? resp.message : _('Unknown error'))), 'error');
					}
				}).catch(function(err) {
					btnQuickEnable.disabled = false;
					btnQuickEnable.innerText = enableBtnText;
					honk.showNotification(null, E('p', _('Failed to enable:') + ' ' + (err.message || err)), 'error');
				});
			}
		}, enableBtnText);

		var unconfTitle = (dashType === 'doona') ? _('Dashboard / Native API Unconfigured') : _('Dashboard / Clash API Unconfigured');
		var unconfDescr = (dashType === 'doona') 
			? _('HONK has not enabled Native API in its configuration file. Doona requires native API listener and dashboard UI path.')
			: _('HONK has not enabled Clash API in its configuration file. Dashboard requires external controller port and dashboard UI path.');
		var unconfWarn = (dashType === 'doona')
			? _('Please add or uncomment experimental.native_api block in Global Settings, and ensure listen and ui are configured.')
			: _('Please add or uncomment experimental.clash_api block in Global Settings, and ensure external_controller and external_ui are configured.');

		var stateUnconfigured = E('div', { 'class': 'cbi-section', 'style': 'display: none;' }, [
			E('h3', {}, unconfTitle),
			E('div', { 'class': 'cbi-section-descr' }, unconfDescr),
			E('div', { 'class': 'alert-message warning', 'style': 'margin: 12px 0;' }, unconfWarn),
			E('div', { 'style': 'margin-top: 10px;' }, [
				E('label', { 'class': 'cbi-value-title' }, E('strong', {}, _('Example Configuration (/etc/honk/config.dae):'))),
				E('pre', { 'style': 'padding: 10px; margin-top: 6px; border: 1px solid var(--border-color-medium, #ccc); border-radius: 4px;' },
					profile.exampleConfig || ''
				)
			]),
			E('div', { 'style': 'margin-top: 16px; display: flex; gap: 10px; align-items: center;' }, [
				E('a', { 'href': L.url('admin/services/honk/global'), 'class': 'cbi-button' }, _('Configure in Global Settings')),
				btnQuickEnable,
				quickEnableMsg
			])
		]);

		// State 2: Missing UI
		var metaUiDir = E('td', {}, profile.defaultDir);
		var metaController = E('td', {}, '0.0.0.0:9090');
		var metaSecret = E('td', {}, _('(Not set)'));

		var radioGithub = E('input', { 'type': 'radio', 'class': 'cbi-input-radio', 'name': 'dash_dl_src', 'value': profile.githubRelease, 'checked': 'checked' });
		var radioMirror1 = E('input', { 'type': 'radio', 'class': 'cbi-input-radio', 'name': 'dash_dl_src', 'value': profile.ghfastMirror });
		var radioMirror2 = E('input', { 'type': 'radio', 'class': 'cbi-input-radio', 'name': 'dash_dl_src', 'value': profile.ghproxyMirror });
		var radioCustom = E('input', { 'type': 'radio', 'class': 'cbi-input-radio', 'name': 'dash_dl_src', 'value': 'custom' });
		var inputCustomUrl = E('input', { 'type': 'text', 'class': 'cbi-input-text', 'style': 'width: 100%;', 'placeholder': 'https://.../' + profile.pkgName });
		var customUrlWrap = E('div', { 'style': 'display: none; margin-top: 8px;' }, [ inputCustomUrl ]);

		var dlLogBox = E('div', { 'class': 'dash-log-box' });
		var dlProgressWrap = E('div', { 'style': 'display: none; margin: 12px 0;' }, [
			E('div', { 'style': 'font-weight: bold; margin-bottom: 4px;' }, _('Preparing download...')),
			dlLogBox
		]);

		function updateCustomVisibility() {
			customUrlWrap.style.display = radioCustom.checked ? 'block' : 'none';
		}
		radioGithub.addEventListener('change', updateCustomVisibility);
		radioMirror1.addEventListener('change', updateCustomVisibility);
		radioMirror2.addEventListener('change', updateCustomVisibility);
		radioCustom.addEventListener('change', updateCustomVisibility);

		var btnStartDownload = E('button', {
			'type': 'button',
			'class': 'cbi-button cbi-button-apply',
			'click': function() {
				var url = '';
				if (radioCustom.checked) {
					url = (inputCustomUrl.value || '').trim();
					if (!url) {
						honk.showNotification(null, E('p', _('Please enter a valid download URL')), 'error');
						return;
					}
				} else if (radioMirror1.checked) {
					url = radioMirror1.value;
				} else if (radioMirror2.checked) {
					url = radioMirror2.value;
				} else {
					url = radioGithub.value;
				}

				btnStartDownload.disabled = true;
				btnStartDownload.innerText = _('Processing...');
				triggerDownload(url, dlLogBox, dlProgressWrap, function() {
					btnStartDownload.disabled = false;
					btnStartDownload.innerText = _('Start Download & Install Dashboard');
				});
			}
		}, _('Start Download & Install Dashboard'));

		var selectDashboardMissing = createDashboardSelect();
		var stateMissingUi = E('div', { 'class': 'cbi-section', 'style': 'display: none;' }, [
			E('h3', {}, _('%s UI Files Not Found').format(profile.name)),
			E('div', { 'class': 'cbi-section-descr' },
				(dashType === 'doona') 
					? _('Native API is configured, but dashboard files are missing in the UI directory. You can download and deploy it directly.')
					: _('Clash API is configured, but dashboard files are missing in the external UI directory. You can download and deploy it directly.')
			),
			E('table', { 'class': 'table', 'style': 'margin: 14px 0;' }, [
				E('tr', {}, [ E('th', { 'style': 'width: 25%;' }, _('Target Dashboard')), selectDashboardMissing ]),
				E('tr', {}, [ E('th', {}, (dashType === 'doona') ? _('Target Directory (ui)') : _('Target Directory (external_ui)')), metaUiDir ]),
				E('tr', {}, [ E('th', {}, _('Listen Address & Port')), metaController ]),
				E('tr', {}, [ E('th', {}, _('API Secret')), metaSecret ])
			]),
			E('div', { 'style': 'margin: 16px 0;' }, [
				E('label', { 'style': 'font-weight: bold; display: block; margin-bottom: 8px;' },
					_('Download Source:')
				),
				E('div', { 'style': 'display: flex; flex-direction: column; gap: 8px;' }, [
					E('label', { 'style': 'display: flex; align-items: center; gap: 8px; cursor: pointer;' }, [
						radioGithub, E('span', {}, [ E('strong', {}, 'GitHub Release '), '(' + profile.pkgName + ')' ])
					]),
					E('label', { 'style': 'display: flex; align-items: center; gap: 8px; cursor: pointer;' }, [
						radioMirror1, E('span', {}, [ E('strong', {}, _('Mirror 1') + ' '), '(ghfast.top)' ])
					]),
					E('label', { 'style': 'display: flex; align-items: center; gap: 8px; cursor: pointer;' }, [
						radioMirror2, E('span', {}, [ E('strong', {}, _('Mirror 2') + ' '), '(ghproxy.net)' ])
					]),
					E('label', { 'style': 'display: flex; align-items: center; gap: 8px; cursor: pointer;' }, [
						radioCustom, E('span', {}, E('strong', {}, _('Custom URL')))
					])
				]),
				customUrlWrap
			]),
			dlProgressWrap,
			E('div', { 'style': 'margin-top: 16px;' }, [ btnStartDownload ])
		]);

		// State 3: Ready
		var httpsAlert = E('div', { 'class': 'alert-message warning', 'style': 'display: none; margin-bottom: 10px; justify-content: space-between; align-items: center;' }, [
			E('div', {}, [
				E('strong', {}, _('HTTPS access detected:') + ' '),
				E('span', {}, _('Modern browsers may block HTTP iframe resources under HTTPS. If the dashboard fails to display, open it in a new tab.'))
			]),
			E('a', { 'href': '#', 'target': '_blank', 'class': 'cbi-button cbi-button-action', 'style': 'white-space: nowrap; margin-left: 10px;' }, _('Open in New Tab'))
		]);

		var honkPortLabel = E('span', { 'class': 'honk_port_label' }, profile.defaultPort || '9090');
		var honkStopAlert = E('div', { 'class': 'alert-message warning', 'style': 'display: none; margin-bottom: 10px; justify-content: space-between; align-items: center;' }, [
			E('div', {}, [
				E('strong', {}, _('HONK service is currently not running:') + ' '),
				E('span', {}, [ _('Dashboard API port ('), honkPortLabel, _(') is not listening. Start the service to display data.') ])
			]),
			E('a', { 'href': L.url('admin/services/honk/global'), 'class': 'cbi-button cbi-button-action', 'style': 'white-space: nowrap; margin-left: 10px;' }, _('Start HONK'))
		]);

		var statusServicePill = E('span', { 'class': 'label success' }, _('Running'));
		var statusEndpointPill = E('span', { 'class': 'label notice', 'style': 'font-family: monospace; text-transform: none !important;' });
		var tokenText = E('span', {
			'style': 'user-select: all; -webkit-user-select: all; font-weight: bold; text-transform: none !important;',
			'title': _('Click or drag to select Token')
		});
		var tokenPill = E('span', {
			'class': 'label info',
			'style': 'font-family: monospace; display: none; padding: 2px 6px; text-transform: none !important;'
		}, [ _('Token: '), tokenText ]);
		var btnExternalOpen = E('a', { 'href': '#', 'target': '_blank', 'class': 'cbi-button cbi-button-action', 'title': _('Open independently in a new tab') }, _('New Tab'));
		var iframe = E('iframe', { 'id': 'dash_iframe', 'src': 'about:blank', 'allow': 'fullscreen; clipboard-read; clipboard-write' });

		var scrollHandle = E('div', { 'id': 'dash_scroll_handle', 'title': _('Drag to scroll page') }, ['\u22ee']);
		var scrollLastY;
		scrollHandle.addEventListener('touchstart', function(e) { scrollLastY = e.touches[0].clientY; }, { passive: true });
		scrollHandle.addEventListener('touchmove', function(e) {
			window.scrollBy(0, scrollLastY - e.touches[0].clientY);
			scrollLastY = e.touches[0].clientY;
			e.preventDefault();
		}, { passive: false });
		var iframeWrap = E('div', { 'id': 'dash_iframe_wrap' }, [iframe, scrollHandle]);

		// Update Modal
		var updateTargetLabel = E('code', {
			'style': 'background: var(--surface-sunken, var(--background-color-low, rgba(128, 128, 128, 0.12))); padding: 2px 6px; border-radius: 4px; font-family: var(--font-mono, monospace); font-weight: bold;'
		}, profile.defaultDir);

		var modalRadioGithub = E('input', { 'type': 'radio', 'class': 'cbi-input-radio', 'name': 'modal_dl_src', 'value': profile.githubRelease, 'checked': 'checked' });
		var modalRadioMirror = E('input', { 'type': 'radio', 'class': 'cbi-input-radio', 'name': 'modal_dl_src', 'value': profile.ghfastMirror });
		var modalLogBox = E('div', { 'class': 'dash-log-box' });
		var modalStatusAlert = E('div', { 'class': 'alert-message', 'style': 'display: none; margin-bottom: 8px;' });
		var modalProgressWrap = E('div', { 'style': 'display: none; margin-top: 12px;' }, [ modalStatusAlert, modalLogBox ]);

		var btnCancelModal = E('button', {
			'type': 'button',
			'class': 'btn cbi-button',
			'click': ui.hideModal
		}, _('Cancel'));

		var btnConfirmUpdate = E('button', { 'type': 'button', 'class': 'btn cbi-button cbi-button-action' }, _('Start Update'));

		function startModalUpdate() {
			var url = modalRadioMirror.checked ? modalRadioMirror.value : modalRadioGithub.value;
			btnConfirmUpdate.disabled = true;
			btnConfirmUpdate.innerText = _('Processing...');
			btnCancelModal.disabled = true;
			modalStatusAlert.style.display = 'none';

			triggerDownload(url, modalLogBox, modalProgressWrap, function(success) {
				if (success) {
					modalStatusAlert.className = 'alert-message success';
					modalStatusAlert.innerText = _('Installation completed successfully!');
					modalStatusAlert.style.display = 'block';
					btnConfirmUpdate.disabled = false;
					btnConfirmUpdate.className = 'btn cbi-button cbi-button-apply';
					btnConfirmUpdate.innerText = _('Close');
					btnConfirmUpdate.onclick = function() { ui.hideModal(); };
					btnCancelModal.style.display = 'none';
				} else {
					modalStatusAlert.className = 'alert-message warning';
					modalStatusAlert.innerText = _('Installation failed. Please check logs.');
					modalStatusAlert.style.display = 'block';
					btnConfirmUpdate.disabled = false;
					btnConfirmUpdate.className = 'btn cbi-button cbi-button-action';
					btnConfirmUpdate.innerText = _('Start Update');
					btnConfirmUpdate.onclick = startModalUpdate;
					btnCancelModal.style.display = '';
					btnCancelModal.disabled = false;
				}
			});
		}

		btnConfirmUpdate.onclick = startModalUpdate;

		var btnUpdateDashboard = E('button', {
			'type': 'button',
			'class': 'btn cbi-button',
			'title': _('Update to latest') + ' ' + profile.name,
			'click': function() {
				modalProgressWrap.style.display = 'none';
				modalStatusAlert.style.display = 'none';
				modalLogBox.innerText = '';
				btnConfirmUpdate.disabled = false;
				btnConfirmUpdate.className = 'btn cbi-button cbi-button-action';
				btnConfirmUpdate.innerText = _('Start Update');
				btnConfirmUpdate.onclick = startModalUpdate;
				btnCancelModal.style.display = '';
				btnCancelModal.disabled = false;

				ui.showModal(_('Update Dashboard') + ' - ' + profile.name, [
					E('p', { 'class': 'cbi-section-descr' }, [
						_('The latest version (%s) will be downloaded and deployed to:').format(profile.pkgName),
						' ',
						updateTargetLabel
					]),
					E('div', { 'class': 'alert-message info', 'style': 'margin: 8px 0;' },
						_('Tip: If the dashboard still shows the old version, press Ctrl+F5 or open in a new tab to bypass PWA cache.')
					),
					E('div', { 'class': 'cbi-value' }, [
						E('label', { 'class': 'cbi-value-title' }, _('Select download source')),
						E('div', { 'class': 'cbi-value-field', 'style': 'display: flex; flex-direction: column; gap: 8px;' }, [
							E('label', { 'style': 'display: flex; align-items: center; gap: 8px; cursor: pointer;' }, [
								modalRadioGithub, E('span', {}, [ E('strong', {}, 'GitHub Release '), '(' + profile.pkgName + ')' ])
							]),
							E('label', { 'style': 'display: flex; align-items: center; gap: 8px; cursor: pointer;' }, [
								modalRadioMirror, E('span', {}, [ E('strong', {}, _('Mirror') + ' '), '(ghfast.top)' ])
							])
						])
					]),
					modalProgressWrap,
					E('div', { 'class': 'right', 'style': 'margin-top: 16px; display: flex; justify-content: flex-end; gap: 10px;' }, [
						btnCancelModal,
						btnConfirmUpdate
					])
				]);
			}
		}, _('Update Dashboard'));

		var btnRefreshIframe = E('button', {
			'type': 'button',
			'class': 'btn cbi-button',
			'title': _('Refresh dashboard content'),
			'click': function() {
				if (currentInfo) {
					reloadIframe(true);
				}
			}
		}, _('Refresh'));

		var btnToggleFullscreen = E('button', {
			'type': 'button',
			'class': 'btn cbi-button',
			'title': _('Toggle fullscreen display'),
			'click': function() {
				if (!document.fullscreenElement) {
					if (iframe.requestFullscreen) {
						iframe.requestFullscreen();
					} else if (iframe.webkitRequestFullscreen) {
						iframe.webkitRequestFullscreen();
					}
				} else {
					if (document.exitFullscreen) {
						document.exitFullscreen();
					}
				}
			}
		}, _('Fullscreen'));

		// Add dashboard switcher in header
		var selectDashboard = createDashboardSelect();

		var stateReady = E('div', { 'style': 'display: none;' }, [
			httpsAlert,
			honkStopAlert,
			E('div', { 'class': 'dash-toolbar' }, [
				E('div', { 'class': 'dash-toolbar-info' }, [
					E('strong', { 'style': 'font-size: 15px;' }, profile.name),
					statusServicePill,
					statusEndpointPill,
					tokenPill
				]),
				E('div', { 'class': 'dash-toolbar-actions' }, [
					selectDashboard,
					btnUpdateDashboard,
					btnRefreshIframe,
					btnToggleFullscreen,
					btnExternalOpen
				])
			]),
			iframeWrap
		]);

		function showState(name) {
			stateLoading.style.display = (name === 'loading') ? 'block' : 'none';
			stateUnconfigured.style.display = (name === 'unconfigured') ? 'block' : 'none';
			stateMissingUi.style.display = (name === 'missing_ui') ? 'block' : 'none';
			stateReady.style.display = (name === 'ready') ? 'block' : 'none';
		}

		function triggerDownload(url, logBox, progressWrap, onFinish) {
			progressWrap.style.display = 'block';
			logBox.innerText = _('Initializing download task...\n');

			honk.callHonkDownloadDashboard(url, dashType).then(function(resp) {
				if (!resp || !resp.success) {
					logBox.innerText += _('Failed to trigger download:') + ' ' + (resp ? resp.message : _('Unknown error')) + '\n';
					if (onFinish) onFinish(false);
					return;
				}

				if (downloadPollFn) {
					poll.remove(downloadPollFn);
					downloadPollFn = null;
				}

				downloadPollFn = function() {
					return honk.callHonkDownloadStatus().then(function(sResp) {
						if (!sResp) return;
						if (sResp.log) {
							logBox.innerText = sResp.log;
							logBox.scrollTop = logBox.scrollHeight;
						}
						if (sResp.status === 'SUCCESS') {
							poll.remove(downloadPollFn);
							downloadPollFn = null;
							logBox.scrollTop = logBox.scrollHeight;
							if (onFinish) onFinish(true);
							loadInfo(true);
						} else if (sResp.status === 'FAILED') {
							poll.remove(downloadPollFn);
							downloadPollFn = null;
							logBox.scrollTop = logBox.scrollHeight;
							if (onFinish) onFinish(false);
						}
					});
				};

				poll.add(downloadPollFn, 1);
			}).catch(function(err) {
				logBox.innerText += _('Download error:') + ' ' + (err.message || err) + '\n';
				if (onFinish) onFinish(false);
			});
		}

		function updateHonkRunningState(running, port) {
			if (running) {
				statusServicePill.className = 'label success';
				statusServicePill.innerText = _('Running');
				honkStopAlert.style.display = 'none';
			} else {
				statusServicePill.className = 'label warning';
				statusServicePill.innerText = _('Not Running');
				honkStopAlert.style.display = 'flex';
				honkPortLabel.innerText = port || '9090';
			}
		}

		function loadInfo(forceReload) {
			honk.callHonkDashboardInfo(dashType).then(function(data) {
				if (!data || !data.configured) {
					showState('unconfigured');
					return;
				}
				currentInfo = data;

				if (!data.has_ui) {
					metaUiDir.innerText = data.external_ui || profile.defaultDir;
					metaController.innerText = data.external_controller || (dashType === 'doona' ? '0.0.0.0:9527' : '0.0.0.0:9090');
					metaSecret.innerText = data.secret ? data.secret : _('Not configured (Empty)');
					showState('missing_ui');
					return;
				}

				// Ready state
				showState('ready');
				var targetHost = getTargetHost(data.host);
				var port = data.port || profile.defaultPort || '9090';
				var fullUrl = buildDashboardUrl(data);

				updateHonkRunningState(data.running, port);

				statusEndpointPill.innerText = targetHost + ':' + port;
				if (dashType === 'doona' && data.secret) {
					tokenText.innerText = data.secret;
					tokenPill.style.display = 'inline-block';
				} else {
					tokenPill.style.display = 'none';
				}
				btnExternalOpen.href = fullUrl;

				var httpsBtn = httpsAlert.querySelector('a');
				if (httpsBtn) httpsBtn.href = fullUrl;

				if (window.location.protocol === 'https:') {
					httpsAlert.style.display = 'flex';
				} else {
					httpsAlert.style.display = 'none';
				}

				if (forceReload) {
					reloadIframe(true);
				} else if (!iframeLoaded || iframe.src !== fullUrl) {
					iframe.src = fullUrl;
					iframeLoaded = true;
				}

				updateTargetLabel.innerText = data.external_ui || profile.defaultDir;
			}).catch(function() {
				showState('unconfigured');
			});
		}

		loadInfo();

		// Background status check every 5 seconds for service running pill
		poll.add(function() {
			if (currentInfo && currentInfo.configured && currentInfo.has_ui) {
				return honk.callHonkStatus().then(function(res) {
					var isRunning = (res && res.running);
					updateHonkRunningState(isRunning, currentInfo.port);
				});
			}
		}, 5);

		return E('div', { 'class': 'dash-wrap' }, [
			style,
			stateLoading,
			stateUnconfigured,
			stateMissingUi,
			stateReady
		]);
	}
});
