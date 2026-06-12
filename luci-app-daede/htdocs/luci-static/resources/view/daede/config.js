// SPDX-License-Identifier: Apache-2.0

'use strict';
'require uci';
'require view';
'require view.daede.backend as backend';
'require view.daede.styles as styles';
'require view.daede.widgets as widgets';
'require view.daede.dae as daeView';
'require view.daede.daed as daedView';

return view.extend({
	load: function() {
		return backend.detectBackend().then(function(ctx) {
			return uci.load(ctx.backend.uci).catch(function() {}).then(function() {
				return ctx;
			});
		});
	},

	render: function(ctx) {
		/* themes signal dark differently — BootstrapDark sets data-darkmode,
		   Argon just loads a dark stylesheet with no flag. Detect dark from the
		   page background luminance and set data-darkmode so our dark rules
		   (keyed on it) fire uniformly across every theme's dark mode. */
		try {
			const bg = getComputedStyle(document.body).backgroundColor.match(/\d+/g);
			if (bg && (0.299 * bg[0] + 0.587 * bg[1] + 0.114 * bg[2]) < 128)
				document.documentElement.setAttribute('data-darkmode', 'true');
		} catch (e) {}

		const listenAddr = uci.get('daed', 'config', 'listen_addr') || backend.BACKENDS.daed.defaultListen;
		const children = [
			E('style', {}, styles.CSS),
			widgets.renderStatusCard(ctx, listenAddr),
			widgets.renderBackendSwitcher(ctx)
		].filter(function(node) { return !!node; });

		if (!ctx.installed[ctx.name]) {
			children.push(E('div', { 'class': 'dd-card dd-warning' }, _('Selected backend is not installed. Install dae or daed from the package feed first.')));
		} else if (ctx.name === 'dae') {
			children.push(daeView.renderDaeImportBanner());
			children.push(daeView.renderDaeForms(ctx));
			children.push(daeView.renderDaeEditor());
		} else {
			children.push(daedView.renderDaedSettings());
		}

		return Promise.all(children.map(function(child) {
			return child && child.then ? child : Promise.resolve(child);
		})).then(function(nodes) {
			return E('div', { 'class': 'dd-wrap' }, nodes.filter(function(n) { return !!n; }));
		});
	},

	/* this view drives its own save buttons (dae form / daed settings / manual
	   editor) — suppress LuCI's global Save/Apply/Reset footer so there is one
	   unambiguous primary action per backend */
	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
