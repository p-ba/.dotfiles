#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
BUNDLE_ID="com.sublimetext.4"

usage() {
  cat <<'USAGE'
Usage: macos-default-editor.sh [--dry-run]

Make Sublime Text the default Finder app for source code and plain-text files.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

if [[ "$(uname -s)" != Darwin ]]; then
  echo "skip default editor: unsupported platform $(uname -s)"
  exit 0
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "skip default editor: swift not found (install Xcode Command Line Tools)"
  exit 0
fi

# Parent types such as public.source-code do not cascade to more specific types
# that other apps claim (Xcode claims public.swift-source), so common extensions
# are listed individually. HTML, SVG, RTF, and CSV are left to their viewers.
TYPES=(
  public.plain-text public.utf8-plain-text public.source-code public.script public.shell-script
  public.json public.yaml public.xml public.log net.daringfireball.markdown
)
# .ts resolves to MPEG-2 transport stream video, which then also opens in Sublime.
EXTENSIONS=(
  txt text log md markdown json jsonc yaml yml toml ini cfg conf env properties xml
  c h cc cpp cxx hpp hh m mm swift py pyi rb pl php js mjs cjs jsx ts tsx go rs java kt kts scala
  lua el lisp clj sh bash zsh fish sql css scss sass less vue svelte gradle cmake mk diff patch
)

args=("$DRY_RUN" "$BUNDLE_ID")
for type in "${TYPES[@]}"; do args+=("uti:$type"); done
for ext in "${EXTENSIONS[@]}"; do args+=("ext:$ext"); done

swift - "${args[@]}" <<'SWIFT'
import AppKit
import UniformTypeIdentifiers

let args = Array(CommandLine.arguments.dropFirst())
let dryRun = args[0] == "1"
let bundleID = args[1]
let workspace = NSWorkspace.shared

guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleID) else {
  print("skip default editor: \(bundleID) is not installed")
  exit(0)
}

var seen = Set<String>()
var failed = false
for spec in args.dropFirst(2) {
  let value = String(spec.dropFirst(4))
  let type = spec.hasPrefix("ext:") ? UTType(filenameExtension: value) : UTType(value)
  guard let type else {
    print("skip unknown type: \(spec)")
    continue
  }
  guard seen.insert(type.identifier).inserted else { continue }

  let label = spec.hasPrefix("ext:") ? ".\(value) (\(type.identifier))" : type.identifier
  let current = workspace.urlForApplication(toOpen: type)
  if current?.standardizedFileURL == appURL.standardizedFileURL {
    print("ok: \(label)")
    continue
  }

  let from = current?.deletingPathExtension().lastPathComponent ?? "none"
  if dryRun {
    print("[dry-run] default: \(label) \(from) -> \(appURL.lastPathComponent)")
    continue
  }
  // The completion handler may run on the main queue, so spin the run loop
  // instead of blocking on a semaphore.
  var done = false
  var setError: Error?
  workspace.setDefaultApplication(at: appURL, toOpen: type) { error in
    setError = error
    done = true
  }
  while !done { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05)) }
  if let setError {
    print("failed: \(label): \(setError.localizedDescription)")
    failed = true
  } else {
    print("default: \(label) \(from) -> \(appURL.lastPathComponent)")
  }
}
exit(failed ? 1 : 0)
SWIFT
