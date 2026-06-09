# Private Asset Path Guard

Status: Completed
Date: 2026-06-09

## Goal

Keep `private-message` from passing missing, non-string, or blank private asset
paths into `require()`.

## Changes

- Validated that the `/message.js` private asset path is a non-blank string
  before module loading.
- Added local harness coverage for a blank private asset path.
- Extended the source baseline to require path validation and test coverage.
- Documented the private asset path contract in the README, changelog, and
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
