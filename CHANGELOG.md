# Changelog
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
