---
description: Preview the stages the crew would run; optionally sync docs/brief.md from a Jira ticket first
argument-hint: "[JIRA-ID]"
---
Classify `$ARGUMENTS` (if given): a Jira ticket id matches `[A-Z][A-Z0-9]+-\d+`. If the argument doesn't match
this shape, say it doesn't look like a Jira ticket id and stop.

## If no argument was given (brief-first)
Read `docs/brief.md` and validate it exactly as in the `ma-deliver` command's step 1. Then print:
1. The resolved profile (type, web scope, mobile apps, extra agents) and the resolved stack (backend, web mode,
   mobile framework — defaults applied if the `## Stack` section is absent).
2. A table of the stages that WOULD run (subagent, inputs, output file, branch), using the stage table in the
   `ma-deliver` command.
3. Any validation problems, each with the fix.
Do not run any subagent, create branches, or write files.

## If a Jira ticket id was given (Jira-first)
### 1. Fetch the ticket
Call `getJiraIssue`. If unreachable, fall back to `docs/tickets/<ID>.md` with a visible staleness warning. If
there is no snapshot either, stop — never invent ticket content.

### 2. Sync the brief
If `docs/brief.md` is missing, create it from the `ma-init` template (fill `## Project` from the repo and
`CLAUDE.md` where possible). Otherwise leave the existing brief alone except for this step.

Update **only** `## Current milestone` and `## Feature list` from the ticket: map the summary/description to
the milestone, and map each acceptance criterion or sub-task to a feature entry, keeping the ticket id as a
reference. Preserve every other section exactly as-is — `## Delivery profile`, `project_mode`, `layout:`,
`## Stack`, `## Exclusions`, `## Schema notes`, `## Database` — never touch these.

Show the brief diff (visible, no separate approval needed — it's a local file) and apply it.

Infer `## Delivery profile` only if that section is still unfilled; if filled, never change it; if it can't be
inferred, ask me once.

### 3. Preview
Run the same preview as the no-argument case above, with the ticket id and key in the output header. Do not
run any subagent, create branches, or write files beyond the brief sync above.
