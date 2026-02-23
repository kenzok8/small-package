\'use strict\';
\'require baseclass\';
\'require fs\';
\'require rpc\';

var callLuciVersion = rpc.declare({
	object: \'luci\',
	method: \'getVersion\'
});

var callSystemBoard = rpc.declare({
	object: \'system\',
	method: \'board\'
});

var callSystemInfo = rpc.declare({
	object: \'system\',
	method: \'info\'
});

var callCPUBench = rpc.declare({
	object: \'luci\',
	method: \'getCPUBench\'
});

var callCPUInfo = rpc.declare({
	object: \'luci\',
	method: \'getCPUInfo\'
});

var callCPUUsage = rpc.declare({
	object: \'luci\',
	method: \'getCPUUsage\'
});

var callTempInfo = rpc.declare({
	object: \'luci\',
	method: \'getTempInfo\'
});

return baseclass.extend({
	title: _(\'System\'),

	load: function() {
		return Promise.all([
			L.resolveDefault(callSystemBoard(), {}),
			L.resolveDefault(callSystemInfo(), {}),
			L.resolveDefault(callCPUBench(), {}),
			L.resolveDefault(callCPUInfo(), {}),
			L.resolveDefault(callCPUUsage(), {}),
			L.resolveDefault(callTempInfo(), {}),
			L.resolveDefault(callLuciVersion(), { revision: _(\'unknown version\'), branch: \'LuCI\' })
		]);
	},

	render: function(data) {
		var boardinfo   = data[0],
		    systeminfo  = data[1],
		    cpubench    = data[2],
		    cpuinfo     = data[3],
		    cpuusage    = data[4],
		    tempinfo    = data[5],
		    luciversion = data[6];

		luciversion = luciversion.branch + \' \' + luciversion.revision;

		var datestr = null;

		if (systeminfo.localtime) {
			var date = new Date(systeminfo.localtime * 1000);

			datestr = \'%04d-%02d-%02d %02d:%02d:%02d\'.format(
				date.getUTCFullYear(),
				date.getUTCMonth() + 1,
				date.getUTCDate(),
				date.getUTCHours(),
				date.getUTCMinutes(),
				date.getUTCSeconds()
			);
		}

		var projectlink = document.createElement(\'a\');
		projectlink.append(\'kenzo\');
		projectlink.href = \'https://github.com/kenzok8\';
		projectlink.target = \'_blank\';

		var corelink = document.createElement(\'a\');
		corelink.append(\'openwrt_Build\');
		corelink.href = \'https://github.com/kenzok8/openwrt_Build\';
		corelink.target = \'_blank\';

		var sourcelink = document.createElement(\'span\');
		sourcelink.append(projectlink);
		sourcelink.append(\' / \');
		sourcelink.append(corelink);

		var fields = [
			_(\'Hostname\'),         boardinfo.hostname,
			_(\'Model\'),            boardinfo.model + cpubench.cpubench,
			_(\'Architecture\'),     cpuinfo.cpuinfo || boardinfo.system,
			_(\'Target Platform\'),  (L.isObject(boardinfo.release) ? boardinfo.release.target : \'\'),
			_(\'Firmware Version\'), (L.isObject(boardinfo.release) ? boardinfo.release.description + \' / \' : \'\') + (luciversion || \'\'),
			_(\'Kernel Version\'),   boardinfo.kernel,
			_(\'Local Time\'),       datestr,
			_(\'Uptime\'),           systeminfo.uptime ? \'%t\'.format(systeminfo.uptime) : null,
			_(\'Load Average\'),     Array.isArray(systeminfo.load) ? \'%.2f, %.2f, %.2f\'.format(
				systeminfo.load[0] / 65535.0,
				systeminfo.load[1] / 65535.0,
				systeminfo.load[2] / 65535.0
			) : null,
			_(\'CPU usage (%)\'),    cpuusage.cpuusage,
			_(\'Source Code\'),      sourcelink
		];

		if (tempinfo.tempinfo) {
			fields.splice(12, 0, _(\'Temperature\'));
			fields.splice(13, 0, tempinfo.tempinfo);
		}

		var table = E(\'table\', { \'class\': \'table\' });

		for (var i = 0; i < fields.length; i += 2) {
			table.appendChild(E(\'tr\', { \'class\': \'tr\' }, [
				E(\'td\', { \'class\': \'td left\', \'width\': \'33%\' }, [ fields[i] ]),
				E(\'td\', { \'class\': \'td left\' }, [ (fields[i + 1] != null) ? fields[i + 1] : \'?\' ])
			]));
		}

		return table;
	}
});
