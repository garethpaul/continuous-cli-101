# Form Data CRLF Remediation

Status: Completed

## Problem

The committed dependency graph resolves `form-data` 2.5.5 through
`@twilio-labs/serverless-api` and 4.0.5 through `axios`. Both releases are
affected by GHSA-hmw2-7cc7-3qxx, which allows CRLF injection through
unescaped multipart field names or filenames. The parent dependency ranges
already permit patched releases, but the lockfile keeps clean installs on the
vulnerable graph.

## Priorities

1. P0: Resolve every locked `form-data` package to a release that contains the
   CRLF validation fix.
2. P1: Preserve the existing `twilio-run` dependency and application behavior.
3. P2: Reject future lockfile regressions before installation or deployment.

## Requirements

- Refresh only the transitive lockfile resolutions permitted by the current
  parent dependency ranges.
- Require the 2.x dependency line to resolve to at least 2.5.6 and the 4.x
  dependency line to resolve to at least 4.0.6.
- Parse `package-lock.json` structurally in the baseline gate and reject every
  vulnerable `form-data` package entry.
- Preserve lint, function tests, source contracts, and a zero
  moderate-or-higher `npm audit` result.
- Add mutation-sensitive contracts for both vulnerable version lines, plan
  completion, and verification evidence.

## Scope Boundaries

- Do not change production Twilio functions, response payloads, workflows,
  direct package versions, or credentialed deployment behavior.
- Do not add a dependency override when the existing parent ranges accept the
  patched releases.
- Do not run or claim a credentialed Twilio deployment.
- Do not merge or close stacked pull requests without explicit authorization.

## Implementation Units

1. Refresh the `package-lock.json` transitive `form-data` resolutions.
2. Extend `scripts/check-baseline.sh` with a structural vulnerable-version
   guard and completed-plan evidence contracts.
3. Record the remediation in maintained guidance and this plan.

## Verification

- lockfile-pinned install, lint, focused function tests, source contracts, and
  zero moderate-or-higher dependency audit
- repository and external-directory `make check`
- hostile 2.x, 4.x, lockfile-gate, plan-status, and verification-evidence
  mutations
- exact-diff, direct-dependency/workflow-drift, generated-artifact,
  credential-pattern, conflict-marker, and whitespace audits

## Verification: Completed

- A clean lockfile-pinned install under Node 22.22.2 resolved `form-data`
  2.5.6 and 4.0.6, and `npm run verify` passed lint, all function tests,
  source contracts, and a zero moderate-or-higher dependency audit.
- Repository and external-directory `make check` gates passed.
- Six isolated hostile form-data mutations were rejected across the 2.x and
  4.x versions, required lock nodes, maintained guidance, plan status, and
  verification evidence.
- Exact-diff, direct-dependency/workflow-drift, generated-artifact,
  credential-pattern, conflict-marker, whitespace, and shell-syntax audits
  passed.
- No credentialed Twilio deployment was run.
