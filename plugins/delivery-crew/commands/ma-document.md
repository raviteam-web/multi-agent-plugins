---
description: Write up a shipped ticket's changes to Confluence, from the ticket, the diff, and QA notes
argument-hint: "JIRA-ID"
---
Parse `$ARGUMENTS`: the LAST token matching `[A-Z][A-Z0-9]+-\d+` is the ticket id. If none matches, print the
usage line (`ma-document JIRA-ID`) and stop. If malformed, say so and stop.

## 1. Gather
Fetch the ticket (`getJiraIssue`, snapshot fallback from `docs/tickets/<ID>.md` is fine here — read-only). Then
gather: the brief or plan for this milestone, `git diff` for the ticket's branch(es), and any QA result notes
(`docs/10-qa.md` if present).

## 2. Draft
Produce: what changed and why, how it works, endpoints or screens affected, configuration or migration notes,
known limitations. Keep it factual — don't speculate beyond what the diff and ticket show.

## 3. Find the target page
Read `## Integrations` in `CLAUDE.md` for `confluence_space`/`confluence_parent_page`. Locate the target, in
order: (1) a page whose title contains the ticket key, via `searchConfluenceUsingCql`; (2) otherwise the page
named in `confluence_parent_page`; (3) otherwise propose creating a new page under `confluence_space`. If
`confluence_space` is missing and no existing page is found, stop and say which key to add.

## 4. Approve, then write
Show the proposed content (or a diff against the existing page) and wait for approval. On approval, call
`updateConfluencePage` or `createConfluencePage` and print the page URL.

If Confluence is unreachable, save the content to `docs/<KEY>.md` and stop.
