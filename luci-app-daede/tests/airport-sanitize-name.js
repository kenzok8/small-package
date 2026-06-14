const assert = require('assert');
const airportSync = require('../htdocs/luci-static/resources/view/daede/airport-sync.js');

// dae: derived names must come out as valid dae group names (no manual fix).
assert.strictEqual(airportSync.sanitizeGroupName('sub.example.com', 'dae'), 'sub_example_com');
assert.strictEqual(airportSync.sanitizeGroupName('My Airport', 'dae'), 'My_Airport');
assert.strictEqual(airportSync.sanitizeGroupName('机场_1', 'dae'), '_1');
assert.strictEqual(airportSync.sanitizeGroupName('....', 'dae'), 'airport');
assert.strictEqual(airportSync.sanitizeGroupName('', 'dae'), '');
// whatever dae sanitize returns (non-empty) must pass the group-name validator.
['sub.example.com', 'My Airport', '机场_1', '1up.cloud', 'a.b.c.d'].forEach(function(raw) {
	const out = airportSync.sanitizeGroupName(raw, 'dae');
	assert.strictEqual(airportSync.isGroupNameValid(out, 'dae'), true, 'invalid dae name from: ' + raw + ' -> ' + out);
});

// daed: any non-empty name is allowed, keep it as-is (incl. CJK and dots).
assert.strictEqual(airportSync.sanitizeGroupName('白月光', 'daed'), '白月光');
assert.strictEqual(airportSync.sanitizeGroupName('sub.example.com', 'daed'), 'sub.example.com');

console.log('airport sanitize name tests passed');
