#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
INHERITED_REGULAR_FD_COUNT=${INHERITED_REGULAR_FD_COUNT:-8192}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-proc-large.XXXXXX")

cleanup() { rm -rf -- "$TEMP_DIR"; }
trap cleanup EXIT HUP INT TERM

identity='CONTINUOUS_CLI_ROOT_ID := proc-large-identity'
makefile="$TEMP_DIR/Makefile"
printf '%s\n' "$identity" >"$makefile"
mkdir -p "$TEMP_DIR/proc-fd" "$TEMP_DIR/files"
python3 - "$TEMP_DIR/files" "$TEMP_DIR/proc-fd" "$makefile" "$INHERITED_REGULAR_FD_COUNT" <<'PY'
import os
import sys

files, descriptors, makefile, count = sys.argv[1:]
os.symlink(makefile, os.path.join(descriptors, '40'))
for index in range(int(count)):
    name = f'{index:05d}-' + ('proc-regular-long-name-' * 4) + '.txt'
    path = os.path.join(files, name)
    open(path, 'wb').close()
    os.symlink(path, os.path.join(descriptors, str(index + 100)))
PY

node - "$ROOT_DIR/scripts/descriptor-discovery.js" "$TEMP_DIR/proc-fd" "$identity" "$makefile" <<'NODE'
const assert = require('node:assert/strict');
const discovery = require(process.argv[2]);
const selected = discovery.discoverFromProc(process.argv[3], process.argv[4]);
assert.equal(selected, process.argv[5]);
NODE

printf 'Large proc simulation passed with %s regular descriptors.\n' "$INHERITED_REGULAR_FD_COUNT"
