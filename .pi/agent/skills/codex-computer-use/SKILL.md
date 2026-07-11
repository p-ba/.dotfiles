---
name: codex-computer-use
description: Delegates browser and macOS desktop interaction to the local Codex CLI using Pi's currently selected model. Use when the user asks to operate a website, browser, or desktop application through a GUI.
---

# Codex Computer Use

Use the `codex_computer_use` tool for tasks that require browser or macOS desktop interaction. The extension launches local Codex CLI with Pi's active model, so the model selection stays aligned with the current session.

## When to use it

- Navigating a website or using a browser UI
- Operating a macOS application or desktop workflow
- Performing a multi-step GUI task that Codex's Computer Use, Chrome, or Browser plugins can complete

Do **not** use it for ordinary repository edits, terminal commands, or read-only web research when Pi's normal tools are sufficient.

## Delegation prompt

Give Codex a complete, bounded task. Include:

- the target app or URL;
- the desired outcome;
- relevant constraints and information already supplied by the user; and
- whether the final external action is explicitly authorized.

Do not include secrets unless the user explicitly supplies them for that operation. Authentication, MFA, and CAPTCHA steps must be left for the user.

For actions with meaningful external effects (sending, submitting, publishing, buying, deleting, or changing settings), delegate only up to the final action unless the user explicitly authorized that exact action. Report the Codex result clearly to the user.
