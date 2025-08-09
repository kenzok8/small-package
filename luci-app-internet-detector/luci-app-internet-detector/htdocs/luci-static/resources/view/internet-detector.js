'use strict';
'require baseclass';
'require form';
'require fs';
'require poll';
'require rpc';
'require uci';
'require ui';
'require view';
'require tools.widgets as widgets'

document.head.append(E('style', {'type': 'text/css'},
`
:root {
	--app-id-font-color: #454545;
	--app-id-font-shadow: #fff;
	--app-id-connected-color: #6bdebb;
	--app-id-disconnected-color: #f8aeba;
	--app-id-undefined-color: #dfdfdf;
}
:root[data-darkmode="true"] {
	--app-id-font-color: #f6f6f6;
	--app-id-font-shadow: #4d4d4d;
	--app-id-connected-color: #005F20;
	--app-id-disconnected-color: #a93734;
	--app-id-undefined-color: #4d4d4d;
}
.id-connected {
	--on-color: var(--app-id-font-color);
	background-color: var(--app-id-connected-color) !important;
	border-color: var(--app-id-connected-color) !important;
	color: var(--app-id-font-color) !important;
	text-shadow: 0 1px 1px var(--app-id-font-shadow);
}
.id-disconnected {
	--on-color: var(--app-id-font-color);
	background-color: var(--app-id-disconnected-color) !important;
	border-color: var(--app-id-disconnected-color) !important;
	color: var(--app-id-font-color) !important;
	text-shadow: 0 1px 1px var(--app-id-font-shadow);
}
.id-undefined {
	--on-color: var(--app-id-font-color);
	background-color: var(--app-id-undefined-color) !important;
	border-color: var(--app-id-undefined-color) !important;
	color: var(--app-id-font-color) !important;
	text-shadow: 0 1px 1px var(--app-id-font-shadow);
}
.id-label-status {
	display: inline-block;
	word-wrap: break-word;
	margin: 2px !important;
	padding: 4px 8px;
	border: 1px solid;
	-webkit-border-radius: 4px;
	-moz-border-radius: 4px;
	border-radius: 4px;
	font-weight: bold;
	box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}
`));

const btnStyleEnabled  = 'btn cbi-button-save';
const btnStyleDisabled = 'btn cbi-button-reset';
const btnStyleApply    = 'btn cbi-button-apply';

var Timefield = ui.Textfield.extend({
	secToString(value) {
		let string = '0';
		if(/^\d+$/.test(value)) {
			value = Number(value);
			if(value >= 86400 && (value % 86400) === 0) {
				string = String(value / 86400) + 'd';
			}
			else if(value >= 3600 && (value % 3600) === 0) {
				string = String(value / 3600) + 'h';
			}
			else if(value >= 60 && (value % 60) === 0) {
				string = String(value / 60) + 'm';
			}
			else {
				string = String(value) + 's';
			};
		};
		return string;
	},

	render() {
		let frameEl = E('div', { 'id': this.options.id }),
		    inputEl = E('input', {
			'id'         : this.options.id ? 'widget.' + this.options.id : null,
			'name'       : this.options.name,
			'type'       : 'text',
			'class'      : 'cbi-input-text',
			'readonly'   : this.options.readonly ? '' : null,
			'disabled'   : this.options.disabled ? '' : null,
			'maxlength'  : this.options.maxlength,
			'placeholder': this.options.placeholder,
			'value'      : this.secToString(this.value),
		});
		frameEl.appendChild(inputEl);
		return this.bind(frameEl);
	},

	getValue() {
		let rawValue = this.node.querySelector('input').value,
		    value    = 0,
		    res      = rawValue.match(/^(\d+)([dhms]?)$/);
		if(res) {
			if(res[2] === 'd') {
				value = Number(res[1]) * 86400;
			}
			else if(res[2] === 'h') {
				value = Number(res[1]) * 3600;
			}
			else if(res[2] === 'm') {
				value = Number(res[1]) * 60;
			}
			else if(!res[2] || res[2] === 's') {
				value = Number(res[1]);
			}
			else {
				value = 0;
			};
		} else {
			value = 0;
		};
		return String(value);
	},

	setValue(value) {
		let inputEl   = this.node.querySelector('input');
		inputEl.value = this.secToString(value);
	},
});

var TextfieldButton = ui.Textfield.extend({
	render() {
		let frameEl = E('div', { 'id': this.options.id }),
		    inputEl = E('input', {
			'id'         : this.options.id ? 'widget.' + this.options.id : null,
			'name'       : this.options.name,
			'type'       : 'text',
			'class'      : 'cbi-input-text',
			'readonly'   : this.options.readonly ? '' : null,
			'disabled'   : this.options.disabled ? '' : null,
			'maxlength'  : this.options.maxlength,
			'placeholder': this.options.placeholder,
			'value'      : this.value,
		});
		frameEl.appendChild(E('div', { 'class': 'control-group' }, [
			inputEl,
			E('button', {
				'class'     : `cbi-button cbi-button-${this.options.btnstyle || 'neutral'}`,
				'title'     : this.options.btntitle,
				'aria-label': this.options.btntitle,
				'click'     : this.options.onclick,
			}, this.options.btntext,)
		]));
		return this.bind(frameEl);
	},
});

return view.extend({
	appName                : 'internet-detector',
	configDir              : '/etc/internet-detector',
	pollInterval           : L.env.pollinterval,
	appStatus              : 'stoped',
	initStatus             : null,
	inetStatus             : null,
	inetStatusArea         : E('div', { 'class': 'cbi-value-field', 'id': 'inetStatusArea' }),
	serviceStatusLabel     : E('em', { 'id': 'serviceStatusLabel' }),
	initButton             : null,
	currentAppMode         : '0',
	defaultHosts           : [ '8.8.8.8', '1.1.1.1' ],
	ledsPath               : '/sys/class/leds',
	ledsPerInstance        : 3,
	leds                   : [],
	tgUpdatesURLPattern    : 'https://api.telegram.org/bot%s/getUpdates',
	mm                     : false,
	mmInit                 : false,
	email                  : false,
	emailExec              : false,
	telegram               : false,
	curlExec               : false,
	modRegularScriptNextRun: {},

	callInitStatus: rpc.declare({
		object: 'luci',
		method: 'getInitList',
		params: [ 'name' ],
		expect: { '': {} }
	}),

	callInitAction: rpc.declare({
		object: 'luci',
		method: 'setInitAction',
		params: [ 'name', 'action' ],
		expect: { result: false }
	}),

	getInitStatus() {
		return this.callInitStatus(this.appName).then(res => {
			if(res) {
				return res[this.appName].enabled;
			} else {
				throw _('Command failed');
			}
		}).catch(e => {
			ui.addNotification(null,
				E('p', _('Failed to get %s init status: %s').format(this.appName, e)));
		});
	},

	handleServiceAction(action) {
		return this.callInitAction(this.appName, action).then(success => {
			if(!success) {
				throw _('Command failed');
			};
			return true;
		}).catch(e => {
			ui.addNotification(null,
				E('p', _('Service action failed "%s %s": %s').format(this.appName, action, e)));
		});
	},

	callInit: rpc.declare({
		object: 'luci.internet-detector',
		method: 'Init',
		expect: { '': {} }
	}),

	getInit() {
		return this.callInit().then(data => {
			return data;
		});
	},

	callUIPoll: rpc.declare({
		object: 'luci.internet-detector',
		method: 'UIPoll',
		expect: { '': {} }
	}),

	getUIPoll() {
		return this.callUIPoll().then(data => {
			return data;
		});
	},

	callStatus: rpc.declare({
		object: 'luci.internet-detector',
		method: 'Status',
		expect: { '': {} }
	}),

	getStatus() {
		return this.callStatus().then(data => {
			return data;
		});
	},

	callInetStatus: rpc.declare({
		object: 'luci.internet-detector',
		method: 'InetStatus',
		expect: { '': {} }
	}),

	getInetStatus() {
		return this.callInetStatus().then(data => {
			return data;
		});
	},

	setInternetStatus() {
		this.inetStatusArea.innerHTML = '';

		if(!this.inetStatus || !this.inetStatus.instances || this.inetStatus.instances.length === 0) {
			let label = E('span', { 'class': 'id-label-status id-undefined' }, _('Undefined'));
			if((this.currentAppMode === '1' && this.appStatus !== 'stoped') || this.currentAppMode === '2') {
				label.classList.add('spinning');
			};
			this.inetStatusArea.append(label);
		} else {
			this.inetStatus.instances.sort((a, b) => a.num > b.num);

			for(let i of this.inetStatus.instances) {
				let status    = _('Disconnected');
				let className = 'id-label-status id-disconnected';
				if(i.inet == 0) {
					status    = _('Connected');
					className = 'id-label-status id-connected';
				}
				else if(i.inet == -1) {
					status    = _('Undefined');
					className = 'id-label-status id-undefined spinning';
				};

				let publicIp = (i.mod_public_ip !== undefined) ?
					' | %s: %s'.format(_('Public IP'), (i.mod_public_ip === '') ? _('Undefined') : _(i.mod_public_ip))
				: '';

				this.inetStatusArea.append(
					E('span', { 'class': className }, '%s%s%s'.format(
						i.instance + ': ', status, publicIp)
					)
				);

				if(i.mod_regular_script) {
					this.modRegularScriptNextRun[i.instance] = i.mod_regular_script;
					let nextRunLabel = document.getElementById('id_next_run_' + i.instance);
					if(nextRunLabel) {
						if(this.appStatus === 'running') {
							nextRunLabel.innerHTML = this.modRegularScriptNextRun[i.instance];
						} else {
							nextRunLabel.innerHTML = _('Not scheduled');
						};
					};
				};
			};
		};

		if(this.appStatus === 'running') {
			this.serviceStatusLabel.textContent = _('Running');
		} else {
			this.serviceStatusLabel.textContent = _('Stopped');
		};
	},

	servicePoll() {
		return Promise.all([
			this.getStatus(),
			this.getInetStatus(),
		]).then(stat => {
			this.appStatus  = stat[0].status;
			this.inetStatus = stat[1];
			this.setInternetStatus();
		}).catch(e => {
			this.appStatus  = 'stoped';
			this.inetStatus = {};
		});
	},

	uiPoll() {
		return this.getUIPoll().then(status => {
			this.inetStatus = status;
			this.setInternetStatus();
		});
	},

	serviceRestart() {
		return this.handleServiceAction('restart');
	},

	serviceRestartHandler() {
		poll.stop();
		return this.serviceRestart().then(() => {
			window.setTimeout(() => this.servicePoll(), 1000);
			poll.start();
		});
	},

	getTgChatIdHandler(ev, instance) {
		ev.preventDefault();
		let botToken;
		let botTokenInput = document.getElementById(
			'widget.cbid.%s.%s.mod_telegram_api_token'.format(this.appName, instance));
		if(botTokenInput) {
			botToken = botTokenInput.value;
		};
		if(!botTokenInput || !botToken) {
			alert(_('Bot API token is missing!'));
			return;
		};
		let apiURL = this.tgUpdatesURLPattern.format(botToken);

		console.log(`Requesting chat ID: ${apiURL}`);

		return fetch(apiURL).then(r => {
			if(r.ok) {
				r.json().then(j => {
					let chats = [];
					if(j.ok && j.result) {
						j.result.forEach(i => {
							if(i.message && i.message.chat && i.message.chat.id) {
								if(!chats.includes(i.message.chat.id)) {
									chats.push(i.message.chat.id);
								};
							};
						});
					};
					let tgChatIdInput = document.getElementById(
						'widget.cbid.%s.%s.mod_telegram_chat_id'.format(this.appName, instance));
					if(tgChatIdInput) {
						if(chats.length == 0) {
							alert(_('No messages available. Write something to the bot and try again.'));
						} else {
							tgChatIdInput.value = chats[chats.length - 1];
							tgChatIdInput.focus();
							tgChatIdInput.blur();
						};
					};
				});
			} else {
				let status      = r.status;
				let errorString = `${_('Error')} ${r.status}.`;
				if(status == 404) {
					errorString += ` ${_('Incorrect bot token?')}`;
				};
				alert(errorString);
			};
		}).catch(e => {
			alert(e.message);
			throw e;
		});
	},

	CBITimeInput: form.Value.extend({
		__name__ : 'CBI.TimeInput',

		renderWidget(section_id, option_index, cfgvalue) {
			let value  = (cfgvalue != null) ? cfgvalue : this.default,
				widget = new Timefield(value, {
				id         : this.cbid(section_id),
				optional   : this.optional || this.rmempty,
				maxlength  : 3,
				placeholder: _('Type a time string'),
				validate   : L.bind(
					function(section, value) {
						return (/^$|^\d+[dhms]?$/.test(value)) ? true : _('Expecting:') +
							` ${_('One of the following:')}\n - ${_('days')}: 1d\n - ${_('hours')}: 2h\n - ${_('minutes')}: 10m\n - ${_('seconds')}: 30s\n`;
					},
					this,
					section_id
				),
				disabled   : (this.readonly != null) ? this.readonly : this.map.readonly,
			});
			return widget.render();
		},
	}),

	CBITextfieldButtonInput: form.Value.extend({
		__name__ : 'CBI.TextfieldButtonInput',

		renderWidget(section_id, option_index, cfgvalue) {
			let value  = (cfgvalue != null) ? cfgvalue : this.default,
				widget = new TextfieldButton(value, {
				id         : this.cbid(section_id),
				optional   : this.optional || this.rmempty,
				datatype   : this.datatype,
				placeholder: this.placeholder,
				validate   : L.bind(this.validate, this, section_id),
				disabled   : (this.readonly != null) ? this.readonly : this.map.readonly,
				btntext    : this.btntext,
				btntitle   : this.btntitle,
				btnstyle   : this.btnstyle,
				onclick    : this.onclick,
			});
			return widget.render();
		},
	}),

	CBIBlockInetStatus: form.Value.extend({
		__name__ : 'CBI.BlockInetStatus',

		__init__(map, section, ctx) {
			this.map      = map;
			this.section  = section;
			this.ctx      = ctx;
			this.optional = true;
			this.rmempty  = true;
		},

		renderWidget(section_id, option_index, cfgvalue) {
			this.ctx.setInternetStatus();

			return E([
				E('label', { 'class': 'cbi-value-title', 'for': 'inetStatusArea' },
					_('Internet status')
				), this.ctx.inetStatusArea
			])
		},
	}),

	CBIBlockServiceStatus: form.Value.extend({
		__name__ : 'CBI.BlockServiceStatus',

		__init__(map, section, ctx) {
			this.map      = map;
			this.section  = section;
			this.ctx      = ctx;
			this.optional = true;
			this.rmempty  = true;
		},

		renderWidget(section_id, option_index, cfgvalue) {
			return E([
				E('label', { 'class': 'cbi-value-title', 'for': 'serviceStatusLabel' },
					_('Service')
				),
				E('div', { 'class': 'cbi-value-field' },
					this.ctx.serviceStatusLabel
				),
			]);
		},
	}),

	CBIBlockInitButton: form.Value.extend({
		__name__ : 'CBI.BlockInitButton',

		__init__(map, section, ctx) {
			this.map      = map;
			this.section  = section;
			this.ctx      = ctx;
			this.optional = true;
			this.rmempty  = true;
		},

		renderWidget(section_id, option_index, cfgvalue) {
			this.ctx.initButton = E('button', {
				'class': (!this.ctx.initStatus) ? btnStyleDisabled : btnStyleEnabled,
				'click': ui.createHandlerFn(this, () => {
					return this.ctx.handleServiceAction(
						(!this.ctx.initStatus) ? 'enable' : 'disable'
					).then(success => {
						if(!success) {
							return;
						};
						if(!this.ctx.initStatus) {
							this.ctx.initButton.textContent = _('Enabled');
							this.ctx.initButton.className   = btnStyleEnabled;
							this.ctx.initStatus             = true;
						}
						else {
							this.ctx.initButton.textContent = _('Disabled');
							this.ctx.initButton.className   = btnStyleDisabled;
							this.ctx.initStatus             = false;
						};
					});
				}),
			}, (!this.ctx.initStatus) ? _('Disabled') : _('Enabled'));

			return E( [
				E('label', { 'class': 'cbi-value-title', 'for': 'initButton' },
					_('Run service at startup')
				),
				E('div', { 'class': 'cbi-value-field' }, [
					E('div', {}, this.ctx.initButton),
					E('input', {
						'id'  : 'initButton',
						'type': 'hidden',
					}),
				]),
			]);
		},
	}),

	CBIBlockFileEdit: form.Value.extend({
		__name__ : 'CBI.BlockFileEdit',

		__init__(map, section, ctx, id, file, title, description, callback) {
			this.map         = map;
			this.section     = section;
			this.ctx         = ctx;
			this.id          = id,
			this.optional    = true;
			this.rmempty     = true;
			this.file        = file;
			this.title       = title;
			this.description = description;
			this.callback    = callback;
			this.content     = '';
		},

		cfgvalue(section_id, option) {
			return this.content;
		},

		formvalue(section_id) {
			let value    = this.content;
			let textarea = document.getElementById('widget.file_edit.content.' + this.id);
			if(textarea) {
				value = textarea.value.trim().replace(/\r\n/g, '\n') + '\n';
			};
			return value;
		},

		write(section_id, formvalue) {
			return fs.write(this.file, formvalue).then(rc => {
				ui.addNotification(null, E('p', _('Contents have been saved.')),
					'info');
				if(this.callback) {
					return this.callback(rc);
				};
			}).catch(e => {
				ui.addNotification(null, E('p', _('Unable to save the contents')
					+ ': %s'.format(e.message)));
			});
		},

		load() {
			return L.resolveDefault(fs.read(this.file), '').then(c => {
				this.content = c;
			});
		},

		renderWidget(section_id, option_index, cfgvalue) {
			return E('textarea', {
				'id'        : 'widget.file_edit.content.' + this.id,
				'class'     : 'cbi-input-textarea',
				'style'     : 'width:100% !important',
				'rows'      : 10,
				'wrap'      : 'off',
				'spellcheck': 'false',
			}, cfgvalue);
		},
	}),

	load() {
		return Promise.all([
			this.getStatus(),
			this.getInitStatus(),
			L.resolveDefault(fs.list(this.ledsPath), []),
			this.getInit(),
			uci.load(this.appName),
		]).catch(e => {
			ui.addNotification(
				null, E('p', _('An error has occurred') + ': %s'.format(e.message)));
		});
	},

	render(data) {
		if(!data) {
			return;
		};
		this.appStatus  = (data[0].code === 0) ? data[0].stdout.trim() : null;
		this.initStatus = data[1];
		this.leds       = data[2];
		if(data[3]) {
			if(data[3].mm_mod) {
				this.mm = true;
			};
			if(data[3].mm_init) {
				this.mmInit = true;
			};
			if(data[3].email_mod) {
				this.email = true;
			};
			if(data[3].email_exec) {
				this.emailExec = true;
			};
			if(data[3].telegram) {
				this.telegram = true;
			};
			if(data[3].curl_exec) {
				this.curlExec = true;
			};
		};
		this.currentAppMode = uci.get(this.appName, 'config', 'mode');

		let s, o, ss;
		let m = new form.Map(this.appName,
			_('Internet Detector'),
			_('Checking Internet availability.'));


		/* Status widget */

		s = m.section(form.NamedSection, 'config', 'main');
		o = s.option(this.CBIBlockInetStatus, this);


		s = m.section(form.NamedSection, 'config', 'main');


		/* Service widget */

		if(this.currentAppMode === '1') {
			o = s.option(this.CBIBlockServiceStatus, this);

			// restart button
			o = s.option(form.Button,
				'_restart_btn', _('Restart service')
			);
			o.onclick    = () => this.serviceRestartHandler();
			o.inputtitle = _('Restart');
			o.inputstyle = btnStyleApply;

			// init button
			o = s.option(this.CBIBlockInitButton, this);
		};


		/* Main settings */

		// mode
		let mode = s.option(form.ListValue, 'mode',
			_('Internet detector mode'));
		mode.value('0', _('Disabled'));
		mode.value('1', _('Service'));
		mode.value('2', _('Web UI only (UI detector)'));
		mode.description = '%s<br />%s<br />%s'.format(
			_('Disabled: detector is completely off.'),
			_('Service: detector always runs as a system service.'),
			_('Web UI only: detector works only when the Web UI is open (UI detector).')
		);
		mode.default = '0';


		/* Instances configuration */

		if(this.currentAppMode !== '2') {

			// logging_level
			o = s.option(form.ListValue, 'logging_level',
				_('Logging'),
				_('Log event level.')
			);
			o.value(-1, _('Disabled'));
			o.value(3, _('Error'));
			o.value(4, _('Warning'));
			o.value(5, _('Notice'));
			o.value(6, _('Info'));
			o.value(7, _('Debug'));
			o.rmempty = false;
			o.default = '6';
		};

		s = m.section(form.GridSection, 'instance');

		s.title          = _('Instances');
		s.addremove      = true;
		s.sortable       = true;
		s.nodescriptions = true;
		s.addbtntitle    = _('Add instance');

		s.tab('main', _('Main settings'));

		function makeIntervalOptions(list) {
			list.value(2,   '2 '  + _('sec'));
			list.value(5,   '5 '  + _('sec'));
			list.value(10,  '10 ' + _('sec'));
			list.value(15,  '15 ' + _('sec'));
			list.value(20,  '20 ' + _('sec'));
			list.value(25,  '25 ' + _('sec'));
			list.value(30,  '30 ' + _('sec'));
			list.value(60,  '1 '  + _('min'));
			list.value(120, '2 '  + _('min'));
			list.value(300, '5 '  + _('min'));
			list.value(600, '10 ' + _('min'));
		}

		function makeTimerDelayOptions(list) {
			list.value(25,   '25 '  + _('msec'));
			list.value(50,   '50 '  + _('msec'));
			list.value(100,  '100 ' + _('msec'));
			list.value(250,  '250 ' + _('msec'));
			list.value(500,  '500 ' + _('msec'));
			list.value(750,  '750 ' + _('msec'));
			list.value(1000, '1 '   + _('sec'));
			list.value(1500, '1.5 ' + _('sec'));
			list.value(2000, '2 '   + _('sec'));
		}

		// enabled
		o = s.taboption('main', form.Flag, 'enabled',
			_('Enabled'),
		);
		o.rmempty   = false;
		o.default   = '1';
		o.editable  = true;
		o.modalonly = false;

		// hosts
		o = s.taboption('main', form.DynamicList,
			'hosts', _('Hosts'),
			_('Hosts to check Internet availability. Hosts are polled (in list order) until at least one of them responds.')
		);
		o.datatype = 'or(or(host,hostport),ipaddrport(1))';
		o.default  = this.defaultHosts;
		o.rmempty  = false;

		// check_type
		o = s.taboption('main', form.ListValue,
			'check_type', _('Check type'),
			_('Host availability check type.')
		);
		o.value(0, _('TCP port connection'));
		o.value(1, _('ICMP-echo request (ping)'));
		o.default   = '0';
		o.modalonly = true;

		// tcp_port
		o = s.taboption('main', form.Value,
			'tcp_port', _('TCP port'),
			_('Default port value for TCP connections.')
		);
		o.datatype = 'port';
		o.default  = '53';
		o.depends({ check_type: '0' });
		o.modalonly = true;

		// icmp_packet_size
		o = s.taboption('main', form.ListValue,
			'icmp_packet_size', _('ICMP packet data size'));
		o.value(1,    _('Small: 1 byte'));
		o.value(32,   _('Windows: 32 bytes'));
		o.value(56,   _('Standard: 56 bytes'));
		o.value(248,  _('Big: 248 bytes'));
		o.value(1492, _('Huge: 1492 bytes'));
		o.value(9000, _('Jumbo: 9000 bytes'));
		o.default = '56';
		o.depends({ check_type: '1' });
		o.modalonly = true;

		// iface
		o = s.taboption('main', widgets.DeviceSelect,
			'iface', _('Device'),
			_('Network device for Internet access. If not specified, the default device is used.')
		);
		o.noaliases  = true;

		// interval_up
		o = s.taboption('main', form.ListValue,
			'interval_up', _('Alive interval'),
			_('Hosts polling interval when the Internet is up.')
		);
		o.default   = '30';
		o.modalonly = true;
		makeIntervalOptions(o);

		// interval_down
		o = s.taboption('main', form.ListValue,
			'interval_down', _('Dead interval'),
			_('Hosts polling interval when the Internet is down.')
		);
		o.default   = '5';
		o.modalonly = true;
		makeIntervalOptions(o);

		// connection_attempts
		o = s.taboption('main', form.ListValue,
			'connection_attempts', _('Connection attempts'),
			_('Maximum number of attempts to connect to each host.')
		);
		o.modalonly = true;
		o.value(1);
		o.value(2);
		o.value(3);
		o.value(4);
		o.value(5);
		o.default = '2';

		// connection_timeout
		o = s.taboption('main', form.ListValue,
			'connection_timeout', _('Connection timeout'),
			_('Maximum timeout for waiting for a response from the host.')
		);
		o.modalonly = true;
		o.value(1,  '1 ' + _('sec'));
		o.value(2,  '2 ' + _('sec'));
		o.value(3,  '3 ' + _('sec'));
		o.value(4,  '4 ' + _('sec'));
		o.value(5,  '5 ' + _('sec'));
		o.value(6,  '6 ' + _('sec'));
		o.value(7,  '7 ' + _('sec'));
		o.value(8,  '8 ' + _('sec'));
		o.value(9,  '9 ' + _('sec'));
		o.value(10, '10 ' + _('sec'));
		o.default = '2';


		/* Modules */

		if(this.currentAppMode !== '2') {
			s.tab('led_control', _('LED control'));
			s.tab('reboot_device', _('Reboot device'));
			s.tab('restart_network', _('Restart network'));
			if(this.mm) {
				s.tab('restart_modem', _('Restart modem'));
			};
		};

		s.tab('public_ip', _('Public IP address'));

		if(this.currentAppMode !== '2') {
			if(this.email) {
				s.tab('email', _('Email notification'));
			};
			if(this.telegram) {
				s.tab('telegram', _('Telegram notification'));
			};
			s.tab('user_scripts', _('User scripts'));
			s.tab('regular_script', _('Regular script'));
		};

		s.addModalOptions = (s, section_id, ev) => {

			if(this.currentAppMode !== '2') {

				// LED control

				o         = s.taboption('led_control', form.DummyValue, '_dummy');
				o.rawhtml = true;
				o.default = '<div class="cbi-section-descr">' +
					_('<abbr title="Light Emitting Diode">LED</abbr> indicates the Internet status.') +
					'</div>';
				o.modalonly = true;

				if(this.leds.length > 0) {
					this.leds.sort((a, b) => a.name > b.name);

					// enabled
					o = s.taboption('led_control', form.Flag,
						'mod_led_control_enabled',
						_('Enabled'));
					o.rmempty   = false;
					o.modalonly = true;

					o = s.taboption('led_control', form.SectionValue,
						s.section, form.NamedSection, s.section);
					o.depends({ mod_led_control_enabled: '1' });
					ss = o.subsection;

					for(let i = 1; i <= this.ledsPerInstance; i++) {
						ss.tab('led' + i + '_tab', _('LED') + ' ' + i);

						// led_name
						o = ss.taboption('led' + i + '_tab', form.ListValue,
							'mod_led_control_led' + i + '_name',
							_('<abbr title="Light Emitting Diode">LED</abbr> Name'));
						o.modalonly = true;
						if(i > 1) {
							o.rmempty  = true;
							o.optional = true;
						};
						this.leds.forEach(e => o.value(e.name));

						// led_action_1
						o = ss.taboption('led' + i + '_tab', form.ListValue,
							'mod_led_control_led' + i + '_action_1',
							_('After connection'));
						o.depends({ ['mod_led_control_led' + i + '_name']: /.+/ });
						o.modalonly = true;
						o.value(1, _('Off'));
						o.value(2, _('On'));
						o.value(3, _('Blinking (kernel: timer)'));
						o.value(4, _('Network device activity (kernel: netdev)'));
						o.default = '2';

						// blink_on_delay_1
						o = ss.taboption('led' + i + '_tab', form.ListValue,
							'mod_led_control_led' + i + '_blink_on_delay_1',
							_('On-state delay'),
							_('On-state delay for blinking option.'));
						makeTimerDelayOptions(o);
						o.depends({ ['mod_led_control_led' + i + '_action_1']: '3' });
						o.modalonly = true;
						o.default   = '500';

						// blink_off_delay_1
						o = ss.taboption('led' + i + '_tab', form.ListValue,
							'mod_led_control_led' + i + '_blink_off_delay_1',
							_('Off-state delay'),
							_('Off-state delay for blinking option.'));
						makeTimerDelayOptions(o);
						o.depends({ ['mod_led_control_led' + i + '_action_1']: '3' });
						o.modalonly = true;
						o.default   = '500';

						// netdev_device_1
						o = ss.taboption('led' + i + '_tab', widgets.DeviceSelect,
							'mod_led_control_led' + i + '_netdev_device_1',
							_('Device'),
							_('<abbr title="Light Emitting Diode">LED</abbr> will display the link activity of this network device.')
						);
						o.depends({ ['mod_led_control_led' + i + '_action_1']: '4' });
						o.modalonly = true;
						o.rmempty   = false;
						o.noaliases = true;

						// netdev_mode_1
						o = ss.taboption('led' + i + '_tab', form.MultiValue,
							'mod_led_control_led' + i + '_netdev_mode_1',
							_('<abbr title="Light Emitting Diode">LED</abbr> mode')
						);
						o.depends({ ['mod_led_control_led' + i + '_action_1']: '4' });
						o.modalonly = true;
						o.value('link', _('Link On'));
						o.value('tx', _('Tramsmit'));
						o.value('rx', _('Receive'));
						o.default = 'link';
						o.rmempty = false;

						// led_action_2
						o = ss.taboption('led' + i + '_tab', form.ListValue,
							'mod_led_control_led' + i + '_action_2',
							_('After disconnection'));
						o.depends({ ['mod_led_control_led' + i + '_name']: /.+/ });
						o.modalonly = true;
						o.value(1, _('Off'));
						o.value(2, _('On'));
						o.value(3, _('Blinking (kernel: timer)'));
						o.value(4, _('Network device activity (kernel: netdev)'));
						o.default = '1';

						// blink_on_delay_2
						o = ss.taboption('led' + i + '_tab', form.ListValue,
							'mod_led_control_led' + i + '_blink_on_delay_2',
							_('On-state delay'),
							_('On-state delay for blinking option.'));
						makeTimerDelayOptions(o);
						o.depends({ ['mod_led_control_led' + i + '_action_2']: '3' });
						o.modalonly = true;
						o.default   = '500';

						// blink_off_delay_2
						o = ss.taboption('led' + i + '_tab', form.ListValue,
							'mod_led_control_led' + i + '_blink_off_delay_2',
							_('Off-state delay'),
							_('Off-state delay for blinking option.'));
						makeTimerDelayOptions(o);
						o.depends({ ['mod_led_control_led' + i + '_action_2']: '3' });
						o.modalonly = true;
						o.default   = '500';

						// netdev_device_2
						o = ss.taboption('led' + i + '_tab', widgets.DeviceSelect,
							'mod_led_control_led' + i + '_netdev_device_2',
							_('Device'),
							_('<abbr title="Light Emitting Diode">LED</abbr> will display the link activity of this network device.')
						);
						o.depends({ ['mod_led_control_led' + i + '_action_2']: '4' });
						o.modalonly  = true;
						o.rmempty    = false;
						o.noaliases  = true;

						// netdev_mode_2
						o = ss.taboption('led' + i + '_tab', form.MultiValue,
							'mod_led_control_led' + i + '_netdev_mode_2',
							_('<abbr title="Light Emitting Diode">LED</abbr> mode')
						);
						o.depends({ ['mod_led_control_led' + i + '_action_2']: '4' });
						o.modalonly = true;
						o.value('link', _('Link On'));
						o.value('tx', _('Tramsmit'));
						o.value('rx', _('Receive'));
						o.default = 'link';
						o.rmempty = false;

					};
				} else {
					o = s.taboption('led_control', form.DummyValue, '_dummy');
					o.rawhtml = true;
					o.default = '<label class="cbi-value-title"></label><div class="cbi-value-field"><em>' +
						_('No <abbr title="Light Emitting Diode">LED</abbr>s available...') +
						'</em></div>';
					o.modalonly = true;
				};

				// Reboot device

				o         = s.taboption('reboot_device', form.DummyValue, '_dummy');
				o.rawhtml = true;
				o.default = '<div class="cbi-section-descr">' +
					_('Device will be rebooted when the Internet is disconnected.') +
					'</div>';
				o.modalonly = true;

				// enabled
				o = s.taboption('reboot_device', form.Flag, 'mod_reboot_enabled',
					_('Enabled'));
				o.rmempty   = false;
				o.modalonly = true;

				// dead_period
				o = s.taboption('reboot_device', this.CBITimeInput,
					'mod_reboot_dead_period', _('Dead period'),
					_('Period of time without Internet access until the device is rebooted.')
				);
				o.default   = '3600';
				o.rmempty   = false;
				o.modalonly = true;

				// force_reboot_delay
				o = s.taboption('reboot_device', form.ListValue,
					'mod_reboot_force_reboot_delay', _('Forced reboot delay'),
					_('Waiting for a reboot to complete before performing a forced reboot.')
				);
				o.modalonly = true;
				o.value(0,    _('Disable forced reboot'));
				o.value(60,   '1 ' + _('min'));
				o.value(120,  '2 ' + _('min'));
				o.value(300,  '5 ' + _('min'));
				o.value(600,  '10 ' + _('min'));
				o.value(1800, '30 ' + _('min'));
				o.value(3600, '1 ' + _('hour'));
				o.default = '300';

				// disconnected_at_startup
				o = s.taboption('reboot_device', form.Flag,
					'mod_reboot_disconnected_at_startup',
					_('On startup'),
					_('Reboot device if the Internet is disconnected at service startup.')
				);
				o.rmempty   = false;
				o.modalonly = true;

				// Restart network

				o = s.taboption('restart_network', form.DummyValue, '_dummy');
					o.rawhtml = true;
					o.default = '<div class="cbi-section-descr">' +
						_('Network will be restarted when the Internet is disconnected.') +
						'</div>';
				o.modalonly = true;

				// enabled
				o = s.taboption('restart_network', form.Flag,
					'mod_network_restart_enabled',
					_('Enabled'));
				o.rmempty   = false;
				o.modalonly = true;

				// dead_period
				o = s.taboption('restart_network', this.CBITimeInput,
					'mod_network_restart_dead_period', _('Dead period'),
					_('Period of time without Internet access before network restart.')
				);
				o.default   = '900';
				o.rmempty   = false;
				o.modalonly = true;

				// ifaces
				o = s.taboption('restart_network', widgets.DeviceSelect,
					'mod_network_restart_ifaces',
					_('Device'),
					_('Network device or interface to restart. If not specified, then the network service is restarted.')
				);
				o.modalonly = true;
				o.multiple  = true;

				// attempts
				o = s.taboption('restart_network', form.ListValue,
					'mod_network_restart_attempts', _('Restart attempts'),
					_('Maximum number of network restart attempts before Internet access is available.')
				);
				o.modalonly = true;
				o.value(1);
				o.value(2);
				o.value(3);
				o.value(4);
				o.value(5);
				o.value(10);
				o.value(0, _('infinitely'));
				o.default = '1';

				// attempt_interval
				o = s.taboption('restart_network', this.CBITimeInput,
					'mod_network_restart_attempt_interval', _('Attempt interval'),
					_('Interval between network restarts.')
				);
				o.default   = '60';
				o.rmempty   = false;
				o.modalonly = true;

				// device_timeout
				o = s.taboption('restart_network', form.ListValue,
					'mod_network_restart_device_timeout', _('Device timeout'),
					_('Timeout between stopping and starting a network device when restarting.')
				);
				o.modalonly = true;
				o.value(0,  '0 ' + _('sec'));
				o.value(1,  '1 ' + _('sec'));
				o.value(2,  '2 ' + _('sec'));
				o.value(3,  '3 ' + _('sec'));
				o.value(4,  '4 ' + _('sec'));
				o.value(5,  '5 ' + _('sec'));
				o.value(6,  '6 ' + _('sec'));
				o.value(7,  '7 ' + _('sec'));
				o.value(8,  '8 ' + _('sec'));
				o.value(9,  '9 ' + _('sec'));
				o.value(10, '10 ' + _('sec'));
				o.default = '0';

				// disconnected_at_startup
				o = s.taboption('restart_network', form.Flag,
					'mod_network_restart_disconnected_at_startup',
					_('On startup'),
					_('Restart network if the Internet is disconnected at service startup.')
				);
				o.rmempty   = false;
				o.modalonly = true;

				// Restart modem

				if(this.mm) {
					if(this.mmInit) {
						o         = s.taboption('restart_modem', form.DummyValue, '_dummy');
						o.rawhtml = true;
						o.default = '<div class="cbi-section-descr">' +
							_('Modem will be restarted when the Internet is disconnected.') +
							'</div>';
						o.modalonly = true;

						// enabled
						o = s.taboption('restart_modem', form.Flag,
							'mod_modem_restart_enabled',
							_('Enabled'),
						);
						o.rmempty   = false;
						o.modalonly = true;

						// dead_period
						o = s.taboption('restart_modem', this.CBITimeInput,
							'mod_modem_restart_dead_period', _('Dead period'),
							_('Period of time without Internet access before modem restart.')
						);
						o.default   = '600';
						o.rmempty   = false;
						o.modalonly = true;

						// any_band
						o = s.taboption('restart_modem', form.Flag,
							'mod_modem_restart_any_band', _('Unlock modem bands'),
							_('Set the modem to be allowed to use any band.')
						);
						o.rmempty   = false;
						o.modalonly = true;

						// attempts
						o = s.taboption('restart_modem', form.ListValue,
							'mod_modem_restart_attempts', _('Restart attempts'),
							_('Maximum number of modem restart attempts before Internet access is available.')
						);
						o.modalonly = true;
						o.value(1);
						o.value(2);
						o.value(3);
						o.value(4);
						o.value(5);
						o.value(10);
						o.value(0, _('infinitely'));
						o.default = '1';

						// attempt_interval
						o = s.taboption('restart_modem', this.CBITimeInput,
							'mod_modem_restart_attempt_interval', _('Attempt interval'),
							_('Interval between modem restarts.')
						);
						o.default   = '60';
						o.rmempty   = false;
						o.modalonly = true;

						// iface
						o = s.taboption('restart_modem', widgets.NetworkSelect,
							'mod_modem_restart_iface',
							_('Interface'),
							_('ModemManger interface. If specified, it will be restarted after restarting ModemManager.')
						);
						o.multiple  = false;
						o.nocreate  = true;
						o.modalonly = true;

						// iface_timeout
						o = s.taboption('restart_modem', form.ListValue,
							'mod_modem_restart_iface_timeout', _('Interface timeout'),
							_('Timeout between stopping and starting a ModemManger interface when restarting.')
						);
						o.modalonly = true;
						o.value(0,  '0 ' + _('sec'));
						o.value(1,  '1 ' + _('sec'));
						o.value(2,  '2 ' + _('sec'));
						o.value(3,  '3 ' + _('sec'));
						o.value(4,  '4 ' + _('sec'));
						o.value(5,  '5 ' + _('sec'));
						o.value(6,  '6 ' + _('sec'));
						o.value(7,  '7 ' + _('sec'));
						o.value(8,  '8 ' + _('sec'));
						o.value(9,  '9 ' + _('sec'));
						o.value(10, '10 ' + _('sec'));
						o.default = '0';

						// disconnected_at_startup
						o = s.taboption('restart_modem', form.Flag,
							'mod_modem_restart_disconnected_at_startup',
							_('On startup'),
							_('Restart modem if the Internet is disconnected at service startup.')
						);
						o.rmempty   = false;
						o.modalonly = true;
					} else {
						o         = s.taboption('restart_modem', form.DummyValue, '_dummy');
						o.rawhtml = true;
						o.default = '<label class="cbi-value-title"></label><div class="cbi-value-field"><em>' +
							_('ModemManager is not available...') +
							'</em></div>';
						o.modalonly = true;
					};
				};
			};

			// Public IP address

			o         = s.taboption('public_ip', form.DummyValue, '_dummy');
			o.rawhtml = true;
			o.default = '<div class="cbi-section-descr">' +
				_('Checking the real public IP address.') +
				'</div>';
			o.modalonly = true;

			// enabled
			o = s.taboption('public_ip', form.Flag, 'mod_public_ip_enabled',
				_('Enabled'));
			o.rmempty   = false;
			o.modalonly = true;

			// provider
			o = s.taboption('public_ip', form.ListValue,
				'mod_public_ip_provider', _('Provider'),
				_('Service for determining the public IP address.') + '<br />' +
				((this.curlExec) ? '' :
					_('To support HTTP services you need to install curl.'))
			);
			o.modalonly = true;
			o.value('opendns1', 'opendns1 (DNS)');
			o.value('opendns2', 'opendns2 (DNS)');
			o.value('opendns3', 'opendns3 (DNS)');
			o.value('opendns4', 'opendns4 (DNS)');
			o.value('google',   'google (DNS)');
			o.value('akamai',   'akamai (DNS)');
			if(this.curlExec) {
				o.value('akamai_http', "akamai (HTTP)");
				o.value('amazonaws',   "amazonaws (HTTP)");
				o.value('wgetip',      "wgetip.com (HTTP)");
				o.value('ifconfig',    "ifconfig.me (HTTP)");
				o.value('ipecho',      "ipecho.net (HTTP)");
				o.value('canhazip',    "canhazip.com (HTTP)");
				o.value('icanhazip',   "icanhazip.com (HTTP)");
			};
			o.default = 'opendns1';

			// ipv6
			o = s.taboption('public_ip', form.ListValue,
				'mod_public_ip_qtype', _('DNS query type'),
				_('The type of record requested in the DNS query (if the service supports it).')
			);
			o.modalonly = true;
			o.value('0', 'A (IPv4)');
			o.value('1', 'AAAA (IPv6)');
			o.default = '0';
			o.depends({ 'mod_public_ip_provider': 'opendns1' });
			o.depends({ 'mod_public_ip_provider': 'opendns2' });
			o.depends({ 'mod_public_ip_provider': 'opendns3' });
			o.depends({ 'mod_public_ip_provider': 'opendns4' });
			o.depends({ 'mod_public_ip_provider': 'google' });
			o.depends({ 'mod_public_ip_provider': 'akamai' });

			// interval
			o = s.taboption('public_ip', form.ListValue,
				'mod_public_ip_interval', _('Polling interval'),
				_('Interval between IP address requests.')
			);
			o.default   = '600';
			o.modalonly = true;
			o.value(60,    '1' + ' ' + _('min'));
			o.value(300,   '5' + ' ' + _('min'));
			o.value(600,   '10' + ' ' + _('min'));
			o.value(1800,  '30' + ' ' + _('min'));
			o.value(3600,  '1' + ' ' + _('hour'));
			o.value(10800, '3' + ' ' + _('hour'));

			// interval_failed
			o = s.taboption('public_ip', form.ListValue,
				'mod_public_ip_interval_failed', _('Failed interval'),
				_('Interval between IP address requests if the IP address is not defined.')
			);
			o.default   = '60';
			o.modalonly = true;
			o.value(30,    '30' + ' ' + _('sec'));
			o.value(60,    '1' + ' ' + _('min'));
			o.value(180,   '3' + ' ' + _('min'));
			o.value(300,   '5' + ' ' + _('min'));
			o.value(600,   '10' + ' ' + _('min'));

			// request_attempts
			o = s.taboption('public_ip', form.ListValue,
				'mod_public_ip_request_attempts', _('Attempts'),
				_('Number of attempts to request an IP address.')
			);
			o.default   = '2'
			o.modalonly = true;
			for(let i = 1; i <= 3; i++) {
				o.value(i);
			};

			// timeout
			o = s.taboption('public_ip', form.ListValue,
				'mod_public_ip_timeout', _('Server response timeout')
			);
			o.default   = '3'
			o.modalonly = true;
			for(let i = 1; i <= 5; i++) {
				o.value(i, i + ' ' + _('sec'));
			};

			if(this.currentAppMode !== '2') {

				// enable_ip_script
				o = s.taboption('public_ip', form.Flag,
					'mod_public_ip_enable_ip_script',
					_('Enable public-ip-script'));
				o.rmempty   = false;
				o.modalonly = true;

				// public-ip-script edit dialog
				o = s.taboption('public_ip', this.CBIBlockFileEdit, this,
					'public-ip-script',
					this.configDir + '/public-ip-script.' + s.section,
					_('Edit public-ip-script'),
					_('Shell commands that run when the public IP address changes. New IP is available as value of the <code>$PUBLIC_IP</code> variable (empty string if undefined).')
				);
				o.modalonly = true;

				// Email notification

				if(this.email) {
					if(this.emailExec) {
						o         = s.taboption('email', form.DummyValue, '_dummy');
						o.rawhtml = true;
						o.default = '<div class="cbi-section-descr">' +
							_('An email will be sent when connected or disconnected from the Internet.') +
							'</div>';
						o.modalonly = true;

						// enabled
						o = s.taboption('email', form.Flag, 'mod_email_enabled',
							_('Enabled'));
						o.rmempty   = false;
						o.modalonly = true;

						// mode
						o = s.taboption('email', form.ListValue,
							'mod_email_mode', _('When email will be sent')
						);
						o.modalonly = true;
						o.value(0, _('after connection'));
						o.value(1, _('after disconnection'));
						o.value(2, _('after connection or disconnection'));
						o.default = '0';

						// alive_period
						o = s.taboption('email', this.CBITimeInput,
							'mod_email_alive_period', _('Alive period'),
							_('Period of time after connecting to the Internet before sending a message.')
						);
						o.rmempty   = false;
						o.modalonly = true;
						o.depends({ 'mod_email_mode': '0' });
						o.depends({ 'mod_email_mode': '2' });
						o.default = '0';

						// dead_period
						o = s.taboption('email', this.CBITimeInput,
							'mod_email_dead_period', _('Dead period'),
							_('Period of time after disconnecting from Internet before sending a message.')
						);
						o.rmempty   = false;
						o.modalonly = true;
						o.depends({ 'mod_email_mode': '1' });
						o.depends({ 'mod_email_mode': '2' });
						o.default = '0';

						// host_alias
						o = s.taboption('email', form.Value,
							'mod_email_host_alias',
							_('Host alias'),
							_('Host identifier in messages. If not specified, hostname will be used.'));
						o.modalonly = true;

						// mail_recipient
						o = s.taboption('email', form.Value,
							'mod_email_mail_recipient', _('Recipient'));
						o.description = _('Email address of the recipient.');
						o.modalonly   = true;

						// mail_sender
						o = s.taboption('email', form.Value,
							'mod_email_mail_sender', _('Sender'));
						o.description = _('Email address of the sender.');
						o.modalonly   = true;

						// mail_user
						o = s.taboption('email', form.Value,
							'mod_email_mail_user', _('User'));
						o.description = _('Username for SMTP authentication.');
						o.modalonly   = true;

						// mail_password
						o = s.taboption('email', form.Value,
							'mod_email_mail_password', _('Password'));
						o.description = _('Password for SMTP authentication.');
						o.password    = true;
						o.modalonly   = true;

						// mail_smtp
						o = s.taboption('email', form.Value,
							'mod_email_mail_smtp', _('SMTP server'));
						o.description = _('Hostname/IP address of the SMTP server.');
						o.datatype    = 'host';
						o.modalonly   = true;

						// mail_smtp_port
						o = s.taboption('email', form.Value,
							'mod_email_mail_smtp_port', _('SMTP server port'));
						o.datatype  = 'port';
						o.modalonly = true;

						// mail_security
						o = s.taboption('email', form.ListValue,
							'mod_email_mail_security', _('Security'));
						o.description = '%s<br />%s'.format(
							_('TLS: use STARTTLS if the server supports it.'),
							_('SSL: SMTP over SSL.'),
						);
						o.value('tls', 'TLS');
						o.value('ssl', 'SSL');
						o.default   = 'tls';
						o.modalonly = true;

						// message_at_startup
						o = s.taboption('email', form.Flag,
							'mod_email_message_at_startup',
							_('On startup'),
							_('Send message on service startup.')
						);
						o.rmempty   = false;
						o.modalonly = true;
					} else {
						o         = s.taboption('email', form.DummyValue, '_dummy');
						o.rawhtml = true;
						o.default = '<label class="cbi-value-title"></label><div class="cbi-value-field"><em>' +
							_('Mailsend is not available...') +
							'</em></div>';
						o.modalonly = true;
					};
				};

				// Telegram notification

				if(this.telegram) {
					if(this.curlExec) {
						o = s.taboption('telegram', form.DummyValue, '_dummy');
						o.rawhtml = true;
						o.default = '<div class="cbi-section-descr">' +
							_('Telegram message will be sent when connected or disconnected from the Internet.') +
							'<br />' +
							_("You need to register a new %sTelegram bot%s. Then get the bot's API token and paste it into the <code>Bot token</code> field. After that, open a chat with the bot, write something (in the Telegram app) and you will be able to get the chat ID using the <code>ID</code> button.").format("<a href='https://core.telegram.org/bots#how-do-i-create-a-bot' target='_blank'>", '</a>') +
							'</div>';

						o.modalonly = true;

						// enabled
						o = s.taboption('telegram', form.Flag,
							'mod_telegram_enabled',
							_('Enable'));
						o.rmempty   = false;
						o.modalonly = true;

						// mode
						o = s.taboption('telegram', form.ListValue,
							'mod_telegram_mode', _('When message will be sent')
						);
						o.modalonly = true;
						o.value(0, _('after connection'));
						o.value(1, _('after disconnection'));
						o.value(2, _('after connection or disconnection'));
						o.default = '0';

						// alive_period
						o = s.taboption('telegram', this.CBITimeInput,
							'mod_telegram_alive_period', _('Alive period'),
							_('Period of time after connecting to the Internet before sending a message.')
						);
						o.rmempty   = false;
						o.modalonly = true;
						o.depends({ 'mod_telegram_mode': '0' });
						o.depends({ 'mod_telegram_mode': '2' });
						o.default = '0';

						// dead_period
						o = s.taboption('telegram', this.CBITimeInput,
							'mod_telegram_dead_period', _('Dead period'),
							_('Period of time after disconnecting from Internet before sending a message.')
						);
						o.rmempty   = false;
						o.modalonly = true;
						o.depends({ 'mod_telegram_mode': '1' });
						o.depends({ 'mod_telegram_mode': '2' });
						o.default = '0';

						// host_alias
						o = s.taboption('telegram', form.Value,
							'mod_telegram_host_alias',
							_('Host alias'),
							_('Host identifier in messages. If not specified, hostname will be used.'));
						o.modalonly = true;

						// tg_api_token
						o = s.taboption('telegram', form.Value,
							'mod_telegram_api_token', _('Bot token'),
							_('Telegram bot API token.'));
						o.password  = true;
						o.modalonly = true;

						// tg_chat_id
						o = s.taboption('telegram', this.CBITextfieldButtonInput,
							'mod_telegram_chat_id', _('Chat ID'),
							_('ID of the Telegram chat to which messages will be sent.')
						);
						o.btntext   = _('ID'),
						o.btntitle  = _('Request chat ID from bot API'),
						o.btnstyle  = 'action',
						o.onclick   = ui.createHandlerFn(this,
							(ev) => this.getTgChatIdHandler(ev, s.section));
						o.modalonly = true;
						o.optional  = false;
						o.rmempty   = false;
						o.depends({ 'mod_telegram_api_token': /.+/ });

						// message_at_startup
						o = s.taboption('telegram', form.Flag,
							'mod_telegram_message_at_startup',
							_('On startup'),
							_('Send message on service startup.')
						);
						o.rmempty   = false;
						o.modalonly = true;
					} else {
						o         = s.taboption('telegram', form.DummyValue, '_dummy');
						o.rawhtml = true;
						o.default = '<label class="cbi-value-title"></label><div class="cbi-value-field"><em>' +
							_('Curl is not available...') +
							'</em></div>';
						o.modalonly = true;
					};
				};

				// User scripts

				o         = s.taboption('user_scripts', form.DummyValue, '_dummy');
				o.rawhtml = true;
				o.default = '<div class="cbi-section-descr">' +
					_('Shell commands to run when connected or disconnected from the Internet.') +
					'</div>';
				o.modalonly = true;

				// enabled
				o = s.taboption('user_scripts', form.Flag, 'mod_user_scripts_enabled',
					_('Enabled'));
				o.rmempty   = false;
				o.modalonly = true;

				o = s.taboption('user_scripts', form.SectionValue,
					'user_scripts_section', form.NamedSection, s.section);
				ss = o.subsection;

				// up-script tab
				ss.tab('user_scripts_up_script', 'up-script');

				o = ss.taboption('user_scripts_up_script', form.DummyValue, '_dummy');
					o.rawhtml = true;
					o.default = '<div class="cbi-section-descr">' +
						_('Shell commands that run when connected to the Internet.') +
						'</div>';
				o.modalonly = true;

				// up_script edit
				o = ss.taboption('user_scripts_up_script', this.CBIBlockFileEdit, this,
					'up_script',
					this.configDir + '/up-script.' + s.section,
					_('Edit up-script')
				);
				o.modalonly = true;

				// alive_period
				o = ss.taboption('user_scripts_up_script', this.CBITimeInput,
					'mod_user_scripts_alive_period', _('Alive period'),
					_('Period of time after connecting to Internet before up-script runs.')
				);
				o.default   = '0';
				o.rmempty   = false;
				o.modalonly = true;

				// up_script_attempts
				o = ss.taboption('user_scripts_up_script', form.ListValue,
					'mod_user_scripts_up_script_attempts', _('Attempts'),
					_('Maximum number of up-script run attempts when connected to the Internet.')
				);
				o.modalonly = true;
				o.value(1);
				o.value(2);
				o.value(3);
				o.value(4);
				o.value(5);
				o.value(10);
				o.value(0, _('infinitely'));
				o.default = '1';

				// up_script_attempt_interval
				o = ss.taboption('user_scripts_up_script', this.CBITimeInput,
					'mod_user_scripts_up_script_attempt_interval',
					_('Attempt interval'),
					_('Interval between up-script runs.')
				);
				o.default   = '60';
				o.rmempty   = false;
				o.modalonly = true;

				// connected_at_startup
				o = ss.taboption('user_scripts_up_script', form.Flag,
					'mod_user_scripts_connected_at_startup',
					_('On startup'),
					_('Run up-script if the Internet is connected at service startup.')
				);
				o.rmempty   = false;
				o.modalonly = true;

				// down-script tab
				ss.tab('user_scripts_down_script', 'down-script');

				o         = ss.taboption('user_scripts_down_script', form.DummyValue, '_dummy');
				o.rawhtml = true;
				o.default = '<div class="cbi-section-descr">' +
					_('Shell commands to run when disconnected from the Internet.') +
					'</div>';
				o.modalonly = true;

				// down_script edit
				o = ss.taboption('user_scripts_down_script', this.CBIBlockFileEdit, this,
					'down_script',
					this.configDir + '/down-script.' + s.section,
					_('Edit down-script')
				);
				o.modalonly = true;

				// dead_period
				o = ss.taboption('user_scripts_down_script', this.CBITimeInput,
					'mod_user_scripts_dead_period', _('Dead period'),
					_('Period of time after disconnecting from Internet before down-script runs.')
				);
				o.default   = '0';
				o.rmempty   = false;
				o.modalonly = true;

				// down_script_attempts
				o = ss.taboption('user_scripts_down_script', form.ListValue,
					'mod_user_scripts_down_script_attempts', _('Attempts'),
					_('Maximum number of down-script run attempts before Internet access is available.')
				);
				o.modalonly = true;
				o.value(1);
				o.value(2);
				o.value(3);
				o.value(4);
				o.value(5);
				o.value(10);
				o.value(0, _('infinitely'));
				o.default = '1';

				// down_script_attempt_interval
				o = ss.taboption('user_scripts_down_script', this.CBITimeInput,
					'mod_user_scripts_down_script_attempt_interval',
					_('Attempt interval'),
					_('Interval between down-script runs.')
				);
				o.default   = '60';
				o.rmempty   = false;
				o.modalonly = true;

				// disconnected_at_startup
				o = ss.taboption('user_scripts_down_script', form.Flag,
					'mod_user_scripts_disconnected_at_startup',
					_('On startup'),
					_('Run down-script if the Internet is disconnected at service startup.')
				);
				o.rmempty   = false;
				o.modalonly = true;

				// Regular script

				o = s.taboption('regular_script', form.DummyValue, '_dummy');
				o.rawhtml = true;
				o.default = '<div class="cbi-section-descr">' +
					_('Shell commands that are run regularly.') +
					'</div>';
				o.modalonly = true;

				// enabled
				o = s.taboption('regular_script', form.Flag,
					'mod_regular_script_enabled',
					_('Enabled'));
				o.rmempty   = false;
				o.modalonly = true;

				// next run
				o = s.taboption('regular_script', form.DummyValue,
					'_dummy', _('Next run'));
				o.rawhtml   = true;
				o.default   = '<span id="id_next_run_' + s.section + '">' + (this.modRegularScriptNextRun[s.section] || _('Not scheduled')) + '</span>';
				o.modalonly = true;

				// interval
				o = s.taboption('regular_script', this.CBITimeInput,
					'mod_regular_script_interval', _('Run interval')
				);
				o.default   = '3600';
				o.rmempty   = false;
				o.modalonly = true;

				// inet_state
				o = s.taboption('regular_script', form.ListValue,
					'mod_regular_script_inet_state', _('Run if Internet state is')
				);
				o.modalonly = true;
				o.value(0, _('connected'));
				o.value(1, _('disconnected'));
				o.value(2, _('connected or disconnected'));
				o.default = '2';

				// regular_script edit
				o = s.taboption('regular_script', this.CBIBlockFileEdit, this,
					'regular_script',
					this.configDir + '/regular-script.' + s.section,
					_('Edit regular-script'),
					_('Shell commands that run regularly at a specified interval. Current state of the Internet is available as value of the <code>$INET_STATE</code> variable (<code>0</code> - connected, <code>1</code> - disconnected).')
				);
				o.modalonly = true;
			};

		};

		if(this.currentAppMode !== '0') {
			poll.add(
				L.bind((this.currentAppMode === '1') ? this.servicePoll : this.uiPoll, this),
				this.pollInterval
			);
		};

		let mapPromise = m.render();
		mapPromise.then(node => node.classList.add('fade-in'));
		return mapPromise;
	},
});
