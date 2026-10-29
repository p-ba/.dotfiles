#!/usr/bin/env python3
"""Stop hook: show a desktop notification when the main session finishes a task.

Claude Code fires Stop for the main agent and SubagentStop for subagents. As a
guard, payloads carrying ``agent_id`` are skipped: it identifies a subagent or an
in-process teammate, whereas ``agent_type`` alone also appears in ``--agent``
sessions. A turn that ends while background agents are still running is not a
finished task either; the main session resumes when they report back and fires
Stop again.
"""

import json
import os
import shutil
import subprocess
import sys

TITLE = "Claude Code"
MAX_MESSAGE_CHARS = 200
AGENT_TASK_TYPES = {"subagent", "workflow", "teammate"}


def summary(payload: dict) -> str:
    """Return the first non-empty line of Claude's final reply, without Markdown markers."""
    text = payload.get("last_assistant_message")
    if isinstance(text, str):
        for line in text.splitlines():
            line = line.replace("**", "").replace("`", "").lstrip("#>-*+ \t").strip()
            if line:
                if len(line) > MAX_MESSAGE_CHARS:
                    line = line[: MAX_MESSAGE_CHARS - 1].rstrip() + "…"
                return line
    return "Task finished"


def notify(subtitle: str, message: str) -> None:
    if sys.platform == "darwin":
        # Pass text as arguments so quotes in the reply never reach AppleScript source.
        command = [
            "osascript",
            "-e",
            "on run argv",
            "-e",
            "display notification (item 1 of argv) with title (item 2 of argv) subtitle (item 3 of argv)",
            "-e",
            "end run",
            "--",
            message,
            TITLE,
            subtitle,
        ]
    elif shutil.which("notify-send"):
        command = ["notify-send", "--", f"{TITLE}: {subtitle}", message]
    else:
        return
    subprocess.run(command, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return 0
    if not isinstance(payload, dict) or payload.get("agent_id"):
        return 0

    tasks = payload.get("background_tasks")
    if isinstance(tasks, list) and any(
        isinstance(task, dict) and task.get("type") in AGENT_TASK_TYPES for task in tasks
    ):
        return 0

    cwd = payload.get("cwd") or os.getcwd()
    notify(os.path.basename(os.path.normpath(cwd)), summary(payload))
    return 0


if __name__ == "__main__":
    sys.exit(main())
