'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const sourcePath = path.resolve(__dirname, '../htdocs/luci-static/resources/view/daede/log.js');
let source = fs.readFileSync(sourcePath, 'utf8');
const exportMarker = 'return view.extend({';

assert.ok(source.includes(exportMarker), 'LuCI view export marker not found');
source = source.replace(
	exportMarker,
	'globalThis.__logTest = { parseLine, formatTs, buildLine };\n' + exportMarker
);

function E(tag, attrs, children) {
	return { tag, attrs: attrs || {}, children };
}

const context = {
	E,
	_: value => value,
	fs: {},
	poll: {},
	ui: {},
	backend: {},
	view: { extend: value => value }
};

vm.runInNewContext('(function() {\n' + source + '\n})()', context);

const { parseLine, formatTs, buildLine } = context.__logTest;
assert.equal(typeof parseLine, 'function');
assert.equal(typeof formatTs, 'function');
assert.equal(typeof buildLine, 'function');

const oldLine = 'time="May 25 15:54:58" level=info msg="Loaded eBPF programs and maps" group=proxy network="tcp4(DNS)"';
const infoLine = '[2026-08-27 17:24:57] INFO 192.168.3.20:46477 <-> 54.87.238.215:9930 dialer=HK network=udp4 outbound=proxy';
const warnLine = '[2026-08-27 17:24:58] WARN UdpEndpoint read loop exited with error dialer=SG err_type=*net.OpError nat_timeout=30s';
const plainLine = '[2026-08-27 17:25:00] INFO Loaded eBPF programs and maps';

assert.deepEqual(
	JSON.parse(JSON.stringify(parseLine(infoLine))),
	{
		ts: '2026-08-27 17:24:57',
		lvl: 'INFO',
		msg: '192.168.3.20:46477 <-> 54.87.238.215:9930',
		kv: 'dialer=HK network=udp4 outbound=proxy'
	}
);
assert.equal(parseLine(warnLine).lvl, 'WARN');
assert.equal(parseLine(warnLine).kv, 'dialer=SG err_type=*net.OpError nat_timeout=30s');
assert.equal(parseLine(plainLine).kv, '');
assert.equal(formatTs('2026-05-28T19:07:54Z'), '2026-05-29 03:07:54');
assert.equal(formatTs('May 25 15:54:58'), 'May 25 15:54:58');

for (const line of [oldLine, infoLine, warnLine]) {
	const node = buildLine(line);
	assert.equal(node.tag, 'div');
	assert.deepEqual(
		JSON.parse(JSON.stringify(node.children.map(child => child.attrs.class.split(' ')[0]))),
		['dd-ts', 'dd-lvl', 'dd-msg', 'dd-kv']
	);
}

assert.equal(buildLine(plainLine).children.length, 3);
console.log('log parser tests passed');
