# README Local Run And Deployment Guidance

Status: Completed

## Problem

The README listed npm scripts but did not explain how to reach the local sample
or safely trigger the guarded manual deployment workflow.

## Requirements

1. Document `npm start` and the local development URL.
2. Add exact manual deployment instructions for the checked-in Twilio CI workflow.
3. Preserve confirmation, main-branch, environment, secret, and concurrency boundaries.
4. Warn against bypassing those controls with an ad hoc real-account deploy.

## Scope Boundaries

- Do not change functions, assets, package metadata, secrets, or workflow behavior.
- Do not execute a credentialed Twilio deployment.

## Verification

- `npm run verify` and `make check` passed.
- Seven isolated hostile mutations were rejected across the local URL, workflow
  selection, confirmation, environment, branch, secret, and direct-deploy guidance.
- No Twilio credentials were configured and no deployment was attempted.
