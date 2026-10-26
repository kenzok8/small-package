#!/usr/bin/ucode
/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 ImmortalWrt.org
 */

'use strict';

import { cursor } from 'uci';
import { glob, mkdir, readfile, rename, rmdir, stat, unlink, writefile } from 'fs';
import { HP_DIR, domainListPath, isEmpty, normalizeDomainList } from 'homeproxy';

/* Move user lists independently of UCI, including disabled or orphaned groups. */
function migrateDomainList(source, target) {
	if (!stat(source))
		return;
	if (!stat(`${HP_DIR}/diversion`) && !mkdir(`${HP_DIR}/diversion`))
		die('HomeProxy: failed to create the diversion directory.\n');

	if (stat(target)) {
		const current = readfile(target), previous = readfile(source);
		if (current === null || previous === null)
			die('HomeProxy: failed to read domain lists during migration.\n');
		/* Preserve both lists when a restored backup contains old and new paths. */
		const merged = normalizeDomainList(current + '\n' + previous);
		const content = length(merged) ? join('\n', merged) + '\n' : '';
		const temporary = target + '.new';
		if (writefile(temporary, content) !== length(content) || !rename(temporary, target)) {
			unlink(temporary);
			die('HomeProxy: failed to merge domain lists during migration.\n');
		}
		if (!unlink(source))
			die('HomeProxy: failed to remove a migrated domain list.\n');
	} else if (!rename(source, target)) {
		die('HomeProxy: failed to move a domain list.\n');
	}
}

migrateDomainList(`${HP_DIR}/resources/direct_list.txt`, domainListPath('direct'));
migrateDomainList(`${HP_DIR}/resources/proxy_list.txt`, domainListPath('proxy'));
for (let path in glob(`${HP_DIR}/resources/diversion/*.txt`))
	migrateDomainList(path, `${HP_DIR}/diversion/${substr(path, length(`${HP_DIR}/resources/diversion/`))}`);
rmdir(`${HP_DIR}/resources/diversion`);

const uci = cursor();
const uciconfig = 'homeproxy';
uci.load(uciconfig);

const stockCommonPort = '22,53,80,143,443,465,587,853,873,993,995,5222,8080,8443,9418';
const updatedCommonPort = '20,21,22,25,53,80,110,119,123,143,389,443,465,514,563,587,636,853,873,989,990,993,995,1194,1883,3306,3389,5222,5432,5671,5672,5900,6379,6443,6514,8080,8443,8883,9418';

function setDefault(section, option, value) {
	if (uci.get(uciconfig, section, option) === null)
		uci.set(uciconfig, section, option, value);
}

function deleteOptions(section, options) {
	for (let option in options)
		if (uci.get(uciconfig, section, option) !== null)
			uci.delete(uciconfig, section, option);
}

function migrateOption(section, oldOption, newOption) {
	const oldValue = uci.get(uciconfig, section, oldOption);
	if (oldValue === null)
		return;
	if (uci.get(uciconfig, section, newOption) === null)
		uci.set(uciconfig, section, newOption, oldValue);
	uci.delete(uciconfig, section, oldOption);
}

function moveOption(sourceSection, sourceOption, targetSection, targetOption) {
	const sourceValue = uci.get(uciconfig, sourceSection, sourceOption);
	if (sourceValue === null)
		return;
	if (uci.get(uciconfig, targetSection, targetOption) === null)
		uci.set(uciconfig, targetSection, targetOption, sourceValue);
	uci.delete(uciconfig, sourceSection, sourceOption);
}

const commonPort = uci.get(uciconfig, 'infra', 'common_port');
if (commonPort === stockCommonPort)
	uci.set(uciconfig, 'infra', 'common_port', updatedCommonPort);
else
	setDefault('infra', 'common_port', updatedCommonPort);

/* Keep only the supported routing modes. */
if (!(uci.get(uciconfig, 'config', 'routing_mode') in ['bypass_mainland_china', 'global']))
	uci.set(uciconfig, 'config', 'routing_mode', 'bypass_mainland_china');
deleteOptions('config', [
	'proxy_mode',
	'main_udp_node', 'main_udp_urltest_nodes',
	'main_udp_urltest_interval', 'main_udp_urltest_tolerance',
	'github_token', 'dashboard_download_url'
]);

deleteOptions('infra', [
	'china_dns_port', 'dns_redirect', 'redirect_port', 'tun_mark', 'tun_gso',
	'tproxy_port', 'table_mark', 'self_mark', 'tproxy_mark',
	'sniff_override', 'github_token'
]);

if (uci.get(uciconfig, 'config', 'routing_port') === 'all')
	uci.delete(uciconfig, 'config', 'routing_port');

deleteOptions('config', ['tcpip_stack']);
deleteOptions('routing', ['tcpip_stack']);

deleteOptions('control', [
	'lan_proxy_mode', 'lan_direct_ipv6_ips', 'lan_proxy_ipv6_ips',
	'lan_global_proxy_ipv6_ips', 'lan_gaming_mode_ipv6_ips',
	'lan_gaming_mode_ipv4_ips', 'lan_gaming_mode_mac_addrs',
	'lan_global_proxy_ipv4_ips', 'lan_global_proxy_mac_addrs',
	'direct_domain_list_checksum', 'proxy_domain_list_checksum'
]);

if (isEmpty(uci.get(uciconfig, 'diversion')))
	uci.set(uciconfig, 'diversion', 'homeproxy');

uci.foreach(uciconfig, 'node', (section) => {
	if (section.type in ['vless', 'vmess'] && section.packet_encoding === '')
		uci.set(uciconfig, section['.name'], 'packet_encoding', 'none');
	for (let pair in [
		['hysteria_recv_window_conn', 'hysteria_stream_receive_window'],
		['hysteria_revc_window', 'hysteria_connection_receive_window'],
		['hysteria_disable_mtu_discovery', 'hysteria_disable_path_mtu_discovery']
	])
		migrateOption(section['.name'], pair[0], pair[1]);
	deleteOptions(section['.name'], ['hysteria_protocol']);
});

uci.foreach(uciconfig, 'server', (section) => {
	for (let pair in [
		['hysteria_recv_window_conn', 'hysteria_stream_receive_window'],
		['hysteria_recv_window_client', 'hysteria_connection_receive_window'],
		['hysteria_revc_window_client', 'hysteria_connection_receive_window'],
		['hysteria_max_conn_client', 'hysteria_max_concurrent_streams'],
		['hysteria_disable_mtu_discovery', 'hysteria_disable_path_mtu_discovery']
	])
		migrateOption(section['.name'], pair[0], pair[1]);
	deleteOptions(section['.name'], ['hysteria_protocol']);
});

deleteOptions('subscription', ['latency_test_mode']);
if (uci.get(uciconfig, 'subscription', 'packet_encoding') === '')
	uci.set(uciconfig, 'subscription', 'packet_encoding', 'none');

const subscriptionUserAgent = uci.get(uciconfig, 'subscription', 'user_agent');
if (subscriptionUserAgent === 'v2rayN/7.23.4' ||
	subscriptionUserAgent === 'sing-box/1.14.0-beta.2')
	uci.set(uciconfig, 'subscription', 'user_agent', 'homeproxy');

setDefault('infra', 'ntp_server', 'nil');
if (isEmpty(uci.get(uciconfig, 'infra', 'udp_timeout')))
	uci.set(uciconfig, 'infra', 'udp_timeout', '300');
setDefault('config', 'main_urltest_interval', '60');
setDefault('config', 'main_urltest_tolerance', '60');
setDefault('config', 'main_urltest_interrupt_exist_connections', '0');
setDefault('config', 'log_level', 'warn');
setDefault('config', 'multi_queue', '1');
if (isEmpty(uci.get(uciconfig, 'tailscale')))
	uci.set(uciconfig, 'tailscale', 'homeproxy');
setDefault('tailscale', 'enabled', '0');
setDefault('tailscale', 'accept_routes', '0');
setDefault('tailscale', 'exit_node_allow_lan_access', '0');
setDefault('tailscale', 'advertise_exit_node', '0');
setDefault('control', 'lan_whitelist_mode', '0');
setDefault('server', 'log_level', 'warn');

if (!isEmpty(uci.changes(uciconfig)) && uci.commit(uciconfig) !== true)
	exit(1);
