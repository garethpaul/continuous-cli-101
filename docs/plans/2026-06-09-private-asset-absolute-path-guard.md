# Private Asset Absolute Path Guard

Status: Completed
Date: 2026-06-09

## Goal

Keep `private-message` from requiring malformed private asset paths by accepting
only absolute paths from Twilio Runtime asset metadata.

## Changes

- Added Node path helper validation before requiring `/message.js`.
- Rejected relative private asset paths with the existing unavailable-asset
  callback error.
- Added local harness coverage for a relative private asset path.
- Extended the source baseline and documentation to enforce the absolute-path
  contract.

## Verification

- `scripts/check-baseline.sh`
- `npm test`
- `npm run lint`
- `make check`
- `git diff --check`
