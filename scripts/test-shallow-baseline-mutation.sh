#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)

if SHALLOW_BASELINE_MUTATION=parent-tree \
    "$ROOT_DIR/scripts/test-shallow-baseline.sh" >/dev/null 2>&1; then
  printf '%s\n' 'hostile mutation survived: shallow-parent-tree-dependence' >&2
  exit 1
fi

printf '%s\n' 'Rejected hostile mutation: shallow-parent-tree-dependence'
