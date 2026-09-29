'use strict';
'require view';
'require ui';
'require tower';

const css = '\
.tower-card{border:1px solid rgba(128,128,128,.2);border-radius:12px;padding:17px 18px;margin-bottom:14px;background:rgba(128,128,128,.055)}\
.tower-export-page .tower-card-title{display:block;width:auto;background:transparent!important;border:0!important;box-shadow:none!important;color:inherit!important;font-size:16px;font-weight:620;opacity:.9;margin:0 0 12px;padding:0!important;letter-spacing:0;text-transform:none}\
.tower-client-section+.tower-client-section{margin-top:18px;padding-top:16px;border-top:1px solid rgba(128,128,128,.16)}\
.tower-client-heading{font-size:12px;font-weight:650;opacity:.65;margin:0 0 9px}\
.tower-client-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(142px,1fr));gap:8px}\
.tower-client-card{display:flex;align-items:center;gap:9px;min-width:0;padding:9px 10px;border:1px solid rgba(128,128,128,.26);border-radius:9px;cursor:pointer;background:transparent;font-size:12.5px;user-select:none}\
.tower-client-card:hover{border-color:rgba(74,160,101,.65)}\
.tower-client-card input{display:none}\
.tower-client-card:has(input:checked){border-color:#4aa065;background:rgba(74,160,101,.14);font-weight:600;box-shadow:0 0 0 1px rgba(74,160,101,.25)}\
.tower-client-icon{width:30px;height:30px;flex:none;object-fit:contain;border-radius:7px}\
.tower-client-fallback{display:flex;align-items:center;justify-content:center;width:30px;height:30px;flex:none;border-radius:7px;background:rgba(84,114,228,.16);color:#5e72e4;font-size:11px;font-weight:700}\
.tower-client-text{display:flex;flex-direction:column;min-width:0;line-height:1.25}\
.tower-client-name{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\
.tower-client-detail{font-size:10.5px;opacity:.56;margin-top:3px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\
.tower-target-note{margin:11px 0 0;font-size:12px;opacity:.7}\
.tower-toolbar{display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin-bottom:10px}\
.tower-filter{margin-left:auto;min-width:200px;box-sizing:border-box;border:1px solid rgba(128,128,128,.28);border-radius:6px;background:transparent!important;color:inherit!important;font-size:12px;padding:7px 9px}\
.tower-filter::placeholder,.tower-preview::placeholder{color:inherit;opacity:.48}\
.tower-summary{display:flex;gap:14px;flex-wrap:wrap;margin-bottom:8px;font-size:12px;opacity:.8}\
.tower-results{border:1px solid rgba(128,128,128,.18);border-radius:8px;max-height:340px;overflow:auto}\
.tower-result{display:grid;grid-template-columns:20px minmax(100px,1fr) 88px;gap:8px;align-items:center;padding:7px 10px;border-bottom:1px solid rgba(128,128,128,.12);font-size:12.5px}\
.tower-result:last-child{border-bottom:0}\
.tower-result input{appearance:checkbox !important;-webkit-appearance:checkbox !important;accent-color:#4aa065;width:15px;height:15px;margin:0}\
.tower-name,.tower-server{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\
.tower-proto{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:11px;opacity:.65;text-transform:uppercase;justify-self:end}\
.tower-empty{display:flex;align-items:center;justify-content:center;min-height:64px;padding:16px;text-align:center;font-size:13px;opacity:.65}\
.tower-preview{width:100%;height:300px;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:12px;line-height:1.5;box-sizing:border-box;border:1px solid rgba(128,128,128,.18);border-radius:8px;background:transparent!important;color:inherit!important;padding:10px}\
.tower-share{display:none}\
.tower-share.tower-visible{display:block}\
.tower-share-head{display:flex;align-items:center;gap:8px;margin-bottom:8px}\
.tower-share-head .tower-card-title{margin:0}\
.tower-share-url{width:100%;box-sizing:border-box;padding:9px 10px;border:1px solid rgba(128,128,128,.28);border-radius:7px;background:transparent!important;color:inherit!important;font:12px ui-monospace,SFMono-Regular,Menlo,monospace}\
.tower-share-help{font-size:12px;opacity:.7;margin:0 0 10px}\
.tower-link-list{border:1px solid rgba(128,128,128,.18);border-radius:8px;max-height:300px;overflow:auto}\
.tower-link-row{display:grid;grid-template-columns:74px minmax(80px,1fr) auto;gap:8px;align-items:center;padding:6px 10px;border-bottom:1px solid rgba(128,128,128,.12);font-size:12px}\
.tower-link-row:last-child{border-bottom:0}\
.tower-link-row .tower-name{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}\
.tower-btn-row{display:flex;gap:6px;align-items:center}\
.tower-btn{font-size:11.5px;padding:4px 10px}\
.tower-modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,.55);display:flex;align-items:center;justify-content:center;z-index:1000;padding:20px}\
.tower-modal{background:var(--cbi-background,#fff);color:var(--cbi-color,#000);border-radius:14px;padding:20px;max-width:340px;width:100%;text-align:center;box-shadow:0 12px 40px rgba(0,0,0,.3)}\
.tower-modal-title{font-size:14px;font-weight:600;margin:0 0 12px}\
.tower-modal canvas{image-rendering:pixelated;width:220px;height:220px;background:#fff;padding:8px;border-radius:8px}\
.tower-modal-link{font-size:11px;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-all;opacity:.65;margin:12px 0;text-align:left;max-height:64px;overflow:auto}\
.tower-modal-actions{display:flex;gap:8px;justify-content:center}\
.tower-gen-status{font-size:12px;opacity:.75}\
.tower-gen-status-ok{color:#4aa065;font-weight:600}\
.tower-gen-status-error{color:#d96d6d}\
.tower-gen-status-busy{opacity:.55}\
.tower-scheme-select{flex:0 1 320px;width:100%;max-width:320px;height:34px!important;min-height:34px!important;box-sizing:border-box;padding:5px 10px!important;border:1px solid rgba(128,128,128,.28)!important;border-radius:7px!important;background-color:rgba(128,128,128,.07)!important;color:inherit!important;font-size:13px!important;line-height:1.2}\
.tower-scheme-select:focus{border-color:#4299e1!important;box-shadow:0 0 0 2px rgba(66,153,225,.16)}\
.tower-scheme-label{font-size:12px;opacity:.7;white-space:nowrap}\
.tower-rule-set-check{display:inline-flex;align-items:center;gap:7px;font-size:12px;opacity:.75;line-height:1.2;white-space:nowrap;cursor:pointer}\
.tower-rule-set-check input{position:static!important;top:auto!important;left:auto!important;appearance:checkbox!important;-webkit-appearance:checkbox!important;accent-color:#5e72e4;flex:none;width:16px;height:16px;margin:0!important}\
@media(max-width:700px){.tower-card{padding:14px}.tower-client-grid{grid-template-columns:repeat(2,minmax(0,1fr))}.tower-client-card{padding:8px}.tower-filter{margin-left:0;min-width:100%}.tower-result{grid-template-columns:20px minmax(0,1fr) auto}.tower-result .tower-server{grid-column:2;grid-row:2}.tower-preview{height:240px}.tower-link-row{grid-template-columns:58px minmax(0,1fr) auto}.tower-btn-row{flex-wrap:wrap}.tower-scheme-select{flex:1 1 100%;max-width:none}}\
';

function extFor(target) {
	if (target === 'links')
		return '.txt';
	if (target === 'sing-box' || target === 'hiddify' || target === 'clashoo-singbox' || target === 'momo')
		return '.json';
	if (target === 'surge' || target === 'surge-mac' || target === 'shadowrocket')
		return '.conf';
	return '.yaml';
}

function reusableLink(item) {
	var aliases = { hysteria2: 'hysteria2|hy2', socks5: 'socks5|socks', http: 'https?' };
	var scheme = aliases[item.kind] || item.kind;
	return new RegExp('^(?:' + scheme + ')://', 'i').test(item.link || '');
}

function clientCard(client) {
	var icon = client.icon
		? E('img', { 'class': 'tower-client-icon', 'src': L.resource('view/tower/icons/' + client.icon), 'alt': '' })
		: E('span', { 'class': 'tower-client-fallback' }, [ 'dae' ]);
	var text = [ E('span', { 'class': 'tower-client-name' }, [ client.name ]) ];
	if (client.detail)
		text.push(E('span', { 'class': 'tower-client-detail' }, [ client.detail ]));
	return E('label', { 'class': 'tower-client-card' }, [
		E('input', { 'type': 'radio', 'name': 'tower-client', 'value': client.id }),
		icon,
		E('span', { 'class': 'tower-client-text' }, text)
	]);
}

function loadQrcode() {
	if (window.qrcode)
		return Promise.resolve(window.qrcode);

	return new Promise(function(resolve, reject) {
		var s = document.createElement('script');
		s.src = L.resource('view/tower/vendor/qrcode.js');
		s.onload = function() { resolve(window.qrcode); };
		s.onerror = function() { reject(new Error(_('二维码组件加载失败'))); };
		document.head.appendChild(s);
	});
}

function renderQR(canvas, text) {
	return loadQrcode().then(function(QR) {
		var qr = QR(0, 'M');
		qr.addData(text);
		qr.make();
		var size = qr.getModuleCount();
		var scale = 5;
		canvas.width = size * scale;
		canvas.height = size * scale;
		var ctx = canvas.getContext('2d');
		ctx.fillStyle = '#ffffff';
		ctx.fillRect(0, 0, canvas.width, canvas.height);
		ctx.fillStyle = '#000000';
		for (var r = 0; r < size; r++)
			for (var c = 0; c < size; c++)
				if (qr.isDark(r, c))
					ctx.fillRect(c * scale, r * scale, scale, scale);
	});
}

function showQRModal(name, link) {
	var canvas = E('canvas');

	var overlay = E('div', { 'class': 'tower-modal-overlay' }, [
		E('div', {
			'class': 'tower-modal',
			'click': function(ev) { ev.stopPropagation(); }
		}, [
			E('p', { 'class': 'tower-modal-title' }, [ name ]),
			canvas,
			E('div', { 'class': 'tower-modal-link' }, [ link ]),
			E('div', { 'class': 'tower-modal-actions' }, [
				E('button', {
					'class': 'btn cbi-button',
					'click': ui.createHandlerFn(this, function() {
						return tower.copyText(link).then(function() {
							ui.addNotification(null, E('p', [ _('已复制链接') ]), 'info');
						}).catch(function() {
							ui.addNotification(null, E('p', [ _('复制失败') ]), 'error');
						});
					})
				}, [ _('复制链接') ]),
				E('button', {
					'class': 'btn cbi-button cbi-button-reset',
					'click': ui.createHandlerFn(this, function() { document.body.removeChild(overlay); })
				}, [ _('关闭') ])
			])
		])
	]);

	overlay.addEventListener('click', function() { document.body.removeChild(overlay); });
	document.body.appendChild(overlay);
	renderQR(canvas, link).catch(function() {
		canvas.parentNode.insertBefore(E('p', { 'class': 'tower-empty' }, [ _('二维码生成失败') ]), canvas);
	});
}

return view.extend({
	load: function() {
		return Promise.all([ tower.rpcListNodes(), tower.rpcSchemes() ]).then(function(res) {
			return { nodes: res[0], schemes: res[1] };
		});
	},

	render: function(data) {
		var nodes = data.nodes;
		var schemes = data.schemes || [];
		var destinations = tower.clients.concat(tower.openwrtClients);
		var selected = {};
		nodes.forEach(function(n) { selected[n.id] = true; });
		var filterText = '';

		var resultBody = E('div', { 'class': 'tower-results' });
		var statTotal = E('strong', {}, '0');
		var statSelected = E('strong', {}, '0');

		var previewArea = E('textarea', {
			'class': 'tower-preview',
			'readonly': 'readonly',
			'placeholder': _('点击「生成」后在此预览配置内容。')
		});

		var linkList = E('div', { 'class': 'tower-link-list' });
		var configTitle = E('h4', { 'class': 'tower-card-title' }, [ _('配置文件') ]);
		var localShareURL = E('input', { 'class': 'tower-share-url', 'readonly': 'readonly', 'placeholder': _('生成后显示仅供本机插件使用的地址') });
		var localShareStatus = E('span', { 'class': 'tower-gen-status' });
		var sharePanel = E('div', { 'class': 'tower-share' }, [
			E('div', { 'class': 'tower-card' }, [
				configTitle,
				E('div', { 'class': 'tower-toolbar' }, [
					E('button', { 'class': 'btn cbi-button', 'id': 'tower-download-file' }, [ _('下载文件') ]),
					E('button', { 'class': 'btn cbi-button', 'id': 'tower-copy-config' }, [ _('复制配置文本') ])
				]),
				previewArea
			]),
			E('div', { 'class': 'tower-card' }, [
				E('h4', { 'class': 'tower-card-title' }, _('节点链接')),
				E('div', { 'class': 'tower-toolbar' }, [
					E('button', { 'class': 'btn cbi-button', 'id': 'tower-download-links' }, [ _('下载链接文件') ]),
					E('button', { 'class': 'btn cbi-button', 'id': 'tower-copy-links' }, [ _('复制全部链接') ]),
					E('span', { 'class': 'tower-summary' }, [ _('点「二维码」用手机扫码导入单个节点。') ])
				]),
				linkList
			]),
			E('div', { 'class': 'tower-card' }, [
				E('h4', { 'class': 'tower-card-title' }, [ _('本机订阅共享') ]),
				E('p', { 'class': 'tower-share-help' }, [ _('为同一台路由器上的 Clashoo、Momo、daede 等插件生成订阅地址；只监听 127.0.0.1。重新生成会使旧地址失效。') ]),
				E('div', { 'class': 'tower-toolbar' }, [
					E('button', { 'class': 'btn cbi-button', 'id': 'tower-share-create' }, [ _('生成本机地址') ]),
					E('button', { 'class': 'btn cbi-button', 'id': 'tower-share-copy' }, [ _('复制地址') ]),
					E('button', { 'class': 'btn cbi-button cbi-button-remove', 'id': 'tower-share-revoke' }, [ _('撤销共享') ]),
					localShareStatus
				]),
				localShareURL
			])
		]);

		function currentDestination() {
			var el = document.querySelector('input[name=tower-client]:checked');
			var id = el ? el.value : 'clash-verge';
			return destinations.filter(function(c) { return c.id === id; })[0] || destinations[0];
		}

		function selectedCount() {
			var n = 0;
			for (var id in selected)
				if (selected[id]) n++;
			return n;
		}

		function updateSummary() {
			statTotal.textContent = String(nodes.length);
			statSelected.textContent = String(selectedCount());
		}

		function visibleNodes() {
			var q = filterText.toLowerCase();
			return nodes.filter(function(n) {
				return !q || n.name.toLowerCase().indexOf(q) >= 0 || String(n.kind).toLowerCase().indexOf(q) >= 0;
			});
		}

		function renderResults() {
			while (resultBody.firstChild)
				resultBody.removeChild(resultBody.firstChild);

			var shown = visibleNodes();
			shown.forEach(function(n) {
				var checkbox = E('input', { 'type': 'checkbox' });
				checkbox.checked = !!selected[n.id];
				checkbox.addEventListener('change', function() {
					selected[n.id] = checkbox.checked;
					updateSummary();
				});
				resultBody.appendChild(E('div', { 'class': 'tower-result' }, [
					checkbox,
					E('span', { 'class': 'tower-name', 'title': n.name }, n.name),
					E('span', { 'class': 'tower-proto' }, String(n.kind))
				]));
			});
			if (!shown.length)
				resultBody.appendChild(E('div', { 'class': 'tower-empty' }, _('没有匹配的节点。')));
			updateSummary();
		}

		function selectedIDs() {
			var ids = [];
			for (var id in selected)
				if (selected[id]) ids.push(id);
			return ids;
		}

		var currentContent = '';
		var currentLinks = [];
		var currentTargetName = 'clash-verge';
		var currentDestinationID = 'clash-verge';
		var generatedOptions = null;

		function renderLinks(links) {
			currentLinks = links || [];
			while (linkList.firstChild)
				linkList.removeChild(linkList.firstChild);

			if (!currentLinks.length) {
				linkList.appendChild(E('div', { 'class': 'tower-empty' }, _('没有可导出的节点链接。')));
				return;
			}

			currentLinks.forEach(function(item) {
				linkList.appendChild(E('div', { 'class': 'tower-link-row' }, [
					E('span', { 'class': 'tower-proto' }, String(item.kind)),
					E('span', { 'class': 'tower-name', 'title': item.link }, item.name),
					E('div', { 'class': 'tower-btn-row' }, [
						E('button', {
							'class': 'btn cbi-button tower-btn',
							'click': ui.createHandlerFn(this, function() {
								return tower.copyText(item.link).then(function() {
									ui.addNotification(null, E('p', [ _('已复制链接') ]), 'info');
								});
							})
						}, [ _('复制') ]),
						E('button', {
							'class': 'btn cbi-button tower-btn',
							'click': ui.createHandlerFn(this, function() { showQRModal(item.name, item.link); })
						}, [ _('二维码') ])
					])
				]));
			});
		}

		// —— 规则方案选择 ——
		var schemeSelect = E('select', { 'class': 'cbi-input-select tower-scheme-select', 'name': 'scheme' });
		var preferRuleSets = E('input', { 'type': 'checkbox', 'name': 'prefer-rule-sets' });
		preferRuleSets.checked = true;
		schemeSelect.appendChild(E('option', { 'value': '' }, [ _('默认（简单分流）') ]));
		schemes.forEach(function(s) {
			schemeSelect.appendChild(E('option', { 'value': s.id }, [ (s.name || _('未命名方案')) + (s.is_bundled ? '' : '（导入）') ]));
		});
		var targetNote = E('p', { 'class': 'tower-target-note' });

		function updateTargetCapabilities() {
			var destination = currentDestination();
			var nodeOnly = !!destination.nodeOnly || destination.id === 'sing-box' || destination.id === 'hiddify';
			schemeSelect.disabled = nodeOnly;
			preferRuleSets.disabled = nodeOnly;
			generateBtn.textContent = destination.target === 'links' ? _('生成节点订阅') : _('生成配置与链接');
			sharePanel.querySelector('#tower-copy-config').textContent = destination.target === 'links' ? _('复制节点订阅') : _('复制配置文本');
			if (nodeOnly) {
				schemeSelect.value = '';
				targetNote.textContent = destination.target === 'links'
					? _('此目标只导出节点订阅；完整配置和分流规则仍在目标插件中管理。')
					: destination.id === 'momo'
						? _('Momo 可导入 sing-box JSON；启用代理前须按 Momo 的 TCP、UDP 和 DNS 模式补齐对应入站。当前仅导出默认分流。')
						: _('sing-box JSON 目前只支持默认分流，不支持导入的规则方案。');
			} else {
				targetNote.textContent = _('使用所选规则方案生成完整配置；兼容目标仍需在对应插件中导入验证。');
			}
			sharePanel.classList.remove('tower-visible');
			setGenStatus('', '');
		}

		// —— 生成 ——
		var genStatus = E('span', { 'class': 'tower-gen-status' });

		function setGenStatus(text, kind) {
			genStatus.textContent = text || '';
			genStatus.className = 'tower-gen-status' + (kind ? ' tower-gen-status-' + kind : '');
		}

		var generateBtn = E('button', {
			'class': 'btn cbi-button cbi-button-apply',
			'click': ui.createHandlerFn(this, function() {
				var ids = selectedIDs();
				if (!ids.length) {
					setGenStatus(_('请至少选择一个节点。'), 'error');
					return Promise.resolve();
				}
				var destination = currentDestination();
				currentDestinationID = destination.id;
				currentTargetName = destination.target || destination.id;
				var idsStr = ids.join(',');
				generatedOptions = {
					destination: destination.id,
					nodes: idsStr,
					scheme: schemeSelect.disabled ? '' : schemeSelect.value,
					preferRuleSets: preferRuleSets.checked
				};
				localShareURL.value = '';
				localShareStatus.textContent = '';
				setGenStatus(_('正在生成…'), 'busy');
				if (currentTargetName === 'links') {
					return tower.rpcLinks('', idsStr).then(function(links) {
						var allowed = destination.allowedKinds || [];
						var supported = links.filter(function(item) { return allowed.indexOf(item.kind) >= 0 && reusableLink(item); });
						if (!supported.length)
							throw new Error(_('所选节点没有此插件支持的协议。'));
						var raw = supported.map(function(item) { return item.link; }).join('\n') + '\n';
						currentContent = raw;
						previewArea.value = currentContent;
						configTitle.textContent = _('节点订阅');
						renderLinks(supported);
						sharePanel.classList.add('tower-visible');
						setGenStatus(_('已导出') + ' ' + supported.length + ' ' + _('个节点；跳过') + ' ' + (links.length - supported.length) + ' ' + _('个不兼容节点'), 'ok');
					}).catch(function(e) {
						setGenStatus(String(e), 'error');
					});
				}
				return Promise.all([
					tower.rpcExport(currentTargetName, '', idsStr, schemeSelect.disabled ? '' : schemeSelect.value, preferRuleSets.checked),
					tower.rpcLinks('', idsStr)
				]).then(function(res) {
					currentContent = res[0] || '';
					previewArea.value = currentContent;
					configTitle.textContent = _('配置文件');
					renderLinks(res[1]);
					sharePanel.classList.add('tower-visible');
					setGenStatus(_('已生成配置与节点链接'), 'ok');
				}).catch(function(e) {
					setGenStatus(String(e), 'error');
				});
			})
		}, [ _('生成配置与链接') ]);

		// —— 分享面板按钮 ——
		sharePanel.querySelector('#tower-download-file').addEventListener('click', function() {
			if (!currentContent) {
				ui.addNotification(null, E('p', [ _('请先生成配置。') ]), 'error');
				return;
			}
			tower.downloadFile('tower-' + currentDestinationID + extFor(currentTargetName), currentContent);
			ui.addNotification(null, E('p', [ currentTargetName === 'links' ? _('节点订阅已下载') : _('配置文件已下载') ]), 'info');
		});

		sharePanel.querySelector('#tower-copy-config').addEventListener('click', function() {
			if (!currentContent) {
				ui.addNotification(null, E('p', [ _('请先生成配置。') ]), 'error');
				return;
			}
			tower.copyText(currentContent).then(function() {
				ui.addNotification(null, E('p', [ currentTargetName === 'links' ? _('节点订阅已复制') : _('配置已复制到剪贴板') ]), 'info');
			}).catch(function() {
				ui.addNotification(null, E('p', [ _('复制失败') ]), 'error');
			});
		});

		sharePanel.querySelector('#tower-download-links').addEventListener('click', function() {
			if (!currentLinks.length) {
				ui.addNotification(null, E('p', [ _('没有可导出的节点链接。') ]), 'error');
				return;
			}
			tower.downloadFile('tower-links.txt', currentLinks.map(function(i) { return i.link; }).join('\n') + '\n');
			ui.addNotification(null, E('p', [ _('链接文件已下载') ]), 'info');
		});

		sharePanel.querySelector('#tower-copy-links').addEventListener('click', function() {
			if (!currentLinks.length) {
				ui.addNotification(null, E('p', [ _('没有可导出的节点链接。') ]), 'error');
				return;
			}
			tower.copyText(currentLinks.map(function(i) { return i.link; }).join('\n')).then(function() {
				ui.addNotification(null, E('p', [ _('全部链接已复制') ]), 'info');
			}).catch(function() {
				ui.addNotification(null, E('p', [ _('复制失败') ]), 'error');
			});
		});

		sharePanel.querySelector('#tower-share-create').addEventListener('click', function() {
			if (!generatedOptions || !currentContent) {
				localShareStatus.textContent = _('请先生成配置。');
				return;
			}
			localShareStatus.textContent = _('正在生成…');
			tower.rpcShareCreate(generatedOptions.destination, generatedOptions.nodes, generatedOptions.scheme, generatedOptions.preferRuleSets).then(function(result) {
				localShareURL.value = result.url;
				localShareStatus.textContent = _('本机地址已生成');
			}).catch(function(e) {
				localShareStatus.textContent = String(e);
			});
		});
		sharePanel.querySelector('#tower-share-copy').addEventListener('click', function() {
			if (!localShareURL.value) {
				localShareStatus.textContent = _('请先生成本机地址。');
				return;
			}
			tower.copyText(localShareURL.value).then(function() {
				localShareStatus.textContent = _('地址已复制');
			}).catch(function() {
				localShareStatus.textContent = _('复制失败');
			});
		});
		sharePanel.querySelector('#tower-share-revoke').addEventListener('click', function() {
			tower.rpcShareRevoke().then(function() {
				localShareURL.value = '';
				localShareStatus.textContent = _('共享已撤销');
			}).catch(function(e) {
				localShareStatus.textContent = String(e);
			});
		});

		// —— 节点选择工具栏 ——
		var filterInput = E('input', {
			'class': 'tower-filter',
			'placeholder': _('筛选节点名称或协议')
		});
		filterInput.addEventListener('input', function() {
			filterText = filterInput.value;
			renderResults();
		});

		var selectAllBtn = E('button', {
			'class': 'btn cbi-button',
			'click': ui.createHandlerFn(this, function() {
				visibleNodes().forEach(function(n) { selected[n.id] = true; });
				renderResults();
			})
		}, [ _('全选') ]);

		var clearBtn = E('button', {
			'class': 'btn cbi-button',
			'click': ui.createHandlerFn(this, function() {
				visibleNodes().forEach(function(n) { selected[n.id] = false; });
				renderResults();
			})
		}, [ _('清空') ]);

		// —— 目标客户端 grid ——
		var clientGrid = tower.clients.map(clientCard);
		var openwrtGrid = tower.openwrtClients.map(clientCard);
		clientGrid[0].querySelector('input').checked = true;
		clientGrid.concat(openwrtGrid).forEach(function(card) {
			card.querySelector('input').addEventListener('change', updateTargetCapabilities);
		});
		updateTargetCapabilities();

		renderResults();

		if (nodes.length === 0) {
			return E('div', { 'class': 'cbi-map tower-export-page' }, [
				E('style', {}, [ css ]),
				E('div', { 'class': 'tower-empty' }, [ _('还没有节点。请先到「订阅」页添加订阅或导入节点。') ])
			]);
		}

		return E('div', { 'class': 'cbi-map tower-export-page' }, [
			E('style', {}, [ css ]),
			E('div', { 'class': 'tower-card' }, [
				E('h4', { 'class': 'tower-card-title' }, _('1. 目标客户端')),
				E('div', { 'class': 'tower-client-section' }, [
					E('p', { 'class': 'tower-client-heading' }, [ _('桌面与移动客户端') ]),
					E('div', { 'class': 'tower-client-grid' }, clientGrid)
				]),
				E('div', { 'class': 'tower-client-section' }, [
					E('p', { 'class': 'tower-client-heading' }, [ _('OpenWrt 插件') ]),
					E('div', { 'class': 'tower-client-grid' }, openwrtGrid)
				]),
				targetNote
			]),
			E('div', { 'class': 'tower-card' }, [
				E('h4', { 'class': 'tower-card-title' }, _('2. 选择节点')),
				E('div', { 'class': 'tower-toolbar' }, [ selectAllBtn, ' ', clearBtn, ' ', filterInput ]),
				E('div', { 'class': 'tower-summary' }, [
					E('span', {}, [ _('共'), ' ', statTotal, ' ', _('个节点') ]),
					E('span', {}, [ _('已选'), ' ', statSelected, ' ', _('个') ])
				]),
				resultBody
			]),
			E('div', { 'class': 'tower-card' }, [
				E('h4', { 'class': 'tower-card-title' }, _('3. 生成与导出')),
				E('div', { 'class': 'tower-toolbar' }, [
					E('span', { 'class': 'tower-scheme-label' }, [ _('规则方案') ]),
					schemeSelect,
					E('label', { 'class': 'tower-rule-set-check' }, [ preferRuleSets, _('优先使用原生规则集') ])
				]),
				E('div', { 'class': 'tower-toolbar' }, [ generateBtn, genStatus ]),
				sharePanel
			])
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
