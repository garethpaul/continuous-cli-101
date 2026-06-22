'use strict';

const { Buffer } = require('node:buffer');
const childProcess = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const READ_LIMIT = 65536;
const FIELD_LIMIT = 65536;

function closeQuietly(handle) {
  try {
    fs.closeSync(handle);
    return true;
  } catch {
    return false;
  }
}

function decodeLsofName(value) {
  return value.replace(/\\(\\|n|r|t|x[0-9a-fA-F]{2}|[0-7]{3})/g, (...parts) => {
    const escape = parts[1];
    if (escape === '\\') return '\\';
    if (escape === 'n') return '\n';
    if (escape === 'r') return '\r';
    if (escape === 't') return '\t';
    const hexadecimal = escape[0] === 'x';
    return String.fromCharCode(parseInt(escape.slice(hexadecimal ? 1 : 0), hexadecimal ? 16 : 8));
  });
}

function identified(descriptor, file, identity) {
  let handle;
  try {
    handle = fs.openSync(descriptor, fs.constants.O_RDONLY | fs.constants.O_NONBLOCK);
    if (!fs.fstatSync(handle).isFile() || !fs.statSync(file).isFile()) return false;
    const buffer = Buffer.alloc(READ_LIMIT);
    let size = 0;
    while (size < READ_LIMIT) {
      const count = fs.readSync(handle, buffer, size, READ_LIMIT - size, size);
      if (count === 0) break;
      size += count;
    }
    return buffer.subarray(0, size).toString('utf8').split(/\r?\n/).includes(identity);
  } catch {
    return false;
  } finally {
    if (handle !== undefined) {
      closeQuietly(handle);
    }
  }
}

function selectSingle(matches) {
  if (matches.size !== 1) throw new Error('descriptor discovery did not select exactly one Makefile');
  return [...matches][0];
}

function discoverFromProc(procDir, identity) {
  const matches = new Set();
  for (const fd of fs.readdirSync(procDir)) {
    if (!/^\d+$/.test(fd)) continue;
    const descriptor = path.join(procDir, fd);
    try {
      const file = fs.readlinkSync(descriptor);
      if (identified(descriptor, file, identity)) matches.add(file);
    } catch {
      continue;
    }
  }
  return selectSingle(matches);
}

function createLsofParser(identity, end) {
  const matches = new Set();
  let pending = Buffer.alloc(0);
  let numeric = false;
  let type = '';
  let complete = false;
  let failed = false;

  function field(buffer) {
    const value = buffer.toString().replace(/^\n+/, '');
    if (value === end) {
      if (complete) failed = true;
      complete = true;
      return;
    }
    if (complete) {
      failed = true;
      return;
    }
    if (value.startsWith('f')) {
      numeric = /^\d+$/.test(value.slice(1));
      type = '';
    } else if (value.startsWith('t')) {
      type = value.slice(1);
    } else if (value.startsWith('n') && numeric && type === 'REG') {
      const file = decodeLsofName(value.slice(1));
      if (identified(file, file, identity)) {
        matches.add(file);
        if (matches.size > 1) failed = true;
      }
    }
  }

  return {
    write(chunk) {
      if (failed) return;
      const data = Buffer.concat([pending, chunk]);
      let start = 0;
      let stop;
      while ((stop = data.indexOf(0, start)) !== -1) {
        field(data.subarray(start, stop));
        if (failed) return;
        start = stop + 1;
      }
      pending = Buffer.from(data.subarray(start));
      if (pending.length > FIELD_LIMIT) failed = true;
    },
    finish(exitCode) {
      if (exitCode !== 0 || failed || !complete ||
          pending.some((byte) => byte !== 10 && byte !== 13)) {
        throw new Error('invalid or incomplete lsof output');
      }
      return selectSingle(matches);
    },
  };
}

async function discoverFromLsofStream(stream, completion, { identity, end }) {
  const parser = createLsofParser(identity, end);
  for await (const chunk of stream) parser.write(Buffer.from(chunk));
  return parser.finish(await completion);
}

async function discoverFromLsofChunks(chunks, exitCode, options) {
  const { Readable } = require('node:stream');
  return discoverFromLsofStream(Readable.from(chunks), Promise.resolve(exitCode), options);
}

function spawnLsof(pid) {
  const child = childProcess.spawn('lsof', ['-a', '-p', String(pid), '-Fftn0'], {
    stdio: ['ignore', 'pipe', 'ignore'],
  });
  return {
    stdout: child.stdout,
    completion: new Promise((resolve, reject) => {
      child.once('error', reject);
      child.once('close', (code) => resolve(code === null ? 1 : code));
    }),
  };
}

async function discoverFromLsofProcess(pid, identity, end, spawn = spawnLsof) {
  const processHandle = spawn(pid);
  const parser = createLsofParser(identity, end);
  for await (const chunk of processHandle.stdout) parser.write(Buffer.from(chunk));
  const exitCode = await processHandle.completion;
  if (exitCode === 0) parser.write(Buffer.from(`${end}\0`));
  return parser.finish(exitCode);
}

async function discover({ backend, pid = process.pid, procDir, identity, end, spawnLsof: spawn }) {
  if (backend === 'proc') return discoverFromProc(procDir, identity);
  if (backend === 'lsof') return discoverFromLsofProcess(pid, identity, end, spawn);
  if (backend !== 'auto') throw new Error('invalid discovery backend');
  const automaticProcDir = procDir || `/proc/${pid}/fd`;
  if (fs.existsSync(automaticProcDir)) return discoverFromProc(automaticProcDir, identity);
  return discoverFromLsofProcess(pid, identity, end, spawn);
}

function emit(file) {
  const root = fs.realpathSync(path.dirname(file)) + path.sep + '.';
  return `${Buffer.from(root).toString('base64')}:${Buffer.from(file).toString('base64')}`;
}

async function runCli(args) {
  const [backend, pidArgument, identityValue, end] = args;
  const pid = pidArgument === 'self' ? process.pid : Number(pidArgument);
  if (!Number.isInteger(pid) || !identityValue || !end) throw new Error('invalid discovery arguments');
  const identity = `CONTINUOUS_CLI_ROOT_ID := ${identityValue}`;
  const file = await discover({ backend, pid, identity, end });
  process.stdout.write(emit(file));
}

module.exports = {
  createLsofParser,
  decodeLsofName,
  discover,
  discoverFromLsofChunks,
  discoverFromLsofProcess,
  discoverFromLsofStream,
  discoverFromProc,
  emit,
  runCli,
};

if (require.main === module) {
  runCli(process.argv.slice(2)).catch(() => process.exit(1));
}
