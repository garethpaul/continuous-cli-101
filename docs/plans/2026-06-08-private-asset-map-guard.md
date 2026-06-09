---
title: Private Asset Map Guard
type: fix
status: completed
date: 2026-06-08
---

# Private Asset Map Guard

## Summary

Keep the private-message Twilio Function on the explicit callback error path
when `Runtime.getAssets()` returns a null asset map.

## Requirements

- R1. The test harness must preserve an explicitly provided null asset map.
- R2. `private-message` must not dereference a null asset map.
- R3. Null and empty asset maps must return the same explicit callback error.
- R4. README, changelog, and source baseline must document the new guard.
- R5. The existing lint, test, source check, and audit gate must remain green.

## Verification

- `npm run lint`
- `npm test`
- `npm run check`
- `npm run audit`
- `npm run verify`
- `git diff --check`
