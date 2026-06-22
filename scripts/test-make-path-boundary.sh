#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
MAKEFILE_UNDER_TEST=${MAKEFILE_UNDER_TEST:-$ROOT_DIR/Makefile}
IDENTITY_UNDER_TEST=${IDENTITY_UNDER_TEST:-$(dirname -- "$MAKEFILE_UNDER_TEST")/.continuous-cli-root}
MAKE_UNDER_TEST=${MAKE_UNDER_TEST:-make}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-path-boundary.XXXXXX")

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

STUB_DIR="$TEMP_DIR/npm stub;safe#"
STUB_NPM="$STUB_DIR/npm"
mkdir -p "$STUB_DIR"
cat >"$STUB_NPM" <<'EOF'
#!/bin/sh
set -eu

if [ "$#" -lt 3 ] || [ "$1" != "--prefix" ]; then
  printf 'unexpected npm arguments:' >&2
  printf ' <%s>' "$@" >&2
  printf '\n' >&2
  exit 64
fi

prefix=$2
shift 2

if [ "$prefix" != "$EXPECTED_ROOT" ]; then
  printf 'unexpected npm prefix: expected <%s>, got <%s>\n' "$EXPECTED_ROOT" "$prefix" >&2
  exit 65
fi

case "$*" in
  'run lint') marker=lint ;;
  'test') marker=test ;;
  'run check') marker=build ;;
  'run audit') marker=audit ;;
  *)
    printf 'unexpected npm script:' >&2
    printf ' <%s>' "$@" >&2
    printf '\n' >&2
    exit 66
    ;;
esac

printf '%s\n' "$marker" >>"$MARKER_LOG"
EOF
chmod +x "$STUB_NPM"

clone_case() {
  destination=$1
  "$ROOT_DIR/scripts/copy-tracked-worktree.sh" "$destination"
  cp -- "$MAKEFILE_UNDER_TEST" "$destination/Makefile"
  cp -- "$IDENTITY_UNDER_TEST" "$destination/.continuous-cli-root"
}

assert_log() {
  log=$1
  expected=$2
  actual=$(paste -sd, "$log")
  if [ "$actual" != "$expected" ]; then
    printf 'unexpected npm marker sequence: expected <%s>, got <%s>\n' "$expected" "$actual" >&2
    exit 67
  fi
}

assert_no_unintended_command() {
  if [ -e "$TEMP_DIR/path-command-executed" ]; then
    printf '%s\n' "checkout path executed an unintended command" >&2
    exit 68
  fi
}

run_target() {
  repository=$1
  target=$2
  caller_dir=$3
  invocation=$4
  log="$TEMP_DIR/markers-$invocation-$target"
  : >"$log"

  expected_root=$(CDPATH='' cd -- "$repository" && pwd -P)

  (
    cd -- "$caller_dir"
    export EXPECTED_ROOT="$expected_root"
    export MARKER_LOG="$log"

    case "$invocation" in
      direct)
        "$MAKE_UNDER_TEST" --no-print-directory -f "$repository/Makefile" \
          NPM="$STUB_NPM" \
          ROOT='/tmp/hostile-root-override' \
          CONTINUOUS_CLI_MAKEFILE_LIST='/tmp/hostile-list-override' \
          CONTINUOUS_CLI_MAKEFILE='/tmp/hostile-entry-override' \
          "$target"
        ;;
      multi)
        "$MAKE_UNDER_TEST" --no-print-directory \
          -f "$MULTI_FIRST_MAKEFILE" \
          -f "$repository/Makefile" \
          NPM="$STUB_NPM" \
          ROOT='/tmp/hostile-root-override' \
          CONTINUOUS_CLI_MAKEFILE_LIST='/tmp/hostile-list-override' \
          CONTINUOUS_CLI_MAKEFILE='/tmp/hostile-entry-override' \
          "$target"
        ;;
      include)
        "$MAKE_UNDER_TEST" --no-print-directory -f "$WRAPPER_MAKEFILE" \
          NPM="$STUB_NPM" \
          ROOT='/tmp/hostile-root-override' \
          CONTINUOUS_CLI_MAKEFILE_LIST='/tmp/hostile-list-override' \
          CONTINUOUS_CLI_MAKEFILE='/tmp/hostile-entry-override' \
          "$target"
        ;;
      leading)
        "$MAKE_UNDER_TEST" --no-print-directory -f "$LEADING_RELATIVE_MAKEFILE" \
          NPM="$STUB_NPM" \
          ROOT='/tmp/hostile-root-override' \
          CONTINUOUS_CLI_MAKEFILE_LIST='/tmp/hostile-list-override' \
          CONTINUOUS_CLI_MAKEFILE='/tmp/hostile-entry-override' \
          "$target"
        ;;
      symlink)
        "$MAKE_UNDER_TEST" --no-print-directory -f "$SYMLINK_MAKEFILE" \
          NPM="$STUB_NPM" \
          ROOT='/tmp/hostile-root-override' \
          CONTINUOUS_CLI_MAKEFILE_LIST='/tmp/hostile-list-override' \
          CONTINUOUS_CLI_MAKEFILE='/tmp/hostile-entry-override' \
          "$target"
        ;;
      *)
        printf 'unknown invocation: %s\n' "$invocation" >&2
        exit 69
        ;;
    esac
  )

  LAST_MARKER_LOG=$log
  assert_no_unintended_command
}

run_all_targets() {
  repository=$1
  caller_dir=$2
  invocation=$3

  run_target "$repository" lint "$caller_dir" "$invocation"
  assert_log "$LAST_MARKER_LOG" lint
  run_target "$repository" test "$caller_dir" "$invocation"
  assert_log "$LAST_MARKER_LOG" test
  run_target "$repository" build "$caller_dir" "$invocation"
  assert_log "$LAST_MARKER_LOG" build
  run_target "$repository" audit "$caller_dir" "$invocation"
  assert_log "$LAST_MARKER_LOG" audit
  run_target "$repository" verify "$caller_dir" "$invocation"
  assert_log "$LAST_MARKER_LOG" lint,test,build,audit
  run_target "$repository" check "$caller_dir" "$invocation"
  assert_log "$LAST_MARKER_LOG" lint,test,build,audit
}

run_case() {
  case_name=$1

  case "$case_name" in
    normal)
      repository="$TEMP_DIR/repository-normal"
      clone_case "$repository"
      run_all_targets "$repository" "$TEMP_DIR" direct
      ;;
    space)
      repository="$TEMP_DIR/repository with spaces"
      clone_case "$repository"
      run_all_targets "$repository" "$TEMP_DIR" direct
      ;;
    meta)
      repository="$TEMP_DIR/repository;touch path-command-executed;#"
      clone_case "$repository"
      run_all_targets "$repository" "$TEMP_DIR" direct
      ;;
    multi)
      repository="$TEMP_DIR/repository-multi"
      clone_case "$repository"
      MULTI_FIRST_MAKEFILE="$TEMP_DIR/first makefile.mk"
      printf '%s\n' '# intentionally loaded before the repository Makefile' >"$MULTI_FIRST_MAKEFILE"
      export MULTI_FIRST_MAKEFILE
      run_all_targets "$repository" "$TEMP_DIR" multi
      ;;
    include)
      repository="$TEMP_DIR/repository-include"
      clone_case "$repository"
      WRAPPER_MAKEFILE="$TEMP_DIR/wrapper.mk"
      printf 'include %s\n' "$repository/Makefile" >"$WRAPPER_MAKEFILE"
      export WRAPPER_MAKEFILE
      run_all_targets "$repository" "$TEMP_DIR" include
      ;;
    leading)
      repository="$TEMP_DIR/ leading-component/repository"
      mkdir -p "$TEMP_DIR/ leading-component"
      clone_case "$repository"
      LEADING_RELATIVE_MAKEFILE=' leading-component/repository/Makefile'
      export LEADING_RELATIVE_MAKEFILE
      run_all_targets "$repository" "$TEMP_DIR" leading
      ;;
    symlink)
      repository="$TEMP_DIR/repository-physical"
      clone_case "$repository"
      symlink="$TEMP_DIR/repository symlink"
      ln -s "$repository" "$symlink"
      SYMLINK_MAKEFILE="$symlink/Makefile"
      export SYMLINK_MAKEFILE
      run_all_targets "$repository" "$TEMP_DIR" symlink
      ;;
    *)
      printf 'unknown path-boundary case: %s\n' "$case_name" >&2
      exit 70
      ;;
  esac
}

case ${PATH_BOUNDARY_CASE:-all} in
  all)
    for case_name in normal space meta multi include leading symlink; do
      run_case "$case_name"
    done
    ;;
  normal|space|meta|multi|include|leading|symlink)
    run_case "$PATH_BOUNDARY_CASE"
    ;;
  *)
    printf 'unknown PATH_BOUNDARY_CASE: %s\n' "$PATH_BOUNDARY_CASE" >&2
    exit 71
    ;;
esac

printf 'Make checkout-path boundary tests passed with %s.\n' \
  "$($MAKE_UNDER_TEST --version | sed -n '1p')"
