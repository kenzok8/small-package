// SPDX-License-Identifier: GPL-3.0-only

'use strict';
'require baseclass';

function sha256(input) {
	const bytes = new Uint8Array(input);
	const bitLength = bytes.length * 8;
	const paddedLength = Math.ceil((bytes.length + 9) / 64) * 64;
	const padded = new Uint8Array(paddedLength);
	padded.set(bytes);
	padded[bytes.length] = 0x80;
	const lowBits = bitLength >>> 0;
	const highBits = Math.floor(bitLength / 0x100000000) >>> 0;
	for (let i = 0; i < 4; i++) {
		padded[paddedLength - 8 + i] = highBits >>> (24 - i * 8);
		padded[paddedLength - 4 + i] = lowBits >>> (24 - i * 8);
	}

	const constants = [
		0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
		0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
		0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
		0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
		0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
		0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
		0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
		0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
	];
	const state = [ 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19 ];
	const words = new Uint32Array(64);
	const rotateRight = function(value, count) { return (value >>> count) | (value << (32 - count)); };

	for (let offset = 0; offset < paddedLength; offset += 64) {
		for (let i = 0; i < 16; i++) {
			const at = offset + i * 4;
			words[i] = ((padded[at] << 24) | (padded[at + 1] << 16) | (padded[at + 2] << 8) | padded[at + 3]) >>> 0;
		}
		for (let i = 16; i < 64; i++) {
			const x = words[i - 15];
			const y = words[i - 2];
			const sigma0 = rotateRight(x, 7) ^ rotateRight(x, 18) ^ (x >>> 3);
			const sigma1 = rotateRight(y, 17) ^ rotateRight(y, 19) ^ (y >>> 10);
			words[i] = (words[i - 16] + sigma0 + words[i - 7] + sigma1) >>> 0;
		}

		let a = state[0], b = state[1], c = state[2], d = state[3];
		let e = state[4], f = state[5], g = state[6], h = state[7];
		for (let i = 0; i < 64; i++) {
			const sum1 = rotateRight(e, 6) ^ rotateRight(e, 11) ^ rotateRight(e, 25);
			const choice = (e & f) ^ (~e & g);
			const temp1 = (h + sum1 + choice + constants[i] + words[i]) >>> 0;
			const sum0 = rotateRight(a, 2) ^ rotateRight(a, 13) ^ rotateRight(a, 22);
			const majority = (a & b) ^ (a & c) ^ (b & c);
			const temp2 = (sum0 + majority) >>> 0;
			h = g; g = f; f = e; e = (d + temp1) >>> 0;
			d = c; c = b; b = a; a = (temp1 + temp2) >>> 0;
		}
		state[0] = (state[0] + a) >>> 0;
		state[1] = (state[1] + b) >>> 0;
		state[2] = (state[2] + c) >>> 0;
		state[3] = (state[3] + d) >>> 0;
		state[4] = (state[4] + e) >>> 0;
		state[5] = (state[5] + f) >>> 0;
		state[6] = (state[6] + g) >>> 0;
		state[7] = (state[7] + h) >>> 0;
	}

	return state.map(function(value) { return value.toString(16).padStart(8, '0'); }).join('');
}

return baseclass.extend({ sha256: sha256 });
