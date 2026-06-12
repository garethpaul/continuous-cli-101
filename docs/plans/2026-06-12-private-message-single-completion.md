# Private Message Single Completion

## Status: Completed

## Goal

Ensure the private-message Twilio Function invokes its completion callback at
most once, even when the callback itself throws.

## Problem

The handler currently invokes validation and success callbacks inside one outer
`try` block. If a callback throws, the catch treats that callback failure as a
handler failure and invokes the same callback again. Twilio Function callbacks
are completion signals and must not receive both an initial completion and a
second error completion for one invocation.

## Scope

- Convert private-asset validation failures into thrown errors inside the
  handler's protected computation block.
- Invoke the error callback once from `catch` and return.
- Invoke the success callback only after leaving the `try/catch`.
- Add direct tests proving throwing success and error callbacks are each called
  exactly once.
- Extend the baseline and maintenance documentation for the completion
  contract.

## Out Of Scope

- Changing private asset lookup, message text, TwiML shape, or deployment flow.
- Swallowing callback exceptions or changing the other training functions.
- Updating dependencies, which are current and audit-clean in this pass.

## Verification

- `npm test`
- `npm run lint`
- `npm run verify`
- `make check`
- `sh -n scripts/check-baseline.sh`
- Targeted mutation checks
- `git diff --check`

The credentialed Twilio deployment command remains intentionally unexecuted.
