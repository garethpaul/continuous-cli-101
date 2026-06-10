# AGENTS.md

## Repository purpose

`garethpaul/continuous-cli-101` is a Twilio Serverless training sample with a GitHub Actions deployment workflow.

## Project structure

- `Makefile` - repository verification targets
- `scripts` - baseline checks and helper scripts
- `docs` - plans, notes, and generated README assets
- `package.json` - Node package metadata and scripts
- `assets` - repository source or sample assets
- `functions` - repository source or sample assets

## Development commands

- Install dependencies: `npm ci`
- Full baseline: `make check`
- Combined verification: `make verify`
- Lint/static checks: `make lint`
- Tests: `make test`
- Build: `make build`
- package script `start`: `npm start`
- package script `lint`: `npm run lint`
- package script `test`: `npm test`
- package script `verify`: `npm run verify`
- package script `check`: `npm run check`
- package script `audit`: `npm run audit`
- If a command above skips because a platform toolchain is missing, verify on a machine with that SDK before claiming platform behavior is tested.

## Coding conventions

- Language mix noted in the README: JavaScript (4).
- Use Node 20 for package scripts.
- ESLint is configured; keep lint fixes in source instead of generated output.

## Testing guidance

- Test-related files detected: `docs/plans/2026-06-08-twilio-function-test-baseline.md`, `scripts/test-functions.js`
- Start with the narrowest relevant test or Make target, then run `make check` before handing off if the change is not documentation-only.
- Keep README verification notes in sync when commands, fixtures, or supported toolchains change.

## PR / change guidance

- Keep diffs focused on the requested repository and avoid unrelated modernization or formatting churn.
- Preserve public APIs, sample behavior, file formats, and documented environment variables unless the task explicitly changes them.
- Update tests, README notes, or docs/plans when behavior, security posture, or validation commands change.
- Call out skipped platform validation, legacy toolchain assumptions, and any risky files touched in the final summary.

## Safety and gotchas

- Twilio account SIDs, API keys, and API secrets must live in GitHub Actions secrets or local environment variables only.
- GitHub Actions runs `npm run verify` for pushes and pull requests. Twilio deployment requires a manual `workflow_dispatch` run with `confirm_deploy: true`.
- Deployment is scoped to the `twilio-development` GitHub environment and serialized to prevent overlapping releases.
- The manual deploy job uses the package-lock-pinned deploy script instead of installing the latest global Twilio CLI and plugin during CI.
- Manual Twilio deployment should continue to call the package-lock-pinned `npm run deploy` script from the workflow.
- Private `/message.js` assets must export a function that returns a non-empty string from a non-blank absolute file asset path before `private-message` adds it to TwiML.
- See `SECURITY.md` for vulnerability reporting and safe research guidance.
- Deployment or publish scripts exist; do not run them unless explicitly asked.

## Agent workflow

1. Inspect the README, Makefile, manifests, and the files directly related to the request.
2. Make the smallest source or docs change that satisfies the task; avoid generated, vendored, or local-environment files unless required.
3. Run the narrowest useful validation first, then `make check` or the documented package/platform gate when available.
4. If a required SDK, service credential, or external runtime is unavailable, record the skipped command and why.
5. Summarize changed files, commands run, and remaining risks or follow-up validation.
