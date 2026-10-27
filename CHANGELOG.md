# Changelog
## 1.5.0
- **Breaking**: every command is now prefixed `ma-` (for "multi-agent"), so it's always clear which commands
  belong to this crew versus Claude Code's own built-ins. `crew-init` → `ma-init`. `plan` and `deliver` are
  retired as separate commands; their behavior is folded into `ma-plan`/`ma-deliver` as the no-argument case.
- `ma-plan [JIRA-ID]` and `ma-deliver [JIRA-ID | stage-name]` now take an optional argument: with none, they run
  exactly as the old `plan`/`deliver` did (brief-first); with a Jira ticket id, they sync `docs/brief.md` from
  it first, Jira-first style; `ma-deliver` also still accepts a stage name to resume from, classified by shape
  (uppercase-id vs. known lowercase stage name) since both share the one argument slot.
- Projects on 1.4.0 or earlier must update: re-run `install.sh`/`/plugin marketplace update`, then use
  `ma-init`/`ma-plan`/`ma-deliver` going forward — `crew-init`, `plan` and `deliver` no longer exist.

## 1.4.0
- New Jira-first command set (additive — brief-first `crew-init`/`plan`/`deliver` are unchanged): `ma-po-new`,
  `ma-po-edit`, `ma-plan`, `ma-deliver`, `ma-deploy`, `ma-document`. Reads/writes Jira and Confluence via the
  Atlassian MCP (`claude mcp add --transport http atlassian https://mcp.atlassian.com/v2/mcp`); every write is
  shown as a draft/diff and requires explicit approval; ticket fetches are cached to `docs/tickets/<ID>.md` for
  offline fallback on read-only commands.
- `crew-init` now also writes a `## Integrations` section to `CLAUDE.md` (`jira_project_key`, `jira_site`,
  `confluence_space`, `confluence_parent_page`, `staging_deploy`), empty by default; if `CLAUDE.md` already
  exists it prints the block instead of modifying the file, keeping the never-overwrite rule.
- Fixed `crew-init`/`plan`/`deliver` hard-coding `/delivery-crew:...` in their own instruction text and in the
  generated `CLAUDE.md` template; they now read correctly whether invoked with the marketplace's
  `delivery-crew:` prefix or bare (`install.sh` route, no plugin namespace) — this was the cause of `/plan`
  colliding with Claude Code's own built-in `/plan` (plan mode) for install.sh-route projects.
- `ma-qa` is intentionally not included yet; it's being designed separately (local Playwright, no MCP).

## 1.3.0
- Stack is no longer fixed to Laravel+Flutter. New `## Stack` section in docs/brief.md: `backend: laravel|node|django`,
  `web: embedded|spa|none`, `mobile: flutter|react-native|none`.
- Backward compatible: omitting `## Stack` (or any field in it) defaults to `laravel`/`embedded`/`flutter`, i.e. exact
  v1.2.0 behavior. Existing briefs need no changes.
- Tech Lead, backend/web/mobile-developer, devops-engineer and qa-engineer now read the resolved stack and adapt
  scope, conventions, scaffold commands and test/CI commands accordingly, instead of assuming Laravel/Flutter.
- codebase-discoverer now detects the real stack per surface from whatever manifests it finds (composer.json vs
  package.json vs manage.py; Blade/Django templates/EJS vs a separate React app; pubspec.yaml vs React Native), and
  flags any mismatch against the brief's `## Stack` section instead of assuming Laravel+Flutter.
- `/delivery-crew:deliver` and `/delivery-crew:plan` validate the `## Stack` section's values.

## 1.2.0
- Renamed `init` command to `crew-init` (avoids clashing with Claude Code's built-in `/init`)
- Existing-project support: `project_mode: new|existing` and `layout:` fields in docs/brief.md
- New codebase-discoverer agent and Discover stage (project_mode: existing only), writes docs/00-codebase-map.md for human review before Tech Lead runs
- Developer agents (backend/web/mobile) never scaffold under project_mode: existing; they use the real layout and existing conventions, and migrations are additive-only
- Tech Lead extends the existing schema/repo structure instead of redesigning it when a codebase map is present
- Added install.sh for VS Code-panel users who can't use /plugin marketplace
- Renamed marketplace to `multi-agent` and repo/folder to `multi-agent-plugins` (README and all references updated)

## 1.1.0
- Delivery profiles: api-only, web, hybrid, low-hybrid (set in docs/brief.md)
- Frontend developer split into web-developer (Laravel Blade) and mobile-developer (Flutter, one run per app)
- /delivery-crew:plan previews the stages without running agents
- Agents take input/output paths from the orchestrator; QA runs on a merged integration branch
- Fixed YAML quoting of argument-hint
- Project-specific agents via extra_agents
## 1.0.0
- Initial 9-agent pipeline
