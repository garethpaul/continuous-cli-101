#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-copy-integrity.XXXXXX")

cleanup() { rm -rf -- "$TEMP_DIR"; }
trap cleanup EXIT HUP INT TERM

repo="$TEMP_DIR/repo"
mkdir -p "$repo/scripts"
cp -- "$ROOT_DIR/scripts/copy-tracked-worktree.sh" "$repo/scripts/"
chmod +x "$repo/scripts/copy-tracked-worktree.sh"
git -C "$repo" init --quiet
git -C "$repo" config user.name 'Copy Integrity Test'
git -C "$repo" config user.email 'copy-integrity@example.invalid'

printf 'committed\n' >"$repo/source.txt"
printf '#!/bin/sh\nprintf executable\n' >"$repo/executable.sh"
chmod +x "$repo/executable.sh"
ln -s source.txt "$repo/link"
printf 'odd\n' >"$repo/odd
+tab	name"
git -C "$repo" add --all
git -C "$repo" commit --quiet -m initial

printf 'staged\n' >"$repo/source.txt"
git -C "$repo" add source.txt
printf 'unstaged\n' >"$repo/source.txt"
ln -snf executable.sh "$repo/link"
chmod -x "$repo/executable.sh"
printf 'untracked\n' >"$repo/untracked.txt"
mkdir -p "$TEMP_DIR/output"
printf 'collision\n' >"$TEMP_DIR/output/source.txt"
"$repo/scripts/copy-tracked-worktree.sh" "$TEMP_DIR/output"

[ "$(cat "$TEMP_DIR/output/source.txt")" = unstaged ]
[ ! -x "$TEMP_DIR/output/executable.sh" ]
[ -L "$TEMP_DIR/output/link" ]
[ "$(readlink "$TEMP_DIR/output/link")" = executable.sh ]
[ -f "$TEMP_DIR/output/odd
+tab	name" ]
[ ! -e "$TEMP_DIR/output/untracked.txt" ]
[ ! -e "$TEMP_DIR/output/collision-only.txt" ]

mv "$repo/.git" "$repo/.git-missing"
if "$repo/scripts/copy-tracked-worktree.sh" "$TEMP_DIR/missing-git" >/dev/null 2>&1; then
  printf '%s\n' 'copy unexpectedly passed without Git metadata' >&2
  exit 1
fi
[ ! -e "$TEMP_DIR/missing-git" ]
mv "$repo/.git-missing" "$repo/.git"

cp "$repo/.git/index" "$TEMP_DIR/index"
printf corrupt >"$repo/.git/index"
if "$repo/scripts/copy-tracked-worktree.sh" "$TEMP_DIR/corrupt-index" >/dev/null 2>&1; then
  printf '%s\n' 'copy unexpectedly passed with corrupt index' >&2
  exit 1
fi
[ ! -e "$TEMP_DIR/corrupt-index" ]
cp "$TEMP_DIR/index" "$repo/.git/index"

head=$(git -C "$repo" rev-parse HEAD)
git -C "$repo" update-index --add --cacheinfo "160000,$head,gitlink"
printf preserved-gitlink >"$TEMP_DIR/gitlink-output"
if "$repo/scripts/copy-tracked-worktree.sh" "$TEMP_DIR/gitlink-output" >/dev/null 2>&1; then
  printf '%s\n' 'copy unexpectedly passed with an unavailable gitlink' >&2
  exit 1
fi
[ "$(cat "$TEMP_DIR/gitlink-output")" = preserved-gitlink ]
cp "$TEMP_DIR/index" "$repo/.git/index"

rm "$repo/source.txt"
printf preserved >"$TEMP_DIR/existing"
if "$repo/scripts/copy-tracked-worktree.sh" "$TEMP_DIR/existing" >/dev/null 2>&1; then
  printf '%s\n' 'copy unexpectedly passed with a missing tracked file' >&2
  exit 1
fi
[ "$(cat "$TEMP_DIR/existing")" = preserved ]

printf '%s\n' 'Tracked-worktree copier integrity tests passed.'
