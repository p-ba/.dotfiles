---
description: Clear the persistent project goal.
---

If the user has explicitly confirmed they want to clear the persistent goal, remove or empty `.opencode/goal.md` in the current project.

Treat `$ARGUMENTS` as the user's confirmation text; only clear the file when it clearly confirms deletion.

If the file is missing, say no persistent goal is set.

If confirmation is not explicit, ask for confirmation and do not modify anything.
