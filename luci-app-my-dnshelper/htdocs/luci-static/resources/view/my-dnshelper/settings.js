'use strict';
'require form';
'require view';
'require fs';
'require uci';
'require poll';
'require rpc';

 var conf = 'my-dnshelper';
 var confh = 'https-dns-proxy';
 var dohright = true;
 var callServiceList = rpc.declare({
	 object: 'service',
	 method: 'list',
	 params: ['name'],
	 expect: { '': {} }
 });
 
function getServiceStatus() {
	return L.resolveDefault(callServiceList(conf), {})
		.then(function (res) {
			var isrunning = false;
			try {
				isrunning = res[conf]['instances']['my-dnshelper']['running'];
			} catch (e) { }
			return isrunning;
		});
}

function getServiceStatusH() {
	return L.resolveDefault(callServiceList(confh), {})
		.then(function (res) {
			var isrunning = false;
			try {
				isrunning = res[confh]['instances']['instance1']['running'];
				dohright = true;
			} catch (e) { dohright = false; }
			return isrunning;
		});
}

function helperServiceStatus() {
	return Promise.all([
		getServiceStatus(),
		getServiceStatusH(),
		L.resolveDefault(fs.exec('/bin/sh',['/usr/share/my-dnshelper/testdns']),''),
		L.resolveDefault(fs.exec('/usr/share/my-dnshelper/waiter',['--port']),''),
		L.resolveDefault(fs.exec('/usr/share/my-dnshelper/waiter',['--dns']),'')
	]);
}
 
function helperRenderStatus(res) {
	var renderHTML = "";
	var isRunning = res[0];
	var isRunningH = res[1];
	var isDnsOK = true;
	var p="";
	var dnso="";
	try {
		if (res[2]){
			if (res[2].code == 0 && res[2].stdout.trim() == "0" ){
				isDnsOK = true;
			}
			else{
				isDnsOK = false;
			}
		}
		if (res[3] && res[3].code == 0){
			p = res[3].stdout.trim();
		}
		if (res[4] && res[4].code == 0){
			dnso = res[4].stdout.trim();
		}

		if (isRunning) {
			renderHTML += "<span style=\"color:green;font-weight:bold\">" + _("DNS Helper") + " - " + _("RUNNING") + "</span>";
		} else {
			renderHTML += "<span style=\"color:red;font-weight:bold\">" + _("DNS Helper") + " - " + _("NOT RUNNING") + "</span>";
		}
		renderHTML +=" | ";
		if (isDnsOK) {
			renderHTML += "<span style=\"color:green;font-weight:bold\">" + _("DNS Status") + " - " + _("CHECK OK") + "</span>";
		} else {
			renderHTML += "<span style=\"color:red;font-weight:bold\">" + _("DNS Status") + " - " + _("ERROR DETECTED") + "</span>";
		}
		if (dohright) {
			renderHTML +=" | ";
			if (isRunningH) {
				renderHTML += "<span style=\"color:green;font-weight:bold\">" + _("DoH") + " - " + _("CONFIGURED") + " " + _("Port")+": "+ p +"</span>";
			} else {
				renderHTML += "<span style=\"color:red;font-weight:bold\">" + _("DoH") + " - " + _("NOT CONFIGURED") + "</span>";
			}
		}
		renderHTML += dnso;
	} catch (e) {}
	return renderHTML;
}

return view.extend({
	load: function(){
		return Promise.all([
			L.resolveDefault(fs.exec('/usr/share/my-dnshelper/waiter',['-m']),null)
		]);
	},
	render: function(stats){
		var m, s, o, v;
		v = '';
		
		if (stats[0] && stats[0].code == 0) {
			v = stats[0].stdout.trim();
		}
		
		m = new form.Map('my-dnshelper', _('DNS Helper'),
		_('A helper for DNS. It can help you configure dnsmasq and support filtering and DNS service settings. DoH is supported.')
		+ ' | <a href=\"https://github.com/kongfl888/openwrt-my-dnshelper/blob/main/README.cn\" target=\"_blank\" style=\"color:mediumturquoise\" >GITHUB</a>'
		+'<br/>'
		+v
		);
		
		s = m.section(form.NamedSection, '_status');
		s.anonymous = true;
		s.render = function (section_id) {
			var renderStatus = function () {
				return L.resolveDefault(helperServiceStatus()).then(function (res) {
					var view = document.getElementById("service_status");
					if (view == null) {
						return;
					}

					view.innerHTML = helperRenderStatus(res);
				});
			}
			poll.add(renderStatus);
			setTimeout(renderStatus, 5000);

			return E('div', { class: 'cbi-map' },
				E('div', { class: 'cbi-section' }, [
					E('div', { id: 'service_status' },
						_('Collecting data ...'))
				])
			);
		}

		s = m.section(form.TypedSection, 'my-dnshelper',  _('General settings'));
		s.anonymous = true;
		
		o = s.option(form.Flag, 'enable', _('Enable'));
		o.rmempty = false;
		o.default = 'false';
		
		o = s.option(form.Flag, "block_ios", _("Block iOS OTA update"));
		o.rmempty = false;
		o.default = 'false';

		o = s.option(form.Flag, "block_games", _("Block Games APP"));
		o.description = _("Make children's games time be controlled");
		o.rmempty = false;
		o.default = 'false';

		o = s.option(form.Flag, "block_short", _("Block Short video APP"));
		o.description = _("Protect children's physical and mental health");
		o.rmempty = false;
		o.default = 'false';

		o = s.option(form.Flag, "my_github", _("Easy to Visit GitHub Website"));
		o.rmempty = false;
		o.default = 'false';

		o = s.option(form.Flag, "autoupdate", _("Enable automatic update rules"));
		o.rmempty = false;
		o.default = 'true';

		o = s.option(form.Flag, "dns_check", _("Help to Network Check"));
		o.rmempty = false;
		o.default = 'true';

		o = s.option(form.Flag, "flash", _("Keep rules to route"), _("Avoid downloading again after restart, but the reading speed will be affected when the number is large"));
		o.rmempty = false;
		o.default = 'false';
		
		o = s.option(form.ListValue, "time_update", _("Update interval"));
		o.datatype = "list(string)";
		o.value('0', _('Halfhour'));o.value('1', '1 '+_('hour'));o.value('2', '2 '+_('hour'));
		o.value('3', '3 '+_('hour'));o.value('4', '4 '+_('hour'));o.value('5', '5 '+_('hour'));
		o.value('6', '6 '+_('hour'));o.value('7', '7 '+_('hour'));o.value('8', '8 '+_('hour'));
		o.value('9', '9 '+_('hour'));o.value('10', '10 '+_('hour'));o.value('11', '11 '+_('hour'));
		o.value('12', '12 '+_('hour'));o.value('13', '13 '+_('hour'));o.value('14', '14 '+_('hour'));
		o.value('15', '15 '+_('hour'));o.value('16', '16 '+_('hour'));o.value('17', '17 '+_('hour'));
		o.value('18', '18 '+_('hour'));o.value('19', '19 '+_('hour'));o.value('20', '20 '+_('hour'));
		o.value('21', '21 '+_('hour'));o.value('22', '22 '+_('hour'));o.value('23', '23 '+_('hour'));
		o.value('24', '24 '+_('hour'));
		o.rmempty = false;
		o.depends("autoupdate","1")
		o.default = 12;

		o = s.option(form.Flag, "app_check", _("Check app version"));
		o.rmempty = false;
		o.default = 'false';

		o = s.option(form.Flag, "dns_detect", _("Show dns detect"));
		o.rmempty = false;
		o.default = 'false';
		o.description = _("show on this page.");

		return m.render();
		
	}

});
