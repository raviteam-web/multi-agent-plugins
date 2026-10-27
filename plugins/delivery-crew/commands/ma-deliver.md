---
description: Run the delivery crew; optionally sync docs/brief.md from a Jira ticket first, or resume from a stage
argument-hint: "[JIRA-ID | stage-name]"
---
You are the orchestrator of the delivery crew. Project rules: `CLAUDE.md`. Scope and profile: `docs/brief.md`.
If either file is missing, tell me to run the `ma-init` command and stop.

## 0. Classify `$ARGUMENTS`
- Empty → brief-first, start from stage 1.
- Matches a Jira ticket id (`[A-Z][A-Z0-9]+-\d+`) → Jira-first: run §0a below, then proceed from stage 1.
- Matches one of the stage names in the table below (`codebase-discoverer`, `product-owner`, `business-analyst`,
  `ux-researcher`, `ui-ux-designer`, `tech-lead`, `backend-developer`, `web-developer`, `mobile-developer`,
  `qa-engineer`, `devops-engineer`) → brief-first resume: start from that stage, nothing before it re-runs.
- Anything else → stop and say it's neither a recognized Jira ticket id nor a stage name, and list both valid forms.

### 0a. Jira-first sync (only when a ticket id was given)
Call `getJiraIssue`; if unreachable, fall back to `docs/tickets/<ID>.md` with a visible staleness warning, or
stop if there's no snapshot either. If `docs/brief.md` is missing, create it from the `ma-init` template
(fill `## Project` from the repo/`CLAUDE.md` where possible). Update **only** `## Current milestone` and
`## Feature list` from the ticket (map summary/description to the milestone, each acceptance criterion/sub-task
to a feature entry, keep the ticket id as reference); preserve every other section exactly — `## Delivery
profile`, `project_mode`, `layout:`, `## Stack`, `## Exclusions`, `## Schema notes`, `## Database`. Show the
brief diff (visible, no separate approval needed) and apply it. Infer `## Delivery profile` only if still
unfilled; ask once if it can't be inferred.

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
Let M = milestone slug (kebab-case, max 30 chars). If this run is Jira-first, suffix M with the ticket key
(`M-KEY`) for branch/commit naming. Doc folder: `docs/`.

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

"main" means the repo's base branch (record it at the start). Start from the stage resolved in §0 (empty/ticket = stage 1).

## 3. Run, one stage at a time, using the Task tool (wait for each to finish)
- In each prompt give ONLY: milestone name, a one-line profile summary (type, web scope, mobile apps), the resolved stack (backend/web/mobile), the input file paths, the output path, and for developers the branch name and base. Never paste earlier outputs.
- Jira-first runs: commit messages are prefixed `<KEY>: <stage>`.
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

If this was a Jira-first run, offer — don't auto-post — a Jira comment summarizing the branches/stages/QA result,
and list the available transitions via `getTransitionsForJiraIssue` (never pick one on your own). Post or
transition only on explicit approval; if Jira is unreachable at this point, print the comment text instead.
