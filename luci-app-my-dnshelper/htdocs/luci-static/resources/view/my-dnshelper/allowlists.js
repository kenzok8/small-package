'use strict';
'require form';
'require view';
'require fs';
'require uci';
'require poll';
'require rpc';

return view.extend({
	load: function(){
		return Promise.all([
			fs.lines('/tmp/my-dnshelper.d/count.txt').then(function(s) {
				var lines=[0,0,0];
				try{
					console.log(s);
					if (s != '') {
						lines=s[0].split(',');
					}
				} catch(e) {}
				console.log(lines);
				return lines;
			}),
			fs.trimmed('/tmp/my-dnshelper.d/my-dnshelper.updated')
		]);
	},
	render: function(stats){
		var m, s, o, ud,rc;
		rc='';
        rc = stats[0];
		ud = stats[1].trim();
		if (!ud) {ud = _("[Not updated]");}
		if ( ud == "0") {ud = _("Updating..."); rc = ['?','?','?']}

		m = new form.Map('my-dnshelper', _('Allowed list'),
		_('Here you can set the allowed list and the accessible hosts')
		);

		s = m.section(form.TypedSection, 'my-dnshelper',  _('Allow Rules'));
		s.anonymous = true;

		o = s.option(form.DynamicList, "allowurl", _("Allowed Rules Subscription URL"));
		o.value("https://cdn.jsdelivr.net/gh/privacy-protection-tools/dead-horse/anti-ad-white-list.txt", _("Anti-AD-White-List"));

		o = s.option(form.Button, "bcallow");
		o.title = _("Allowed Rules");
		o.inputtitle = _("Delete All");
		o.inputstyle = "apply";
		o.description = "<strong>"+rc[1]+_("Records")+"</strong><br/><br/>";
		o.onclick = function () {
			fs.exec('/usr/share/my-dnshelper/waiter',['--xw']).then(function(s){
				try{
					window.location=location;
				}catch(e){}
			});
		};

		s = m.section(form.TypedSection, 'my-dnshelper',  _('Hosts Rules'));
		s.anonymous = true;

		o = s.option(form.DynamicList, "hostsurl", _("Hosts Subscription URL"));
		o.value("https://cdn.jsdelivr.net/gh/frankwuzp/coursera-host/hosts", _("Thanks Coursera-Host"));

		o = s.option(form.Button, "bchosts");
		o.title = _("Hosts Data");
		o.inputtitle = _("Delete All");
		o.inputstyle = "apply";
		o.description = "<strong>"+rc[2]+_("Records")+"</strong><br/><br/>";
		o.onclick = function () {
			fs.exec('/usr/share/my-dnshelper/waiter',['--xh']).then(function(s){
				try{
					window.location=location;
				}catch(e){}
			});
		};

		s = m.section(form.TypedSection, 'my-dnshelper');
		s.anonymous = true;

		o = s.option(form.Button, "bupdate");
		o.title = _("Subscription Update");
		o.inputtitle = _("Update");
		o.inputstyle = "apply";
		o.onclick = function () {
			fs.exec('/usr/share/my-dnshelper/waiter',['-u']);
			window.alert(_("Please wait for the background update to complete."));
		};
		o.description = "<strong>"+_("Last Update Checked")+":</strong> %s<br/>".format(ud)+"<br/><br/>";

		return m.render();
	}

});
