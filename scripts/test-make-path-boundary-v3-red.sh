#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
MAKEFILE_UNDER_TEST=${MAKEFILE_UNDER_TEST:-$ROOT_DIR/Makefile}
IDENTITY_UNDER_TEST=${IDENTITY_UNDER_TEST:-$(dirname -- "$MAKEFILE_UNDER_TEST")/.continuous-cli-root}
MAKE_UNDER_TEST=${MAKE_UNDER_TEST:-make}
CASE=${PATH_BOUNDARY_CASE:-all}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-path-v3-red.XXXXXX")

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

STUB_NPM="$TEMP_DIR/npm-stub"
cat >"$STUB_NPM" <<'EOF'
#!/bin/sh
set -eu

if [ "$#" -ne 3 ] || [ "$1" != "--prefix" ] || [ "$3" != "test" ]; then
  exit 64
fi

printf '%s' "$2" >"$PREFIX_LOG"
EOF
chmod +x "$STUB_NPM"

run_newline_case() {
  sibling=$1
  parent="$TEMP_DIR/repository
"
  makefile="$parent/Makefile"
  mkdir -p -- "$parent"
  cp -- "$MAKEFILE_UNDER_TEST" "$makefile"
  cp -- "$IDENTITY_UNDER_TEST" "$parent/.continuous-cli-root"

  if [ "$sibling" = yes ]; then
    mkdir -p -- "$TEMP_DIR/repository"
  fi

  physical_temp=$(CDPATH='' cd -- "$TEMP_DIR" && pwd -P)
  expected="$physical_temp/repository
"
  expected_log="$TEMP_DIR/expected-$sibling"
  printf '%s' "$expected" >"$expected_log"
  prefix_log="$TEMP_DIR/prefix-$sibling"
  : >"$prefix_log"

  if ! PREFIX_LOG="$prefix_log" \
      "$MAKE_UNDER_TEST" --no-print-directory -f "$makefile" \
      NPM="$STUB_NPM" test >"$TEMP_DIR/stdout-$sibling" \
      2>"$TEMP_DIR/stderr-$sibling"; then
    printf '%s\n' "trailing-newline case failed instead of verifying its selected checkout" >&2
    return 1
  fi

  if ! cmp -s "$expected_log" "$prefix_log"; then
    printf '%s\n' "wrong npm prefix for trailing-newline checkout" >&2
    return 1
  fi
}

run_leading_dash_case() {
  repository="$TEMP_DIR/leading-dash"
  makefile="$repository/-Makefile"
  mkdir -p -- "$repository"
  cp -- "$MAKEFILE_UNDER_TEST" "$makefile"
  cp -- "$IDENTITY_UNDER_TEST" "$repository/.continuous-cli-root"
  expected=$(CDPATH='' cd -- "$repository" && pwd -P)
  prefix_log="$TEMP_DIR/prefix-dash"
  : >"$prefix_log"

  (
    cd -- "$repository"
    PREFIX_LOG="$prefix_log" \
      "$MAKE_UNDER_TEST" --no-print-directory -f -Makefile \
      NPM="$STUB_NPM" test
  )

  actual=$(cat "$prefix_log")
  if [ "$actual" != "$expected" ]; then
    printf 'wrong leading-dash npm prefix: expected <%s>, got <%s>\n' "$expected" "$actual" >&2
    return 1
  fi
}

case $CASE in
  all)
    run_newline_case no
    run_newline_case yes
    run_leading_dash_case
    ;;
  newline-no-sibling)
    run_newline_case no
    ;;
  newline-sibling)
    run_newline_case yes
    ;;
  leading-dash)
    run_leading_dash_case
    ;;
  *)
    printf 'unknown PATH_BOUNDARY_CASE: %s\n' "$CASE" >&2
    exit 65
    ;;
esac

printf 'v3 RED cases passed with %s.\n' \
  "$($MAKE_UNDER_TEST --version | sed -n '1p')"
