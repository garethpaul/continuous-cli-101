# Twilio Main-Branch Deployment Guard

## Status: Completed

## Context

The Twilio deploy job already required a manual workflow dispatch and explicit
`confirm_deploy: true` input, but it did not constrain the selected dispatch
ref. A confirmed run against a non-default branch could therefore become
eligible for the credentialed `twilio-development` environment after its verify
job, increasing the chance of deploying unmerged workshop or experiment code.

## Objectives

- Keep verification available on pushes, pull requests, and manual runs.
- Restrict the credentialed deploy job to the exact `refs/heads/main` ref.
- Preserve explicit confirmation, environment protection, serialization,
  read-only repository permissions, and the package-lock-pinned deploy script.
- Keep workflow runners and local Make targets deterministic.
- Do not execute a Twilio deployment during verification.

## Work Completed

- Added the default-branch ref condition to the deploy job alongside manual
  dispatch and confirmation checks.
- Kept the verification job independent of deployment eligibility.
- Fixed both workflow jobs to Ubuntu 24.04 and updated reviewed action version
  annotations without changing their pinned commits.
- Rooted every Makefile npm command with `npm --prefix` so checks work from any
  caller directory.
- Extended the source baseline to enforce the ref condition, both runner pins,
  rooted Make targets, documentation, and completed plan.
- Updated README, VISION, and CHANGES with the deployment eligibility boundary.

## Verification

- `npm ci`
- `npm run verify`
- `make check`
- `make -f /tmp/continuous-cli-101-second-pass/Makefile check`
- Baseline mutation checks for the main-ref condition, runner pins, Makefile
  rooting, documentation, and plan status
- `sh -n scripts/check-baseline.sh`
- `git diff --check`

The credentialed `npm run deploy` command was intentionally not executed.
Deployment still requires the configured GitHub environment and Twilio secrets.

## Follow-Up Candidates

- Configure environment deployment-branch restrictions in GitHub settings as
  an external defense in depth control.
- Require protected-branch status checks or an approval policy appropriate for
  the training environment before production use.
