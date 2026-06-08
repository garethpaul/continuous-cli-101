## Continuous CLI 101 Vision

Continuous CLI 101 is a Twilio Serverless and GitHub Actions training sample.
It contains Twilio Functions, static assets, and a workflow that deploys on
push to `main`.

The repository is useful as a compact example of deploying Twilio serverless
code through CI with secrets supplied by GitHub Actions.

The goal is to keep the training project clear, credential-safe, and easy to
adapt for small Twilio CLI workshops.

The current focus is:

Priority:

- Preserve the Twilio Functions and assets as simple examples
- Keep deployment credentials in GitHub Actions secrets
- Make Node and Twilio CLI expectations explicit
- Avoid adding tests that intentionally fail in normal CI paths

Next priorities:

- Add README setup, local run, and deployment instructions
- Replace the placeholder failing `npm test` script with a useful check
- Update Node runtime expectations and workflow actions deliberately
- Add examples for protected functions and private assets

Contribution rules:

- One PR = one focused function, workflow, or documentation change.
- Do not commit Twilio credentials or generated deployment secrets.
- Verify `npm ci` and the relevant Twilio deploy command when changing tooling.
- Keep examples small enough for workshop use.

## Security

Twilio account SIDs, API keys, and API secrets must live in GitHub Actions
secrets or local environment configuration. They must never be committed.

Protected functions and private assets should remain clearly separated from
public browser assets.

## What We Will Not Merge (For Now)

- Committed Twilio credentials or deployment artifacts
- Workflow changes that expose secrets in logs
- Large app features that obscure the CLI training purpose
- Failing placeholder tests left as the default quality gate

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
