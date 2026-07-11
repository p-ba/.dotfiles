import { mkdtemp, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	formatSize,
	truncateHead,
	type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const CodexComputerUseParams = Type.Object({
	task: Type.String({
		description:
			"A complete computer-use task for Codex, including the target site/app, desired outcome, and any safe stopping point.",
	}),
});

function buildPrompt(task: string): string {
	return `You are a delegated computer-use agent. Complete this explicit user request using the enabled Chrome, Browser, or Computer Use tools; prefer Chrome for browser tasks.\n\nUser request:\n${task}\n\nRules:\n- Operate the visible browser or macOS desktop rather than editing local project files or using direct HTTP APIs, unless the user explicitly requests otherwise.\n- Do not bypass logins, MFA, CAPTCHAs, or other access controls. Ask the user to take over when authentication or a CAPTCHA is required.\n- Stop and report before any irreversible or externally visible action, including submitting a form, sending a message, publishing, placing an order, making a payment, deleting data, or changing account/security settings, unless the user explicitly requested that exact final action.\n- Do not reveal secrets, credentials, or private data in the final response.\n- End with a concise summary of what you completed, what needs user input, and any remaining step.`;
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "codex_computer_use",
		label: "Codex Computer Use",
		description: [
			"Delegate a browser or macOS desktop GUI task to the locally installed Codex CLI.",
			"It runs Codex with Pi's currently selected model and returns Codex's final report.",
			`Output is truncated to ${DEFAULT_MAX_LINES} lines or ${formatSize(DEFAULT_MAX_BYTES)}; full output is saved to a temporary file when needed.`,
		].join(" "),
		promptSnippet: "Delegate browser or macOS desktop GUI tasks to Codex CLI with the current Pi model",
		promptGuidelines: [
			"Use codex_computer_use for browser or macOS desktop interaction that should be performed by Codex's Computer Use, Chrome, or Browser plugins; do not use it for ordinary local coding or read-only web research.",
		],
		parameters: CodexComputerUseParams,

		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const model = ctx.model?.id;
			if (!model) throw new Error("No Pi model is selected, so Codex cannot inherit one.");

			const tempDir = await mkdtemp(join(tmpdir(), "pi-codex-computer-use-"));
			const outputPath = join(tempDir, "final.md");

			const result = await pi.exec(
				"codex",
				[
					"--ask-for-approval",
					"never",
					"exec",
					"--ephemeral",
					"--color",
					"never",
					"--sandbox",
					"read-only",
					"--model",
					model,
					"--cd",
					ctx.cwd,
					"--output-last-message",
					outputPath,
					buildPrompt(params.task),
				],
				{ signal },
			);

			let output = "";
			try {
				output = await readFile(outputPath, "utf8");
			} catch {
				output = result.stderr || result.stdout || "Codex produced no final report.";
			}

			const truncation = truncateHead(output, {
				maxLines: DEFAULT_MAX_LINES,
				maxBytes: DEFAULT_MAX_BYTES,
			});
			let text = `Codex Computer Use (${ctx.model.provider}/${model}) exited with code ${result.code}.\n\n${truncation.content}`;
			if (truncation.truncated) {
				text += `\n\n[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines (${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}). Full output: ${outputPath}]`;
			}

			if (result.code !== 0) throw new Error(text);
			return {
				content: [{ type: "text", text }],
				details: {
					model,
					provider: ctx.model.provider,
					cwd: ctx.cwd,
					exitCode: result.code,
					fullOutputPath: truncation.truncated ? outputPath : undefined,
				},
			};
		},
	});
}
