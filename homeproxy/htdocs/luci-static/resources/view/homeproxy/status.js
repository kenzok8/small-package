/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2022-2023 ImmortalWrt.org
 */

'use strict';
'require dom';
'require form';
'require fs';
'require poll';
'require rpc';
'require ui';
'require view';

/* Thanks to luci-app-aria2 */
var css = '				\
#log_textarea {				\
	padding: 10px;			\
	text-align: left;		\
}					\
#log_textarea pre {			\
	padding: .5rem;			\
	word-break: break-all;		\
	margin: 0;			\
}					\
.description {				\
	background-color: #33ccff;	\
}';

var hp_dir = '/var/run/homeproxy';

function getResVersion(self, type) {
	var callResVersion = rpc.declare({
		object: 'luci.homeproxy',
		method: 'resources_get_version',
		params: ['type'],
		expect: { '': {} }
	});

	var callResUpdate = rpc.declare({
		object: 'luci.homeproxy',
		method: 'resources_update',
		params: ['type'],
		expect: { '': {} }
	});

	return L.resolveDefault(callResVersion(type), {}).then((res) => {
		var spanTemp = E('div', { 'style': 'cbi-value-field' }, [
			E('button', {
				'class': 'btn cbi-button cbi-button-action',
				'click': ui.createHandlerFn(this, function() {
					return L.resolveDefault(callResUpdate(type), {}).then((res) => {
						switch (res.status) {
						case 0:
							self.description = _('Successfully updated.');
							break;
						case 1:
							self.description = _('Update failed.');
							break;
						case 2:
							self.description = _('Already in updating.');
							break;
						case 3:
							self.description = _('Already at the latest version.');
							break;
						default:
							self.description = _('Unknown error.');
							break;
						}

						return self.map.reset();
					});
				})
			}, [ _('Check update') ]),
			' ',
			E('strong', { 'style': (res.error ? 'color:red' : 'color:green') },
				[ res.error ? 'not found' : res.version ]),
		]);

		self.default = spanTemp;
	});
}

function getRuntimeLog(name) {
	var callLogClean = rpc.declare({
		object: 'luci.homeproxy',
		method: 'log_clean',
		params: ['type'],
		expect: { '': {} }
	});

	var log_textarea = E('div', { 'id': 'log_textarea' },
		E('img', {
			'src': L.resource(['icons/loading.gif']),
			'alt': _('Loading'),
			'style': 'vertical-align:middle'
		}, _('Collecting data...'))
	);

	var log;
	poll.add(L.bind(function() {
		return fs.read_direct(`${hp_dir}/${name.toLowerCase()}.log`, 'text')
		.then(function(res) {
			log = E('pre', { 'wrap': 'pre' }, [
				res.trim() || _('Log is empty.')
			]);

			dom.content(log_textarea, log);
		}).catch(function(err) {
			if (err.toString().includes('NotFoundError'))
				log = E('pre', { 'wrap': 'pre' }, [
					_('Log file does not exist.')
				]);
			else
				log = E('pre', { 'wrap': 'pre' }, [
					_('Unknown error: %s').format(err)
				]);

			dom.content(log_textarea, log);
		});
	}));

	return E([
		E('style', [ css ]),
		E('div', {'class': 'cbi-map'}, [
			E('h3', {'name': 'content'}, [
				_('%s log').format(name),
				' ',
				E('button', {
					'class': 'btn cbi-button cbi-button-action',
					'click': ui.createHandlerFn(this, function() {
						return L.resolveDefault(callLogClean(name.toLowerCase()), {});
					})
				}, [ _('Clean log') ])
			]),
			E('div', {'class': 'cbi-section'}, [
				log_textarea,
				E('div', {'style': 'text-align:right'},
					E('small', {}, _('Refresh every %s seconds.').format(L.env.pollinterval))
				)
			])
		])
	]);
}

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('homeproxy');

		s = m.section(form.NamedSection, 'config', 'homeproxy', _('Resources management'));
		s.anonymous = true;

		o = s.option(form.DummyValue, '_geoip_version', _('GeoIP version'));
		o.cfgvalue = function() { return getResVersion(this, 'geoip') };
		o.rawhtml = true;

		o = s.option(form.DummyValue, '_geosite_version', _('GeoSite version'));
		o.cfgvalue = function() { return getResVersion(this, 'geosite') };
		o.rawhtml = true;

		o = s.option(form.DummyValue, '_china_ip4_version', _('China IPv4 list version'));
		o.cfgvalue = function() { return getResVersion(this, 'china_ip4') };
		o.rawhtml = true;

		o = s.option(form.DummyValue, '_china_ip6_version', _('China IPv6 list version'));
		o.cfgvalue = function() { return getResVersion(this, 'china_ip6') };
		o.rawhtml = true;

		o = s.option(form.DummyValue, '_gfw_list_version', _('GFW list version'));
		o.cfgvalue = function() { return getResVersion(this, 'gfw_list') };
		o.rawhtml = true;

		o = s.option(form.DummyValue, '_china_list_version', _('China list version'));
		o.cfgvalue = function() { return getResVersion(this, 'china_list') };
		o.rawhtml = true;

		o = s.option(form.DummyValue, '_homeproxy_logview');
		o.render = L.bind(getRuntimeLog, this, 'HomeProxy');

		o = s.option(form.DummyValue, '_sing-box_logview');
		o.render = L.bind(getRuntimeLog, this, 'sing-box');

		return m.render();
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
