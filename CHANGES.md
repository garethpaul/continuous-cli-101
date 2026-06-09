# Changes

## 2026-06-09

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
