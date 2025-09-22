// SPDX-License-Identifier: Apache-2.0

'use strict';
'require dom';
'require fs';
'require poll';
'require view';

return view.extend({
	render: function() {
		/* Thanks to luci-app-aria2 */
		let css = '					\
			#log_textarea {				\
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

		let log_textarea = E('div', { 'id': 'log_textarea' },
			E('img', {
				'src': L.resource('icons/loading.svg'),
				'alt': _('Loading...'),
				'style': 'vertical-align:middle'
			}, _('Collecting data…'))
		);

		poll.add(L.bind(function() {
			return fs.read_direct('/var/log/dae/dae.log', 'text')
			.then(function(content) {
				let log = E('pre', { 'wrap': 'pre' }, [
					content.trim() || _('Log is empty.')
				]);

				dom.content(log_textarea, log);
			}).catch(function(e) {
				let log;

				if (e.toString().includes('NotFoundError'))
					log = E('pre', { 'wrap': 'pre' }, [
						_('Log file does not exist.')
					]);
				else
					log = E('pre', { 'wrap': 'pre' }, [
						_('Unknown error: %s').format(e)
					]);

				dom.content(log_textarea, log);
			});
		}));

		const scrollDownButton = E('button', {
				'id': 'scrollDownButton',
				'class': 'cbi-button cbi-button-neutral',
			}, _('Scroll to tail', 'scroll to bottom (the tail) of the log file')
		);
		scrollDownButton.addEventListener('click', () => {
			scrollUpButton.focus();
		});

		const scrollUpButton = E('button', {
				'id' : 'scrollUpButton',
				'class': 'cbi-button cbi-button-neutral',
			}, _('Scroll to head', 'scroll to top (the head) of the log file')
		);
		scrollUpButton.addEventListener('click', () => {
			scrollDownButton.focus();
		});

		return E([
			E('style', [ css ]),
			E('h2', {}, [ _('Log') ]),
			E('div', {'class': 'cbi-map'}, [
				E('div', {'style': 'padding-bottom: 20px'}, [scrollDownButton]),
				E('div', {'class': 'cbi-section'}, [
					log_textarea,
					E('div', {'style': 'text-align:right'},
						E('small', {}, _('Refresh every %s seconds.').format(L.env.pollinterval))
					)
				]),
				E('div', {'style': 'padding-bottom: 20px'}, [scrollUpButton])
			])
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
