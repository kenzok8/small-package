'use strict';
'require view';
'require rpc';
'require uci';

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
        return Promise.all([
            getServiceStatus(),
            uci.load('wechatpush')
        ]);
    },

    render: function (data) {
        var status = data[0];
        // 检查配置，默认为 '1' (开启)
        var preferClient = uci.get('wechatpush', 'config', 'prefer_client_page') !== '0';

        // 如果服务正在运行 且 优先展示在线设备开关开启，跳转到 client 页面
        if (status && preferClient) {
            window.location.replace('/cgi-bin/luci/admin/services/wechatpush/client');
        } else {
            window.location.replace('/cgi-bin/luci/admin/services/wechatpush/config');
        }
    },

    handleSave: null,
    handleSaveApply: null,
    handleReset: null
});
