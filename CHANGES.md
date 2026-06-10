# Changes

## 2026-06-10

- Restricted confirmed manual Twilio deployments to `refs/heads/main` while
  preserving verification on other refs.
- Made Makefile npm commands location-independent and pinned both workflow jobs
  to the stable Ubuntu 24.04 runner image.
- Pin GitHub Actions to immutable commits and declare read-only repository
  permissions plus bounded job timeouts.
- Require explicit confirmation before the manual Twilio deploy job can run,
  scope it to the `twilio-development` environment, and serialize deployments.
- Upgrade ESLint to 10.4.1, declare `@eslint/js` directly, pin `twilio-run`, and
  raise the npm audit gate from high to moderate severity.
- Move the supported runtime from Node 20 to Node 22 and update checkout and
  Node setup actions to current immutable v6 commits without persisted Git
  credentials.

## 2026-06-09

- Updated the local TwiML test double to render multiple messages inside one
  `<Response>` envelope.
- Rejected directory or missing-file private `/message.js` asset paths before
  module loading and covered the directory-path case in the local harness.
- Made README contract checks tolerate normal Markdown line wrapping.
- Rejected relative private `/message.js` asset paths before module loading and
  covered the relative-path case in the local harness.
- Rejected missing, non-string, and blank private `/message.js` asset paths
  before module loading and covered the blank-path case in the local harness.
- Added a callback error and local fixture coverage for private `/message.js`
  assets that return blank or non-string message output.
- Updated the local TwiML test harness to XML-escape message bodies and assert
  escaping for special characters.
- Switched the manual GitHub Actions deploy step to the package-lock-pinned
  `npm run deploy` script instead of global Twilio CLI/plugin installs.
- Added an explicit callback error when the private `/message.js` asset does
  not export the expected function.
- Added local harness coverage and a fixture for malformed private asset
  exports, plus source-baseline and README guardrails.

## 2026-06-08

- Added `make check` as the root wrapper for lint, function tests, source
  checks, and the high-severity npm audit gate.
- Guarded the private-message function when Twilio Runtime returns a null
  asset map and covered it in the local harness.
- Replaced the failing placeholder test command with a no-credential Twilio
  Function harness and a combined `npm run verify` gate.
- Updated the project baseline to Node 20 and `twilio-run` 5.x with a refreshed
  lockfile.
- Added an explicit callback error when the private message asset is missing.
- Updated GitHub Actions to verify pushes and pull requests while reserving
  credentialed Twilio deployment for manual `workflow_dispatch` runs.
- Added an ESLint flat config and included the zero-warning lint gate in
  `npm run verify`.
