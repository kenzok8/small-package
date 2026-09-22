'use strict';
'require view';
'require form';
'require uci';
'require fs';
'require ui';

// 辅助工具：统一纯净数组转换
function toArray(val) {
	if (Array.isArray(val)) return val.filter(Boolean);
	return typeof val === 'string' ? val.trim().split(/\s+/).filter(Boolean) : [];
}

// 辅助工具：提取首个 IP 并去除可能的 CIDR 掩码（容错支持 String、Array 及 null/undefined）
function getFirstIp(val, defaultVal) {
	if (Array.isArray(val)) val = val[0];
	if (typeof val === 'string') return val.split('/')[0].trim();
	return defaultVal || '';
}

// 辅助工具：通用值深度比对（支持标量与数组）
function isEqual(a, b) {
	if (Array.isArray(a) || Array.isArray(b)) {
		var arrA = toArray(a).sort(), arrB = toArray(b).sort();
		return arrA.length === arrB.length && arrA.every(function(v, i) { return v === arrB[i]; });
	}
	return String(a == null ? '' : a) === String(b == null ? '' : b);
}

// 辅助工具：检查数组是否包含元素（兼容低版本环境）
function has(arr, item) {
	return Array.isArray(arr) && arr.indexOf(item) !== -1;
}

// 辅助工具：安全删除 UCI 选项（只有当该选项在 UCI 内存中真实存在时才调用 unset，防止 ubus 报错）
function safeUnset(conf, sid, opt) {
	try {
		if (uci.get(conf, sid, opt) != null) {
			uci.unset(conf, sid, opt);
			return true;
		}
	} catch(e) {}
	return false;
}

// 辅助工具：智能判断无线物理网卡的频段 (2.4G / 5G / 6G)
function getRadioBand(devName) {
	if (!devName) return '2.4G';
	var b = uci.get('wireless', devName, 'band');
	if (b === '6g') return '6G';
	if (b === '5g') return '5G';
	if (b === '2g') return '2.4G';

	var ch = parseInt(uci.get('wireless', devName, 'channel'), 10);
	if (!isNaN(ch)) {
		if (ch >= 1 && ch <= 14) return '2.4G';
		if (ch >= 32 && ch <= 196) return '5G';
		if (ch > 196) return '6G';
	}

	var hw = (uci.get('wireless', devName, 'hwmode') || '').toLowerCase();
	if (hw.indexOf('a') !== -1) return '5G';
	if (hw.indexOf('b') !== -1 || hw.indexOf('g') !== -1) return '2.4G';

	var dl = devName.toLowerCase();
	if (dl.indexOf('6g') !== -1) return '6G';
	if (dl.indexOf('5g') !== -1) return '5G';
	return '2.4G';
}

return view.extend({
	initialValues: {},
	initialShortcuts: [],
	originalLanIp: null, // 持久快照，防止被 handleSave 覆盖
	hasWireless: false,
	hasNginx: false,
	map: null,
	fields: null,
	optMap: null,

	// 1. 直连加载系统真实配置包，无需任何中间文件
	load: function() {
		var pkgs = ['network', 'wireless', 'dhcp', 'uhttpd', 'firewall', 'luci', 'wizard'];
		var tasks = pkgs.map(function(p) {
			return uci.load(p).catch(function() { return null; });
		});
		tasks.push(fs.stat('/etc/nginx/uci.conf').then(function() { return true; }).catch(function() { return false; }));

		return Promise.all(tasks).then(function(res) {
			var wifiSecs = (res && res) ? (uci.sections('wireless', 'wifi-device') || []) : [];
			return {
				hasWireless: wifiSecs.length > 0,
				hasNginx: !!res[7]
			};
		});
	},

	// 2. 统一聚合读取系统当前各子模块的实时配置
	getSystemConfig: function() {
		var lanGw = getFirstIp(uci.get('network', 'lan', 'gateway'), '');
		var wanSec = uci.get('network', 'wan');

		// 判定 WAN 接口是否不存在或处于停用状态
		var isWanDisabled = !wanSec ||
			uci.get('network', 'wan', 'auto') === '0' ||
			uci.get('network', 'wan', 'disabled') === '1' ||
			uci.get('network', 'wan', 'proto') === 'none';

		// 核心判定：配置了局域网网关，且 WAN 口被停用或不存在，即确认处于旁路由模式
		var isSideRouter = !!lanGw && isWanDisabled;

		var ap = null;
		if (this.hasWireless) {
			var ifaces = uci.sections('wireless', 'wifi-iface') || [];
			for (var i = 0; i < ifaces.length; i++) {
				if (ifaces[i].mode === 'ap' || !ifaces[i].mode) {
					ap = ifaces[i];
					break;
				}
			}
		}

		// 剥离现有频段后缀，确保输入框展示纯净的基准名称
		var rawSsid = (ap && ap.ssid) || (this.hasWireless ? 'Kwrt' : '');
		var baseSsid = rawSsid.replace(/_(2\.4G|5G|6G)$/i, '').trim();

		return {
			wan_proto: isSideRouter ? 'siderouter' : (uci.get('network', 'wan', 'proto') || 'dhcp'),
			wan_pppoe_user: uci.get('network', 'wan', 'username') || '',
			wan_pppoe_pass: uci.get('network', 'wan', 'password') || '',
			lan_ipaddr: getFirstIp(uci.get('network', 'lan', 'ipaddr'), '10.0.0.1'),
			lan_gateway: lanGw,
			lan_dns: toArray(uci.get('network', 'lan', 'dns')),
			dhcp: uci.get('dhcp', 'lan', 'ignore') === '1' ? '0' : '1',
			ipv6: uci.get('network', 'wan6', 'auto') === '0' ? '0' : '1',
			https: uci.get('wizard', 'default', 'https') || '0',
			cookie_p: uci.get('wizard', 'default', 'persistent_cookies') || '1',
			landing_page: uci.get('wizard', 'default', 'landing_page') || 'default',
			autoupgrade_fm: uci.get('wizard', 'default', 'autoupgrade_fm') || '1',
			coremark: uci.get('wizard', 'default', 'coremark') || '0',
			wifi_ssid: baseSsid || (this.hasWireless ? 'Kwrt' : ''),
			wifi_key: (ap && ap.key) || ''
		};
	},

	render: function(data) {
		this.hasWireless = !!data.hasWireless;
		this.hasNginx = !!data.hasNginx;

		var sys = this.getSystemConfig();
		this.initialValues = Object.assign({}, sys);
		this.originalLanIp = sys.lan_ipaddr; // 记录不可变初始 IP

		// 缓存初始 shortcuts 配置快照，用于保存时比对差异
		var shortcuts = uci.sections('wizard', 'shortcuts') || [];
		this.initialShortcuts = shortcuts.map(function(sec) {
			return {
				shortcut: sec.shortcut || '',
				to_url: sec.to_url || '',
				comments: sec.comments || ''
			};
		});

		var m = new form.Map('wizard', _('Setup Wizard'),
			_('Quickly configure common network, wireless, and system settings.'));

		var s = m.section(form.NamedSection, 'default', 'wizard');
		s.anonymous = true;
		s.addremove = false;

		s.tab('netsetup', _('Net Settings'));
		s.tab('firmware', _('Firmware Settings'));
		if (this.hasWireless) s.tab('wifisetup', _('Wireless Settings'));

		if (this.hasNginx) {
			s.tab('shortcuts', _('Shortcuts'), _('比如设置google.com的快捷方式为字母g,则在此路由器网络的任何浏览器中输入g/即可访问google.com'));
		}

		// 3. 声明式配置项驱动表
		var opt, fields = [
			// 网络设置
			{ tab: 'netsetup', type: form.ListValue, id: 'wan_proto', title: _('WAN Protocol / Mode'),
			  choices: { dhcp: _('DHCP Client (Default Router)'), pppoe: _('PPPoE Dial-up'), siderouter: _('Side-Router Mode (Bypass Gateway)') } },
			{ tab: 'netsetup', type: form.Value, id: 'wan_pppoe_user', title: _('PPPoE Username'), depends: { wan_proto: 'pppoe' } },
			{ tab: 'netsetup', type: form.Value, id: 'wan_pppoe_pass', title: _('PPPoE Password'), depends: { wan_proto: 'pppoe' }, password: true },
			{ tab: 'netsetup', type: form.Value, id: 'lan_ipaddr', title: _('LAN IPv4 Address'), datatype: 'ip4addr', placeholder: '10.0.0.1' },
			{ tab: 'netsetup', type: form.DynamicList, id: 'lan_dns', title: _('Custom DNS Server(s)'), datatype: 'ipaddr', placeholder: '223.5.5.5', desc: _('Leave empty for ISP DNS.') },
			{ tab: 'netsetup', type: form.Value, id: 'lan_gateway', title: _('Gateway Address'), datatype: 'ip4addr', placeholder: '', depends: { wan_proto: 'siderouter' }, desc: _('Primary router IP address used when operating in side-router mode.') },
			{ tab: 'netsetup', type: form.Flag, id: 'dhcp', title: _('Enable DHCP Server'), desc: _("If this DHCP is enabled, disable the main router's DHCP. If disabled, manually set client devices' gateway and DNS to this bypass router's IP.") },
			{ tab: 'netsetup', type: form.Flag, id: 'ipv6', title: _('IPv6 Support'), desc: _('Enable or disable IPv6 router advertisements and DHCPv6.') },

			// 固件与系统设置
			{ tab: 'firmware', type: form.Flag, id: 'autoupgrade_fm', title: _('Firmware Upgrade Notice'), desc: _('Check and display notices for newer firmware versions.') },
			{ tab: 'firmware', type: form.Flag, id: 'coremark', title: _('Run CoreMark on Boot'), desc: _('Run CPU benchmark asynchronously upon router initialization.') },
			{ tab: 'firmware', type: form.Flag, id: 'cookie_p', title: _('Persistent Cookie Session'), desc: _('Maintain persistent login sessions in the web browser.') },
			{ tab: 'firmware', type: form.Flag, id: 'https', title: _('Enforce HTTPS Access'), desc: _('Automatically redirect HTTP requests to secure HTTPS.') },
			{ tab: 'firmware', type: form.ListValue, id: 'landing_page', title: _('Landing Dashboard Mode'),
			  choices: { 'default': _('Default'), routerdog: _('RouterDog'), nas: _('NAS'), 'next-nas': _('Next-NAS'), router: _('Router') } }
		];

		// 无线配置根据设备硬件动态追加
		if (this.hasWireless) {
			fields.push(
				{ tab: 'wifisetup', type: form.Value, id: 'wifi_ssid', title: _('Wireless Network Name (SSID)'), placeholder: 'Kwrt' },
				{ tab: 'wifisetup', type: form.Value, id: 'wifi_key', title: _('Wireless Password (Key)'), password: true, placeholder: _('Leave empty for open network or 8+ characters') }
			);
		}

		var optMap = {};
		fields.forEach(function(f) {
			opt = s.taboption(f.tab, f.type, f.id, f.title, f.desc);
			opt.cfgvalue = function() { return sys[f.id]; };
			opt.default = sys[f.id];

			opt.write = function() {};
			opt.remove = function() {};

			if (f.password) opt.password = true;
			if (f.datatype) opt.datatype = f.datatype;
			if (f.placeholder) opt.placeholder = f.placeholder;
			if (f.choices) Object.keys(f.choices).forEach(function(k) { opt.value(k, f.choices[k]); });
			if (f.depends) Object.keys(f.depends).forEach(function(k) { opt.depends(k, f.depends[k]); });

			// 为无线密码增加 8~64 位安全校验，防止 hostapd 崩溃
			if (f.id === 'wifi_key') {
				opt.validate = function(section_id, value) {
					if (!value) return true;
					if (value.length < 8 || value.length > 64) {
						return _('Wireless key must be between 8 and 64 characters long');
					}
					return true;
				};
			}

			optMap[f.id] = opt;
		});

		// Shortcuts GridSection 渲染
		if (this.hasNginx) {
			var so = s.taboption('shortcuts', form.SectionValue, '_shortcuts', form.GridSection, 'shortcuts', null, _('Shortcuts'));
			var ss = so.subsection;
			ss.addremove = true;
			ss.anonymous = true;
			ss.sortable  = true;

			var o_sc = ss.option(form.Value, 'shortcut', _('Shortcut'));
			o_sc.rmempty = false;
			o_sc.placeholder = 'g';
			o_sc.validate = function(section_id, value) {
				if (!value)
					return _('Shortcut phrase cannot be empty');
				if (!value.match(/^[a-zA-Z0-9_-]+$/))
					return _('Only alphanumeric characters, dashes and underscores are allowed');
				return true;
			};

			var o_url = ss.option(form.Value, 'to_url', _('Target URL'));
			o_url.rmempty = false;
			o_url.placeholder = 'https://example.com';
			o_url.validate = function(section_id, value) {
				if (value && value.match(/^https?:\/\/.+/i)) {
					return true;
				}
				return _('Please enter a valid URL starting with http:// or https://');
			};

			var o_comm = ss.option(form.Value, 'comments', _('Comments'));
			o_comm.optional = true;
			o_comm.placeholder = _('Optional');
		}

		this.map = m;
		this.fields = fields;
		this.optMap = optMap;

		return m.render();
	},

	// 4. 重写 View 级别的 handleSave：精准写入发生变化的配置到 UCI 暂存区
	handleSave: function(ev) {
		var self = this;
		if (!this.map) return Promise.resolve(false);

		return this.map.parse().then(function() {
			var cur = {};
			self.fields.forEach(function(f) {
				var v = self.optMap[f.id].formvalue('default');
				// 对 Flag 进行布尔归一化，彻底消除 null 与 '0' 比对产生的假变动
				if (f.type === form.Flag) {
					cur[f.id] = (v == '1') ? '1' : '0';
				} else {
					cur[f.id] = (v != null) ? v : '';
				}
			});
			cur.lan_dns = toArray(cur.lan_dns);

			// 精准筛选出发生变化的常规字段
			var changed = self.fields.map(function(f) { return f.id; }).filter(function(id) {
				return !isEqual(cur[id], self.initialValues[id]);
			});

			// 检测 shortcuts 是否有增删改
			var curShortcuts = (uci.sections('wizard', 'shortcuts') || []).map(function(sec) {
				return {
					shortcut: sec.shortcut || '',
					to_url: sec.to_url || '',
					comments: sec.comments || ''
				};
			});
			var shortcutsChanged = JSON.stringify(curShortcuts) !== JSON.stringify(self.initialShortcuts);

			// 未做任何改动直接提示并退出
			if (changed.length === 0 && !shortcutsChanged) {
				ui.addNotification(null, E('p', _('There are no changes to apply')), 'info');
				return false;
			}

			// A. 无线配置直接写回 wireless（全频段适配：2.4G加_2.4G，5G加_5G，6G加_6G）
			if (self.hasWireless && (has(changed, 'wifi_ssid') || has(changed, 'wifi_key'))) {
				var rawInputSsid = (cur.wifi_ssid || '').trim();
				var baseSsid = rawInputSsid.replace(/_(2\.4G|5G|6G)$/i, '').trim();
				if (!baseSsid) baseSsid = rawInputSsid;

				var ifaces = uci.sections('wireless', 'wifi-iface') || [];
				ifaces.forEach(function(ifc) {
					if (ifc.mode === 'ap' || !ifc.mode) {
						var band = getRadioBand(ifc.device);
						var autoSsid = baseSsid ? (baseSsid + '_' + band) : '';

						if (has(changed, 'wifi_ssid') && autoSsid) {
							uci.set('wireless', ifc['.name'], 'ssid', autoSsid);
						}

						if (has(changed, 'wifi_key')) {
							if (cur.wifi_key) {
								uci.set('wireless', ifc['.name'], 'key', cur.wifi_key);
								var enc = ifc.encryption || uci.get('wireless', ifc['.name'], 'encryption') || '';
								if (enc.indexOf('psk') === -1 && enc.indexOf('sae') === -1) {
									uci.set('wireless', ifc['.name'], 'encryption', 'psk2');
								}
							} else {
								safeUnset('wireless', ifc['.name'], 'key');
								uci.set('wireless', ifc['.name'], 'encryption', 'none');
							}
						}

						// 解除物理无线与接口禁用状态
						if (ifc.device) {
							safeUnset('wireless', ifc.device, 'disabled');
						}
						safeUnset('wireless', ifc['.name'], 'disabled');
					}
				});
			}

			// B. WAN 模式与 PPPoE（单网卡判空保护 + LAN 防火墙动态伪装清理）
			if (has(changed, 'wan_proto') || has(changed, 'wan_pppoe_user') || has(changed, 'wan_pppoe_pass')) {
				var zones = uci.sections('firewall', 'zone') || [];
				var lanZone = null;
				for (var zi = 0; zi < zones.length; zi++) {
					if (zones[zi].name === 'lan') {
						lanZone = zones[zi];
						break;
					}
				}

				var hasWanSec = !!uci.get('network', 'wan');

				if (cur.wan_proto === 'siderouter') {
					if (hasWanSec) uci.set('network', 'wan', 'auto', '0');
					// 旁路由模式：开启 LAN 区域动态伪装 (masq)
					if (lanZone) uci.set('firewall', lanZone['.name'], 'masq', '1');
				} else {
					if (hasWanSec) {
						uci.set('network', 'wan', 'auto', '1');
						uci.set('network', 'wan', 'proto', cur.wan_proto);
						if (cur.wan_proto === 'pppoe') {
							uci.set('network', 'wan', 'username', cur.wan_pppoe_user);
							uci.set('network', 'wan', 'password', cur.wan_pppoe_pass);
						} else {
							safeUnset('network', 'wan', 'username');
							safeUnset('network', 'wan', 'password');
						}
					}
					// 切换回主路由模式：恢复清除 LAN 区域的动态伪装 (masq)
					if (lanZone) safeUnset('firewall', lanZone['.name'], 'masq');
				}
			}

			// C. LAN IP（兼容 list ipaddr / option ipaddr / CIDR 掩码）
			if (has(changed, 'lan_ipaddr') && cur.lan_ipaddr) {
				var origIpRaw = uci.get('network', 'lan', 'ipaddr');
				var firstIp = Array.isArray(origIpRaw) ? origIpRaw[0] : origIpRaw;
				var mask = '';

				if (typeof firstIp === 'string') {
					var slashIdx = firstIp.indexOf('/');
					if (slashIdx !== -1) {
						mask = '/' + firstIp.substring(slashIdx + 1).trim();
					}
				}

				var cleanIp = (typeof cur.lan_ipaddr === 'string') ? cur.lan_ipaddr.split('/')[0].trim() : String(cur.lan_ipaddr);
				var targetVal = cleanIp + mask;

				if (Array.isArray(origIpRaw)) {
					var newArr = origIpRaw.slice();
					newArr[0] = targetVal;
					uci.set('network', 'lan', 'ipaddr', newArr);
				} else {
					uci.set('network', 'lan', 'ipaddr', targetVal);
					if (!mask && !uci.get('network', 'lan', 'netmask')) {
						uci.set('network', 'lan', 'netmask', '255.255.255.0');
					}
				}
			}

			// D. 自定义 LAN DNS（支持旁路由模式自动回落至网关或公网兜底 DNS）
			if (has(changed, 'lan_dns') || has(changed, 'wan_proto') || has(changed, 'lan_gateway')) {
				if (cur.wan_proto === 'siderouter') {
					var effectiveDns = toArray(cur.lan_dns);

					// 若 DNS 列表为空，按优先级进行智能兜底
					if (effectiveDns.length === 0) {
						var cleanGw = getFirstIp(cur.lan_gateway, '');
						if (cleanGw) {
							// 优先级 1：回落至主路由网关 IP
							effectiveDns.push(cleanGw);
						} else {
							// 优先级 2：若网关也未填写，使用常用可靠公网 DNS 兜底
							effectiveDns.push('223.5.5.5', '119.29.29.29');
						}
					}
					uci.set('network', 'lan', 'dns', effectiveDns);
				} else {
					// 常规主路由模式：用户未配则清除，让系统通过 WAN 动态获取
					if (cur.lan_dns && cur.lan_dns.length > 0) {
						uci.set('network', 'lan', 'dns', cur.lan_dns);
					} else {
						safeUnset('network', 'lan', 'dns');
					}
				}
			}

			// E. LAN 网关
			if (has(changed, 'lan_gateway') || has(changed, 'wan_proto')) {
				if (cur.wan_proto === 'siderouter') {
					if (cur.lan_gateway) {
						uci.set('network', 'lan', 'gateway', cur.lan_gateway);
					} else {
						safeUnset('network', 'lan', 'gateway');
					}
				} else {
					safeUnset('network', 'lan', 'gateway');
				}
			}

			// F. DHCP 开关（根据勾选状态精准配置，解除模式死锁冲突）
			if (has(changed, 'dhcp') || has(changed, 'wan_proto')) {
				if (cur.dhcp === '0') {
					uci.set('dhcp', 'lan', 'ignore', '1');
				} else {
					safeUnset('dhcp', 'lan', 'ignore');
				}
			}

			// G. IPv6
			if (has(changed, 'ipv6')) {
				var enabled = (cur.ipv6 === '1');
				if (uci.get('network', 'wan6')) {
					uci.set('network', 'wan6', 'auto', enabled ? '1' : '0');
				}
				uci.set('dhcp', 'lan', 'ra', enabled ? 'server' : 'disabled');
				uci.set('dhcp', 'lan', 'dhcpv6', enabled ? 'server' : 'disabled');
				uci.set('dhcp', 'lan', 'ndp', enabled ? 'server' : 'disabled');
			}

			// H. HTTPS 访问重定向（由 wizard.init 调度底层生效）
			if (has(changed, 'https')) {
				uci.set('wizard', 'default', 'https', cur.https);
			}

			// I. 页面与会话设置（持久Cookie双向同步至luci系统底层与向导配置包）
			if (has(changed, 'cookie_p')) {
				uci.set('wizard', 'default', 'persistent_cookies', cur.cookie_p);
			}
			if (has(changed, 'landing_page')) {
				uci.set('wizard', 'default', 'landing_page', cur.landing_page);
			}

			// J. 向导专属项（完整保留 autoupgrade_fm 与 coremark）
			if (has(changed, 'autoupgrade_fm')) {
				uci.set('wizard', 'default', 'autoupgrade_fm', cur.autoupgrade_fm);
			}
			if (has(changed, 'coremark')) {
				uci.set('wizard', 'default', 'coremark', cur.coremark);
			}

			self.initialValues = Object.assign({}, cur);
			self.initialShortcuts = curShortcuts;

			return uci.save().then(function() {
				return true;
			});
		});
	},

	// 5. 重写 View 级别的 handleSaveApply：前置检测 LAN IP 变动，强制非回滚提交并精准弹出倒计时
	handleSaveApply: function(ev, mode) {
		var self = this;

		// 关键修复：在 handleSave 覆盖 initialValues 之前，立即计算并锁定是否修改了 LAN IP
		var oldIp = (self.originalLanIp || self.initialValues.lan_ipaddr || '').split('/')[0].trim();
		var newIp = (self.optMap['lan_ipaddr'] ? self.optMap['lan_ipaddr'].formvalue('default') : '') || '';
		newIp = newIp.split('/')[0].trim();
		var ipChanged = !!(newIp && oldIp && (newIp !== oldIp));

		return this.handleSave(ev).then(function(hasChanges) {
			if (!hasChanges) return false;

			if (ipChanged) {
				var sec = 15;
				var targetUrl = window.location.protocol + '//' + newIp + (window.location.pathname || '/cgi-bin/luci/');
				var countSpan = E('strong', {}, String(sec));

				// 1. 核心操作：调用 apply_unchecked，进行强制永久提交，彻底绕过 90 秒回滚保护机制！
				L.post(L.url('admin', 'uci', 'apply_unchecked')).catch(function() {});

				// 2. 立即在前端呼出弹窗遮罩层
				ui.showModal(_('LAN IP Address Changed'), [
					E('p', {}, [_('LAN IP has been changed to '), E('strong', {}, newIp), '.']),
					E('p', {}, [_('Applying changes without rollback. Redirecting to the new address in '), countSpan, _(' seconds...')]),
					E('p', { 'class': 'alert-message notice', 'style': 'margin-top: 1em;' },
						_('提示：更改网段后，若未能自动加载新页面，请尝试重新插拔网线或断开重连 Wi-Fi，以获取新网段的 IP 地址。')),
					E('div', { 'class': 'spinning', 'style': 'margin: 1.5em auto;' }),
					E('div', { 'class': 'right' }, [
						E('button', {
							'class': 'cbi-button cbi-button-action',
							'click': function() {
								window.location.href = targetUrl;
							}
						}, _('Redirect Now'))
					])
				]);

				// 3. 启动倒计时并自动跳转
				var timer = window.setInterval(function() {
					sec--;
					countSpan.textContent = String(sec);
					if (sec <= 0) {
						window.clearInterval(timer);
						window.location.href = targetUrl;
					}
				}, 1000);

				return true;
			} else {
				// 未改动 LAN IP 的常规操作，保留原生的回滚自愈保护
				return ui.changes.apply(mode == '0');
			}
		});
	},

	handleReset: null
});
