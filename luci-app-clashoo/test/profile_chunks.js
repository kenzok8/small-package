'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '..', 'htdocs',
  'luci-static', 'resources', 'tools', 'clashoo.js'), 'utf8');
const content = 'a'.repeat(24575) + '中文' + 'b'.repeat(524288);
const bytes = Buffer.from(content, 'utf8');
const chunkSize = 24576;
const total = Math.ceil(bytes.length / chunkSize);
let failAt = -1;
const uploads = [];

const responses = {
  get_singbox_profile: () => ({ error: 'too large' }),
  get_singbox_profile_chunk: (name, index) => {
    const i = Number(index);
    if (i === failAt) return { error: 'read_failed' };
    return {
      name, index: i, total, size: bytes.length, mtime: '1',
      content_b64: bytes.subarray(i * chunkSize, (i + 1) * chunkSize).toString('base64')
    };
  },
  save_singbox_profile_chunk: (name, chunk, index, total) => {
    uploads.push(chunk);
    return { success: true, name, index: Number(index), total: Number(total) };
  }
};
const rpc = { declare: ({ method }) => (...args) => Promise.resolve(responses[method](...args)) };
const baseclass = { extend: (value) => value };
const ui = { _clashooPatched: true };
const document = { getElementById: () => ({}) };
const L = { resolveDefault: (promise, fallback) => Promise.resolve(promise).catch(() => fallback) };
const clashoo = new Function('baseclass', 'rpc', 'ui', 'document', 'L', '_', 'atob',
  'TextDecoder', source)(baseclass, rpc, ui, document, L, (s) => s, atob, TextDecoder);

(async () => {
  const loaded = await clashoo.getSingboxProfile('large.json');
  assert.equal(loaded.content, content, 'large UTF-8 profile must survive chunk boundaries');

  failAt = 1;
  const failed = await clashoo.getSingboxProfile('large.json');
  assert.equal(failed.error, 'read_failed', 'a failed chunk must fail the entire read');
  assert.equal(failed.content, undefined, 'a failed read must not become an empty profile');
  const edited = 'a'.repeat(24575) + '😀' + 'b'.repeat(524288);
  const saved = await clashoo.saveSingboxProfile('large.json', edited);
  assert.equal(saved.success, true);
  assert.equal(uploads.join(''), edited, 'saving must preserve a Unicode character at a chunk boundary');
  assert.ok(uploads.every((chunk) => !/[\uD800-\uDBFF]$/.test(chunk)),
    'an upload chunk must not end with half of a Unicode character');
  process.stdout.write('sing-box profile chunk tests passed\n');
})().catch((error) => {
  process.stderr.write(String(error) + '\n');
  process.exitCode = 1;
});
