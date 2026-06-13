---
title: Twilio Duplicate Callback Detection
type: test
date: 2026-06-13
status: completed
---

# Twilio Duplicate Callback Detection

## Summary

Make the no-credential Twilio Function harness fail when a handler invokes its
completion callback more than once instead of silently ignoring the duplicate.

## Problem Frame

The shared `invoke` helper currently marks the promise settled on the first
callback and returns early from every later settlement attempt. That protects
global cleanup, but it also lets a double-callback handler pass the main test
path. Direct single-completion tests exist for `private-message`; the reusable
harness itself does not enforce the contract for every function.

## Requirements

- R1. The first callback must stop the missing-callback deadline and retain its
  error/result until duplicate observation completes.
- R2. A second synchronous or near-immediate callback must reject with a clear
  duplicate-completion error.
- R3. A single success or expected-error callback must preserve existing
  assertions and results after the bounded observation window.
- R4. Timeout, synchronous throw, duplicate callback, and normal completion
  must each clear owned timers and restore prior Twilio/Runtime globals once.
- R5. A callback arriving after a missing-callback timeout must remain inert and
  must not overwrite globals restored by a later test.
- R6. Tests, static contracts, and project documentation must preserve the
  duplicate-callback boundary through `npm test` and `make check`.

## Key Technical Decisions

- **Separate deadline and observation timers:** Clear the missing-callback
  timer as soon as the first callback arrives, then use a short bounded timer
  to observe a duplicate before resolving or rejecting from the first result.
- **Snapshot the first callback:** Store the first error/result pair and run
  the existing success/error assertions only after the observation window.
- **Reject through the existing settlement owner:** A duplicate uses the same
  idempotent cleanup path as timeouts and throws, preventing global-state drift.
- **Keep late post-timeout callbacks inert:** Once timeout cleanup settles the
  invocation, later callbacks remain no-ops and cannot affect another fixture.

## Implementation Units

### U1. Add Duplicate Observation To The Harness

- **Files:** `scripts/test-functions.js`
- **Goal:** Track callback count, own both timers, delay first-result settlement
  briefly, and reject a second callback with stable error text.
- **Covers:** R1, R2, R3, R4, R5

### U2. Exercise Immediate And Deferred Duplicates

- **Files:** `scripts/test-functions.js`
- **Goal:** Prove both a synchronous second callback and a zero-delay second
  callback fail while single callbacks and post-timeout callbacks remain safe.
- **Covers:** R2, R3, R5

### U3. Preserve Repository Contracts

- **Files:** `scripts/check-baseline.sh`, `README.md`, `CHANGES.md`, `VISION.md`,
  `AGENTS.md`
- **Goal:** Keep the state-machine source, fixtures, completed plan, and user
  documentation enforced by the existing static and full verification gates.
- **Covers:** R6

## Verification

- Run `node scripts/test-functions.js`, `npm test`, `npm run verify`,
  `make check`, and the absolute-path `make check` wrapper from `/tmp`.
- Run ESLint, shell syntax, whitespace, lockfile, audit, and explicit
  secret/artifact checks.
- Apply isolated hostile mutations for duplicate-count removal, deadline timer
  retention, observation timer removal, duplicate-error drift, missing
  immediate/deferred fixtures, late-callback guard removal, and incomplete plan
  status; each mutation must fail.
- Do not run or claim credentialed Twilio deployment validation.

## Verification Results

- Node 22.22.2 `node scripts/test-functions.js`, `npm test`, `npm run verify`,
  `make check`, and the absolute-path `make check` wrapper from `/tmp` passed.
- Lockfile-pinned ESLint 10.4.1 passed with zero warnings, and `npm audit`
  reported zero known vulnerabilities.
- Shell and Node syntax checks, whitespace validation, lockfile stability, and
  explicit secret/artifact scans passed.
- Eight isolated hostile mutations covering callback counting, deadline timer
  cleanup, the observation window, duplicate-error text, both duplicate
  fixtures, the late-callback guard, and completed-plan status were rejected.
- The default shell runtime is Node 20.19.5, so dependencies were installed
  from the unchanged lockfile and authoritative gates were rerun with the
  installed Node 22.22.2 runtime required by `package.json`.
- Credentialed Twilio deployment was intentionally not executed; functions,
  dependencies, lockfile, and deployment workflows are unchanged.

## Prioritized Follow-Ups

1. Add explicit examples for authentication-protected Twilio Functions without
   broadening the current public sample behavior.
2. Keep Node and Twilio CLI versions deliberate and lockfile-pinned.

## Risks

- The bounded observation window adds a small delay to each local invocation;
  it should remain short enough for fast tests while catching immediate handler
  mistakes deterministically.
- No local harness can observe an arbitrarily late second callback after a test
  has legitimately completed; the contract targets synchronous and
  near-immediate duplicate completion in these small training functions.
