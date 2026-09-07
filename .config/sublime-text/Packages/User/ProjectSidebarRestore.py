"""Open detected source project folders from the Command Palette."""

import os

import sublime
import sublime_plugin


_VCS_MARKERS = frozenset((".git", ".hg", ".svn"))
_FALLBACK_MARKERS = frozenset((
    "Makefile", "package.json", "pyproject.toml", "setup.py", "Cargo.toml",
    "go.mod", "composer.json", "Gemfile", "mix.exs", "pom.xml",
    "build.gradle", "build.gradle.kts",
))


def _normal_path(path):
    return os.path.realpath(path)


def _same_path(first, second):
    try:
        return os.path.samefile(first, second)
    except OSError:
        return _normal_path(first) == _normal_path(second)


def _is_within(path, folder):
    """Return whether *path* is inside *folder*, without prefix matching."""
    candidate = _normal_path(path)
    while True:
        if _same_path(candidate, folder):
            return True
        parent = os.path.dirname(candidate)
        if parent == candidate:
            break
        candidate = parent
    try:
        return os.path.commonpath((_normal_path(path), _normal_path(folder))) == _normal_path(folder)
    except ValueError:
        return False


def _find_root(start):
    """Prefer the nearest VCS root; otherwise return the nearest fallback root."""
    if not start:
        return None

    fallback_root = None
    candidate = _normal_path(start)
    while True:
        if any(os.path.exists(os.path.join(candidate, marker)) for marker in _VCS_MARKERS):
            return candidate
        if fallback_root is None and any(
                os.path.exists(os.path.join(candidate, marker)) for marker in _FALLBACK_MARKERS):
            fallback_root = candidate
        parent = os.path.dirname(candidate)
        if parent == candidate:
            return fallback_root
        candidate = parent


def _reduce_roots(roots):
    """Keep outermost roots so nested sidebar entries do not accumulate."""
    result = []
    for root in roots:
        if any(_same_path(root, known) for known in result):
            continue
        if any(not _same_path(root, other) and _is_within(root, other) for other in roots):
            continue
        result.append(root)
    return result


def _discover_roots(folders, file_name):
    """Do filesystem marker discovery only; this is safe from async callbacks."""
    roots = []
    if file_name:
        root = _find_root(os.path.dirname(file_name))
        if root:
            roots.append(root)
    for folder in folders:
        root = _find_root(folder)
        if root:
            roots.append(root)
    return _reduce_roots(roots)


def _merge_folder_entries(root, entries):
    """Merge promoted entries: first scalars win and list values are unioned."""
    merged = {"path": root}
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        for key, value in entry.items():
            if key == "path":
                continue
            if key not in merged:
                merged[key] = list(value) if isinstance(value, list) else value
            elif isinstance(merged[key], list) and isinstance(value, list):
                for item in value:
                    if not any(item == existing for existing in merged[key]):
                        merged[key].append(item)
    return merged


def _add_roots_to_unnamed_window(window, roots):
    """Promote transient folders without writing named project files."""
    if window.project_file_name():
        return

    project_data = window.project_data() or {}
    folders = project_data.get("folders", [])
    matches = {}
    root_by_key = {_normal_path(root): root for root in roots}
    for index, entry in enumerate(folders):
        path = entry.get("path") if isinstance(entry, dict) else entry if isinstance(entry, str) else None
        root = next((candidate for candidate in roots if path and _is_within(path, candidate)), None)
        if root:
            matches.setdefault(_normal_path(root), []).append((index, entry))

    merged = {
        key: _merge_folder_entries(root_by_key[key], [entry for _, entry in entries])
        for key, entries in matches.items()
    }
    new_folders = []
    emitted = set()
    for index, entry in enumerate(folders):
        key = next((match_key for match_key, entries in matches.items()
                    if any(match_index == index for match_index, _ in entries)), None)
        if key is None:
            new_folders.append(entry)
        elif key not in emitted:
            new_folders.append(merged[key])
            emitted.add(key)
    for root in roots:
        key = _normal_path(root)
        if key not in emitted:
            new_folders.append({"path": root})

    if new_folders != folders:
        project_data["folders"] = new_folders
        window.set_project_data(project_data)


def _begin_restore(window):
    """Capture window state on the main thread before async filesystem work."""
    if not window or not window.is_valid():
        return
    project_file = window.project_file_name()
    view = window.active_view()
    captured_view_id = view.id() if view else None
    file_name = view.file_name() if view else None
    folders = window.folders()
    folder_state = tuple(sorted(_normal_path(folder) for folder in folders))

    def discover():
        roots = _discover_roots(folders, file_name)
        if roots:
            sublime.set_timeout(
                lambda: _commit_restore(
                    window, project_file, roots, captured_view_id,
                    folder_state), 0)

    sublime.set_timeout_async(discover, 0)


def _commit_restore(window, project_file, roots, view_id, folder_state):
    """Apply state and UI changes only after main-thread identity checks."""
    if (not window.is_valid() or
            window.project_file_name() != project_file):
        return
    view = window.active_view()
    current_view_id = view.id() if view else None
    current_folder_state = tuple(
        sorted(_normal_path(folder) for folder in window.folders()))
    if current_view_id != view_id or current_folder_state != folder_state:
        return

    # This check is intentionally repeated at commit time: named project files
    # must never be rewritten, including if a project was named during discovery.
    _add_roots_to_unnamed_window(window, roots)
    window.set_sidebar_visible(True)
    file_name = view.file_name() if view else None
    if file_name and any(_is_within(file_name, root) for root in roots):
        window.run_command("reveal_in_side_bar")


class OpenDetectedProjectCommand(sublime_plugin.WindowCommand):
    """Show detected project roots and reveal the active file in the sidebar."""

    def run(self):
        _begin_restore(self.window)
