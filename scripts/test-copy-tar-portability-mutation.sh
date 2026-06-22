#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-copy-tar-mutation.XXXXXX")

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

repository="$TEMP_DIR/repository"
"$ROOT_DIR/scripts/copy-tracked-worktree.sh" "$repository"
git -C "$repository" init --quiet
git -C "$repository" config user.name 'Tar Portability Mutation Test'
git -C "$repository" config user.email 'tar-portability@example.invalid'
git -C "$repository" add --all
git -C "$repository" commit --quiet -m fixture

node - "$repository/scripts/copy-tracked-worktree.sh" <<'NODE'
const fs = require('fs');
const path = process.argv[2];
const source = fs.readFileSync(path, 'utf8');
const portableExtraction = `(\n  CDPATH='' cd -- "$staging"\n  tar -xf "$archive"\n)`;
if (!source.includes(portableExtraction)) {
  throw new Error('portable extraction block not found');
}
fs.writeFileSync(
  path,
  source.replace(portableExtraction, 'tar -C "$staging" -xf "$archive"'),
);
NODE

if SOURCE_REPOSITORY="$repository" \
    "$ROOT_DIR/scripts/test-copy-tar-portability.sh" \
    >"$TEMP_DIR/output" 2>&1; then
  printf '%s\n' 'GNU tar destination-path mutation unexpectedly passed' >&2
  exit 1
fi

if ! grep -Fq 'root\backslash.copy.' "$TEMP_DIR/output"; then
  printf '%s\n' 'GNU tar destination-path mutation failed for the wrong reason' >&2
  cat "$TEMP_DIR/output" >&2
  exit 1
fi

printf '%s\n' 'Tracked-worktree tar portability mutation was rejected.'
