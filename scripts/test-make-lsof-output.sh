#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
MAKEFILE_UNDER_TEST=${MAKEFILE_UNDER_TEST:-$ROOT_DIR/Makefile}
IDENTITY_UNDER_TEST=${IDENTITY_UNDER_TEST:-}
MAKE_UNDER_TEST=${MAKE_UNDER_TEST:-/usr/bin/make}
MAKE_PATH=$(command -v "$MAKE_UNDER_TEST")
INHERITED_REGULAR_FD_COUNT=${INHERITED_REGULAR_FD_COUNT:-8192}
CASE_TIMEOUT=${CASE_TIMEOUT:-45}
PATH_BOUNDARY_TARGET=${PATH_BOUNDARY_TARGET:-all}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-lsof-output.XXXXXX")

if command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT=$(command -v gtimeout)
elif command -v timeout >/dev/null 2>&1; then
  TIMEOUT=$(command -v timeout)
else
  printf '%s\n' 'lsof output tests require timeout or gtimeout' >&2
  exit 69
fi

if [ -z "$IDENTITY_UNDER_TEST" ] && \
    [ -f "$(dirname -- "$MAKEFILE_UNDER_TEST")/.continuous-cli-root" ]; then
  IDENTITY_UNDER_TEST=$(dirname -- "$MAKEFILE_UNDER_TEST")/.continuous-cli-root
fi

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

repository="$TEMP_DIR/repository"
"$ROOT_DIR/scripts/copy-tracked-worktree.sh" "$repository"
cp -- "$MAKEFILE_UNDER_TEST" "$repository/Makefile"
if [ -n "$IDENTITY_UNDER_TEST" ]; then
  cp -- "$IDENTITY_UNDER_TEST" "$repository/.continuous-cli-root"
fi

fixture_root="$TEMP_DIR/distinct-regular-files-with-a-deliberately-long-parent-directory-name-for-lsof-record-size"
mkdir -p "$fixture_root"
python3 - "$fixture_root" "$INHERITED_REGULAR_FD_COUNT" <<'PY'
import os
import sys

root, count = sys.argv[1:]
for index in range(int(count)):
    name = f'{index:05d}-' + ('regular-descriptor-long-name-' * 4) + '.txt'
    with open(os.path.join(root, name), 'wb'):
        pass
PY

STUB_NPM="$TEMP_DIR/npm-stub"
cat >"$STUB_NPM" <<'EOF'
#!/bin/sh
set -eu
if [ "$#" -lt 3 ] || [ "$1" != --prefix ]; then exit 64; fi
actual=$(CDPATH='' cd -- "$2" && pwd -P) || exit 64
if [ "$actual" != "$EXPECTED_ROOT" ]; then exit 64; fi
shift 2
case "$*" in
  'run lint') marker=lint ;;
  'test') marker=test ;;
  'run check') marker=build ;;
  'run audit') marker=audit ;;
  *) exit 65 ;;
esac
printf '%s\n' "$marker" >>"$MARKER_LOG"
EOF
chmod +x "$STUB_NPM"

expected_root=$(CDPATH='' cd -- "$repository" && pwd -P)
expected_markers() {
  case $1 in
    lint) printf '%s\n' lint ;;
    test) printf '%s\n' test ;;
    build) printf '%s\n' build ;;
    audit) printf '%s\n' audit ;;
    verify|check) printf '%s\n' lint,test,build,audit ;;
  esac
}

if [ "$PATH_BOUNDARY_TARGET" = all ]; then
  targets='lint test build audit verify check'
else
  targets=$PATH_BOUNDARY_TARGET
fi

failures=0
for target in $targets; do
  log="$TEMP_DIR/$target.log"
  : >"$log"
  set +e
  EXPECTED_ROOT="$expected_root" MARKER_LOG="$log" \
    "$TIMEOUT" "$CASE_TIMEOUT" python3 - \
      "$MAKE_PATH" "$repository/Makefile" "$STUB_NPM" "$target" \
      "$fixture_root" <<'PY'
import os
import sys

make, makefile, npm, target, fixture_root = sys.argv[1:]
held = []
for name in os.listdir(fixture_root):
    descriptor = os.open(os.path.join(fixture_root, name), os.O_RDONLY)
    os.set_inheritable(descriptor, True)
    held.append(descriptor)

os.chdir('/')
os.execve(
    make,
    [make, '--no-print-directory', '-f', makefile, f'NPM={npm}', target],
    os.environ.copy(),
)
PY
  status=$?
  set -e

  actual=$(paste -sd, "$log")
  expected=$(expected_markers "$target")
  if [ "$status" -ne 0 ] || [ "$actual" != "$expected" ]; then
    printf 'lsof-output/%s status=%s expected <%s>, got <%s>\n' \
      "$target" "$status" "$expected" "$actual" >&2
    failures=$((failures + 1))
  fi
done

if [ "$failures" -ne 0 ]; then
  printf 'lsof output matrix failures: %s\n' "$failures" >&2
  exit 1
fi

printf 'Large lsof-output matrix passed with %s and %s regular descriptors.\n' \
  "$($MAKE_UNDER_TEST --version | sed -n '1p')" "$INHERITED_REGULAR_FD_COUNT"
