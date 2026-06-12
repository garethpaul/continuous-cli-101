---
title: CodeQL Baseline
date: 2026-06-12
status: completed
execution: code
---

# CodeQL Baseline

## Summary

Add pinned static analysis for Twilio JavaScript and GitHub Actions without
changing the exact reviewed verification/deployment workflow or secret scope.

## Requirements

- Analyze `actions` and `javascript-typescript` on pushes, pull requests,
  schedules, and manual dispatches with no-build mode.
- Use immutable actions, exact least-privilege result-upload permissions,
  non-persisted checkout credentials, bounded runtime, and cancellation.
- Extend the exact workflow inventory and checker contracts without weakening
  the existing manual, confirmed, main-only, environment-serialized deploy.
- Preserve package graph, functions, assets, tests, and runtime behavior.
- Pass full local/external gates, audit, YAML parsing, hostile mutations, and
  exact-head hosted Check/CodeQL verification.

## Scope And Verification

Only the CodeQL workflow, static checker, guidance, and evidence change.

## Work Completed

- Added pinned no-build CodeQL analysis for Actions and JavaScript/TypeScript.
- Added a byte-for-byte workflow contract with exact permissions, credentials,
  languages, triggers, schedule, action pins, timeout, and concurrency.
- Preserved `main.yml`, the manual confirmed main-only deployment, package
  graph, functions, assets, tests, and secret scope.

## Verification Completed

- A fresh Node 22.22.2 `npm ci --ignore-scripts` completed with zero audit findings.
- `make check` passed lint, Twilio function tests, contracts, and the
  moderate-severity audit from the repository and an external working directory.
- Focused hostile mutations rejected language, pin, permission, credential,
  command, documentation, and incomplete-plan drift; all hostile mutations rejected.
- YAML/shell parsing, `git diff --check`, lockfile stability, and secret scanning passed.

## Hosted Verification

Exact-head Twilio CI and CodeQL evidence will be recorded after push. Tracker
reconciliation remains pending until both are terminal green.
