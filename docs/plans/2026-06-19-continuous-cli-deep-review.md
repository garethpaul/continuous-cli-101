# Continuous CLI Deep Review

Status: Completed

## Scope

Review the stacked maintenance work in pull requests #1 through #9 across the
Twilio function harness, dependencies, workflow triggers, deployment boundary,
and repository verification contracts.

## Finding

The callback harness observed synchronous throws but ignored a handler's
returned Promise. An async handler rejection therefore waited for the callback
timeout, while a Promise rejected after callback could become an unhandled
rejection. The behavior originated in the first callback harness commit
`8f976546` and was carried through the timeout and concurrency remediations.

## Fix

Capture the handler return value and attach a rejection observer to it. Route
that failure through the existing exactly-once settlement owner so timers and
process-global Twilio fixtures are restored once. Preserve callback ownership:
a resolved Promise does not complete the invocation, and a rejection after an
already-settled invocation is observed but cannot settle it again.

## Evidence

- Red-first regressions reproduced immediate async rejection and a callback
  racing a returned rejected Promise.
- A hostile queue-removal mutation exposed a weak concurrency scenario; a new
  overlapping delayed-fixture regression now rejects that mutation.
- The focused function suite, lint, source contracts, dependency audit, and
  external-root Make gate pass on supported Node 22 releases.
- Both transitive `form-data` lines remain on patched releases, the npm lock is
  reproducible, and the canonical workflow keeps no-credential verification on
  every branch while deployment remains manual, confirmed, environment-scoped,
  serialized, and main-only.

## Residual Risk

No credentialed Twilio request or deployment was performed. Live Twilio
callback scheduling, provider authentication, environment approval, and remote
deployment behavior still require an authorized development account.
