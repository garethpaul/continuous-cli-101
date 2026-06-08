---
title: Twilio Function Test Baseline
type: fix
status: completed
date: 2026-06-08
---

# Twilio Function Test Baseline

## Summary

Replace the placeholder failing test script with a deterministic Node-based
Twilio Function harness, document the new verification flow, align the
toolchain with the `twilio-run` 5.x Node 20 baseline, make credentialed
deployment manual, and make the private asset function fail through the Twilio
callback contract when its private message asset is unavailable.

---

## Problem Frame

The repository contains small Twilio Serverless functions, but `npm test`
exits with `Error: no test specified`. That makes the default quality gate fail
even for source-only edits. The `private-message` function also assumes
`Runtime.getAssets()['/message.js']` is always present and throws if the asset
is missing, which bypasses the normal callback error path. The workflow also
deployed on every push to `main`, mixing routine verification with a
credentialed side effect.

---

## Requirements

- R1. `npm test` must run a real deterministic check without Twilio
  credentials, network calls, or deployment.
- R2. The harness must cover the public JSON function, protected SMS reply
  function, private asset message function, and private asset missing path.
- R3. The private-message function must report missing asset/runtime failures
  through `callback(error)` instead of throwing synchronously.
- R4. The Node baseline must match the checked-in `twilio-run` 5.x toolchain.
- R5. README must document `npm test`, `npm run verify`, and the Twilio credential boundary.
- R6. The workflow must verify pushes and pull requests, and deploy only through manual `workflow_dispatch`.
- R7. Dependency verification must include a high-severity `npm audit` gate and checked-in overrides for known vulnerable transitive packages.

---

## Implementation Units

### U1. Local Function Harness

- **Goal:** Exercise Twilio handlers without a Twilio runtime.
- **Files:** `scripts/test-functions.js`, `package.json`
- **Patterns:** Use Node's built-in `assert`, stub `Twilio.twiml.MessagingResponse`, and stub `Runtime.getAssets`.
- **Verification:** `npm test`

### U2. Private Asset Error Handling

- **Goal:** Keep private-message failures explicit and callback-based.
- **Files:** `functions/private-message.js`
- **Patterns:** Validate `Runtime.getAssets`, `/message.js`, and asset `path` before requiring the private module.
- **Verification:** `npm test`

### U3. Documentation Baseline

- **Goal:** Make setup and CI expectations clear for future maintainers.
- **Files:** `README.md`, `CHANGES.md`, `scripts/check-baseline.sh`, `docs/plans/2026-06-08-twilio-function-test-baseline.md`
- **Patterns:** Replace generated README text about missing tests with the real verification command and credential notes.
- **Verification:** `git diff --check`, `npm run verify`

### U4. Workflow Safety

- **Goal:** Keep verification automatic while making deployment an explicit credentialed action.
- **Files:** `.github/workflows/main.yml`, `.nvmrc`, `package.json`, `package-lock.json`
- **Patterns:** Use Node 20 from `.nvmrc`, current checkout/setup-node actions, `npm run verify`, and a deploy job gated to `workflow_dispatch`.
- **Verification:** `scripts/check-baseline.sh`

### U5. Dependency Audit Baseline

- **Goal:** Keep the modernized Twilio toolchain free of high-severity npm audit findings.
- **Files:** `package.json`, `package-lock.json`
- **Patterns:** Use `npm audit --audit-level=high` and checked-in overrides for vulnerable transitive packages.
- **Verification:** `npm run audit`

---

## Risks & Dependencies

- The harness validates function behavior, not a live Twilio deployment.
- The workflow deploy job still requires correctly configured Twilio secrets.
- The project now follows the checked-in `twilio-run` 5.x Node 20 toolchain,
  but live Twilio runtime compatibility still needs deployment verification.

---

## Sources / Research

- `functions/hello-world.js` returns the public JSON example.
- `functions/sms/reply.protected.js` returns a TwiML SMS response.
- `functions/private-message.js` loads `/message.js` through Twilio Runtime assets.
- `assets/message.private.js` exports the private message text.
- `package.json` owns the default `npm test` command.
- `.github/workflows/main.yml` owns CI verification and manual deployment.
