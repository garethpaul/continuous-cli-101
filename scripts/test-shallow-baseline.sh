#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
SOURCE_REPOSITORY=${SOURCE_REPOSITORY:-$ROOT_DIR}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-shallow-baseline.XXXXXX")

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

snapshot="$TEMP_DIR/snapshot"
"$SOURCE_REPOSITORY/scripts/copy-tracked-worktree.sh" "$snapshot"

git -C "$snapshot" init --quiet
git -C "$snapshot" config user.name 'Shallow Baseline Test'
git -C "$snapshot" config user.email 'shallow-baseline@example.invalid'
git -C "$snapshot" add --all
git -C "$snapshot" commit --quiet -m 'single commit snapshot'

if git -C "$snapshot" cat-file -e '1c82b9674e7bc39a6722e2617b90a3c55e0de026^{tree}' 2>/dev/null; then
  printf '%s\n' 'single-commit fixture unexpectedly contains the original parent tree' >&2
  exit 1
fi

if [ "${SHALLOW_BASELINE_MUTATION:-}" = parent-tree ]; then
  cat >"$snapshot/scripts/copy-tracked-worktree.sh" <<'EOF'
#!/bin/sh
set -eu
ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
destination=$1
mkdir -p -- "$destination"
git -C "$ROOT_DIR" archive 1c82b9674e7bc39a6722e2617b90a3c55e0de026 | tar -C "$destination" -xf -
EOF
  chmod +x "$snapshot/scripts/copy-tracked-worktree.sh"
fi

CONTINUOUS_CLI_SHALLOW_BASELINE_ACTIVE=1 sh "$snapshot/scripts/check-baseline.sh"

cp -- "$snapshot/Makefile" "$TEMP_DIR/Makefile"
sed 's/ifeq ($(MAKE_VERSION),3.81)/ifeq ($(MAKE_VERSION),3.81-tampered)/' \
  "$TEMP_DIR/Makefile" >"$snapshot/Makefile"
if CONTINUOUS_CLI_SHALLOW_BASELINE_ACTIVE=1 \
    sh "$snapshot/scripts/check-baseline.sh" >/dev/null 2>&1; then
  printf '%s\n' 'shallow baseline accepted Makefile source tampering' >&2
  exit 1
fi
cp -- "$TEMP_DIR/Makefile" "$snapshot/Makefile"

cp -- "$snapshot/scripts/test-make-path-boundary-v4.sh" "$TEMP_DIR/path-test"
sed 's/dollar-directory) run_dollar_directory ;;/dollar-directory) exit 0 ;;/' \
  "$TEMP_DIR/path-test" \
  >"$snapshot/scripts/test-make-path-boundary-v4.sh"
git -C "$snapshot" add scripts/test-make-path-boundary-v4.sh
if CONTINUOUS_CLI_SHALLOW_BASELINE_ACTIVE=1 \
    sh "$snapshot/scripts/check-baseline.sh" >/dev/null 2>&1; then
  printf '%s\n' 'shallow baseline accepted path-test tampering' >&2
  exit 1
fi
git -C "$snapshot" reset --quiet HEAD -- scripts/test-make-path-boundary-v4.sh
cp -- "$TEMP_DIR/path-test" "$snapshot/scripts/test-make-path-boundary-v4.sh"
printf '%s\n' 'Single-commit shallow baseline passed without historical objects.'
