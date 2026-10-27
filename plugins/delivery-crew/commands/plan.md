---
description: Show the stages and branches the crew would run for this project, without running any agent
---
Read `docs/brief.md` and validate it exactly as in the `deliver` command's step 1. Then print:
1. The resolved profile (type, web scope, mobile apps, extra agents) and the resolved stack (backend, web mode, mobile framework — defaults applied if the `## Stack` section is absent).
2. A table of the stages that WOULD run (subagent, inputs, output file, branch), using the stage table in the deliver command.
3. Any validation problems, each with the fix.
Do not run any subagent, create branches, or write files.
