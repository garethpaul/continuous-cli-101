# TwiML Harness Escaping

Status: Completed
Date: 2026-06-09

## Goal

Keep the local Twilio function harness from producing unsafe or invalid XML
when message bodies contain XML special characters.

## Changes

- Added XML entity escaping to the local `MessagingResponse` test double.
- Added an assertion for ampersand, angle bracket, double-quote, and apostrophe
  escaping.
- Extended the source baseline to require the escaping helper, coverage, and
  completed plan.
- Documented the harness behavior in the README, changelog, and vision.

## Verification

- `scripts/check-baseline.sh`
- `npm run lint`
- `npm test`
- `npm run check`
- `npm run audit`
- `npm run verify`
- `make check`
- `git diff --check`
