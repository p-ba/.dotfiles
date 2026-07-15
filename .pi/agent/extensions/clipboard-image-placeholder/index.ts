import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionUIContext,
	type ExtensionContext,
	type SessionStartEvent,
} from "@earendil-works/pi-coding-agent";

const ZERO_WIDTH_SPACE = "\u200b";
const LOCAL_IMAGE_PATH = /(?<![\w/:])@?(?:(?:~|\.\.?)\/|\/|(?:[\w.-]+\/)+)(?:[^\s/()[\]{}"'`]+\/)*[^\s/()[\]{}"'`]+\.(?:png|jpe?g|webp|gif)(?=$|[\s),.;:!?])/gi;

type EditorState = {
	lines: string[];
};
type EditorFactory = NonNullable<Parameters<ExtensionUIContext["setEditorComponent"]>[0]>;

/**
 * Keeps local image paths intact for submission while showing a compact label
 * in the prompt editor. Zero-width padding preserves the editor's cursor
 * offsets without taking terminal space.
 */
class ClipboardImagePlaceholderEditor extends CustomEditor {
	render(width: number): string[] {
		const editor = this as unknown as { state: EditorState };
		const originalLines = editor.state.lines;
		let imageNumber = 0;

		editor.state.lines = originalLines.map((line: string) =>
			line.replace(LOCAL_IMAGE_PATH, (imagePath: string, offset: number, source: string) => {
				if (/https?:\/\/[^\s]*$/i.test(source.slice(0, offset))) return imagePath;

				imageNumber += 1;
				const filename = imagePath.replace(/^@/, "").split("/").pop() ?? "image";
				const label = `[Image #${imageNumber}: ${filename}]`;
				const placeholder = label.length <= imagePath.length ? label : filename;
				return placeholder + ZERO_WIDTH_SPACE.repeat(imagePath.length - placeholder.length);
			}),
		);

		try {
			return super.render(width);
		} finally {
			editor.state.lines = originalLines;
		}
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event: SessionStartEvent, ctx: ExtensionContext) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setEditorComponent((
			tui: Parameters<EditorFactory>[0],
			theme: Parameters<EditorFactory>[1],
			keybindings: Parameters<EditorFactory>[2],
		) => new ClipboardImagePlaceholderEditor(tui, theme, keybindings));
	});
}
