---
title: Continuous CLI All-Branch Verification
type: ci
date: 2026-06-17
status: implemented
execution: code
---

# Continuous CLI All-Branch Verification

## Context

The canonical workflow documents verification for pushes and pull requests,
but both event triggers are filtered to `main`. Stacked remediation branches
and pull requests therefore receive no hosted lint, function-test, source
contract, or dependency-audit evidence. The deploy job already has independent
manual confirmation, main-ref, environment, secret, and concurrency guards, so
verification can cover every branch without broadening deployment authority.

## Priorities

1. Restore hosted verification for every push and pull request.
2. Add a Node-version matrix if future runtime compatibility requires more than
   the repository-pinned Node 22 baseline.
3. Exercise credentialed Twilio deployment only through the protected manual
   workflow after maintainer authorization.

This change implements only priority 1 and preserves the single pinned runtime.

## Requirements

- Run the `verify` job for pushes to every branch.
- Run the `verify` job for pull requests targeting any branch, including
  stacked remediation branches.
- Keep `workflow_dispatch` and its required `confirm_deploy` choice unchanged.
- Keep the deploy job restricted to manual dispatch with confirmation on
  `refs/heads/main`.
- Preserve the `twilio-development` environment, environment-scoped secrets,
  read-only repository permissions, immutable action pins, timeouts, and
  serialized deployment concurrency.
- Update the exact workflow fixture and maintained guidance so reintroducing
  event branch filters fails the local gate.
- Do not run or claim a credentialed Twilio deployment.

## Implementation

### Workflow triggers

Update `.github/workflows/main.yml` to declare unfiltered `push` and
`pull_request` events. Do not alter either job body or the deploy `if` guard.

### Contract coverage

Update `scripts/check-baseline.sh` so its canonical workflow fixture matches the
unfiltered events and separately rejects `branches` or `branches-ignore` under
the push and pull-request trigger block.

### Documentation

Update `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, and `CHANGES.md` to
state that verification applies to all branches while deployment remains
manual and main-only.

## Verification

- Run shell syntax and the focused source baseline.
- Run `npm ci --ignore-scripts` and repository/external-directory `make check`.
- Reject isolated mutations that restore either event filter, weaken the deploy
  guard, drift the exact workflow fixture, or remove the guidance contract.
- Audit the exact diff, lockfile, generated artifacts, and credential-shaped
  additions.
- Require exact-head push and pull-request hosted verification success.

## Verification Results

- Shell syntax and the focused workflow source baseline passed.
- Node 22.22.2 repository-root and external-directory `make check` passed
  zero-warning ESLint, all Twilio function tests, exact source contracts, and
  the moderate-severity dependency audit with zero vulnerabilities.
- Seven isolated mutations were rejected across push and pull-request branch
  filters, the deploy main-ref guard, confirmation, protected environment,
  README scope, and plan status.
- `package-lock.json` remained unchanged and no credentialed Twilio deployment
  command was run.
- Exact-head push and pull-request hosted verification remain pending until the
  implementation commit is pushed.

## Risks

- More branches will consume GitHub Actions minutes; the verify job remains
  bounded to ten minutes and uses the pinned Node runtime.
- Pull requests targeting stacked branches will now run the same no-credential
  verification as main-targeting pull requests.
- Deployment remains intentionally unexecuted and requires explicit maintainer
  authorization outside this change.
