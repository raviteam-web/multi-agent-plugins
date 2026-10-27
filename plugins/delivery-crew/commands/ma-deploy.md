---
description: Deploy the dev branch to staging (fixed target — no arguments accepted)
---
Deploy branch `dev` to staging. This command's target is fixed: ignore any argument given — never accept a
branch or environment override, and never touch production.

## 1. Read the deploy method
Read `staging_deploy` from `## Integrations` in `CLAUDE.md`. If missing, stop and tell me to add it (see
`crew-init`). If the configured method looks like it points at production (e.g. names a prod host, prod
branch, or prod environment), stop and say why.

## 2. Pre-checks
1. Working tree is clean.
2. Current branch is `dev` — if not, ask before switching to it.
3. Local `dev` is up to date with remote (`git fetch` then compare).

## 3. Confirm, then run
Show the exact command that will run, plus the branch and commit it targets, and wait for confirmation before
running it. If the mechanism includes `git push`, say explicitly that this needs my separate explicit
permission, since pushes are denied by default — do not run it as part of this confirmation.

## 4. Report
Report success or failure strictly from the deploy command's exit status or the CI result. Never claim success
without that confirmation.
