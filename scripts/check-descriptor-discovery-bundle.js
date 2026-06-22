'use strict';

const { Buffer } = require('node:buffer');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const makefile = fs.readFileSync(path.join(root, 'Makefile'), 'utf8');
const match = makefile.match(/^CONTINUOUS_CLI_DISCOVERY_MODULE := ([A-Za-z0-9+/=]+)$/m);
if (!match) throw new Error('Makefile descriptor-discovery bundle is missing');
const bundled = Buffer.from(match[1], 'base64');
const source = fs.readFileSync(path.join(__dirname, 'descriptor-discovery.js'));
if (!bundled.equals(source)) throw new Error('Makefile descriptor-discovery bundle is stale');
if (!makefile.includes('$(CONTINUOUS_CLI_DISCOVERY_MODULE) auto $$$$')) {
  throw new Error('production discovery backend is not hardcoded to auto');
}
process.stdout.write('Descriptor discovery production bundle matches source.\n');
