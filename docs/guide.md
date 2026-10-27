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

**Everyone installs it themselves.** The repo being public just means anyone is allowed to install it — it
doesn't spread to anyone automatically. If you install it, that only sets it up on your own computer. Every
teammate has to run one of the two install routes themselves, on their own computer.

- **`/plugin` route**: Claude Code manages this one for you, in the background, on your computer. You won't see
  any new folders in your project — that's normal for this route, not a mistake.
- **`install.sh` route**: this one visibly copies files into your project, under its `.claude/` folder. If you
  update the plugin later, just run `install.sh` again to get the update.

**How to check it actually worked** (don't look at your project's folders — the `/plugin` route won't show
anything there, on purpose): run `/agents` and see if the crew's agents are listed, or just try
`/delivery-crew:plan`. If it runs — even if it just tells you `docs/brief.md` is missing — the install worked.

Every command in this guide is written as `/delivery-crew:<name>` (the marketplace-route form). If you
installed via `install.sh` instead, there's no plugin namespace — drop the prefix and use `/<name>` (e.g.
`/crew-init`, `/plan`, `/deliver`) directly.

## 3. Quickstart — New project

1. `/delivery-crew:crew-init` — creates `CLAUDE.md` and `docs/brief.md` if they don't already exist (never overwrites).
2. Fill in `docs/brief.md`: milestone, feature list, Delivery profile, exclusions, and a real database choice
   (leaving it `PENDING` blocks the run). Leave `project_mode` unset or `new`. Leave `## Stack` out entirely unless
   this project isn't Laravel+Blade+Flutter — see §5 for the field values.
3. `/delivery-crew:plan` — previews the stages and branches that would run. No agents run, nothing is written.
4. `/agents` — confirm the crew's agents loaded.
5. `/delivery-crew:deliver` — runs the pipeline stage by stage. It stops after the Tech Lead stage for your
   approval before any developer touches code.

## 4. Quickstart — On an existing project

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
- **Cost model**: the crew runs on your Claude subscription inside Claude Code, not the API — no per-token
  billing, so costs don't pile up as it runs; usage limits apply instead (see above). That's why we moved off
  the API-based CrewAI setup, which bills per token and gets expensive fast at this scale — reach for that
  project only if you specifically need client-facing automation outside Claude Code.
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

- Edit the agents and commands under `plugins/delivery-crew/`.
- Bump `version` in `plugins/delivery-crew/.claude-plugin/plugin.json` and add a `CHANGELOG.md` entry for any
  change to agents or commands.
- If behavior, fields, or commands changed, update this guide and the README in the same change.
- Each agent's model is set by the `model:` line in `agents/*.md` (minimum Sonnet) — change it there if needed.
- Push to the repo, tag the release (`git tag vX.Y.Z`).
- Updates are not automatic — each person updates on their own machine: `/plugin marketplace update
  multi-agent` (CLI route) or re-run `install.sh` (VS Code panel route).
- Report issues or request changes the same way you would any other change to this repo — open an issue or
  reach out to whoever owns the plugin repo for your org.

## 10. Jira-first workflow (`ma-*` commands)

An alternative to §3/§4: instead of hand-editing `docs/brief.md`, work from a Jira ticket. The brief-first
commands (`crew-init`, `plan`, `deliver`) are unchanged and still work exactly as above; these are additive.

| Command | Arguments | Does |
|---|---|---|
| `ma-po-new` | `"task description"` | Drafts a new Jira ticket, grounded in a read-only pass over the codebase |
| `ma-po-edit` | `"edit description" JIRA-ID` | Edits an existing ticket, checked against the codebase |
| `ma-plan` | `JIRA-ID` | Syncs `docs/brief.md` from the ticket, then runs the same preview as `plan` |
| `ma-deliver` | `JIRA-ID` | Syncs the brief, then runs the same pipeline as `deliver` — same gates, no exceptions |
| `ma-deploy` | none | Deploys `dev` to staging; the target is fixed, any argument is ignored |
| `ma-document` | `JIRA-ID` | Writes up a shipped ticket to Confluence from the ticket, the branch diff, and QA notes |

`ma-qa` is out of scope for now — it's being designed separately (local Playwright, no MCP, reading a PostHog
replay URL in-page).

**Argument parsing**: a Jira id matches `[A-Z][A-Z0-9]+-\d+`. The LAST argument token matching this pattern is
the ticket id; everything before it is free text (so `ma-po-edit "mentions JIRA-1 in passing" PROJ-12` resolves
to id `PROJ-12`, not `JIRA-1`). A command that requires an id and gets none prints its usage line and stops. A
malformed id (matches the shape loosely but isn't valid) stops with a clear message rather than being guessed at.

**Integrations config**: every `ma-*` command reads its settings from a `## Integrations` section in
`CLAUDE.md` — `jira_project_key`, `jira_site` (optional), `confluence_space`/`confluence_parent_page`
(optional), `staging_deploy`. `crew-init` writes this as an empty template when creating a new `CLAUDE.md`, or
prints it for you to paste in if `CLAUDE.md` already exists — it never modifies an existing file. If a command
needs a key that's missing, it stops and names the key; it never guesses a Jira site, project key, or
Confluence space.

**Jira/Confluence access**: via the Atlassian MCP, registered with
`claude mcp add --transport http atlassian https://mcp.atlassian.com/v2/mcp`, then `/mcp` to authenticate
(OAuth 2.1; API token is also supported — see Atlassian's own docs for that flow). Recommended
`.claude/settings.json` shape: allow the read tools (`getAccessibleAtlassianResources`, `getJiraIssue`,
`searchJiraIssuesUsingJql`, `getVisibleJiraProjects`, `getJiraProjectIssueTypesMetadata`,
`getJiraIssueTypeMetaWithFields`, `getTransitionsForJiraIssue`, `getConfluencePage`, `searchConfluenceUsingCql`);
leave every write tool (`createJiraIssue`, `editJiraIssue`, `addCommentToJiraIssue`, `transitionJiraIssue`,
`createConfluencePage`, `updateConfluencePage`) on "ask" — this is what enforces "only with my approval" at the
tool level. Never allow `git push`.

**Ticket snapshots**: every Jira fetch is saved to `docs/tickets/<ID>.md` (summary, description, acceptance
criteria, status, fetched-at timestamp). Read-only commands (`ma-plan`, `ma-deliver`, `ma-document`) fall back
to the snapshot with a visible staleness warning if Jira is unreachable; if there's no snapshot either, they
stop rather than invent ticket content. Write commands (`ma-po-edit`'s edit, and anything that must post or
transition) stop outright if Jira is unreachable — they never act from a stale snapshot.

**Writes need approval**: any Jira or Confluence write is shown first as a draft or diff, written only after an
explicit yes. Status transitions are always offered via `getTransitionsForJiraIssue` and never picked
automatically — same principle as the Tech Lead and QA gates in §7.

**Brief sync (`ma-plan`/`ma-deliver`)**: only `## Current milestone` and `## Feature list` are written from the
ticket. Every other brief section — `## Delivery profile`, `project_mode`, `layout:`, `## Stack`,
`## Exclusions`, `## Schema notes`, `## Database` — is preserved exactly as it was.

**Troubleshooting**:
- **A `ma-*` command stops asking for an Integrations key**: add it to `## Integrations` in `CLAUDE.md` — see
  the template `crew-init` prints. Don't guess the value yourself from an old ticket or branch name.
- **"Atlassian MCP not connected"**: run `claude mcp add --transport http atlassian
  https://mcp.atlassian.com/v2/mcp` then `/mcp` in a fresh session to authenticate.
- **A ticket id isn't recognized**: check it matches `[A-Z][A-Z0-9]+-\d+` and is the LAST token in the
  argument — free text containing something that looks like an id earlier in the string is ignored by design.
- **Jira is unreachable mid-command**: read-only commands fall back to `docs/tickets/<ID>.md` if one exists;
  write commands stop instead of guessing. Re-run once Jira is back.
- **`ma-deploy` refuses to run**: either `staging_deploy` is missing from `## Integrations`, or the configured
  method looks like it points at production — both are deliberate; fix the brief/CLAUDE.md rather than forcing it.

## 11. Rules for humans using the crew

- Never skip the Tech Lead approval gate, even for a small milestone.
- `RECOMMENDATION: NO-GO` from QA means stop — don't merge around it.
- Review every diff before approving a PR; the crew's own review of itself (QA stage) is not a substitute for
  human code review.
- Don't let the crew's output cap (400–700 words per doc) tempt you into skipping the doc — read it before the
  stage that depends on it runs.
