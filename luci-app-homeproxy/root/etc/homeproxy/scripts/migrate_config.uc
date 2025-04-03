#!/usr/bin/ucode
/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 ImmortalWrt.org
 */

'use strict';

import { cursor } from 'uci';
import { isEmpty } from 'homeproxy';

const uci = cursor();

const uciconfig = 'homeproxy';
uci.load(uciconfig);

const uciinfra = 'infra',
      ucimain = 'config',
      ucinode = 'node',
      ucidns = 'dns',
      ucidnsrule = 'dns_rule',
      ucirouting = 'routing',
      uciroutingnode = 'routing_node',
      uciroutingrule = 'routing_rule',
      uciserver = 'server';

/* chinadns-ng has been removed */
if (uci.get(uciconfig, uciinfra, 'china_dns_port'))
	uci.delete(uciconfig, uciinfra, 'china_dns_port');

/* chinadns server now only accepts single server */
const china_dns_server = uci.get(uciconfig, ucimain, 'china_dns_server');
if (china_dns_server === 'wan_114')
	uci.set(uciconfig, ucimain, 'china_dns_server', '114.114.114.114');
else if (match(china_dns_server, /,/))
	uci.set(uciconfig, ucimain, 'china_dns_server', split(china_dns_server, ',')[0]);
else if (match(china_dns_server, / /))
	uci.set(uciconfig, ucimain, 'china_dns_server', split(china_dns_server, ' ')[0]);

/* github_token option has been moved to config section */
const github_token = uci.get(uciconfig, uciinfra, 'github_token');
if (github_token) {
	uci.set(uciconfig, uciconfig, 'github_token', github_token);
	uci.delete(uciconfig, uciinfra, 'github_token')
}

/* empty value defaults to all ports now */
if (uci.get(uciconfig, ucimain, 'routing_port') === 'all')
	uci.delete(uciconfig, ucimain, 'routing_port');

/* experimental section was removed */
if (uci.get(uciconfig, 'experimental'))
	uci.delete(uciconfig, 'experimental');

/* block-dns was removed from built-in dns servers */
if (uci.get(uciconfig, ucidns, 'default_server') === 'block-dns')
	uci.set(uciconfig, ucidns, 'default_server', 'default-dns');

/* block-out was removed from built-in outbounds */
if (uci.get(uciconfig, ucirouting, 'default_outbound') === 'block-out')
	uci.set(uciconfig, ucirouting, 'default_outbound', 'nil');


/* DNS rules options */
uci.foreach(uciconfig, ucidnsrule, (cfg) => {
	/* rule_set_ipcidr_match_source was renamed in sb 1.10 */
	if (cfg.rule_set_ipcidr_match_source === '1')
		uci.rename(uciconfig, cfg, 'rule_set_ipcidr_match_source', 'rule_set_ip_cidr_match_source');
});

/* nodes options */
uci.foreach(uciconfig, ucinode, (cfg) => {
	/* tls_ech_tls_disable_drs is useless and deprecated in sb 1.12 */
	if (!isEmpty(cfg.tls_ech_tls_disable_drs))
		uci.delete(uciconfig, cfg, 'tls_ech_tls_disable_drs');

	/* wireguard_gso was deprecated in sb 1.11 */
	if (!isEmpty(cfg.wireguard_gso))
		uci.delete(uciconfig, cfg, 'wireguard_gso');
});

/* routing rules options */
uci.foreach(uciconfig, uciroutingrule, (cfg) => {
	/* rule_set_ipcidr_match_source was renamed in sb 1.10 */
	if (cfg.rule_set_ipcidr_match_source === '1')
		uci.rename(uciconfig, cfg, 'rule_set_ipcidr_match_source', 'rule_set_ip_cidr_match_source');
});

/* server options */
uci.foreach(uciconfig, uciserver, (cfg) => {
	/* sniff_override was deprecated in sb 1.11 */
	if (!isEmpty(cfg.sniff_override))
		uci.delete(uciconfig, cfg, 'sniff_override');

	/* domain_strategy is now pointless without sniff override */
	if (!isEmpty(cfg.domain_strategy))
		uci.delete(uciconfig, cfg, 'domain_strategy');
});

if (!isEmpty(uci.changes(uciconfig)))
	uci.commit(uciconfig);
