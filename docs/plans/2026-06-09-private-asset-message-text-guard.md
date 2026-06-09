# Private Asset Message Text Guard

Status: Completed
Date: 2026-06-09

## Goal

Keep malformed private `/message.js` asset output from being rendered into the
`private-message` TwiML response.

## Changes

- Required the private asset function to return a non-empty string before
  creating the TwiML response.
- Added a blank-message fixture and local harness assertion for the new callback
  error.
- Extended the source baseline, README, changelog, and vision with the private
  message text contract.

## Verification

- `npm test`
- `scripts/check-baseline.sh`
- `npm run lint`
- `npm run check`
- `npm run audit`
- `npm run verify`
- `make check`
- `git diff --check`
