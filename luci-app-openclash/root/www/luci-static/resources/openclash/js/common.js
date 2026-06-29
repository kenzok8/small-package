/**
 * OpenClash Common JavaScript Utilities
 * Shared functions used across multiple view templates.
 */

/**
 * Detects if an element has a dark background by analyzing its computed CSS.
 * Used by CodeMirror log editor to set dark mode attribute.
 * @param {HTMLElement} element - The element to check
 * @returns {boolean} True if the background is dark
 */
function isDarkBackground(element) {
	var cachedTheme = localStorage.getItem('oc-theme');
	if (cachedTheme === 'dark') {
		return true;
	} else if (cachedTheme === 'light') {
		return false;
	}

	if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
		return true;
	}

	var style = window.getComputedStyle(element);
	var bgColor = style.backgroundColor;
	var r, g, b;
	if (/rgb\(/.test(bgColor)) {
		var rgb = bgColor.match(/\d+/g);
		r = parseInt(rgb[0]);
		g = parseInt(rgb[1]);
		b = parseInt(rgb[2]);
	} else if (/#/.test(bgColor)) {
		if (bgColor.length === 4) {
			r = parseInt(bgColor[1] + bgColor[1], 16);
			g = parseInt(bgColor[2] + bgColor[2], 16);
			b = parseInt(bgColor[3] + bgColor[3], 16);
		} else {
			r = parseInt(bgColor.slice(1, 3), 16);
			g = parseInt(bgColor.slice(3, 5), 16);
			b = parseInt(bgColor.slice(5, 7), 16);
		}
	} else {
		return false;
	}
	var luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;
	return luminance < 128;
}

/**
 * Opens a URL in a new window. Used for external links (Wiki, GitHub, etc.).
 * @param {string} url - The URL to open
 * @returns {boolean} false to prevent default link behavior
 */
function winOpen(url) {
	var win = window.open(url);
	if (win == null || typeof(win) == 'undefined') {
		window.location.href = url;
	}
	return false;
}
