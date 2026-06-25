'use strict';

const childProcess = require('node:child_process');
const { clearTimeout, setTimeout } = require('node:timers');

const seconds = Number(process.argv[2]);
const command = process.argv[3];
const args = process.argv.slice(4);

if (!Number.isFinite(seconds) || seconds <= 0 || !command) process.exit(64);

const child = childProcess.spawn(command, args, { stdio: 'inherit' });
let timedOut = false;
let forceTimer;

const timer = setTimeout(() => {
  timedOut = true;
  child.kill('SIGTERM');
  forceTimer = setTimeout(() => child.kill('SIGKILL'), 1000);
}, seconds * 1000);

child.once('error', () => {
  clearTimeout(timer);
  process.exit(127);
});

child.once('close', (code, signal) => {
  clearTimeout(timer);
  clearTimeout(forceTimer);
  if (timedOut) process.exit(124);
  if (code !== null) process.exit(code);
  process.exit(signal ? 128 : 1);
});
