#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/continuous-cli-v4-mutations.XXXXXX")

resolve_make() {
  candidate=$1
  resolved=$(command -v "$candidate" 2>/dev/null || true)
  if [ -z "$resolved" ] || [ ! -x "$resolved" ]; then
    printf 'configured Make executable is unavailable: %s\n' "$candidate" >&2
    exit 1
  fi
  printf '%s\n' "$resolved"
}

DEFAULT_MAKE=$(resolve_make make)
if command -v gmake >/dev/null 2>&1; then
  DEFAULT_MODERN_MAKE=$(resolve_make gmake)
else
  DEFAULT_MODERN_MAKE=$DEFAULT_MAKE
fi
MAKE_381=$(resolve_make "${MAKE_381:-$DEFAULT_MAKE}")
MAKE_441=$(resolve_make "${MAKE_441:-$DEFAULT_MODERN_MAKE}")

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

mutate() {
  name=$1
  make_bin=$2
  harness=$3
  case_name=$4
  search=$5
  replacement=$6
  second_search=${7-}
  second_replacement=${8-}
  destination="$TEMP_DIR/$name/Makefile"
  mkdir -p "$(dirname -- "$destination")"
  cp -- "$ROOT_DIR/.continuous-cli-root" "$(dirname -- "$destination")/.continuous-cli-root"

  node - "$ROOT_DIR/Makefile" "$destination" "$search" "$replacement" \
    "$second_search" "$second_replacement" <<'NODE'
const fs = require('node:fs');
const [, , source, destination, search, replacement, secondSearch, secondReplacement] = process.argv;
const input = fs.readFileSync(source, 'utf8');
if (!input.includes(search)) {
  throw new Error(`mutation source not found: ${search}`);
}
let output = input.split(search).join(replacement);
if (secondSearch) {
  if (!output.includes(secondSearch)) {
    throw new Error(`second mutation source not found: ${secondSearch}`);
  }
  output = output.split(secondSearch).join(secondReplacement);
}
fs.writeFileSync(destination, output);
NODE

  if [ "$harness" = scripts/test-make-descriptor-types.sh ]; then
    mutation_result=0
    MAKEFILE_UNDER_TEST="$destination" \
      IDENTITY_UNDER_TEST="$(dirname -- "$destination")/.continuous-cli-root" \
      MAKE_UNDER_TEST="$make_bin" \
      DESCRIPTOR_CASE="$case_name" \
      PATH_BOUNDARY_TARGET=lint \
      CASE_TIMEOUT=2 \
      "$ROOT_DIR/$harness" >/dev/null 2>&1 || mutation_result=$?
  elif [ "$harness" = scripts/test-make-lsof-output.sh ]; then
    mutation_result=0
    MAKEFILE_UNDER_TEST="$destination" \
      IDENTITY_UNDER_TEST="$(dirname -- "$destination")/.continuous-cli-root" \
      MAKE_UNDER_TEST="$make_bin" \
      INHERITED_REGULAR_FD_COUNT=8192 \
      PATH_BOUNDARY_TARGET=lint \
      CASE_TIMEOUT=45 \
      "$ROOT_DIR/$harness" >/dev/null 2>&1 || mutation_result=$?
  else
    mutation_result=0
    MAKEFILE_UNDER_TEST="$destination" \
      IDENTITY_UNDER_TEST="$(dirname -- "$destination")/.continuous-cli-root" \
      MAKE_UNDER_TEST="$make_bin" \
      PATH_BOUNDARY_CASE="$case_name" \
      "$ROOT_DIR/$harness" >/dev/null 2>&1 || mutation_result=$?
  fi

  if [ "$mutation_result" -eq 0 ]; then
    printf 'hostile mutation survived: %s\n' "$name" >&2
    exit 1
  fi

  printf 'Rejected hostile mutation: %s\n' "$name"
}

mutate_module() {
  name=$1
  make_bin=$2
  harness=$3
  case_name=$4
  search=$5
  replacement=$6
  second_search=${7-}
  second_replacement=${8-}
  destination="$TEMP_DIR/$name/Makefile"
  module_destination="$TEMP_DIR/$name/descriptor-discovery.js"
  mkdir -p "$(dirname -- "$destination")"
  cp -- "$ROOT_DIR/.continuous-cli-root" "$(dirname -- "$destination")/.continuous-cli-root"

  node - "$ROOT_DIR/Makefile" "$ROOT_DIR/scripts/descriptor-discovery.js" \
    "$destination" "$module_destination" "$search" "$replacement" \
    "$second_search" "$second_replacement" <<'NODE'
const fs = require('node:fs');
const [, , makefilePath, modulePath, destination, moduleDestination, search, replacement, secondSearch, secondReplacement] = process.argv;
let moduleSource = fs.readFileSync(modulePath, 'utf8');
if (!moduleSource.includes(search)) throw new Error(`module mutation source not found: ${search}`);
moduleSource = moduleSource.split(search).join(replacement);
if (secondSearch) {
  if (!moduleSource.includes(secondSearch)) throw new Error(`second module mutation source not found: ${secondSearch}`);
  moduleSource = moduleSource.split(secondSearch).join(secondReplacement);
}
let makefile = fs.readFileSync(makefilePath, 'utf8');
makefile = makefile.replace(
  /^CONTINUOUS_CLI_DISCOVERY_MODULE := [A-Za-z0-9+/=]+$/m,
  `CONTINUOUS_CLI_DISCOVERY_MODULE := ${Buffer.from(moduleSource).toString('base64')}`,
);
fs.writeFileSync(destination, makefile);
fs.writeFileSync(moduleDestination, moduleSource);
NODE

  mutation_result=0
  if [ "$harness" = scripts/test-descriptor-discovery.js ]; then
    cp -- "$ROOT_DIR/scripts/test-descriptor-discovery.js" "$TEMP_DIR/$name/test-descriptor-discovery.js"
    node "$TEMP_DIR/$name/test-descriptor-discovery.js" >/dev/null 2>&1 || mutation_result=$?
  elif [ "$harness" = scripts/test-make-descriptor-types.sh ]; then
    MAKEFILE_UNDER_TEST="$destination" \
      IDENTITY_UNDER_TEST="$(dirname -- "$destination")/.continuous-cli-root" \
      MAKE_UNDER_TEST="$make_bin" DESCRIPTOR_CASE="$case_name" \
      PATH_BOUNDARY_TARGET=lint CASE_TIMEOUT=2 \
      "$ROOT_DIR/$harness" >/dev/null 2>&1 || mutation_result=$?
  elif [ "$harness" = scripts/test-make-lsof-output.sh ]; then
    MAKEFILE_UNDER_TEST="$destination" \
      IDENTITY_UNDER_TEST="$(dirname -- "$destination")/.continuous-cli-root" \
      MAKE_UNDER_TEST="$make_bin" INHERITED_REGULAR_FD_COUNT=8192 \
      PATH_BOUNDARY_TARGET=lint CASE_TIMEOUT=45 \
      "$ROOT_DIR/$harness" >/dev/null 2>&1 || mutation_result=$?
  else
    MAKEFILE_UNDER_TEST="$destination" \
      IDENTITY_UNDER_TEST="$(dirname -- "$destination")/.continuous-cli-root" \
      MAKE_UNDER_TEST="$make_bin" PATH_BOUNDARY_CASE="$case_name" \
      "$ROOT_DIR/$harness" >/dev/null 2>&1 || mutation_result=$?
  fi
  if [ "$mutation_result" -eq 0 ]; then
    printf 'hostile mutation survived: %s\n' "$name" >&2
    exit 1
  fi
  printf 'Rejected hostile mutation: %s\n' "$name"
}

MAKE_381_VERSION=$("$MAKE_381" --version | sed -n '1p')
if [ "$MAKE_381_VERSION" = 'GNU Make 3.81' ]; then
  mutate \
    make-381-list-export \
    "$MAKE_381" \
    scripts/test-make-path-boundary-v4.sh \
    dollar-directory \
    'ifeq ($(MAKE_VERSION),3.81)' \
    'ifeq ($(MAKE_VERSION),never)'

  mutate_module \
    lsof-escape-decoding-removed \
    "$MAKE_381" \
    scripts/test-make-path-boundary-v4.sh \
    byte-matrix \
    'const file = decodeLsofName(value.slice(1));' \
    'const file = value.slice(1);'

  mutate_module \
    fixed-lsof-descriptor-range \
    "$MAKE_381" \
    scripts/test-make-high-fd.sh \
    all \
    "['-a', '-p', String(pid), '-Fftn0']" \
    "['-a', '-p', String(pid), '-d', '3-64', '-Fftn0']"

  mutate_module \
    lsof-output-truncated \
    "$MAKE_381" \
    scripts/test-make-lsof-output.sh \
    all \
    'for await (const chunk of processHandle.stdout) parser.write(Buffer.from(chunk));' \
    'let captured = 0; for await (const chunk of processHandle.stdout) { const buffer = Buffer.from(chunk); if (captured < 1048576) parser.write(buffer.subarray(0, 1048576 - captured)); captured += buffer.length; }'
else
  for mutation in make-381-list-export lsof-escape-decoding-removed \
    fixed-lsof-descriptor-range lsof-output-truncated; do
    printf 'Skipped %s: GNU Make 3.81 required, found %s.\n' \
      "$mutation" "$MAKE_381_VERSION"
  done
fi

mutate_module \
  fifo-socket-regular-filter-removed \
  "$MAKE_381" \
  scripts/test-descriptor-discovery.js \
  all \
  "value.startsWith('n') && numeric && type === 'REG'" \
  "value.startsWith('n') && numeric"

mutate \
  public-marker-scan \
  "$MAKE_441" \
  scripts/test-make-path-boundary-v4.sh \
  multi-collision \
  '[ -f "$$root/.continuous-cli-root" ] && [ "$$(cat "$$root/.continuous-cli-root")" = "$$identity" ] && grep -Fqx "CONTINUOUS_CLI_ROOT_ID := $$identity" <"$$candidate"' \
  'grep -Fqx "CONTINUOUS_CLI_MAKEFILE_MARKER := continuous-cli-101" <"$$candidate"'

mutate \
  duplicate-identity-first-match \
  "$MAKE_441" \
  scripts/test-make-path-boundary-v4.sh \
  duplicate-identity \
  'channel=$$root_b64:$$file_b64; count=$$((count + 1));' \
  'channel=$$root_b64:$$file_b64; count=1; break;'

mutate \
  deleted-file-revalidation-removed \
  "$MAKE_441" \
  scripts/test-make-path-boundary-v4.sh \
  deleted-identity \
  '[ -f "$$makefile" ]; CDPATH= cd -P -- "$$root"; [ "$$(cat .continuous-cli-root)" = "$(CONTINUOUS_CLI_ROOT_ID)" ]; grep -Fqx "$(CONTINUOUS_CLI_MAKEFILE_IDENTITY)" <"$$makefile";' \
  'CDPATH= cd -P -- "$$root";'

mutate \
  trailing-newline-file-truncated \
  "$MAKE_441" \
  scripts/test-make-path-boundary-v4.sh \
  byte-matrix \
  'makefile=$$({ node -e "process.stdout.write(Buffer.from(process.argv[1],\"base64\"))" "$$makefile_b64"; printf .; }); makefile=$${makefile%.};' \
  'makefile=$$(node -e "process.stdout.write(Buffer.from(process.argv[1],\"base64\"))" "$$makefile_b64");'

mutate \
  physical-root-replaced-by-caller-cwd \
  "$MAKE_441" \
  scripts/test-make-path-boundary.sh \
  normal \
  'CDPATH= cd -P -- "$$root";' \
  'CDPATH= cd -P -- .;'

mutate \
  root-channel-caller-override \
  "$MAKE_441" \
  scripts/test-make-path-boundary-v4.sh \
  dollar-directory \
  'override CONTINUOUS_CLI_ROOT_CHANNEL :=' \
  'CONTINUOUS_CLI_ROOT_CHANNEL :='

mutate \
  unquoted-npm-executable \
  "$MAKE_441" \
  scripts/test-make-path-boundary.sh \
  normal \
  'exec "$$NPM" --prefix "$$PWD"' \
  'exec $$NPM --prefix "$$PWD"'

mutate \
  unquoted-physical-prefix \
  "$MAKE_441" \
  scripts/test-make-path-boundary.sh \
  space \
  '--prefix "$$PWD"' \
  '--prefix $$PWD'

printf '%s\n' 'Make v7 path-boundary hostile mutations passed.'
