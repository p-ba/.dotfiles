#!/usr/bin/env python3
"""Stop hook: show a desktop notification when the main session finishes a task.

Claude Code fires Stop for the main agent and SubagentStop for subagents. As a
guard, payloads carrying ``agent_id`` are skipped: it identifies a subagent or an
in-process teammate, whereas ``agent_type`` alone also appears in ``--agent``
sessions. A turn that ends while background agents are still running is not a
finished task either; the main session resumes when they report back and fires
Stop again.

On macOS with terminal-notifier installed, clicking the notification brings the
terminal app forward and, inside tmux, switches the most recently used client to
the pane Claude runs in. Otherwise the notification is informational only.
"""

import json
import os
import shlex
import shutil
import subprocess
import sys

TITLE = "Claude Code"
MAX_MESSAGE_CHARS = 200
AGENT_TASK_TYPES = {"subagent", "workflow", "teammate"}
DEFAULT_TERMINAL_BUNDLE_ID = "com.mitchellh.ghostty"


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


def tmux_focus_command() -> str | None:
    """Return a shell command that shows this pane in the most recently used tmux client."""
    pane = os.environ.get("TMUX_PANE")
    socket = os.environ.get("TMUX", "").split(",")[0]
    tmux = shutil.which("tmux")
    if not (pane and socket and tmux):
        return None
    # The click handler runs outside tmux with launchd's minimal PATH, so name the binary and server explicitly.
    return shlex.join([tmux, "-S", socket, "switch-client", "-t", pane])


def notify_clickable(group: str, subtitle: str, message: str) -> bool:
    notifier = shutil.which("terminal-notifier")
    if not notifier:
        return False
    # Processes started from a macOS app inherit its bundle ID, and tmux sessions keep the one from the
    # terminal that started the server.
    terminal = os.environ.get("__CFBundleIdentifier") or DEFAULT_TERMINAL_BUNDLE_ID
    command = [notifier, "-title", TITLE, "-subtitle", subtitle, "-group", group, "-activate", terminal]
    focus = tmux_focus_command()
    if focus:
        command += ["-execute", focus]
    # Pipe the message so a leading "-" or "[" in Claude's reply is never parsed as an option.
    result = subprocess.run(
        command, input=message, text=True, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    return result.returncode == 0


def notify(group: str, subtitle: str, message: str) -> None:
    if sys.platform == "darwin":
        # Fall back to a plain notification when terminal-notifier is missing or not yet allowed to post.
        if notify_clickable(group, subtitle, message):
            return
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

    # One notification slot per Claude session, so a newer finish replaces the older banner.
    group = f"claude-code-{payload.get('session_id') or 'session'}"
    cwd = payload.get("cwd") or os.getcwd()
    notify(group, os.path.basename(os.path.normpath(cwd)), summary(payload))
    return 0


if __name__ == "__main__":
    sys.exit(main())
