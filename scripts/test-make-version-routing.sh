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

printf '%s\n' 'GNU Make legacy-version routing contract passed.'
