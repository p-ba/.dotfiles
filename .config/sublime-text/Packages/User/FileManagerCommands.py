import os

import sublime
import sublime_plugin


class FmCreateRelativeToCurrentFileCommand(sublime_plugin.WindowCommand):
    def run(self):
        view = self.window.active_view()
        file_name = view.file_name() if view is not None else None

        if file_name:
            self.window.run_command("fm_create", {"paths": [os.path.dirname(file_name)]})
            return

        self.window.run_command("fm_create")

    def is_enabled(self):
        return self.window.active_view() is not None
