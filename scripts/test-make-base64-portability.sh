#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-base64-portability.XXXXXX")
REAL_BASE64=$(command -v base64)

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$TEMP_DIR/bin"
cat >"$TEMP_DIR/bin/base64" <<'EOF'
#!/bin/sh
set -eu

for argument in "$@"; do
  if [ "$argument" = -d ]; then
    printf '%s\n' 'GNU base64 decode flag is not portable' >&2
    exit 69
  fi
done

exec "$REAL_BASE64_UNDER_TEST" "$@"
EOF
chmod +x "$TEMP_DIR/bin/base64"

REAL_BASE64_UNDER_TEST="$REAL_BASE64" PATH="$TEMP_DIR/bin:$PATH" \
  PATH_BOUNDARY_CASE=dollar-directory PATH_BOUNDARY_TARGET=lint \
  "$ROOT_DIR/scripts/test-make-path-boundary-v4.sh"

printf '%s\n' 'Make Base64 portability test passed.'
