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
Private repo: make sure `git` already has access (SSH key or `gh auth login`).
Local test without Git: `/plugin marketplace add ./path/to/this/repo`

No `/plugin` support in your VS Code panel? Run `./install.sh <path-to-project>` from a clone of this repo instead —
it copies the agents/commands straight into that project's `.claude/` folder and writes a version stamp.

## Use
1. `/delivery-crew:crew-init`  creates CLAUDE.md and docs/brief.md (never overwrites)
2. Fill in `docs/brief.md`: milestone, features, Delivery profile, exclusions, database (PENDING blocks the run).
   Adding an existing codebase (not a fresh repo)? Set `project_mode: existing` and the `layout:` field — see below.
3. `/delivery-crew:plan`     preview of the stages and branches, no cost
4. `/agents`                 confirm the agents loaded
5. `/delivery-crew:deliver`  runs the pipeline; approval required after the Tech Lead plan.
   Resume: `/delivery-crew:deliver tech-lead`

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

## Update
Edit agents/commands, bump `version` in `plugins/delivery-crew/.claude-plugin/plugin.json`, push, then in each
project: `/plugin marketplace update multi-agent`.

## Notes
- Models: Haiku for PO/BA/UX/UI/DevOps; Sonnet for Tech Lead, developers, QA (edit `model:` in agents/*.md).
- Runs on your Claude subscription inside Claude Code; usage limits apply. For client-facing automation use the API-based CrewAI project.
