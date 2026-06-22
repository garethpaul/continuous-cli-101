'use strict';

const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
for (const relative of [
  'scripts/check-descriptor-discovery-bundle.js',
  'scripts/descriptor-discovery.js',
  'scripts/test-descriptor-discovery.js',
]) {
  const source = fs.readFileSync(path.join(root, relative), 'utf8');
  if (/\bBuffer\b/.test(source) &&
      !source.includes("const { Buffer } = require('node:buffer');")) {
    throw new Error(`${relative} must import Buffer from node:buffer`);
  }
}
const discoverySource = fs.readFileSync(path.join(root, 'scripts/descriptor-discovery.js'), 'utf8');
if (/}\s*catch\s*\([^)]*\)/.test(discoverySource) || /catch\s*\{\s*\}/.test(discoverySource)) {
  throw new Error('descriptor-discovery.js must use nonempty optional catch bindings');
}
process.stdout.write('Descriptor discovery Node globals are imported explicitly.\n');
