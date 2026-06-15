# Twilio Concurrent Harness Isolation

Status: Planned

## Problem

The Node test harness installs invocation-specific `Twilio` and `Runtime`
objects on process globals. Sequential tests restore those globals correctly,
but overlapping `invoke()` calls can replace each other's asset map and restore
the wrong prior values. This makes concurrent function tests nondeterministic
and can allow one invocation to execute with another invocation's fixtures.

## Priorities

1. P0: Prevent overlapping harness invocations from sharing Twilio Runtime
   globals.
2. P1: Preserve timeout, duplicate-callback, synchronous-throw, and global
   restoration behavior for every invocation.
3. P2: Keep the queue usable after a prior invocation rejects.

## Requirements

- Serialize public `invoke()` calls through one harness-local promise tail.
- Start each callback timeout only when that invocation owns the globals, not
  while it waits in the queue.
- Release the queue after both resolved and rejected invocations.
- Add a concurrent regression with distinct private assets and delayed
  callbacks that proves each invocation receives its own fixture.
- Prove original `Twilio` and `Runtime` sentinels are restored after concurrent
  completion and after a queued predecessor rejects.
- Add mutation-sensitive queue, fixture, guidance, and completed-plan contracts.

## Scope Boundaries

- Do not change production Twilio functions, assets, deployment behavior,
  package versions, lockfiles, workflows, or public response payloads.
- Preserve the existing 5-second default callback deadline and duplicate-call
  observation window.
- Do not run or claim a credentialed Twilio deployment.
- Do not merge or close stacked pull requests without explicit authorization.

## Implementation Units

1. Split the current invocation body into an isolated execution function and a
   serialized public wrapper in `scripts/test-functions.js`.
2. Add concurrent private-asset and post-rejection queue recovery scenarios in
   `scripts/test-functions.js` and focused fixtures under `scripts/fixtures/`.
3. Extend `scripts/check-baseline.sh` and maintained guidance to protect the
   concurrency boundary and completed evidence.

## Verification

- JavaScript syntax checks and focused function tests
- pinned `npm run verify` and repository/external-directory `make check`
- hostile serialization, queue-recovery, concurrent-fixture, guidance, plan
  status, and verification-evidence mutations
- exact-diff, dependency/workflow-drift, generated-artifact, credential-pattern,
  conflict-marker, and whitespace audits
