import type { Plugin } from "@opencode-ai/plugin"

const GOAL_FILE = ".opencode/goal.md"
const MAX_GOAL_CHARS = 12000

declare const Bun:
  | {
      file(path: string): {
        text(): Promise<string>
      }
    }
  | undefined

async function readTextFile(path: string): Promise<string | null> {
  try {
    if (typeof Bun !== "undefined" && typeof Bun.file === "function") {
      return await Bun.file(path).text()
    }
  } catch {
    return null
  }

  return null
}

function buildInjectedSystem(goal: string): string {
  const trimmed = goal.trim()
  const truncated = trimmed.slice(0, MAX_GOAL_CHARS)
  const wasTruncated = trimmed.length > MAX_GOAL_CHARS

  return [
    `Persistent project goal from ${GOAL_FILE}:`,
    "This is standing project context that persists across sessions.",
    `Use this goal as ongoing guidance, keep ${GOAL_FILE} updated when explicitly asked via /goal, and ask if it conflicts with the user's current request.`,
    "",
    truncated,
    wasTruncated
      ? `\n[Goal truncated to the first ${MAX_GOAL_CHARS} characters.]`
      : "",
  ]
    .filter((part) => part.length > 0)
    .join("\n")
}

const PersistedGoalPlugin = (async ({ directory, worktree }) => {
  const candidates = Array.from(
    new Set(
      [worktree, directory].filter(
        (value): value is string => typeof value === "string" && value.length > 0,
      ),
    ),
  )

  return {
    "experimental.chat.system.transform": async (_input, output) => {
      for (const base of candidates) {
        const goalPath = `${base}/${GOAL_FILE}`
        const goal = await readTextFile(goalPath)
        if (!goal) continue

        const trimmed = goal.trim()
        if (!trimmed) continue

        output.system.push(buildInjectedSystem(trimmed))
        return
      }
    },
  }
}) satisfies Plugin

export default PersistedGoalPlugin
