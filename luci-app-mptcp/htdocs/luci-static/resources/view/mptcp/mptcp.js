'use strict';
'require rpc';
'require form';
'require fs';
'require uci';
'require tools.widgets as widgets';

/*
 * Copyright (C) 2024-2025 Ycarus (Yannick Chabanois) <contact@openmptcprouter.com> for OpenMPTCProuter
 * This is free software, licensed under the GNU General Public License v3.
 * See /LICENSE for more information
 */

var callSystemBoard = rpc.declare({
    object: 'system',
    method: 'board'
});


return L.view.extend({
    load: function() {
	return Promise.all([
	    L.resolveDefault(callSystemBoard(), {})
	]);
    },

    render: function(res) {
	var m, s, o;
	var boardinfo = res[0];

	m = new form.Map('network', _('MPTCP'),_('Networks MPTCP settings.'));

	s = m.section(form.TypedSection, 'globals');

	o = s.option(form.ListValue, 'multipath', _('Multipath TCP'));
	o.value("enable", _("enable"));
	o.value("disable", _("disable"));
	o.readonly = true;

	o = s.option(form.ListValue, "mptcp_checksum", _("Multipath TCP checksum"));
	o.value(1, _("enable"));
	o.value(0, _("disable"));

	if (boardinfo.kernel.substring(1,4) != "5.15" && boardinfo.kernel.substring(1,1) != "6") {
		o = s.option(form.ListValue, "mptcp_debug", _("Multipath Debug"));
		o.value(1, _("enable"));
		o.value(0, _("disable"));
	}

	o = s.option(form.ListValue, "mptcp_path_manager", _("Multipath TCP path-manager"), _("Default is fullmesh"));
	o.value("default", _("default"));
	o.value("fullmesh", "fullmesh");

	if (parseFloat(boardinfo.kernel.substring(0,4)) < 6) {
		o.value("ndiffports", "ndiffports");
		o.value("binder", "binder");
		o.value("netlink", _("Netlink"));
	}

	var scheduler = s.option(form.ListValue, "mptcp_scheduler", _("Multipath TCP scheduler"), _('BPF schedulers (not available on all platforms):') + '<br />' +
		_('bpf_burst => same as the default scheduler') + '<br />' +
		_('bpf_red => sends all packets redundantly on all available subflows') + '<br />' +
		_('bpf_first => always picks the first subflow to send data')  + '<br />' +
		_('bpf_rr => always picks the next available subflow to send data (round-robin)')

	);
	scheduler.value("default", _("default"));
	if (parseFloat(boardinfo.kernel.substring(0,4)) < 6) {
		scheduler.value("roundrobin", "round-robin");
		scheduler.value("redundant", "redundant");
		scheduler.value("blest", "BLEST");
		scheduler.value("ecf", "ECF");
	}

	if (parseFloat(boardinfo.kernel.substring(0,3)) > 6) {
	    scheduler.load = function(section_id) {
		    return L.resolveDefault(fs.list('/usr/share/bpf/scheduler'), []).then(L.bind(function(entries) {
			    for (var i = 0; i < entries.length; i++)
				    if (entries[i].type == 'file' && entries[i].name.match(/\.o$/))
					this.value(entries[i].name);
			    return this.super('load', [section_id]);
		    }, this));
	    };
	    // bpf_burst => same as the default scheduler
	    // bpf_red => sends all packets redundantly on all available subflows
	    // bpf_first => always picks the first subflow to send data
	    // bpf_rr => always picks the next available subflow to send data (round-robin)
	}

	if (parseFloat(boardinfo.kernel.substring(0,4)) < 6) {
		o = s.option(form.Value, "mptcp_syn_retries", _("Multipath TCP SYN retries"));
		o.datatype = "uinteger";
		o.rmempty = false;
	}

	if (parseFloat(boardinfo.kernel.substring(0,4)) < 6) {
		o = s.option(form.ListValue, "mptcp_version", _("Multipath TCP version"));
		o.value(0, _("0"));
		o.value(1, _("1"));
		o.default = 0;
	}

	o = s.option(form.ListValue, "congestion", _("Congestion Control"),_("Default is cubic"));
	o.load = function(section_id) {
		return fs.exec_direct('/sbin/sysctl', ['-n', 'net.ipv4.tcp_available_congestion_control']).then(L.bind(function(entries) {
			var congestioncontrol = entries.toString().split(' ');
			for (var d in congestioncontrol) {
				this.value(congestioncontrol[d]);
			};
			return this.super('load', [section_id]);
		}, this));
	};

	if (parseFloat(boardinfo.kernel.substring(0,4)) >= 6) {
		if (boardinfo.kernel.substring(0,1) == "6") {
			// Only available since 5.19
			o = s.option(form.ListValue, "mptcp_pm_type", _("Path Manager type"));
			o.value(0, _("In-kernel path manager"));
			o.value(1, _("Userspace path manager"));
			o.default = 0;
		}

		o = s.option(form.ListValue, "mptcp_disable_initial_config", _("Initial MPTCP configuration"));
		o.depends("mptcp_pm_type","1");
		o.value("0", _("enable"));
		o.value("1", _("disable"));
		o.default = "0";

		o = s.option(form.ListValue, "mptcp_force_multipath", _("Force Multipath configuration"));
		o.depends("mptcp_pm_type","1");
		o.value("1", _("enable"));
		o.value("0", _("disable"));
		o.default = "1";

		o = s.option(form.ListValue, "mptcpd_enable", _("Enable MPTCPd"));
		o.depends("mptcp_pm_type","1");
		o.value("enable", _("enable"));
		o.value("disable", _("disable"));
		o.default = "disable";

		o = s.option(form.DynamicList, "mptcpd_path_manager", _("MPTCPd path managers"));
		o.load = function(section_id) {
			return L.resolveDefault(fs.list('/usr/lib/mptcpd'), []).then(L.bind(function(entries) {
				for (var i = 0; i < entries.length; i++)
					if (entries[i].type == 'file' && entries[i].name.match(/\.so$/))
						this.value(entries[i].name);
				return this.super('load', [section_id]);
			}, this));
		};
		o.depends("mptcp_pm_type","1");

		o = s.option(form.DynamicList, "mptcpd_plugins", _("MPTCPd plugins"));
		o.load = function(section_id) {
			return L.resolveDefault(fs.list('/usr/lib/mptcpd'), []).then(L.bind(function(entries) {
				for (var i = 0; i < entries.length; i++)
					if (entries[i].type == 'file' && entries[i].name.match(/\.so$/))
						this.value(entries[i].name);
				return this.super('load', [section_id]);
			}, this));
		};
		o.depends("mptcp_pm_type","1");

		o = s.option(form.DynamicList, "mptcpd_addr_flags", _("MPTCPd Address annoucement flags"));
		o.value("subflow","subflow");
		o.value("signal","signal");
		o.value("backup","backup");
		o.value("fullmesh","fullmesh");
		o.depends("mptcp_pm_type","1");

		o = s.option(form.DynamicList, "mptcpd_notify_flags", _("MPTCPd Address notification flags"));
		o.value("existing","existing");
		o.value("skip_link_local","skip_link_local");
		o.value("skip_loopback","skip_loopback");
		o.depends("mptcp_pm_type","1");

		o = s.option(form.Value, "mptcp_subflows", _("Max subflows"),_("specifies the maximum number of additional subflows allowed for each MPTCP connection"));
		o.datatype = "uinteger";
		o.rmempty = false;
		o.default = 3;

		o = s.option(form.Value, "mptcp_stale_loss_cnt", _("Retranmission intervals"),_("The number of MPTCP-level retransmission intervals with no traffic and pending outstanding data on a given subflow required to declare it stale. A low stale_loss_cnt value allows for fast active-backup switch-over, an high value maximize links utilization on edge scenarios e.g. lossy link with high BER or peer pausing the data processing."));
		o.datatype = "uinteger";
		o.rmempty = false;
		o.default = 4;

		o = s.option(form.Value, "mptcp_add_addr_accepted", _("Max add address"),_("specifies the maximum number of ADD_ADDR (add address) suboptions accepted for each MPTCP connection"));
		o.datatype = "uinteger";
		o.rmempty = false;
		o.default = 1;

		o = s.option(form.Value, "mptcp_add_addr_timeout", _("Control message timeout"),_("Set the timeout after which an ADD_ADDR (add address) control message will be resent to an MPTCP peer that has not acknowledged a previous ADD_ADDR message."));
		o.datatype = "uinteger";
		o.rmempty = false;
		o.default = 120;
	} else {
		o = s.option(form.Value, "mptcp_fullmesh_num_subflows", _("Fullmesh subflows for each pair of IP addresses"));
		o.datatype = "uinteger";
		o.rmempty = false;
		o.default = 1;
		//o.depends("mptcp_path_manager","fullmesh")

		o = s.option(form.ListValue, "mptcp_fullmesh_create_on_err", _("Re-create fullmesh subflows after a timeout"));
		o.value(1, _("enable"));
		o.value(0, _("disable"));
		//o.depends("mptcp_path_manager","fullmesh");

		o = s.option(form.Value, "mptcp_ndiffports_num_subflows", _("ndiffports subflows number"));
		o.datatype = "uinteger";
		o.rmempty = false;
		o.default = 1;
		//o.depends("mptcp_path_manager","ndiffports")

		o = s.option(form.ListValue, "mptcp_rr_cwnd_limited", _("Fill the congestion window on all subflows for round robin"));
		o.value("Y", _("enable"));
		o.value("N", _("disable"));
		o.default = "Y";
		//o.depends("mptcp_scheduler","roundrobin")

		o = s.option(form.Value, "mptcp_rr_num_segments", _("Consecutive segments that should be sent for round robin"));
		o.datatype = "uinteger";
		o.rmempty = false;
		o.default = 1;
		//o.depends("mptcp_scheduler","roundrobin")
	}

	s = m.section(form.TypedSection, "interface", _("Interfaces Settings"));
	s.filter = function(section) {
	    return (!section.match("^oip.*") && !section.match("^lo.*") && section != "omrvpn" && section != "omr6in4");
	}

	o = s.option(form.ListValue, "multipath", _("Multipath TCP"), _("One interface must be set as master"));
	o.value("on", _("enabled"));
	o.value("off", _("disabled"));
	o.value("master", _("master"));
	o.value("backup", _("backup"));
	//o.value("handover", _("handover"));
	o.default = "off";

	o = s.option(form.Value, "multipath_weight", _("Weight"), _("Only for *weight schedulers/path managers (if any available)") + '<br />' + _("A weight <100 make it more attractive, a weight >100 make it less attractive."));
	o.datatype = "uinteger";
	o.rmempty = false;
	o.default = 100;
	//o.depends("mptcp_scheduler","mptcp_bpf_weight.o");
	return m.render();
    }
});