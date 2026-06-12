---
title: CodeQL Baseline
date: 2026-06-12
status: completed
execution: code
---

# CodeQL Baseline

## Summary

Document and guard the existing GitHub CodeQL default setup for Twilio
JavaScript and GitHub Actions without changing the exact reviewed
verification/deployment workflow or secret scope.

## Requirements

- Preserve GitHub default setup analysis for `actions` and
  `javascript-typescript` as the external security configuration authority.
- Do not add an advanced CodeQL workflow while default setup is active because
  GitHub rejects the conflicting configuration modes.
- Extend exact workflow inventory and checker contracts without weakening the
  existing manual, confirmed, main-only, environment-serialized deploy.
- Preserve package graph, functions, assets, tests, and runtime behavior.
- Pass full local/external gates, audit, YAML parsing, hostile mutations, and
  exact-head hosted Check/CodeQL verification.

## Scope And Verification

Only the static checker, guidance, and evidence change.

## Work Completed

- Recorded that GitHub default setup analyzes Actions and JavaScript/TypeScript.
- Removed the conflicting advanced CodeQL workflow after both of its jobs
  failed while the matching default-setup jobs succeeded.
- Added a contract rejecting extra and advanced CodeQL workflows.
- Preserved `main.yml`, the manual confirmed main-only deployment, package
  graph, functions, assets, tests, and secret scope.

## Verification Completed

- A fresh Node 22.22.2 `npm ci --ignore-scripts` completed with zero audit findings.
- `make check` passed lint, Twilio function tests, contracts, and the
  moderate-severity audit from the repository and an external working directory.
- Focused hostile mutations rejected duplicate CodeQL and extra workflows,
  command, documentation, and incomplete-plan drift; all hostile mutations rejected.
- YAML/shell parsing, `git diff --check`, lockfile stability, and secret scanning passed.

## Hosted Verification

On head `5a1468690fb4e60ce9500ed220490bdfb5eaf46d`, Twilio CI run
`27442276845` succeeded and its deploy job was correctly skipped. Default-setup
CodeQL run `27442276405` succeeded for Actions and JavaScript/TypeScript, while
duplicate advanced run `27442276855` failed for both languages. Exact-head
replacement evidence remains pending after the conflicting workflow removal.
