// Copyright 2022-2025 tty228 <tty228@yeah.net> zzsj0928
// Licensed to the public under the Apache License 2.0.

import { popen, open, readfile } from 'fs';
import { cursor } from 'uci';
import { translate } from 'luci.core';

/* ── helper: bytes formatting ── */
function format_bytes(n) {
	n = +n || 0;
	if (n > 1073741824) return sprintf("%.2f G", n / 1073741824);
	if (n > 1048576)  return sprintf("%.2f M", n / 1048576);
	if (n > 1024)     return sprintf("%.2f K", n / 1024);
	return sprintf("%d B", n);
}

/* ── helper: shell-safe quoting ── */
function sq(s) {
	return "'" + replace(s, /'/g, "'\\''") + "'";
}

/* ── helper: uci commit ── */
function uci_commit(conf) {
	system("/sbin/uci -q commit " + conf);
}

return {

	act_status: function() {
		let f = popen("pgrep -f pushbot/pushbot", "r");
		let out = "";
		if (f) { out = f.read("all"); f.close(); }
		http.prepare_content("application/json");
		http.write_json({ running: length(out) > 0 });
	},

	act_client_list: function() {
		let clients = [];
		let usage_map = {};

		let pf = popen("/usr/bin/pushbot/pushbot usage list 2>/dev/null", "r");
		if (pf) {
			for (let line = pf.read("line"); line; line = pf.read("line")) {
				let m = match(line, /^(\S+)\s+(\S+)/);
				if (m) usage_map[uc(m[1])] = +m[2] || 0;
			}
			pf.close();
		}

		let f = open("/tmp/pushbot/ipAddress", "r");
		if (f) {
			for (let l = f.read("line"); l; l = f.read("line")) {
				l = replace(l, /\s+$/, "");
				if (length(l) > 0) {
					let m = match(l, /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/);
					if (m) {
						let now = time();
						let up = +m[4] || 0;
						push(clients, {
							ip:       m[1] ?? "",
							mac:      uc(m[2]),
							hostname: m[3] ?? "",
							uptime:   up ? now - up : 0,
							usage:    format_bytes(usage_map[uc(m[2])] ?? 0)
						});
					}
				}
			}
			f.close();
		}

		http.prepare_content("application/json");
		http.write_json(clients);
	},

	act_send_test: function() {
		system("/usr/bin/pushbot/pushbot test >/dev/null 2>&1 &");
		http.prepare_content("application/json");
		http.write_json({ ok: true });
	},

	act_send_manual: function() {
		system("/usr/bin/pushbot/pushbot send >/dev/null 2>&1 &");
		http.prepare_content("application/json");
		http.write_json({ ok: true });
	},

	act_version: function() {
		let ver = "";
		/* apk (OpenWrt 24.10+): /lib/apk/db/installed */
		let f = popen("awk '/^P:luci-app-pushbot$/{f=1;next} f&&/^V:/{print substr($0,3);exit}' /lib/apk/db/installed 2>/dev/null", "r");
		if (f) { ver = replace(f.read("all"), /\s+/, ""); f.close(); }
		/* opkg (legacy): /usr/lib/opkg/status */
		if (ver == "") {
			f = popen("awk '/^Package: luci-app-pushbot$/{f=1;next} f&&/^Version:/{print $2;exit}' /usr/lib/opkg/status 2>/dev/null", "r");
			if (f) { ver = replace(f.read("all"), /\s+/, ""); f.close(); }
		}
		http.prepare_content("application/json");
		http.write_json({ version: ver });
	},

	act_soc_test: function() {
		system("/usr/bin/pushbot/pushbot soc");
		http.redirect(dispatcher.build_url("admin", "services", "pushbot"));
	},

	act_soc_result: function() {
		let fallback = translate('No output') ?? 'No output';
		let f = popen("cat /tmp/pushbot/soc_tmp 2>/dev/null || echo '" + fallback + "'", "r");
		if (f) {
			http.write(f.read("all"));
			f.close();
		}
	},

	get_log: function() {
		let u = cursor();
		if (u.get("pushbot", "pushbot", "debuglevel") != "1") {
			http.write(translate('Logging disabled') ?? 'Logging disabled');
			return;
		}
		let f = open("/tmp/pushbot/pushbot.log", "r");
		if (f) { http.write(f.read("all")); f.close(); }
	},

	clear_log: function() {
		let f = open("/tmp/pushbot/pushbot.log", "w");
		if (f) { f.write(""); f.close(); }
	},

	act_restart: function() {
		system("/etc/init.d/pushbot restart");
		http.prepare_content("application/json");
		http.write_json({ ok: true });
	},

	act_get_config: function() {
		let u = cursor();
		let cfg = {};
		let lists = {};
		let files = {};
		let sysinfo = {};

		/* scalar options */
		let scalar_opts = [
			"pushbot_enable","lite_enable","jsonpath","dd_webhook","we_webhook",
			"pp_token","pp_channel","pp_webhook","pp_topic_enable","pp_topic",
			"pushdeer_key","pushdeer_srv_enable","pushdeer_srv","fs_webhook",
			"bark_token","bark_srv_enable","bark_srv","bark_sound",
			"bark_icon_enable","bark_icon","bark_level","device_name",
			"sleeptime","oui_data","oui_dir","reset_regularly","debuglevel",
			"pushbot_sheep","starttime","endtime","macmechanism",
			"pushbot_interface","macmechanism2","crontab","regular_time",
			"regular_time_2","regular_time_3","interval_time","send_title",
			"router_status","router_temp","router_wan","client_list",
			"google_check_count","pushbot_up","pushbot_down","table_format",
			"ntfy_srv_enable","ntfy_server","ntfy_topic","ntfy_token_enable","ntfy_token","ntfy_priority","gotify_server","gotify_token","gotify_priority",
			"cpuload_enable","cpuload","temperature_enable","temperature",
			"client_usage","client_usage_max","client_usage_disturb",
			"pushbot_ipv4","ipv4_interface","pushbot_ipv6","ipv6_interface",
			"web_logged","ssh_logged","web_login_failed","ssh_login_failed",
			"login_max_num","web_login_black","ip_black_timeout",
			"up_timeout","down_timeout","timeout_retry_count","thread_num",
			"soc_code","pve_host","pve_port","err_enable","err_sheep_enable",
			"network_err_event","system_time_event","autoreboot_time",
			"network_restart_time","public_ip_event","public_ip_retry_count",
			"font_title","font_success","font_fail","font_client","font_module"
		];

		let section = u.get_all("pushbot", "pushbot") ?? {};

		for (let o in scalar_opts) {
			let v = section[o];
			if (v != null) cfg[o] = v;
		}

		/* lite_enable: may be space-separated string or list */
		let lite_raw = section["lite_enable"];
		if (type(lite_raw) == 'array' && length(lite_raw) > 0)
			cfg["lite_enable"] = lite_raw;
		else if (type(lite_raw) == 'string' && length(lite_raw) > 0)
			cfg["lite_enable"] = filter(split(lite_raw, /\s+/), v => length(v) > 0);

		/* list options */
		let list_opts = [
			"device_aliases","pushbot_whitelist","pushbot_blacklist",
			"MAC_online_list","MAC_offline_list","ip_white_list",
			"client_usage_whitelist","err_device_aliases"
		];

		for (let o in list_opts) {
			let v = section[o];
			let t = [];
			if (type(v) == 'array')
				for (let item in v)
					if (item != null && item != "") push(t, item);
			else if (type(v) == 'string' && v != "")
				for (let item in split(v, /\s+/))
					if (length(item) > 0) push(t, item);
			lists[o] = t;
		}

		/* files */
		let file_paths = {
			diy_json:    "/usr/bin/pushbot/api/diy.json",
			ipv4_list:   "/usr/bin/pushbot/api/ipv4.list",
			ipv6_list:   "/usr/bin/pushbot/api/ipv6.list",
			ip_black_list: "/usr/bin/pushbot/api/ip_blacklist"
		};

		for (let name, path in file_paths) {
			try {
				files[name] = readfile(path) ?? "";
			}
			catch {
				files[name] = "";
			}
		}

		/* network interfaces */
		let ifaces = [];
		let pf = popen("ls /sys/class/net 2>/dev/null", "r");
		if (pf) {
			for (let line = pf.read("line"); line; line = pf.read("line")) {
				let n = replace(line, /\s+/, "");
				if (n != "lo" && !match(n, /^ifb/))
					push(ifaces, n);
			}
			pf.close();
		}
		sysinfo.ifaces = ifaces;

		/* IP hints from arp */
		let ip_hints = [];
		let arpf = popen("grep -E '^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+' /proc/net/arp 2>/dev/null", "r");
		if (arpf) {
			for (let line = arpf.read("line"); line; line = arpf.read("line")) {
				let m = match(line, /^(\d+\.\d+\.\d+\.\d+)/);
				if (m && m[1] != "0.0.0.0" && m[1] != "127.0.0.1")
					push(ip_hints, m[1]);
			}
			arpf.close();
		}
		sysinfo.ip_hints = ip_hints;

		/* MAC hints from dhcp leases */
		let mac_hints = [];
		let lf = open("/tmp/dhcp.leases", "r");
		if (lf) {
			for (let line = lf.read("line"); line; line = lf.read("line")) {
				let parts = filter(split(line, /\s+/), v => length(v) > 0);
				if (length(parts) >= 4)
					push(mac_hints, { m: parts[1], n: parts[3] });
			}
			lf.close();
		}
		/* also try arp for additional MACs */
		let arpf2 = popen("grep -E '^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+' /proc/net/arp 2>/dev/null", "r");
		if (arpf2) {
			for (let line = arpf2.read("line"); line; line = arpf2.read("line")) {
				let m = match(line, /^(\d+\.\d+\.\d+\.\d+)\s+\S+\s+\S+\s+(\S+)/);
				if (m && m[2] && m[2] != "0.0.0.0") {
					let known = false;
					for (let h in mac_hints)
						if (h.m == m[2]) { known = true; break; }
					if (!known)
						push(mac_hints, { m: m[2], n: "" });
				}
			}
			arpf2.close();
		}
		sysinfo.mac_hints = mac_hints;

		http.prepare_content("application/json");
		http.write_json({ config: cfg, lists: lists, files: files, system: sysinfo });
	},

	act_save_config: function() {
		http.prepare_content("application/json");

		let body;
		try { body = http.content(); } catch { body = null; }
		if (!body) {
			http.write_json({ ok: false, error: "no data" });
			return;
		}

		let data;
		try { data = json(body); } catch { data = null; }
		if (type(data) != 'object') {
			http.write_json({ ok: false, error: "invalid json" });
			return;
		}

		let file_paths = {
			diy_json: "/usr/bin/pushbot/api/diy.json",
			ipv4_list: "/usr/bin/pushbot/api/ipv4.list",
			ipv6_list: "/usr/bin/pushbot/api/ipv6.list",
			ip_black_list: "/usr/bin/pushbot/api/ip_blacklist"
		};

		let list_opt_set = {
			device_aliases: true,
			pushbot_whitelist: true,
			pushbot_blacklist: true,
			MAC_online_list: true,
			MAC_offline_list: true,
			ip_white_list: true,
			client_usage_whitelist: true,
			err_device_aliases: true
		};

		let font_opts = {
			font_title: true, font_success: true, font_fail: true,
			font_client: true, font_module: true
		};

		function uci_cmd(...args) {
			let cmd = "/sbin/uci -q";
			for (let a in args)
				cmd += " " + a;
			system(cmd);
		}

		for (let opt, val in data) {
			/* color options: only #RRGGBB */
			if (opt in font_opts) {
				if (type(val) != 'string' || val == "" || !match(val, /^#[0-9a-fA-F]{6}$/))
					uci_cmd("delete", "pushbot.pushbot." + sq(opt));
				else {
					uci_cmd("delete", "pushbot.pushbot." + sq(opt));
					uci_cmd("set", "pushbot.pushbot." + sq(opt) + "=" + sq(val));
				}
			}
			/* file paths */
			else if (opt in file_paths) {
				let path = file_paths[opt];
				if (type(val) == 'string' && val != "") {
					/* 黑名单文件：支持换行/空格/tab 混合分隔（与脚本端
					   IFS 空白分割一致），保存时统一规范为每行一个 IP */
					if (opt == "ip_black_list") {
						let keep = [];
						let seen = {};
						let loc = { "::1": true, "127.0.0.1": true };
						let pf = popen("ip -o addr show 2>/dev/null | awk '{print $4}' | cut -d/ -f1", "r");
						if (pf) {
							for (let line = pf.read("line"); line; line = pf.read("line")) {
								let a = replace(line, /[\r\n\s]+/, "");
								if (a != "")
									loc[a] = true;
							}
							pf.close();
						}
						/* 按任意空白分割（换行/空格/tab 混用均可） */
						let parts = split(replace(val, /\r\n/g, "\n"), /\s+/);
						for (let p in parts) {
							let l = replace(p, /[\r\n\s]+/, "");
							if (l == "" || (l in loc) || (l in seen))
								continue;
							seen[l] = true;
							push(keep, l);
						}
						content = join("\n", keep);
						if (length(content) > 0)
							content += "\n";
					}
					let f = open(path, "w");
					if (f) { f.write(content); f.close(); }
				}
				else {
					let f = open(path, "w");
					if (f) { f.write(""); f.close(); }
				}
			}
			/* list options */
			else if (opt in list_opt_set) {
				uci_cmd("delete", "pushbot.pushbot." + sq(opt));
				/* 黑名单保存校验：剔除本机接口地址与 ::1 / 127.0.0.1
				   （防止误拉黑自己断掉 Web/SSH 访问；脚本侧还有
				   is_local_address 硬保护，这里保存端提前过滤） */
				let localset = {};
				if (opt == "pushbot_blacklist") {
					localset["::1"] = true;
					localset["127.0.0.1"] = true;
					let pf = popen("ip -o addr show 2>/dev/null | awk '{print $4}' | cut -d/ -f1", "r");
					if (pf) {
						for (let line = pf.read("line"); line; line = pf.read("line")) {
							let a = replace(line, /[\r\n\s]+/, "");
							if (a != "")
								localset[a] = true;
						}
						pf.close();
					}
				}
				function add(v) {
					if (v == "")
						return;
					if (opt == "pushbot_blacklist" && v in localset)
						return;   /* 本机地址：剔除，不写入配置 */
					uci_cmd("add_list", "pushbot.pushbot." + sq(opt) + "=" + sq(v));
				}
				if (type(val) == 'array')
					for (let v in val) add(v);
				else if (type(val) == 'string')
					add(val);
			}
			/* scalar options */
			else {
				if (val == null || val == "") {
					uci_cmd("delete", "pushbot.pushbot." + sq(opt));
				}
				else if (type(val) == 'array') {
					let p = [];
					for (let v in val)
						if (v != "") push(p, v);
					if (length(p) > 0) {
						uci_cmd("delete", "pushbot.pushbot." + sq(opt));
						uci_cmd("set", "pushbot.pushbot." + sq(opt) + "=" + sq(join(" ", p)));
					}
				}
				else {
					uci_cmd("delete", "pushbot.pushbot." + sq(opt));
					uci_cmd("set", "pushbot.pushbot." + sq(opt) + "=" + sq("" + val));
				}
			}
		}
		uci_commit("pushbot");

		/* 保存后联动服务状态（避免"config 启用但服务未启动"）：
		 *   enable=1 → 服务未跑则启动，已在跑则重启使新配置生效
		 *   enable=0 → 停止服务（配合主脚本 enable_detection 双保险）
		 *   后台(&)执行，避免阻塞 HTTP 请求导致前端"保存失败" */
		let u = cursor();
		let en = u.get("pushbot", "pushbot", "pushbot_enable");
		if (en == "1" || en == 1 || en == true)
			system("/etc/init.d/pushbot start >/dev/null 2>&1 &");
		else if (en == "0" || en == 0 || en == false)
			system("/etc/init.d/pushbot stop >/dev/null 2>&1 &");

		/* 拉黑规则立即应用：保存后后台触发（新增/修改/清空黑名单、
		   切换拉黑开关、改白名单/超时全部即时生效，不等 sleeptime 轮询） */
		system("/usr/bin/pushbot/pushbot blacklist >/dev/null 2>&1 &");

		http.write_json({ ok: true });
	},

	/* compatibility: index — no-op, menu registration is handled by menu.d JSON */
	index: function() {}
};
