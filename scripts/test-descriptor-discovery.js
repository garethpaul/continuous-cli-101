'use strict';

const assert = require('node:assert/strict');
const { Buffer } = require('node:buffer');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const childProcess = require('node:child_process');
const { Readable } = require('node:stream');
const discovery = require('./descriptor-discovery');

const identity = 'CONTINUOUS_CLI_ROOT_ID := test-identity';
const end = 'test-end-marker';

function fakeRegularFile(tempDir, name = 'Makefile') {
  const file = path.join(tempDir, name);
  fs.writeFileSync(file, `${identity}\n`);
  return file;
}

async function expectFailure(label, action) {
  await assert.rejects(action, undefined, label);
}

(async () => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'descriptor-discovery-test.'));
  try {
    const makefile = fakeRegularFile(tempDir);
    const wrapper = path.join(tempDir, 'wrapper with spaces.mk');
    fs.writeFileSync(wrapper, '# wrapper\n');
    const trailer = path.join(tempDir, 'trailer.mk');
    fs.writeFileSync(trailer, '# trailer\n');
    assert.equal(
      discovery.discoverFromMakefileList(`${wrapper} ${makefile} ${trailer}`, identity),
      makefile,
    );

    const duplicate = fakeRegularFile(tempDir, 'duplicate Makefile');
    assert.throws(
      () => discovery.discoverFromMakefileList(`${makefile} ${duplicate}`, identity),
      /exactly one Makefile/,
    );
    assert.throws(
      () => discovery.discoverFromMakefileList(Array(257).fill('missing').join(' '), identity),
      /too many entries/,
    );

    const dollarMakefile = fakeRegularFile(tempDir, 'Make$file');
    assert.equal(
      discovery.discoverFromMakeInputs('', identity, ['make', '-f', dollarMakefile]),
      dollarMakefile,
    );

    const valid = Buffer.from(`p1\0f9\0tREG\0n${makefile}\0${end}\0`);
    assert.equal(await discovery.discoverFromLsofChunks([valid], 0, { identity, end }), makefile);

    await expectFailure('truncated record', () =>
      discovery.discoverFromLsofChunks([
        Buffer.from(`p1\0f9\0tREG\0n${makefile}\0f10\0tREG\0ntruncated`),
      ], 0, { identity, end }));
    await expectFailure('nonzero child', () =>
      discovery.discoverFromLsofChunks([valid], 7, { identity, end }));
    await expectFailure('post-sentinel framing', () =>
      discovery.discoverFromLsofChunks([
        Buffer.from(`p1\0f9\0tREG\0n${makefile}\0${end}\0f10\0`),
      ], 0, { identity, end }));
    await expectFailure('non-regular lsof type', () =>
      discovery.discoverFromLsofChunks([
        Buffer.from(`p1\0f9\0tFIFO\0n${makefile}\0${end}\0`),
      ], 0, { identity, end }));

    const procDir = path.join(tempDir, 'proc');
    fs.mkdirSync(procDir);
    fs.symlinkSync(makefile, path.join(procDir, '40'));
    assert.equal(discovery.discoverFromProc(procDir, identity), makefile);

    let spawned = false;
    assert.equal(await discovery.discover({
      backend: 'auto',
      procDir,
      identity,
      end,
      spawnLsof() {
        spawned = true;
        throw new Error('lsof must not run when proc is available');
      },
    }), makefile);
    assert.equal(spawned, false);

    const stream = Readable.from([valid]);
    assert.equal(await discovery.discoverFromLsofStream(stream, Promise.resolve(0), { identity, end }), makefile);

    const splitStream = Readable.from([
      valid.subarray(0, 7),
      valid.subarray(7, valid.length - 2),
      valid.subarray(valid.length - 2),
    ]);
    assert.equal(await discovery.discoverFromLsofStream(splitStream, Promise.resolve(0), { identity, end }), makefile);

    const handle = fs.openSync(makefile, 'r');
    try {
      const automatic = childProcess.spawnSync(
        process.execPath,
        [path.join(__dirname, 'descriptor-discovery.js'), 'auto', 'self', 'test-identity', end],
        { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe', handle] },
      );
      assert.equal(automatic.status, 0, automatic.stderr);
      const selected = Buffer.from(automatic.stdout.split(':')[1], 'base64').toString();
      assert.equal(selected, fs.realpathSync(makefile));
    } finally {
      fs.closeSync(handle);
    }

    process.stdout.write('Descriptor discovery direct tests passed.\n');
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
