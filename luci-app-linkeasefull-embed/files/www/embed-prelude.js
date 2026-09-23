'use strict';

(function() {
	window.__LINKEASE_LUCI_EMBEDDED__ = true;

	function root() {
		return window.__LINKEASE_LUCI_ROOT__ ||
			document.querySelector('.le-luci-document') ||
			document;
	}

	function query(selector) {
		return root().querySelector(selector);
	}

	function queryAll(selector) {
		return root().querySelectorAll(selector);
	}

	function config() {
		return window.__LINKEASE_LUCI_CONFIG__ || {};
	}

	function isolationMode() {
		var mode = config().isolation;
		switch (mode) {
		case 'none':
		case 'scoped-dom':
		case 'scoped-dom-css':
		case 'strict':
			return mode;
		default:
			return 'scoped-dom-css';
		}
	}

	function shouldScopeDOM() {
		return isolationMode() !== 'none';
	}

	function shouldScopeDynamicNodes() {
		var mode = isolationMode();
		return mode === 'scoped-dom-css' || mode === 'strict';
	}

	function shouldScopeCSS() {
		var mode = isolationMode();
		return mode === 'scoped-dom-css' || mode === 'strict';
	}

	function shouldGuardGlobals() {
		return isolationMode() === 'strict';
	}

	function ensureHost(name) {
		var scope = root();
		if (!scope || scope === document)
			return null;

		var attr = 'data-linkease-luci-' + name + '-host';
		var host = scope.querySelector('[' + attr + ']');
		if (host)
			return host;

		host = document.createElement('div');
		host.setAttribute(attr, 'true');
		if (name === 'style')
			host.hidden = true;
		scope.appendChild(host);
		return host;
	}

	function findScopedId(scope, id) {
		if (scope.id === id)
			return scope;

		var nodes = scope.getElementsByTagName ? scope.getElementsByTagName('*') : [];
		for (var i = 0; i < nodes.length; i++) {
			if (nodes[i].id === id)
				return nodes[i];
		}

		return null;
	}

	function simpleIdSelector(selector) {
		var match = /^#([A-Za-z_][A-Za-z0-9_-]*)$/.exec(String(selector || '').trim());
		return match ? match[1] : null;
	}

	function mountIds() {
		var defaults = ['root', 'app', 'app-root', 'mount', 'vue-app', 'react-root'];
		var configured = window.__LINKEASE_LUCI_CONFIG__ &&
			Array.isArray(window.__LINKEASE_LUCI_CONFIG__.mountIds)
			? window.__LINKEASE_LUCI_CONFIG__.mountIds
			: [];
		var seen = {};

		return defaults.concat(configured).filter(function(id) {
			if (typeof id != 'string' || !id || seen[id])
				return false;

			seen[id] = true;
			return true;
		});
	}

	function isMountId(id) {
		return mountIds().indexOf(id) >= 0;
	}

	function getScopedElementById(id, fallback) {
		if (!shouldScopeDOM())
			return fallback();

		if (!isMountId(id))
			return fallback();

		if (window.__LINKEASE_LUCI_EMBEDDED__) {
			var scope = root();
			if (scope && scope !== document) {
				var scoped = findScopedId(scope, id);
				if (scoped)
					return scoped;

				return null;
			}
		}

		return fallback();
	}

	function installDocumentIdScope() {
		if (document.__linkeaseLuciIdScopeVersion >= 2)
			return;

		var originalGetElementById =
			document.__linkeaseLuciOriginalGetElementById ||
			document.getElementById.bind(document);
		var originalQuerySelector =
			document.__linkeaseLuciOriginalQuerySelector ||
			document.querySelector.bind(document);

		document.getElementById = function(id) {
			return getScopedElementById(String(id), function() {
				return originalGetElementById(id);
			});
		};

		document.querySelector = function(selector) {
			var id = simpleIdSelector(selector);
			if (id) {
				return getScopedElementById(id, function() {
					return originalQuerySelector(selector);
				});
			}

			return originalQuerySelector(selector);
		};

		document.__linkeaseLuciOriginalGetElementById = originalGetElementById;
		document.__linkeaseLuciOriginalQuerySelector = originalQuerySelector;
		document.__linkeaseLuciIdScopeInstalled = true;
		document.__linkeaseLuciIdScopeVersion = 2;
	}

	function isStylesheetNode(node) {
		if (!node || node.nodeType !== 1)
			return false;

		var tag = node.tagName ? node.tagName.toLowerCase() : '';
		return tag === 'style' ||
			(tag === 'link' && /\bstylesheet\b/i.test(node.getAttribute('rel') || ''));
	}

	function isPortalNode(node) {
		if (!node || node.nodeType !== 1)
			return false;

		var value = [
			node.id || '',
			node.className || '',
			node.getAttribute('role') || '',
			node.getAttribute('data-testid') || ''
		].join(' ');

		return /\b(modal|toast|message|notification|notify|overlay|popover|drawer|loading|tooltip)\b/i.test(value) ||
			/\b(dialog|alertdialog)\b/i.test(value);
	}

	function rebaseCssUrls(css, baseHref) {
		return String(css || '').replace(/url\(\s*(['"]?)([^'")]+)\1\s*\)/gi, function(match, quote, rawUrl) {
			var url = String(rawUrl || '').trim();
			if (!url || url[0] === '/' || url[0] === '#' || /^[a-z][a-z0-9+.-]*:/i.test(url))
				return match;

			try {
				return 'url("' + new URL(url, baseHref).href + '")';
			} catch (e) {
				return match;
			}
		});
	}

	function scopeSelector(selector) {
		var trimmed = String(selector || '').trim();
		if (!trimmed || trimmed.indexOf('.le-luci-document') === 0)
			return trimmed;

		var rootScoped = trimmed.replace(/^(html|body|:root|#app)(?=$|[\s.#:[>+~])/, '.le-luci-document');
		if (rootScoped !== trimmed)
			return rootScoped;

		return '.le-luci-document ' + trimmed;
	}

	function scopeCss(css) {
		return String(css || '')
			.replace(/position\s*:\s*fixed/gi, 'position: absolute')
			.replace(/\b100vh\b|\b100vw\b/gi, '100%')
			.replace(/(^|})\s*([^@{}][^{]+)\{/g, function(match, close, selectorList) {
				var scoped = selectorList.split(',').map(scopeSelector).join(',');
				return close + scoped + '{';
			});
	}

	function prepareStyleNode(node, baseHref) {
		if (!node || !node.tagName || node.tagName.toLowerCase() !== 'style')
			return node;

		var css = rebaseCssUrls(node.textContent || '', baseHref || window.location.href);
		node.textContent = shouldScopeCSS() ? scopeCss(css) : css;
		return node;
	}

	function loadScopedStylesheet(linkNode, host) {
		var href = linkNode.href || linkNode.getAttribute('href');
		if (!href || typeof fetch != 'function')
			return;

		fetch(href, { credentials: 'include' })
			.then(function(response) {
				if (!response.ok)
					throw new Error('stylesheet load failed');
				return response.text();
			})
			.then(function(css) {
				var style = document.createElement('style');
				style.setAttribute('data-linkease-luci-from', href);
				css = rebaseCssUrls(css, href);
				style.textContent = shouldScopeCSS() ? scopeCss(css) : css;
				host.appendChild(style);
			})
			.catch(function() {});
	}

	function installDynamicNodeScope() {
		if (document.__linkeaseLuciDynamicNodeScopeInstalled)
			return;

		var originalHeadAppendChild = document.head.appendChild.bind(document.head);
		var originalHeadInsertBefore = document.head.insertBefore.bind(document.head);
		var originalBodyAppendChild = document.body.appendChild.bind(document.body);
		var originalBodyInsertBefore = document.body.insertBefore.bind(document.body);

	function redirectHeadNode(node, fallback) {
			if (window.__LINKEASE_LUCI_EMBEDDED__ && shouldScopeDynamicNodes() && isStylesheetNode(node)) {
				var host = ensureHost('style');
				if (host) {
					if (node.tagName && node.tagName.toLowerCase() === 'link') {
						loadScopedStylesheet(node, host);
						return node;
					}

					return host.appendChild(prepareStyleNode(node));
				}
			}

			return fallback();
		}

		function redirectBodyNode(node, fallback) {
			if (window.__LINKEASE_LUCI_EMBEDDED__ && shouldScopeDynamicNodes() && isPortalNode(node)) {
				var host = ensureHost('portal');
				if (host)
					return host.appendChild(node);
			}

			return fallback();
		}

		document.head.appendChild = function(node) {
			return redirectHeadNode(node, function() {
				return originalHeadAppendChild(node);
			});
		};

		document.head.insertBefore = function(node, child) {
			return redirectHeadNode(node, function() {
				return originalHeadInsertBefore(node, child);
			});
		};

		document.body.appendChild = function(node) {
			return redirectBodyNode(node, function() {
				return originalBodyAppendChild(node);
			});
		};

		document.body.insertBefore = function(node, child) {
			return redirectBodyNode(node, function() {
				return originalBodyInsertBefore(node, child);
			});
		};

		document.__linkeaseLuciDynamicNodeScopeInstalled = true;
	}

	function installStrictGlobalGuard() {
		if (!shouldGuardGlobals()) {
			if (document.__linkeaseLuciStrictGlobalGuardObserver) {
				document.__linkeaseLuciStrictGlobalGuardObserver.disconnect();
				document.__linkeaseLuciStrictGlobalGuardObserver = null;
			}
			document.__linkeaseLuciStrictGlobalGuardInstalled = false;
			return;
		}

		if (document.__linkeaseLuciStrictGlobalGuardInstalled || typeof MutationObserver === 'undefined')
			return;

		var html = document.documentElement;
		var body = document.body;
		var original = [
			{ node: html, className: html.getAttribute('class'), style: html.getAttribute('style') },
			{ node: body, className: body.getAttribute('class'), style: body.getAttribute('style') }
		];
		var restoring = false;

		function restoreAttribute(node, name, value) {
			if (value == null)
				node.removeAttribute(name);
			else
				node.setAttribute(name, value);
		}

		function restore() {
			if (restoring)
				return;

			restoring = true;
			original.forEach(function(item) {
				restoreAttribute(item.node, 'class', item.className);
				restoreAttribute(item.node, 'style', item.style);
			});
			restoring = false;
		}

		var observer = new MutationObserver(function(mutations) {
			if (restoring)
				return;

			if (mutations.some(function(mutation) {
				return mutation.type === 'attributes' &&
					(mutation.attributeName === 'class' || mutation.attributeName === 'style');
			})) {
				queueMicrotask(restore);
			}
		});

		observer.observe(html, { attributes: true, attributeFilter: ['class', 'style'] });
		observer.observe(body, { attributes: true, attributeFilter: ['class', 'style'] });
		document.__linkeaseLuciStrictGlobalGuardInstalled = true;
		document.__linkeaseLuciStrictGlobalGuardObserver = observer;
	}

	function keepSingleMainMenu() {
		var mainMenu = query('#mainmenu');
		if (!mainMenu)
			return;

		var navs = Array.prototype.slice.call(mainMenu.querySelectorAll(':scope > ul.nav'));
		navs.slice(0, -1).forEach(function(node) {
			node.parentNode.removeChild(node);
		});

		if (navs.length)
			mainMenu.style.display = '';
	}

	window.__LINKEASE_LUCI_EMBED = {
		root: root,
		query: query,
		queryAll: queryAll,
		keepSingleMainMenu: keepSingleMainMenu,
		isolationMode: isolationMode
	};

	installDocumentIdScope();
	installDynamicNodeScope();
	installStrictGlobalGuard();
	document.addEventListener('luci-loaded', keepSingleMainMenu, true);
})();
