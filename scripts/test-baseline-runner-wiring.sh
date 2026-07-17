#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
GATE="$ROOT_DIR/scripts/check-baseline.sh"

# check-baseline.sh already proves every runner FILE exists (require_file) and
# that several runners keep their blocker mutations (grep -Fq content pins).
# Neither proves a runner is ever EXECUTED: stubbing an unpinned runner to
# "exit 0", or deleting its invocation line, left the whole gate green.
#
# Each entry below is the exact, whole invocation line that must stay wired into
# scripts/check-baseline.sh. Whole-line matching (grep -Fxq) is mandatory: a
# substring pin would also be satisfied by the require_file list or the shallow
# snapshot diff list, which name each script without running it -- an
# existence check masquerading as an execution check.
missing=0

require_wired() {
  invocation=$1
  count=$(grep -Fxc "$invocation" "$GATE" || true)
  if [ "${count:-0}" -ne 1 ]; then
    printf '%s\n' "check-baseline.sh must execute this runner exactly once (found ${count:-0}): $invocation" >&2
    missing=$((missing + 1))
  fi
}

require_wired '"$ROOT_DIR/scripts/test-make-path-boundary.sh"'
require_wired '"$ROOT_DIR/scripts/test-make-base64-portability.sh"'
require_wired '"$ROOT_DIR/scripts/test-make-version-routing.sh"'
require_wired '"$ROOT_DIR/scripts/test-baseline-working-tree-contract.sh"'
require_wired '"$ROOT_DIR/scripts/test-baseline-runner-wiring.sh"'
require_wired 'node "$ROOT_DIR/scripts/test-run-with-timeout.js"'
require_wired 'node "$ROOT_DIR/scripts/check-descriptor-discovery-bundle.js"'
require_wired 'node "$ROOT_DIR/scripts/check-descriptor-discovery-lint-contract.js"'
require_wired 'node "$ROOT_DIR/scripts/check-descriptor-discovery-test-wiring.js"'
require_wired 'node "$ROOT_DIR/scripts/test-descriptor-discovery.js"'
require_wired '"$ROOT_DIR/scripts/test-make-path-boundary-v3-red.sh"'
require_wired '"$ROOT_DIR/scripts/test-make-path-boundary-v4.sh"'
require_wired '"$ROOT_DIR/scripts/test-make-high-fd.sh"'
require_wired '"$ROOT_DIR/scripts/test-make-descriptor-types.sh"'
require_wired '"$ROOT_DIR/scripts/test-make-proc-simulation.sh"'
require_wired '"$ROOT_DIR/scripts/test-make-lsof-output.sh"'
require_wired '"$ROOT_DIR/scripts/test-make-proc-large-output.sh"'
require_wired '"$ROOT_DIR/scripts/test-make-lsof-truncation.sh"'
require_wired '"$ROOT_DIR/scripts/test-make-linux-authority-mutations.sh"'
require_wired '"$ROOT_DIR/scripts/test-make-path-boundary-mutations.sh"'

# The snapshot-only runners stay inside the shallow-baseline guard, so their
# invocations carry the two-space indentation of that if-block.
require_wired '  "$ROOT_DIR/scripts/test-copy-tracked-worktree.sh"'
require_wired '  "$ROOT_DIR/scripts/test-copy-tar-portability.sh"'
require_wired '  "$ROOT_DIR/scripts/test-copy-tar-portability-mutation.sh"'
require_wired '  "$ROOT_DIR/scripts/test-shallow-baseline.sh"'
require_wired '  "$ROOT_DIR/scripts/test-shallow-baseline-mutation.sh"'

# Wiring alone only proves check-baseline.sh still names each runner. A runner
# replaced by a bare "exit 0" stub is still invoked, still exits 0, and still
# satisfies both require_file and the wiring pins above. check-baseline.sh
# already anchors most runners to a distinctive internal string; the runners
# below had no anchor at all, so each is anchored here to its success marker,
# which a stub cannot emit.
require_anchor() {
  runner=$1
  anchor=$2
  if ! grep -Fq "$anchor" "$ROOT_DIR/scripts/$runner"; then
    printf '%s\n' "Runner must keep its observable behaviour anchor: $runner -> $anchor" >&2
    missing=$((missing + 1))
  fi
}

require_anchor test-make-base64-portability.sh 'Make Base64 portability test passed.'
require_anchor test-make-base64-portability.sh 'GNU base64 decode flag is not portable'
require_anchor test-make-version-routing.sh 'GNU Make legacy-version routing contract passed.'
require_anchor test-make-version-routing.sh 'CONTINUOUS_CLI_USE_LIST_DISCOVERY := 1'
require_anchor test-baseline-working-tree-contract.sh 'Working-tree baseline contract passed.'
require_anchor test-make-path-boundary-v3-red.sh 'v3 RED cases passed with %s.'
require_anchor test-copy-tracked-worktree.sh 'Tracked-worktree copier integrity tests passed.'
require_anchor test-copy-tar-portability.sh 'Tracked-worktree tar portability tests passed.'
require_anchor test-copy-tar-portability-mutation.sh 'Tracked-worktree tar portability mutation was rejected.'
require_anchor test-copy-tar-portability-mutation.sh 'GNU tar destination-path mutation unexpectedly passed'
require_anchor test-run-with-timeout.js 'Portable timeout runner tests passed.'
require_anchor check-descriptor-discovery-bundle.js 'Descriptor discovery production bundle matches source.'
require_anchor check-descriptor-discovery-lint-contract.js 'Descriptor discovery Node globals are imported explicitly.'

if [ "$missing" -ne 0 ]; then
  printf '%s\n' "$missing baseline runner invocation(s) are not wired into check-baseline.sh." >&2
  exit 1
fi

printf '%s\n' 'Baseline runner execution wiring is authoritative.'
