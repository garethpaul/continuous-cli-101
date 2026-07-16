#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
MAKEFILE="$ROOT_DIR/Makefile"

if ! grep -Fq 'ifeq ($(MAKE_VERSION),3.81)' "$MAKEFILE" || \
   ! grep -Fq 'else ifeq ($(MAKE_VERSION),3.82)' "$MAKEFILE" || \
   ! grep -Fq 'CONTINUOUS_CLI_MAKEFILE_LIST = $(value MAKEFILE_LIST)' "$MAKEFILE" || \
   ! grep -Fq 'export CONTINUOUS_CLI_MAKEFILE_LIST' "$MAKEFILE" || \
   ! grep -Fq 'CONTINUOUS_CLI_USE_LIST_DISCOVERY := 1' "$MAKEFILE" || \
   ! grep -Fq 'list self' "$MAKEFILE"; then
  printf '%s\n' 'GNU Make 3.82 must use byte-preserving Makefile-list discovery.' >&2
  exit 1
fi

# GNU Make 4.2 expands '$' sequences when MAKEFILE_LIST is written through
# $(file), so the modern branch falls back to byte-preserving list discovery
# whenever its capture channel comes back empty. Hosted CI runs Make 4.3, where
# the fallback stays dormant and is never exercised, so pin it statically the
# same way the 3.81/3.82 routing is pinned. The legacy greps above cannot cover
# this: they match the 3.82 branch, so they still pass if the 4.2 fallback is
# removed.
FALLBACK_GUARD='ifeq ($(strip $(CONTINUOUS_CLI_ROOT_CHANNEL)),)'

if ! grep -Fq "$FALLBACK_GUARD" "$MAKEFILE"; then
  printf '%s\n' 'GNU Make 4.2 must fall back to byte-preserving Makefile-list discovery when the modern capture channel is empty.' >&2
  exit 1
fi

FALLBACK_BLOCK=$(awk -v guard="$FALLBACK_GUARD" '
  index($0, guard) { found = 1 }
  found { print; if ($0 == "endif") exit }
' "$MAKEFILE")

for required in \
  'override CONTINUOUS_CLI_USE_LIST_DISCOVERY := 1' \
  'override CONTINUOUS_CLI_MAKEFILE_LIST = $(value MAKEFILE_LIST)' \
  'export CONTINUOUS_CLI_MAKEFILE_LIST'
do
  if ! printf '%s\n' "$FALLBACK_BLOCK" | grep -Fqx "$required"; then
    printf '%s\n' "GNU Make 4.2 fallback must contain: $required" >&2
    exit 1
  fi
done

printf '%s\n' 'GNU Make legacy-version routing contract passed.'
printf '%s\n' 'GNU Make 4.2 dollar-path fallback contract passed.'
