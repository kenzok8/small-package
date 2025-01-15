'use strict';
'require form';
'require poll';
'require uci';
'require view';

'require fchomo as hm';
'require tools.widgets as widgets';

function loadDNSServerLabel(section_id) {
	delete this.keylist;
	delete this.vallist;

	this.value('default-dns', _('Default DNS (issued by WAN)'));
	this.value('system-dns', _('System DNS'));
	this.value('block-dns', _('Block DNS queries'));
	uci.sections(this.config, 'dns_server', (res) => {
		if (res.enabled !== '0')
			this.value(res['.name'], res.label);
	});

	return this.super('load', section_id);
}
function validateNameserver(section_id, value) {
	const arr = value.trim().split(' ');
	if (arr.length > 1 && arr.includes('block-dns'))
		return _('Expecting: %s').format(_('If Block is selected, uncheck others'));

	return true;
}

class DNSAddress {
	constructor(address) {
		this.input = address || '';
		[this.addr, this.rawparams] = this.input.split('#');
		if (this.rawparams) {
			if (this.rawparams.match(/^[^=&]+(&|$)/))
				this.rawparams = 'detour=' + this.rawparams
		} else
			this.rawparams = '';
		this.params = new URLSearchParams(this.rawparams);
	}

	parseParam(param) {
		return this.params.has(param) ? decodeURI(this.params.get(param)) : null;
	}

	setParam(param, value) {
		if (value) {
			this.params.set(param, value);
		} else
			this.params.delete(param);

		return this
	}

	toString() {
		return this.addr + (this.params.size === 0 ? '' : '#' +
			['detour', 'h3', 'ecs', 'ecs-override'].map((k) => {
				return this.params.has(k) ? '%s=%s'.format(k, encodeURI(this.params.get(k))) : null;
			}).filter(v => v).join('&')
		);
	}
}

class RulesEntry {
	constructor(entry) {
		this.input = entry || '';
		try {
			let content = JSON.parse(this.input.trim());
			Object.keys(content).forEach(key => this[key] = content[key]);
		} catch {}

		this.type ||= hm.rules_type[0][0];
		this.payload ||= [
			{type: hm.rules_type[0][0], factor: '', /* deny: false */},
			//{type: 'DOMAIN-SUFFIX', factor: '.google.com', deny: true}
		];
		this.detour ||= hm.preset_outbound.full[0][0];
		this.params ||= {/* src: false, no-resolve: true */};
		this.subrule ||= false;
	}

	setKey(key, value) {
		this[key] = value;

		return this
	}

	getPayload(n) {
		return this.payload[n] || {};
	}

	getPayloads() {
		return this.payload || [];
	}

	setPayload(n, obj, limit) {
		this.payload[n] ||= {};

		Object.keys(obj).forEach((key) => {
			this.payload[n][key] = obj[key] || null;
		});

		if (limit)
			this.payload.splice(limit);

		return this
	}

	getParam(param) {
		return this.params?.[param] || null;
	}

	setParam(param, value) {
		if (value) {
			this.params[param] = value;
		} else
			this.params[param] = null;

		return this
	}

	_payloadStrategy(payload) {
		// LOGIC_TYPE,((payload1),(payload2))
		if (payload.factor === null || ['undefined', 'boolean', 'number', 'string'].includes(typeof(payload.factor))) {
			return (payload.deny ? 'NOT,((%s))' : '%s').format([payload.type, payload.factor ?? ''].join(','));
		} else if (payload.factor?.constructor === Array) {
			return `${payload.type},(%s)`.format(payload.factor.map(p => `(${this._payloadStrategy(p)})`).join(','));
		} else if (payload.factor?.constructor === Object) {
			throw new Error(`Factor type cannot be an object: '${JSON.stringify(payload.factor)}'`);
		} else
			throw new Error(`Factor type is incorrect: '${payload.factor}'`);
	}

	_toMihomo(rule, logical) {
		let payload = this._payloadStrategy(logical ? {type: rule.type, factor: rule.payload} : rule.payload[0]);

		if (rule.subrule)
			return 'SUB-RULE,(%s),%s'.format(payload, rule.subrule);
		else
			if (rule.type === 'MATCH')
				return [rule.type, rule.detour].join(',');
			else
				return [payload, rule.detour].concat(
					rule.params ? ['no-resolve', 'src'].filter(k => rule.params[k]) : []
				).join(',');
	}

	toString(format) {
		format ||= 'json';
		let logical = hm.rules_logical_type.map(e => e[0] || e).includes(this.type);
		let rule, factor, detour, params;

		if (logical) {
			let n = hm.rules_logical_payload_count[this.type] ? hm.rules_logical_payload_count[this.type].high : 0;
			factor = this.payload.slice(0, n);
		} else
			factor = [ {...this.payload[0], ...{type: this.type}} ];

		if (!this.subrule) {
			detour = this.detour;
			params = this.params;
			if (this.type === 'MATCH')
				factor = [{type: 'MATCH'}];
		}

		rule = hm.removeBlankAttrs(hm, {
			type: this.type,
			payload: factor,
			detour: detour || null,
			params: params || null,
			subrule: this.subrule || null,
		});

		if (format === 'json')
			return JSON.stringify(rule);
		else if (format === 'mihomo')
			return this._toMihomo(rule, logical);
		else
			throw new Error(`Unknown format: '${format}'`);
	}
}

function boolToFlag(boolean) {
	if (typeof(boolean) !== 'boolean')
		return null;

	switch(boolean) {
	case true:
		return '1';
	case false:
		return '0';
	default:
		return null;
	}
}
function flagToBool(flag) {
	if (!flag)
		return null;

	switch(flag) {
	case '1':
		return true;
	case '0':
		return false;
	default:
		return null;
	}
}

function renderPayload(s, total, uciconfig) {
	// common payload
	let initPayload = function(o, n, key, uciconfig) {
		o.load = L.bind(function(n, key, uciconfig, section_id) {
			return new RulesEntry(uci.get(uciconfig, section_id, 'entry')).getPayload(n)[key];
		}, o, n, key, uciconfig);
		o.onchange = function(ev, section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'entry');

			let n = this.option.match(/^payload(\d+)_/)[1];
			let rule = new RulesEntry(UIEl.getValue()).setPayload(n, {factor: value});

			UIEl.node.previousSibling.innerText = rule.toString('mihomo');
			UIEl.setValue(rule.toString('json'));
		}
		o.write = function() {};
		o.rmempty = false;
		o.modalonly = true;
	}
	let initDynamicPayload = function(o, n, key, uciconfig) {
		o.allowduplicates = true;
		o.load = L.bind(function(n, key, uciconfig, section_id) {
			return new RulesEntry(uci.get(uciconfig, section_id, 'entry')).getPayloads().slice(n).map(e => e[key] ?? '');
		}, o, n, key, uciconfig);
		o.validate = function(section_id, value) {
			value = this.formvalue(section_id);
			let UIEl = this.section.getUIElement(section_id, 'entry');
			let rule = new RulesEntry(UIEl.getValue());

			let n = this.option.match(/^payload(\d+)_/)[1];
			let limit = rule.getPayloads().length;
			value.forEach((val) => {
				rule.setPayload(n, {factor: val}); n++;
			});
			rule.setPayload(limit, {factor: null}, limit);

			UIEl.node.previousSibling.innerText = rule.toString('mihomo');
			UIEl.setValue(rule.toString('json'));

			return true;
		}
		o.write = function() {};
		o.rmempty = true;
		o.modalonly = true;
	}

	let o, prefix;
	// StaticList payload
	for (let n=0; n<total; n++) {
		prefix = `payload${n}_`;

		o = s.option(form.ListValue, prefix + 'type', _('Type') + ` ${n+1}`);
		o.default = hm.rules_type[0][0];
		hm.rules_type.forEach((res) => {
			o.value.apply(o, res);
		})
		Object.keys(hm.rules_logical_payload_count).forEach((key) => {
			if (n < hm.rules_logical_payload_count[key].low)
				o.depends('type', key);
		})
		initPayload(o, n, 'type', uciconfig);
		o.onchange = function(ev, section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'entry');

			let n = this.option.match(/^payload(\d+)_/)[1];
			let rule = new RulesEntry(UIEl.getValue()).setPayload(n, {type: value});

			UIEl.node.previousSibling.innerText = rule.toString('mihomo');
			UIEl.setValue(rule.toString('json'));
		}

		o = s.option(form.Value, prefix + 'general', _('Factor') + ` ${n+1}`);
		if (n === 0) {
			o.depends({type: /\bDOMAIN\b/});
			o.depends({type: /\bGEO(SITE|IP)\b/});
			o.depends({type: /\bASN\b/});
			o.depends({type: /\bPROCESS\b/});
		}
		o.depends(Object.fromEntries([[prefix + 'type', /\bDOMAIN\b/]]));
		o.depends(Object.fromEntries([[prefix + 'type', /\bGEO(SITE|IP)\b/]]));
		o.depends(Object.fromEntries([[prefix + 'type', /\bASN\b/]]));
		o.depends(Object.fromEntries([[prefix + 'type', /\bPROCESS\b/]]));
		initPayload(o, n, 'factor', uciconfig);

		o = s.option(form.Value, prefix + 'ip', _('Factor') + ` ${n+1}`);
		o.datatype = 'cidr';
		if (n === 0) {
			o.depends({type: /\b(CIDR|CIDR6)\b/});
			o.depends({type: /\bIP-SUFFIX\b/});
		}
		o.depends(Object.fromEntries([[prefix + 'type', /\b(CIDR|CIDR6)\b/]]));
		o.depends(Object.fromEntries([[prefix + 'type', /\bIP-SUFFIX\b/]]));
		initPayload(o, n, 'factor', uciconfig);

		o = s.option(form.Value, prefix + 'port', _('Factor') + ` ${n+1}`);
		o.datatype = 'or(port, portrange)';
		if (n === 0)
			o.depends({type: /\bPORT\b/});
		o.depends(Object.fromEntries([[prefix + 'type', /\bPORT\b/]]));
		initPayload(o, n, 'factor', uciconfig);

		o = s.option(form.ListValue, prefix + 'l4', _('Factor') + ` ${n+1}`);
		o.value('udp', _('UDP'));
		o.value('tcp', _('TCP'));
		if (n === 0)
			o.depends('type', 'NETWORK');
		o.depends(prefix + 'type', 'NETWORK');
		initPayload(o, n, 'factor', uciconfig);

		o = s.option(form.Value, prefix + 'dscp', _('Factor') + ` ${n+1}`);
		o.datatype = 'range(0, 63)';
		if (n === 0)
			o.depends('type', 'DSCP');
		o.depends(prefix + 'type', 'DSCP');
		initPayload(o, n, 'factor', uciconfig);

		o = s.option(form.ListValue, prefix + 'rule_set', _('Factor') + ` ${n+1}`);
		if (n === 0)
			o.depends('type', 'RULE-SET');
		o.depends(prefix + 'type', 'RULE-SET');
		initPayload(o, n, 'factor', uciconfig);
		o.load = L.bind(function(n, key, uciconfig, section_id) {
			hm.loadRulesetLabel.call(this, [], null, section_id);

			return new RulesEntry(uci.get(uciconfig, section_id, 'entry')).getPayload(n)[key];
		}, o, n, 'factor', uciconfig)

		o = s.option(form.Flag, prefix + 'NOT', _('NOT') + ` ${n+1}`);
		o.default = o.disabled;
		o.depends(Object.fromEntries([[prefix + 'type', /.+/]]));
		initPayload(o, n, 'deny', uciconfig);
		o.load = L.bind(function(n, key, uciconfig, section_id) {
			return boolToFlag(new RulesEntry(uci.get(uciconfig, section_id, 'entry')).getPayload(n)[key] ? true : false);
		}, o, n, 'deny', uciconfig);
		o.onchange = function(ev, section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'entry');

			let n = this.option.match(/^payload(\d+)_/)[1];
			let rule = new RulesEntry(UIEl.getValue()).setPayload(n, {deny: flagToBool(value) || null});

			UIEl.node.previousSibling.innerText = rule.toString('mihomo');
			UIEl.setValue(rule.toString('json'));
		}
	}

	// DynamicList payload
	let extenbox = {};
	Object.entries(hm.rules_logical_payload_count).filter(e => e[1].high === undefined).forEach((e) => {
		let low = e[1].low;
		let type = e[0];
		if (!Array.isArray(extenbox[low]))
			extenbox[low] = [];
		extenbox[low].push(type);
	})
	Object.keys(extenbox).forEach((n) => {
		prefix = `payload${n}_`;

		o = s.option(hm.CBIStaticList, prefix + 'type', _('Type') + ' ++');
		o.default = hm.rules_type[0][0];
		hm.rules_type.forEach((res) => {
			o.value.apply(o, res);
		})
		extenbox[n].forEach((type) => {
			o.depends('type', type);
		})
		initDynamicPayload(o, n, 'type', uciconfig);
		o.validate = function(section_id, value) {
			value = this.formvalue(section_id);
			let UIEl = this.section.getUIElement(section_id, 'entry');
			let rule = new RulesEntry(UIEl.getValue());

			let n = this.option.match(/^payload(\d+)_/)[1];
			value.forEach((val) => {
				rule.setPayload(n, {type: val}); n++;
			});
			rule.setPayload(n, {type: null}, n);

			UIEl.node.previousSibling.innerText = rule.toString('mihomo');
			UIEl.setValue(rule.toString('json'));

			return true;
		}

		o = s.option(form.DynamicList, prefix + 'fused', _('Factor') + ' ++',
			_('Content will not be verified, Please make sure you enter it correctly.'));
		extenbox[n].forEach((type) => {
			o.depends(Object.fromEntries([['type', type], [prefix + 'type', /.+/]]));
		})
		initDynamicPayload(o, n, 'factor', uciconfig);
		o.load = L.bind(function(n, key, uciconfig, section_id) {
			let fusedval = [
				['NETWORK', '-- NETWORK --'],
				['udp', _('UDP')],
				['tcp', _('TCP')],
				['RULESET', '-- RULE-SET --']
			];
			hm.loadRulesetLabel.call(this, fusedval, null, section_id);
			this.super('load', section_id);

			return new RulesEntry(uci.get(uciconfig, section_id, 'entry')).getPayloads().slice(n).map(e => e[key] ?? '');
		}, o, n, 'factor', uciconfig)

		o = s.option(hm.CBIStaticList, prefix + 'NOTs', _('NOT') + ' ++',
			_('<code>0</code> or <code>1</code> only.'));
		o.value('0');
		o.value('1');
		extenbox[n].forEach((type) => {
			o.depends(Object.fromEntries([['type', type], [prefix + 'type', /.+/]]));
		})
		initDynamicPayload(o, n, 'deny', uciconfig);
		o.load = L.bind(function(n, key, uciconfig, section_id) {
			return new RulesEntry(uci.get(uciconfig, section_id, 'entry')).getPayloads().slice(n).map(e => boolToFlag(e[key] ? true : false));
		}, o, n, 'deny', uciconfig);
		o.validate = function(section_id, value) {
			value = this.formvalue(section_id);
			let UIEl = this.section.getUIElement(section_id, 'entry');
			let rule = new RulesEntry(UIEl.getValue());

			let n = this.option.match(/^payload(\d+)_/)[1];
			let limit = rule.getPayloads().length;
			value.forEach((value) => {
				rule.setPayload(n, {deny: flagToBool(value) || null}); n++;
			});
			rule.setPayload(limit, {deny: null}, limit);

			UIEl.node.previousSibling.innerText = rule.toString('mihomo');
			UIEl.setValue(rule.toString('json'));

			return true;
		}
	})
}

function renderRules(s, uciconfig) {
	let o;

	o = s.option(form.DummyValue, 'entry', _('Entry'));
	o.renderWidget = function(/* ... */) {
		let El = form.DummyValue.prototype.renderWidget.apply(this, arguments);

		El.firstChild.innerText = new RulesEntry(El.querySelector('input').value).toString('mihomo');

		return El;
	}
	o.load = function(section_id) {
		return form.DummyValue.prototype.load.call(this, section_id) || new RulesEntry().toString('json');
	}
	o.write = L.bind(form.AbstractValue.prototype.write, o);
	o.remove = L.bind(form.AbstractValue.prototype.remove, o);
	o.editable = true;

	o = s.option(form.ListValue, 'type', _('Type'));
	o.default = hm.rules_type[0][0];
	[...hm.rules_type, ...hm.rules_logical_type].forEach((res) => {
		o.value.apply(o, res);
	})
	o.load = function(section_id) {
		return new RulesEntry(uci.get(uciconfig, section_id, 'entry')).type;
	}
	o.validate = function(section_id, value) {
		// params only available for types other than
		// https://github.com/muink/mihomo/blob/43f21c0b412b7a8701fe7a2ea6510c5b985a53d6/config/config.go#L1050
		// https://github.com/muink/mihomo/blob/43f21c0b412b7a8701fe7a2ea6510c5b985a53d6/rules/parser.go#L12
		if (['GEOIP', 'IP-ASN', 'IP-CIDR', 'IP-CIDR6', 'IP-SUFFIX', 'RULE-SET'].includes(value)) {
			['no-resolve', 'src'].forEach((opt) => {
				let UIEl = this.section.getUIElement(section_id, opt);
				UIEl.node.querySelector('input').disabled = null;
			});
		} else {
			['no-resolve', 'src'].forEach((opt) => {
				let UIEl = this.section.getUIElement(section_id, opt);
				UIEl.setValue('');
				UIEl.node.querySelector('input').disabled = 'true';
			});

			let UIEl = this.section.getUIElement(section_id, 'entry');

			let rule = new RulesEntry(UIEl.getValue()).setParam('no-resolve').setParam('src');

			UIEl.node.previousSibling.innerText = rule.toString('mihomo');
			UIEl.setValue(rule.toString('json'));
		}

		return true;
	}
	o.onchange = function(ev, section_id, value) {
		let UIEl = this.section.getUIElement(section_id, 'entry');

		let rule = new RulesEntry(UIEl.getValue()).setKey('type', value);

		UIEl.node.previousSibling.innerText = rule.toString('mihomo');
		UIEl.setValue(rule.toString('json'));
	}
	o.write = function() {};
	o.rmempty = false;
	o.modalonly = true;

	renderPayload(s, Math.max(...Object.values(hm.rules_logical_payload_count).map(e => e.low)), uciconfig);

	o = s.option(hm.CBIListValue, 'detour', _('Proxy group'));
	o.load = function(section_id) {
		hm.loadProxyGroupLabel.call(this, hm.preset_outbound.full, section_id);

		return new RulesEntry(uci.get(uciconfig, section_id, 'entry')).detour;
	}
	o.onchange = function(ev, section_id, value) {
		let UIEl = this.section.getUIElement(section_id, 'entry');

		let rule = new RulesEntry(UIEl.getValue()).setKey('detour', value);

		UIEl.node.previousSibling.innerText = rule.toString('mihomo');
		UIEl.setValue(rule.toString('json'));
	}
	o.write = function() {};
	//o.depends('SUB-RULE', '');
	o.editable = true;

	o = s.option(form.Flag, 'src', _('src'));
	o.default = o.disabled;
	o.load = function(section_id) {
		return boolToFlag(new RulesEntry(uci.get(uciconfig, section_id, 'entry')).getParam('src') ? true : false);
	}
	o.onchange = function(ev, section_id, value) {
		let UIEl = this.section.getUIElement(section_id, 'entry');

		let rule = new RulesEntry(UIEl.getValue()).setParam('src', flagToBool(value) || null);

		UIEl.node.previousSibling.innerText = rule.toString('mihomo');
		UIEl.setValue(rule.toString('json'));
	}
	o.write = function() {};
	o.depends('SUB-RULE', '');
	o.modalonly = true;

	o = s.option(form.Flag, 'no-resolve', _('no-resolve'));
	o.default = o.disabled;
	o.load = function(section_id) {
		return boolToFlag(new RulesEntry(uci.get(uciconfig, section_id, 'entry')).getParam('no-resolve') ? true : false);
	}
	o.onchange = function(ev, section_id, value) {
		let UIEl = this.section.getUIElement(section_id, 'entry');

		let rule = new RulesEntry(UIEl.getValue()).setParam('no-resolve', flagToBool(value) || null);

		UIEl.node.previousSibling.innerText = rule.toString('mihomo');
		UIEl.setValue(rule.toString('json'));
	}
	o.write = function() {};
	o.depends('SUB-RULE', '');
	o.modalonly = true;
}

return view.extend({
	load() {
		return Promise.all([
			uci.load('fchomo')
		]);
	},

	render(data) {
		const dashboard_repo = uci.get(data[0], 'api', 'dashboard_repo');

		let m, s, o, ss, so;

		m = new form.Map('fchomo', _('Mihomo client'));

		s = m.section(form.TypedSection);
		s.render = function () {
			poll.add(function () {
				return hm.getServiceStatus('mihomo-c').then((isRunning) => {
					hm.updateStatus(hm, document.getElementById('_client_bar'), isRunning ? { dashboard_repo: dashboard_repo } : false, 'mihomo-c', true);
				});
			});

			return E('div', { class: 'cbi-section' }, [
				E('p', [
					hm.renderStatus(hm, '_client_bar', false, 'mihomo-c', true)
				])
			]);
		}

		s = m.section(form.NamedSection, 'routing', 'fchomo', null);

		/* Proxy Group START */
		s.tab('group', _('Proxy Group'));

		/* Client switch */
		o = s.taboption('group', form.Button, '_reload_client', _('Quick Reload'));
		o.inputtitle = _('Reload');
		o.inputstyle = 'apply';
		o.onclick = L.bind(hm.handleReload, o, 'mihomo-c');

		o = s.taboption('group', form.Flag, 'client_enabled', _('Enable'));
		o.default = o.disabled;

		/* Proxy Group */
		o = s.taboption('group', form.SectionValue, '_group', form.GridSection, 'proxy_group', null);
		ss = o.subsection;
		var prefmt = { 'prefix': 'group_', 'suffix': '' };
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.modaltitle = L.bind(hm.loadModalTitle, ss, _('Proxy Group'), _('Add a proxy group'));
		ss.sectiontitle = L.bind(hm.loadDefaultLabel, ss);
		ss.renderSectionAdd = L.bind(hm.renderSectionAdd, ss, prefmt, true);
		ss.handleAdd = L.bind(hm.handleAdd, ss, prefmt);

		ss.tab('field_general', _('General fields'));
		ss.tab('field_override', _('Override fields'));
		ss.tab('field_health', _('Health fields'));

		/* General fields */
		so = ss.taboption('field_general', form.Value, 'label', _('Label'));
		so.load = L.bind(hm.loadDefaultLabel, so);
		so.validate = function(section_id, value) {
			if (value.match(/[,]/))
				return _('Expecting: %s').format(_('not included ","'));

			return hm.validateUniqueValue.call(this, section_id, value);
		}
		so.modalonly = true;

		so = ss.taboption('field_general', form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;

		so = ss.taboption('field_general', form.ListValue, 'type', _('Type'));
		so.default = hm.proxy_group_type[0][0];
		hm.proxy_group_type.forEach((res) => {
			so.value.apply(so, res);
		})

		so = ss.taboption('field_general', form.MultiValue, 'groups', _('Group'));
		hm.preset_outbound.full.forEach((res) => {
			so.value.apply(so, res);
		})
		so.load = L.bind(hm.loadProxyGroupLabel, so, hm.preset_outbound.full);
		so.editable = true;

		so = ss.taboption('field_general', form.MultiValue, 'proxies', _('Node'));
		so.value('', _('-- Please choose --'));
		so.load = L.bind(hm.loadNodeLabel, so, [['', _('-- Please choose --')]]);
		so.validate = function(section_id, value) {
			if (this.section.getOption('include_all').formvalue(section_id) === '1' ||
			    this.section.getOption('include_all_proxies').formvalue(section_id) === '1')
				this.getUIElement(section_id, this.option).node.setAttribute('disabled', '');
			else
				this.getUIElement(section_id, this.option).node.removeAttribute('disabled');

			return true;
		}
		so.editable = true;

		so = ss.taboption('field_general', form.MultiValue, 'use', _('Provider'));
		so.value('', _('-- Please choose --'));
		so.load = L.bind(hm.loadProviderLabel, so, [['', _('-- Please choose --')]]);
		so.validate = function(section_id, value) {
			if (this.section.getOption('include_all').formvalue(section_id) === '1' ||
			    this.section.getOption('include_all_providers').formvalue(section_id) === '1')
				this.getUIElement(section_id, this.option).node.setAttribute('disabled', '');
			else
				this.getUIElement(section_id, this.option).node.removeAttribute('disabled');

			return true;
		}
		so.editable = true;

		so = ss.taboption('field_general', form.Flag, 'include_all', _('Include all'),
			_('Includes all Proxy Node and Provider.'));
		so.default = so.disabled;
		so.editable = true;

		so = ss.taboption('field_general', form.Flag, 'include_all_proxies', _('Include all node'),
			_('Includes all Proxy Node.'));
		so.default = so.disabled;
		so.editable = true;

		so = ss.taboption('field_general', form.Flag, 'include_all_providers', _('Include all provider'),
			_('Includes all Provider.'));
		so.default = so.disabled;
		so.editable = true;

		/* Override fields */
		so = ss.taboption('field_override', form.Flag, 'disable_udp', _('Disable UDP'));
		so.default = so.disabled;
		so.modalonly = true;

		so = ss.taboption('field_override', widgets.DeviceSelect, 'interface_name', _('Bind interface'),
			_('Bind outbound interface.</br>') +
			_('Priority: Proxy Node > Proxy Group > Global.'));
		so.multiple = false;
		so.noaliases = true;
		so.modalonly = true;

		so = ss.taboption('field_override', form.Value, 'routing_mark', _('Routing mark'),
			_('Priority: Proxy Node > Proxy Group > Global.'));
		so.datatype = 'uinteger';
		so.modalonly = true;

		/* Health fields */
		/* Url-test/Fallback/Load-balance */
		so = ss.taboption('field_health', form.Value, 'url', _('Health check URL'));
		so.default = hm.health_checkurls[0][0];
		hm.health_checkurls.forEach((res) => {
			so.value.apply(so, res);
		})
		so.validate = L.bind(hm.validateUrl, so);
		so.depends({type: 'select', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_health', form.Value, 'interval', _('Health check interval'),
			_('In seconds. <code>%s</code> will be used if empty.').format('600'));
		so.placeholder = '600';
		so.validate = L.bind(hm.validateTimeDuration, so);
		so.depends({type: 'select', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_health', form.Value, 'timeout', _('Health check timeout'),
			_('In millisecond. <code>%s</code> will be used if empty.').format('5000'));
		so.datatype = 'uinteger';
		so.placeholder = '5000';
		so.depends({type: 'select', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_health', form.Flag, 'lazy', _('Lazy'),
			_('No testing is performed when this provider node is not in use.'));
		so.default = so.enabled;
		so.depends({type: 'select', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_health', form.Value, 'expected_status', _('Health check expected status'),
			_('Expected HTTP code. <code>204</code> will be used if empty. ') +
			_('For format see <a target="_blank" href="%s" rel="noreferrer noopener">%s</a>.')
				.format('https://wiki.metacubex.one/config/proxy-groups/#expected-status', _('Expected status')));
		so.placeholder = '200/302/400-503';
		so.depends({type: 'select', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_health', form.Value, 'max_failed_times', _('Max count of failures'),
			_('Exceeding this triggers a forced health check. <code>5</code> will be used if empty.'));
		so.datatype = 'uinteger';
		so.placeholder = '5';
		so.depends({type: 'select', '!reverse': true});
		so.modalonly = true;

		/* Url-test fields */
		so = ss.taboption('field_general', form.Value, 'tolerance', _('Node switch tolerance'),
			_('In millisecond. <code>%s</code> will be used if empty.').format('150'));
		so.datatype = 'uinteger';
		so.placeholder = '150';
		so.depends('type', 'url-test');
		so.modalonly = true;

		/* Load-balance fields */
		so = ss.taboption('field_general', form.ListValue, 'strategy', _('Strategy'),
			_('For details, see <a target="_blank" href="%s" rel="noreferrer noopener">%s</a>.')
			.format('https://wiki.metacubex.one/config/proxy-groups/load-balance/#strategy', _('Strategy')));
		so.default = hm.load_balance_strategy[0][0];
		hm.load_balance_strategy.forEach((res) => {
			so.value.apply(so, res);
		})
		so.depends('type', 'load-balance');
		so.modalonly = true;

		/* General fields */
		so = ss.taboption('field_general', form.DynamicList, 'filter', _('Node filter'),
			_('Filter nodes that meet keywords or regexps.'));
		so.placeholder = '(?i)港|hk|hongkong|hong kong';
		so.modalonly = true;

		so = ss.taboption('field_general', form.DynamicList, 'exclude_filter', _('Node exclude filter'),
			_('Exclude nodes that meet keywords or regexps.'));
		so.placeholder = 'xxx';
		so.modalonly = true;

		so = ss.taboption('field_general', form.DynamicList, 'exclude_type', _('Node exclude type'),
			_('Exclude matched node types. Available types see <a target="_blank" href="%s" rel="noreferrer noopener">here</a>.')
			.format('https://wiki.metacubex.one/config/proxy-groups/#exclude-type'));
		so.placeholder = 'Shadowsocks|Trojan';
		so.modalonly = true;
		/* Proxy Group END */

		/* Routing rules START */
		s.tab('rules', _('Routing rule'));

		/* Routing rules */
		o = s.taboption('rules', form.SectionValue, '_rules', form.GridSection, 'rules', null);
		ss = o.subsection;
		var prefmt = { 'prefix': '', 'suffix': '_host' };
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.modaltitle = L.bind(hm.loadModalTitle, ss, _('Routing rule'), _('Add a routing rule'));
		ss.sectiontitle = L.bind(hm.loadDefaultLabel, ss);
		ss.renderSectionAdd = L.bind(hm.renderSectionAdd, ss, prefmt, false);
		ss.handleAdd = L.bind(hm.handleAdd, ss, prefmt);

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = L.bind(hm.loadDefaultLabel, so);
		so.validate = L.bind(hm.validateUniqueValue, so);
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;

		renderRules(ss, data[0]);

		so = ss.option(form.ListValue, 'SUB-RULE', _('SUB-RULE'));
		so.load = function(section_id) {
			hm.loadSubRuleGroup.call(this, [['', _('-- Please choose --')]], section_id);

			return new RulesEntry(uci.get(data[0], section_id, 'entry')).subrule || '';
		}
		so.validate = function(section_id, value) {
			value = this.formvalue(section_id);

			this.section.getUIElement(section_id, 'detour').node.querySelector('select').disabled = value ? 'true' : null;

			return true;
		}
		so.onchange = function(ev, section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'entry');

			let rule = new RulesEntry(UIEl.getValue()).setKey('subrule', value);

			UIEl.node.previousSibling.innerText = rule.toString('mihomo');
			UIEl.setValue(rule.toString('json'));
		}
		so.write = function() {};
		so.modalonly = true;
		/* Routing rules END */

		/* Sub rules START */
		s.tab('subrules', _('Sub rule'));

		/* Sub rules */
		o = s.taboption('subrules', form.SectionValue, '_subrules', form.GridSection, 'subrules', null);
		ss = o.subsection;
		var prefmt = { 'prefix': '', 'suffix': '_subhost' };
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.modaltitle = L.bind(hm.loadModalTitle, ss, _('Sub rule'), _('Add a sub rule'));
		ss.sectiontitle = L.bind(hm.loadDefaultLabel, ss);
		ss.renderSectionAdd = L.bind(hm.renderSectionAdd, ss, prefmt, false);
		ss.handleAdd = L.bind(hm.handleAdd, ss, prefmt);

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = L.bind(hm.loadDefaultLabel, so);
		so.validate = L.bind(hm.validateUniqueValue, so);
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;

		so = ss.option(form.Value, 'group', _('Sub rule group'));
		so.value('sub-rule1');
		so.rmempty = false;
		so.validate = L.bind(hm.validateAuthUsername, so);
		so.editable = true;

		renderRules(ss, data[0]);
		/* Sub rules END */

		/* DNS settings START */
		s.tab('dns', _('DNS settings'));

		/* DNS settings */
		o = s.taboption('dns', form.SectionValue, '_dns', form.NamedSection, 'dns', 'fchomo', null);
		ss = o.subsection;

		so = ss.option(form.Value, 'port', _('Listen port'));
		so.datatype = 'port'
		so.placeholder = '7853';
		so.rmempty = false;

		so = ss.option(form.Flag, 'ipv6', _('IPv6 support'));
		so.default = so.enabled;

		so = ss.option(form.MultiValue, 'boot_server', _('Boot DNS server'),
			_('Used to resolve the domain of the DNS server. Must be IP.'));
		so.default = 'default-dns';
		so.load = L.bind(loadDNSServerLabel, so);
		so.validate = L.bind(validateNameserver, so);
		so.rmempty = false;

		so = ss.option(form.MultiValue, 'bootnode_server', _('Boot DNS server (Node)'),
			_('Used to resolve the domain of the Proxy node.'));
		so.default = 'default-dns';
		so.load = L.bind(loadDNSServerLabel, so);
		so.validate = L.bind(validateNameserver, so);
		so.rmempty = false;

		so = ss.option(form.MultiValue, 'default_server', _('Default DNS server'));
		so.description = uci.get(data[0], so.section.section, 'fallback_server') ? _('Final DNS server (For non-poisoned domains)') : _('Final DNS server');
		so.default = 'default-dns';
		so.load = L.bind(loadDNSServerLabel, so);
		so.validate = L.bind(validateNameserver, so);
		so.rmempty = false;

		so = ss.option(form.MultiValue, 'fallback_server', _('Fallback DNS server'));
		so.description = uci.get(data[0], so.section.section, 'fallback_server') ? _('Final DNS server (For poisoned domains)') : _('Fallback DNS server');
		so.load = L.bind(loadDNSServerLabel, so);
		so.validate = L.bind(validateNameserver, so);
		so.onchange = function(ev, section_id, value) {
			let ddesc = this.section.getUIElement(section_id, 'default_server').node.nextSibling;
			let fdesc = ev.target.nextSibling;
			if (value.length > 0) {
				ddesc.innerHTML = _('Final DNS server (For non-poisoned domains)');
				fdesc.innerHTML = _('Final DNS server (For poisoned domains)');
			} else {
				ddesc.innerHTML = _('Final DNS server');
				fdesc.innerHTML = _('Fallback DNS server');
			}
		}
		/* DNS settings END */

		/* DNS server START */
		s.tab('dns_server', _('DNS server'));

		/* DNS server */
		o = s.taboption('dns_server', form.SectionValue, '_dns_server', form.GridSection, 'dns_server', null);
		ss = o.subsection;
		var prefmt = { 'prefix': 'dns_', 'suffix': '' };
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.modaltitle = L.bind(hm.loadModalTitle, ss, _('DNS server'), _('Add a DNS server'));
		ss.sectiontitle = L.bind(hm.loadDefaultLabel, ss);
		ss.renderSectionAdd = L.bind(hm.renderSectionAdd, ss, prefmt, true);
		ss.handleAdd = L.bind(hm.handleAdd, ss, prefmt);

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = L.bind(hm.loadDefaultLabel, so);
		so.validate = L.bind(hm.validateUniqueValue, so);
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;

		so = ss.option(form.DummyValue, 'address', _('Address'));
		so.write = L.bind(form.AbstractValue.prototype.write, so);
		so.remove = L.bind(form.AbstractValue.prototype.remove, so);
		so.editable = true;

		so = ss.option(form.Value, 'addr', _('Address'));
		so.load = function(section_id) {
			return new DNSAddress(uci.get(data[0], section_id, 'address')).addr;
		}
		so.validate = function(section_id, value) {
			if (value.match('#'))
				return _('Expecting: %s').format(_('No add\'l params'));

			// params only available on DoH
			// https://github.com/muink/mihomo/blob/43f21c0b412b7a8701fe7a2ea6510c5b985a53d6/config/config.go#L1211C8-L1211C14
			if (value.match(/^https?:\/\//)){
				this.section.getUIElement(section_id, 'h3').node.querySelector('input').disabled = null;
				this.section.getUIElement(section_id, 'ecs').node.querySelector('input').disabled = null;
				this.section.getUIElement(section_id, 'ecs-override').node.querySelector('input').disabled = null;
			} else {
				let UIEl = this.section.getUIElement(section_id, 'address');

				let newvalue = new DNSAddress(UIEl.getValue()).setParam('h3').setParam('ecs').setParam('ecs-override').toString();

				UIEl.node.previousSibling.innerText = newvalue;
				UIEl.setValue(newvalue);

				['h3', 'ecs', 'ecs-override'].forEach((opt) => {
					let UIEl = this.section.getUIElement(section_id, opt);
					UIEl.setValue('');
					UIEl.node.querySelector('input').disabled = 'true';
				});
			}

			return true;
		}
		so.onchange = function(ev, section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'address');

			let newvalue = ('N' + UIEl.getValue()).replace(/^[^#]+/, value);

			UIEl.node.previousSibling.innerText = newvalue;
			UIEl.setValue(newvalue);
		}
		so.write = function() {};
		so.rmempty = false;
		so.modalonly = true;

		so = ss.option(hm.CBIListValue, 'detour', _('Proxy group'));
		so.load = function(section_id) {
			hm.loadProxyGroupLabel.call(this, hm.preset_outbound.dns, section_id);

			return new DNSAddress(uci.get(data[0], section_id, 'address')).parseParam('detour');
		}
		so.onchange = function(ev, section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'address');

			let newvalue = new DNSAddress(UIEl.getValue()).setParam('detour', value).toString();

			UIEl.node.previousSibling.innerText = newvalue;
			UIEl.setValue(newvalue);
		}
		so.write = function() {};
		so.editable = true;

		so = ss.option(form.Flag, 'h3', _('HTTP/3'));
		so.default = so.disabled;
		so.load = function(section_id) {
			return boolToFlag(new DNSAddress(uci.get(data[0], section_id, 'address')).parseParam('h3') ? true : false);
		}
		so.onchange = function(ev, section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'address');

			let newvalue = new DNSAddress(UIEl.getValue()).setParam('h3', flagToBool(value) || null).toString();

			UIEl.node.previousSibling.innerText = newvalue;
			UIEl.setValue(newvalue);
		}
		so.write = function() {};
		so.modalonly = true;

		so = ss.option(form.Value, 'ecs', _('EDNS Client Subnet'));
		so.datatype = 'cidr';
		so.load = function(section_id) {
			return new DNSAddress(uci.get(data[0], section_id, 'address')).parseParam('ecs');
		}
		so.onchange = function(ev, section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'address');

			let newvalue = new DNSAddress(UIEl.getValue()).setParam('ecs', value).toString();

			UIEl.node.previousSibling.innerText = newvalue;
			UIEl.setValue(newvalue);
		}
		so.write = function() {};
		so.modalonly = true;

		so = ss.option(form.Flag, 'ecs-override', _('ECS override'),
			_('Override ECS in original request.'));
		so.default = so.disabled;
		so.load = function(section_id) {
			return boolToFlag(new DNSAddress(uci.get(data[0], section_id, 'address')).parseParam('ecs-override') ? true : false);
		}
		so.onchange = function(ev, section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'address');

			let newvalue = new DNSAddress(UIEl.getValue()).setParam('ecs-override', flagToBool(value) || null).toString();

			UIEl.node.previousSibling.innerText = newvalue;
			UIEl.setValue(newvalue);
		}
		so.write = function() {};
		so.depends({'ecs': /.+/});
		so.modalonly = true;
		/* DNS server END */

		/* DNS policy START */
		s.tab('dns_policy', _('DNS policy'));

		/* DNS policy */
		o = s.taboption('dns_policy', form.SectionValue, '_dns_policy', form.GridSection, 'dns_policy', null);
		ss = o.subsection;
		var prefmt = { 'prefix': '', 'suffix': '_domain' };
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.modaltitle = L.bind(hm.loadModalTitle, ss, _('DNS policy'), _('Add a DNS policy'));
		ss.sectiontitle = L.bind(hm.loadDefaultLabel, ss);
		ss.renderSectionAdd = L.bind(hm.renderSectionAdd, ss, prefmt, false);
		ss.handleAdd = L.bind(hm.handleAdd, ss, prefmt);

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = L.bind(hm.loadDefaultLabel, so);
		so.validate = L.bind(hm.validateUniqueValue, so);
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;

		so = ss.option(form.ListValue, 'type', _('Type'));
		so.value('domain', _('Domain'));
		so.value('geosite', _('Geosite'));
		so.value('rule_set', _('Rule set'));
		so.default = 'domain';

		so = ss.option(form.DynamicList, 'domain', _('Domain'),
			_('Match domain. Support wildcards.'));
		so.depends('type', 'domain');
		so.modalonly = true;

		so = ss.option(form.DynamicList, 'geosite', _('Geosite'),
			_('Match geosite.'));
		so.depends('type', 'geosite');
		so.modalonly = true;

		so = ss.option(form.MultiValue, 'rule_set', _('Rule set'),
			_('Match rule set.'));
		so.value('', _('-- Please choose --'));
		so.load = L.bind(hm.loadRulesetLabel, so, [['', _('-- Please choose --')]], ['domain', 'classical']);
		so.depends('type', 'rule_set');
		so.modalonly = true;

		so = ss.option(form.DummyValue, '_entry', _('Entry'));
		so.load = function(section_id) {
			const option = uci.get(data[0], section_id, 'type');

			return uci.get(data[0], section_id, option)?.join(',');
		}
		so.modalonly = false;

		so = ss.option(form.MultiValue, 'server', _('DNS server'));
		so.value('default-dns');
		so.default = 'default-dns';
		so.load = L.bind(loadDNSServerLabel, so);
		so.validate = L.bind(validateNameserver, so);
		so.rmempty = false;
		so.editable = true;

		so = ss.option(hm.CBIListValue, 'proxy', _('Proxy group override'),
			_('Override the Proxy group of DNS server.'));
		so.default = hm.preset_outbound.direct[0][0];
		hm.preset_outbound.direct.forEach((res) => {
			so.value.apply(so, res);
		})
		so.load = L.bind(hm.loadProxyGroupLabel, so, hm.preset_outbound.direct);
		so.editable = true;
		/* DNS policy END */

		/* Fallback filter START */
		s.tab('fallback_filter', _('Fallback filter'));

		/* Fallback filter */
		o = s.taboption('fallback_filter', form.SectionValue, '_fallback_filter', form.NamedSection, 'dns', 'fchomo', null);
		o.depends({'fchomo.dns.fallback_server': /.+/});
		ss = o.subsection;

		so = ss.option(form.Flag, 'fallback_filter_geoip', _('Geoip enable'));
		so.default = so.enabled;

		so = ss.option(form.Value, 'fallback_filter_geoip_code', _('Geoip code'),
			_('Match response with geoip.</br>') +
			_('The matching <code>%s</code> will be deemed as not-poisoned.').format(_('IP')));
		so.default = 'cn';
		so.placeholder = 'cn';
		so.rmempty = false;
		so.retain = true;
		so.depends('fallback_filter_geoip', '1');

		so = ss.option(form.DynamicList, 'fallback_filter_geosite', _('Geosite'),
			_('Match geosite.</br>') +
			_('The matching <code>%s</code> will be deemed as poisoned.').format(_('Domain')));

		so = ss.option(form.DynamicList, 'fallback_filter_ipcidr', _('IP CIDR'),
			_('Match response with ipcidr.</br>') +
			_('The matching <code>%s</code> will be deemed as poisoned.').format(_('IP')));
		so.datatype = 'list(cidr)';

		so = ss.option(form.DynamicList, 'fallback_filter_domain', _('Domain'),
			_('Match domain. Support wildcards.</br>') +
			_('The matching <code>%s</code> will be deemed as poisoned.').format(_('Domain')));
		/* Fallback filter END */

		return m.render();
	}
});
