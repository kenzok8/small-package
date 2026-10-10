// Run with: node luci-app-fakemesh/tests/topology.js
'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const source = fs.readFileSync(path.join(__dirname, '../htdocs/luci-static/resources/view/fakemesh/topology.js'), 'utf8');
const view = new Function('view', 'rpc', source)({ extend: value => value }, { declare: () => () => {} });

function check(nodes, expectedParents) {
	const root = view.buildNodeTree(nodes);
	const seen = new Set();
	const parents = {};
	function visit(node, parent) {
		assert(!seen.has(node.id), 'cycle or duplicate node: ' + node.id);
		seen.add(node.id);
		parents[node.id] = parent;
		node.children.forEach(child => visit(child, node.id));
	}
	visit(root, null);
	assert.strictEqual(seen.size, nodes.length, 'all nodes must remain visible');
	if (expectedParents) assert.deepStrictEqual(parents, expectedParents);
	// Polling reuses node objects; rebuilding must not duplicate children.
	const childCount = root.children.length;
	assert.strictEqual(view.buildNodeTree(nodes).children.length, childCount);
}

check([
	{ id: 'ac', role: 'controller' },
	{ id: 'A', parent_id: 'ac' },
	{ id: 'B', parent_id: 'A' }
], { ac: null, A: 'ac', B: 'A' });
check([
	{ id: 'ac', role: 'controller' },
	{ id: 'A', parent_id: 'B' },
	{ id: 'B', parent_id: 'A' },
	{ id: 'C', parent_id: 'B' }
]);
check([
	{ id: 'ac', role: 'controller' },
	{ id: 'A', parent_id: 'A' },
	{ id: 'B', parent_id: 'missing' }
], { ac: null, A: 'ac', B: 'ac' });
check([{ id: 'A' }, { id: 'B', parent_id: 'A' }], { A: null, B: 'A' });
assert.strictEqual(view.buildNodeTree([]), null);

// formatLastActive tests
assert.strictEqual(view.formatLastActive(0), 'Just now');
assert.strictEqual(view.formatLastActive(5), 'Just now');
assert.strictEqual(view.formatLastActive(30), '30 seconds ago');
assert.strictEqual(view.formatLastActive(60), '1 minutes ago');
assert.strictEqual(view.formatLastActive(125), '2m 5s ago');
assert.strictEqual(view.formatLastActive(3600), '1 hours ago');
assert.strictEqual(view.formatLastActive(3720), '1h 2m ago');
assert.strictEqual(view.formatLastActive(86400), '1 days ago');
assert.strictEqual(view.formatLastActive(90000), '1d 1h ago');
assert.strictEqual(view.formatLastActive(-1), '-');
assert.strictEqual(view.formatLastActive(null), '-');
// Modal title translation regression tests
let modalTitle = null;
global.ui = {
	showModal: function(title) { modalTitle = title; },
	hideModal: function() {}
};
global._ = function(s) {
	const dict = {
		'Node Details': '节点详情',
		'Client Details': '终端详情'
	};
	return dict[s] || s;
};
global.E = function() { return {}; };
global.formatUptime = function() { return '1d'; };

view.showNodeModal({ hostname: 'NodeA', ip: '192.168.1.1' });
assert.strictEqual(modalTitle, '节点详情: NodeA');

view.showClientModal({ hostname: 'PhoneB', mac: 'AA:BB:CC:DD:EE:FF' }, {});
assert.strictEqual(modalTitle, '终端详情: PhoneB');

// Ensure all _('...') translation keys have no leading or trailing whitespace
const trRegex = /(?:_|\btr)\(\s*([`'"])(.*?)\1\s*\)/g;
let trMatch;
while ((trMatch = trRegex.exec(source)) !== null) {
	const s = trMatch[2];
	assert.strictEqual(s, s.trim(), 'Translation key must not have leading or trailing whitespace: "' + s + '"');
}
// Verify that all strings in PO match strings in code with zero missing or unused entries
const poPath = path.join(__dirname, '../files/luci/i18n/fakemesh.zh-cn.po');
const poContent = fs.readFileSync(poPath, 'utf8');
const poBlocks = poContent.split(/\n\n+/);
const poMsgids = new Set();
for (const b of poBlocks) {
	const mId = b.match(/msgid\s+"(.*)"/);
	if (mId && mId[1] !== '') {
		poMsgids.add(mId[1].replace(/\\"/g, '"'));
	}
}

const fakemeshJs = fs.readFileSync(path.join(__dirname, '../htdocs/luci-static/resources/view/fakemesh/fakemesh.js'), 'utf8');
const menuJson = JSON.parse(fs.readFileSync(path.join(__dirname, '../root/usr/share/luci/menu.d/luci-app-fakemesh.json'), 'utf8'));

const codeStrings = new Set();
for (const src of [source, fakemeshJs]) {
	const r = /(?:_|\btr)\(\s*([`'"])(.*?)\1\s*\)/g;
	let m;
	while ((m = r.exec(src)) !== null) {
		codeStrings.add(m[2].replace(/\\'/g, "'"));
	}
}
for (const k in menuJson) {
	if (menuJson[k].title) codeStrings.add(menuJson[k].title);
}

for (const s of codeStrings) {
	assert(poMsgids.has(s), 'Missing translation in PO for code string: ' + s);
}
for (const id of poMsgids) {
	assert(codeStrings.has(id), 'Unused translation in PO: ' + id);
}

console.log('9 frontend topology regression tests passed');
