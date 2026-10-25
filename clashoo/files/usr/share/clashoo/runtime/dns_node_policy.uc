#!/usr/bin/ucode
'use strict';

import { readfile } from 'fs';

// Mirror node-domain DNS policies from the subscription into
// proxy-server-nameserver-policy (issue #73).
//
// Airports publish their own resolver for node domains, e.g.
//   nameserver-policy:
//     "+.chylink.xyz": [tls://112.74.48.57:10853]
// which answers with domestic relay IPs. mihomo resolves *proxy server* domains
// through proxy-server-nameserver(-policy) and ignores nameserver-policy there,
// so that resolver is never used and node domains fall back to public DNS -
// which may return overseas CDN IPs that some lines cannot reach at all, leaving
// every node (AnyTLS is TCP-only) timing out.
//
// Input : CLASHOO_NODE_DNS_SOURCE_FILE = path to {"policies": {...}, "servers": [...]}
//         (CLASHOO_NODE_DNS_SOURCE with the JSON itself is still accepted)
// Output: JSON map with only the policy entries matching a node server domain
//         (nothing is printed when there is no match)

let source = '';
let source_file = getenv('CLASHOO_NODE_DNS_SOURCE_FILE') || '';

if (length(source_file)) {
	try {
		source = readfile(source_file) || '';
	}
	catch (e) {
		exit(0);
	}
}
else {
	source = getenv('CLASHOO_NODE_DNS_SOURCE') || '';
}

if (!length(source))
	exit(0);

let parsed;

try {
	parsed = json(source);
}
catch (e) {
	exit(0);
}

if (type(parsed) != 'object')
	exit(0);

let policies = parsed.policies;
let servers = parsed.servers;

if (type(policies) != 'object' || type(servers) != 'array')
	exit(0);

let domains = [];
let seen = {};

for (let server in servers) {
	if (type(server) != 'string' || !length(server))
		continue;
	server = lc(server);
	if (seen[server])
		continue;
	seen[server] = true;
	push(domains, server);
}

if (!length(domains))
	exit(0);

// suffix match on a label boundary: node.example.com matches +.example.com
function domain_matches(key, domain) {
	let key_len = length(key);
	let domain_len = length(domain);

	if (!key_len || domain_len < key_len)
		return false;
	if (domain == key)
		return true;
	if (substr(domain, domain_len - key_len) != key)
		return false;
	return substr(domain, domain_len - key_len - 1, 1) == '.';
}

let result = {};

for (let key, value in policies) {
	if (type(key) != 'string' || !length(key))
		continue;

	let lowered = lc(key);
	let is_pattern = match(lowered, /^[+*]?\./) != null;
	let domain = replace(lowered, /^\+\./, '');

	domain = replace(domain, /^\*\./, '');
	domain = replace(domain, /^\./, '');

	let matched = false;

	for (let candidate in domains) {
		if (is_pattern ? domain_matches(domain, candidate) : (candidate == lowered)) {
			matched = true;
			break;
		}
	}

	if (matched)
		result[key] = value;
}

if (!length(keys(result)))
	exit(0);

print(sprintf('%J', result));
