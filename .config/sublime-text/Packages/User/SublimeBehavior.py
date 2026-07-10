import sublime
import sublime_plugin


class CloseOtherSublimeWindowsCommand(sublime_plugin.WindowCommand):
    """Close every Sublime Text window except the one handling this command."""

    def run(self):
        for window in sublime.windows():
            if window.id() != self.window.id():
                window.run_command("close_window")
