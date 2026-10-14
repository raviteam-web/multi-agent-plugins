---
description: Run the delivery crew for the milestone and delivery profile in docs/brief.md
argument-hint: "[optional stage to start from, e.g. tech-lead]"
---
You are the orchestrator of the delivery crew. Project rules: `CLAUDE.md`. Scope and profile: `docs/brief.md`.
If either file is missing, tell me to run `/delivery-crew:crew-init` and stop.

## 1. Validate (stop and list every problem if any fails)
- Milestone and feature list are filled in (no `<e.g.` placeholders).
- Database is not PENDING.
- `## Delivery profile` exists with `type` = one of: api-only, web, hybrid, low-hybrid.
- hybrid and low-hybrid need `mobile:` with one or more app names (lowercase, comma separated).
- `web_scope` defaults: web = full, hybrid = full, low-hybrid = admin. If given it must be `admin` or `full`. api-only has no web or mobile.
- Every name in `extra_agents` (if not "none") exists in `.claude/agents/`.
- `project_mode` (if present) must be `new` or `existing`; missing defaults to `new`. `existing` should have a `layout:` block (warn, don't block, if empty).
- `## Stack` (if present): `backend` must be `laravel`, `node` or `django`; `web` must be `embedded`, `spa` or `none`; `mobile` must be `flutter`, `react-native` or `none`. Missing section, or a missing field within it, defaults to `laravel`/`embedded`/`flutter`.

## 2. Build the stage list from the profile
Let M = milestone slug (kebab-case, max 30 chars). Doc folder: `docs/`.

| # | Subagent | Runs when | Inputs | Output | Branch (base) |
|---|---|---|---|---|---|
| 0 | codebase-discoverer | project_mode: existing | brief | docs/00-codebase-map.md | none |
| 1 | product-owner | always | brief | docs/01-product-owner.md | none |
| 2 | business-analyst | always | brief, 01 | docs/02-business-analyst.md | none |
| 3 | ux-researcher | always | 01, 02 | docs/03-ux-research.md | none |
| 4 | ui-ux-designer | always | 02, 03 | docs/04-ui-ux-design.md | none |
| 5 | tech-lead | always | brief, 02, 04, and 00 if it exists | docs/05-tech-lead.md | none |
| 6 | backend-developer | always | 05 | docs/06-backend.md | feature/M-backend (main) |
| 7 | web-developer | type is web, hybrid or low-hybrid | 05, 04 | docs/07-web.md | feature/M-web (feature/M-backend) |
| 8 | mobile-developer, once per app | type is hybrid or low-hybrid | 05, 04 | docs/08-mobile-APP.md | feature/M-mobile-APP (main) |
| 9 | each extra agent, in listed order | extra_agents set | 05 | docs/09-EXTRA.md | feature/M-EXTRA (main) |
| 10 | qa-engineer | always | 01, and every doc from steps 6-9 | docs/10-qa.md | qa/M-integration |
| 11 | devops-engineer | always | 05, 10 | docs/11-devops.md | feature/M-devops (main) |

"main" means the repo's base branch (record it at the start). Start from: "$ARGUMENTS" (empty = stage 1).

## 3. Run, one stage at a time, using the Task tool (wait for each to finish)
- In each prompt give ONLY: milestone name, a one-line profile summary (type, web scope, mobile apps), the resolved stack (backend/web/mobile), the input file paths, the output path, and for developers the branch name and base. Never paste earlier outputs.
- Before every developer stage: ensure the working tree is clean, then `git checkout` the stated base. After it: confirm the work is committed, then `git checkout` the base branch again.
- web-developer is told its scope (admin or full). mobile-developer is told its single app name and its folder `mobile/APP`.
- Subagents may appear in /agents with a plugin prefix (for example `delivery-crew:product-owner`); use the exact listed name.
- After each stage print ONE line: stage, output file, status (under 50 words).

## 4. Gates
- After codebase-discoverer (if it ran): show me the path of docs/00-codebase-map.md and ask for approval/corrections before product-owner runs.
- After tech-lead: show me the path of docs/05-tech-lead.md and ask for approval before any developer runs.
- Before QA: create `qa/M-integration` from the base branch and merge every feature branch built so far (`git merge --no-edit`). If a merge conflicts, abort the merge, stop, and show me the files. After QA, check out the base branch.
- If the last line of docs/10-qa.md is `RECOMMENDATION: NO-GO` (or missing), stop and show me the defects. Never loop automatically.

## 5. Finish
List all branches created, the doc paths, and remind me: human PR review is required; web-developer's branch is stacked on the backend branch, so review and merge backend first. Nothing is merged or pushed by the crew.
