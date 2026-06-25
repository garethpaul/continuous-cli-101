'use strict';

const assert = require('node:assert/strict');
const childProcess = require('node:child_process');
const path = require('node:path');

const runner = path.join(__dirname, 'run-with-timeout.js');

const success = childProcess.spawnSync(
  process.execPath,
  [runner, '1', process.execPath, '-e', 'process.exit(0)'],
);
assert.equal(success.status, 0);

const timedOut = childProcess.spawnSync(
  process.execPath,
  [runner, '0.05', process.execPath, '-e', 'setTimeout(() => {}, 1000)'],
);
assert.equal(timedOut.status, 124);

process.stdout.write('Portable timeout runner tests passed.\n');
