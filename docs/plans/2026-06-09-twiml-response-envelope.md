# TwiML Response Envelope

Status: Completed
Date: 2026-06-09

## Goal

Keep the local Twilio function test double aligned with Twilio's XML shape by
rendering all message elements inside one response envelope.

## Changes

- Updated the local `MessagingResponse` test double to wrap the whole message
  list in a single `<Response>` element.
- Added a regression assertion for two local TwiML messages in the same
  response.
- Extended the source baseline to require the multi-message assertion, README
  note, and completed plan.
- Documented the response-envelope baseline in the README, changelog, and
  vision.

## Verification

- `scripts/check-baseline.sh`
- `npm run lint`
- `npm test`
- `npm run check`
- `npm run audit`
- `npm run verify`
- `make check`
- `git diff --check`
