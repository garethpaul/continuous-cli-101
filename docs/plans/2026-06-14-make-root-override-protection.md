---
title: Make Root Override Protection
type: reliability
status: in_progress
date: 2026-06-14
---

# Make Root Override Protection

## Status: In Progress

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

Pending implementation and validation.
