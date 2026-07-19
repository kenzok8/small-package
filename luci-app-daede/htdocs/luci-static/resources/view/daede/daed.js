// SPDX-License-Identifier: Apache-2.0

'use strict';
'require baseclass';
'require form';
'require fs';
'require ui';
'require uci';
'require view.daede.widgets as widgets';

function applyUciChanges() {
	return uci.save().then(function() {
		return uci.changes().then(function(ch) {
			return (ch && Object.keys(ch).length) ? uci.apply() : null;
		});
	}).then(function() {
		return new Promise(function(resolve) { window.setTimeout(resolve, 1800); });
	}).then(function() {
		return ui.changes.init();
	});
}

function renderDaedSettings() {
	let m, s, o;
	m = new form.Map('daed', null, null);

	s = m.section(form.NamedSection, 'config', 'daed');
	s.addremove = false;
	s.anonymous = true;

	o = s.option(form.Value, 'listen_addr', _('Listen Address'));
	o.datatype = 'ipaddrport(1)';
	o.default = '0.0.0.0:2023';
	o.rmempty = false;

	o = s.option(form.Value, 'dashboard_username', _('daed Username'),
		_('Used by LuCI to access daed (subscription updates and import). If daed is not initialized yet, this account is used to create the daed admin.'));
	o.placeholder = 'admin';
	o.rmempty = false;

	o = s.option(form.Value, 'dashboard_password', _('daed Password'));
	o.password = true;

	o = s.option(form.Flag, 'subscribe_auto_update', _('Enable subscription auto-update'));
	o.default = '0';

	o = s.option(form.ListValue, 'subscribe_update_cycle', _('Update Cycle'));
	o.value('daily', _('Daily'));
	o.value('weekly', _('Weekly'));
	o.default = 'daily';
	o.depends('subscribe_auto_update', '1');

	o = s.option(form.ListValue, 'subscribe_update_hour', _('Update Time'));
	for (let h = 0; h < 24; h++) {
		const hh = ('0' + h).slice(-2);
		o.value(String(h), hh + ':00');
	}
	o.default = '4';
	o.depends('subscribe_auto_update', '1');

	o = s.option(form.Value, 'log_maxsize', _('Max Log Size (MB)'),
		_('Rotate the log file once it grows past this many megabytes.'));
	o.datatype = 'uinteger';
	o.default = '5';

	o = s.option(form.Value, 'log_maxbackups', _('Max Log Backups'),
		_('Number of rotated log files to keep.'));
	o.datatype = 'uinteger';
	o.default = '1';

	return widgets.wrapSettingsCard(
		_('daede Settings'),
		null,
		m.render(),
		_('Log Settings'),
		['log_maxsize', 'log_maxbackups']
	).then(function(card) {
		/* native Save/Apply footer is suppressed view-wide, so daed carries its
		   own primary action */
		const status = E('span', { 'class': 'dd-editor-status' }, '');
		let statusTimer = null;
		function flash(text, kind, hold) {
			status.textContent = text;
			status.classList.remove('ok', 'err');
			if (kind) status.classList.add(kind);
			status.classList.add('show');
			if (statusTimer) clearTimeout(statusTimer);
			statusTimer = setTimeout(function() { status.classList.remove('show'); }, hold || 3000);
		}

		const save = E('button', { 'class': 'cbi-button cbi-button-positive' }, _('Save and Apply'));
		const update = E('button', { 'class': 'cbi-button cbi-button-action' }, _('Update subscriptions now'));
		update.addEventListener('click', function(ev) {
			ev.preventDefault();
			update.disabled = true;
			flash(_('Updating daed subscriptions…'));
			fs.exec('/usr/share/luci-app-daede/daed-sub-update.sh', []).then(function(res) {
				if (res && res.code !== 0) {
					const err = (res.stderr || res.stdout || ('exit ' + res.code)).trim().split('\n')[0];
					flash(_('Subscription update failed: %s').format(err), 'err', 9000);
				} else {
					flash(_('Subscriptions updated and applied'), 'ok');
				}
			}).catch(function(e) {
				flash(_('Subscription update failed: %s').format(e.message || e), 'err', 9000);
			}).finally(function() { update.disabled = false; });
		});
		save.addEventListener('click', function(ev) {
			ev.preventDefault();
			save.disabled = true;
			m.save(null, true)
				.then(applyUciChanges)
				.then(function() {
					const enabled = uci.get('daed', 'config', 'subscribe_auto_update') === '1';
					return fs.exec('/usr/share/luci-app-daede/daed-sub-cron.sh', [ enabled ? 'enable' : 'disable' ]);
				})
				.then(function(res) {
					if (res && res.code !== 0)
						throw new Error((res.stderr || res.stdout || ('exit ' + res.code)).trim());
				})
				.then(function() {
					/* no success popup — the reload is feedback enough */
					setTimeout(function() { window.location.reload(); }, 500);
				})
				.catch(function(e) {
					if (e && e.name === 'CBIValidationError')
						flash(_('Please fix the highlighted fields.'), 'err', 6000);
					else
						flash(_('Save failed: %s').format(e.message || e), 'err', 9000);
				})
				.finally(function() { save.disabled = false; });
		});
		card.appendChild(E('div', { 'class': 'dd-editor-actions' }, [ update, save, status ]));
		return card;
	});
}

return baseclass.extend({ renderDaedSettings: renderDaedSettings });
