# Changes

## 2026-06-25

- Added concrete `npm start` local-server instructions and documented the
  no-credential local verification boundary.
- Added exact manual GitHub Actions deployment steps, required environment
  secrets, main-branch eligibility, confirmation, environment protection, and
  guidance against bypassing workflow safety with an ad hoc real-account deploy.

## 2026-06-24

- Routed GNU Make 3.82 through recipe-time `MAKEFILE_LIST` discovery instead
  of expanding the GNU Make 4.0-only `file` function during parsing.
- Preserved dollar-containing direct `-f` paths through bounded Linux ancestor
  argument discovery when GNU Make 3.82's list variable loses those bytes.
- Added a legacy-version routing regression and included it in baseline and
  shallow-clone integrity verification.
- Passed the full hostile path matrix with GNU Make 3.82 and the complete Node
  22 `npm run verify` gate, including the zero-vulnerability audit.
- Limited exact-HEAD verifier integrity enforcement to copied shallow
  snapshots so staged pre-commit verifier changes can run the documented gate.
- Replaced the descriptor stress tests' GNU `timeout` dependency with a
  checked-in Node runner that works on stock macOS and Linux hosts.
- Replaced GNU-only `base64 -d` channel decoding with Node decoding and added
  a regression that rejects the GNU decode flag while exercising Make.
- Re-ran Codex review after the initial pull-request head; the review identified
  the 3.82 compatibility regression before merge.

## 2026-06-19

- Made the Twilio harness observe returned Promise rejections so async handler
  failures cannot hang until the callback deadline or escape after callback
  completion as unhandled rejections.
- Strengthened concurrent fixture coverage so removing invocation serialization
  produces a real overlapping Runtime-state failure.

## 2026-06-17

- Restored no-credential verification for pushes and pull requests on every
  branch while preserving confirmed, environment-protected deployment only
  from `refs/heads/main`.

## 2026-06-15

- Locked both transitive form-data lines on CRLF-safe releases and added a
  structural lockfile regression gate for GHSA-hmw2-7cc7-3qxx.

## 2026-06-13

- Serialized concurrent Twilio harness invocations so each test owns its Runtime
  fixtures and the queue recovers after rejected handlers.
- Upgraded the package-lock-pinned lint toolchain from ESLint 10.4.1 to 10.5.0
  under the existing Node 22 runtime and zero-warning policy.
- Made the shared Twilio harness reject synchronous and near-immediate duplicate
  callbacks instead of silently accepting the first completion.
- Separated the missing-callback deadline from a bounded duplicate-observation
  timer while preserving exactly-once global restoration and late-callback
  isolation.
- Prevented false-green missing-callback tests by adding a bounded completion
  deadline to every local Twilio handler invocation.
- Added regression coverage for never-called, late, and synchronously failing
  callback paths with exactly-once timer cleanup and global restoration.

## 2026-06-12

- Documented GitHub CodeQL default setup for Actions and Twilio JavaScript and
  rejected a conflicting advanced workflow without broadening deployment secrets.
- Refactored `private-message` validation to flow through one error completion
  site and moved successful completion outside the catchable computation block.
- Added regression coverage proving throwing success and error callbacks are
  each invoked exactly once.
- Covered non-throwing error callbacks so a missing return cannot fall through
  into a second success completion.
- Required one canonical Twilio workflow and rejected additional workflow files.

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
