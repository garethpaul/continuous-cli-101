---
title: Continuous CLI Check Wrapper
type: chore
status: completed
date: 2026-06-08
---

# Continuous CLI Check Wrapper

## Summary

Expose the Twilio Serverless sample's npm lint, function tests, source checks,
and audit gate through the shared root `make check` command.

## Requirements

- R1. Preserve the existing npm scripts and Node 20 baseline.
- R2. Run lint, no-credential function tests, source checks, and high-severity
  npm audit from the root wrapper.
- R3. Avoid changing function runtime behavior or deployment workflow.
- R4. Document the wrapper in README and CHANGES.

## Verification

- `make check`
- `git diff --check`
