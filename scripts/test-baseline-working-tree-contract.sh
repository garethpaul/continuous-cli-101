#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)

if ! grep -Fq 'if [ "${CONTINUOUS_CLI_SHALLOW_BASELINE_ACTIVE:-}" = 1 ] &&' \
    "$ROOT_DIR/scripts/check-baseline.sh"; then
  printf '%s\n' 'Verifier integrity must be enforced only inside copied snapshots.' >&2
  exit 1
fi

printf '%s\n' 'Working-tree baseline contract passed.'
