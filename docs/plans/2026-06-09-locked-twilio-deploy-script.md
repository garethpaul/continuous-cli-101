# Locked Twilio Deploy Script

## Status: Completed

## Goal

Keep manual Twilio deployment tied to the repository's locked npm dependency
graph instead of installing the latest global Twilio CLI and plugin inside CI.

## Scope

- Preserve deployment as a manual `workflow_dispatch` job.
- Preserve the existing service name, environment, and force-deploy flags.
- Use the checked-in `npm run deploy` script backed by `package-lock.json`.
- Add source checks and README notes for the locked deploy baseline.

## Out Of Scope

- Running a real Twilio deploy from this environment.
- Changing Twilio credentials, service names, or GitHub secrets.
- Migrating away from the Twilio Serverless training sample shape.

## Verification

- `make check`
- `npm run verify`
- `git diff --check`
