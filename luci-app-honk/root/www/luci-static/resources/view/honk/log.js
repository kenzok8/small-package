'use strict';
'require view';
'require ui';
'require poll';
'require honk.common as honk';

return view.extend({
	handleSaveApply: null,
	handleSave: null,
	handleReset: null,

	render: function() {
		var scrolled = false;

		var logTextarea = E('textarea', {
			'id': 'log_textarea',
			'class': 'cbi-input-textarea',
			'style': 'width: 100%; height: 600px; font-family: var(--font-mono, monospace); font-size: 12px; line-height: 1.4; box-sizing: border-box; resize: vertical;',
			'rows': 25,
			'wrap': 'off',
			'readonly': 'readonly'
		});

		var btnClear = E('button', {
			'type': 'button',
			'class': 'btn cbi-button cbi-button-remove',
			'click': function() {
				btnClear.disabled = true;
				honk.callHonkClearLog().then(function() {
					btnClear.disabled = false;
					logTextarea.value = '';
					logTextarea.textContent = '';
					logTextarea.scrollTop = 0;
					scrolled = false;
					ui.addNotification(null, E('p', _('Logs cleared successfully.')), 'info');
				}).catch(function(err) {
					btnClear.disabled = false;
					ui.addNotification(null, E('p', _('Failed to clear logs:') + ' ' + (err.message || err)), 'error');
				});
			}
		}, _('Clear logs'));

		function updateLog() {
			return honk.callHonkGetLog().then(function(data) {
				var content = (data && data.log) ? data.log : '';
				logTextarea.value = content;
				if (!scrolled && content) {
					logTextarea.scrollTop = logTextarea.scrollHeight;
					scrolled = true;
				}
			});
		}

		updateLog();

		poll.add(function() {
			return updateLog();
		}, 3);

		return E('fieldset', { 'class': 'cbi-section', 'id': '_log_fieldset' }, [
			E('legend', {}, _('Logs')),
			E('div', { 'style': 'margin-bottom: 10px;' }, [ btnClear ]),
			logTextarea
		]);
	}
});

