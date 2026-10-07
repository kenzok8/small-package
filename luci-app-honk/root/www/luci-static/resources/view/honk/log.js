'use strict';
'require view';
'require ui';
'require uci';
'require poll';
'require honk.common as honk';

return view.extend({
	load: function() {
		return uci.load('honk');
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null,

	render: function() {
		if (honk && honk.applyTabVisibility) {
			honk.applyTabVisibility();
		}

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
					logTextarea.scrollTop = 0;
					scrolled = false;
					honk.showNotification(null, E('p', _('Logs cleared successfully.')), 'info');
				}).catch(function(err) {
					btnClear.disabled = false;
					honk.showNotification(null, E('p', _('Failed to clear logs:') + ' ' + (err.message || err)), 'error');
				});
			}
		}, _('Clear logs'));

		function updateLog() {
			return honk.callHonkGetLog().then(function(data) {
				var content = (data && data.log) ? data.log : '';
				var atBottom = !scrolled || (logTextarea.scrollHeight - logTextarea.scrollTop - logTextarea.clientHeight < 50);
				logTextarea.value = content;
				if (atBottom && content) {
					logTextarea.scrollTop = logTextarea.scrollHeight;
					scrolled = true;
				}
			});
		}

		updateLog();

		var onVisibilityChange;

		var logPollFn = function() {
			if (!document.body.contains(logTextarea)) {
				poll.remove(logPollFn);
				if (onVisibilityChange) {
					document.removeEventListener('visibilitychange', onVisibilityChange);
				}
				return Promise.resolve();
			}
			if (document.hidden) {
				return Promise.resolve();
			}
			return updateLog();
		};

		poll.add(logPollFn, 3);

		onVisibilityChange = function() {
			if (!document.body.contains(logTextarea)) {
				document.removeEventListener('visibilitychange', onVisibilityChange);
				return;
			}
			if (!document.hidden) {
				updateLog();
			}
		};

		document.addEventListener('visibilitychange', onVisibilityChange);

		return E('fieldset', { 'class': 'cbi-section', 'id': '_log_fieldset' }, [
			E('legend', {}, _('Logs')),
			E('div', { 'style': 'margin-bottom: 10px;' }, [ btnClear ]),
			logTextarea
		]);
	}
});

