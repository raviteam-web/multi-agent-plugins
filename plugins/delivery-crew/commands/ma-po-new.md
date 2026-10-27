---
description: Draft a Jira ticket from a rough task description, grounded in the real codebase
argument-hint: "\"task description\""
---
Turn `$ARGUMENTS` into a Jira ticket the crew can implement with minimum clarification. If empty, print the
usage line (`ma-po-new "task description"`) and stop.

## 1. Preflight
Read `## Integrations` in `CLAUDE.md`. If missing or `jira_project_key` is empty, stop and say which key to add
(see `ma-init`). Confirm the Atlassian MCP is connected (`getAccessibleAtlassianResources`); if not, tell me
to run `claude mcp add --transport http atlassian https://mcp.atlassian.com/v2/mcp` then `/mcp`, and stop.

## 2. Ground it in the code
Using Glob/Grep/Read (read-only), find the models, controllers, routes, Filament/admin resources, Blade views
and mobile screens relevant to the description. Work only from what you find — never assume a pattern exists.

## 3. Draft the ticket
- **Summary**: short, imperative.
- **Description**: the context and the problem or goal.
- **Acceptance criteria**: Given/When/Then, each independently testable.
- **Technical notes**: affected modules/files, routes/endpoints, schema changes, existing patterns to follow.
- **Out of scope**.
- **QA hints**: URLs/screens, steps, test data — feeds the future `ma-qa` command.
- **Open questions**: anything you couldn't settle from the code. Never guess here.

Pick the issue type from `getJiraProjectIssueTypesMetadata`/`getJiraIssueTypeMetaWithFields` for
`jira_project_key` — default Task, Bug only if the description clearly reads as a defect.

## 4. Approve, then create
Show the full draft and wait for an explicit yes. On approval, call `createJiraIssue`, print the new key and
URL, and save a snapshot to `docs/tickets/<KEY>.md` (summary, description, acceptance criteria, status,
fetched-at timestamp). On rejection, apply the requested changes and show the draft again — never create
anything without approval.

If Jira is unreachable at any point, save the draft to `docs/tickets/draft-<timestamp>.md` and stop.
