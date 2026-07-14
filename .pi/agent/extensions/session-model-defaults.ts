import { SettingsManager, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

type PatchState = {
	originalSetDefaultModelAndProvider: SettingsManager["setDefaultModelAndProvider"];
	patchedSetDefaultModelAndProvider: SettingsManager["setDefaultModelAndProvider"];
};

// Symbol.for keeps one shared patch state across extension module reloads.
const patchMarker = Symbol.for("pi.session-model-defaults.patch");

function getPatchState(): PatchState | undefined {
	return Object.getOwnPropertyDescriptor(SettingsManager.prototype, patchMarker)?.value as PatchState | undefined;
}

function installPatch(): PatchState {
	const prototype = SettingsManager.prototype;
	const existing = getPatchState();
	if (existing) {
		return existing;
	}

	const originalSetDefaultModelAndProvider = prototype.setDefaultModelAndProvider;
	const patchedSetDefaultModelAndProvider: SettingsManager["setDefaultModelAndProvider"] = function (
		this: SettingsManager,
		_provider: string,
		_modelId: string,
	): void {
		// Model selection is session-local; do not persist it as the next startup default.
	};
	const state: PatchState = {
		originalSetDefaultModelAndProvider,
		patchedSetDefaultModelAndProvider,
	};

	Object.defineProperty(prototype, patchMarker, {
		configurable: true,
		enumerable: false,
		value: state,
		writable: false,
	});
	prototype.setDefaultModelAndProvider = state.patchedSetDefaultModelAndProvider;
	return state;
}

function restorePatch(state: PatchState): void {
	const prototype = SettingsManager.prototype;
	if (getPatchState() !== state) {
		return;
	}

	prototype.setDefaultModelAndProvider = state.originalSetDefaultModelAndProvider;
	Reflect.deleteProperty(prototype, patchMarker);
}

export default function sessionModelDefaults(pi: ExtensionAPI): void {
	const patchState = installPatch();
	pi.on("session_shutdown", () => {
		restorePatch(patchState);
	});
}
