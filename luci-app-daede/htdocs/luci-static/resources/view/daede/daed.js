// SPDX-License-Identifier: Apache-2.0

'use strict';
'require baseclass';
'require form';
'require uci';
'require view.daede.widgets as widgets';

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
		save.addEventListener('click', function(ev) {
			ev.preventDefault();
			save.disabled = true;
			m.save(null, true)
				.then(function() { return uci.save(); })
				.then(function() {
					return uci.changes().then(function(ch) {
						return (ch && Object.keys(ch).length) ? uci.apply() : null;
					});
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
		card.appendChild(E('div', { 'class': 'dd-editor-actions' }, [ save, status ]));
		return card;
	});
}

return baseclass.extend({ renderDaedSettings: renderDaedSettings });
