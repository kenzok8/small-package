function readdata(source, callback) {
	var xmlhttp;
	try {xmlhttp = new XMLHttpRequest();} catch (e) {
		try {xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");} catch (e) {
			try {xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");} catch (e) {
				alert("Old browser?");
				return false;
			}
		}
	}
	xmlhttp.open("GET", "/cgi-bin/" + source);
	xmlhttp.onreadystatechange = function() {
		if (xmlhttp.readyState == 4) {
			if(xmlhttp.status == 200) {
				callback(JSON.parse(xmlhttp.responseText));
			}
		}
	}
	xmlhttp.send(null);
}

function translate() {
	var lang = navigator.languages ? navigator.languages[0] : navigator.language;
	this._lang = lang.substr(0, 2);
//	this._lang = 'en';

	fetch(`/i18n/${this._lang}.json`)
		.then((response) => {
			if (response.ok) {
				return response.json();
			}
			throw new Error('Something went wrong');
		})
		.then((translation) => {
			this._translation = translation;
			this._elements = document.querySelectorAll("[data-i18n]");
			this._elements.forEach((element) => {
				var keys = element.dataset.i18n.split(".");
				var text = keys.reduce((obj, i) => obj[i], translation);
				if (text) {
					element.innerHTML = text;
				}
			});
		})
		.catch((error) => {
			console.log(`Could not load ${this._lang}, en will be used`);
		});
}

function _t(text, defaulttext) {
	if (this._translation) {
		var key = text.replaceAll(' ', '').toLowerCase();
		if (key in this._translation) {
			return this._translation[key];
		}
	}
	return defaulttext ? defaulttext : text;
}

function info_onload() {
	translate();
	showmodeminfo();
}

function formatDateTime(s) {
	if (s.length == 14) {
		return s.replace(/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/, "$1-$2-$3 $4:$5:$6");
	} else if (s.length == 12) {
		return s.replace(/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})/, "$1-$2-$3 $4:$5");
	} else if (s.length == 8) {
		return s.replace(/(\d{4})(\d{2})(\d{2})/, "$1-$2-$3");
	} else if (s.length == 6) {
		return s.replace(/(\d{4})(\d{2})/, "$1-$2");
	}
	return s;
}

function lz(n) {
	return (n < 10 ? '0' : '' ) + n;
}

function formatDateTimeForUptime(uptime) {
	var d = new Date(new Date().getTime() - uptime * 1000);
	return '' +
		d.getFullYear() + '-' +
		lz(d.getMonth() + 1) + '-' +
		lz(d.getDate()) + ' ' +
		lz(d.getHours()) + ':' +
		lz(d.getMinutes()) + ':' +
		lz(d.getSeconds());
}

function createRowForModal(key, value) {
	return '<div class="row"><div class="col-xs-5 col-sm-6 text-right">' + key + '</div><div class="col-xs-7 col-sm-6 text-left"><p>' + value + '</p></div></div>';
}

function createRow9ColForModal(arr) {
	return '<div class="row">' +
		'<div class="col-xs-1 text-right"><p>' + arr[0] + '</p></div>' +
		'<div class="col-xs-3 text-left"><p>' + arr[1] + '</p></div>' +
		'<div class="col-xs-2 text-left"><p>' + arr[2] + '</p></div>' +
		'<div class="col-xs-1 text-left"><p>' + arr[3] + '</p></div>' +
		'<div class="col-xs-1 text-left"><p>' + arr[4] + '</p></div>' +
		'<div class="col-xs-1 text-left"><p>' + arr[5] + '</p></div>' +
		'<div class="col-xs-1 text-left"><p>' + arr[6] + '</p></div>' +
		'<div class="col-xs-1 text-left"><p>' + arr[7] + '</p></div>' +
		'<div class="col-xs-1 text-left"><p>' + arr[8] + '</p></div>' +
		'</div>';
}

/*****************************************************************************/

var modal;

function setValue(element, value) {
	var e = document.getElementById(element);
	if (e.tagName == "SELECT") {
		for (var i = 0; i < e.options.length; i++) {
			if (e.options[i].value == value) {
				e.selectedIndex = i;
				break;
			}
		}
	} else if (e.tagName == "P") {
		e.innerHTML = value;
	} else if (e.tagName == "H3") {
		e.innerHTML = value;
	} else if (e.tagName == "SPAN") {
		e.innerHTML = value;
	} else if (e.tagName == "DIV") {
		e.innerHTML = value;
	} else if (e.type === 'checkbox') {
		e.checked = value;
	} else if (e.type === 'radio') {
		e.checked = value;
	} else {
		e.value = value;
	}
}

function setDisplay(element, show) {
	document.getElementById(element).style.display = (show ? 'block' : 'none');
}

function addClasses(element, classes) {
	for (var i = 0; i < classes.length; i++) {
		if (!element.className.match(new RegExp('(?:^|\\s)' + classes[i] + '(?!\\S)', 'g')))
			element.className += " " + classes[i];
	}
}

function removeClasses(element, classes) {
	for (var i = 0; i < classes.length; i++) {
		element.className = element.className.replace(new RegExp('(?:^|\\s)' + classes[i] + '(?!\\S)', 'g'), '');
	}
}

function showMsg(msg, error) {
	closeMsg();

	if (!msg || 0 === msg.length) { msg = _t('Please wait') + '...'; }
	var e = document.getElementById('msgtxt');
	e.innerHTML = msg;

	if (error) {
		e.style.color = 'red';
		addClasses(e, ['has-error']);
	} else {
		e.style.color = null;
		removeClasses(e, ['has-error']);
	}

	modal = document.getElementById('div_msg');
	modal.style.display = 'block';

	window.onclick = function(event) {
		if (event.target == modal) {
			modal.style.display = 'none';
		}
	    }
}

function closeMsg() {
	if (modal) { modal.style.display = 'none'; }
}

function sortJSON(data, key, way) {
	return data.sort(function(a, b) {
		var x = a[key]; var y = b[key];
		if (way === 'asc' ) { return ((x < y) ? -1 : ((x > y) ? 1 : 0)); }
		if (way === 'desc') { return ((x > y) ? -1 : ((x < y) ? 1 : 0)); }
	});
}

function formatDuration(s, showsec) {
	if (s === '-') {return '-';}
	if (s === '') {return '-';}
	var d = Math.floor(s/86400),
		h = Math.floor(s/3600) % 24,
		m = Math.floor(s/60)%60,
		s = s % 60;
	var time = d > 0 ? d + 'd ' : '';
	if (time != '') {time += h + _t('h') + ' '} else {time = h > 0 ? h + _t('h') + ' ' : ''}
	if (time != '') {time += m + 'm '} else {time = m > 0 ? m + 'm ' : ''}
	if (showsec) {
		time += s + 's';
	} else {
		if (time == '') { time += m + 'm'; }
	}
	return time;
}

/*****************************************************************************/

function modem(evt, modem) {
	var i, tabcontent, tablinks;
	tabcontent = document.getElementsByClassName("tabcontent");
	for (i = 0; i < tabcontent.length; i++) {
		tabcontent[i].style.display = "none";
	}
	tablinks = document.getElementsByClassName("tablinks");
	for (i = 0; i < tablinks.length; i++) {
		tablinks[i].className = tablinks[i].className.replace(" active", "");
	}
	document.getElementById(modem).style.display = "block";
	evt.currentTarget.className += " active";
}

function showmodeminfo() {
	readdata('infoproducts.sh', function(data1) {
		var html = '';
		if (data1.res.length > 1) {
			var htmltab = '<div class="tab">';
			(data1.res).forEach(function callback(value, idx) {
				var id = (idx == 0 ? 'id="defaultOpen"' : '');
				htmltab += '<button class="tablinks" onclick="modem(event, \'modem' + idx + '\')"' + id + '><span id="tabtitle' + idx + '"></span></button>';
				html += ('<div id="modem' + idx + '" class="tabcontent">' + document.getElementById('div_template').innerHTML + '</div>').replaceAll('_idx', idx);
			});
			htmltab += '</div>';
			setValue('div_modems', '');
			document.getElementById('div_modems').insertAdjacentHTML('beforeend', htmltab + html);

			document.getElementById("defaultOpen").click();
		} else {
			setValue('div_modems', '');
			html += ('<div id="modem0">' + document.getElementById('div_template').innerHTML + '</div>').replaceAll('_idx', 0);
			document.getElementById('div_modems').insertAdjacentHTML('beforeend', html);
		}

		(data1.res).forEach(function callback(data, idx) {
			setValue('vendor' + idx, data.vendor == '' ? '-' : data.vendor);
			setValue('product' + idx, data.product == '' ? '-' : data.product);
			if (data1.res.length > 1) {
				setValue('tabtitle' + idx, data.product == '' ? 'modem #' + (idx + 1) : data.product);
			}
			setValue('revision' + idx, data.revision == '' ? '-' : data.revision);
			setValue('imei' + idx, data.imei == '' ? '-' : data.imei);
			setValue('iccid' + idx, data.iccid == '' ? '-' : data.iccid);
			setValue('imsi' + idx, data.imsi == '' ? '-' : data.imsi);
		});

		showmodemparams();
		setInterval(showmodemparams, 10000);
	});
}

var arrmodemaddon = [];

function showmodemparams() {
	readdata('info.sh', function(data1) {

		(data1.res).forEach(function callback(data2, idx) {
			var data = data2[0];
			setValue('rx' + idx, data.rx == '' ? '-' : data.rx);
			setValue('tx' + idx, data.tx == '' ? '-' : data.tx);
			setValue('uptime' + idx, formatDuration(data.conn_time_sec, false));
			setValue('uptime_since' + idx, ' (' + _t('since') + ' ' + formatDateTimeForUptime(data.conn_time_sec) + ')');

			var data = data2[1];
			if (data.error)
				return;

			arrmodemaddon[idx] = [];

			switch(data.registration) {
				case "0":
					setValue('registration' + idx, _t('registered0', 'Not registered'));
					break;
				case "1":
					setValue('registration' + idx, _t('registered1', 'Registered, home network'));
					break;
				case "2":
					setValue('registration' + idx, _t('registered2', 'Not registered, searching'));
					break;
				case "3":
					setValue('registration' + idx, _t('registered3', 'Registration denied'));
					break;
				case "5":
					setValue('registration' + idx, _t('registered5', 'Registered, roaming'));
					break;
				case "6":
					setValue('registration' + idx, _t('registered6', 'Registered for SMS only, home network'));
					break;
				case "7":
					setValue('registration' + idx, _t('registered7', 'Registered for SMS only, roaming'));
					break;
				default:
					setValue('registration' + idx, data.registration == '' ? '-' : data.registration);
			}

			if (data.registration == '1' || data.registration == '5' || data.registration == '6' || data.registration == '7') {
				setValue('signal' + idx, data.signal == '' ? '-' : data.signal + '%');

				if (data.signal) {
					var e = document.getElementById('signal_bars' + idx);
					removeClasses(e, ['lzero', 'lone', 'ltwo', 'lthree', 'lfour', 'lfive', 'one-bar', 'two-bars', 'three-bars', 'four-bars', 'five-bars']);
					if (data.signal >= 80) {
						addClasses(e, ['lfive', 'five-bars']);
					}
					if (data.signal < 80 && data.signal >= 60) {
						addClasses(e, ['lfour', 'four-bars']);
					}
					if (data.signal < 60 && data.signal >= 40) {
						addClasses(e, ['lthree', 'three-bars']);
					}
					if (data.signal < 40 && data.signal >= 20) {
						addClasses(e, ['ltwo', 'two-bars']);
					}
					if (data.signal < 20 && data.signal > 0) {
						addClasses(e, ['lone', 'one-bar']);
					}
					if (data.signal == 0) {
						addClasses(e, ['lzero', 'one-bar']);
					}
				}

				setValue('operator' + idx, data.operator_name == '' ? '-' : data.operator_name);
				var mode = (data.mode == '' ? '-' : data.mode);
				if (mode.toLowerCase().includes('lte') || mode.toLowerCase().includes('5g')) {
					if (mode.toLowerCase().includes('lte')) {
						mode = (data.mode).split(' ')[0];
					}
					if (mode.toLowerCase().includes('5g')) {
						mode = (data.mode).split(' ')[0] + ' ' + (data.mode).split(' ')[1];
					}
					var count = ((data.mode).match(/\//g) || []).length;
					if (count > 0) {
						mode += ' (' + (count + 1) + 'CA)';
					}
				}
				setValue('mode' + idx, mode);

				arrmodemaddon[idx].push({'idx':1, 'key':'Mode', 'value':data.mode});
				if (data.country) {
					arrmodemaddon[idx].push({'idx':19, 'key':'Country', 'value':data.country});
				}
				if (data.operator_mcc && data.operator_mcc != '' && data.operator_mnc && data.operator_mnc != '') {
					arrmodemaddon[idx].push({'idx':20, 'key':'MCC MNC', 'value':data.operator_mcc + ' ' + data.operator_mnc});
				}
				if (data.lac_dec && data.lac_dec > 0) {
					arrmodemaddon[idx].push({'idx':22, 'key':'LAC', 'value':data.lac_dec + ' (' + data.lac_hex + ')'});
				}
				if (data.cid_dec && data.cid_dec > 0) {
					arrmodemaddon[idx].push({'idx':21, 'key':'Cell ID', 'value':data.cid_dec + ' (' + data.cid_hex + ')'});
				}

				if (data.cid_dec && data.cid_dec > 0 && data.operator_mcc == 260) {
					document.getElementById('btsearch' + idx).setAttribute("href", "http://www.btsearch.pl/szukaj.php?search=" + data.cid_dec + "&siec=-1&mode=std");
					setDisplay('div_btsearch' + idx, true);
				} else {
					setDisplay('div_btsearch' + idx, false);
				}
			} else {
				setValue('signal' + idx, '-');
				var e = document.getElementById('signal_bars' + idx);
				removeClasses(e, ['lzero', 'lone', 'ltwo', 'lthree', 'lfour', 'lfive', 'one-bar', 'two-bars', 'three-bars', 'four-bars', 'five-bars']);
				addClasses(e, ['lzero', 'one-bar']);
				setValue('operator' + idx, '-');
				setValue('mode' + idx, '-');
				setDisplay('div_btsearch' + idx, false);
			}
			if (data.addon) {
				arrmodemaddon[idx] = arrmodemaddon[idx].concat(data.addon);
			}
			setDisplay('div_addon' + idx, (arrmodemaddon[idx]).length > 0);
		});
	});
}

function paramdesc(param, value) {
	var pvalue = parseInt(value.split(' ')[0]);
	var description = '';
	var color = '';
	var title = '';
	switch(param) {
		case 'rssi':
			if (pvalue > -65) { color = '#2bdf5a'; description += _t('excellent'); }
			if (pvalue > -75 && pvalue <= -65 ) { color = '#efff12'; description += _t('good'); }
			if (pvalue > -85 && pvalue <= -75 ) { color = '#f8c200'; description += _t('fair'); }
			if (pvalue > -95 && pvalue <= -85 ) { color = '#fa0000'; description += _t('poor'); }
			if (pvalue <= -95) { color = '#fa0000'; description += _t('very poor'); }
			title += '> -65 dBm ' + _t('excellent') + '\n';
			title += '> -75 dBm i <= -65 dBm ' + _t('good') + '\n';
			title += '> -85 dBm i <= -75 dBm ' + _t('fair') + '\n';
			title += '> -95 dBm i <= -85 dBm ' + _t('poor') + '\n';
			title += '<= -95 dBm ' + _t('very poor');
			break;
		case 'rsrp':
			if (pvalue >= -80) { color = '#2bdf5a'; description += _t('excellent'); }
			if (pvalue >= -90 && pvalue < -80 ) { color = '#efff12'; description += _t('good'); }
			if (pvalue >= -100 && pvalue < -90 ) { color = '#f8c200'; description += _t('fair'); }
			if (pvalue < -100) { color = '#fa0000'; description += _t('poor'); }
			title += '> -80 dBm ' + _t('excellent') + '\n';
			title += '>= -90 dBm i < -80 dBm ' + _t('good') + '\n';
			title += '>= -100 dBm i < -90 dBm ' + _t('fair') + '\n';
			title += '< -100 dBm ' + _t('poor');
			break;
		case 'rsrq':
			if (pvalue >= -10) { color = '#2bdf5a'; description += _t('excellent'); }
			if (pvalue >= -15 && pvalue < -10 ) { color = '#efff12'; description += _t('good'); }
			if (pvalue >= -20 && pvalue < -15 ) { color = '#f8c200'; description += _t('fair'); }
			if (pvalue < -20) { color = '#fa0000'; description += _t('poor'); }
			title += '>= -10 dB ' + _t('excellent') + '\n';
			title += '>= -15 dB i < -10 dB ' + _t('good') + '\n';
			title += '>= -20 dB i < -15 dB ' + _t('fair') + '\n';
			title += '< -20 dB ' + _t('poor');
			break;
	}
	return ', <span style="color:' + color + '" title="' + title + '">' + description + '</span>';
}

function modemaddon(idx) {
	var htmlco = '';
	var htmlxs = '';
	var html = '';
	var pcc = [];
	var scc1 = [];
	var scc2 = [];
	var scc3 = [];
	var scc4 = [];
	var ulscc = [];
	var sorted = sortJSON(arrmodemaddon[idx], 'idx', 'asc');
	sorted.forEach(function(e) {
		var description = '';
		switch (e.idx) {
			// MODE
			case 1:
				if ((e.value).search(/^LTE B/) > -1 || (e.value).search(/^LTE_A B/) > -1) {
					pcc[1] = (e.value).replace(/^LTE /, '').replace(/^LTE_A /, '');
				}
				if ((e.value).search(/^5G/) > -1) {
					pcc[1] = (e.value).replace(/^5G NSA /, '').replace(/^5G SA /, '');
				}
				break;
			// PCC
			case 30:
				if ((e.value).includes(' @')) {
					pcc[1] = (e.value).split(' @')[0];
					pcc[2] = (e.value).split(' @')[1];
				} else {
					pcc[1] = e.value;
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 31:
				pcc[2] = e.value;
				htmlxs += createRowForModal(e.key, e.value);
				break;
			case 32:
				if (typeof pcc[2] === 'undefined') {
					pcc[2] = e.value;
				} else {
					pcc[2] = e.value + ' DL<br>' + pcc[2] + ' UL'
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 33:
				pcc[3] = e.value;
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 34:
				if ((e.key).toLowerCase().includes('earfcn ul')) {
					if (typeof pcc[4] === 'undefined') {
						pcc[4] = e.value + ' UL';
					} else {
						pcc[4] = pcc[4] + ' DL<br>' + e.value + ' UL';
					}
				} else {
					if (typeof pcc[4] === 'undefined') {
						pcc[4] = e.value;
					} else {
						pcc[4] = e.value + ' DL<br>' + pcc[4];
					}
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 35:
				description = paramdesc('rssi', e.value);
				pcc[5] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 36:
				description = paramdesc('rsrp', e.value);
				pcc[6] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 37:
				description = paramdesc('rsrq', e.value);
				pcc[7] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 38:
				if ((e.key).toLowerCase().includes('sinr')) {
					pcc[8] = e.value;
				} else {
					html += createRowForModal(_t(e.key), e.value);
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			// SCC1
			case 50:
				if ((e.value).includes(' @')) {
					scc1[1] = (e.value).split(' @')[0];
					scc1[2] = (e.value).split(' @')[1];
				} else {
					scc1[1] = e.value;
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 52:
				scc1[2] = e.value;
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 53:
				scc1[3] = e.value;
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 54:
				if (!(e.key).toLowerCase().includes('earfcn ul')) {
					scc1[4] = e.value;
				} else {
					html += createRowForModal(_t(e.key), e.value);
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 55:
				description = paramdesc('rssi', e.value);
				scc1[5] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 56:
				description = paramdesc('rsrp', e.value);
				scc1[6] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 57:
				description = paramdesc('rsrq', e.value);
				scc1[7] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 58:
				if ((e.key).toLowerCase().includes('sinr')) {
					scc1[8] = e.value;
				} else {
					html += createRowForModal(e.key, e.value);
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			// SCC2
			case 60:
				if ((e.value).includes(' @')) {
					scc2[1] = (e.value).split(' @')[0];
					scc2[2] = (e.value).split(' @')[1];
				} else {
					scc2[1] = e.value;
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 62:
				scc2[2] = e.value;
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 63:
				scc2[3] = e.value;
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 64:
				if (!(e.key).toLowerCase().includes('earfcn ul')) {
					scc2[4] = e.value;
				} else {
					html += createRowForModal(_t(e.key), e.value);
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 65:
				description = paramdesc('rssi', e.value);
				scc2[5] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 66:
				description = paramdesc('rsrp', e.value);
				scc2[6] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 67:
				description = paramdesc('rsrq', e.value);
				scc2[7] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 68:
				if ((e.key).toLowerCase().includes('sinr')) {
					scc2[8] = e.value;
				} else {
					html += createRowForModal(_t(e.key), e.value);
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			// SCC3
			case 70:
				if ((e.value).includes(' @')) {
					scc3[1] = (e.value).split(' @')[0];
					scc3[2] = (e.value).split(' @')[1];
				} else {
					scc3[1] = e.value;
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 72:
				scc3[2] = e.value;
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 73:
				scc3[3] = e.value;
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 74:
				if (!(e.key).toLowerCase().includes('earfcn ul')) {
					scc3[4] = e.value;
				} else {
					html += createRowForModal(e.key, e.value);
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 75:
				description = paramdesc('rssi', e.value);
				scc3[5] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 76:
				description = paramdesc('rsrp', e.value);
				scc3[6] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 77:
				description = paramdesc('rsrq', e.value);
				scc3[7] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 78:
				if ((e.key).toLowerCase().includes('sinr')) {
					scc3[8] = e.value;
				} else {
					html += createRowForModal(_t(e.key), e.value);
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			// SCC4
			case 80:
				if ((e.value).includes(' @')) {
					scc4[1] = (e.value).split(' @')[0];
					scc4[2] = (e.value).split(' @')[1];
				} else {
					scc4[1] = e.value;
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 82:
				scc4[2] = e.value;
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 83:
				scc4[3] = e.value;
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 84:
				if (!(e.key).toLowerCase().includes('earfcn ul')) {
					scc4[4] = e.value;
				} else {
					html += createRowForModal(_t(e.key), e.value);
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 85:
				description = paramdesc('rssi', e.value);
				scc4[5] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 86:
				description = paramdesc('rsrp', e.value);
				scc4[6] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 87:
				description = paramdesc('rsrq', e.value);
				scc4[7] = e.value + description.replace(', ', '<br>');
				htmlxs += createRowForModal(_t(e.key), e.value + description);
				break;
			case 88:
				if ((e.key).toLowerCase().includes('sinr')) {
					scc4[8] = e.value;
				} else {
					html += createRowForModal(_t(e.key), e.value);
				}
				htmlxs += createRowForModal(_t(e.key), e.value);
				break;
			case 150:
				ulscc[1] = e.value;
				htmlxs += createRowForModal(e.key, e.value);
				break;
			case 152:
				ulscc[2] = e.value;
				htmlxs += createRowForModal(e.key, e.value);
				break;
			case 153:
				ulscc[3] = e.value;
				htmlxs += createRowForModal(e.key, e.value);
				break;
			case 154:
				ulscc[4] = e.value;
				htmlxs += createRowForModal(e.key, e.value);
				break;
			default:
				if (e.idx < 30) {
					htmlco += createRowForModal(_t(e.key), e.value);
				} else {
					html += createRowForModal(_t(e.key), e.value);
					htmlxs += createRowForModal(_t(e.key), e.value);
				}
		}
	});
	htmlco += '<div class="visible-xs-block visible-sm-block">' + htmlxs + '</div>';
	if (pcc.length + scc1.length + scc2.length + scc3.length + scc4.length > 0) {
		htmlco += '<div class="margintop hidden-xs hidden-sm">' + html;
		if (pcc.length > 0) {
			pcc[0] = 'PCC';
			for (var idx = 0; idx <= 9; idx++) {
				if (typeof pcc[idx] === 'undefined') { pcc[idx] = '-'; }
			}
			htmlco += createRow9ColForModal(['', _t('Band'), _t('Bandwidth'), 'PCI', 'EARFCN', 'RSSI', 'RSRP', 'RSRQ', 'SINR']);
			htmlco += createRow9ColForModal(pcc);
		}
		if (scc1.length > 0) {
			scc1[0] = 'SCC1';
			for (var idx = 0; idx <= 9; idx++) {
				if (typeof scc1[idx] === 'undefined') { scc1[idx] = '-'; }
			}
			htmlco += createRow9ColForModal(scc1);
		}
		if (scc2.length > 0) {
			scc2[0] = 'SCC2';
			for (var idx = 0; idx <= 9; idx++) {
				if (typeof scc2[idx] === 'undefined') { scc2[idx] = '-'; }
			}
			htmlco += createRow9ColForModal(scc2);
		}
		if (scc3.length > 0) {
			scc3[0] = 'SCC3';
			for (var idx = 0; idx <= 9; idx++) {
				if (typeof scc3[idx] === 'undefined') { scc3[idx] = '-'; }
			}
			htmlco += createRow9ColForModal(scc3);
		}
		if (scc4.length > 0) {
			scc4[0] = 'SCC4';
			for (var idx = 0; idx <= 9; idx++) {
				if (typeof scc4[idx] === 'undefined') { scc4[idx] = '-'; }
			}
			htmlco += createRow9ColForModal(scc4);
		}
		if (ulscc.length > 0) {
			ulscc[0] = 'UL SCC';
			for (var idx = 0; idx <= 9; idx++) {
				if (typeof ulscc[idx] === 'undefined') { ulscc[idx] = '-'; }
			}
			htmlco += createRow9ColForModal(ulscc);
		}
		htmlco += '</div>';
	}
	showMsg(htmlco);
}

/*****************************************************************************/

window.onload = info_onload;
