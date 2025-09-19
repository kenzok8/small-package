// SPDX-License-Identifier: Apache-2.0

'use strict';
'require form';
'require poll';
'require rpc';
'require uci';
'require validation';
'require view';

const callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

function getServiceStatus() {
	return L.resolveDefault(callServiceList('lingtigameacc'), {}).then(function (res) {
		var isRunning = false;
		try {
			isRunning = res['lingtigameacc']['instances']['lingtigameacc']['running'];
		} catch (e) { }
		return isRunning;
	});
}

function renderStatus(isRunning, port) {
	var spanTemp = '<span style="color:%s"><strong>%s %s</strong></span>';
	var renderHTML;
	if (isRunning) {
		renderHTML = spanTemp.format('green', _('lingtigameacc'), _('RUNNING'));
	} else {
		renderHTML = spanTemp.format('red', _('lingtigameacc'), _('NOT RUNNING'));
	}

	return renderHTML;
}

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('lingtigameacc')
		]);
	},

	render: function(data) {
		let m, s, o;

		m = new form.Map('lingtigameacc', _('LingTi Game Acc'),
            _('请先下载灵缇游戏加速器APP.'));

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

		s = m.section(form.NamedSection, 'config', 'lingtigameacc');

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = o.disabled;
		o.rmempty = false;
		
		o = s.option(form.DummyValue, '_image');
        o.renderWidget = function() {
            return E('img', {
                src: '/luci-static/lingtigameacc/router-steps.png',
                style: 'max-width: 100%'
            });
        };

		return m.render();
	}
});
