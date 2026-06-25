#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
MAKEFILE_UNDER_TEST=${MAKEFILE_UNDER_TEST:-$ROOT_DIR/Makefile}
MAKE_UNDER_TEST=${MAKE_UNDER_TEST:-make}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-path-v4.XXXXXX")

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

STUB_DIR="$TEMP_DIR/npm-stub"
STUB_NPM="$STUB_DIR/npm"
mkdir -p "$STUB_DIR"
cat >"$STUB_NPM" <<'EOF'
#!/bin/sh
set -eu

if [ "$#" -lt 3 ] || [ "$1" != "--prefix" ]; then
  exit 64
fi

prefix=$2
shift 2
identity=$(cat "$prefix/.package-identity" 2>/dev/null || printf missing)

case "$*" in
  'run lint') marker=lint ;;
  'test') marker=test ;;
  'run check') marker=build ;;
  'run audit') marker=audit ;;
  *) exit 65 ;;
esac

printf '%s|%s\n' "$identity" "$marker" >>"$MARKER_LOG"
EOF
chmod +x "$STUB_NPM"

clone_case() {
  destination=$1
  "$ROOT_DIR/scripts/copy-tracked-worktree.sh" "$destination"
  cp -- "$MAKEFILE_UNDER_TEST" "$destination/Makefile"
  identity_source=$(dirname -- "$MAKEFILE_UNDER_TEST")/.continuous-cli-root
  if [ -f "$identity_source" ]; then
    cp -- "$identity_source" "$destination/.continuous-cli-root"
  fi
  printf '%s\n' intended >"$destination/.package-identity"
}

expected_markers() {
  case $1 in
    lint) printf '%s\n' 'intended|lint' ;;
    test) printf '%s\n' 'intended|test' ;;
    build) printf '%s\n' 'intended|build' ;;
    audit) printf '%s\n' 'intended|audit' ;;
    verify|check) printf '%s\n' 'intended|lint,intended|test,intended|build,intended|audit' ;;
  esac
}

assert_target() {
  case_name=$1
  repository=$2
  makefile=$3
  target=$4
  shift 4
  log="$TEMP_DIR/$case_name-$target.log"
  : >"$log"

  (
    cd -- "$TEMP_DIR"
    MARKER_LOG="$log" "$MAKE_UNDER_TEST" --no-print-directory "$@" \
      -f "$makefile" \
      NPM="$STUB_NPM" \
      ROOT=/tmp/hostile-root \
      CONTINUOUS_CLI_ROOT_CHANNEL=hostile \
      CONTINUOUS_CLI_ROOT_B64=hostile \
      CONTINUOUS_CLI_MAKEFILE_LIST=hostile \
      "$target"
  )

  actual=$(paste -sd, "$log")
  expected=$(expected_markers "$target")
  if [ "$actual" != "$expected" ]; then
    printf '%s/%s selected the wrong package: expected <%s>, got <%s>\n' \
      "$case_name" "$target" "$expected" "$actual" >&2
    exit 66
  fi
}

run_all_targets() {
  case_name=$1
  repository=$2
  makefile=$3
  shift 3

  case ${PATH_BOUNDARY_TARGET:-all} in
    all)
      for target in lint test build audit verify check; do
        assert_target "$case_name" "$repository" "$makefile" "$target" "$@"
      done
      ;;
    lint|test|build|audit|verify|check)
      assert_target "$case_name" "$repository" "$makefile" \
        "$PATH_BOUNDARY_TARGET" "$@"
      ;;
    *)
      printf 'unknown PATH_BOUNDARY_TARGET: %s\n' "$PATH_BOUNDARY_TARGET" >&2
      exit 67
      ;;
  esac
}

run_dollar_directory() {
  repository="$TEMP_DIR/repository\$suffix"
  clone_case "$repository"
  run_all_targets dollar-directory "$repository" "$repository/Makefile"
}

run_dollar_makefile() {
  repository="$TEMP_DIR/repository-dollar-file"
  clone_case "$repository"
  mv -- "$repository/Makefile" "$repository/Make\$file"
  run_all_targets dollar-makefile "$repository" "$repository/Make\$file"
}

install_collision_package() {
  collision_file=$1
  collision_root=${collision_file%/*}
  mkdir -p -- "$collision_root"
  printf '%s\n' 'CONTINUOUS_CLI_MAKEFILE_MARKER := continuous-cli-101' >"$collision_file"
  printf '%s\n' wrong >"$collision_root/.package-identity"
}

run_multi_collision() {
  repository="$TEMP_DIR/repository-multi"
  clone_case "$repository"
  first="$TEMP_DIR/first wrapper.mk"
  printf '%s\n' '# loaded before the repository Makefile' >"$first"
  collision="$first $repository/Makefile"
  install_collision_package "$collision"
  run_all_targets multi-collision "$repository" "$repository/Makefile" -f "$first"
}

run_include_collision() {
  repository="$TEMP_DIR/repository-include"
  clone_case "$repository"
  wrapper="$TEMP_DIR/include-wrapper.mk"
  printf 'include %s\n' "$repository/Makefile" >"$wrapper"
  collision="$wrapper $repository/Makefile"
  install_collision_package "$collision"
  run_all_targets include-collision "$repository" "$wrapper"
}

run_named_path_case() {
  case_name=$1
  repository=$2
  makefile_name=$3
  clone_case "$repository"
  if [ "$makefile_name" != Makefile ]; then
    mv -- "$repository/Makefile" "$repository/$makefile_name"
  fi
  run_all_targets "$case_name" "$repository" "$repository/$makefile_name"
}

run_byte_matrix() {
  tab=$(printf '\t')
  run_named_path_case trailing-newline-root "$TEMP_DIR/root-trailing
" Makefile
  run_named_path_case embedded-newline-root "$TEMP_DIR/root-embedded
middle" Makefile
  run_named_path_case multiple-newline-root "$TEMP_DIR/root-multiple

middle" Makefile
  run_named_path_case tab-root "$TEMP_DIR/root${tab}tab" Makefile
  run_named_path_case colon-root "$TEMP_DIR/root:colon" Makefile
  run_named_path_case backslash-root "$TEMP_DIR/root\\backslash" Makefile
  run_named_path_case metachar-root "$TEMP_DIR/root;()[]{}!#&|\`" Makefile
  run_named_path_case leading-dash-root "$TEMP_DIR/-root" Makefile

  run_named_path_case trailing-newline-makefile "$TEMP_DIR/file-root-1" "Makefile
"
  run_named_path_case embedded-newline-makefile "$TEMP_DIR/file-root-2" "Make
file"
  run_named_path_case multiple-newline-makefile "$TEMP_DIR/file-root-3" "Make

file"
  run_named_path_case tab-makefile "$TEMP_DIR/file-root-4" "Make${tab}file"
  run_named_path_case colon-makefile "$TEMP_DIR/file-root-5" 'Make:file'
  run_named_path_case backslash-makefile "$TEMP_DIR/file-root-6" 'Make\file'
  run_named_path_case metachar-makefile "$TEMP_DIR/file-root-7" 'Make;()[]{}!#&|`file'
  run_named_path_case leading-dash-makefile "$TEMP_DIR/file-root-8" '-Makefile'
}

run_recursive_make() {
  repository="$TEMP_DIR/recursive repository"
  clone_case "$repository"
  wrapper="$TEMP_DIR/recursive-wrapper.mk"
  cat >"$wrapper" <<EOF
.PHONY: lint test build audit verify check
lint test build audit verify check:
	@\$(MAKE) --no-print-directory -f "$repository/Makefile" \$@
EOF

  for target in lint test build audit verify check; do
    log="$TEMP_DIR/recursive-$target.log"
    : >"$log"
    MARKER_LOG="$log" NPM="$STUB_NPM" \
      CONTINUOUS_CLI_ROOT_CHANNEL=hostile \
      CONTINUOUS_CLI_PARSE_LIST=hostile \
      "$MAKE_UNDER_TEST" --no-print-directory -f "$wrapper" "$target"
    actual=$(paste -sd, "$log")
    expected=$(expected_markers "$target")
    if [ "$actual" != "$expected" ]; then
      printf 'recursive/%s selected the wrong package: expected <%s>, got <%s>\n' \
        "$target" "$expected" "$actual" >&2
      exit 69
    fi
  done
}

run_deleted_makefile() {
  for target in lint test build audit verify check; do
    repository="$TEMP_DIR/deleted-$target"
    clone_case "$repository"
    remover="$TEMP_DIR/remove-$target.mk"
    printf '$(shell rm -f "%s")\n' "$repository/Makefile" >"$remover"
    log="$TEMP_DIR/deleted-$target.log"
    : >"$log"

    if MARKER_LOG="$log" "$MAKE_UNDER_TEST" --no-print-directory \
        -f "$repository/Makefile" -f "$remover" \
        NPM="$STUB_NPM" "$target" >/dev/null 2>&1; then
      printf 'deleted Makefile unexpectedly passed target %s\n' "$target" >&2
      exit 70
    fi
    if [ -s "$log" ]; then
      printf 'deleted Makefile invoked npm for target %s\n' "$target" >&2
      exit 71
    fi
  done
}

run_deleted_identity() {
  for target in lint test build audit verify check; do
    repository="$TEMP_DIR/deleted-identity-$target"
    clone_case "$repository"
    remover="$TEMP_DIR/remove-identity-$target.mk"
    printf '$(shell rm -f "%s")\n' "$repository/.continuous-cli-root" >"$remover"
    log="$TEMP_DIR/deleted-identity-$target.log"
    : >"$log"

    if MARKER_LOG="$log" "$MAKE_UNDER_TEST" --no-print-directory \
        -f "$repository/Makefile" -f "$remover" \
        NPM="$STUB_NPM" "$target" >/dev/null 2>&1; then
      printf 'deleted identity unexpectedly passed target %s\n' "$target" >&2
      exit 75
    fi
    if [ -s "$log" ]; then
      printf 'deleted identity invoked npm for target %s\n' "$target" >&2
      exit 76
    fi
  done
}

run_duplicate_identity_collision() {
  repository="$TEMP_DIR/repository-duplicate-identity"
  clone_case "$repository"
  first="$TEMP_DIR/duplicate-first.mk"
  printf '%s\n' '# loaded before the repository Makefile' >"$first"
  collision="$first $repository/Makefile"
  collision_root=${collision%/*}
  mkdir -p -- "$collision_root"
  grep -F 'CONTINUOUS_CLI_ROOT_ID :=' "$repository/Makefile" >"$collision"
  cp -- "$repository/.continuous-cli-root" "$collision_root/.continuous-cli-root"
  printf '%s\n' wrong >"$collision_root/.package-identity"

  for target in lint test build audit verify check; do
    log="$TEMP_DIR/duplicate-$target.log"
    : >"$log"
    if [ "$($MAKE_UNDER_TEST --version | sed -n '1p')" = 'GNU Make 3.81' ]; then
      MARKER_LOG="$log" "$MAKE_UNDER_TEST" --no-print-directory \
        -f "$first" -f "$repository/Makefile" NPM="$STUB_NPM" "$target"
      actual=$(paste -sd, "$log")
      expected=$(expected_markers "$target")
      [ "$actual" = "$expected" ] || exit 72
    else
      if MARKER_LOG="$log" "$MAKE_UNDER_TEST" --no-print-directory \
          -f "$first" -f "$repository/Makefile" NPM="$STUB_NPM" \
          "$target" >/dev/null 2>&1; then
        printf 'duplicate identity unexpectedly passed target %s\n' "$target" >&2
        exit 73
      fi
      [ ! -s "$log" ] || exit 74
    fi
  done
}

case ${PATH_BOUNDARY_CASE:-all} in
  all)
    run_dollar_directory
    run_dollar_makefile
    run_multi_collision
    run_include_collision
    run_byte_matrix
    run_recursive_make
    run_deleted_makefile
    run_deleted_identity
    run_duplicate_identity_collision
    ;;
  dollar-directory) run_dollar_directory ;;
  dollar-makefile) run_dollar_makefile ;;
  multi-collision) run_multi_collision ;;
  include-collision) run_include_collision ;;
  byte-matrix) run_byte_matrix ;;
  recursive) run_recursive_make ;;
  deleted) run_deleted_makefile ;;
  deleted-identity) run_deleted_identity ;;
  duplicate-identity) run_duplicate_identity_collision ;;
  *)
    printf 'unknown PATH_BOUNDARY_CASE: %s\n' "$PATH_BOUNDARY_CASE" >&2
    exit 68
    ;;
esac

printf 'Make v4 blocker regressions passed with %s.\n' \
  "$($MAKE_UNDER_TEST --version | sed -n '1p')"
