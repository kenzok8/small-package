// SPDX-License-Identifier: Apache-2.0
/*
 * Copyright (C) 2025 ImmortalWrt.org
 */

'use strict';
'require form';
'require poll';
'require rpc';
'require uci';
'require view';

const callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

function getServiceStatus() {
	return L.resolveDefault(callServiceList('gost'), {}).then(function(res) {
		let isRunning = false;
		try {
			isRunning = res['gost']['instances']['instance1']['running'];
		} catch (e) { }
		return isRunning;
	});
}

function renderStatus(isRunning) {
	let spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';
	let renderHTML;
	if (isRunning)
		renderHTML = spanTemp.format('green', _('GOST'), _('RUNNING'));
	else
		renderHTML = spanTemp.format('red', _('GOST'), _('NOT RUNNING'));

	return renderHTML;
}

return view.extend({
	render() {
		let m, s, o;

		m = new form.Map('gost', _('GOST'),
			_('A simple security tunnel written in Golang.'));

		s = m.section(form.TypedSection);
		s.anonymous = true;
		s.render = function() {
			poll.add(function() {
				return L.resolveDefault(getServiceStatus()).then(function(res) {
					let view = document.getElementById('service_status');
					view.innerHTML = renderStatus(res);
				});
			});

			return E('div', { class: 'cbi-section', id: 'status_bar' }, [
				E('p', { id: 'service_status' }, _('Collecting data…'))
			]);
		}

		s = m.section(form.NamedSection, 'config', 'gost');

		o = s.option(form.Flag, 'enabled', _('Enable'));

		o = s.option(form.Value, 'config_file', _('Configuration file'));
		o.value('/etc/gost/gost.json');
		o.datatype = 'path';

		o = s.option(form.DynamicList, 'arguments', _('Arguments'));
		o.validate = function(section_id) {
			if (section_id) {
				let config_file = this.section.formvalue(section_id, 'config_file');
				let value = this.section.formvalue(section_id, 'arguments');

				if (!config_file && !value?.length)
					return _('Expecting: %s').format(_('non-empty value'));
			}

			return true;
		}

		return m.render();
	}
});
