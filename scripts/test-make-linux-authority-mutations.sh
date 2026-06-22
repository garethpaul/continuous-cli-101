#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-linux-authority-mutations.XXXXXX")

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

repository="$TEMP_DIR/repository"
"$ROOT_DIR/scripts/copy-tracked-worktree.sh" "$repository"
git -C "$repository" init --quiet
git -C "$repository" config user.name 'Linux Authority Mutation Test'
git -C "$repository" config user.email 'linux-authority@example.invalid'
git -C "$repository" add --all
git -C "$repository" commit --quiet -m fixture

node - "$repository/scripts/test-make-proc-simulation.sh" <<'NODE'
const fs = require('node:fs');
const path = process.argv[2];
const source = fs.readFileSync(path, 'utf8');
const original = '  >"$TEMP_DIR/descriptors"\nwhile IFS= read -r descriptor; do';
const replacement = '  >"$TEMP_DIR/descriptors" || :\nwhile IFS= read -r descriptor; do';
if (!source.includes(original)) process.exit(70);
fs.writeFileSync(path, source.replace(original, replacement));
NODE
if ! DESCRIPTOR_GENERATOR=/usr/bin/false \
    "$repository/scripts/test-make-proc-simulation.sh" \
    >"$TEMP_DIR/generator-output" 2>&1; then
  printf '%s\n' 'generator-failure suppression mutation did not reproduce the false green' >&2
  cat "$TEMP_DIR/generator-output" >&2
  exit 1
fi
if ! grep -Fq 'Linux proc descriptor simulation passed' "$TEMP_DIR/generator-output"; then
  printf '%s\n' 'generator-failure suppression mutation omitted the false pass line' >&2
  exit 1
fi
printf '%s\n' 'Rejected hostile mutation: generator-failure-suppressed'

cp -- "$repository/scripts/descriptor-discovery.js" "$TEMP_DIR/descriptor-discovery"
node - "$repository/scripts/descriptor-discovery.js" <<'NODE'
const fs = require('node:fs');
const path = process.argv[2];
const source = fs.readFileSync(path, 'utf8');
const original = 'if (exitCode !== 0 || failed || !complete ||\n          pending.some((byte) => byte !== 10 && byte !== 13)) {';
const replacement = 'if (exitCode !== 0 || failed) {';
if (!source.includes(original)) process.exit(70);
fs.writeFileSync(path, source.replace(original, replacement));
NODE
if node "$repository/scripts/test-descriptor-discovery.js" \
    >"$TEMP_DIR/parser-output" 2>&1; then
  printf '%s\n' 'descriptor parser fail-open mutation unexpectedly passed' >&2
  exit 1
fi
if ! grep -Fq 'Missing expected rejection: truncated record' "$TEMP_DIR/parser-output"; then
  printf '%s\n' 'descriptor parser mutation failed for the wrong reason' >&2
  cat "$TEMP_DIR/parser-output" >&2
  exit 1
fi
cp -- "$TEMP_DIR/descriptor-discovery" "$repository/scripts/descriptor-discovery.js"
printf '%s\n' 'Rejected hostile mutation: direct-parser-framing-bypassed'

node - "$repository/scripts/test-make-lsof-truncation.sh" <<'NODE'
const fs = require('node:fs');
const path = process.argv[2];
const source = fs.readFileSync(path, 'utf8');
const original = 'node "$ROOT_DIR/scripts/test-descriptor-discovery.js"';
if (source.split(original).length !== 2) process.exit(70);
fs.writeFileSync(path, source.replace(original, ': # direct descriptor test bypassed'));
NODE
if node "$repository/scripts/check-descriptor-discovery-test-wiring.js" "$repository" \
    >"$TEMP_DIR/wiring-output" 2>&1; then
  printf '%s\n' 'direct descriptor-test bypass mutation unexpectedly passed' >&2
  exit 1
fi
if ! grep -Fq 'descriptor discovery direct test is not wired exactly once' "$TEMP_DIR/wiring-output"; then
  printf '%s\n' 'direct descriptor-test bypass failed for the wrong reason' >&2
  cat "$TEMP_DIR/wiring-output" >&2
  exit 1
fi
printf '%s\n' 'Rejected hostile mutation: direct-helper-test-bypassed'

printf '%s\n' 'Linux test-authority hostile mutations passed.'
