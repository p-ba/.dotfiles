"""Permanently delete sidebar/FileManager selections after confirmation."""

import os
import shutil

import sublime
import sublime_plugin


def _delete_paths(paths):
    paths = list(dict.fromkeys(path for path in paths if path))
    if not paths:
        return
    if not sublime.ok_cancel_dialog(
            "Permanently delete these files/folders?\n\n" + "\n".join(paths),
            "Delete Permanently"):
        return

    for path in paths:
        try:
            # Remove symlinks themselves, never their target directories.
            if os.path.isdir(path) and not os.path.islink(path):
                shutil.rmtree(path)
            else:
                os.remove(path)
        except FileNotFoundError:
            # A selected parent folder may already have removed this path.
            continue
        except OSError as error:
            sublime.error_message("Unable to delete {}: {}".format(path, error))


class PermanentDeletePathsCommand(sublime_plugin.WindowCommand):
    def run(self, paths):
        _delete_paths(paths)


class PermanentDeleteListener(sublime_plugin.EventListener):
    def on_window_command(self, window, command_name, args):
        key = {"delete_file": "files", "delete_folder": "dirs"}.get(command_name)
        if key:
            return "permanent_delete_paths", {"paths": (args or {}).get(key, [])}


# User plugins load after installed packages, replacing FileManager's command.
class FmDeleteCommand(sublime_plugin.ApplicationCommand):
    def run(self, paths=None, **kwargs):
        if not paths:
            window = sublime.active_window()
            view = window.active_view() if window else None
            paths = [view.file_name()] if view else []
        _delete_paths(paths)
