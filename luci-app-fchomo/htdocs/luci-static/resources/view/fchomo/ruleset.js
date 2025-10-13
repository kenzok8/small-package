'use strict';
'require form';
'require uci';
'require ui';
'require view';

'require fchomo as hm';

function parseRulesetYaml(field, name, cfg) {
	if (!cfg.type)
		return null;

	// key mapping
	let config = hm.removeBlankAttrs({
		id: cfg.hm_id,
		label: cfg.hm_label,
		type: cfg.type,
		format: cfg.format,
		behavior: cfg.behavior,
		...(cfg.type === 'inline' ? {
			payload: cfg.payload, // string: array
		} : {
			url: cfg.url,
			size_limit: cfg["size-limit"],
			interval: cfg.interval,
			proxy: cfg.proxy ? hm.preset_outbound.full.map(([key, label]) => key).includes(cfg.proxy) ? cfg.proxy : this.calcID(hm.glossary["proxy_group"].field, cfg.proxy) : null,
		})
	});

	return config;
}

function parseRulesetLink(section_type, uri) {
	const filefmt = new RegExp(/^(text|yaml|mrs)$/);
	const filebehav = new RegExp(/^(domain|ipcidr|classical)$/);

	let config;

	uri = uri.split('://');
	if (uri[0] && uri[1]) {
		switch (uri[0]) {
		case 'http':
		case 'https':
			var url = new URL('http://' + uri[1]);
			var format = url.searchParams.get('fmt');
			var behavior = url.searchParams.get('behav');
			var interval = url.searchParams.get('sec');
			var rawquery = url.searchParams.get('rawq');
			var name = hm.toUciname(decodeURI(url.pathname).split('/').pop());

			if (filefmt.test(format) && filebehav.test(behavior)) {
				let fullpath = (url.username ? url.username + '@' : '') + url.host + url.pathname + (rawquery ? '?' + decodeURIComponent(rawquery) : '');
				config = {
					label: url.hash ? decodeURIComponent(url.hash.slice(1)) : name ? name : null,
					type: 'http',
					format: format,
					behavior: behavior,
					url: String.format('%s://%s', uri[0], fullpath),
					interval: interval,
					id: hm.calcStringMD5(String.format('http://%s', fullpath))
				};
			}

			break;
		case 'file':
			var url = new URL('file://' + uri[1]);
			var format = url.searchParams.get('fmt');
			var behavior = url.searchParams.get('behav');
			var filler = url.searchParams.get('fill');
			var path = decodeURI(url.pathname);
			var name = hm.toUciname(path.split('/').pop());

			if (filefmt.test(format) && filebehav.test(behavior)) {
				config = {
					label: url.hash ? decodeURIComponent(url.hash.slice(1)) : name ? name : null,
					type: 'file',
					format: format,
					behavior: behavior,
					id: hm.calcStringMD5(String.format('file://%s%s', url.host, url.pathname))
				};
				hm.writeFile(section_type, config.id, hm.decodeBase64Str(filler));
			}

			break;
		case 'inline':
			var url = new URL('inline:' + uri[1]);
			var behavior = url.searchParams.get('behav');
			var payload = hm.decodeBase64Str(url.pathname).trim();

			if (filebehav.test(behavior) && payload && payload.length) {
				config = {
					label: url.hash ? decodeURIComponent(url.hash.slice(1)) : null,
					type: 'inline',
					behavior: behavior,
					payload: payload,
					id: hm.calcStringMD5(String.format('inline:%s', btoa(payload)))
				};
			}

			break;
		}
	}

	if (config) {
		if (!config.type || !config.id)
			return null;
		else if (!config.label)
			config.label = config.id;
	}

	return config;
}

return view.extend({
	load() {
		return Promise.all([
			uci.load('fchomo')
		]);
	},

	render(data) {
		let m, s, o;

		m = new form.Map('fchomo', _('Edit ruleset'));

		/* Rule set START */
		/* Rule set settings */
		s = m.section(hm.GridSection, 'ruleset');
		s.addremove = true;
		s.rowcolors = true;
		s.sortable = true;
		s.nodescriptions = true;
		s.hm_modaltitle = [ _('Rule set'), _('Add a rule set') ];
		s.hm_prefmt = hm.glossary[s.sectiontype].prefmt;
		s.hm_field  = hm.glossary[s.sectiontype].field;
		s.hm_lowcase_only = false;
		/* Import mihomo config and Import rule-set links and Remove idle files start */
		s.handleYamlImport = function() {
			const field = this.hm_field;
			const o = new hm.HandleImport(this.map, this, _('Import mihomo config'),
				_('Please type <code>%s</code> fields of mihomo config.</br>')
					.format(field));
			o.placeholder = 'rule-providers:\n' +
							'  google:\n' +
							'    type: http\n' +
							'    path: ./rule1.yaml\n' +
							'    url: "https://raw.githubusercontent.com/../Google.yaml"\n' +
							'    interval: 600\n' +
							'    proxy: DIRECT\n' +
							'    behavior: classical\n' +
							'    format: yaml\n' +
							'    size-limit: 0\n' +
							'  alidns:\n' +
							'    type: file\n' +
							'    path: ./rule2.yaml\n' +
							'    behavior: classical\n' +
							'  google2:\n' +
							'    type: http\n' +
							'    path: ./rule3.yaml\n' +
							'    url: "https://raw.githubusercontent.com/../Google.yaml"\n' +
							'    proxy: proxy\n' +
							'    behavior: classical\n' +
							'  rule4:\n' +
							'    type: inline\n' +
							'    behavior: domain\n' +
							'    payload:\n' +
							"      - '.blogger.com'\n" +
							"      - '*.*.microsoft.com'\n" +
							"      - 'books.itunes.apple.com'\n" +
							'  ...'
			o.parseYaml = function(field, name, cfg) {
				let config = hm.HandleImport.prototype.parseYaml.call(this, field, name, cfg);

				return config ? parseRulesetYaml.call(this, field, name, config) : null;
			};

			return o.render();
		}
		s.handleLinkImport = function() {
			const section_type = this.sectiontype;
			const o = new hm.HandleImport(this.map, this, _('Import rule-set links'),
				_('Supports rule-set links of type: <code>%s</code> and format: <code>%s</code>.</br>')
					.format('file, http, inline', 'text, yaml, mrs') +
					_('Please refer to <a href="%s" target="_blank">%s</a> for link format standards.')
						.format(hm.rulesetdoc, _('Ruleset-URI-Scheme')));
			o.placeholder = 'http(s)://github.com/ACL4SSR/ACL4SSR/raw/refs/heads/master/Clash/Providers/BanAD.yaml?fmt=yaml&behav=classical&rawq=good%3Djob#BanAD\n' +
							'file:///example.txt?fmt=text&behav=domain&fill=LmNuCg#CN%20TLD\n' +
							'inline://LSAnLmhrJwoK?behav=domain#HK%20TLD\n';
			o.handleFn = function(textarea) {
				let input_links = textarea.getValue().trim().split('\n');
				let imported_count = 0;

				if (input_links && input_links[0]) {
					/* Remove duplicate lines */
					input_links = input_links.reduce((pre, cur) =>
						(!pre.includes(cur) && pre.push(cur), pre), []);

					input_links.forEach((l) => {
						let config = parseRulesetLink(section_type, l);
						if (config) {
							this.write(config);
							imported_count++;
						}
					});

					if (imported_count === 0)
						ui.addNotification(null, E('p', _('No valid rule-set link found.')));
					else
						ui.addNotification(null, E('p', _('Successfully imported %s %s of total %s.')
							.format(imported_count, _('rule-set'), input_links.length)));
				}

				if (imported_count)
					return this.save();
				else
					return ui.hideModal();
			}

			return o.render();
		}
		s.renderSectionAdd = function(/* ... */) {
			let el = hm.GridSection.prototype.renderSectionAdd.apply(this, arguments);

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('mihomo config'),
				'click': ui.createHandlerFn(this, 'handleYamlImport')
			}, [ _('Import mihomo config') ]));

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('Import rule-set links'),
				'click': ui.createHandlerFn(this, 'handleLinkImport')
			}, [ _('Import rule-set links') ]));

			el.appendChild(E('button', {
				'class': 'cbi-button cbi-button-add',
				'title': _('Remove idles'),
				'click': ui.createHandlerFn(this, hm.handleRemoveIdles)
			}, [ _('Remove idles') ]));

			return el;
		}
		/* Import mihomo config and Import rule-set links and Remove idle files end */

		o = s.option(form.Value, 'label', _('Label'));
		o.load = hm.loadDefaultLabel;
		o.validate = hm.validateUniqueValue;
		o.modalonly = true;

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = o.enabled;
		o.editable = true;
		o.validate = function(/* ... */) {
			return hm.validatePresetIDs.call(this, [
				['select', 'type'],
				['select', 'behavior'],
				['select', 'format'],
				['textarea', '_editer']
			], ...arguments);
		}

		o = s.option(form.ListValue, 'type', _('Type'));
		o.value('file', _('Local'));
		o.value('http', _('Remote'));
		o.value('inline', _('Inline'));
		o.default = 'http';

		o = s.option(form.ListValue, 'behavior', _('Behavior'));
		o.value('classical');
		o.value('domain');
		o.value('ipcidr');
		o.default = 'classical';
		o.validate = function(section_id, value) {
			const format = this.section.getUIElement(section_id, 'format').getValue();

			if (value === 'classical' && format === 'mrs')
				return _('Expecting: %s').format(_('Binary format only supports domain / ipcidr'));

			return true;
		}

		o = s.option(form.ListValue, 'format', _('Format'));
		o.value('text', _('Plain text'));
		o.value('yaml', _('Yaml text'));
		o.value('mrs', _('Binary mrs'));
		o.default = 'yaml';
		o.validate = function(section_id, value) {
			const behavior = this.section.getUIElement(section_id, 'behavior').getValue();

			if (value === 'mrs' && behavior === 'classical')
				return _('Expecting: %s').format(_('Binary format only supports domain / ipcidr'));

			return true;
		}
		o.textvalue = function(section_id) {
			let cval = this.cfgvalue(section_id) || this.default;
			let inline = function() {
				let cval = this.cfgvalue(section_id) || this.default;
				return (cval === 'inline') ? true : false;
			}.call(s.getOption('type'));
			return inline ? _('none') : cval;
		};
		o.depends({'type': 'inline', '!reverse': true});

		o = s.option(form.DummyValue, '_value', _('Value'));
		o.load = function(section_id) {
			const option = uci.get(data[0], section_id, 'type');

			switch (option) {
				case 'file':
					return `${hm.HM_DIR}/${this.section.sectiontype}/` + uci.get(data[0], section_id, '.name');
				case 'http':
					return uci.get(data[0], section_id, 'url');
				case 'inline':
					return uci.get(data[0], section_id, '.name');
				default:
					return null;
			}
		}
		o.modalonly = false;

		o = s.option(hm.TextValue, '_editer', _('Editer'),
			_('Please type <a target="_blank" href="%s" rel="noreferrer noopener">%s</a>.')
				.format('https://wiki.metacubex.one/config/rule-providers/content/', _('Contents')));
		o.placeholder = _('Content will not be verified, Please make sure you enter it correctly.');
		o.load = function(section_id) {
			return L.resolveDefault(hm.readFile(this.section.sectiontype, section_id), '');
		}
		o.write = L.bind(hm.writeFile, o, o.section.sectiontype);
		o.remove = L.bind(hm.writeFile, o, o.section.sectiontype);
		o.rmempty = false;
		o.retain = true;
		o.depends({'type': 'file', 'format': /^(text|yaml)$/});
		o.modalonly = true;

		o = s.option(hm.TextValue, 'payload', 'payload:',
			_('Please type <a target="_blank" href="%s" rel="noreferrer noopener">%s</a>.')
				.format('https://wiki.metacubex.one/config/rule-providers/content/', _('Payload')));
		o.placeholder = '- DOMAIN-SUFFIX,google.com\n# ' + _('Content will not be verified, Please make sure you enter it correctly.');
		o.rmempty = false;
		o.depends('type', 'inline');
		o.modalonly = true;

		o = s.option(form.Value, 'url', _('Rule set URL'));
		o.validate = hm.validateUrl;
		o.rmempty = false;
		o.depends('type', 'http');
		o.modalonly = true;

		o = s.option(form.Value, 'size_limit', _('Size limit'),
			_('In bytes. <code>%s</code> will be used if empty.').format('0'));
		o.placeholder = '0';
		o.validate = hm.validateBytesize;
		o.depends('type', 'http');

		o = s.option(form.Value, 'interval', _('Update interval'),
			_('In seconds. <code>%s</code> will be used if empty.').format('259200'));
		o.placeholder = '259200';
		o.validate = hm.validateTimeDuration;
		o.depends('type', 'http');

		o = s.option(form.ListValue, 'proxy', _('Proxy group'),
			_('Name of the Proxy group to download rule set.'));
		o.default = hm.preset_outbound.direct[0][0];
		hm.preset_outbound.direct.forEach((res) => {
			o.value.apply(o, res);
		})
		o.load = L.bind(hm.loadProxyGroupLabel, o, hm.preset_outbound.direct);
		o.textvalue = hm.textvalue2Value;
		//o.editable = true;
		o.depends('type', 'http');

		o = s.option(form.DummyValue, '_update');
		o.cfgvalue = hm.renderResDownload;
		o.editable = true;
		o.modalonly = false;
		/* Rule set END */

		return m.render();
	}
});
