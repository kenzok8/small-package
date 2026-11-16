'use strict';
'require form';
'require fs';
'require rpc';
'require view';
'require tools.widgets as widgets';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

function getInstances() {
	return L.resolveDefault(callServiceList('natmap'), {}).then(function(res) {
		try {
			return res.natmap.instances || {};
		} catch (e) {}
		return {};
	});
}

function getStatus() {
	return getInstances().then(function(instances) {
		var promises = [];
		var status = {};
		for (var key in instances) {
			var i = instances[key];
			if (i.running && i.pid) {
				var f = '/var/run/natmap/' + i.pid + '.json';
				(function(k) {
					promises.push(fs.read(f).then(function(res) {
						status[k] = JSON.parse(res);
					}).catch(function(e){}));
				})(key);
			}
		}
		return Promise.all(promises).then(function() { return status; });
	});
}

return view.extend({
	load: function() {
		return getStatus();
	},
	render: function(status) {
		var m, s, o;

		m = new form.Map('natmap', _('NATMap'));
		s = m.section(form.GridSection, 'natmap');
		s.addremove = true;
		s.anonymous = true;

		s.tab('general', _('General Settings'));
		s.tab('notify', _('Notify Settings'));
		s.tab('link', _('Link Settings'));
		
		o = s.option(form.DummyValue, '_nat_name', _('Name'));
		o.modalonly = false;
		o.textvalue = function(section_id) {
			var s = status[section_id];
			if (s) return s.name;
		};

		o = s.taboption('general', form.Value, 'nat_name', _('Name'));
		o.datatype = 'string';
		o.modalonly = true;

		o = s.taboption('general', form.ListValue, 'udp_mode', _('Protocol'));
		o.default = '1';
		o.value('0', 'TCP');
		o.value('1', 'UDP');
		o.textvalue = function(section_id) {
			var cval = this.cfgvalue(section_id);
			var i = this.keylist.indexOf(cval);
			return this.vallist[i];
		};

		o = s.taboption('general', form.ListValue, 'family', _('Restrict to address family'));
		o.modalonly = true;
		o.value('', _('IPv4 and IPv6'));
		o.value('ipv4', _('IPv4 only'));
		o.value('ipv6', _('IPv6 only'));

		o = s.taboption('general', widgets.NetworkSelect, 'interface', _('Interface'));
		o.modalonly = true;

		o = s.taboption('general', form.Value, 'interval', _('Keep-alive interval'));
		o.datatype = 'uinteger';
		o.modalonly = true;

		o = s.taboption('general', form.Value, 'stun_server', _('STUN server'));
		o.datatype = 'host';
		o.modalonly = true;
		o.optional = false;
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'http_server', _('HTTP server'), _('For TCP mode'));
		o.datatype = 'host';
		o.modalonly = true;
		o.rmempty = false;

		o = s.taboption('general', form.Value, 'port', _('Bind port'));
		o.datatype = 'port';
		o.rmempty = false;

		o = s.taboption('general', form.Flag, '_forward_mode', _('Forward mode'));
		o.modalonly = true;
		o.ucioption = 'forward_target';
		o.load = function(section_id) {
			return this.super('load', section_id) ? '1' : '0';
		};
		o.write = function(section_id, formvalue) {};

		o = s.taboption('general', form.Value, 'forward_target', _('Forward target'));
		o.datatype = 'host';
		o.modalonly = true;
		o.depends('_forward_mode', '1');

		o = s.taboption('general', form.Value, 'forward_port', _('Forward target port'), _('0 will forward to the out port get from STUN'));
		o.datatype = 'port';
		o.modalonly = true;
		o.depends('_forward_mode', '1');

		o = s.taboption('general', form.Flag, 'forward_use_natmap', _('Forward use natmap'));
		o.editable = true;
		o.default = false;
		o.modalonly = true;

		o = s.taboption('general', form.Value, 'notify_script', _('Notify script'));
		o.datatype = 'file';
		o.modalonly = true;

		o = s.taboption('notify', form.Flag, 'im_notify_enable', _('Notify'));
		o.default = false;
		o.modalonly = true;

		o = s.taboption('notify', form.ListValue, 'im_notify_channel', _('Notify channel'));
		o.default = 'telegram_bot';
		o.modalonly = true;
		o.value('telegram_bot', _('Telegram Bot'));
		o.value('pushplus', _('PushPlus'));
		o.depends('im_notify_enable', '1');

		o = s.taboption('notify', form.Value, 'im_notify_channel_telegram_bot_chat_id', _('Chat ID'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('im_notify_channel', 'telegram_bot');

		o = s.taboption('notify', form.Value, 'im_notify_channel_telegram_bot_token', _('Token'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('im_notify_channel', 'telegram_bot');

		o = s.taboption('notify', form.Value, 'im_notify_channel_pushplus_token', _('Token'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('im_notify_channel', 'pushplus');

		o = s.taboption('link', form.Flag, '_link_to', _('Change another service\'s config'));
		o.modalonly = true;
		o.ucioption = 'mode';
		o.load = function(section_id) {
			return this.super('load', section_id) ? '1' : '0';
		};
		o.write = function(section_id, formvalue) {};

		o = s.taboption('link', form.ListValue, 'mode', _('Service'));
		o.default = 'qbittorrent';
		o.modalonly = true;
		o.value('emby', _('Emby'));
		o.value('qbittorrent', _('qBittorrent'));
		o.value('transmission', _('Transmission'));
		o.value('cloudflare_origin_rule', _('Cloudflare Origin Rule'));
		o.value('cloudflare_redirect_rule', _('Cloudflare Redirect Rule'));
		o.value('proxy_port', _('Proxy port'));
		o.depends('_link_to', '1');

		o = s.taboption('link', form.Value, 'cloudflare_email', _('Email'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'cloudflare_origin_rule');
		o.depends('mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'cloudflare_api_key', _('API Key'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'cloudflare_origin_rule');
		o.depends('mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'cloudflare_zone_id', _('Zone ID'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'cloudflare_origin_rule');
		o.depends('mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'cloudflare_rule_name', _('Rule Name'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'cloudflare_origin_rule');
		o.depends('mode', 'cloudflare_redirect_rule');
		
		o = s.taboption('link', form.Value, 'cloudflare_rule_target_url', _('Target URL'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'cloudflare_redirect_rule');

		o = s.taboption('link', form.Value, 'emby_url', _('URL'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'emby');

		o = s.taboption('link', form.Value, 'emby_api_key', _('API Key'));
		o.datatype = 'host';
		o.modalonly = true;
		o.depends('mode', 'emby');

		o = s.taboption('link', form.Flag, 'emby_use_https', _('Update HTTPS Port'), _('Set to False if you want to use HTTP'));
		o.default = false;
		o.modalonly = true;
		o.depends('mode', 'emby');

		o = s.taboption('link', form.Flag, 'emby_update_host_with_ip', _('Update host with IP'));
		o.default = false;
		o.modalonly = true;
		o.depends('mode', 'emby');

		o = s.taboption('link', form.Value, 'qb_web_ui_url', _('Web UI URL'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'qbittorrent');
		
		o = s.taboption('link', form.Value, 'qb_username', _('Username'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'qbittorrent');

		o = s.taboption('link', form.Value, 'qb_password', _('Password'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'qbittorrent');

		o = s.taboption('link', form.Flag, 'qb_allow_ipv6', _('Allow IPv6'));
		o.default = false;
		o.modalonly = true;
		o.depends('mode', 'qbittorrent');

		o = s.taboption('link', form.Value, 'qb_ipv6_address', _('IPv6 Address'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('qb_allow_ipv6', '1');

		o = s.taboption('link', form.Value, 'tr_rpc_url', _('RPC URL'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'transmission');
		
		o = s.taboption('link', form.Value, 'tr_username', _('Username'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'transmission');

		o = s.taboption('link', form.Value, 'tr_password', _('Password'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'transmission');

		o = s.taboption('link', form.Flag, 'tr_allow_ipv6', _('Allow IPv6'));
		o.modalonly = true;
		o.default = false;
		o.depends('mode', 'transmission');

		o = s.taboption('link', form.Value, 'tr_ipv6_address', _('IPv6 Address'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('tr_allow_ipv6', '1');

		o = s.taboption('link', form.Value, 'proxy_port_content_url', _('Content URL'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'proxy_port');
		
		o = s.taboption('link', form.Value, 'proxy_port_gist_id', _('Gist ID'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'proxy_port');

		o = s.taboption('link', form.Value, 'proxy_port_gist_filename', _('Gist Filename'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'proxy_port');

		o = s.taboption('link', form.Value, 'proxy_port_github_token', _('GitHub Token'));
		o.datatype = 'string';
		o.modalonly = true;
		o.depends('mode', 'proxy_port');


		o = s.option(form.DummyValue, '_external_ip', _('External IP'));
		o.modalonly = false;
		o.textvalue = function(section_id) {
			var s = status[section_id];
			if (s) return s.ip;
		};

		o = s.option(form.DummyValue, '_external_port', _('External Port'));
		o.modalonly = false;
		o.textvalue = function(section_id) {
			var s = status[section_id];
			if (s) return s.port;
		};

		o = s.option(form.Flag, 'enable', _('Enable'));
		o.editable = true;
		o.modalonly = false;

		return m.render();
	}
});
