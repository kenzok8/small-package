'use strict';
'require baseclass';
'require rpc';

const callListSubs = rpc.declare({ object: 'luci.tower', method: 'subscriptions' });
const callListNodes = rpc.declare({ object: 'luci.tower', method: 'nodes' });
const callUpdateNode = rpc.declare({ object: 'luci.tower', method: 'update_node', params: ['node_json'] });
const callRemoveNode = rpc.declare({ object: 'luci.tower', method: 'remove_node', params: ['id'] });
const callAddSub = rpc.declare({ object: 'luci.tower', method: 'add_subscription', params: ['name', 'url', 'user_agent'] });
const callRemoveSub = rpc.declare({ object: 'luci.tower', method: 'remove_subscription', params: ['id'] });
const callRefresh = rpc.declare({ object: 'luci.tower', method: 'refresh', params: ['id'] });
const callExport = rpc.declare({ object: 'luci.tower', method: 'export', params: ['target', 'protocols', 'nodes', 'scheme', 'prefer_rule_sets'] });
const callLinks = rpc.declare({ object: 'luci.tower', method: 'links', params: ['protocols', 'nodes'] });
const callShareCreate = rpc.declare({ object: 'luci.tower', method: 'share_create', params: ['destination', 'nodes', 'scheme', 'prefer_rule_sets'] });
const callShareRevoke = rpc.declare({ object: 'luci.tower', method: 'share_revoke' });
const callImport = rpc.declare({ object: 'luci.tower', method: 'import_nodes', params: ['content'] });
const callSchemes = rpc.declare({ object: 'luci.tower', method: 'schemes' });
const callSchemeDetail = rpc.declare({ object: 'luci.tower', method: 'scheme_detail', params: ['id'] });
const callAddScheme = rpc.declare({ object: 'luci.tower', method: 'add_scheme', params: ['name', 'config', 'source_url'] });
const callRemoveScheme = rpc.declare({ object: 'luci.tower', method: 'remove_scheme', params: ['id'] });
const callRenameScheme = rpc.declare({ object: 'luci.tower', method: 'rename_scheme', params: ['id', 'name'] });
const callRefreshScheme = rpc.declare({ object: 'luci.tower', method: 'refresh_scheme', params: ['id'] });

function rpcError(r) {
	if (r && r.error)
		throw new Error(r.error);
	return r;
}

/* Export destinations share the existing format generators. */
const clients = [
	{ id: 'clash-verge', name: 'Clash Verge', icon: 'ClientClashVerge.png' },
	{ id: 'clash', name: 'Stash', icon: 'ClientStash.png' },
	{ id: 'clash-apple', name: 'Clash', icon: 'ClientClash.png' },
	{ id: 'clashmac', name: 'ClashMac', icon: 'ClientClashMac.png' },
	{ id: 'flclash', name: 'FlClash', icon: 'ClientFlClash.png' },
	{ id: 'mihomo-party', name: 'Mihomo Party', icon: 'ClientMihomoParty.png' },
	{ id: 'clash-mi', name: 'Clash Mi', icon: 'ClientClashMi.png' },
	{ id: 'karing', name: 'Karing', icon: 'ClientKaring.png' },
	{ id: 'sing-box', name: 'sing-box MT', icon: 'ClientSingBox.png' },
	{ id: 'hiddify', name: 'Hiddify', icon: 'ClientHiddify.png' },
	{ id: 'surge', name: 'Surge', icon: 'ClientSurge.png' },
	{ id: 'surge-mac', name: 'Surge Mac', icon: 'ClientSurgeMac.png' },
	{ id: 'shadowrocket', name: 'Shadowrocket', icon: 'ClientShadowrocket.png' }
];

const openwrtClients = [
	{ id: 'openclash', name: 'OpenClash', icon: 'OpenClash.png', detail: 'Mihomo YAML' },
	{ id: 'nikki', name: 'Nikki', icon: 'Nikki.png', detail: 'Mihomo YAML' },
	{ id: 'clashoo-mihomo', name: 'Clashoo · Mihomo', icon: 'Clashoo.png', detail: 'Mihomo YAML' },
	{ id: 'clashoo-singbox', name: 'Clashoo · sing-box', icon: 'Clashoo.png', detail: 'sing-box JSON', nodeOnly: true },
	{ id: 'momo', name: 'Momo', icon: 'ClientSingBox.png', detail: 'sing-box JSON · 需适配入站', nodeOnly: true },
	{ id: 'daede', name: 'daede', target: 'links', icon: 'ClientDae.png', detail: '节点订阅 · 规则在插件中管理', nodeOnly: true, allowedKinds: [ 'ss', 'vmess', 'vless', 'trojan', 'hysteria2', 'tuic', 'socks5' ] }
];

/* Protocol filter options. */
/* User-Agent presets for subscription fetch. */
const userAgents = [
	{ id: '', name: _('自动选择 User-Agent（推荐）') },
	{ id: 'ClashMeta', name: 'ClashMeta' },
	{ id: 'clash-verge/v2.4.2', name: 'clash-verge/v2.4.2' },
	{ id: 'ClashForWindows/0.20.39', name: 'ClashForWindows/0.20.39' },
	{ id: 'Clash', name: 'Clash' },
	{ id: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36', name: _('浏览器 User-Agent') }
];

const protocols = [
	{ id: 'ss', name: 'Shadowsocks' },
	{ id: 'ssr', name: 'ShadowsocksR' },
	{ id: 'vmess', name: 'VMess' },
	{ id: 'vless', name: 'VLESS' },
	{ id: 'trojan', name: 'Trojan' },
	{ id: 'hysteria', name: 'Hysteria' },
	{ id: 'hysteria2', name: 'Hysteria 2' },
	{ id: 'tuic', name: 'TUIC' },
	{ id: 'wireguard', name: 'WireGuard' },
	{ id: 'anytls', name: 'AnyTLS' },
	{ id: 'snell', name: 'Snell' },
	{ id: 'socks5', name: 'SOCKS5' },
	{ id: 'http', name: 'HTTP' }
];

function copyText(text) {
	if (navigator.clipboard && navigator.clipboard.writeText)
		return navigator.clipboard.writeText(text);

	return new Promise(function(resolve, reject) {
		var ta = document.createElement('textarea');
		ta.value = text;
		ta.style.position = 'fixed';
		ta.style.opacity = '0';
		document.body.appendChild(ta);
		ta.select();
		try {
			document.execCommand('copy');
			resolve();
		} catch (e) {
			reject(e);
		} finally {
			document.body.removeChild(ta);
		}
	});
}

function downloadFile(filename, content) {
	var blob = new Blob([ content ], { type: 'text/plain;charset=utf-8' });
	var url = URL.createObjectURL(blob);
	var a = document.createElement('a');
	a.href = url;
	a.download = filename;
	document.body.appendChild(a);
	a.click();
	document.body.removeChild(a);
	setTimeout(function() { URL.revokeObjectURL(url); }, 2000);
}

return baseclass.extend({
	copyText: copyText,
	downloadFile: downloadFile,
	rpcListSubs: function() {
		return L.resolveDefault(callListSubs(), { data: [] }).then(function(r) { return r.data; });
	},
	rpcListNodes: function() {
		return L.resolveDefault(callListNodes(), { data: [] }).then(function(r) { return r.data; });
	},
	rpcUpdateNode: function(node) {
		return L.resolveDefault(callUpdateNode(node), { success: false }).then(rpcError);
	},
	rpcRemoveNode: function(id) {
		return L.resolveDefault(callRemoveNode(id), { success: false }).then(rpcError);
	},
	rpcAddSub: function(name, url, ua) {
		return L.resolveDefault(callAddSub(name, url, ua), { data: null }).then(function(r) { return r.data; });
	},
	rpcRemoveSub: function(id) {
		return L.resolveDefault(callRemoveSub(id), { success: false });
	},
	rpcRefresh: function(id) {
		return L.resolveDefault(callRefresh(id), { data: [] }).then(function(r) { return rpcError(r).data; });
	},
	rpcExport: function(target, protocols, nodes, scheme, preferRuleSets) {
		return L.resolveDefault(callExport(target, protocols, nodes, scheme, preferRuleSets !== false), { content: '' }).then(function(r) { return rpcError(r).content; });
	},
	rpcLinks: function(protocols, nodes) {
		return L.resolveDefault(callLinks(protocols, nodes), { data: [] }).then(function(r) { return rpcError(r).data; });
	},
	rpcShareCreate: function(destination, nodes, scheme, preferRuleSets) {
		return L.resolveDefault(callShareCreate(destination, nodes, scheme, preferRuleSets !== false), { data: null }).then(function(r) { return rpcError(r).data; });
	},
	rpcShareRevoke: function() {
		return L.resolveDefault(callShareRevoke(), { success: false }).then(rpcError);
	},
	rpcSchemes: function() {
		return L.resolveDefault(callSchemes(), { data: [] }).then(function(r) { return rpcError(r).data; });
	},
	rpcSchemeDetail: function(id) {
		return L.resolveDefault(callSchemeDetail(id), { data: null }).then(function(r) { return rpcError(r).data; });
	},
	rpcAddScheme: function(name, config, url) {
		return L.resolveDefault(callAddScheme(name, config, url), { data: null }).then(function(r) { return rpcError(r).data; });
	},
	rpcRemoveScheme: function(id) {
		return L.resolveDefault(callRemoveScheme(id), { success: false }).then(rpcError);
	},
	rpcRenameScheme: function(id, name) {
		return L.resolveDefault(callRenameScheme(id, name), { success: false }).then(rpcError);
	},
	rpcRefreshScheme: function(id) {
		return L.resolveDefault(callRefreshScheme(id), { data: null }).then(function(r) { return rpcError(r).data; });
	},
	rpcImport: function(content) {
		return L.resolveDefault(callImport(content), { imported: 0 });
	},
	clients: clients,
	openwrtClients: openwrtClients,
	protocols: protocols,
	userAgents: userAgents
});
