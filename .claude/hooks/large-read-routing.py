#!/usr/bin/env python3
"""Route unbounded large main-session reads to Explore; not a shell security boundary."""
import json
import os
import shlex
import stat
import sys

DEFAULT_MIN_LINES = 350
CHUNK_SIZE = 8192
MAX_SCAN_BYTES = 8 * 1024 * 1024
SHELL_META = set("|&;<>`$(){}*?[]\\\n")
NON_TEXT_SUFFIXES = {".avif", ".bmp", ".gif", ".ico", ".jpeg", ".jpg", ".pdf", ".png", ".tif", ".tiff", ".webp"}


def threshold():
    try:
        value = int(os.environ.get("CLAUDE_BULK_READ_MIN_LINES", DEFAULT_MIN_LINES))
    except (TypeError, ValueError):
        return DEFAULT_MIN_LINES
    return value if value > 0 else DEFAULT_MIN_LINES


def bounded(value, minimum):
    return isinstance(value, int) and not isinstance(value, bool) and 0 < value <= minimum


def resolve(path, cwd):
    if not isinstance(path, str) or not path:
        return None
    return path if os.path.isabs(path) else os.path.join(cwd, path)


def large_text(path, minimum):
    """Bounded chunk scan; special, missing, unreadable, and binary files fail open."""
    try:
        if os.path.splitext(path)[1].lower() in NON_TEXT_SUFFIXES:
            return False
        descriptor = os.open(path, os.O_RDONLY | getattr(os, "O_NONBLOCK", 0))
        try:
            if not stat.S_ISREG(os.fstat(descriptor).st_mode):
                return False
            lines, saw_data, last = 0, False, b""
            scanned = 0
            while True:
                chunk = os.read(descriptor, CHUNK_SIZE)
                if not chunk:
                    break
                saw_data = True
                scanned += len(chunk)
                if b"\0" in chunk:
                    return False
                lines += chunk.count(b"\n")
                if lines > minimum:
                    return True
                if scanned >= MAX_SCAN_BYTES:
                    return False
                last = chunk[-1:]
            return saw_data and lines + (last != b"\n") > minimum
        finally:
            os.close(descriptor)
    except (OSError, ValueError):
        return False


def simple_command(command):
    if not isinstance(command, str) or not command or any(c in command for c in SHELL_META):
        return None
    try:
        words = shlex.split(command, posix=True)
    except ValueError:
        return None
    if not words or any(not word or any(c in word for c in SHELL_META) for word in words):
        return None
    name = os.path.basename(words[0])
    return (name, words[1:]) if name in {"cat", "head", "tail", "less", "more"} else None


def bash_paths(command, cwd, minimum):
    """Only recognize literal cat/head/tail/less/more; ambiguous shell remains native."""
    parsed = simple_command(command)
    if parsed is None:
        return None
    name, args = parsed
    if name in {"head", "tail"}:
        files, index, safe_output = [], 0, 10 <= minimum
        while index < len(args):
            arg = args[index]
            if arg == "--":
                files.extend(args[index + 1:])
                break
            if arg in {"-n", "--lines"}:
                if index + 1 == len(args):
                    return None
                count = args[index + 1]
                if count.isdigit():
                    safe_output = bounded(int(count), minimum)
                elif name == "tail" and count.startswith("+") and count[1:].isdigit():
                    safe_output = False
                else:
                    return None
                index += 2
            elif arg.startswith("--lines="):
                count = arg[8:]
                if count.isdigit():
                    safe_output = bounded(int(count), minimum)
                elif name == "tail" and count.startswith("+") and count[1:].isdigit():
                    safe_output = False
                else:
                    return None
                index += 1
            elif arg.startswith("-") and arg[1:].isdigit():
                safe_output = bounded(int(arg[1:]), minimum)
                index += 1
            elif name == "tail" and arg.startswith("+") and arg[1:].isdigit():
                safe_output = False
                index += 1
            elif arg.startswith("-"):
                return None
            else:
                files.append(arg)
                index += 1
        # Defaults emit ten lines; only known bounded numeric options are safe.
        if not files:
            return None
        return [] if safe_output else [resolve(item, cwd) for item in files]
    if not args or any(arg.startswith("-") and arg != "--" for arg in args):
        return None
    return [resolve(arg, cwd) for arg in args if arg != "--"]


def deny(paths):
    reason = ("This unbounded read exceeds the configured large-file threshold. Delegate a focused question about "
              f"{', '.join(paths)} to Explore and request concise path:line evidence, use a positive bounded Read "
              "limit for local reasoning, or start with CLAUDE_ALLOW_LARGE_READS=1.")
    json.dump({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
               "permissionDecisionReason": reason}}, sys.stdout)


def main():
    if os.environ.get("CLAUDE_ALLOW_LARGE_READS") == "1":
        return
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, TypeError, ValueError):
        return
    if not isinstance(payload, dict):
        return
    if "agent_id" in payload or "agent_type" in payload:
        return
    data = payload.get("tool_input")
    if not isinstance(data, dict):
        return
    minimum = threshold()
    cwd = payload.get("cwd") if isinstance(payload.get("cwd"), str) else os.getcwd()
    paths = []
    if payload.get("tool_name") == "Read":
        path = resolve(data.get("file_path"), cwd)
        if not bounded(data.get("limit"), minimum) and path and large_text(path, minimum):
            paths = [path]
    elif payload.get("tool_name") == "Bash":
        candidates = bash_paths(data.get("command"), cwd, minimum)
        if candidates is not None:
            paths = [path for path in candidates if path and large_text(path, minimum)]
    if paths:
        deny(paths)


if __name__ == "__main__":
    main()
