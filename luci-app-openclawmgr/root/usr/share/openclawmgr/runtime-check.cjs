'use strict';

// Run with the candidate Node, never with the host's default Node.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { createRequire } = require('node:module');
const { pathToFileURL } = require('node:url');
const [mode, ...args] = process.argv.slice(2);
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const write = (file, value) => fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n', { mode: 0o600 });
const assert = (ok, message) => { if (!ok) throw new Error(message); };
const sharedSdk = () => process.env.ISTORE_RUNTIME_STORAGE && process.env.ISTORE_RUNTIME_ID
  ? path.join(process.env.ISTORE_RUNTIME_STORAGE, 'environments', process.env.ISTORE_RUNTIME_ID) : null;
const semver = npm => createRequire(sharedSdk()
  ? path.join(sharedSdk(), 'lib/node_modules/npm/bin/npm-cli.js') : fs.realpathSync(npm))('semver');
async function digestFile(file, algorithm) {
  const hash = crypto.createHash(algorithm);
  for await (const chunk of fs.createReadStream(file)) hash.update(chunk);
  return hash;
}

async function main() {
  if (mode === 'node') {
    const [major, minor] = process.versions.node.split('.').map(Number);
    assert(!process.versions.node.includes('-') && ((major === 24 && minor >= 16) ||
      (major === 26 && minor >= 1) || major > 26), `Unsupported Node ${process.versions.node}`);
    assert(process.platform === 'linux' && process.arch === args[0], 'Node platform/architecture mismatch');
    if (args[1]) {
      const glibc = Boolean(process.report.getReport().header.glibcVersionRuntime);
      assert(glibc === (args[1] === 'glibc'), 'Node libc mismatch');
    }
    const { DatabaseSync } = require('node:sqlite');
    const db = new DatabaseSync(':memory:');
    try {
      const version = db.prepare('select sqlite_version() v').get().v;
      const [a, b, c] = version.split('.').map(Number);
      assert(a > 3 || (a === 3 && (b > 51 || (b === 51 && c >= 3) ||
        (b === 50 && c >= 7) || (b === 44 && c >= 6))), `Unsafe linked SQLite ${version}`);
      const value = 'a\0b\0';
      const row = db.prepare('select ? text, ? blob, json_extract(?, \'$.v\') json').get(
        value, Buffer.from(value), JSON.stringify({ v: value }));
      assert(row.text === value && Buffer.from(row.blob).equals(Buffer.from(value)) && row.json === value,
        'node:sqlite TEXT/BLOB/JSON round trip failed');
    } finally { db.close(); }
    console.log(process.versions.node);
  } else if (mode === 'metadata') {
    const [input, npm, output] = args;
    const meta = read(input);
    assert(typeof meta.version === 'string' && /^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/.test(meta.version), 'Invalid package version');
    assert(meta.name === 'openclaw' && typeof meta.engines?.node === 'string', 'Missing OpenClaw engines');
    if (!semver(npm).satisfies(process.versions.node, meta.engines.node)) {
      const error = new Error(`Node ${process.versions.node} does not satisfy ${meta.engines.node}`);
      error.exitCode = 61;
      throw error;
    }
    assert(/^sha512-[A-Za-z0-9+/]+={0,2}$/.test(meta.dist?.integrity || ''), 'Missing SHA512 package integrity');
    write(output, { version: meta.version, engines: meta.engines.node, integrity: meta.dist.integrity,
      node: process.versions.node, platform: process.platform, arch: process.arch });
    console.log(meta.version);
  } else if (mode === 'pack') {
    const [metadata, packResult, directory] = args;
    const meta = read(metadata), result = read(packResult);
    assert(Array.isArray(result) && result.length === 1, 'Invalid npm pack result');
    const item = result[0];
    assert(item.name === 'openclaw' && item.version === meta.version && item.integrity === meta.integrity,
      'npm package identity/integrity changed after resolution');
    assert(item.filename === `openclaw-${meta.version}.tgz`, 'Unexpected package filename');
    const tarball = path.join(directory, item.filename);
    const digest = 'sha512-' + (await digestFile(tarball, 'sha512')).digest('base64');
    assert(digest === meta.integrity, 'Downloaded npm tarball integrity mismatch');
    console.log(tarball);
  } else if (mode === 'native') {
    const [globalDir, metadata] = args;
    const pkgPath = path.join(globalDir, 'lib/node_modules/openclaw/package.json');
    const pkg = read(pkgPath), meta = read(metadata), load = createRequire(pkgPath);
    const checks = { uid: process.getuid?.(), gid: process.getgid?.(), groups: process.getgroups?.(),
      user: process.env.USER, home: process.env.HOME };
    assert(pkg.name === 'openclaw' && pkg.version === meta.version, 'Installed package version mismatch');
    // These required modules are used by the gateway. Optional integrations are
    // not silently promoted to requirements for every router.
    if (pkg.dependencies?.sharp) {
      await load('sharp')({ create: { width: 1, height: 1, channels: 3, background: '#000' } }).png().toBuffer();
      checks.sharp = { available: true };
    }
    if (pkg.dependencies?.['sqlite-vec']) {
      const { DatabaseSync } = require('node:sqlite');
      const db = new DatabaseSync(':memory:', { allowExtension: true });
      try {
        const sdkExport = './plugin-sdk/memory-core-host-engine-storage';
        let loader = 'sqlite-vec';
        if (pkg.exports?.[sdkExport]) {
          const host = await import(pathToFileURL(load.resolve('openclaw' + sdkExport.slice(1))).href);
          const result = await host.loadSqliteVecExtension({ db });
          assert(result?.ok, `OpenClaw vector loader failed: ${result?.error || 'unknown error'}`);
          loader = 'openclaw-memory-host';
        } else load('sqlite-vec').load(db);
        db.prepare('select vec_version()').get();
        db.exec('CREATE VIRTUAL TABLE vec_probe USING vec0(embedding float[2])');
        const insert = db.prepare('INSERT INTO vec_probe(rowid, embedding) VALUES (?, ?)');
        insert.run(1n, '[1,0]'); insert.run(2n, '[0,1]');
        const hit = db.prepare('SELECT rowid, distance FROM vec_probe WHERE embedding MATCH ? AND k = 1').get('[0.9,0.1]');
        assert(hit?.rowid === 1 && Number.isFinite(hit.distance), 'sqlite-vec nearest-neighbor query failed');
        checks.sqliteVec = { available: true, loader, version: db.prepare('select vec_version() v').get().v, nearestNeighbor: true };
      } finally { db.close(); }
    }
    if (pkg.dependencies?.['@lydell/node-pty']) {
      try {
        load('@lydell/node-pty'); checks.nodePty = { available: true };
      } catch (error) {
        // 2026.3.28 lazily imports PTY and retries exec via its child adapter.
        if (pkg.version !== '2026.3.28') throw error;
        const output = require('node:child_process').execFileSync('/bin/sh', ['-c', 'printf openclawmgr-child-probe'],
          { encoding: 'utf8', timeout: 5000 });
        assert(output === 'openclawmgr-child-probe', 'Child process fallback verification failed');
        checks.nodePty = { available: false, fallback: 'openclaw-2026.3.28-child-process', error: error.message };
        checks.childProcess = { available: true };
        console.error('node-pty unavailable; verified child process fallback. Interactive PTY is unavailable.');
      }
    }
    let matrixPath;
    try { matrixPath = load.resolve('@matrix-org/matrix-sdk-crypto-nodejs'); } catch {}
    if (matrixPath) {
      try {
        load('@matrix-org/matrix-sdk-crypto-nodejs'); checks.matrix = { available: true };
      } catch (error) {
        checks.matrix = { available: false, error: error.message };
        console.error('Optional Matrix native integration unavailable: ' + error.message);
      }
    }
    console.log(JSON.stringify(checks));
  } else if (mode === 'receipt') {
    const [metadata, npmVersion, channel, source, nodeSource, nodeDigest, output] = args;
    const managedRoot = path.dirname(path.dirname(process.execPath));
    const managed = fs.existsSync(path.join(managedRoot, '.openclawmgr-glibc'));
    const sdk = sharedSdk();
    const nodeFile = managed || sdk ? path.join(sdk || managedRoot, 'bin/node.real') : process.execPath;
    const nodeExecutableSha256 = (await digestFile(nodeFile, 'sha256')).digest('hex');
    let runtime;
    if (sdk) {
      const ref = read(path.join(path.dirname(output), 'runtime.json'));
      assert(ref.provider === 'mise-runtime' && ref.instance === process.env.ISTORE_RUNTIME_ID &&
        ref.storage_root === process.env.ISTORE_RUNTIME_STORAGE, 'Application binding differs from executed SDK');
      runtime = { kind: 'mise-runtime', instance: ref.instance, storageRoot: ref.storage_root,
        library: ref.library, manifestSha256: ref.library_manifest_sha256,
        glibc: process.report.getReport().header.glibcVersionRuntime };
    } else runtime = managed ? { kind: 'isolated-glibc', glibc: process.report.getReport().header.glibcVersionRuntime,
      manifestSha256: (await digestFile(path.join(managedRoot, 'glibc/SHA256SUMS'), 'sha256')).digest('hex') } : { kind: 'native' };
    write(output, { ...read(metadata), npm: npmVersion, channel, source, nodeSource, nodeExecutableSha256,
      nodeSha256: nodeDigest || null, runtime, installedAt: new Date().toISOString(), nativeChecks: read(args[7]) });
    // No credentials: the service UID must read its exact release identity.
    if (sdk) fs.chmodSync(output, 0o644);
  } else if (mode === 'scripts') {
    const npmVersion = args[0];
    if (semver(args[1]).gte(npmVersion, '11.16.0')) console.log('--allow-scripts=openclaw');
  } else throw new Error(`Unknown runtime check: ${mode}`);
}

main().catch(error => { console.error(error.message); process.exitCode = error.exitCode || 1; });
