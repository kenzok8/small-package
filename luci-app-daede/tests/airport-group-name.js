const assert = require('assert');
const airportSync = require('../htdocs/luci-static/resources/view/daede/airport-sync.js');

assert.strictEqual(airportSync.backendGroupName('fs-cloud', 'dae', 'airport_123'), 'fs-cloud');
assert.strictEqual(airportSync.backendGroupName('fs-cloud', 'daed', 'airport_123'), 'fs-cloud');
assert.strictEqual(airportSync.backendGroupName('白月光', 'daed', 'airport_123'), '白月光');
assert.strictEqual(airportSync.backendGroupName('白月光', 'dae', 'airport_123'), 'airport123');
assert.strictEqual(airportSync.backendGroupName('', 'dae', 'airport_123'), 'airport123');
assert.strictEqual(airportSync.isGroupNameValid('fs-cloud', 'dae'), true);
assert.strictEqual(airportSync.isGroupNameValid('白月光', 'dae'), false);
assert.strictEqual(airportSync.isGroupNameValid('白月光', 'daed'), true);

const managed = { group_id: 'group-1', name: 'Airport 1' };
assert.strictEqual(airportSync.findManagedGroup([
	{ id: 'group-1', name: 'Airport 1' },
	{ id: 'group-2', name: 'Airport 2' }
], managed).id, 'group-1');
assert.strictEqual(airportSync.findManagedGroup([
	{ id: 'group-1', name: 'Unrelated group' }
], managed), null);

console.log('airport group name tests passed');
