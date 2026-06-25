#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
MAKEFILE_UNDER_TEST=${MAKEFILE_UNDER_TEST:-$ROOT_DIR/Makefile}
IDENTITY_UNDER_TEST=${IDENTITY_UNDER_TEST:-}
MAKE_UNDER_TEST=${MAKE_UNDER_TEST:-make}
MAKE_PATH=$(command -v "$MAKE_UNDER_TEST")
INHERITED_FD_COUNT=${INHERITED_FD_COUNT:-100}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-high-fd.XXXXXX")

if [ -z "$IDENTITY_UNDER_TEST" ] && \
    [ -f "$(dirname -- "$MAKEFILE_UNDER_TEST")/.continuous-cli-root" ]; then
  IDENTITY_UNDER_TEST=$(dirname -- "$MAKEFILE_UNDER_TEST")/.continuous-cli-root
fi

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

repository="$TEMP_DIR/repository with spaces"
"$ROOT_DIR/scripts/copy-tracked-worktree.sh" "$repository"
cp -- "$MAKEFILE_UNDER_TEST" "$repository/Makefile"
if [ -n "$IDENTITY_UNDER_TEST" ]; then
  cp -- "$IDENTITY_UNDER_TEST" "$repository/.continuous-cli-root"
fi

STUB_NPM="$TEMP_DIR/npm-stub"
cat >"$STUB_NPM" <<'EOF'
#!/bin/sh
set -eu

if [ "$#" -lt 3 ] || [ "$1" != --prefix ] || [ "$2" != "$EXPECTED_ROOT" ]; then
  exit 64
fi

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

for target in lint test build audit verify check; do
  log="$TEMP_DIR/$target.log"
  : >"$log"
  EXPECTED_ROOT="$expected_root" MARKER_LOG="$log" \
    python3 - "$MAKE_PATH" "$repository/Makefile" "$STUB_NPM" \
    "$target" "$INHERITED_FD_COUNT" <<'PY'
import os
import sys

make, makefile, npm, target, count = sys.argv[1:]
for _ in range(int(count)):
    descriptor = os.open('/dev/null', os.O_RDONLY)
    os.set_inheritable(descriptor, True)

os.chdir('/')
os.execve(
    make,
    [make, '--no-print-directory', '-f', makefile, f'NPM={npm}', target],
    os.environ.copy(),
)
PY

  actual=$(paste -sd, "$log")
  expected=$(expected_markers "$target")
  if [ "$actual" != "$expected" ]; then
    printf 'high-fd/%s expected <%s>, got <%s>\n' \
      "$target" "$expected" "$actual" >&2
    exit 66
  fi
done

printf 'High inherited-fd matrix passed with %s.\n' \
  "$($MAKE_UNDER_TEST --version | sed -n '1p')"
