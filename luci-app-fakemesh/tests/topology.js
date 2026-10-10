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

console.log('6 frontend topology regression tests passed');
