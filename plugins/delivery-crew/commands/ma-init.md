---
description: Set up CLAUDE.md and docs/brief.md in this project for the delivery crew
---
Set up this project for the delivery crew. Create each file below ONLY if it does not already exist (never overwrite).
Then say which files you created and that I must fill in `docs/brief.md` (milestone, features, delivery profile, a
Database that is not PENDING, and a Stack section only if the project isn't Laravel+Blade+Flutter).
If this is an existing codebase (not a fresh repo), set `project_mode: existing` and the `layout:` field, and remind me the first
`ma-deliver` run (`/delivery-crew:ma-deliver` via the marketplace route, or `/ma-deliver` if installed via `install.sh`)
will insert a Discover stage that writes `docs/00-codebase-map.md` for me to review before Tech Lead runs.
Then run `ma-plan` (`/delivery-crew:ma-plan` or `/ma-plan`) to preview the stages before running `ma-deliver`.

If `CLAUDE.md` already exists, do not modify it — instead print the `## Integrations` block from File 1 below and tell
me to paste it in myself if I want the Jira-first argument on `ma-plan`/`ma-deliver` (see README).

**File 1: `CLAUDE.md`**
```
# Virtual Software Agency – Project Rules

## Pipeline (sequential, via the ma-deliver command)
Discover (project_mode: existing only) → PO → BA → UX → UI/UX → Tech Lead → Backend → Web (if profile) → Mobile per app (if profile) → extra agents → QA → DevOps
Stages depend on the Delivery profile in docs/brief.md.

## Hard rules
- docs/brief.md is the single source of truth for scope. Exclusions listed there are never built.
- Stack: as recorded in docs/brief.md's `## Stack` section (defaults, if that section is absent: Laravel+Sanctum
  backend, web embedded in the backend app via Blade, Flutter mobile). GitHub Actions CI, Docker, regardless of stack.
- Output cap: every agent document is 400–700 words (Tech Lead up to 900). Code is exempt but must be complete, not stubs.
- Context discipline: read only the input files named in your prompt, never the whole docs/ folder.
- Each agent writes to the output path in its prompt and replies with max 120 words plus the path.
- File ownership: backend, web and each mobile app each own a separate top-level folder and never edit another's files;
  the exact paths and boundaries for the chosen stack are set by Tech Lead in docs/05-tech-lead.md.
- Git: each developer works on its own branch (feature/<milestone>-backend|web|mobile-<app>|devops). Never merge, never push, never force-push, never touch main. A human reviews every PR.
- Do not invent a database choice. If the brief says PENDING, stop.
- project_mode: existing (docs/brief.md) — no developer ever scaffolds a new framework project. Backend/web/mobile code goes into the paths in `docs/brief.md`'s `layout:` field and `docs/00-codebase-map.md`, following existing conventions. Migrations are additive only (no column drops/renames), applied to a local/dev database only.

## Integrations (optional — only needed for the Jira-first argument on ma-plan/ma-deliver, and ma-po-new/ma-po-edit/ma-deploy/ma-document)
jira_project_key:          # e.g. PROJ — required by ma-po-new, ma-po-edit, ma-plan <id>, ma-deliver <id>, ma-document
jira_site:                 # optional, your-domain.atlassian.net
confluence_space:          # optional — required by ma-document if creating a new page
confluence_parent_page:    # optional — preferred parent page for new docs, by title
staging_deploy:            # required by ma-deploy — the script/CI-trigger/command that deploys `dev` to staging
```

**File 2: `docs/brief.md`**
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
                          #   e.g. "backend = api/, web = api/resources/views, mobile/customer = apps/customer_app"

## Stack
backend: laravel          # laravel | node | django (default: laravel)
web: embedded             # embedded (server-rendered in the backend app) | spa (separate React app in web/) | none
mobile: flutter           # flutter | react-native | none
                          # Omit this whole section to use the defaults (laravel, embedded, flutter) — v1.2.0 behavior.

## Exclusions
ratings, promo codes, loyalty, referrals, in-app chat, advanced analytics, live map tracking, multiple payment gateways

## Schema notes
- ...

## Database
PENDING (MySQL vs PostgreSQL – confirm with CTO)
```
