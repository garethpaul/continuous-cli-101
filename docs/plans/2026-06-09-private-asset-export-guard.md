# Private Asset Export Guard

## Status: Completed

## Goal

Make `functions/private-message.js` fail through the Twilio callback contract
when `/message.js` exists but does not export the expected message function.

## Scope

- Validate the required private asset export before calling it.
- Return an explicit callback error for malformed private asset modules.
- Add a fixture and local harness coverage for a non-function private asset.
- Extend the SDK-free baseline and docs for the private asset export contract.

## Out Of Scope

- Changing the real private message text.
- Changing Twilio deployment workflow behavior.
- Adding networked Twilio integration tests.

## Verification

- `make check`
- `npm run lint`
- `npm test`
- `npm run check`
- `npm run audit`
- `npm run verify`
- `git diff --check`
