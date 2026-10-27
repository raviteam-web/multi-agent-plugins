---
description: Sync docs/brief.md from a Jira ticket, then run the delivery pipeline (Jira-first version of deliver)
argument-hint: "JIRA-ID"
---
Parse `$ARGUMENTS`: the LAST token matching `[A-Z][A-Z0-9]+-\d+` is the ticket id. If none matches, print the
usage line (`ma-deliver JIRA-ID`) and stop. If malformed, say so and stop.

## 1. Sync
Run the same fetch-and-sync as `ma-plan` steps 1-2 (fetch ticket with snapshot fallback, update only
`## Current milestone`/`## Feature list`, preserve every other brief section, infer/ask on Delivery profile).

## 2. Run the pipeline
Run the identical pipeline as the `deliver` command (same validation, stage table, and gates — the Tech Lead
approval gate and the QA NO-GO stop are never skipped), with these changes:
- Branch names include the ticket key: `feature/<KEY>-<milestone-slug>-backend`, etc.
- Commit messages are prefixed `<KEY>: <stage>`.

## 3. Finish
After the pipeline finishes, offer — don't auto-post — a Jira comment summarizing the branches created, the
stages run, and the QA result. Also list the available transitions via `getTransitionsForJiraIssue` and offer
them; never pick one on your own. Post the comment or apply the transition only on explicit approval.

If Jira is unreachable at this point, print the comment text so I can paste it in myself.
