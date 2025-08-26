'use strict';
'require dom';
'require uci';
'require ui';
'require view';
'require view.xray.shared as shared';

const maxResults = 2048;

const WireType = {
    VARINT: 0,
    FIXED64: 1,
    LENGTH_DELIMITED: 2,
    FIXED32: 5
};

class ProtoReader {
    constructor(buffer) {
        this.buffer = new Uint8Array(buffer);
        this.pos = 0;
    }

    readVarint() {
        let result = 0;
        let shift = 0;

        while (this.pos < this.buffer.length) {
            const byte = this.buffer[this.pos++];
            result |= (byte & 0x7F) << shift;
            if ((byte & 0x80) === 0) {
                return result;
            }
            shift += 7;
        }
        throw new Error('Malformed varint');
    }

    readString() {
        const length = this.readVarint();
        const value = new TextDecoder().decode(
            this.buffer.slice(this.pos, this.pos + length)
        );
        this.pos += length;
        return value;
    }

    readBytes() {
        const length = this.readVarint();
        const bytes = this.buffer.slice(this.pos, this.pos + length);
        this.pos += length;
        return bytes;
    }

    readTag() {
        const tag = this.readVarint();
        return {
            fieldNumber: tag >>> 3,
            wireType: tag & 0x7
        };
    }
}

// Domain Type enum
const DomainType = {
    Plain: 0,
    Regex: 1,
    Domain: 2,
    Full: 3
};

function decodeDomainAttribute(reader) {
    const attribute = {
        key: '',
        typedValue: null
    };

    while (reader.pos < reader.buffer.length) {
        const tag = reader.readTag();

        switch (tag.fieldNumber) {
            case 1: // key
                attribute.key = reader.readString();
                break;
            case 2: // bool_value
                attribute.typedValue = reader.readVarint() !== 0;
                break;
            case 3: // int_value
                attribute.typedValue = reader.readVarint();
                break;
            default:
                throw new Error(`Unknown field number: ${tag.fieldNumber}`);
        }
    }

    return attribute;
}

function decodeDomain(reader) {
    const domain = {
        type: DomainType.Plain,
        value: '',
        attribute: []
    };

    while (reader.pos < reader.buffer.length) {
        const tag = reader.readTag();

        switch (tag.fieldNumber) {
            case 1: // type
                domain.type = reader.readVarint();
                break;
            case 2: // value
                domain.value = reader.readString();
                break;
            case 3: // attribute
                const attrBytes = reader.readBytes();
                domain.attribute.push(
                    decodeDomainAttribute(new ProtoReader(attrBytes))
                );
                break;
            default:
                throw new Error(`Unknown field number: ${tag.fieldNumber}`);
        }
    }

    return domain;
}

function decodeCIDR(reader) {
    const cidr = {
        ip: new Uint8Array(),
        prefix: 0
    };

    while (reader.pos < reader.buffer.length) {
        const tag = reader.readTag();

        switch (tag.fieldNumber) {
            case 1: // ip
                cidr.ip = reader.readBytes();
                break;
            case 2: // prefix
                cidr.prefix = reader.readVarint();
                break;
            default:
                throw new Error(`Unknown field number: ${tag.fieldNumber}`);
        }
    }

    return cidr;
}

function decodeGeoIP(reader) {
    const geoIP = {
        countryCode: '',
        cidr: [],
        reverseMatch: false
    };

    while (reader.pos < reader.buffer.length) {
        const tag = reader.readTag();

        switch (tag.fieldNumber) {
            case 1: // country_code
                geoIP.countryCode = reader.readString();
                break;
            case 2: // cidr
                const cidrBytes = reader.readBytes();
                geoIP.cidr.push(
                    decodeCIDR(new ProtoReader(cidrBytes))
                );
                break;
            case 3: // reverse_match
                geoIP.reverseMatch = reader.readVarint() !== 0;
                break;
            default:
                throw new Error(`Unknown field number: ${tag.fieldNumber}`);
        }
    }

    return geoIP;
}

function decodeGeoSite(reader) {
    const geoSite = {
        countryCode: '',
        domain: []
    };

    while (reader.pos < reader.buffer.length) {
        const tag = reader.readTag();

        switch (tag.fieldNumber) {
            case 1: // country_code
                geoSite.countryCode = reader.readString();
                break;
            case 2: // domain
                const domainBytes = reader.readBytes();
                geoSite.domain.push(
                    decodeDomain(new ProtoReader(domainBytes))
                );
                break;
            default:
                throw new Error(`Unknown field number: ${tag.fieldNumber}`);
        }
    }

    return geoSite;
}

function decodeGeoSiteList(buffer) {
    const reader = new ProtoReader(buffer);
    const geoSiteList = {
        entry: []
    };

    while (reader.pos < reader.buffer.length) {
        const tag = reader.readTag();

        if (tag.fieldNumber === 1) { // entry
            const entryBytes = reader.readBytes();
            geoSiteList.entry.push(
                decodeGeoSite(new ProtoReader(entryBytes))
            );
        } else {
            throw new Error(`Unknown field number: ${tag.fieldNumber}`);
        }
    }

    return geoSiteList;
}

function decodeGeoIPList(buffer) {
    const reader = new ProtoReader(buffer);
    const geoIPList = {
        entry: []
    };

    while (reader.pos < reader.buffer.length) {
        const tag = reader.readTag();

        if (tag.fieldNumber === 1) { // entry
            const entryBytes = reader.readBytes();
            geoIPList.entry.push(
                decodeGeoIP(new ProtoReader(entryBytes))
            );
        } else {
            throw new Error(`Unknown field number: ${tag.fieldNumber}`);
        }
    }

    return geoIPList;
}

function matchesDomain(subdomain, domain) {
    const lowerDomain = domain.toLowerCase();
    const lowerSubdomain = subdomain.toLowerCase();
    if (lowerSubdomain === lowerDomain) {
        return true;
    }
    return lowerSubdomain.endsWith('.' + lowerDomain);
}

function matchesCIDR(cidrIp, prefix, queryIp) {
    // Check if input IP matches CIDR IP version
    if ((cidrIp.length === 4 && queryIp.length !== 4) || (cidrIp.length === 16 && queryIp.length !== 16)) {
        return false;
    }

    // Compare full bytes first
    const prefixBytes = Math.floor(prefix / 8);
    for (let i = 0; i < prefixBytes; i++) {
        if (cidrIp[i] !== queryIp[i]) return false;
    }

    // Compare remaining bits if any
    const remainingBits = prefix % 8;
    if (remainingBits > 0) {
        const mask = 0xFF << (8 - remainingBits);
        return (cidrIp[prefixBytes] & mask) === (queryIp[prefixBytes] & mask);
    }

    return true;
}

function renderGeoIPResults(results) {
    const container = document.getElementById('geoip-results');
    container.innerHTML = '<br/>';

    const flatResults = results.flatMap(entry => entry.cidr.map(cidr => ({ entry, cidr })));

    const table = E('table', { 'class': 'table' }, [
        E('thead', {}, [
            E('tr', { 'class': 'tr table-titles' }, [
                E('th', { 'class': 'th' }, _('Country Code')),
                E('th', { 'class': 'th' }, _(`CIDR (${flatResults.length} total)`))
            ])
        ]),
        E('tbody', {}, flatResults.slice(0, maxResults).map(({ entry, cidr }, index) => {
            const ip = cidr.ip.length === 4 ? Array.from(cidr.ip).join('.') : Array.from(cidr.ip).reduce((arr, byte, i) => {
                if (i % 2 === 0) {
                    arr.push((byte << 8) | cidr.ip[i + 1]);
                }
                return arr;
            }, []).map(part => part.toString(16).padStart(4, '0')).join(':').replace(/\b(?:0+:){2,}/, ':').split(':').map(octet => octet.replace(/\b0+/g, '')).join(':');
            return E('tr', { 'class': `tr cbi-rowstyle-${index % 2 + 1}` }, [
                E('td', { 'class': 'td' }, entry.countryCode),
                E('td', { 'class': 'td' }, `${ip}/${cidr.prefix}`)
            ]);
        }))
    ]);

    container.appendChild(table);
}

function renderGeoSiteResults(results) {
    const container = document.getElementById('geosite-results');
    container.innerHTML = '<br/>';

    const flatResults = results.flatMap(entry => entry.domain.map(domain => ({ entry, domain })));

    const table = E('table', { 'class': 'table' }, [
        E('thead', {}, [
            E('tr', { 'class': 'tr table-titles' }, [
                E('th', { 'class': 'th' }, _('Country Code')),
                E('th', { 'class': 'th' }, _(`Domain (${flatResults.length} total)`))
            ])
        ]),
        E('tbody', {}, flatResults.slice(0, maxResults).map(({ entry, domain }, index) =>
            E('tr', { 'class': `tr cbi-rowstyle-${index % 2 + 1}` }, [
                E('td', { 'class': 'td' }, entry.countryCode),
                E('td', { 'class': 'td' }, domain.value)
            ])
        ))
    ]);

    container.appendChild(table);
}

return view.extend({
    load: function () {
        return Promise.all([
            new Date(),
            uci.load(shared.variant),
            fetch("/xray/geoip.dat").then(v => v.arrayBuffer()),
            fetch("/xray/geosite.dat").then(v => v.arrayBuffer()),
        ]);
    },

    render: function (load_result) {
        const geoip_result = decodeGeoIPList(load_result[2]);
        const geosite_result = decodeGeoSiteList(load_result[3]);
        const result = E([], {}, [
            E('div', {}, [
                E('div', { 'class': 'cbi-section', 'data-tab': 'geoip', 'data-tab-title': _('GeoIP') }, [
                    E('select', {
                        'id': 'geoip-select',
                        'change': function () {
                            const selectedCode = document.getElementById('geoip-select').value;
                            const results = selectedCode ? geoip_result.entry.filter(entry => entry.countryCode === selectedCode) : [];
                            renderGeoIPResults(results);
                        }
                    }, [
                        E('option', { 'value': '' }, _('Filter GeoIP by Country Code')),
                        ...Array.from(new Set(geoip_result.entry.map(entry => entry.countryCode)))
                            .sort()
                            .map(code => {
                                const count = geoip_result.entry
                                    .find(entry => entry.countryCode === code)
                                    .cidr.length;
                                return E('option', { 'value': code }, `${code} (${count} items)`);
                            })
                    ]),
                    E('div', { 'class': 'cbi-section-create' }, [
                        E('input', {
                            'type': 'text',
                            'id': 'geoip-search',
                            'class': 'cbi-input-text',
                            'placeholder': _('Search GeoIP...')
                        }),
                        E('button', {
                            'class': 'cbi-button',
                            'click': function () {
                                const query = document.getElementById('geoip-search').value.trim();
                                let queryIp = null;
                                if (query.includes('.')) {
                                    queryIp = query.split('.').map(Number);
                                } else if (query.includes(':')) {
                                    queryIp = query.split(':').reduce((acc, part, i, arr) => {
                                        if (part === '') {
                                            const padding = new Array((8 - arr.filter(x => x !== '').length) * 2).fill(0);
                                            return acc.concat(padding);
                                        }
                                        const hex = part.padStart(4, '0');
                                        return acc.concat([parseInt(hex.slice(0, 2), 16), parseInt(hex.slice(2, 4), 16)]);
                                    }, []);
                                    console.log(queryIp);
                                }
                                const selectedCode = document.getElementById('geoip-select').value;
                                const results = geoip_result.entry.map(entry => ({
                                    ...entry,
                                    cidr: entry.cidr.filter(cidr => {
                                        return queryIp && (selectedCode === '' || entry.countryCode === selectedCode) && matchesCIDR(cidr.ip, cidr.prefix, queryIp);
                                    })
                                })).filter(entry => entry.cidr.length > 0);
                                renderGeoIPResults(results);
                            }
                        }, _('Search GeoIP')),
                    ]),
                    E('div', { 'id': 'geoip-results', 'class': 'results-container' }),
                ]),
                E('div', { 'class': 'cbi-section', 'data-tab': 'geosite', 'data-tab-title': _('GeoSite') }, [
                    E('select', {
                        'id': 'geosite-select',
                        'change': function () {
                            const selectedCode = document.getElementById('geosite-select').value;
                            const results = selectedCode ? geosite_result.entry.filter(entry => entry.countryCode === selectedCode) : [];
                            renderGeoSiteResults(results);
                        }
                    }, [
                        E('option', { 'value': '' }, _('Filter GeoSite by Country Code')),
                        ...Array.from(new Set(geosite_result.entry.map(entry => entry.countryCode)))
                            .sort()
                            .map(code => {
                                const count = geosite_result.entry
                                    .find(entry => entry.countryCode === code)
                                    .domain.length;
                                return E('option', { 'value': code }, `${code} (${count} items)`);
                            })
                    ]),
                    E('div', { 'class': 'cbi-section-create' }, [
                        E('input', {
                            'type': 'text',
                            'id': 'geosite-search',
                            'class': 'cbi-input-text',
                            'placeholder': _('Search GeoSite...')
                        }),
                        E('button', {
                            'class': 'cbi-button',
                            'click': function () {
                                const query = document.getElementById('geosite-search').value.toLowerCase();
                                const selectedCode = document.getElementById('geosite-select').value;
                                const results = geosite_result.entry.map(entry => ({
                                    ...entry,
                                    domain: entry.domain.filter(domain => {
                                        return query && (selectedCode === '' || entry.countryCode === selectedCode) && matchesDomain(query, domain.value);
                                    })
                                })).filter(entry => entry.domain.length > 0);
                                renderGeoSiteResults(results);
                            }
                        }, _('Search GeoSite')),
                    ]),
                    E('div', { 'id': 'geosite-results', 'class': 'results-container' })
                ]),
            ])
        ]);
        ui.tabs.initTabGroup(result.lastElementChild.childNodes);

        return E([], [
            E('h2', _('Xray (geodata)')),
            E('p', { 'class': 'cbi-map-descr' }, `${_("Only first")} ${maxResults} ${_("results will be shown. Load GeoData files cost")} ${new Date().getTime() - load_result[0].getTime()} ${_("ms")}; ${geoip_result.entry.length} ${_("GeoIP entries")}, ${geosite_result.entry.length} ${_("GeoSite entries")}.`),
            result
        ]);
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
