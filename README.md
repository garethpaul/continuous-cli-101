# continuous-cli-101

<!-- README-OVERVIEW-IMAGE -->
![Project overview](docs/readme-overview.svg)

## Overview

`garethpaul/continuous-cli-101` is a Twilio Serverless training sample with a
GitHub Actions deployment workflow.

This README is based on the checked-in source, manifests, scripts, and repository metadata on the `main` branch. The project language mix found during review was: JavaScript (4).

## Repository Contents

- `README.md` - project overview and local usage notes
- `package.json` - JavaScript dependency and script metadata
- `.github` - source or example code
- `assets` - source or example code
- `functions` - source or example code
- `package-lock.json` - JavaScript dependency and script metadata
- `SECURITY.md` - security reporting and disclosure guidance
- `VISION.md` - project direction and maintenance guardrails

Additional scan context:

- Source directories: .github, assets, functions
- Dependency and build manifests: package-lock.json, package.json
- Entry points or build surfaces: package.json
- Test harness: `scripts/test-functions.js`

## Getting Started

### Prerequisites

- Git
- Node.js 22, matching `.nvmrc`
- npm

### Setup

```bash
git clone https://github.com/garethpaul/continuous-cli-101.git
cd continuous-cli-101
npm ci
```

The setup commands above are derived from repository files. Legacy mobile, Python, or JavaScript samples may require older SDKs or package versions than a modern workstation uses by default.

## Running or Using the Project

- Run `npm start` for the default development command.

Detected npm scripts:

- `npm run audit` - `npm audit --audit-level=moderate`
- `npm run check` - `scripts/check-baseline.sh`
- `npm run deploy` - `twilio-run deploy`
- `npm run lint` - `eslint assets functions scripts --max-warnings=0`
- `npm run start` - `twilio-run`
- `npm run test` - `node scripts/test-functions.js`
- `npm run verify` - `npm run lint && npm test && npm run check && npm run audit`

## Testing and Verification

Run the local function harness before changing or deploying functions:

```bash
make check
npm run lint
npm test
npm run check
npm run audit
npm run verify
```

`npm run lint` runs package-lock-pinned ESLint `10.5.0` under Node 22 against
the checked-in JavaScript assets, functions, and test scripts with zero warnings
allowed.

The test harness stubs the Twilio Runtime and TwiML response classes, so it
does not require Twilio credentials, network access, or a deployment. It covers
the public JSON function, protected SMS reply, private asset message, and the
missing private asset error path. Those tests include a null Runtime asset map,
a blank private asset path, a relative private asset path, and
a directory private asset path, and a malformed private asset export.
It also covers blank private asset message output before it can reach TwiML.
The harness XML-escapes local TwiML message bodies so special characters are
represented safely in the output.
It renders multiple local TwiML messages inside one Response envelope to keep
the local test double aligned with Twilio's response shape.
It verifies that non-throwing error callbacks complete once without falling
through to the success callback. Throwing success and error callbacks also
propagate their sentinel after one completion.
Every harness invocation has a bounded callback deadline, so a function that
never completes fails explicitly instead of allowing a false-green Node exit.
Timeout and synchronous-failure paths restore the prior Twilio globals, and a
late callback cannot settle or restore them again.
The harness also holds the first callback for a short bounded observation
window and fails when a handler invokes a synchronous or near-immediate second
callback instead of silently accepting duplicate completion.
Concurrent harness invocations are serialized before installing process-global Twilio fixtures.

`npm run check` runs `scripts/check-baseline.sh` for source-only guardrails.
`npm run verify` runs lint, tests, source checks, and the moderate-severity npm
audit gate in the same order used by CI.
GitHub CodeQL default setup analyzes the GitHub Actions and
JavaScript/TypeScript surfaces. It is intentionally not duplicated by an
advanced workflow and does not broaden the manual Twilio deployment secret
boundary.

When the required SDK or runtime is unavailable, use static checks and source review first, then verify on a machine that has the matching platform toolchain.

## Configuration and Secrets

- Twilio account SIDs, API keys, and API secrets must live in GitHub Actions
  secrets or local environment variables only.
- GitHub Actions provides verification for pushes and pull requests on every branch. Twilio
  deployment is only available through a manual `workflow_dispatch` run that
  explicitly selects `confirm_deploy: true` and only deploys from refs/heads/main.
- The manual deploy job uses the package-lock-pinned deploy script instead of
  installing the latest global Twilio CLI and plugin during CI.
- Deployment uses the `twilio-development` GitHub environment, serializes
  deploy runs, keeps repository permissions read-only, and does not persist the
  workflow token in the checkout.
- Root Makefile targets run npm with the repository as their explicit prefix,
  including out-of-tree `make -f` verification.

## Security and Privacy Notes

- Review changes touching external API calls or credential-adjacent configuration; examples from the scan include .github/workflows/main.yml, assets/index.html, functions/private-message.js, functions/sms/reply.protected.js, and 1 more.
- Review changes touching network requests, sockets, or service endpoints; examples from the scan include assets/index.html.

## Maintenance Notes

- Keep ESLint pinned to the verified `10.5.0` package artifact under Node 22;
  see `docs/plans/2026-06-13-eslint-10-5-upgrade.md` for the completed upgrade
  evidence.
- Manual Twilio deployment should continue to call the package-lock-pinned
  `npm run deploy` script from the workflow.
- Private `/message.js` assets must export a function that returns a non-empty
  string from a non-blank absolute file asset path before `private-message`
  adds it to TwiML.
- `private-message` computes its result before completing, with one error and
  one success callback site outside each other's exception boundary.
- The local TwiML harness keeps all message elements inside one response
  envelope, including multi-message fixtures.
- See `SECURITY.md` for vulnerability reporting and safe research guidance.
- See `VISION.md` for project direction and contribution guardrails.
- See `CHANGES.md` for maintenance history.
- See `docs/plans/2026-06-09-private-asset-message-text-guard.md` for private
  asset message text validation.
- See `docs/plans/2026-06-09-private-asset-path-guard.md` for private asset
  path validation.
- See `docs/plans/2026-06-09-private-asset-absolute-path-guard.md` for private
  asset absolute path validation.
- See `docs/plans/2026-06-09-private-asset-file-path-guard.md` for private
  asset file path validation.
- See `docs/plans/2026-06-09-readme-contract-whitespace-guard.md` for
  line-wrap-tolerant README contract checks.
- See `docs/plans/2026-06-09-twiml-response-envelope.md` for the local TwiML
  response envelope baseline.
- See `docs/plans/2026-06-08-continuous-cli-check-wrapper.md` for the root
  verification wrapper baseline.
- See `docs/plans/2026-06-10-twilio-deployment-safety.md` for the Node 22,
  dependency, and manual deployment safety baseline.
- See `docs/plans/2026-06-10-twilio-main-branch-deploy-guard.md` for the
  default-branch deployment eligibility guard.
- See `docs/plans/2026-06-13-twilio-callback-timeout-harness.md` for bounded
  local callback completion verification.

## Contributing

Keep changes small and tied to the project that is already present in this repository. For code changes, document the toolchain used, avoid committing generated dependency directories or local configuration, and update this README when setup or verification steps change.
