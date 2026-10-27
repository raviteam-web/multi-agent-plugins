---
description: Sync docs/brief.md from a Jira ticket, then preview the stages (Jira-first version of plan)
argument-hint: "JIRA-ID"
---
Parse `$ARGUMENTS`: the LAST token matching `[A-Z][A-Z0-9]+-\d+` is the ticket id. If none matches, print the
usage line (`ma-plan JIRA-ID`) and stop. If malformed, say so and stop.

## 1. Fetch the ticket
Call `getJiraIssue`. If unreachable, fall back to `docs/tickets/<ID>.md` with a visible staleness warning. If
there is no snapshot either, stop — never invent ticket content.

## 2. Sync the brief
If `docs/brief.md` is missing, create it from the `crew-init` template (fill `## Project` from the repo and
`CLAUDE.md` where possible). Otherwise leave the existing brief alone except for step 3.

Update **only** `## Current milestone` and `## Feature list` from the ticket: map the summary/description to
the milestone, and map each acceptance criterion or sub-task to a feature entry, keeping the ticket id as a
reference. Preserve every other section exactly as-is — `## Delivery profile`, `project_mode`, `layout:`,
`## Stack`, `## Exclusions`, `## Schema notes`, `## Database` — never touch these.

Show the brief diff (visible, no separate approval needed — it's a local file) and apply it.

Infer `## Delivery profile` only if that section is still unfilled; if filled, never change it; if it can't be
inferred, ask me once.

## 3. Preview
Run the same validation and stage-table logic as the `plan` command (its steps 1-2), with the ticket id and
key in the output header. Do not run any subagent, create branches, or write files beyond the brief sync above.
