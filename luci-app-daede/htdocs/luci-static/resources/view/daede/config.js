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
	_loadContext: function() {
		return backend.detectBackend().then(function(ctx) {
			return uci.load(ctx.backend.uci).catch(function() {}).then(function() {
				return ctx;
			});
		});
	},

	load: function() {
		return this._loadContext();
	},

	render: function(ctx) {
		const self = this;
		const themeHref = Array.prototype.map.call(document.styleSheets, function(sheet) { return sheet.href || ''; }).join(' ');
		document.documentElement.setAttribute('data-daede-theme', /\/argon\//.test(themeHref) ? 'argon' : 'bootstrap');

		/* themes signal dark differently — BootstrapDark sets data-darkmode,
		   Argon just loads a dark stylesheet with no flag. Read the first opaque
		   background up the tree; a transparent body (CSS not applied yet) must
		   NOT count as black, else argon light is misdetected as dark. */
		try {
			const probe = [document.body, document.documentElement];
			for (let i = 0; i < probe.length; i++) {
				const m = getComputedStyle(probe[i]).backgroundColor.match(/[\d.]+/g);
				if (!m) continue;
				const a = m.length >= 4 ? parseFloat(m[3]) : 1;
				if (a < 0.1) continue; // transparent — keep looking
				if (0.299 * m[0] + 0.587 * m[1] + 0.114 * m[2] < 128)
					document.documentElement.setAttribute('data-darkmode', 'true');
				break; // first opaque background decides
			}
		} catch (e) {}

		const redrawBackend = function(name, message) {
			self._backendHint = message;
			return self._loadContext()
				.then(function(nextCtx) { return self.render(nextCtx); })
				.then(function(nextRoot) {
					const current = document.querySelector('.dd-config-page');
					if (!current) return;
					Array.prototype.forEach.call(current.querySelectorAll('.dd-status-card'), function(card) {
						if (card._ddCleanup) card._ddCleanup();
					});
					current.replaceWith(nextRoot);
					if (self._backendHintTimer) clearTimeout(self._backendHintTimer);
					self._backendHintTimer = setTimeout(function() {
						self._backendHint = '';
						const hint = document.querySelector('.dd-config-page .dd-backend-help');
						if (hint) hint.textContent = '';
					}, 3500);
				});
		};

		const listenAddr = uci.get('daed', 'config', 'listen_addr') || backend.BACKENDS.daed.defaultListen;
		const children = [
			E('style', {}, styles.CSS),
			widgets.renderStatusCard(ctx, listenAddr),
			widgets.renderBackendSwitcher(ctx, redrawBackend, self._backendHint)
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
			return E('div', { 'class': 'dd-wrap dd-config-page' }, nodes.filter(function(n) { return !!n; }));
		});
	},

	/* this view drives its own save buttons (dae form / daed settings / manual
	   editor) — suppress LuCI's global Save/Apply/Reset footer so there is one
	   unambiguous primary action per backend */
	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
