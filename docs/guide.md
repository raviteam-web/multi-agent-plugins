# Delivery Crew — Usage Guide

This repository holds the code that implements the delivery crew in Claude Code. This guide is the full
reference; the [README](../README.md) is just the quickstart. Keep this file in sync with the plugin — it's
versioned alongside the code, so it never drifts from what's actually installed.

## 1. What this is, and what it is not

The delivery crew is a set of Claude Code subagents and commands that turn a short brief into design docs,
a technical plan, and working code on feature branches. The default stack is Laravel (Sanctum) + Blade + Flutter;
Node/Express and Django are supported backends, a separate React SPA is a supported web mode, and React Native is
a supported mobile framework (see §5, the `## Stack` section). GitHub Actions CI and Docker apply regardless of stack.

It is **not**:
- An auto-merge or auto-deploy tool. Nothing is ever merged or pushed by the crew; every branch needs a human PR review.
- A replacement for the Tech Lead approval gate or the QA GO/NO-GO gate. Both are hard stops.
- An any-stack tool. It supports the fixed list above, not arbitrary frameworks — naming anything else in `## Stack`
  stops the Tech Lead stage with an error rather than improvising.
- A fit for every change. It's built for scoped feature milestones with a clear brief, not open-ended exploration.

## 2. Requirements and install

- Claude Code (CLI, desktop, or the VS Code extension). The repo is public, so no repo access setup is needed.
- Whichever tools the chosen stack needs are already installed where that surface exists: `composer`/PHP (laravel),
  Node (node backend, or a `spa` web app), Python (django), `flutter`, or `react-native`/Expo tooling.

**CLI / plugin-marketplace route** (preferred):
```
/plugin marketplace add raviteam-web/multi-agent-plugins
/plugin install delivery-crew@multi-agent
```

**VS Code-panel route**, if `/plugin` isn't available in your panel:
```
git clone <repo-url>
cd multi-agent-plugins
./install.sh /path/to/your/project
```

**This is per-person, not per-team.** The repo being public means anyone *can* install it, but nobody gets it
automatically just because a teammate did — every person installs it on their own machine, individually, the
same way you did. There's no shared or central install; each route below is local to the machine it's run on:

- **`/plugin` route**: global per machine, not per project. `/plugin marketplace add` registers the marketplace
  under `~/.claude/plugins/marketplaces/multi-agent/` (a clone of this repo) and caches the plugin under
  `~/.claude/plugins/cache/`; `/plugin install` then records that this plugin is enabled, normally per project
  via that project's `.claude/settings.json`. Only works in a Claude Code client that supports `/plugin` (CLI,
  desktop — not every VS Code panel).
- **`install.sh` route**: local per project, not global. It copies `agents/` and `commands/` straight into
  `<target-project>/.claude/agents/delivery-crew/` and `<target-project>/.claude/commands/delivery-crew/`, plus
  a version stamp at `<target-project>/.claude/delivery-crew.version`. Re-run it for every project you want the
  crew in, and every teammate using this route runs it themselves, on their own machine, against their own
  project checkout.
This copies `agents/` and `commands/` into your project's `.claude/` folder and writes a version stamp
(`.claude/delivery-crew.version`). Re-run it after pulling an update to upgrade in place.

## 3. Quickstart — new project

1. `/delivery-crew:crew-init` — creates `CLAUDE.md` and `docs/brief.md` if they don't already exist (never overwrites).
2. Fill in `docs/brief.md`: milestone, feature list, Delivery profile, exclusions, and a real database choice
   (leaving it `PENDING` blocks the run). Leave `project_mode` unset or `new`. Leave `## Stack` out entirely unless
   this project isn't Laravel+Blade+Flutter — see §5 for the field values.
3. `/delivery-crew:plan` — previews the stages and branches that would run. No agents run, nothing is written.
4. `/agents` — confirm the crew's agents loaded.
5. `/delivery-crew:deliver` — runs the pipeline stage by stage. It stops after the Tech Lead stage for your
   approval before any developer touches code.

## 4. Using it on an existing project

Existing codebases need more care, because the crew is writing into code that's already live and already has
conventions. Do this pre-flight before `crew-init`:

- Clean working tree (commit or stash anything in progress).
- Baseline tests are green, so you can tell the crew's changes apart from pre-existing failures.
- Confirm which database the crew should point at — a local/dev copy, never production.

Then:

1. `/delivery-crew:crew-init`, and in `docs/brief.md` set:
   - `project_mode: existing`
   - `layout:` — the real paths, if they differ from this plugin's `backend/` and `mobile/<app>/` defaults,
     e.g. `backend = api/, web = api/resources/views, mobile/customer = apps/customer_app`
   - `## Stack` — set it to whatever the codebase actually uses (don't rely on the `laravel`/`embedded`/`flutter`
     default for an existing project that isn't that stack); `codebase-discoverer` will flag a mismatch, not fix it.
   - One small feature for the first run, not the whole backlog. Tight `Exclusions`. Real schema notes (what
     tables already exist), not a from-scratch schema.
2. `/delivery-crew:deliver` now inserts a **Discover** stage first. The `codebase-discoverer` agent reads the
   real repo (backend manifest — composer.json / package.json / manage.py —, migrations, models, routes, views,
   and each mobile app's pubspec.yaml or package.json) and writes `docs/00-codebase-map.md`.
   **A human must read and correct this file** before the pipeline continues to Tech Lead — it's the foundation
   everything else is built on.
3. From here it's the same pipeline, with these differences baked into every agent:
   - **Scaffolding is never allowed.** No `composer create-project`, `npm init`/Express generator, `django-admin
     startproject`, `flutter create`, or `react-native init`. Code goes into the real paths from the codebase map
     / `layout:` field.
   - **Migrations are additive only** — no column drops or renames — and only ever applied to a local/dev DB.
   - Tech Lead extends the existing schema and repo structure instead of redesigning it, and will flag (not
     silently resolve) any conflict between `docs/00-codebase-map.md`, the brief's `layout:` field, and its
     `## Stack` section.
4. Review discipline is stricter: run `git diff --stat` after every developer stage (not just at the end), and
   read the Tech Lead plan carefully before approving — on an existing codebase, that approval is your main
   chance to catch a wrong assumption before code gets written.
5. Merge is the same as new-project (normal PR), plus a mandatory human code review — no exceptions, since the
   crew doesn't have full certainty about every existing convention.

| | New project | Existing project |
|---|---|---|
| Setup | `crew-init`, fill `docs/brief.md` | Clean tree, baseline tests green, dev DB confirmed, then `crew-init` |
| Brief | Full feature list | One small feature, tight Exclusions, real schema notes, `project_mode: existing` + `layout:` |
| First stage | product-owner | codebase-discoverer, then a human corrects `docs/00-codebase-map.md` |
| Scaffolding | Allowed | Never |
| Migrations | Normal | Additive only, local DB only |
| Review | Check each stage's output | Also `git diff --stat` after every stage; review the Tech Lead plan strictly |
| Merge | Normal PR | Normal PR + human code review, no exceptions |

## 5. The brief, field by field

`docs/brief.md` is the single source of truth for scope — anything in `Exclusions` is never built, regardless
of what a later stage infers.

```
# Brief (keep this minimal)

## Project
<project name and one-line description>

## Current milestone
<e.g. M1: Auth + restaurant menu browsing>

## Feature list (this milestone only)
- ...

## Delivery profile
type: low-hybrid          # api-only | web | hybrid | low-hybrid
mobile: customer          # app names, comma separated (hybrid and low-hybrid only)
web_scope:                # optional: admin | full (defaults: web=full, hybrid=full, low-hybrid=admin)
extra_agents: none        # names of project agents in .claude/agents/, run after the builders
project_mode: new         # new | existing. existing = never scaffold, additive migrations only, Discover runs first
layout:                   # existing only: real paths if different from backend/ and mobile/<app>/ defaults

## Stack
backend: laravel          # laravel | node | django (default: laravel)
web: embedded             # embedded (server-rendered in the backend app) | spa (separate React app in web/) | none
mobile: flutter           # flutter | react-native | none
                          # omit this whole section to use the defaults (laravel, embedded, flutter)

## Exclusions
ratings, promo codes, loyalty, referrals, in-app chat, advanced analytics, live map tracking, multiple payment gateways

## Schema notes
- ...

## Database
PENDING (MySQL vs PostgreSQL – confirm with CTO)
```

`## Stack` is independent of `## Delivery profile`: the profile says *which surfaces* run, the stack says *which
framework* implements each one. Values outside the allowed set stop the Tech Lead stage rather than being guessed at.
Where the stack leaves a choice open (which ORM for `node`, which templating engine for `embedded`), Tech Lead picks
one and states it in `docs/05-tech-lead.md` — read that before approving.

Filled example (existing, low-hybrid, default stack — `## Stack` omitted):
```
## Project
Linkyfy – restaurant ordering platform

## Current milestone
M3: Loyalty points on existing orders flow

## Feature list (this milestone only)
- Award points on completed orders
- Customer-facing points balance screen

## Delivery profile
type: low-hybrid
mobile: customer
web_scope: admin
extra_agents: none
project_mode: existing
layout: backend = backend/, web = backend/resources/views, mobile/customer = mobile/customer

## Exclusions
redeeming points, tiers, referrals, expiry rules

## Schema notes
- orders table exists with status enum; no points-related tables yet

## Database
MySQL 8 (already in use)
```

Filled example (new, non-default stack — Node API + React SPA + React Native):
```
## Delivery profile
type: low-hybrid
mobile: customer
web_scope: full

## Stack
backend: node
web: spa
mobile: react-native
```

## 6. Stages, branches, and what each agent produces

| Stage | Runs when | Output | Branch (base) |
|---|---|---|---|
| codebase-discoverer | `project_mode: existing` | `docs/00-codebase-map.md` | none |
| product-owner | always | `docs/01-product-owner.md` | none |
| business-analyst | always | `docs/02-business-analyst.md` | none |
| ux-researcher | always | `docs/03-ux-research.md` | none |
| ui-ux-designer | always | `docs/04-ui-ux-design.md` | none |
| tech-lead | always | `docs/05-tech-lead.md` | none |
| backend-developer | always | `docs/06-backend.md` | `feature/<m>-backend` (main) |
| web-developer | profile has web | `docs/07-web.md` | `feature/<m>-web` (stacked on backend) |
| mobile-developer, once per app | profile has mobile | `docs/08-mobile-<app>.md` | `feature/<m>-mobile-<app>` (main) |
| extra agents, in listed order | `extra_agents` set | `docs/09-<agent>.md` | `feature/<m>-<agent>` (main) |
| qa-engineer | always | `docs/10-qa.md` | `qa/<m>-integration` (throwaway) |
| devops-engineer | always | `docs/11-devops.md` | `feature/<m>-devops` (main) |

Nothing is merged or pushed by the crew. Review and merge the backend branch before the web branch, since web
is stacked on it.

## 7. Run discipline

- **Resuming a stage**: `/delivery-crew:deliver <stage-name>`, e.g. `/delivery-crew:deliver tech-lead` to
  restart from there (useful after a usage-limit stop or an interrupted run — nothing before that stage is re-run).
- **Hitting a Claude usage limit mid-pipeline**: wait for the limit to reset, then resume from the last stage
  that didn't finish — check the last line the orchestrator printed for the stage name and output path.
- **The Tech Lead gate**: always read `docs/05-tech-lead.md` before approving. This is the one point where a
  wrong assumption (wrong schema, wrong file ownership, or the wrong ORM/templating choice for an open `## Stack`
  field) is cheap to catch and expensive to catch later.
- **The QA gate**: if the last line of `docs/10-qa.md` is `RECOMMENDATION: NO-GO` or missing, stop. Don't loop
  the crew automatically — read the defects, decide, and only re-run the specific stage that needs rework.
- **Every diff**: review `git diff --stat` per branch minimum, full diff on anything touching auth, payments,
  or migrations.

## 8. Troubleshooting

- **A stage silently does nothing, or `/init` behaves unexpectedly**: make sure you're running
  `/delivery-crew:crew-init`, not Claude Code's built-in `/init` — the crew's command was renamed in v1.2.0
  specifically to avoid this clash. If you installed before that, update the plugin.
- **A web or mobile stage stops partway through**: check `git status` on that branch — most often it's an
  interrupted tool call. Commit or discard partial work, then resume with `/delivery-crew:deliver web-developer`
  (or the relevant stage name); the orchestrator re-checks the branch and base before continuing.
- **Code lands in the wrong paths on an existing project**: this almost always means `docs/00-codebase-map.md`
  wasn't corrected before Tech Lead ran, or `layout:` in the brief didn't match reality. Fix the brief/map and
  re-run from `tech-lead`.
- **An extra agent isn't picked up**: confirm its name in `extra_agents` exactly matches a file in
  `.claude/agents/` in that project (not this plugin's repo).
- **Tech Lead stops with a stack error**: `## Stack` has a value outside `laravel|node|django` / `embedded|spa|none`
  / `flutter|react-native|none`. Fix the brief and resume from `tech-lead`.
- **codebase-discoverer flags a stack mismatch**: the manifests it found (composer.json, package.json, manage.py,
  pubspec.yaml, etc.) don't match the brief's `## Stack` section. Trust what it found over a stale brief, correct
  the brief, and resume.

## 9. Updating and versioning

- Bump `version` in `plugins/delivery-crew/.claude-plugin/plugin.json` and add a `CHANGELOG.md` entry for any
  change to agents or commands.
- Push to the repo, tag the release (`git tag vX.Y.Z`).
- Each project then runs `/plugin marketplace update multi-agent` (CLI route) or re-runs `install.sh` (VS Code
  panel route).
- Report issues or request changes the same way you would any other change to this repo — open an issue or
  reach out to whoever owns the plugin repo for your org.

## 10. Rules for humans using the crew

- Never skip the Tech Lead approval gate, even for a small milestone.
- `RECOMMENDATION: NO-GO` from QA means stop — don't merge around it.
- Review every diff before approving a PR; the crew's own review of itself (QA stage) is not a substitute for
  human code review.
- Don't let the crew's output cap (400–700 words per doc) tempt you into skipping the doc — read it before the
  stage that depends on it runs.
