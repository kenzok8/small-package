function selectElement(selector) {
	return new Promise(resolve => {
		const nodes = document.querySelectorAll(selector);
		if (nodes.length > 0) {
			return resolve(nodes);
		}
		const observer = new MutationObserver(mutations => {
			const nodes = document.querySelectorAll(selector);
			if (nodes.length > 0) {
				observer.disconnect();
				return resolve(nodes);
			}
		});
		observer.observe(document.body, { childList: true, subtree: true });
	});
}

function eachElement(selector, callback, scope) {
	selectElement(selector).then(elements => {
		for (let i = 0; i < elements.length; i++) {
			callback.call(scope, elements[i], i, elements);
		}
	});
}

async function updateInvertSelection(invertSelection) {
	let count = 0, selected = 0;
	await eachElement(".tr:not(:last-child) input[type=checkbox]", checkbox => {
		count++; selected += checkbox.checked ? 1 : 0;
	});
	invertSelection.checked = (selected == count);
	invertSelection.indeterminate = (selected > 0 && selected < count);
}

function toLocalTimeString(date) {
	date.setTime(date.getTime() - 60000 * date.getTimezoneOffset())
	return date.toISOString().replace("T", " ").substring(0, 19);
}

function toHumanTimeString(sec) {
	let date = new Date(sec * 1000), str = date.getSeconds() + "s";
	if (date.getUTCMinutes() > 0) { str = date.getUTCMinutes() + "m " + str; }
	if (date.getUTCHours() > 0) { str = date.getUTCHours() + "h " + str; }
	if (date.getUTCDate() > 1) { str = (date.getUTCDate() - 1) + "d " + str; }
	return str;
}

function updateNextRunTime(element, start, interval) {
	document.getElementById(element).innerHTML = "<i>updating..</i>";
	setInterval(function() {
		let now = Date.now();
		let remaining = start * 1000 > now
			? start * 1000 - now
			: (interval * 1000) - (now - start * 1000) % (interval * 1000);
		document.getElementById(element).innerHTML = toLocalTimeString(new Date(now + remaining))
			+ " (" + toHumanTimeString(Math.floor(remaining / 1000)) + " remaining)";
	}, 1000);
}
