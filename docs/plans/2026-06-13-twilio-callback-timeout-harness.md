---
title: Twilio Callback Timeout Harness
type: test
date: 2026-06-13
---

# Twilio Callback Timeout Harness

## Summary

Make the local Twilio function harness fail deterministically when a handler
never invokes its completion callback, preventing silent or hanging
false-green test runs.

## Problem Frame

`invoke` waits on a Promise that resolves only from a Twilio callback. If a
handler returns without invoking that callback, the Promise remains pending but
does not itself keep Node's event loop alive. The process can therefore exit
without proving handler completion.

## Requirements

- R1. Every `invoke` call must have a bounded callback deadline with a stable,
  descriptive timeout error.
- R2. Callback success and error paths must clear the deadline before settling.
- R3. Synchronous handler exceptions must clear the deadline and restore the
  prior Twilio globals before rejection.
- R4. A callback arriving after timeout or another settlement must not restore
  globals or settle the Promise again.
- R5. The test suite must execute a handler that never calls back and assert the
  timeout failure.
- R6. The repository contract must enforce the timeout implementation, the
  never-callback fixture, and synchronized maintenance documentation.

## Key Technical Decisions

- **Keep timeout ownership inside `invoke`:** The harness already owns global
  setup and Promise settlement, so it is the only place that can reliably
  coordinate timeout cleanup and restoration.
- **Allow a per-invocation timeout override:** Production-like tests use a
  conservative default, while the deliberate never-callback regression uses a
  short timeout to keep the suite fast.
- **Use one settlement guard:** Success, callback error, synchronous throw, and
  timeout all pass through a shared completion boundary so cleanup happens at
  most once.
- **Do not change function runtime behavior:** `functions/` remains untouched;
  this task strengthens verification rather than adding runtime timeouts.

## Implementation Units

### U1. Bound Harness Callback Completion

- **Files:** `scripts/test-functions.js`
- **Goal:** Add a default timeout, configurable override, one settlement guard,
  timer cleanup, and exactly-once global restoration for all invoke outcomes.
- **Covers:** R1, R2, R3, R4

### U2. Prove Missing Callback Failure

- **Files:** `scripts/test-functions.js`, `scripts/check-baseline.sh`
- **Goal:** Run a never-callback handler, assert the stable timeout message, and
  enforce the harness contract statically.
- **Covers:** R5, R6

### U3. Record The Verification Boundary

- **Files:** `README.md`, `CHANGES.md`, `VISION.md`
- **Goal:** Document bounded callback verification and retain the explicit
  no-credentialed-deploy boundary.
- **Covers:** R6

## Verification

- Run `npm test`, `npm run lint`, `npm run check`, `npm run audit`, `make check`,
  and the absolute-path `make check` wrapper from an external directory.
- Confirm `npm audit --json` reports zero known vulnerabilities and direct
  dependency versions remain unchanged.
- Apply isolated hostile mutations for timeout removal, missing timer cleanup,
  duplicate settlement, omitted never-callback execution, timeout-message
  drift, and documentation contracts; each mutation must fail.
- Do not execute the credentialed Twilio deployment workflow or claim hosted
  deployment validation.

## Prioritized Follow-Ups

1. Add explicit timeout/settlement coverage for asynchronous handler fixtures
   if the training sample introduces asynchronous functions.
2. Replace deprecated transitive packages when a maintained `twilio-run`
   release removes them without changing the supported deploy contract.

## Risks

- A deadline that is too short could make legitimate asynchronous tests flaky;
  the default remains conservative and only the intentional failure fixture
  uses the short override.
- This harness timeout detects missing local callbacks but does not configure
  Twilio's hosted function execution timeout.
