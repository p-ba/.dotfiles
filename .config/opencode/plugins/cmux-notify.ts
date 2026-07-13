import { execFile } from "node:child_process"
import { promisify } from "node:util"
import { Plugin } from "@opencode-ai/plugin/v2"

const NOTIFIED_SESSIONS = new Set<string>()
const execFileAsync = promisify(execFile)

export default Plugin.define({
  id: "pavel.cmux-notify",
  setup: async (ctx) => {
    const controller = new AbortController()
    const task = (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        if (event.type !== "session.idle") continue

        const sessionID = event.data.sessionID
        if (NOTIFIED_SESSIONS.has(sessionID)) continue

        const session = await ctx.session.get({ sessionID })
        if (session?.parentID) continue

        NOTIFIED_SESSIONS.add(sessionID)

        const sessionDirectory = session.location.directory
        const cwd = sessionDirectory.replace(/^.*\//, "") || sessionDirectory
        const title = session?.title?.trim() || "OpenCode session finished"
        const shortSessionID = sessionID.slice(0, 8)
        const body = `${title}\nSession ${shortSessionID}`

        await execFileAsync("cmux", [
          "notify",
          "--title",
          "opencode: idle",
          "--subtitle",
          cwd,
          "--body",
          body,
        ]).catch(() => {})
      }
    })()

    return async () => {
      controller.abort()
      await task.catch(() => {})
    }
  },
})
