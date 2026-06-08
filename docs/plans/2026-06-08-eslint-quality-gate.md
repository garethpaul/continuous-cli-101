---
title: ESLint Quality Gate
type: chore
status: completed
date: 2026-06-08
---

# ESLint Quality Gate

## Summary

Add a zero-warning ESLint gate for the checked-in JavaScript assets, Twilio
Functions, and local test harness, then make the existing CI `verify` command
run lint before tests, source checks, and dependency audit.

## Requirements

- R1. `npm run lint` must lint `assets`, `functions`, and `scripts`.
- R2. The lint gate must fail on warnings.
- R3. The ESLint config must recognize CommonJS, Node globals, and Twilio
  Serverless runtime globals used by the sample functions.
- R4. `npm run verify` must run lint before tests and source checks.
- R5. README, CHANGES, and source baseline checks must document and preserve
  the new gate.

## Verification

- `npm run lint`
- `npm test`
- `npm run check`
- `npm run audit`
- `npm run verify`
