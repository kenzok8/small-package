function arraysEqual(a, b) {
	if (a === b) return true;
	if (a == null || b == null) return false;
	if (a.length !== b.length) return false;
	for (let i = 0; i < a.length; i++) {
		if (a[i] !== b[i]) return false;
	}
	return true;
}

function waitForElement(selector, callback) {
	const el = document.querySelector(selector);
	if (el) return callback(el);
	const observer = new MutationObserver(() => {
		const el = document.querySelector(selector);
		if (el) {
			observer.disconnect();
			callback(el);
		}
	});
	observer.observe(document.body, { childList: true, subtree: true });
}

function get_current_url() {
	return window.location.origin + window.location.pathname;
}

function getOption(config, section, opt) {
	let obj;
	const id = `cbid.${config}.${section}.${opt}`;
	obj = document.getElementsByName(id)[0] || document.getElementById(id);
	if (obj) {
		const combobox = document.getElementById('cbi.combobox.' + id);
		if (combobox) {
			obj.combobox = combobox;
		}
		const div = document.getElementById(id);
		if (div && div.getElementsByTagName("li").length > 0) {
			obj = div;
		}
		return obj;
	} else {
		return null;
	}
}
