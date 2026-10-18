// Requires Puppeteer and the sibling LuCI checkout; override with LUCI_JS if needed.
// Run with: node luci-app-fakemesh/tests/topology-browser.js
// PUPPETEER_EXECUTABLE_PATH can select an existing Chromium installation.
const fs = require('node:fs');
const assert = require('node:assert/strict');
const path = require('node:path');
const puppeteer = require('puppeteer');
const luciPath = process.env.LUCI_JS || path.resolve(__dirname, '../../../luci/modules/luci-base/htdocs/luci-static/resources/luci.js');
(async () => {
	const browser = await puppeteer.launch({headless:true, args:['--no-sandbox']});
	try {
		const page = await browser.newPage();
		const errors = [];
		page.on('pageerror', error => errors.push(error.message));
		await page.setContent('<html><head></head><body><div id="modal_overlay"><div class="modal"></div></div></body></html>');
		await page.evaluate(() => {
			window._ = s => s;
			String.prototype.format = function(...args) {let i = 0; return this.replace(/%[ds]/g, () => args[i++]);};
			window.poll = {add: fn => {window.pollCallback = fn;}};
			window.ui = {
				showModal(title, contents, ...classes) {
					const modal = document.querySelector('#modal_overlay > div');
					modal.className = ['modal', ...classes].join(' ');
					modal.replaceChildren(E('h4', {}, title), ...contents);
					document.body.classList.add('modal-overlay-active');
					return modal;
				},
				hideModal() {document.body.classList.remove('modal-overlay-active');}
			};
			window.check = (value, message) => {if (!value) throw new Error(message);};
			window.checkIcons = () => {
				const icons = document.querySelectorAll('.fm-client-icon, .fm-node-icon, .fm-mini-icon, .fm-uplink-icon, .fm-wan-icon');
				check(icons.length > 0, 'no topology icons found');
				icons.forEach(icon => {
					check(icon.firstElementChild && icon.firstElementChild.namespaceURI === 'http://www.w3.org/2000/svg', 'icon lacks an SVG element');
					check(!icon.hasAttribute('innerhtml'), 'SVG was stored in an attribute');
				});
			};
			window.rpc = {declare: () => () => window.rpcFailure ? Promise.reject(new Error('offline')) : Promise.resolve(structuredClone(window.nextTopology))};
		});
		// Use LuCI's production DOM helpers: nested arrays must stringify as they do on the router.
		await page.addScriptTag({content: fs.readFileSync(luciPath, 'utf8')});
		await page.evaluate(() => {
			window.dom = LuCI.prototype.dom;
			window.E = dom.create.bind(dom);
		});
		const source = fs.readFileSync(path.join(__dirname, '../htdocs/luci-static/resources/view/fakemesh/topology.js'), 'utf8');
		await page.evaluate(source => {window.topology = new Function('view', 'rpc', source)({extend: value=>value}, window.rpc);}, source);
		await page.evaluate(() => {
			const t = window.topology;
			t.viewMode = 'expanded';
			window.nextTopology = {
				mesh_id:'test', current_node_id:'ac', timestamp:1000,
				summary:{node_count:2, client_count:2, wifi_6g:1, wired:1},
				nodes:[{id:'ac', role:'controller', online:true, ip:'192.168.1.1', hostname:'AC', uptime:10, uplink:{type:'root'}}, {id:'A', role:'agent', online:true, parent_id:'ac', ip:'192.168.1.2', hostname:'AP', uptime:10, uplink:{type:'wired',speed:'1000M'}}],
				clients:[{mac:'AA:BB:CC:DD:EE:01', node_id:'A', access_type:'wireless', band:'6G', hostname:'Phone', ip:'192.168.1.90', signal:-60, rate_rx:1201, rate_tx:866.7, rx_speed:10, tx_speed:1}, {mac:'AA:BB:CC:DD:EE:02', node_id:'A', access_type:'wired',hostname:'PC',ip:'192.168.1.91'}]
			};
			document.body.append(t.render(structuredClone(window.nextTopology)));
			t.updateCanvas();
			checkIcons();
			window.originalCard = document.querySelector('[data-fm-key="client:AA:BB:CC:DD:EE:01"]');
			window.originalBranch = document.querySelector('[data-fm-key="node:A"]');
			check(document.querySelector('.badge-6g'), '6 GHz badge missing');
			window.nextTopology.clients.reverse();
			window.nextTopology.clients[1].hostname = 'Updated phone';
			window.nextTopology.clients[1].rx_speed = 999;
			window.nextTopology.clients[1].icon = 'pc';
			window.nextTopology.nodes[1].uptime = 15;
			window.nextTopology.nodes[1].uplink = {type:'wireless', band:'6G', signal:-50};
		});
		await page.evaluate(async () => {
			await window.pollCallback();
			check(window.originalCard === document.querySelector('[data-fm-key="client:AA:BB:CC:DD:EE:01"]'), 'client DOM was replaced');
			check(window.originalBranch === document.querySelector('[data-fm-key="node:A"]'), 'node DOM was replaced');
			check(window.originalCard.textContent.includes('Updated phone'), 'card text did not update');
			check(window.originalCard.querySelector('.fm-client-icon svg rect'), 'polled icon type did not update');
			checkIcons();
			window.originalCard.click();
			check(document.querySelector('.modal').textContent.includes('Updated phone'), 'retained click handler read an old snapshot');
			window.ui.hideModal();
			const real = window.topology.updateCanvas;
			let renders = 0;
			window.topology.updateCanvas = function() {renders++; return real.call(this);};
			const input = document.querySelector('.fm-search-input');
			for (const value of ['u','up','updated']) {input.value=value; input.dispatchEvent(new Event('input'));}
			await new Promise(resolve => setTimeout(resolve, 220));
			check(renders === 1, 'search was not debounced');
			check(document.querySelectorAll('.fm-client-card').length === 1, 'search filter incorrect');
			window.topology.searchQuery = '';
			window.topology.filterBand = '6g';
			window.topology.updateCanvas();
			check(document.querySelectorAll('.fm-client-card').length === 1, '6 GHz filter incorrect');
			window.topology.filterBand = 'all';
			window.topology.viewMode = 'minimap';
			window.topology.selectedNodeId = 'A';
			window.topology.updateCanvas();
			check(document.querySelectorAll('.fm-client-card').length === 2, 'minimap filtering differs');
			window.nextTopology.clients = window.nextTopology.clients.filter(c => c.access_type === 'wireless');
			window.nextTopology.nodes = window.nextTopology.nodes.filter(n => n.id === 'ac');
			window.nextTopology.clients[0].node_id = 'ac';
			await window.pollCallback();
			check(document.querySelectorAll('.fm-minimap-node').length === 1, 'removed node remained in DOM');
			check(document.querySelectorAll('.fm-minimap-node.selected').length === 1 && document.querySelector('[data-fm-key="node:ac"] > .fm-minimap-node.selected'), 'removed selection did not move to the fallback node in the same poll');
			check(document.querySelectorAll('.fm-client-card').length === 1, 'roaming client lost or duplicated');
		});
		await page.evaluate(async () => {
			const t = window.topology;
			const mac = window.nextTopology.clients[0].mac;
			t.showClientModal(t.findClient(mac), t.findNode('ac'));
			const modal = document.querySelector('.fm-detail-modal');
			const close = modal.querySelector('.right button');
			close.focus();
			window.nextTopology.clients[0].rate_rx = 2402;
			window.nextTopology.clients[0].hostname = 'Live details';
			await window.pollCallback();
			check(modal.textContent.includes('2402 Mbps') && modal.textContent.includes('Live details'), 'open client details did not refresh');
			check(modal.querySelector('.right button') === close && document.activeElement === close, 'refresh replaced the Close button or lost focus');
			for (let pass = 0; pass < 3; pass++) {
				window.nextTopology.clients[0].rx_speed = (pass + 1) * 1024;
				await window.pollCallback();
				check(modal.querySelectorAll('.fm-modal-body table').length === 2, 'refresh removed client detail tables');
				check(!modal.textContent.includes('[object HTMLDivElement]'), 'refresh stringified DOM nodes');
				check(modal.textContent.includes((pass + 1) + '.0 KB/s'), 'repeated refresh did not update speed');
				check(modal.querySelector('.right button') === close && document.activeElement === close, 'repeated refresh lost button focus');
			}
			const snapshot = t.data;
			window.rpcFailure = true;
			await window.pollCallback();
			check(t.data === snapshot && modal.textContent.includes('Refresh failed'), 'request failure discarded data or lacked stale warning');
			window.rpcFailure = false;
			window.nextTopology.clients = [];
			await window.pollCallback();
			check(modal.textContent.includes('no longer present'), 'removed client kept stale detail values');
			window.nextTopology.clients = [{mac, node_id:'ac', access_type:'wireless', band:'6G', hostname:'Returned',rate_rx:1201,rate_tx:1201}];
			await window.pollCallback();
			check(modal.textContent.includes('Returned') && !modal.textContent.includes('no longer present'), 'returning client did not restore live details');
			modal.click();
			check(document.body.classList.contains('modal-overlay-active'), 'inside click closed dialog');
			document.getElementById('modal_overlay').click();
			check(!document.body.classList.contains('modal-overlay-active'), 'backdrop no longer closes dialog');
			await window.pollCallback();
			check(!document.body.classList.contains('modal-overlay-active'), 'poll reopened a closed dialog');
			t.showNodeModal(t.findNode('ac'));
			window.nextTopology.nodes[0].hostname = 'Updated AC';
			await window.pollCallback();
			check(modal.textContent.includes('Updated AC'), 'node details did not refresh');
			ui.showModal('Unrelated dialog', [E('p', {}, 'Other content')]);
			await window.pollCallback();
			document.getElementById('modal_overlay').click();
			check(document.body.classList.contains('modal-overlay-active') && modal.textContent.includes('Other content'), 'poll or backdrop affected unrelated modal');
			ui.hideModal();
		});
		await page.evaluate(async () => {
			const t = window.topology;
			const payload = '<img src=x onerror=window.fmInjected=1>';
			const node = {id:'ac', role:'controller', hostname:payload, model:payload, ip:'192.168.1.1', online:true, uplink:{type:'root'}};
			const client = {mac:'AA:BB:CC:DD:EE:99', node_id:'ac', hostname:payload, ssid:payload, icon:payload, band:'6G', access_type:'wireless', ip:payload, ips:[payload], ip6:[payload]};
			window.nextTopology = {mesh_id:payload, current_node_id:'ac', nodes:[node], clients:[client]};
			for (const mode of ['expanded', 'minimap']) {
				t.viewMode = mode;
				await window.pollCallback();
				const card = document.querySelector('.fm-client-card');
				checkIcons();
				check(card.querySelector('.fm-client-name').textContent === payload, 'hostname is not literal text');
				check(card.textContent.includes(payload), 'client details lost special characters');
				check(document.querySelector('#fm-topology-summary').textContent.includes(payload), 'Mesh ID is not literal text');
				t.showNodeModal(t.findNode('ac'));
				check(document.querySelector('.fm-detail-modal h4').textContent === 'Node Details: ' + payload, 'node title is not literal text');
				check(document.querySelector('.fm-modal-body').textContent.includes(payload), 'node details lost special characters');
				ui.hideModal();
				t.showClientModal(t.findClient(client.mac), t.findNode('ac'));
				for (let pass = 0; pass < 2; pass++) {
					await window.pollCallback();
					const modal = document.querySelector('.fm-detail-modal');
					check(modal.querySelector('h4').textContent === 'Client Details: ' + payload, 'client title is not literal text');
					check(Array.from(modal.querySelectorAll('tr')).some(row => row.textContent.includes('Access Mode') && row.textContent.includes(payload)), 'SSID is not literal text');
					check(!document.querySelector('img, [onerror]'), 'topology data created executable markup');
				}
				ui.hideModal();
			}
			await new Promise(resolve => setTimeout(resolve, 50));
			check(window.fmInjected === undefined, 'topology data executed script');
		});
		console.log('Chromium text checks passed: literal Mesh ID, node/client names, model, IPs, SSID and modal titles in both views and across polls.');
		console.log('Chromium detail checks passed: live node/client data, focus, removal/return, failures, backdrop, closed/unrelated dialogs.');
		assert.deepEqual(errors, []);
		console.log('Chromium checks passed: keyed updates/reordering, latest click data, search debounce, 6 GHz, both views, removal/roaming.');
	} finally {await browser.close();}
})().catch(error => {console.error(error); process.exitCode=1;});
