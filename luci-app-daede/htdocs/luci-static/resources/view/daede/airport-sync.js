// SPDX-License-Identifier: Apache-2.0

'use strict';
'require baseclass';

function deriveAirportName(value) {
	try {
		const url = new URL(String(value || ''));
		const filename = url.searchParams.get('filename');
		if (filename) {
			const name = filename.replace(/\.(?:ya?ml)$/i, '').trim();
			if (name)
				return name;
		}
		// Use the registrable label, not the whole hostname: sub.ssr.sh -> ssr.
		// Dropping the TLD (and any sub.* prefix) keeps the default group name
		// clean and avoids leaking the provider's full domain.
		const labels = (url.hostname || '').split('.').filter(Boolean);
		if (labels.length >= 2)
			return labels[labels.length - 2];
		return labels[0] || '机场_1';
	} catch (e) {
		return '机场_1';
	}
}

function nextPastedName(names) {
	const used = {};
	(names || []).forEach(function(name) { used[String(name)] = true; });
	let index = 1;
	while (used['机场_' + index])
		index++;
	return '机场_' + index;
}

function makeAirportId() {
	return 'airport_' + Date.now().toString(36) + '_' + Math.random().toString(36).slice(2, 8);
}

function backendId(id) {
	return String(id || '').replace(/[^A-Za-z0-9]/g, '') || 'airport';
}

function backendGroupName(name, backend, id) {
	const value = String(name || '').trim();
	if (isGroupNameValid(value, backend))
		return value || backendId(id);
	return backendId(id);
}

function isGroupNameValid(name, backend) {
	const value = String(name || '').trim();
	return !!value && (backend !== 'dae' || /^[A-Za-z_][A-Za-z0-9_-]*$/.test(value));
}

// Coerce an auto-derived name (URL hostname/filename) into a name the third
// step accepts, so the group name is pre-filled valid and needs no manual fix.
// daed allows any non-empty name (incl. CJK); dae requires
// /^[A-Za-z_][A-Za-z0-9_-]*$/, so collapse illegal chars to '_' and drop a
// leading non-letter/underscore run.
function sanitizeGroupName(name, backend) {
	const value = String(name || '').trim();
	if (!value || backend !== 'dae')
		return value;
	const cleaned = value
		.replace(/[^A-Za-z0-9_-]+/g, '_')
		.replace(/_{2,}/g, '_')
		.replace(/^[^A-Za-z_]+/, '')
		.replace(/[-_]+$/, '');
	return cleaned || 'airport';
}

function hashSource(value) {
	// LuCI is commonly served over plain HTTP, where Web Crypto is unavailable.
	// This stable opaque key is only used to match a previously managed source.
	let h1 = 0x811c9dc5, h2 = 0x9e3779b9, h3 = 0x85ebca6b, h4 = 0xc2b2ae35;
	const text = unescape(encodeURIComponent(String(value || '')));
	for (let index = 0; index < text.length; index++) {
		const code = text.charCodeAt(index);
		h1 = Math.imul(h1 ^ code, 0x01000193);
		h2 = Math.imul(h2 ^ code, 0x5bd1e995);
		h3 = Math.imul(h3 ^ code, 0x27d4eb2d);
		h4 = Math.imul(h4 ^ code, 0x165667b1);
	}
	const words = [ h1, h2, h3, h4, h1 ^ h3, h2 ^ h4, h1 ^ h2 ^ h4, h1 ^ h2 ^ h3 ^ h4 ];
	return Promise.resolve(words.map(function(word) {
		return (word >>> 0).toString(16).padStart(8, '0');
	}).join(''));
}

function list(value) {
	if (Array.isArray(value))
		return value.filter(Boolean).map(String);
	return value ? [ String(value) ] : [];
}

function parseAirportSection(section) {
	if (!section)
		return null;
	return {
		sid: section['.name'],
		id: String(section.id || ''),
		backend: String(section.backend || ''),
		name: String(section.name || ''),
		source_hash: String(section.source_hash || ''),
		group_id: String(section.group_id || ''),
		subscription_id: String(section.subscription_id || ''),
		node_ids: list(section.node_id)
	};
}

function airportSectionValues(record) {
	return {
		id: String(record.id || ''),
		backend: String(record.backend || ''),
		name: String(record.name || ''),
		source_hash: String(record.sourceHash || record.source_hash || ''),
		group_id: String(record.groupId || record.group_id || ''),
		subscription_id: String(record.subscriptionId || record.subscription_id || ''),
		node_id: list(record.nodeIds || record.node_ids)
	};
}

function matchAirport(records, candidate) {
	const sameBackend = (records || []).filter(function(record) {
		return record.backend === candidate.backend;
	});
	if (candidate.selectedId) {
		const selected = sameBackend.find(function(record) { return record.id === candidate.selectedId; });
		if (selected)
			return selected;
	}
	if (candidate.sourceHash) {
		const bySource = sameBackend.find(function(record) { return record.source_hash === candidate.sourceHash; });
		if (bySource)
			return bySource;
	}
	return sameBackend.find(function(record) { return record.name === candidate.name; }) || null;
}

function safeOldNodeIds(oldIds, newIds, otherAirportNodeIds, otherGroupNodeIds) {
	const keep = {};
	list(newIds).forEach(function(id) { keep[id] = true; });
	(otherAirportNodeIds || []).forEach(function(ids) { list(ids).forEach(function(id) { keep[id] = true; }); });
	(otherGroupNodeIds || []).forEach(function(ids) { list(ids).forEach(function(id) { keep[id] = true; }); });
	return list(oldIds).filter(function(id) { return !keep[id]; });
}

function findManagedGroup(groups, record) {
	if (!record || !record.group_id)
		return null;
	return (groups || []).find(function(group) {
		return group.id === record.group_id && group.name === record.name;
	}) || null;
}

function findGroupByName(groups, name) {
	return (groups || []).find(function(group) { return group.name === name; }) || null;
}

const api = {
	deriveAirportName: deriveAirportName,
	nextPastedName: nextPastedName,
	makeAirportId: makeAirportId,
	backendId: backendId,
	backendGroupName: backendGroupName,
	isGroupNameValid: isGroupNameValid,
	sanitizeGroupName: sanitizeGroupName,
	hashSource: hashSource,
	parseAirportSection: parseAirportSection,
	airportSectionValues: airportSectionValues,
	matchAirport: matchAirport,
	findManagedGroup: findManagedGroup,
	findGroupByName: findGroupByName,
	safeOldNodeIds: safeOldNodeIds
};

if (typeof module !== 'undefined' && module.exports)
	module.exports = api;

if (typeof baseclass !== 'undefined')
	return baseclass.extend(api);

return api;
