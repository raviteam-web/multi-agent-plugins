---
description: Apply an edit to an existing Jira ticket, checked against the codebase
argument-hint: "\"edit description\" JIRA-ID"
---
Parse `$ARGUMENTS`: the LAST token matching `[A-Z][A-Z0-9]+-\d+` is the ticket id; everything before it is the
edit instruction. Never treat the id as free text. If no id matches, or the edit text is empty, print the
usage line (`ma-po-edit "edit description" JIRA-ID`) and stop. If a token looks like an id but is malformed
(e.g. no digits), say so and stop.

## 1. Fetch
Call `getJiraIssue` for the id and refresh `docs/tickets/<ID>.md`. If Jira is unreachable, stop — this command
never edits from a stale snapshot.

## 2. Apply the edit
Change only the fields the edit instruction targets. Check the result against the codebase (Glob/Grep/Read)
and the ticket's other acceptance criteria for consistency; flag — don't silently resolve — any conflict you
find.

## 3. Approve, then write
Show a before/after diff of the changed fields only. On approval, call `editJiraIssue` and update the
snapshot. Add a Jira comment only if I explicitly ask for one. Never transition status here — that's
`ma-deliver`'s job, and even there only on request.
