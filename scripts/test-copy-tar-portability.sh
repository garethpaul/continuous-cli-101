#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
SOURCE_REPOSITORY=${SOURCE_REPOSITORY:-$ROOT_DIR}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-copy-tar.XXXXXX")
REAL_TAR=$(command -v tar)

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$TEMP_DIR/bin"
cat >"$TEMP_DIR/bin/tar" <<'EOF'
#!/bin/sh
set -eu

extract=false
for argument in "$@"; do
  case $argument in
    -*x*|-x*) extract=true ;;
  esac
done

previous=
backslash=$(printf '\\')
for argument in "$@"; do
  if [ "$previous" = -C ] && [ "$extract" = true ]; then
    case $argument in
      *"$backslash"*)
        printf 'tar: %s: Cannot open: No such file or directory\n' "$argument" >&2
        exit 2
        ;;
    esac
  fi
  previous=$argument
done

exec "$REAL_TAR_UNDER_TEST" "$@"
EOF
chmod +x "$TEMP_DIR/bin/tar"

run_case() {
  name=$1
  destination="$TEMP_DIR/$name"
  REAL_TAR_UNDER_TEST="$REAL_TAR" PATH="$TEMP_DIR/bin:$PATH" \
    "$SOURCE_REPOSITORY/scripts/copy-tracked-worktree.sh" "$destination"
  test -f "$destination/Makefile"
  test -x "$destination/scripts/copy-tracked-worktree.sh"
}

run_case 'root with spaces'
run_case 'root\backslash'
run_case 'root
newline'
run_case '-root-leading-dash'

printf '%s\n' 'Tracked-worktree tar portability tests passed.'
