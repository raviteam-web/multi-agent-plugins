# Multi-Agent Plugins (Claude Code plugin)

This repository holds the code that implements the delivery crew in Claude Code: a profile- and stack-driven AI
delivery crew for API + web + mobile projects. Default stack is Laravel (Sanctum) + Blade + Flutter; Node/Express
and Django are supported backends, a separate React SPA is a supported web mode, and React Native is a supported
mobile framework — see [Stack](#stack) below. See [docs/guide.md](docs/guide.md) for the full usage guide.

## Install (in any project, inside Claude Code / VS Code)
```
/plugin marketplace add raviteam-web/multi-agent-plugins
/plugin install delivery-crew@multi-agent
```
Public repo, so no extra `git` access setup needed.
Local test without Git: `/plugin marketplace add ./path/to/this/repo`

No `/plugin` support in your VS Code panel? Clone this repo and run `install.sh` instead:
```
git clone https://github.com/raviteam-web/multi-agent-plugins.git
cd multi-agent-plugins
./install.sh /path/to/your/project
```
It copies the agents/commands straight into that project's `.claude/` folder and writes a version stamp.

Either route is per-person, per-machine — nobody gets it automatically just because a teammate installed it.
See [docs/guide.md §2](docs/guide.md#2-requirements-and-install) for exactly where each route installs to.

## Use
Every command is prefixed `ma-` (short for "multi-agent"), so it's always clear which commands are this crew's
and which are Claude Code's own built-ins.

1. `/delivery-crew:ma-init`     creates CLAUDE.md and docs/brief.md (never overwrites)
2. Fill in `docs/brief.md`: milestone, features, Delivery profile, exclusions, database (PENDING blocks the run).
   Adding an existing codebase (not a fresh repo)? Set `project_mode: existing` and the `layout:` field — see below.
3. `/delivery-crew:ma-plan`     preview of the stages and branches, no cost
4. `/agents`                    confirm the agents loaded
5. `/delivery-crew:ma-deliver`  runs the pipeline; approval required after the Tech Lead plan.
   Resume: `/delivery-crew:ma-deliver tech-lead`

Both `ma-plan` and `ma-deliver` also accept a Jira ticket id instead (`/delivery-crew:ma-plan PROJ-123`) — see
"Jira-first workflow" below.

Installed via `install.sh` instead of `/plugin`? Drop the `delivery-crew:` prefix — the same commands are just
`/ma-init`, `/ma-plan`, `/ma-deliver` (no plugin namespace exists for copied-in commands).

## New project vs existing project
| | New project | Existing project |
|---|---|---|
| `docs/brief.md` | `project_mode: new` (or omit) | `project_mode: existing` + `layout:` (real backend/web/mobile paths) |
| Pre-flight | — | Clean working tree, baseline tests passing, confirm the dev DB before running |
| First stage | product-owner | **codebase-discoverer** writes `docs/00-codebase-map.md` — review and correct it before continuing |
| Scaffolding | Allowed (the chosen stack's own scaffold tool) | Never — developers use the real paths and conventions found |
| Migrations | Normal | Additive only (no drops/renames), local/dev database only |
| Review | Check each stage's output | Also run `git diff --stat` after every developer stage; review the Tech Lead plan strictly |
| Merge | Normal PR | Normal PR + human code review, no exceptions |

## Delivery profiles
| type | Surfaces | Builders |
|---|---|---|
| api-only | API only | backend |
| web | API + admin and customer web | backend, web (full) |
| hybrid | API + full web + apps | backend, web (full), mobile per app |
| low-hybrid | API + admin web + apps | backend, web (admin), mobile per app |

Example block in docs/brief.md:
```
## Delivery profile
type: low-hybrid
mobile: customer, restaurant, partner
extra_agents: none
```

## Stack
Independent of the Delivery profile (which says *which surfaces* run), the Stack section says *which framework*
implements each one:
```
## Stack
backend: laravel          # laravel | node | django (default: laravel)
web: embedded             # embedded (server-rendered in the backend app) | spa (separate React app in web/) | none
mobile: flutter           # flutter | react-native | none
```
Omit the whole `## Stack` section to keep the default (laravel, embedded, flutter) — existing briefs from before
v1.3.0 keep working unchanged. Tech Lead reports which templating engine/ORM it picked for `embedded`/`node`/`django`
where the brief leaves that open.

## Core vs project-specific agents
- Core (in this plugin): Codebase Discoverer (existing projects only), PO, BA, UX Researcher, UI/UX Designer, Tech Lead, Backend, Web, Mobile, QA, DevOps.
- Project-specific roles (e.g. payments integrator, WordPress developer): add a subagent file in that project's
  `.claude/agents/` and list its name in `extra_agents`. It runs after the builders, before QA, on its own branch.
- Same role, several targets (e.g. three apps): the agent is run once per target, never cloned.

## Branches (nothing is merged or pushed by the crew)
feature/<m>-backend, feature/<m>-web (stacked on backend: review backend first), feature/<m>-mobile-<app>,
feature/<m>-devops, qa/<m>-integration (throwaway merge for QA).

## Jira-first workflow
`ma-plan` and `ma-deliver` both take an optional Jira ticket id argument — an alternative to hand-editing
`docs/brief.md`. The other `ma-*` commands only make sense with Jira:

| Command | Arguments | Does |
|---|---|---|
| `/ma-po-new` | `"task description"` | Drafts a new Jira ticket, grounded in the real codebase |
| `/ma-po-edit` | `"edit description" JIRA-ID` | Edits an existing ticket, checked against the codebase |
| `/ma-plan` | `[JIRA-ID]` | No argument: brief-first preview, as above. With a ticket id: syncs `docs/brief.md` from it first |
| `/ma-deliver` | `[JIRA-ID \| stage-name]` | No argument: brief-first pipeline, as above. A ticket id syncs the brief first; a stage name resumes from there |
| `/ma-deploy` | none | Deploys `dev` to staging — fixed target, ignores any argument |
| `/ma-document` | `JIRA-ID` | Writes up a shipped ticket to Confluence from the ticket, diff and QA notes |
| `/ma-qa` | `JIRA-ID` | Runs a real local-browser test (Playwright) from the ticket's QA hints, then attaches a PostHog session recording link to the ticket |

**Setup**:
1. Run `/delivery-crew:ma-init` (or `/ma-init`) — it now also writes a `## Integrations` block to
   `CLAUDE.md` with empty values: `jira_project_key`, `jira_site` (optional), `confluence_space` and
   `confluence_parent_page` (optional), `staging_deploy`, and — for `ma-qa` — `qa_local_url`, `posthog_host`,
   `posthog_project_id`. If `CLAUDE.md` already existed, it's not modified — the command instead prints the
   block for you to paste in.
   **`ma-qa` also needs a `POSTHOG_PERSONAL_API_KEY` environment variable** (Query Read +
   session_recording:read/write scopes) — never put this in `CLAUDE.md` or any other committed file, it's a
   secret; export it in your shell instead.
2. Register and authenticate the Atlassian MCP:
   ```
   claude mcp add --transport http atlassian https://mcp.atlassian.com/v2/mcp
   /mcp
   ```
   (OAuth 2.1; an API token is also supported as an alternative — see Atlassian's own docs for that flow.)
3. Recommended `.claude/settings.json` permissions — allow the read tools, leave every write tool on "ask" so
   nothing reaches Jira/Confluence without your approval, and never allow `git push`:
   ```json
   {
     "permissions": {
       "allow": [
         "mcp__atlassian__getAccessibleAtlassianResources",
         "mcp__atlassian__getJiraIssue",
         "mcp__atlassian__searchJiraIssuesUsingJql",
         "mcp__atlassian__getVisibleJiraProjects",
         "mcp__atlassian__getJiraProjectIssueTypesMetadata",
         "mcp__atlassian__getJiraIssueTypeMetaWithFields",
         "mcp__atlassian__getTransitionsForJiraIssue",
         "mcp__atlassian__getConfluencePage",
         "mcp__atlassian__searchConfluenceUsingCql"
       ],
       "ask": [
         "mcp__atlassian__createJiraIssue",
         "mcp__atlassian__editJiraIssue",
         "mcp__atlassian__addCommentToJiraIssue",
         "mcp__atlassian__transitionJiraIssue",
         "mcp__atlassian__createConfluencePage",
         "mcp__atlassian__updateConfluencePage"
       ],
       "deny": ["Bash(git push:*)"]
     }
   }
   ```

Every Jira fetch is cached to `docs/tickets/<ID>.md`; read-only commands fall back to that snapshot (with a
staleness warning) if Jira is unreachable. Writes always show a draft or diff first and wait for an explicit
yes — nothing is created, edited, transitioned, or posted on its own. See
[docs/guide.md §10](docs/guide.md#10-jira-first-workflow) for the full reference.

## Update
Edit agents/commands, bump `version` in `plugins/delivery-crew/.claude-plugin/plugin.json`, push, then in each
project: `/plugin marketplace update multi-agent`.

## Notes
- Models: Minimum Sonnet for PO/BA/UX/UI/Tech Lead/developers/QA/DevOps agent; you can change it from `model:` in agents/*.md.
- Runs on your Claude subscription inside Claude Code, not the API — no per-token billing, so no surprise costs
  piling up as the crew runs; usage limits apply instead. That's why we moved off the API-based CrewAI project:
  it bills per token and gets expensive fast at this scale. Reach for the API-based CrewAI project only if you
  specifically need client-facing automation outside Claude Code.
