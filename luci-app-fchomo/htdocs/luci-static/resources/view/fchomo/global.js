'use strict';
'require form';
'require fs';
'require network';
'require poll';
'require rpc';
'require uci';
'require ui';
'require view';

'require fchomo as hm';
'require tools.firewall as fwtool';
'require tools.widgets as widgets';

const callResVersion = rpc.declare({
	object: 'luci.fchomo',
	method: 'resources_get_version',
	params: ['type', 'repo'],
	expect: { '': {} }
});

const callCrondSet = rpc.declare({
	object: 'luci.fchomo',
	method: 'crond_set',
	params: ['type', 'expr'],
	expect: { '': {} }
});

function getRandom(min, max) {
	const floatRandom = Math.random()
	const difference = max - min

	// A random number between 0 and the difference
	const random = Math.round(difference * floatRandom)

	return random + min
}

function handleResUpdate(type, repo) {
	const callResUpdate = rpc.declare({
		object: 'luci.fchomo',
		method: 'resources_update',
		params: ['type', 'repo'],
		expect: { '': {} }
	});

	// Dynamic repo
	let label;
	if (repo) {
		const section_id = this.section.section;
		let weight = document.getElementById(this.cbid(section_id));
		if (weight)
			repo = weight.firstChild.value,
			label = weight.firstChild.selectedOptions[0].label;
	}

	return L.resolveDefault(callResUpdate(type, repo), {}).then((res) => {
		switch (res.status) {
		case 0:
			this.description = (repo ? label + ' ' : '') + _('Successfully updated.');
			break;
		case 1:
			this.description = (repo ? label + ' ' : '') + _('Update failed.');
			break;
		case 2:
			this.description = (repo ? label + ' ' : '') + _('Already in updating.');
			break;
		case 3:
			this.description = (repo ? label + ' ' : '') + _('Already at the latest version.');
			break;
		default:
			this.description = (repo ? label + ' ' : '') + _('Unknown error.');
			break;
		}

		return this.map.reset();
	});
}

function renderResVersion(El, type, repo) {
	return L.resolveDefault(callResVersion(type, repo), {}).then((res) => {
		let resEl = E([
			E('button', {
				'class': 'cbi-button cbi-button-apply',
				'click': ui.createHandlerFn(this, handleResUpdate, type, repo)
			}, [ _('Check update') ]),
			updateResVersion(E('span', { style: 'border: unset; font-weight: bold; align-items: center' }), res.version)
		]);

		if (El) {
			El.appendChild(resEl);
			El.lastChild.style.display = 'flex';
		} else
			El = resEl;

		return El;
	});
}

function updateResVersion(El, version) {
	if (El) {
		El.style.color = version ? 'green' : 'red';
		El.innerHTML = '&ensp;%s'.format(version || _('not found'));
	}

	return El;
}

return view.extend({
	load() {
		return Promise.all([
			uci.load('fchomo'),
			hm.getFeatures(),
			network.getHostHints(),
			hm.getServiceStatus('mihomo-c'),
			hm.getClashAPI('mihomo-c'),
			hm.getServiceStatus('mihomo-s'),
			hm.getClashAPI('mihomo-s'),
			callResVersion('geoip').then((res) => { return res.version }),
			callResVersion('geosite').then((res) => { return res.version })
		]);
	},

	render(data) {
		const features = data[1];
		const hosts = data[2]?.hosts;
		const CisRunning = data[3];
		const CclashAPI = data[4];
		const SisRunning = data[5];
		const SclashAPI = data[6];
		const res_ver_geoip = data[7];
		const res_ver_geosite = data[8];

		const dashboard_repo = uci.get(data[0], 'api', 'dashboard_repo');

		let m, s, o, ss, so;

		m = new form.Map('fchomo', _('FullCombo Shark!'),
			'<img src="' + hm.sharktaikogif + '" title="A!" alt="Ciallo～(∠・ω< )⌒☆" height="52"></img>' +
			'<audio src="' + hm.sharkaudio + '" preload="auto" hidden=""></audio>');
		m.renderContents = function(/* ... */) {
			let node = form.Map.prototype.renderContents.apply(this, arguments);

			return node.then((mapEl) => {
				const playButton = mapEl.querySelector('.cbi-map-descr > img');
				const audio = mapEl.querySelector('.cbi-map-descr > audio');

				playButton.addEventListener('click', () => {
					if (audio.paused)
						audio.play();
				});

				return mapEl;
			});
		}

		s = m.section(form.NamedSection, 'config', 'fchomo');

		/* Overview START */
		s.tab('status', _('Overview'));

		/* Service status */
		o = s.taboption('status', form.SectionValue, '_status', form.NamedSection, 'config', 'fchomo', _('Service status'));
		ss = o.subsection;

		so = ss.option(form.DummyValue, '_core_version', _('Core version'));
		so.cfgvalue = function() {
			return E('strong', [features.core_version || _('Unknown')]);
		}

		so = ss.option(form.DummyValue, '_app_version', _('Application version'));
		so.cfgvalue = function() {
			return E('strong', [features.app_version || _('Unknown')]);
		}

		so = ss.option(form.DummyValue, '_client_status', _('Client status'));
		so.cfgvalue = function() { return hm.renderStatus('_client_bar', CisRunning ? { ...CclashAPI, dashboard_repo: dashboard_repo } : false, 'mihomo-c') }
		poll.add(function() {
			return hm.getServiceStatus('mihomo-c').then((isRunning) => {
				hm.updateStatus(document.getElementById('_client_bar'), isRunning ? { dashboard_repo: dashboard_repo } : false, 'mihomo-c');
			});
		})

		so = ss.option(form.DummyValue, '_server_status', _('Server status'));
		so.cfgvalue = function() { return hm.renderStatus('_server_bar', SisRunning ? { ...SclashAPI, dashboard_repo: dashboard_repo } : false, 'mihomo-s') }
		poll.add(function() {
			return hm.getServiceStatus('mihomo-s').then((isRunning) => {
				hm.updateStatus(document.getElementById('_server_bar'), isRunning ? { dashboard_repo: dashboard_repo } : false, 'mihomo-s');
			});
		})

		so = ss.option(form.Button, '_reload', _('Reload All'));
		so.inputtitle = _('Reload');
		so.inputstyle = 'apply';
		so.onclick = L.bind(hm.handleReload, so, null);

		so = ss.option(form.DummyValue, '_conn_check', _('Connection check'));
		so.cfgvalue = function() {
			const callConnStat = rpc.declare({
				object: 'luci.fchomo',
				method: 'connection_check',
				params: ['url'],
				expect: { '': {} }
			});

			const ElId = '_connection_check_results';

			return E([
				E('button', {
					'class': 'cbi-button cbi-button-apply',
					'click': ui.createHandlerFn(this, () => {
						let weight = document.getElementById(ElId);

						weight.innerHTML = '';
						return hm.checkurls.forEach((site) => {
							L.resolveDefault(callConnStat(site[0]), {}).then((res) => {
								weight.innerHTML += '<span style="color:%s">&ensp;%s</span>'.format((res.httpcode && res.httpcode.match(/^20\d$/)) ? 'green' : 'red', site[1]);
							});
						});
					})
				}, [ _('Check') ]),
				E('strong', { id: ElId }, [
					E('span', { style: 'color:gray' }, ' ' + _('unchecked'))
				])
			]);
		}

		so = ss.option(form.Value, '_nattest', _('Check routerself NAT Behavior'));
		so.default = `udp://${hm.stunserver[0][0]}`;
		hm.stunserver.forEach((res) => {
			so.value.apply(so, res);
		})
		so.rmempty = false;
		if (!features.has_stunclient) {
			so.description = _('To check NAT Behavior you need to install <a href="%s"><b>%s</b></a> first')
				.format(L.url('admin/system/package-manager') + '?query=stuntman-client', 'stuntman-client');
			so.readonly = true;
		} else {
			so.renderWidget = function(section_id, option_index, cfgvalue) {
				const cval = new URL(cfgvalue || this.default);
				//console.info(cval.toString());
				let El = form.Value.prototype.renderWidget.call(this, section_id, option_index, cval.host);

				let resEl = E('div',  { 'class': 'control-group' }, [
					E('select', {
						'id': '_status_nattest_l4proto',
						'class': 'cbi-input-select',
						'style': 'width: 5em'
					}, [
						...[
							['udp', 'UDP'], // default
							['tcp', 'TCP']
						].map(res => E('option', {
								value: res[0],
								selected: (cval.protocol === `${res[0]}:`) ? "" : null
							}, res[1]))
					]),
					E('button', {
						'class': 'cbi-button cbi-button-apply',
						'click': ui.createHandlerFn(this, () => {
							const stun = this.formvalue(this.section.section);
							const l4proto = document.getElementById('_status_nattest_l4proto').value;

							return fs.exec_direct('/usr/libexec/fchomo/natcheck.sh', [stun, l4proto, getRandom(32768, 61000)]).then((stdout) => {
								this.description = '<details><summary>' + _('Expand/Collapse result') + '</summary>' + stdout + '</details>';

								return this.map.reset().then((res) => {
								});
							});
						})
					}, [ _('Check') ])
				]);
				ui.addValidator(resEl.querySelector('#_status_nattest_l4proto'), 'string', false, (v) => {
					const section_id = this.section.section;
					const stun = this.formvalue(section_id);

					this.onchange.call(this, {}, section_id, stun);
					return true;
				}, 'change');

				let newEl = E('div', { style: 'font-weight: bold; align-items: center; display: flex' }, []);
				if (El) {
					newEl.appendChild(E([El, resEl]));
				} else
					newEl.appendChild(resEl);

				return newEl;
			}
		}
		so.onchange = function(ev, section_id, value) {
			const l4proto = document.getElementById('_status_nattest_l4proto').value;
			this.default = `${l4proto}://${value}`;
		}
		so.write = function() {};
		so.remove = function() {};

		/* Resources management */
		o = s.taboption('status', form.SectionValue, '_config', form.NamedSection, 'resources', 'fchomo', _('Resources management'));
		ss = o.subsection;

		if (!res_ver_geoip || !res_ver_geosite) {
			so = ss.option(form.Button, '_upload_initia', _('Upload initial package'),
				_('Click <a target="_blank" href="%s" rel="noreferrer noopener">here</a> to download the latest initial package.')
					.format('https://raw.githubusercontent.com/fcshark-org/openwrt-fchomo/refs/heads/initialpack/initial.tgz'));
			so.inputstyle = 'action';
			so.inputtitle = _('Upload...');
			so.onclick = hm.uploadInitialPack;
		}

		so = ss.option(form.Flag, 'auto_update', _('Auto update'),
			_('Auto update resources.'));
		so.default = so.disabled;
		so.rmempty = false;
		so.write = function(section_id, formvalue) {
			if (formvalue == 1) {
				callCrondSet('resources', uci.get(data[0], section_id, 'auto_update_expr'));
			} else
				callCrondSet('resources');

			return this.super('write', section_id, formvalue);
		}

		so = ss.option(form.Value, 'auto_update_expr', _('Cron expression'),
			_('The default value is 2:00 every day.'));
		so.default = '0 2 * * *';
		so.placeholder = '0 2 * * *';
		so.rmempty = false;
		so.retain = true;
		so.depends('auto_update', '1');
		so.write = function(section_id, formvalue) {
			callCrondSet('resources', formvalue);

			return this.super('write', section_id, formvalue);
		};
		so.remove = function(section_id) {
			callCrondSet('resources');

			return this.super('remove', section_id);
		};

		so = ss.option(form.ListValue, '_dashboard_version', _('Dashboard version'));
		so.default = hm.dashrepos[0][0];
		hm.dashrepos.forEach((repo) => {
			so.value.apply(so, repo);
		})
		so.renderWidget = function(/* ... */) {
			let El = form.ListValue.prototype.renderWidget.apply(this, arguments);

			El.classList.add('control-group');
			El.firstChild.style.width = '10em';

			return renderResVersion.call(this, El, 'dashboard', this.default);
		}
		so.onchange = function(ev, section_id, value) {
			this.default = value;

			let weight = ev.target;
			if (weight)
				return L.resolveDefault(callResVersion('dashboard', value), {}).then((res) => {
					updateResVersion(weight.lastChild, res.version);
				});
		}
		so.write = function() {};

		so = ss.option(form.DummyValue, '_geoip_version', _('GeoIP version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'geoip') };

		so = ss.option(form.DummyValue, '_geosite_version', _('GeoSite version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'geosite') };

		so = ss.option(form.DummyValue, '_asn_version', _('ASN version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'asn') };

		so = ss.option(form.DummyValue, '_china_ip4_version', _('China IPv4 list version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'china_ip4') };

		so = ss.option(form.DummyValue, '_china_ip6_version', _('China IPv6 list version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'china_ip6') };

		so = ss.option(form.DummyValue, '_gfw_list_version', _('GFW list version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'gfw_list') };

		so = ss.option(form.DummyValue, '_china_list_version', _('China list version'));
		so.cfgvalue = function() { return renderResVersion.call(this, null, 'china_list') };
		/* Overview END */

		/* General START */
		s.tab('general', _('General'));

		/* General settings */
		o = s.taboption('general', form.SectionValue, '_global', form.NamedSection, 'global', 'fchomo', _('General settings'));
		ss = o.subsection;

		so = ss.option(form.ListValue, 'mode', _('Operation mode'));
		so.value('direct', _('Direct'));
		so.value('rule', _('Rule'));
		so.value('global', _('Global'));
		so.default = 'rule';

		so = ss.option(form.ListValue, 'find_process_mode', _('Process matching mode'));
		so.value('always', _('Enable'));
		so.value('strict', _('Auto'));
		so.value('off', _('Disable'));
		so.default = 'off';

		so = ss.option(form.ListValue, 'log_level', _('Log level'));
		so.default = 'warning';
		hm.log_levels.forEach((res) => {
			so.value.apply(so, res);
		})

		so = ss.option(form.Flag, 'etag_support', _('ETag support'));
		so.default = so.enabled;

		so = ss.option(form.Flag, 'ipv6', _('IPv6 support'));
		so.default = so.enabled;

		so = ss.option(form.Flag, 'unified_delay', _('Unified delay'));
		so.default = so.disabled;

		so = ss.option(form.Flag, 'tcp_concurrent', _('TCP concurrency'));
		so.default = so.disabled;

		so = ss.option(form.Value, 'keep_alive_interval', _('TCP-Keep-Alive interval'),
			_('In seconds. <code>%s</code> will be used if empty.').format('30'));
		so.placeholder = '30';
		so.validate = hm.validateTimeDuration;

		so = ss.option(form.Value, 'keep_alive_idle', _('TCP-Keep-Alive idle timeout'),
			_('In seconds. <code>%s</code> will be used if empty.').format('600'));
		so.placeholder = '600';
		so.validate = hm.validateTimeDuration;

		/* Global Authentication */
		o = s.taboption('general', form.SectionValue, '_global', form.NamedSection, 'global', 'fchomo', _('Global Authentication'));
		ss = o.subsection;

		so = ss.option(form.DynamicList, 'authentication', _('User Authentication'));
		so.datatype = 'list(string)';
		so.placeholder = 'user1:pass1';
		so.validate = hm.validateAuth;

		so = ss.option(form.DynamicList, 'skip_auth_prefixes', _('No Authentication IP ranges'));
		so.datatype = 'list(cidr)';
		so.placeholder = '127.0.0.1/8';
		/* General END */

		/* Inbound START */
		s.tab('inbound', _('Inbound'));

		/* Listen ports */
		o = s.taboption('inbound', form.SectionValue, '_inbound', form.NamedSection, 'inbound', 'fchomo', _('Listen ports'));
		ss = o.subsection;

		so = ss.option(form.Value, 'mixed_port', _('Mixed port'));
		so.datatype = 'port';
		so.placeholder = '7890';
		so.rmempty = false;

		so = ss.option(form.Value, 'redir_port', _('Redir port'));
		so.datatype = 'port';
		so.placeholder = '7891';
		so.rmempty = false;

		so = ss.option(form.Value, 'tproxy_port', _('Tproxy port'));
		so.datatype = 'port';
		so.placeholder = '7892';
		so.rmempty = false;

		// @Not required for v1.19.2+
		so = ss.option(form.Value, 'tunnel_port', _('DNS port'));
		so.datatype = 'port';
		so.placeholder = '7893';
		so.rmempty = false;

		so = ss.option(form.ListValue, 'proxy_mode', _('Proxy mode'));
		so.value('redir', _('Redirect TCP'));
		if (features.has_tproxy)
			so.value('redir_tproxy', _('Redirect TCP + TProxy UDP'));
		if (features.has_ip_full && features.has_tun) {
			so.value('redir_tun', _('Redirect TCP + Tun UDP'));
			so.value('tun', _('Tun TCP/UDP'));
		} else
			so.description = _('To enable Tun support, you need to install <code>ip-full</code> and <code>kmod-tun</code>');
		so.default = 'redir_tproxy';
		so.rmempty = false;

		/* Tun settings */
		o = s.taboption('inbound', form.SectionValue, '_inbound', form.NamedSection, 'inbound', 'fchomo', _('Tun settings'));
		ss = o.subsection;

		so = ss.option(form.RichListValue, 'tun_stack', _('Stack'),
			_('Tun stack.'));
		so.value('system', _('System'), _('Less compatibility and sometimes better performance.'));
		if (features.with_gvisor) {
			so.value('gvisor', _('gVisor'), _('Based on google/gvisor.'));
			so.value('mixed', _('Mixed'), _('Mixed <code>system</code> TCP stack and <code>gVisor</code> UDP stack.'));
		}
		so.default = 'system';
		so.rmempty = false;

		so = ss.option(form.Value, 'tun_mtu', _('MTU'));
		so.datatype = 'uinteger';
		so.placeholder = '9000';

		so = ss.option(form.Flag, 'tun_gso', _('Generic segmentation offload'));
		so.default = so.disabled;

		so = ss.option(form.Value, 'tun_gso_max_size', _('Segment maximum size'));
		so.datatype = 'uinteger';
		so.placeholder = '65536';

		so = ss.option(form.Value, 'tun_udp_timeout', _('UDP NAT expiration time'),
			_('Aging time of NAT map maintained by client.</br>') +
			_('In seconds. <code>%s</code> will be used if empty.').format('300'));
		so.placeholder = '300';
		so.validate = hm.validateTimeDuration;

		so = ss.option(form.Flag, 'tun_endpoint_independent_nat', _('Endpoint-Independent NAT'),
			_('Performance may degrade slightly, so it is not recommended to enable on when it is not needed.'));
		so.default = so.disabled;

		so = ss.option(form.Flag, 'tun_disable_icmp_forwarding', _('Disable ICMP Forwarding'),
			_('Prevent ICMP loopback issues in some cases. Ping will not show real delay.'));
		so.default = so.enabled;
		/* Inbound END */

		/* TLS START */
		s.tab('tls', _('TLS'));

		/* TLS settings */
		o = s.taboption('tls', form.SectionValue, '_tls', form.NamedSection, 'tls', 'fchomo', null);
		ss = o.subsection;

		so = ss.option(form.ListValue, 'global_client_fingerprint', _('Global client fingerprint'));
		so.default = hm.tls_client_fingerprints[0][0];
		hm.tls_client_fingerprints.forEach((res) => {
			so.value.apply(so, res);
		})

		so = ss.option(form.Value, 'tls_cert_path', _('API TLS certificate path'));
		so.datatype = 'file';
		so.value('/etc/ssl/acme/example.crt');

		so = ss.option(form.Value, 'tls_key_path', _('API TLS private key path'));
		so.datatype = 'file';
		so.value('/etc/ssl/acme/example.key');

		so = ss.option(form.ListValue, 'tls_client_auth_type', _('API Client Auth type') + _(' (mTLS)'));
		so.default = hm.tls_client_auth_types[0][0];
		hm.tls_client_auth_types.forEach((res) => {
			so.value.apply(so, res);
		})

		so = ss.option(form.Value, 'tls_client_auth_cert_path', _('API Client Auth Certificate path') + _(' (mTLS)'),
			_('The %s public key, in PEM format.').format(_('Client')));
		so.value('/etc/fchomo/certs/client_publickey.pem');
		so.validate = L.bind(hm.validateMTLSClientAuth, so, 'tls_client_auth_type');

		so = ss.option(hm.GenText, 'tls_ech_key', _('API ECH key'));
		so.placeholder = '-----BEGIN ECH KEYS-----\nACATwY30o/RKgD6hgeQxwrSiApLaCgU+HKh7B6SUrAHaDwBD/g0APwAAIAAgHjzK\nmadSJjYQIf9o1N5GXjkW4DEEeb17qMxHdwMdNnwADAABAAEAAQACAAEAAwAIdGVz\ndC5jb20AAA==\n-----END ECH KEYS-----';
		so.hm_placeholder = 'outer-sni.any.domain';
		so.cols = 30
		so.rows = 2;
		so.hm_options = {
			type: 'ech-keypair',
			params: '',
			callback: function(result) {
				return [
					[this.option, result.ech_key],
					['tls_ech_cfg', result.ech_cfg]
				]
			}
		}
		so.renderWidget = function(section_id, option_index, cfgvalue) {
			let node = hm.TextValue.prototype.renderWidget.call(this, section_id, option_index, cfgvalue);
			const cbid = this.cbid(section_id) + '._outer_sni';

			node.appendChild(E('div',  { 'class': 'control-group' }, [
				E('input', {
					id: cbid,
					class: 'cbi-input-text',
					style: 'width: 10em',
					placeholder: this.hm_placeholder
				}),
				E('button', {
					class: 'cbi-button cbi-button-add',
					click: ui.createHandlerFn(this, () => {
						this.hm_options.params = document.getElementById(cbid).value;

						return hm.handleGenKey.call(this, this.hm_options);
					})
				}, [ _('Generate') ])
			]));

			return node;
		}

		so = ss.option(form.Value, 'tls_ech_cfg', _('API ECH config'),
			_('This ECH parameter needs to be added to the HTTPS record of the domain.'));
		so.placeholder = 'AEn+DQBFKwAgACABWIHUGj4u+PIggYXcR5JF0gYk3dCRioBW8uJq9H4mKAAIAAEAAQABAANAEnB1YmxpYy50bHMtZWNoLmRldgAA';
		/* TLS END */

		/* API START */
		s.tab('api', _('API'));

		/* API settings */
		o = s.taboption('api', form.SectionValue, '_api', form.NamedSection, 'api', 'fchomo', null);
		ss = o.subsection;

		so = ss.option(form.ListValue, 'dashboard_repo', _('Select Dashboard'));
		so.default = hm.dashrepos[0][0];
		so.load = function(section_id) {
			delete this.keylist;
			delete this.vallist;

			hm.dashrepos.forEach((repo) => {
				L.resolveDefault(callResVersion('dashboard', repo[0]), {}).then((res) => {
					this.value(repo[0], repo[1] + ' - ' + (res.version || _('Not Installed')));
				});
			});

			return this.super('load', section_id);
		}
		so.rmempty = false;

		so = ss.option(form.DynamicList, 'external_controller_cors_allow_origins', _('CORS Allow origins'),
			_('CORS allowed origins, <code>*</code> will be used if empty.'));
		so.placeholder = 'https://board.zash.run.place';

		so = ss.option(form.Flag, 'external_controller_cors_allow_private_network', _('CORS Allow private network'),
			_('Allow access from private network.</br>' +
			'To access the API on a private network from a public website, it must be enabled.'));
		so.default = so.enabled;

		so = ss.option(form.Value, 'external_controller_port', _('API HTTP port'));
		so.datatype = 'port';
		so.placeholder = '9090';

		so = ss.option(form.Value, 'external_controller_tls_port', _('API HTTPS port'));
		so.datatype = 'port';
		so.placeholder = '9443';
		so.depends({'fchomo.tls.tls_cert_path': /^\/.+/, 'fchomo.tls.tls_key_path': /^\/.+/});

		so = ss.option(form.Value, 'external_doh_server', _('API DoH service'));
		so.placeholder = '/dns-query';
		so.depends({'external_controller_tls_port': /\d+/});

		so = ss.option(form.Value, 'secret', _('API secret'),
			_('Random will be used if empty.'));
		so.password = true;
		/* API END */

		/* Sniffer START */
		s.tab('sniffer', _('Sniffer'));

		/* Sniffer settings */
		o = s.taboption('sniffer', form.SectionValue, '_sniffer', form.NamedSection, 'sniffer', 'fchomo', _('Sniffer settings'));
		ss = o.subsection;

		so = ss.option(form.Flag, 'override_destination', _('Override destination'),
			_('Override the connection destination address with the sniffed domain.'));
		so.default = so.enabled;

		so = ss.option(form.DynamicList, 'force_domain', _('Forced sniffing domain'));
		so.datatype = 'list(string)';

		so = ss.option(form.DynamicList, 'skip_domain', _('Skiped sniffing domain'));
		so.datatype = 'list(string)';

		so = ss.option(form.DynamicList, 'skip_src_address', _('Skiped sniffing src address'));
		so.datatype = 'list(cidr)';

		so = ss.option(form.DynamicList, 'skip_dst_address', _('Skiped sniffing dst address'));
		so.datatype = 'list(cidr)';

		/* Sniff protocol settings */
		o = s.taboption('sniffer', form.SectionValue, '_sniffer_sniff', form.GridSection, 'sniff', _('Sniff protocol'));
		ss = o.subsection;
		ss.anonymous = true;
		ss.addremove = false;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;

		so = ss.option(form.ListValue, 'protocol', _('Protocol'));
		so.value('HTTP');
		so.value('TLS');
		so.value('QUIC');
		so.readonly = true;

		so = ss.option(form.DynamicList, 'ports', _('Ports'));
		so.datatype = 'list(or(port, portrange))';

		so = ss.option(form.Flag, 'override_destination', _('Override destination'));
		so.default = so.enabled;
		so.editable = true;
		/* Sniffer END */

		/* Experimental START */
		s.tab('experimental', _('Experimental'));

		/* Experimental settings */
		o = s.taboption('experimental', form.SectionValue, '_experimental', form.NamedSection, 'experimental', 'fchomo', null);
		ss = o.subsection;

		so = ss.option(form.Flag, 'skip_safe_path_check', _('Disable safe path check'));
		so.default = so.disabled;

		so = ss.option(form.Flag, 'quic_go_disable_gso', _('Disable GSO of quic-go'));
		so.default = so.disabled;

		so = ss.option(form.Flag, 'quic_go_disable_ecn', _('Disable ECN of quic-go'));
		so.default = so.disabled;

		so = ss.option(form.Flag, 'dialer_ip4p_convert', _('Enable <a target="_blank" href="%s" rel="noreferrer noopener">IP4P</a> conversion for outbound connections')
			.format('https://github.com/heiher/natmap/wiki/faq#%E5%9F%9F%E5%90%8D%E8%AE%BF%E9%97%AE%E6%98%AF%E5%A6%82%E4%BD%95%E5%AE%9E%E7%8E%B0%E7%9A%84'));
		so.default = so.disabled;
		/* Experimental END */

		/* ACL START */
		s.tab('control', _('Access Control'));

		/* Access Control settings */
		o = s.taboption('control', form.SectionValue, '_control', form.NamedSection, 'routing', 'fchomo', null);
		ss = o.subsection;

		/* Interface control */
		ss.tab('interface', _('Interface Control'));

		so = ss.taboption('interface', widgets.DeviceSelect, 'listen_interfaces', _('Listen interfaces'),
			_('Only process traffic from specific interfaces. Leave empty for all.'));
		so.multiple = true;
		so.noaliases = true;

		so = ss.taboption('interface', widgets.DeviceSelect, 'bind_interface', _('Bind interface'),
			_('Bind outbound traffic to specific interface. Leave empty to auto detect.</br>') +
			_('Priority: Proxy Node > Global.'));
		so.multiple = false;
		so.noaliases = true;

		so = ss.taboption('interface', form.Value, 'route_table_id', _('Routing table ID'));
		so.ucisection = 'config';
		so.datatype = 'uinteger';
		so.placeholder = '2022';
		so.rmempty = false;

		so = ss.taboption('interface', form.Value, 'route_rule_pref', _('Routing rule priority'));
		so.ucisection = 'config';
		so.datatype = 'uinteger';
		so.placeholder = '9000';
		so.rmempty = false;

		so = ss.taboption('interface', form.Value, 'self_mark', _('Routing mark (Fwmark)'),
			_('Priority: Proxy Node > Global.'));
		so.ucisection = 'config';
		so.datatype = 'uinteger';
		so.placeholder = '200';
		so.rmempty = false;

		so = ss.taboption('interface', form.Value, 'tproxy_mark', _('Tproxy Fwmark/fwmask'));
		so.ucisection = 'config';
		so.placeholder = '201 or 0xc9/0xff';
		so.rmempty = false;

		so = ss.taboption('interface', form.Value, 'tun_mark', _('Tun Fwmark/fwmask'));
		so.ucisection = 'config';
		so.placeholder = '202 or 0xca/0xff';
		so.rmempty = false;

		/* Access control */
		ss.tab('access_control', _('Access Control'));

		so = ss.taboption('access_control', form.ListValue, 'lan_filter', _('Users filter mode'));
		so.value('', _('All allowed'));
		so.value('white_list', _('White list'));
		so.value('black_list', _('Black list'));

		so = fwtool.addIPOption(ss, 'access_control', 'lan_direct_ipv4_ips', _('Direct IPv4 IP-s'), null, 'ipv4', hosts, true);
		so.depends('lan_filter', 'black_list');

		so = fwtool.addIPOption(ss, 'access_control', 'lan_direct_ipv6_ips', _('Direct IPv6 IP-s'), null, 'ipv6', hosts, true);
		so.depends({'lan_filter': 'black_list', 'fchomo.global.ipv6': '1'});

		so = fwtool.addMACOption(ss, 'access_control', 'lan_direct_mac_addrs', _('Direct MAC-s'), null, hosts);
		so.depends('lan_filter', 'black_list');

		so = fwtool.addIPOption(ss, 'access_control', 'lan_proxy_ipv4_ips', _('Proxy IPv4 IP-s'), null, 'ipv4', hosts, true);
		so.depends('lan_filter', 'white_list');

		so = fwtool.addIPOption(ss, 'access_control', 'lan_proxy_ipv6_ips', _('Proxy IPv6 IP-s'), null, 'ipv6', hosts, true);
		so.depends({'lan_filter': 'white_list', 'fchomo.global.ipv6': '1'});

		so = fwtool.addMACOption(ss, 'access_control', 'lan_proxy_mac_addrs', _('Proxy MAC-s'), null, hosts);
		so.depends('lan_filter', 'white_list');

		so = ss.taboption('access_control', form.Flag, 'proxy_router', _('Proxy routerself'));
		so.default = so.enabled;

		so = ss.taboption('access_control', form.Flag, 'top_upstream', _('As the TOP upstream of dnsmasq'),
			_('As the TOP upstream of dnsmasq.'));
		so.default = so.disabled;
		so.validate = function(section_id, value) {
			let desc = this.getUIElement(section_id).node.nextSibling;
			value = this.formvalue(section_id);

			if (value == 1)
				desc.innerHTML = _('As the TOP upstream of dnsmasq.');
			else
				desc.innerHTML = _('dnsmasq selects upstream on its own. (may affect CDN accuracy)');

			return true;
		}

		/* Routing control */
		ss.tab('routing_control', _('Routing Control'));

		so = ss.taboption('routing_control', hm.RichMultiValue, 'routing_tcpport', _('Routing ports') + ' (TCP)',
			_('Specify target ports to be proxied. Multiple ports must be separated by commas.'));
		so.create = true;
		hm.routing_port_type.forEach((res) => {
			if (!res[0].match(/_udpport$/))
				so.value.apply(so, res);
		})
		so.validate = hm.validateCommonPort;

		so = ss.taboption('routing_control', hm.RichMultiValue, 'routing_udpport', _('Routing ports') + ' (UDP)',
			_('Specify target ports to be proxied. Multiple ports must be separated by commas.'));
		so.create = true;
		hm.routing_port_type.forEach((res) => {
			if (!res[0].match(/_tcpport$/))
				so.value.apply(so, res);
		})
		so.validate = hm.validateCommonPort;

		so = ss.taboption('routing_control', form.ListValue, 'routing_mode', _('Routing mode'),
			_('Routing mode of the traffic enters mihomo via firewall rules.'));
		so.value('', _('All allowed'));
		so.value('bypass_cn', _('Bypass CN'));
		so.value('routing_gfw', _('Routing GFW'));

		so = ss.taboption('routing_control', form.Flag, 'routing_domain', _('Handle domain'),
			_('Routing mode will be handle domain.') + '</br>' +
			_('Please ensure that the DNS query of the domains to be processed in the DNS policy</br>' +
				'are send via DIRECT/Proxy Node in the same semantics as Routing mode.'));
		so.default = so.disabled;
		if (!features.has_dnsmasq_full) {
			so.description = _('To enable, you need to install <code>dnsmasq-full</code>.');
			so.readonly = true;
			uci.set(data[0], so.section.section, so.option, '');
			uci.save();
		}
		so.depends('routing_mode', 'bypass_cn');
		so.depends('routing_mode', 'routing_gfw');

		so = ss.taboption('routing_control', form.ListValue, 'routing_dscp_mode', _('Routing DSCP'));
		so.value('', _('All allowed'));
		so.value('bypass_dscp', _('Bypass DSCP'));
		so.value('routing_dscp', _('Routing DSCP'));

		so = ss.taboption('routing_control', form.Value, 'routing_dscp_list', _('DSCP list'));
		so.placeholder = '0,10,12,14,63';
		so.validate = function(section_id, value) {
			if (!value)
				return true;
			else if (value.match('^(6[0-3]|[1-5]?[0-9])(,(6[0-3]|[1-5]?[0-9]))*$') === null)
				return _('Expecting: %s').format(_('One or more numbers in the range 0-63 separated by commas'));

			return true;
		}
		so.rmempty = false;
		so.depends('routing_dscp_mode', 'bypass_dscp');
		so.depends('routing_dscp_mode', 'routing_dscp');

		/* Custom Direct list */
		ss.tab('direct_list', _('Custom Direct List'));

		so = ss.taboption('direct_list', hm.TextValue, 'direct_list.yaml', null);
		so.rows = 20;
		so.default = 'DOMAIN:\nIPCIDR:\nIPCIDR6:\n';
		so.placeholder = "DOMAIN:\n- mask.icloud.com\n- mask-h2.icloud.com\n- mask.apple-dns.net\nIPCIDR:\n- '223.0.0.0/12'\nIPCIDR6:\n- '2400:3200::/32'\n";
		so.load = function(section_id) {
			return L.resolveDefault(hm.readFile('resources', this.option), '');
		}
		so.write = function(section_id, formvalue) {
			return hm.writeFile('resources', this.option, formvalue);
		}
		so.remove = function(section_id) {
			return hm.writeFile('resources', this.option);
		}
		so.rmempty = false;

		/* Custom Proxy list */
		ss.tab('proxy_list', _('Custom Proxy List'));

		so = ss.taboption('proxy_list', hm.TextValue, 'proxy_list.yaml', null);
		so.rows = 20;
		so.default = 'DOMAIN:\nIPCIDR:\nIPCIDR6:\n';
		so.placeholder = "DOMAIN:\n- www.google.com\n- '.googlevideo.com'\n- google.com\nIPCIDR:\n- '91.105.192.0/23'\nIPCIDR6:\n- '2001:67c:4e8::/48'\n";
		so.load = function(section_id) {
			return L.resolveDefault(hm.readFile('resources', this.option), '');
		}
		so.write = function(section_id, formvalue) {
			return hm.writeFile('resources', this.option, formvalue);
		}
		so.remove = function(section_id) {
			return hm.writeFile('resources', this.option);
		}
		so.rmempty = false;
		/* ACL END */

		return m.render();
	}
});
