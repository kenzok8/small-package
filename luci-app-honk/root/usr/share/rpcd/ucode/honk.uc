#!/usr/bin/ucode

'use strict';

import { readfile, writefile, popen, stat } from 'fs';
import { cursor } from 'uci';

function strip_dae_comments(content) {
	if (!content) return "";
	let lines = split(content, /[\r\n]+/);
	let clean_lines = [];
	for (let idx, line in lines) {
		let in_single = false;
		let in_double = false;
		let clean = "";
		let len = length(line);
		for (let i = 0; i < len; i++) {
			let c = substr(line, i, 1);
			let next_c = (i + 1 < len) ? substr(line, i + 1, 1) : "";
			if (c == "'" && !in_double) {
				in_single = !in_single;
				clean += c;
			} else if (c == '"' && !in_single) {
				in_double = !in_double;
				clean += c;
			} else if (!in_single && !in_double) {
				if (c == '#' || (c == '/' && next_c == '/')) {
					break;
				} else {
					clean += c;
				}
			} else {
				clean += c;
			}
		}
		if (match(clean, /\S/)) {
			push(clean_lines, clean);
		}
	}
	return join("\n", clean_lines);
}

function parse_clash_api(clean_content) {
	let api_m = match(clean_content, /clash_api\s*\{([^}]+)\}/);
	if (!api_m) return null;
	let block = api_m[1];

	let ec_m = match(block, /external_controller\s*:\s*['"]?([^'" \t\r\n]+)['"]?/);
	let ui_m = match(block, /external_ui\s*:\s*['"]?([^'" \t\r\n]+)['"]?/);
	let sec_m = match(block, /secret\s*:\s*['"]?([^'" \t\r\n]*)['"]?/);
	let dm_m = match(block, /default_mode\s*:\s*['"]?([^'" \t\r\n]*)['"]?/);

	let res = {
		external_controller: ec_m ? ec_m[1] : "",
		external_ui: ui_m ? ui_m[1] : "",
		secret: sec_m ? sec_m[1] : "",
		default_mode: dm_m ? dm_m[1] : "Rule",
		host: "",
		port: ""
	};

	let ec = res.external_controller;
	if (ec) {
		let m_v6 = match(ec, /^\[([^\]]+)\]:([0-9]+)$/);
		let m_v4 = match(ec, /^([^:]+):([0-9]+)$/);
		let m_p = match(ec, /^:([0-9]+)$/);
		if (m_v6) {
			res.host = m_v6[1];
			res.port = m_v6[2];
		} else if (m_v4) {
			res.host = m_v4[1];
			res.port = m_v4[2];
		} else if (m_p) {
			res.host = "0.0.0.0";
			res.port = m_p[1];
		} else if (match(ec, /^[0-9]+$/)) {
			res.host = "0.0.0.0";
			res.port = ec;
		}
	}

	return res;
}

function get_config_file_path() {
	let u = cursor();
	let p = u ? u.get("honk", "config", "config_file") : null;
	return p || "/etc/honk/config.dae";
}

function remove_bracket_block(content, header_regex) {
	let lines = split(content, "\n");
	let new_lines = [];
	let in_block = false;
	let depth = 0;

	for (let idx, line in lines) {
		let trimmed = trim(line);
		if (!in_block && match(trimmed, header_regex)) {
			in_block = true;
			depth = 1;
			continue;
		}

		if (in_block) {
			if (match(trimmed, /\{/)) depth++;
			if (match(trimmed, /\}/)) depth--;
			if (depth <= 0) {
				in_block = false;
			}
			continue;
		}

		push(new_lines, line);
	}
	return join("\n", new_lines);
}

return {
	"luci.honk": {
		status: {
			call: function(req) {
				let p = popen("pidof honk-core 2>/dev/null");
				let pids = p ? p.read("all") : "";
				if (p) p.close();
				let m = match(pids, /([0-9]+)/);
				let pid = m ? m[1] : null;
				let running = !!pid;
				let memory = null;
				if (running) {
					let status_str = readfile("/proc/" + pid + "/status");
					if (status_str) {
						let rss_m = match(status_str, /VmRSS:\s+([0-9]+)\s+kB/);
						if (rss_m) {
							memory = sprintf("%.1f MB", +rss_m[1] / 1024);
						}
					}
				}
				return { running: running, memory: memory };
			}
		},

		reload: {
			call: function(req) {
				system("/etc/init.d/honk hot_reload >/dev/null 2>&1 &");
				return { success: true };
			}
		},

		get_log: {
			call: function(req) {
				let p = popen("tail -n 1000 /var/log/honk/honk.log 2>/dev/null");
				let content = p ? p.read("all") : "";
				if (p) p.close();
				return { log: content || "" };
			}
		},

		clear_log: {
			call: function(req) {
				system("true > /var/log/honk/honk.log");
				return { success: true };
			}
		},

		get_zashboard_info: {
			call: function(req) {
				let config_file = get_config_file_path();
				let content = readfile(config_file) || "";
				let clean = strip_dae_comments(content);
				let parsed = parse_clash_api(clean);

				let p = popen("pidof honk-core 2>/dev/null");
				let pids = p ? p.read("all") : "";
				if (p) p.close();
				let running = !!match(pids, /[0-9]+/);

				let res = {
					configured: false,
					has_ui: false,
					running: running,
					config_file: config_file,
					external_controller: "",
					host: "",
					port: "",
					secret: "",
					external_ui: "",
					default_mode: "Rule"
				};

				if (!parsed) {
					return res;
				}

				res.configured = true;
				res.external_controller = parsed.external_controller;
				res.host = parsed.host;
				res.port = parsed.port;
				res.secret = parsed.secret;
				res.external_ui = parsed.external_ui;
				res.default_mode = parsed.default_mode;

				if (res.external_ui) {
					let index_path = res.external_ui + "/index.html";
					let s = stat(index_path);
					if (s && s.type == "file") {
						res.has_ui = true;
					}
				}

				return res;
			}
		},

		download_zashboard: {
			args: { url: "string" },
			call: function(req) {
				let url = req.args ? req.args.url : null;
				if (!url) {
					url = "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip";
				}

				if (!match(url, /^https?:\/\//) || match(url, /[ \t\r\n'"`]/)) {
					return { success: false, message: "Invalid URL" };
				}

				let config_file = get_config_file_path();
				let content = readfile(config_file) || "";
				let clean = strip_dae_comments(content);
				let parsed = parse_clash_api(clean);

				let target_dir = (parsed && parsed.external_ui) ? parsed.external_ui : "/etc/honk/zashboard";
				let script = "/usr/share/honk/download_zashboard.sh";
				let s = stat(script);
				if (!s) {
					return { success: false, message: "Script not found: " + script };
				}

				let safe_script = replace(script, "'", "'\\''");
				let safe_target = replace(target_dir, "'", "'\\''");
				let safe_url = replace(url, "'", "'\\''");

				let cmd = sprintf("/bin/sh '%s' '%s' '%s' >/dev/null 2>&1 &", safe_script, safe_target, safe_url);
				system(cmd);

				return { success: true, target_dir: target_dir, url: url };
			}
		},

		download_status: {
			call: function(req) {
				let status_raw = readfile("/tmp/honk_zashboard_download.status") || "IDLE";
				let log = readfile("/tmp/honk_zashboard_download.log") || "";
				let status_m = match(status_raw, /\S+/);
				let status = status_m ? status_m[0] : "IDLE";
				return { status: status, log: log };
			}
		},

		enable_clash_api: {
			call: function(req) {
				let config_file = get_config_file_path();
				let content = readfile(config_file);
				if (!content) {
					return { success: false, message: "Config file not found: " + config_file };
				}

				let api_inner =
"    clash_api {\n" +
"        external_controller: '0.0.0.0:9090'\n" +
"        external_ui: '/etc/honk/zashboard'\n" +
"        secret: ''\n" +
"        default_mode: 'Rule'\n" +
"    }\n";

				let default_block = "experimental {\n" + api_inner + "}\n";

				let cleaned = remove_bracket_block(content, /^[#\/]*\s*clash_api\s*\{/);
				cleaned = replace(cleaned, /experimental\s*\{\s*\}/, "experimental {\n}");

				let has_active_exp = match(cleaned, /(^|\n)[ \t]*experimental\s*\{/);
				let new_content;
				if (has_active_exp) {
					new_content = replace(cleaned, /(experimental\s*\{[^\n]*\n?)/, "$1" + api_inner);
				} else {
					cleaned = remove_bracket_block(cleaned, /^[#\/]+\s*experimental\s*\{/);
					new_content = rtrim(cleaned, "\r\n\t ") + "\n\n" + default_block;
				}

				writefile(config_file, new_content);
				system("/etc/init.d/honk restart >/dev/null 2>&1 &");

				return { success: true };
			}
		}
	}
};
