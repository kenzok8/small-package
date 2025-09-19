'use strict';
'require dom';
'require fs';
'require poll';
'require uci';
'require view';
'require form';

return view.extend({
	render: function () {
		var css = `
			/* 日志框文本区域 */
			#log_textarea {
				margin-top: 10px;
			}
			#log_textarea pre {
				padding: 10px; /* 内边距 */
				border: 1px solid #ddd; /* 边框颜色 */
				border-radius: 6px; /* 边框圆角 */
				font-family: Consolas, Menlo, Monaco, monospace;
				font-size: 14px;
				line-height: 1.6; /* 行高 */
				white-space: pre-wrap;
				word-wrap: break-word;
				overflow-y: auto;
				max-height: 600px;
			}
			/* 5s 自动刷新文字 */
			.cbi-section small {
				margin-left: 5px;
				font-size: 12px; 
				color: #666; /* 深灰色文字 */
			}
		`;

		var log_textarea = E('div', { 'id': 'log_textarea' },
			E('img', {
				'src': L.resource(['icons/loading.gif']),
				'alt': _('Loading...'),
				'style': 'vertical-align:middle'
			}, _('Collecting data ...'))
		);

		var log_path = '/tmp/wechatpush/wechatpush.log';
		var lastLogContent = '';

		var clear_log_button = E('div', {}, [
			E('button', {
				'class': 'cbi-button cbi-button-remove',
				'click': function (ev) {
					ev.preventDefault();
					var button = ev.target;
					button.disabled = true;
					button.textContent = _('Clear Logs...');
					fs.exec_direct('/usr/libexec/wechatpush-call', ['clear_log'])
						.then(function () {
							button.textContent = _('Logs cleared successfully!');
							button.disabled = false;
							button.textContent = _('Clear Logs');
							// 立即刷新日志显示框
							var log = E('pre', { 'wrap': 'pre' }, [_('Log is clean.')]);
							dom.content(log_textarea, log);
							lastLogContent = '';
						})
						.catch(function () {
							button.textContent = _('Failed to clear log.');
							button.disabled = false;
							button.textContent = _('Clear Logs');
						});
				}
			}, _('Clear Logs'))
		]);

		poll.add(L.bind(function () {
			return fs.read_direct(log_path, 'text')
				.then(function (res) {
					var newContent = res.trim() || _('Log is clean.');

					if (newContent !== lastLogContent) {
						var log = E('pre', { 'wrap': 'pre' }, [newContent]);
						dom.content(log_textarea, log);
						log.scrollTop = log.scrollHeight;
						lastLogContent = newContent;
					}
				}).catch(function (err) {
					var log;
					if (err.toString().includes('NotFoundError')) {
						log = E('pre', { 'wrap': 'pre' }, [_('Log file does not exist.')]);
					} else {
						log = E('pre', { 'wrap': 'pre' }, [_('Unknown error: %s').format(err)]);
					}
					dom.content(log_textarea, log);
				});
		}));

		return E('div', { 'class': 'cbi-map' }, [
			E('style', [css]),
			E('div', { 'class': 'cbi-section' }, [
				clear_log_button,
				log_textarea,
				E('small', {}, _('Refresh every 5 seconds.').format(L.env.pollinterval)),
				E('div', { 'class': 'cbi-section-actions cbi-section-actions-right' })
			])
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
