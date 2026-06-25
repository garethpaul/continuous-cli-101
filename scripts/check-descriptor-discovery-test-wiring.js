'use strict';

const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(process.argv[2] || path.join(__dirname, '..'));
const wrapper = fs.readFileSync(path.join(root, 'scripts/test-make-lsof-truncation.sh'), 'utf8');
const directTest = fs.readFileSync(path.join(root, 'scripts/test-descriptor-discovery.js'), 'utf8');
const invocation = 'node "$ROOT_DIR/scripts/test-descriptor-discovery.js"';
if (wrapper.split(invocation).length !== 2) {
  throw new Error('descriptor discovery direct test is not wired exactly once');
}
for (const contract of [
  "'truncated record'",
  "'nonzero child'",
  "'post-sentinel framing'",
  "backend: 'auto'",
]) {
  if (!directTest.includes(contract)) throw new Error(`missing direct discovery contract: ${contract}`);
}
process.stdout.write('Descriptor discovery direct-test wiring is authoritative.\n');
