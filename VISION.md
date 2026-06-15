## Continuous CLI 101 Vision

This document explains the current state and direction of the project.
Project overview and developer docs: [`README.md`](README.md)

Continuous CLI 101 is a Twilio Serverless and GitHub Actions training sample.
It contains Twilio Functions, static assets, and a workflow that verifies
pushes while reserving deployment for manual `workflow_dispatch` runs.

The repository is useful as a compact example of deploying Twilio serverless
code through CI with secrets supplied by GitHub Actions.

The goal is to keep the training project clear, credential-safe, and easy to
adapt for small Twilio CLI workshops.

The current focus is:

Priority:

- Preserve the Twilio Functions and assets as simple examples
- Keep deployment credentials in GitHub Actions secrets
- Keep private asset contracts explicit in local function tests
- Keep private asset paths validated before module loading
- Keep private asset module loading constrained to absolute Runtime paths
- Keep private asset module loading constrained to file paths
- Keep private asset message output validated before TwiML rendering
- Keep each Twilio Function invocation limited to one completion callback
- Make local verification reject immediate duplicate completion callbacks
- Keep local time-bounded Twilio callback verification fail-closed
- Keep concurrent local Twilio invocations isolated from process-global fixtures
- Keep multipart dependencies on CRLF-safe releases
- Keep local TwiML harness output escaped like production XML
- Keep local TwiML harness responses shaped like production XML envelopes
- Make Node and Twilio CLI expectations explicit
- Keep manual deploy tooling tied to package-lock-pinned dependencies
- Keep Twilio deployment behind explicit confirmation, a named environment,
  and serialized execution
- Keep credentialed deployment restricted to the default branch ref
- Keep workflow actions commit-pinned and repository access read-only
- Keep CodeQL default-setup coverage for Actions and Twilio JavaScript
- Keep the ESLint release exact, current, and verified under the supported Node
  runtime
- Keep lint, test, and audit gates useful in normal CI paths

Next priorities:

- Add README setup, local run, and deployment instructions
- Update Node runtime expectations and workflow actions deliberately
- Add examples for protected functions and private assets

Contribution rules:

- One PR = one focused function, workflow, or documentation change.
- Do not commit Twilio credentials or generated deployment secrets.
- Verify `npm run verify` and the relevant Twilio deploy command when changing tooling.
- Keep examples small enough for workshop use.

## Security

Canonical security policy and reporting:

- [`SECURITY.md`](SECURITY.md)

Twilio account SIDs, API keys, and API secrets must live in GitHub Actions
secrets or local environment configuration. They must never be committed.

Protected functions and private assets should remain clearly separated from
public browser assets.

## What We Will Not Merge (For Now)

- Committed Twilio credentials or deployment artifacts
- Workflow changes that expose secrets in logs
- Large app features that obscure the CLI training purpose
- Failing placeholder tests or disabled lint left as the default quality gate

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
