'use strict';
'require form';
'require view';
'require fs';
'require ui';

// 创建视图页面
return view.extend({
    render: function() {
        var m, s, o;

        // 创建表单映射
        m = new form.Map('subconverter', _('Subconverter'),
            _('Edit subconverter configuration file'));

        // 创建配置节
        s = m.section(form.NamedSection, 'config', 'subconverter');

        // 创建文件编辑器选项
        o = s.option(form.TextValue, '_pref', 
            _('Edit pref.example.ini'),
            _('This is the content of /etc/subconverter/pref.example.ini'));

        // 读取文件内容
        o.rows = 25;
        o.wrap = 'off';
        o.cfgvalue = function(section_id) {
            return fs.trimmed('/etc/subconverter/pref.example.ini');
        };

        // 保存文件内容
        o.write = function(section_id, formvalue) {
            return fs.write('/etc/subconverter/pref.example.ini', formvalue.trim() + '\n');
        };

        return m.render();
    }
});
