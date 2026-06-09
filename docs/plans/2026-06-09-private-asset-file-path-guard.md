# Private Asset File Path Guard

Status: Completed
Date: 2026-06-09

## Goal

Keep `private-message` from passing non-file private asset paths into
`require()`, which can expose low-level module loading errors and filesystem
paths to callers.

## Changes

- Added `fs.statSync(...).isFile()` and `fs.accessSync(..., fs.constants.R_OK)`
  validation before requiring `/message.js`.
- Returned the existing generic missing-asset callback error when the Runtime
  path is a directory, missing file, or otherwise unreadable.
- Added local harness coverage for a directory private asset path.
- Extended the static baseline and README notes to enforce file-path
  validation.

## Verification

- `npm test`
- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
