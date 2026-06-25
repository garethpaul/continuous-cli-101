#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
MAKEFILE_UNDER_TEST=${MAKEFILE_UNDER_TEST:-$ROOT_DIR/Makefile}
IDENTITY_UNDER_TEST=${IDENTITY_UNDER_TEST:-}
MAKE_UNDER_TEST=${MAKE_UNDER_TEST:-make}
MAKE_PATH=$(command -v "$MAKE_UNDER_TEST")
DESCRIPTOR_CASE=${DESCRIPTOR_CASE:-all}
PATH_BOUNDARY_TARGET=${PATH_BOUNDARY_TARGET:-all}
INHERITED_FD_COUNT=${INHERITED_FD_COUNT:-4096}
CASE_TIMEOUT=${CASE_TIMEOUT:-8}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-descriptor-types.XXXXXX")
TIMEOUT="$ROOT_DIR/scripts/run-with-timeout.js"

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

STUB_NPM="$TEMP_DIR/npm-stub"
cat >"$STUB_NPM" <<'EOF'
#!/bin/sh
set -eu

if [ "$#" -lt 3 ] || [ "$1" != --prefix ]; then
  exit 64
fi

actual_root=$(CDPATH='' cd -- "$2" && pwd -P) || exit 64
if [ "$actual_root" != "$EXPECTED_ROOT" ]; then
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

run_case() {
  descriptor_type=$1
  target=$2
  fixture="$TEMP_DIR/$descriptor_type-$target"
  log="$fixture.log"
  mkdir -p "$fixture"
  : >"$log"

  set +e
  EXPECTED_ROOT="$expected_root" MARKER_LOG="$log" \
    node "$TIMEOUT" "$CASE_TIMEOUT" python3 - \
      "$MAKE_PATH" "$repository/Makefile" "$STUB_NPM" "$target" \
      "$descriptor_type" "$fixture" "$INHERITED_FD_COUNT" <<'PY'
import os
import socket
import sys

make, makefile, npm, target, descriptor_type, fixture, count = sys.argv[1:]
held = []

if descriptor_type == 'fifo':
    path = os.path.join(fixture, 'inherited-fifo')
    os.mkfifo(path)
    held.append(os.open(path, os.O_RDWR))
elif descriptor_type == 'socket':
    path = f'/tmp/cc-v6-socket-{os.getpid()}'
    listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    listener.bind(path)
    listener.listen(1)
    os.unlink(path)
    held.append(listener)
elif descriptor_type == 'pipe':
    held.extend(os.pipe())
elif descriptor_type == 'deleted-regular':
    path = os.path.join(fixture, 'deleted-regular')
    descriptor = os.open(path, os.O_CREAT | os.O_RDWR, 0o600)
    os.write(descriptor, b'not the repository identity\n')
    os.unlink(path)
    held.append(descriptor)
elif descriptor_type == 'directory':
    held.append(os.open(fixture, os.O_RDONLY))
elif descriptor_type == 'device':
    held.append(os.open('/dev/null', os.O_RDONLY))
elif descriptor_type == 'ordinary-many':
    for _ in range(int(count)):
        held.append(os.open('/dev/null', os.O_RDONLY))
else:
    raise SystemExit(f'unknown descriptor type: {descriptor_type}')

for item in held:
    descriptor = item.fileno() if hasattr(item, 'fileno') else item
    os.set_inheritable(descriptor, True)

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
    printf 'descriptor/%s/%s status=%s expected <%s>, got <%s>\n' \
      "$descriptor_type" "$target" "$status" "$expected" "$actual" >&2
    return 1
  fi
}

if [ "$DESCRIPTOR_CASE" = all ]; then
  descriptor_cases='fifo socket pipe deleted-regular directory device ordinary-many'
else
  descriptor_cases=$DESCRIPTOR_CASE
fi

if [ "$PATH_BOUNDARY_TARGET" = all ]; then
  targets='lint test build audit verify check'
else
  targets=$PATH_BOUNDARY_TARGET
fi

failures=0
for descriptor_type in $descriptor_cases; do
  for target in $targets; do
    if ! run_case "$descriptor_type" "$target"; then
      failures=$((failures + 1))
    fi
  done
done

if [ "$failures" -ne 0 ]; then
  printf 'descriptor matrix failures: %s\n' "$failures" >&2
  exit 1
fi

printf 'Descriptor-type matrix passed with %s.\n' \
  "$($MAKE_UNDER_TEST --version | sed -n '1p')"
