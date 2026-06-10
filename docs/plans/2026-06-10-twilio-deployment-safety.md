# Twilio Deployment Safety

Status: Completed

## Goal

Reduce accidental or supply-chain deployment risk while preserving the
existing manually triggered Twilio Serverless release flow.

## Requirements

- Verification and deployment jobs use immutable action commits, read-only
  repository permissions, non-persisted checkout credentials, and bounded
  timeouts.
- A manual workflow run does not deploy unless the operator explicitly selects
  `confirm_deploy: true`.
- Twilio deployments use a named GitHub environment and cannot overlap.
- The workflow continues using the package-lock-pinned `twilio-run` command.
- ESLint dependencies are direct and current, and dependency auditing fails for
  moderate or more severe advisories.
- Node 22 is the supported runtime shared by local scripts and CI.

## Implementation

- Pin current v6 `actions/checkout` and `actions/setup-node` releases to commit
  SHAs and disable persisted checkout credentials.
- Add confirmation input, `twilio-development` environment scope, and deploy
  concurrency controls.
- Add job timeouts and workflow-level read-only permissions.
- Upgrade ESLint and tighten exact dependency pins.
- Move `.nvmrc` and package engine metadata to Node 22.
- Extend `scripts/check-baseline.sh` to enforce every safety contract.

## Verification

- `npm ci`
- `npm run verify`
- Negative workflow contract tests
- `npm outdated`
- `npm audit --audit-level=moderate`
- `git diff --check`

The credentialed deploy command is intentionally not executed locally or from
automated pull-request validation.
