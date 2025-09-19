'use strict';
'require view';
'require rpc';

var callServiceList = rpc.declare({
    object: 'service',
    method: 'list',
    params: ['name'],
    expect: { '': {} }
});

function getServiceStatus() {
    return L.resolveDefault(callServiceList('wechatpush'), {}).then(function (res) {
        console.log(res);
        var isRunning = false;
        try {
            isRunning = res['wechatpush']['instances']['instance1']['running'];
        } catch (e) { }
        return isRunning;
    });
}

return view.extend({
    load: function () {
        return getServiceStatus();
    },

    render: function (status) {
        // 如果服务正在运行，跳转到 client 页面
        if (status) {
            window.location.pathname = '/cgi-bin/luci/admin/services/wechatpush/client';
        } else {
            window.location.pathname = '/cgi-bin/luci/admin/services/wechatpush/config';
        }
    },

    handleSave: null,
    handleSaveApply: null,
    handleReset: null
});
