#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
DESCRIPTOR_GENERATOR=${DESCRIPTOR_GENERATOR:-$(command -v node)}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-proc-simulation.XXXXXX")

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

identity='CONTINUOUS_CLI_ROOT_ID := proc-simulation-identity'
makefile="$TEMP_DIR/Makefile"
printf '%s\n' "$identity" >"$makefile"
mkdir -p "$TEMP_DIR/proc-fd"
mkfifo "$TEMP_DIR/inherited-fifo"
ln -s "$makefile" "$TEMP_DIR/proc-fd/40"
ln -s "$TEMP_DIR/inherited-fifo" "$TEMP_DIR/proc-fd/41"
"$DESCRIPTOR_GENERATOR" -e \
  'for (let descriptor = 100; descriptor < 356; descriptor++) console.log(descriptor);' \
  >"$TEMP_DIR/descriptors"
while IFS= read -r descriptor; do
  ln -s /dev/null "$TEMP_DIR/proc-fd/$descriptor"
done <"$TEMP_DIR/descriptors"

node - "$ROOT_DIR/scripts/descriptor-discovery.js" "$TEMP_DIR/proc-fd" "$identity" "$makefile" <<'NODE'
const assert = require('node:assert/strict');
const discovery = require(process.argv[2]);
const selected = discovery.discoverFromProc(process.argv[3], process.argv[4]);
assert.equal(selected, process.argv[5]);
NODE

printf '%s\n' 'Linux proc descriptor simulation passed with direct helper backend.'
