'use strict';
'require form';
'require poll';
'require uci';
'require ui';
'require view';

'require fchomo as hm';
'require tools.widgets as widgets';

const parseProxyGroupYaml = hm.parseYaml.extend({
	key_mapping(cfg) {
		if (!cfg.type)
			return null;

		// key mapping // 2025/02/13
		let config = hm.removeBlankAttrs({
			id: this.id,
			label: this.label,
			type: cfg.type,
			groups: cfg.proxies ? cfg.proxies.map((grop) => hm.preset_outbound.full.map(([key, label]) => key).includes(grop) ? grop : this.calcID(hm.glossary["proxy_group"].field, grop)) : null, // array
			use: cfg.use ? cfg.use.map((prov) => this.calcID(hm.glossary["provider"].field, prov)) : null, // array
			include_all: this.bool2str(cfg["include-all"]), // bool
			include_all_proxies: this.bool2str(cfg["include-all-proxies"]), // bool
			include_all_providers: this.bool2str(cfg["include-all-providers"]), // bool
			// Url-test fields
			tolerance: cfg.tolerance,
			// Load-balance fields
			strategy: cfg.strategy,
			// Override fields
			disable_udp: this.bool2str(cfg["disable-udp"]), // bool
			// Health fields
			url: cfg.url,
			interval: cfg.interval,
			timeout: cfg.timeout,
			lazy: this.bool2str(cfg.lazy), // bool
			expected_status: cfg["expected-status"],
			max_failed_times: cfg["max-failed-times"],
			// General fields
			filter: [cfg.filter], // array.string: string
			exclude_filter: [cfg["exclude-filter"]], // array.string: string
			exclude_type: [cfg["exclude-type"]], // array.string: string
			hidden: this.bool2str(cfg.hidden), // bool
			icon: cfg.icon
		});

		return config;
	}
});

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
			['detour', 'h3', 'skip-cert-verify', 'ecs', 'ecs-override', 'disable-ipv4', 'disable-ipv6'].map((k) => {
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

		rule = hm.removeBlankAttrs({
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

const parseDNSYaml = hm.parseYaml.extend({
	key_mapping(cfg) {
		let addr = new DNSAddress(cfg);

		if (!addr.toString())
			return null;

		let detour = addr.parseParam('detour');
		if (detour)
			addr.setParam('detour', hm.preset_outbound.full.map(([key, label]) => key).includes(detour) ? detour : this.calcID(hm.glossary["proxy_group"].field, detour));

		// key mapping // 2025/12/01
		let config = {
			id: this.id,
			label: this.label,
			address: addr.toString()
		};

		return config;
	}
});

const parseDNSPolicyYaml = hm.parseYaml.extend({
	key_mapping(cfg) {
		//console.info([this.name, cfg]);

		let type = this.name.match(/^([^:]+):(.*)$/),
			rules;
		switch (type?.[1]) {
			case 'geosite':
				rules = type[2].split(',');
				type = 'geosite';
				break;
			case 'rule-set':
				rules = type[2].split(',').map((rule) => this.calcID(hm.glossary["ruleset"].field, rule));
				type = 'rule_set';
				break;
			default:
				rules = this.name.split(',');
				type = 'domain';
				break;
		}

		// key mapping // 2025/12/01
		let config = {
			id: this.id,
			label: this.label,
			type: type,
			...Object.fromEntries([[type, rules]]),
			server: (Array.isArray(cfg) ? cfg : [cfg]).map((dns) => this.calcID(hm.glossary["dns_server"].field, dns)),
			//proxy: null // fchomo unique features
		};

		return config;
	}
});

const parseRulesYaml = hm.parseYaml.extend({
	key_mapping(cfg) {
		let entry = this.parseRules(cfg); // 2025/07/11

		if (!entry)
			return null;

		// key mapping // 2025/07/11
		let config = {
			id: this.id,
			label: '%s %s'.format(this.id.slice(0,7), _('(Imported)')),
			entry: entry
		};

		return config;
	},

	ParseRulePayload(ruleRaw, needTarget) {
		// parse rules
		// https://github.com/muink/mihomo/blob/300eb8b12a75504c4bd4a6037d2f6503fd3b347f/rules/common/base.go#L48-L76
		let item = ruleRaw.split(",");
		let tp = item[0].toUpperCase(),
			payload,
			target,
			params = [];

		if (item.length > 1) {
			switch (tp) {
				case "MATCH":
					// MATCH doesn't contain payload and params
					target = item[1];
					break;
				case "NOT":
				case "OR":
				case "AND":
				case "SUB-RULE":
				case "DOMAIN-REGEX":
				case "PROCESS-NAME-REGEX":
				case "PROCESS-PATH-REGEX":
					// some type of rules that has comma in payload and don't need params
					if (needTarget)
						target = item.pop(); // don't have params so target must at the end of slices
					payload = item.slice(1).join(",");
					break;
				default:
					payload = item[1];
					if (item.length > 2) {
						if (needTarget) {
							target = item[2];
							if (item.length > 3)
								params = item.slice(3);
						} else
							params = item.slice(2);
					}
			}
		}

		return [ tp, payload, target, params ];
	},

	ParseRule(tp, payload, target, params) {
		// parse rules
		// https://github.com/muink/mihomo/blob/300eb8b12a75504c4bd4a6037d2f6503fd3b347f/rules/parser.go#L12

		// nested ParseRule
		let logical_payload, subrule;

		if (tp === 'SUB-RULE') {
			payload = payload.match(/^\((.*)\)$/); // SUB-RULE,(payload),subrule
			if (payload)
				[tp, payload, target, params, subrule] = [...this.ParseRulePayload(payload[1], false), target];
			else
				return null;
		}

		if (hm.rules_logical_type.map(e => e[0] || e).includes(tp)) {
			logical_payload = payload.match(/^\(\((.*)\)\)$/); // LOGIC_TYPE,((payload1),(payload2),(payload3)),DIRECT
			if (logical_payload)
				logical_payload = logical_payload[1].split('),(');
			else
				return null;
		}

		// make entry
		let entry = new RulesEntry();
		entry.type = tp;

		// parse payload
		if (logical_payload)
			for (let i=0; i < logical_payload.length; i++) {
				let type, factor, deny;

				// deny
				deny = logical_payload[i].match(/^NOT,\(\((.*)\)\)$/);
				if (deny)
					[type, factor] = deny[1].split(',');
				else
					[type, factor] = logical_payload[i].split(',');

				if (type === 'RULE-SET')
					factor = this.calcID(hm.glossary["ruleset"].field, factor);

				entry.setPayload(i, {type: type.toUpperCase(), factor: factor, deny: deny ? true : null});
			}
		else if (payload)
			if (tp === 'RULE-SET')
				entry.setPayload(0, {factor: this.calcID(hm.glossary["ruleset"].field, payload)});
			else
				entry.setPayload(0, {factor: payload});

		// parse target/subrule
		if (subrule)
			entry.subrule = subrule;
		else
			entry.detour = hm.preset_outbound.full.map(([key, label]) => key).includes(target) ? target : this.calcID(hm.glossary["proxy_group"].field, target);

		// parse params
		params.forEach((param) => entry.setParam(param, true));

		return entry;
	},

	parseRules(line) {
		// parse rules
		// https://github.com/muink/mihomo/blob/300eb8b12a75504c4bd4a6037d2f6503fd3b347f/config/config.go#L1038-L1062
		let [tp, payload, target, params] = this.ParseRulePayload(line, true);
		if (!target)
			return null; // error: format invalid

		let parsed = this.ParseRule(tp, payload, target, params);

		return parsed.toString('json');
	}
});
const parseSubrulesYaml = parseRulesYaml.extend({
	key_mapping(cfg) {
		cfg = cfg.match(/^([^:]+):(.+)$/);

		if (!cfg)
			return null;

		let config = new parseRulesYaml(this.field, this.name, cfg[2]).output(); // 2024/08/05

		return config ? Object.assign(config, {group: cfg[1]}) : null;
	}
});

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

		o = s.option(form.Value, prefix + 'uint', _('Factor') + ` ${n+1}`);
		o.datatype = 'uinteger';
		if (n === 0)
			o.depends('type', 'UID');
		o.depends(prefix + 'type', 'UID');
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

		o = s.option(hm.StaticList, prefix + 'type', _('Type') + ' ++');
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

		o = s.option(hm.less_25_12 ? hm.DynamicList : form.DynamicList, prefix + 'fused', _('Factor') + ' ++', // @less_25_12
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

		o = s.option(hm.StaticList, prefix + 'NOTs', _('NOT') + ' ++',
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
	o.write = form.AbstractValue.prototype.write;
	o.remove = form.AbstractValue.prototype.remove;
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
		if (hm.rules_type_allowparms.includes(value)) {
			['no-resolve', 'src'].forEach((opt) => {
				let UIEl = this.section.getUIElement(section_id, opt);
				UIEl.node.querySelector('input').removeAttribute('disabled');
			});
		} else {
			['no-resolve', 'src'].forEach((opt) => {
				let UIEl = this.section.getUIElement(section_id, opt);
				UIEl.setValue('');
				UIEl.node.querySelector('input').disabled = true;
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

	o = s.option(hm.ListValue, 'detour', _('Proxy group'));
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

	o = s.option(form.Flag, 'src', _('src'),
		_('Treat the <code>destination IP</code> as the <code>source IP</code>.'));
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

	o = s.option(form.Flag, 'no-resolve', _('no-resolve'),
		_('Do not resolve the domain connection to IP for this match.</br>' +
		'Only works for pure domain inbound connections without DNS resolution. e.g., socks5h'));
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
			poll.add(function() {
				return hm.getServiceStatus('mihomo-c').then((isRunning) => {
					hm.updateStatus(document.getElementById('_client_bar'), isRunning ? { dashboard_repo: dashboard_repo } : false, 'mihomo-c', true);
				});
			});

			return E('div', { class: 'cbi-section' }, [
				E('p', [
					hm.renderStatus('_client_bar', false, 'mihomo-c', true)
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
		o = s.taboption('group', form.SectionValue, '_group', hm.GridSection, 'proxy_group', null);
		ss = o.subsection;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.hm_modaltitle = [ _('Proxy Group'), _('Add a proxy group') ];
		ss.hm_prefmt = hm.glossary[ss.sectiontype].prefmt;
		ss.hm_field  = hm.glossary[ss.sectiontype].field;
		ss.hm_lowcase_only = true;
		/* Import mihomo config start */
		ss.handleYamlImport = function() {
			const field = this.hm_field;
			const o = new hm.HandleImport(this.map, this, _('Import mihomo config'),
				_('Please type <code>%s</code> fields of mihomo config.</br>')
					.format(field));
			o.placeholder = 'proxy-groups:\n' +
							'- name: "auto"\n' +
							'  type: url-test\n' +
							'  proxies:\n' +
							'    - ss1\n' +
							'    - ss2\n' +
							'    - vmess1\n' +
							'  tolerance: 150\n' +
							'  lazy: true\n' +
							'  expected-status: 204\n' +
							'  url: "https://cp.cloudflare.com/generate_204"\n' +
							'  interval: 300\n' +
							'  timeout: 5000\n' +
							'  max-failed-times: 5\n' +
							'- name: "fallback-auto"\n' +
							'  type: fallback\n' +
							'  proxies:\n' +
							'    - DIRECT\n' +
							'    - auto\n' +
							'  url: "https://cp.cloudflare.com/generate_204"\n' +
							'  interval: 300\n' +
							'- name: "load-balance"\n' +
							'  type: load-balance\n' +
							'  include-all: true\n' +
							'  url: "https://cp.cloudflare.com/generate_204"\n' +
							'  interval: 300\n' +
							'  lazy: false\n' +
							'  strategy: consistent-hashing\n' +
							'- name: AllProxy\n' +
							'  type: select\n' +
							'  disable-udp: true\n' +
							'  include-all-proxies: true\n' +
							'  use:\n' +
							'    - provider1\n' +
							'- name: AllProvider\n' +
							'  type: select\n' +
							'  include-all-providers: true\n' +
							'  filter: "(?i)港|hk|hongkong|hong kong"\n' +
							'  exclude-filter: "美|日"\n' +
							'  exclude-type: "Shadowsocks|Http"\n' +
							'  ...'
			o.parseYaml = parseProxyGroupYaml;

			return o.render();
		}
		ss.renderSectionAdd = function(/* ... */) {
			let el = hm.GridSection.prototype.renderSectionAdd.apply(this, arguments);

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('mihomo config'),
				'click': ui.createHandlerFn(this, 'handleYamlImport')
			}, [ _('Import mihomo config') ]));

			return el;
		}
		/* Import mihomo config end */

		ss.tab('field_general', _('General fields'));
		ss.tab('field_override', _('Override fields'));
		ss.tab('field_health', _('Health fields'));

		/* General fields */
		so = ss.taboption('field_general', form.Value, 'label', _('Label'));
		so.load = hm.loadDefaultLabel;
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

		/* Health fields */
		/* Url-test/Fallback/Load-balance */
		so = ss.taboption('field_health', form.Value, 'url', _('Health check URL'));
		so.default = hm.health_checkurls[0][0];
		hm.health_checkurls.forEach((res) => {
			so.value.apply(so, res);
		})
		so.validate = hm.validateUrl;
		so.depends({type: 'select', '!reverse': true});
		so.modalonly = true;

		so = ss.taboption('field_health', form.Value, 'interval', _('Health check interval'),
			_('In seconds. <code>%s</code> will be used if empty.').format('600'));
		so.placeholder = '600';
		so.validate = hm.validateTimeDuration;
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

		so = ss.taboption('field_general', form.Flag, 'hidden', _('Hidden'),
			_('Returns hidden status in the API to hide the display of this proxy group.') + '</br>' +
			_('requires front-end adaptation using the API.'));
		so.default = so.disabled;
		so.modalonly = true;

		so = ss.taboption('field_general', form.Value, 'icon', _('Icon'),
			_('Returns the string input for icon in the API to display in this proxy group.') + '</br>' +
			_('requires front-end adaptation using the API.'));
		so.modalonly = true;
		/* Proxy Group END */

		/* Routing rules START */
		s.tab('rules', _('Routing rule'));

		/* Routing rules */
		o = s.taboption('rules', form.SectionValue, '_rules', hm.GridSection, 'rules', null);
		ss = o.subsection;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.hm_modaltitle = [ _('Routing rule'), _('Add a routing rule') ];
		ss.hm_prefmt = hm.glossary[ss.sectiontype].prefmt;
		ss.hm_field  = hm.glossary[ss.sectiontype].field;
		ss.hm_lowcase_only = false;
		/* Import mihomo config start */
		ss.handleYamlImport = function() {
			const field = this.hm_field;
			const o = new hm.HandleImport(this.map, this, _('Import mihomo config'),
				_('Please type <code>%s</code> fields of mihomo config.</br>')
					.format(field));
			o.placeholder = 'rules:\n' +
							'- DOMAIN,ad.com,REJECT\n' +
							'- DOMAIN-WILDCARD,*.google.com,auto\n' +
							'- DOMAIN-REGEX,^abc.*com,auto\n' +
							'- GEOSITE,youtube,GLOBAL\n' +
							'- IP-CIDR,127.0.0.0/8,DIRECT,no-resolve\n' +
							'- IP-CIDR6,2620:0:2d0:200::7/32,auto\n' +
							'- IP-SUFFIX,8.8.8.8/24,auto\n' +
							'- IP-ASN,13335,DIRECT\n' +
							'- GEOIP,CN,DIRECT\n' +
							'- SRC-GEOIP,cn,DIRECT\n' +
							'- SRC-IP-ASN,9808,DIRECT\n' +
							'- SRC-IP-CIDR,192.168.1.201/32,DIRECT\n' +
							'- SRC-IP-SUFFIX,192.168.1.201/8,DIRECT\n' +
							'- DST-PORT,80,DIRECT\n' +
							'- SRC-PORT,7777,DIRECT\n' +
							'- PROCESS-PATH,/usr/bin/wget,auto\n' +
							'- PROCESS-PATH-REGEX,.*bin/wget,auto\n' +
							'- PROCESS-PATH-REGEX,(?i).*Application\\\\chrome.*,GLOBAL\n' +
							'- PROCESS-NAME,curl,auto\n' +
							'- PROCESS-NAME-REGEX,curl$,auto\n' +
							'- PROCESS-NAME-REGEX,(?i)Telegram,GLOBAL\n' +
							'- PROCESS-NAME-REGEX,.*telegram.*,GLOBAL\n' +
							'- UID,1001,DIRECT\n' +
							'- NETWORK,udp,DIRECT\n' +
							'- DSCP,4,DIRECT\n' +
							'- RULE-SET,google,GLOBAL,no-resolve\n' +
							'- AND,((DST-PORT,443),(NETWORK,udp)),REJECT\n' +
							'- OR,((NETWORK,UDP),(DOMAIN,baidu.com)),DIRECT\n' +
							'- NOT,((DOMAIN,baidu.com)),auto\n' +
							'- SUB-RULE,(NETWORK,tcp),sub-rule1\n' +
							'- SUB-RULE,(OR,((NETWORK,udp),(DOMAIN,google.com))),sub-rule2\n' +
							'- AND,((GEOIP,cn),(DSCP,12),(NETWORK,udp),(NOT,((IP-ASN,12345))),(DSCP,14),(NOT,((NETWORK,udp)))),DIRECT\n' +
							'- MATCH,GLOBAL\n' +
							'  ...'
			o.parseYaml = parseRulesYaml;

			return o.render();
		}
		ss.renderSectionAdd = function(/* ... */) {
			let el = hm.GridSection.prototype.renderSectionAdd.apply(this, arguments);

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('mihomo config'),
				'click': ui.createHandlerFn(this, 'handleYamlImport')
			}, [ _('Import mihomo config') ]));

			return el;
		}
		/* Import mihomo config end */

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = hm.loadDefaultLabel;
		so.validate = hm.validateUniqueValue;
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;
		so.validate = function(/* ... */) {
			let n = 0;

			return hm.validatePresetIDs.call(this, [
				['select', 'type'],
				['select', `payload${n}_` + 'rule_set']
			], ...arguments);
		}

		renderRules(ss, data[0]);

		so = ss.option(form.ListValue, 'SUB-RULE', _('SUB-RULE'));
		so.load = function(section_id) {
			hm.loadSubRuleGroup.call(this, [['', _('-- Please choose --')]], section_id);

			return new RulesEntry(uci.get(data[0], section_id, 'entry')).subrule || '';
		}
		so.validate = function(section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'detour');
			value = this.formvalue(section_id);

			UIEl.node.querySelector('select').disabled = value ? true : null;

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
		o = s.taboption('subrules', form.SectionValue, '_subrules', hm.GridSection, 'subrules', null);
		ss = o.subsection;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.hm_modaltitle = [ _('Sub rule'), _('Add a sub rule') ];
		ss.hm_prefmt = hm.glossary[ss.sectiontype].prefmt;
		ss.hm_field  = hm.glossary[ss.sectiontype].field;
		ss.hm_lowcase_only = false;
		/* Import mihomo config start */
		ss.handleYamlImport = function() {
			const field = this.hm_field;
			const o = new hm.HandleImport(this.map, this, _('Import mihomo config'),
				_('Please type <code>%s</code> fields of mihomo config.</br>')
					.format(field));
			o.placeholder = 'sub-rules:\n' +
							'  sub-rule1:\n' +
							'    - DOMAIN-SUFFIX,baidu.com,DIRECT\n' +
							'    - MATCH,GLOBAL\n' +
							'  sub-rule2:\n' +
							'    - IP-CIDR,1.1.1.1/32,REJECT\n' +
							'    - IP-CIDR,8.8.8.8/32,auto\n' +
							'    - DOMAIN,dns.alidns.com,REJECT\n' +
							'  ...'
			o.appendcommand = ' | with_entries(.key as $k | .value |= map("\\($k):" + .)) | [.[][]]'
			o.parseYaml = parseSubrulesYaml;

			return o.render();
		}
		ss.renderSectionAdd = function(/* ... */) {
			let el = hm.GridSection.prototype.renderSectionAdd.apply(this, arguments);

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('mihomo config'),
				'click': ui.createHandlerFn(this, 'handleYamlImport')
			}, [ _('Import mihomo config') ]));

			return el;
		}
		/* Import mihomo config end */

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = hm.loadDefaultLabel;
		so.validate = hm.validateUniqueValue;
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;

		so = ss.option(form.Value, 'group', _('Sub rule group'));
		so.value('sub-rule1');
		so.rmempty = false;
		so.validate = hm.validateAuthUsername;
		so.editable = true;

		renderRules(ss, data[0]);
		/* Sub rules END */

		/* DNS settings START */
		s.tab('dns', _('DNS settings'));

		/* DNS settings */
		o = s.taboption('dns', form.SectionValue, '_dns', form.NamedSection, 'dns', 'fchomo', null);
		ss = o.subsection;

		so = ss.option(form.Value, 'dns_port', _('Listen port'));
		so.datatype = 'port'
		so.placeholder = '7853';
		so.rmempty = false;

		so = ss.option(form.Flag, 'ipv6', _('IPv6 support'));
		so.default = so.enabled;

		so = ss.option(form.MultiValue, 'boot_server', _('Bootstrap DNS server'),
			_('Used to resolve the domain of the DNS server. Must be IP.'));
		so.default = 'default-dns';
		so.load = loadDNSServerLabel;
		so.validate = validateNameserver;
		so.rmempty = false;

		so = ss.option(form.MultiValue, 'bootnode_server', _('Bootstrap DNS server (Node)'),
			_('Used to resolve the domain of the Proxy node.'));
		so.default = 'default-dns';
		so.load = loadDNSServerLabel;
		so.validate = validateNameserver;
		so.rmempty = false;

		const ddesc_disabled = _('Final DNS server');
		const fdesc_disabled = _('Fallback DNS server');
		const ddesc_enabled = _('Final DNS server (For non-poisoned domains)') + '</br>' +
			_('Used to resolve domains that can be directly connected. Can use domestic DNS servers or ECS.');
		const fdesc_enabled = _('Final DNS server (For poisoned domains)') + '</br>' +
			_('Used to resolve domains you want to proxy. Recommended to configure %s for DNS servers.').format(_('Proxy Group'));

		so = ss.option(form.MultiValue, 'default_server', _('Default DNS server'));
		so.description = uci.get(data[0], so.section.section, 'fallback_server') ? ddesc_enabled : ddesc_disabled;
		so.default = 'default-dns';
		so.load = loadDNSServerLabel;
		so.validate = validateNameserver;
		so.rmempty = false;

		so = ss.option(form.MultiValue, 'fallback_server', _('Fallback DNS server'));
		so.description = uci.get(data[0], so.section.section, 'fallback_server') ? fdesc_enabled : fdesc_disabled;
		so.load = loadDNSServerLabel;
		so.validate = validateNameserver;
		so.onchange = function(ev, section_id, value) {
			let ddesc = this.section.getUIElement(section_id, 'default_server').node.nextSibling;
			let fdesc = ev.target.nextSibling;
			if (value.length > 0) {
				ddesc.innerHTML = ddesc_enabled;
				fdesc.innerHTML = fdesc_enabled;
			} else {
				ddesc.innerHTML = ddesc_disabled;
				fdesc.innerHTML = fdesc_disabled;
			}
		}
		/* DNS settings END */

		/* DNS server START */
		s.tab('dns_server', _('DNS server'));

		/* DNS server */
		o = s.taboption('dns_server', form.SectionValue, '_dns_server', hm.GridSection, 'dns_server', null);
		ss = o.subsection;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.hm_modaltitle = [ _('DNS server'), _('Add a DNS server') ];
		ss.hm_prefmt = hm.glossary[ss.sectiontype].prefmt;
		ss.hm_field  = hm.glossary[ss.sectiontype].field;
		ss.hm_lowcase_only = true;
		/* Import mihomo config start */
		ss.handleYamlImport = function() {
			const field = this.hm_field;
			const o = new hm.HandleImport(this.map, this, _('Import mihomo config'),
				_('Please type <code>%s</code> fields of mihomo config.</br>')
					.format(field));
			o.placeholder = 'dns:\n' +
							'  default-nameserver:\n' +
							'    - 223.5.5.5\n' +
							'    - tls://8.8.4.4:853\n' +
							'    - https://doh.pub/dns-query#DIRECT\n' +
							'    - https://dns.alidns.com/dns-query#auto&h3=true&ecs=1.1.1.1/24\n' +
							'  nameserver-policy:\n' +
							"    'geosite:category-ads-all': rcode://refused\n" +
							"    '+.arpa': '10.0.0.1'\n" +
							"    'rule-set:cn':\n" +
							'    - https://doh.pub/dns-query\n' +
							'    - https://dns.alidns.com/dns-query\n' +
							'  nameserver:\n' +
							'    - https://doh.pub/dns-query\n' +
							'    - https://dns.alidns.com/dns-query\n' +
							'  fallback:\n' +
							'    - tls://8.8.4.4\n' +
							'    - tls://1.1.1.1\n' +
							'  proxy-server-nameserver:\n' +
							'    - https://doh.pub/dns-query\n' +
							'  ...'
			o.overridecommand = '.dns | pick(["default-nameserver", "proxy-server-nameserver", "nameserver", "fallback", "nameserver-policy"]) | with(.["nameserver-policy"]; . = [.[]] | flatten) | [.[][]] | unique'
			o.parseYaml = parseDNSYaml;

			return o.render();
		}
		ss.renderSectionAdd = function(/* ... */) {
			let el = hm.GridSection.prototype.renderSectionAdd.apply(this, arguments);

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('mihomo config'),
				'click': ui.createHandlerFn(this, 'handleYamlImport')
			}, [ _('Import mihomo config') ]));

			return el;
		}
		/* Import mihomo config end */

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = hm.loadDefaultLabel;
		so.validate = hm.validateUniqueValue;
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;

		so = ss.option(form.DummyValue, 'address', _('Address'));
		so.write = form.AbstractValue.prototype.write;
		so.remove = form.AbstractValue.prototype.remove;
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
				this.section.getUIElement(section_id, 'h3').node.querySelector('input').removeAttribute('disabled');
			} else {
				let UIEl = this.section.getUIElement(section_id, 'address');

				let newvalue = new DNSAddress(UIEl.getValue()).setParam('h3').toString();

				UIEl.node.previousSibling.innerText = newvalue;
				UIEl.setValue(newvalue);

				['h3'].forEach((opt) => {
					let UIEl = this.section.getUIElement(section_id, opt);
					UIEl.setValue('');
					UIEl.node.querySelector('input').disabled = true;
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

		so = ss.option(hm.ListValue, 'detour', _('Proxy group'));
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

		so = ss.option(form.Flag, 'skip-cert-verify', _('Skip cert verify'),
			_('Donot verifying server certificate.') +
			'<br/>' +
			_('This is <strong>DANGEROUS</strong>, your traffic is almost like <strong>PLAIN TEXT</strong>! Use at your own risk!'));
		so.default = so.disabled;
		so.load = function(section_id) {
			return boolToFlag(new DNSAddress(uci.get(data[0], section_id, 'address')).parseParam('skip-cert-verify') ? true : false);
		}
		so.onchange = function(ev, section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'address');

			let newvalue = new DNSAddress(UIEl.getValue()).setParam('skip-cert-verify', flagToBool(value) || null).toString();

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
			_('Override the existing ECS in original request.'));
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

		so = ss.option(form.Flag, 'disable-ipv4', _('Discard A responses'));
		so.default = so.disabled;
		so.load = function(section_id) {
			return boolToFlag(new DNSAddress(uci.get(data[0], section_id, 'address')).parseParam('disable-ipv4') ? true : false);
		}
		so.onchange = function(ev, section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'address');

			let newvalue = new DNSAddress(UIEl.getValue()).setParam('disable-ipv4', flagToBool(value) || null).toString();

			UIEl.node.previousSibling.innerText = newvalue;
			UIEl.setValue(newvalue);
		}
		so.write = function() {};
		so.modalonly = true;

		so = ss.option(form.Flag, 'disable-ipv6', _('Discard AAAA responses'));
		so.default = so.disabled;
		so.load = function(section_id) {
			return boolToFlag(new DNSAddress(uci.get(data[0], section_id, 'address')).parseParam('disable-ipv6') ? true : false);
		}
		so.onchange = function(ev, section_id, value) {
			let UIEl = this.section.getUIElement(section_id, 'address');

			let newvalue = new DNSAddress(UIEl.getValue()).setParam('disable-ipv6', flagToBool(value) || null).toString();

			UIEl.node.previousSibling.innerText = newvalue;
			UIEl.setValue(newvalue);
		}
		so.write = function() {};
		so.modalonly = true;
		/* DNS server END */

		/* DNS policy START */
		s.tab('dns_policy', _('DNS policy'));

		/* DNS policy */
		o = s.taboption('dns_policy', form.SectionValue, '_dns_policy', hm.GridSection, 'dns_policy', null);
		ss = o.subsection;
		ss.addremove = true;
		ss.rowcolors = true;
		ss.sortable = true;
		ss.nodescriptions = true;
		ss.hm_modaltitle = [ _('DNS policy'), _('Add a DNS policy') ];
		ss.hm_prefmt = hm.glossary[ss.sectiontype].prefmt;
		ss.hm_field  = hm.glossary[ss.sectiontype].field;
		ss.hm_lowcase_only = false;
		/* Import mihomo config start */
		ss.handleYamlImport = function() {
			const field = this.hm_field;
			const o = new hm.HandleImport(this.map, this, _('Import mihomo config'),
				_('Please type <code>%s</code> fields of mihomo config.</br>')
					.format(field));
			o.placeholder = 'nameserver-policy:\n' +
							"  'www.baidu.com,.baidu.com': '223.5.5.5'\n" +
							"  '+.internal.crop.com': 'tls://8.8.4.4:853'\n" +
							'  "geosite:cn,private":\n' +
							'    - https://doh.pub/dns-query#DIRECT\n' +
							'  "rule-set:google": tls://8.8.4.4:853\n' +
							'  ...'
			o.parseYaml = parseDNSPolicyYaml;

			return o.render();
		}
		ss.renderSectionAdd = function(/* ... */) {
			let el = hm.GridSection.prototype.renderSectionAdd.apply(this, arguments);

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('mihomo config'),
				'click': ui.createHandlerFn(this, 'handleYamlImport')
			}, [ _('Import mihomo config') ]));

			return el;
		}
		/* Import mihomo config end */

		so = ss.option(form.Value, 'label', _('Label'));
		so.load = hm.loadDefaultLabel;
		so.validate = hm.validateUniqueValue;
		so.modalonly = true;

		so = ss.option(form.Flag, 'enabled', _('Enable'));
		so.default = so.enabled;
		so.editable = true;
		so.validate = function(/* ... */) {
			return hm.validatePresetIDs.call(this, [
				['select', 'type'],
				['', 'rule_set']
			], ...arguments);
		}

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
		so.load = loadDNSServerLabel;
		so.validate = validateNameserver;
		so.rmempty = false;
		so.editable = true;

		so = ss.option(hm.ListValue, 'proxy', _('Proxy group override'),
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
