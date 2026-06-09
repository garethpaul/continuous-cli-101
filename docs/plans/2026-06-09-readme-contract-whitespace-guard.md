# README Contract Whitespace Guard

Status: Completed
Date: 2026-06-09

## Goal

Keep source-baseline README contract checks stable when Markdown wraps phrases
across lines.

## Changes

- Normalized README newlines before fixed-string contract checks.
- Kept the private asset coverage sentence readable while preserving the
  enforced phrases.
- Added this plan to the required source-baseline plan list.

## Verification

- `scripts/check-baseline.sh`
- `npm test`
- `npm run lint`
- `make check`
- `git diff --check`
