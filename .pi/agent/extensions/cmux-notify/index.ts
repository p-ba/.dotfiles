import type {
	AgentSettledEvent,
	ExtensionAPI,
	ExtensionContext,
	SessionEntry,
} from "@earendil-works/pi-coding-agent";
import { spawnSync } from "node:child_process";
import path from "node:path";

const CUSTOM_TYPE = "cmux-notify";
const notifiedSessions = new Set<string>();

function getShortStat(cwd: string): string {
	const result = spawnSync("git", ["diff", "--shortstat"], {
		cwd,
		encoding: "utf8",
		stdio: ["ignore", "pipe", "ignore"],
	});

	const output = typeof result.stdout === "string" ? result.stdout.trim() : "";
	return result.status === 0 && output ? output : "No file changes";
}

function getBasename(cwd: string): string {
	const base = path.basename(cwd);
	return base || cwd || "/";
}

function hasNotifyMarker(ctx: ExtensionContext): boolean {
	return ctx.sessionManager.getEntries().some(
		(entry: SessionEntry) => entry.type === "custom" && entry.customType === CUSTOM_TYPE,
	);
}

function getUserText(content: unknown): string | undefined {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return undefined;
	return content
		.map((part: unknown) => (part && typeof part === "object" && "type" in part && part.type === "text" && "text" in part ? String(part.text) : ""))
		.join("\n")
		.trim();
}

function getSessionTitle(ctx: ExtensionContext): string {
	const name = ctx.sessionManager.getSessionName()?.trim();
	if (name) return name;

	for (const entry of ctx.sessionManager.getEntries()) {
		if (entry.type !== "message" || entry.message?.role !== "user") continue;
		const text = getUserText(entry.message.content)?.replace(/\s+/g, " ").trim();
		if (!text) continue;
		return text.length > 120 ? `${text.slice(0, 117)}...` : text;
	}

	return "Pi session finished";
}

export default function (pi: ExtensionAPI) {
	pi.on("agent_settled", async (_event: AgentSettledEvent, ctx: ExtensionContext) => {
		if (ctx.mode !== "tui") return;

		const sessionFile = ctx.sessionManager.getSessionFile();
		if (!sessionFile) return;

		const header = ctx.sessionManager.getHeader();
		if (header?.parentSession) return;

		const sessionId = ctx.sessionManager.getSessionId();
		if (notifiedSessions.has(sessionId) || hasNotifyMarker(ctx)) return;

		notifiedSessions.add(sessionId);
		pi.appendEntry(CUSTOM_TYPE, {
			notified: true,
			sessionId,
		});

		const title = getSessionTitle(ctx);
		const shortStat = getShortStat(ctx.cwd);
		const shortSessionId = sessionId.slice(0, 8);
		const subtitle = getBasename(ctx.cwd);
		const body = `${title}\n${shortStat}\nSession ${shortSessionId}`;

		const availability = spawnSync("sh", ["-c", "command -v cmux >/dev/null 2>&1"], {
			encoding: "utf8",
			stdio: ["ignore", "ignore", "ignore"],
		});
		if (availability.status !== 0) return;

		const notification = spawnSync("cmux", ["notify", "--title", "pi: idle", "--subtitle", subtitle, "--body", body], {
			encoding: "utf8",
			stdio: ["ignore", "ignore", "ignore"],
		});

		if (notification.status !== 0) return;
	});
}
