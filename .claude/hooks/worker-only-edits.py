#!/usr/bin/env python3
"""PreToolUse hook: reserve file-editing tools for the worker subagent.

Claude Code passes the tool call as JSON on stdin. Inside a subagent the payload
carries ``agent_type``; the main session has none. Deny edits from anything but
the allowed agents so the cheap worker model makes every change and the session
model only briefs and reviews. Start Claude with ``CLAUDE_ALLOW_MAIN_EDITS=1`` to
switch the rule off for a session.
"""

import json
import os
import sys

ALLOWED_AGENTS = {"worker", "statusline-setup"}


def main() -> int:
    if os.environ.get("CLAUDE_ALLOW_MAIN_EDITS") == "1":
        return 0

    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    agent_type = payload.get("agent_type")
    if agent_type in ALLOWED_AGENTS:
        return 0

    caller = f"subagent '{agent_type}'" if agent_type else "the main session"
    reason = (
        f"{payload.get('tool_name', 'This tool')} is reserved for the worker agent; {caller} may not edit files. "
        "Delegate the change to `worker` with a self-contained brief (see ~/.claude/CLAUDE.md), "
        "or start Claude with CLAUDE_ALLOW_MAIN_EDITS=1 to disable this rule for a session."
    )
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        },
        sys.stdout,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
