'use strict';
'require form';
'require poll';
'require rpc';
'require uci';
'require view';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

function getServiceStatus() {
	return L.resolveDefault(callServiceList('qbittorrent'), {}).then(function (res) {
		var isRunning = false;
		try {
			isRunning = res['qbittorrent']['instances']['instance1']['running'];
		} catch (e) { }
		return isRunning;
	});
}

function renderStatus(isRunning, webport) {
	var spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';
	var renderHTML;
	if (isRunning) {
		var button = String.format('<input class="cbi-button-reload" type="button" style="margin-left: 50px" value="%s" onclick="window.open(\'//%s:%s/\')">',
			_('Open Web Interface'), window.location.hostname, webport);
		renderHTML = spanTemp.format('green', _('qBittorrent'), _('RUNNING')) + button;
	} else {
		renderHTML = spanTemp.format('red', _('qBittorrent'), _('NOT RUNNING'));
	}

	return renderHTML;
}

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('qbittorrent')
		]);
	},

	render: function(data) {
		var m, s, o;
		var webport = uci.get(data[0], 'config', 'port') || '8080';

		m = new form.Map('qbittorrent', _('qBittorrent'),
			_('qBittorrent is a cross-platform free and open-source BitTorrent client. Default username & password: admin / adminadmin'));

		s = m.section(form.TypedSection);
		s.anonymous = true;
		s.render = function () {
			poll.add(function () {
				return L.resolveDefault(getServiceStatus()).then(function (res) {
					var view = document.getElementById('service_status');
					view.innerHTML = renderStatus(res, webport);
				});
			});

			return E('div', { class: 'cbi-section', id: 'status_bar' }, [
					E('p', { id: 'service_status' }, _('Collecting data...'))
			]);
		}

		s = m.section(form.NamedSection, 'config', 'qbittorrent');

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Value, 'port', _('WebUI Listen port'));
		o.datatype = 'port';
		o.default = '8080';
		o.rmempty = false;

		o = s.option(form.Value, 'profile_dir', _('Configuration files Path'));
		o.default = '/etc/qbittorrent';
		o.rmempty = false;

		return m.render();
	}
});
