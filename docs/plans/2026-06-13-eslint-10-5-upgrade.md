---
title: ESLint 10.5 Upgrade
type: maintenance
status: planned
date: 2026-06-13
---

# ESLint 10.5 Upgrade

## Status: Planned

## Problem Frame

The repository pins ESLint `10.4.1`, while the npm registry reports `10.5.0` as
the current release. The newer release retains support for Node `^22.13.0`, so
the lint tool can be updated without widening the repository runtime or changing
the Twilio deployment architecture.

## Scope Boundaries

- Update only the direct `eslint` development dependency and the dependency
  graph npm resolves for that exact version.
- Preserve `@eslint/js`, `twilio-run`, Node engines, `.nvmrc`, npm scripts,
  function behavior, assets, workflow permissions, deployment guards, and
  Twilio secrets.
- Do not run credentialed Twilio deployment.
- Do not suppress, downgrade, or ignore new lint findings to make the upgrade
  pass.

## Requirements

- R1. `package.json` and `package-lock.json` must pin ESLint `10.5.0` exactly.
- R2. Lockfile installation must succeed under Node `22.22.2` with scripts
  disabled during dependency installation.
- R3. ESLint must pass with zero warnings under the existing flat configuration.
- R4. Function tests, source contracts, and the moderate-severity audit must
  remain green without application or workflow changes.
- R5. `npm outdated --json` must report no outdated direct dependencies after
  installation.
- R6. Static contracts and documentation must pin the exact supported ESLint
  version and completed verification evidence.

## Implementation Units

### U1. Refresh The Pinned Lint Toolchain

- **Files:** `package.json`, `package-lock.json`
- Resolve ESLint `10.5.0` with npm under Node `22.22.2`.
- Accept only lockfile changes required by that direct dependency update.

### U2. Update Repository Contracts

- **Files:** `scripts/check-baseline.sh`, `README.md`, `CHANGES.md`, `VISION.md`,
  this plan
- Replace the prior exact version contract with `10.5.0` and document the
  unchanged Node/runtime/deployment boundaries.
- Make stale manifest, lockfile, documentation, or completed-plan evidence fail
  the source baseline.

## Verification

- Node `22.22.2` `npm ci --ignore-scripts`
- `npm run lint`
- `npm test`
- `npm run check`
- `npm run verify`
- `make check`
- Run the absolute-path Make wrapper from `/tmp`.
- `npm audit --json`
- `npm outdated --json`
- `node --check` and `sh -n` for changed executable files.
- `git diff --check`
- Isolated hostile mutations for manifest version drift, lockfile version drift,
  documentation drift, stale plan status, and missing verification evidence must
  each fail.

## Risks

- A lint release can tighten default diagnostics even when configuration is
  unchanged; any new finding must be fixed in source or the upgrade deferred,
  never suppressed as part of this unit.
- npm may refresh transitive metadata while resolving the exact direct version;
  the final diff must be reviewed against the requested dependency scope.
- Credentialed deployment remains outside local and pull-request validation.

## Prioritized Follow-Ups

1. Guard the test harness against overlapping invocations that mutate shared
   process globals.
2. Add explicit workshop documentation for authentication-protected Twilio
   Functions without broadening public example behavior.
