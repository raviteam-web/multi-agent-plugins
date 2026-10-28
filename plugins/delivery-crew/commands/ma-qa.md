---
description: Run a real browser test for a Jira ticket locally and attach the PostHog session recording to it
argument-hint: "JIRA-ID"
---
Parse `$ARGUMENTS`: the LAST token matching `[A-Z][A-Z0-9]+-\d+` is the ticket id. If none matches, print the
usage line (`ma-qa JIRA-ID`) and stop. If malformed, say so and stop.

## 1. Preflight
Read `## Integrations` in `CLAUDE.md`. Stop and name whichever is missing: `qa_local_url`, `posthog_host`,
`posthog_project_id`. Then confirm the `POSTHOG_PERSONAL_API_KEY` environment variable is set — **never read a
PostHog key from `CLAUDE.md` or any committed file**, it's a secret; if it's not set, stop and tell me to
export it. Confirm the Atlassian MCP is connected (`getAccessibleAtlassianResources`); if not, tell me to run
`claude mcp add --transport http atlassian https://mcp.atlassian.com/v2/mcp` then `/mcp`, and stop.

## 2. Fetch the ticket
Call `getJiraIssue`. If unreachable, fall back to `docs/tickets/<ID>.md` with a visible staleness warning; stop
if there's no snapshot either. Read its QA hints section. If there's no QA hints section (the ticket wasn't
created by `ma-po-new`, or was edited since), fall back to the Acceptance Criteria section instead, and say so.

## 3. Ensure Playwright is set up
Check for `@playwright/test` in `package.json`. If missing, show me the exact commands
(`npm install -D @playwright/test && npx playwright install`) and wait for my confirmation before running them
— this changes the project's own dependencies and lockfile. If there's no `playwright.config.ts`, propose a
minimal one with `baseURL` set to `qa_local_url`, show it, and wait for confirmation before writing it.

## 4. Generate or reuse the test spec
Target file: `tests/e2e/<ID>.spec.ts`.

**Before writing it for the first time**, check the project's `.gitignore` for an entry covering `tests/e2e/`;
if there isn't one, append one with a short comment (e.g. `# crew-generated QA specs (ma-qa) — local only`).
These specs are local, per-machine QA artifacts, not part of the product's own committed test suite.

If `tests/e2e/<ID>.spec.ts` doesn't already exist, translate the QA hints (or acceptance criteria) into real
Playwright steps: navigate, fill, click, assert — whatever the ticket actually describes, don't invent steps it
doesn't mention. Immediately after the first `page.goto`, inject this tagging step so the session can be found
in PostHog later:
```ts
await page.evaluate((runId) => (window as any).posthog?.capture('qa_run_marker', { run_id: runId }), process.env.QA_RUN_ID);
```
Read `process.env.QA_RUN_ID` at test time — never hardcode a run id — so the same spec gets a fresh,
correlatable id on every run. If the file already exists, reuse it as-is; regenerating it is out of scope here.

## 5. Check the target is reachable
`curl -sf qa_local_url` (or equivalent). If it fails, stop and tell me to start the local dev server first —
this command never starts one itself.

## 6. Run it
Generate a run id, e.g. `<ID>-$(date +%s)`. Run:
```
QA_RUN_ID=<run-id> npx playwright test tests/e2e/<ID>.spec.ts
```
Capture pass/fail per test from the output and exit status.

## 7. Find the PostHog recording
Wait briefly for PostHog to ingest the event, then run:
```
POST {posthog_host}/api/projects/{posthog_project_id}/query/
Authorization: Bearer $POSTHOG_PERSONAL_API_KEY
{"query": {"kind": "HogQLQuery", "query": "SELECT distinct $session_id FROM events WHERE properties.run_id = '<run-id>' AND timestamp >= now() - INTERVAL 1 DAY"}}
```
If no `$session_id` comes back, wait longer and retry once. If still nothing, continue without a recording
link — note in the report that PostHog didn't produce one (its SDK may not be active on this page, or
ingestion is delayed) rather than blocking the whole command on it.

If a `$session_id` was found, make it shareable:
```
PATCH {posthog_host}/api/projects/{posthog_project_id}/session_recordings/{session_id}/sharing
Authorization: Bearer $POSTHOG_PERSONAL_API_KEY
{"enabled": true}
```
Build the link from the response's `accessToken`: `{posthog_host}/embedded/{accessToken}`.

## 8. Write the report
`docs/tickets/<ID>-qa.md`: test results, an acceptance-criteria pass/fail table, defects found (if any), the
recording link (or a note on why there isn't one), and a last line that is exactly `RECOMMENDATION: GO` or
`RECOMMENDATION: NO-GO`.

## 9. Approve, then post
Show the proposed Jira comment (report summary + recording link) and wait for an explicit yes before calling
`addCommentToJiraIssue`. Never transition the ticket's status here. If Jira is unreachable, print the comment
text so I can paste it in myself.
