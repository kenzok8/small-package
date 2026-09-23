'use strict';
'require view';
'require ui';
'require poll';
'require honk.common as honk';

return view.extend({
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,

	render: function() {
		var currentInfo = null;
		var downloadPollFn = null;
		var iframeLoaded = false;

		function getTargetHost(configHost) {
			if (!configHost || configHost === '0.0.0.0' || configHost === '::' || configHost === '[::]') {
				return window.location.hostname;
			}
			return configHost;
		}

		function buildZashboardUrl(info, forceFresh) {
			var targetHost = getTargetHost(info.host);
			var port = info.port || '9090';
			var secret = info.secret || '';
			var protocol = 'http';

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
			return protocol + '://' + targetHost + ':' + port + '/ui/?' + uiQuery + '#/setup?' + query;
		}

		function reloadIframe(forceFresh) {
			if (!currentInfo) return;
			var url = buildZashboardUrl(currentInfo, forceFresh);
			iframe.src = 'about:blank';
			setTimeout(function() {
				iframe.src = url;
				iframeLoaded = true;
			}, 60);
		}

		// Create HTML elements
		var style = E('style', {}, [
			'#zash_iframe {',
			'	width: 100%;',
			'	height: calc(100vh - 210px);',
			'	min-height: 650px;',
			'	border: 1px solid var(--hairline, var(--border-color-medium, #ccc));',
			'	border-radius: var(--radius-base, 4px);',
			'	display: block;',
			'}',
			'#zash_iframe.fullscreen {',
			'	position: fixed !important; top: 0 !important; left: 0 !important;',
			'	width: 100vw !important; height: 100vh !important; z-index: 999999 !important;',
			'	border: none !important; border-radius: 0 !important;',
			'}',
			'#zash_iframe_wrap { display: flex; align-items: stretch; }',
			'#zash_scroll_handle { display: none; }',
			'@media (max-width: 768px) {',
			'	#zash_iframe { border-right: none; border-radius: var(--radius-base,4px) 0 0 var(--radius-base,4px); }',
			'	#zash_scroll_handle { display: flex; align-items: center; justify-content: center; width: 14px; flex-shrink: 0; touch-action: none; user-select: none; border: 1px solid var(--hairline,var(--border-color-medium,#ccc)); border-radius: 0 var(--radius-base,4px) var(--radius-base,4px) 0; }',
			'}',
			'.zash-log-box {',
			'	max-height: 150px; overflow-y: auto; font-family: var(--font-mono, monospace);',
			'	font-size: 12px; line-height: 1.4; padding: 8px; margin: 8px 0;',
			'	background: var(--surface-sunken, var(--background-color-low, transparent));',
			'	border: 1px solid var(--hairline, var(--border-color-medium, #ccc));',
			'	border-radius: var(--radius-base, 3px); white-space: pre-wrap; word-break: break-all;',
			'}'
		].join('\n'));

		// State 0: Loading
		var stateLoading = E('div', { 'class': 'cbi-section', 'style': 'text-align: center; padding: 30px;' }, [
			E('p', {}, E('em', {}, _('Checking Zashboard and Clash API configuration...')))
		]);

		// State 1: Unconfigured
		var quickEnableMsg = E('span', { 'style': 'margin-left: 8px;' });
		var btnQuickEnable = E('button', {
			'type': 'button',
			'class': 'cbi-button cbi-button-apply',
			'click': function() {
				btnQuickEnable.disabled = true;
				btnQuickEnable.innerText = _('Enabling and restarting HONK...');
				honk.callHonkEnableClashApi().then(function(resp) {
					btnQuickEnable.disabled = false;
					btnQuickEnable.innerText = _('One-click Enable Default Clash API');
					if (resp && resp.success) {
						quickEnableMsg.innerText = _('Successfully enabled! Restarting service and initializing dashboard...');
						setTimeout(loadInfo, 2500);
					} else {
						ui.addNotification(null, E('p', _('Failed to enable:') + ' ' + (resp ? resp.message : _('Unknown error'))), 'error');
					}
				}).catch(function(err) {
					btnQuickEnable.disabled = false;
					btnQuickEnable.innerText = _('One-click Enable Default Clash API');
					ui.addNotification(null, E('p', _('Failed to enable:') + ' ' + (err.message || err)), 'error');
				});
			}
		}, _('One-click Enable Default Clash API'));

		var stateUnconfigured = E('div', { 'class': 'cbi-section', 'style': 'display: none;' }, [
			E('h3', {}, _('Zashboard / Clash API Unconfigured')),
			E('div', { 'class': 'cbi-section-descr' },
				_('HONK has not enabled Clash API in its configuration file. Zashboard requires external controller port and dashboard UI path.')
			),
			E('div', { 'class': 'alert-message warning', 'style': 'margin: 12px 0;' },
				_('Please add or uncomment experimental.clash_api block in Global Settings, and ensure external_controller and external_ui are configured.')
			),
			E('div', { 'style': 'margin-top: 10px;' }, [
				E('label', { 'class': 'cbi-value-title' }, E('strong', {}, _('Example Configuration (/etc/honk/config.dae):'))),
				E('pre', { 'style': 'padding: 10px; margin-top: 6px; border: 1px solid var(--border-color-medium, #ccc); border-radius: 4px;' },
					"experimental {\n" +
					"    clash_api {\n" +
					"        external_controller: '0.0.0.0:9090'\n" +
					"        external_ui: '/etc/honk/zashboard'\n" +
					"        secret: ''\n" +
					"        default_mode: 'Rule'\n" +
					"    }\n" +
					"}"
				)
			]),
			E('div', { 'style': 'margin-top: 16px; display: flex; gap: 10px; align-items: center;' }, [
				E('a', { 'href': L.url('admin/services/honk/global'), 'class': 'cbi-button' }, _('Configure in Global Settings')),
				btnQuickEnable,
				quickEnableMsg
			])
		]);

		// State 2: Missing UI
		var metaUiDir = E('td', {}, '/etc/honk/zashboard');
		var metaController = E('td', {}, '0.0.0.0:9090');
		var metaSecret = E('td', {}, _('(Not set)'));

		var radioGithub = E('input', { 'type': 'radio', 'class': 'cbi-input-radio', 'name': 'zash_dl_src', 'value': 'https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip', 'checked': 'checked' });
		var radioMirror1 = E('input', { 'type': 'radio', 'class': 'cbi-input-radio', 'name': 'zash_dl_src', 'value': 'https://ghfast.top/https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip' });
		var radioMirror2 = E('input', { 'type': 'radio', 'class': 'cbi-input-radio', 'name': 'zash_dl_src', 'value': 'https://ghproxy.net/https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip' });
		var radioCustom = E('input', { 'type': 'radio', 'class': 'cbi-input-radio', 'name': 'zash_dl_src', 'value': 'custom' });
		var inputCustomUrl = E('input', { 'type': 'text', 'class': 'cbi-input-text', 'style': 'width: 100%;', 'placeholder': 'https://.../dist-no-fonts.zip' });
		var customUrlWrap = E('div', { 'style': 'display: none; margin-top: 8px;' }, [ inputCustomUrl ]);

		var dlLogBox = E('div', { 'class': 'zash-log-box' });
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
						ui.addNotification(null, E('p', _('Please enter a valid download URL')), 'error');
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
					btnStartDownload.innerText = _('Start Download & Install Zashboard');
				});
			}
		}, _('Start Download & Install Zashboard'));

		var stateMissingUi = E('div', { 'class': 'cbi-section', 'style': 'display: none;' }, [
			E('h3', {}, _('Zashboard UI Files Not Found')),
			E('div', { 'class': 'cbi-section-descr' },
				_('Clash API is configured, but dashboard files are missing in the external UI directory. You can download and deploy it directly.')
			),
			E('table', { 'class': 'table', 'style': 'margin: 14px 0;' }, [
				E('tr', {}, [ E('th', { 'style': 'width: 25%;' }, _('Target Directory (external_ui)')), metaUiDir ]),
				E('tr', {}, [ E('th', {}, _('Listen Address & Port')), metaController ]),
				E('tr', {}, [ E('th', {}, _('API Secret')), metaSecret ])
			]),
			E('div', { 'style': 'margin: 16px 0;' }, [
				E('label', { 'style': 'font-weight: bold; display: block; margin-bottom: 8px;' },
					_('Download Source (Optimized fontless dist for OpenWrt, ~1MB):')
				),
				E('div', { 'style': 'display: flex; flex-direction: column; gap: 8px;' }, [
					E('label', { 'style': 'display: flex; align-items: center; gap: 8px; cursor: pointer;' }, [
						radioGithub, E('span', {}, [ E('strong', {}, 'GitHub Release '), '(dist-no-fonts.zip)' ])
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

		var honkPortLabel = E('span', { 'class': 'honk_port_label' }, '9090');
		var honkStopAlert = E('div', { 'class': 'alert-message warning', 'style': 'display: none; margin-bottom: 10px; justify-content: space-between; align-items: center;' }, [
			E('div', {}, [
				E('strong', {}, _('HONK service is currently not running:') + ' '),
				E('span', {}, [ _('Clash API port ('), honkPortLabel, _(') is not listening. Start the service to display data.') ])
			]),
			E('a', { 'href': L.url('admin/services/honk/global'), 'class': 'cbi-button cbi-button-action', 'style': 'white-space: nowrap; margin-left: 10px;' }, _('Start HONK'))
		]);

		var statusServicePill = E('span', { 'class': 'label success' }, _('Running'));
		var statusEndpointPill = E('span', { 'class': 'label notice', 'style': 'font-family: monospace;' });
		var btnExternalOpen = E('a', { 'href': '#', 'target': '_blank', 'class': 'cbi-button cbi-button-action', 'title': _('Open independently in a new tab') }, _('New Tab'));
		var iframe = E('iframe', { 'id': 'zash_iframe', 'src': 'about:blank', 'allow': 'fullscreen; clipboard-read; clipboard-write' });
		var scrollHandle = E('div', { 'id': 'zash_scroll_handle', 'title': _('Drag to scroll page') }, ['\u22ee']);
		var scrollLastY;
		scrollHandle.addEventListener('touchstart', function(e) { scrollLastY = e.touches[0].clientY; }, { passive: true });
		scrollHandle.addEventListener('touchmove', function(e) {
			window.scrollBy(0, scrollLastY - e.touches[0].clientY);
			scrollLastY = e.touches[0].clientY;
			e.preventDefault();
		}, { passive: false });
		var iframeWrap = E('div', { 'id': 'zash_iframe_wrap' }, [iframe, scrollHandle]);

		// Update Modal
		var updateTargetLabel = E('code', {
			'style': 'background: var(--surface-sunken, var(--background-color-low, rgba(128, 128, 128, 0.12))); padding: 2px 6px; border-radius: 4px; font-family: var(--font-mono, monospace); font-weight: bold;'
		}, '/etc/honk/zashboard');

		var modalRadioGithub = E('input', { 'type': 'radio', 'class': 'cbi-input-radio', 'name': 'modal_dl_src', 'value': 'https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip', 'checked': 'checked' });
		var modalRadioMirror = E('input', { 'type': 'radio', 'class': 'cbi-input-radio', 'name': 'modal_dl_src', 'value': 'https://ghfast.top/https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip' });
		var modalLogBox = E('div', { 'class': 'zash-log-box' });
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
			'title': _('Update to latest Zashboard'),
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

				ui.showModal(_('Update Zashboard Dashboard'), [
					E('p', { 'class': 'cbi-section-descr' }, [
						_('The latest fontless version (dist-no-fonts.zip) will be downloaded and deployed to:'),
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
								modalRadioGithub, E('span', {}, [ E('strong', {}, 'GitHub Release '), '(dist-no-fonts.zip)' ])
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

		var stateReady = E('div', { 'style': 'display: none;' }, [
			httpsAlert,
			honkStopAlert,
			E('div', { 'style': 'display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; flex-wrap: wrap; gap: 8px;' }, [
				E('div', { 'style': 'display: flex; align-items: center; gap: 8px;' }, [
					E('strong', { 'style': 'font-size: 15px;' }, 'Zashboard'),
					statusServicePill,
					statusEndpointPill
				]),
				E('div', { 'style': 'display: flex; align-items: center; gap: 6px;' }, [
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

			honk.callHonkDownloadZashboard(url).then(function(resp) {
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
			honk.callHonkZashboardInfo().then(function(data) {
				if (!data || !data.configured) {
					showState('unconfigured');
					return;
				}
				currentInfo = data;

				if (!data.has_ui) {
					metaUiDir.innerText = data.external_ui || '/etc/honk/zashboard';
					metaController.innerText = data.external_controller || '0.0.0.0:9090';
					metaSecret.innerText = data.secret ? _('Configured (Hidden)') : _('Not configured (Empty)');
					showState('missing_ui');
					return;
				}

				// Ready state
				showState('ready');
				var targetHost = getTargetHost(data.host);
				var port = data.port || '9090';
				var fullUrl = buildZashboardUrl(data);

				updateHonkRunningState(data.running, port);

				statusEndpointPill.innerText = targetHost + ':' + port;
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

				updateTargetLabel.innerText = data.external_ui || '/etc/honk/zashboard';
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

		return E('div', { 'class': 'zash-wrap' }, [
			style,
			stateLoading,
			stateUnconfigured,
			stateMissingUi,
			stateReady
		]);
	}
});
