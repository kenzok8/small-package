'use strict';
'require form';
'require poll';
'require rpc';
'require uci';
'require view';
'require tools.widgets as widgets';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

function getServiceStatus() {
	return L.resolveDefault(callServiceList('airconnect'), {}).then(function (res) {
		var isRunning = false;
		try {
			isRunning = res['airconnect']['instances']['airupnp']['running'] || res['airconnect']['instances']['aircast']['running'];
		} catch (e) { }
		return isRunning;
	});
}

function renderStatus(isRunning) {
	var spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';
	var renderHTML;
	if (isRunning) {
		renderHTML = spanTemp.format('green', 'AirConnect', _('RUNNING'));
	} else {
		renderHTML = spanTemp.format('red', 'AirConnect', _('NOT RUNNING'));
	}

	return renderHTML;
}

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('airconnect', _('AirConnect'),
			_('Send audio to UPnP/Sonos/Chromecast players using AirPlay.'));

		s = m.section(form.TypedSection);
		s.anonymous = true;
		s.render = function () {
			poll.add(function () {
				return L.resolveDefault(getServiceStatus()).then(function (res) {
					var view = document.getElementById('service_status');
					view.innerHTML = renderStatus(res);
				});
			});

			return E('div', { class: 'cbi-section', id: 'status_bar' }, [
					E('p', { id: 'service_status' }, _('Collecting data...'))
			]);
		}

		s = m.section(form.NamedSection, 'config', 'airconnect');

		o = s.option(form.Flag, 'enabled', _('Enabled'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(widgets.DeviceSelect, 'interface',
			_('Bind interface'));
		o.filter = function(section_id, value) {
			var dev = this.devices.filter(function(dev) { return dev.getName() == value })[0];
			var excludeDevice = ['docker', 'dummy', 'radio', 'sit', 'teql', 'veth', 'ztly'];
			return (dev && dev.getName() != null && !excludeDevice.some(prefix => dev.getName().startsWith(prefix)));
		}
		o.rmempty = false;

		o = s.option(form.Flag, 'airupnp', _('UPnP/Sonos'), _('Enable UPnP/Sonos Device Support'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Flag, 'aircast', _('Chromecast'), _('Enable Chromecast Device Support'));
		o.default = o.disabled;
		o.rmempty = false;

		return m.render();
	}
});
