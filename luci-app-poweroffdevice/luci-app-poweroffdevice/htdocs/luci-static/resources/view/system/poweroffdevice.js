
'use strict';
'require view';
'require ui';
'require fs';

return view.extend({
    render: function() {
        return E([
            E('h2', _('PowerOff')),
            E('p',  _('Turn off the power to the device you are using')),
	    E('hr'),
            E('button', {
                        class: 'btn cbi-button cbi-button-negative',
                        click: ui.createHandlerFn(this, 'handlePowerOff')
            }, _('Perform Power Off')),

            E('div', { 'style': 'text-align: center; padding: 10px; font-style: italic;' }, [
                E('span', {}, [
                    _('© github '),
                    E('a', { 
                        'href': 'https://github.com/sirpdboy/luci-app-poweroffdevice', 
                        'target': '_blank',
                        'style': 'text-decoration: none;'
                    }, 'by sirpdboy')
                ])
            ])
        ]);
    },

    handlePowerOff: function() {
        return ui.showModal(_('PowerOff Device'), [
            E('h4', { }, _('Turn off the power to the device you are using')),

            E('div', { class: 'right' }, [

                E('button', {
                    'class': 'btn btn-danger ',
		    'style': 'background: red!important; border-color: red!important',
                    'click': ui.createHandlerFn(this, function() {
                        ui.hideModal();
                        ui.showModal(_('PowerOffing...'), [
                            E('p', {'class': 'spinning'  }, _('The device may have powered off. If not, check manually.'))
                        ]);
                        return fs.exec('/sbin/poweroff').catch(function(e) {
                            ui.addNotification(null, E('p', e.message));
                        });
                    })
                }, _('OK')),
                ' ',
                E('button', {
                    'class': 'btn cbi-button cbi-button-apply',
                    'click': ui.hideModal
                }, _('Cancel'))
            ])
        ]);
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
