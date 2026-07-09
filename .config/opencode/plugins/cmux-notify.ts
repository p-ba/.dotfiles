import type { Plugin } from "@opencode-ai/plugin"

const NOTIFIED_SESSIONS = new Set<string>()

export const CmuxNotifyPlugin = (async ({ $, client, directory }) => {
  return {
    event: async ({ event }) => {
      if (event.type !== "session.idle") return

      const sessionID = event.properties.sessionID
      if (NOTIFIED_SESSIONS.has(sessionID)) return

      const result = await client.session.get({
        path: { id: sessionID },
        query: { directory },
      })
      const session = result.data
      if (session?.parentID) return

      NOTIFIED_SESSIONS.add(sessionID)

      const sessionDirectory = session?.directory ?? directory
      const cwd = sessionDirectory.replace(/^.*\//, "") || sessionDirectory
      const title = session?.title?.trim() || "OpenCode session finished"
      const shortSessionID = sessionID.slice(0, 8)
      const summary = session?.summary
      const changes = summary
        ? `${summary.files} file${summary.files === 1 ? "" : "s"}, +${summary.additions} -${summary.deletions}`
        : "No file changes"
      const body = `${title}\n${changes}\nSession ${shortSessionID}`

      await $`sh -c 'command -v cmux >/dev/null 2>&1'`
        .quiet()
        .then(async () => {
          await $`cmux notify --title ${"opencode: idle"} --subtitle ${cwd} --body ${body}`.quiet()
        })
        .catch(() => {})
    },
  }
}) satisfies Plugin

export default CmuxNotifyPlugin
