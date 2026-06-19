---
title: Make Root Override Protection
type: reliability
status: completed
date: 2026-06-14
---

# Make Root Override Protection

## Status: Completed

## Problem Frame

The Makefile derives its root from `MAKEFILE_LIST`, but a command-line `ROOT`
assignment still takes precedence and can redirect the pinned npm verification
gate outside the checkout.

## Scope Boundaries

- Protect only the repository-derived `ROOT`; preserve the intentional `NPM`
  override.
- Preserve Node 22, pinned packages, lint, callback tests, source contracts,
  moderate-severity audit, workflows, and deployment guards.
- Do not run credentialed Twilio deployment or alter secrets.

## Requirements

- R1. A hostile `ROOT` variable must not redirect any Make target.
- R2. Repository and external-working-directory verification must pass.
- R3. The baseline checker must reject an overrideable root assignment.
- R4. Completed plan evidence and isolated mutations must be enforced.

## Verification

- `sh -n scripts/check-baseline.sh` and `node --check
  scripts/test-functions.js` passed.
- All four Make gates passed through `make lint`, `make test`, `make build`,
  and `make check`; the check gate retained the pinned moderate-severity npm
  audit.
- `npm run verify` passed with ESLint 10.5.0, all callback harness cases, source
  contracts, and zero reported package vulnerabilities.
- `make ROOT=/tmp check` passed and still used the repository package root.
- The full gate passed from `/tmp` through the absolute Makefile path, covering
  the external working directory.
- Four isolated hostile mutations were rejected: overrideable root, missing
  plan, reopened plan, and missing verification evidence.
- `git diff --check`, intended-path review, artifact inspection, and the
  changed-line secret scan passed.
- No credentialed Twilio deployment was run.
