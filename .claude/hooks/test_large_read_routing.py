#!/usr/bin/env python3
import importlib.util
import io
import json
import os
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

HERE = os.path.dirname(__file__)
SPEC = importlib.util.spec_from_file_location("routing", os.path.join(HERE, "large-read-routing.py"))
routing = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(routing)


class RoutingTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="routing cwd ")
        self.cwd = self.tmp.name
        for name, text in {"large.txt": "x\n" * 351, "final.txt": "x\n" * 350 + "x"}.items():
            with open(os.path.join(self.cwd, name), "w", encoding="utf-8") as file:
                file.write(text)
        with open(os.path.join(self.cwd, "+10"), "w", encoding="utf-8") as file:
            file.write("x\n" * 351)

    def tearDown(self):
        self.tmp.cleanup()

    def call(self, payload, env=None):
        output = io.StringIO()
        with patch.dict(os.environ, env or {}, clear=False), patch("sys.stdin", io.StringIO(json.dumps(payload))), redirect_stdout(output):
            routing.main()
        return json.loads(output.getvalue()) if output.getvalue() else None

    def payload(self, tool, **data):
        return {"tool_name": tool, "cwd": self.cwd, "tool_input": data}

    def test_read_thresholds_and_no_contents(self):
        denied = self.call(self.payload("Read", file_path="large.txt"))
        self.assertEqual(denied["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertNotIn("x\n", json.dumps(denied))
        self.assertIsNotNone(self.call(self.payload("Read", file_path="final.txt")))
        self.assertIsNone(self.call(self.payload("Read", file_path="large.txt", limit=350)))
        self.assertIsNotNone(self.call(self.payload("Read", file_path="large.txt", offset=1)))
        self.assertIsNone(self.call(self.payload("Read", file_path="large.txt"), {"CLAUDE_BULK_READ_MIN_LINES": "500"}))

    def test_bypass_malformed_binary_and_special(self):
        bypass = self.payload("Read", file_path="large.txt")
        bypass["agent_id"] = "agent"
        self.assertIsNone(self.call(bypass))
        bypass["agent_type"] = "Explore"
        self.assertIsNone(self.call(bypass))
        bypass = self.payload("Read", file_path="large.txt")
        bypass["agent_id"] = None
        self.assertIsNone(self.call(bypass))
        self.assertIsNone(self.call(["malformed"]))
        self.assertIsNone(self.call({"tool_name": "Read", "tool_input": {"file_path": 3}}))
        with open(os.path.join(self.cwd, "binary"), "wb") as file:
            file.write(b"\0" + b"x\n" * 400)
        self.assertIsNone(self.call(self.payload("Read", file_path="binary")))
        self.assertIsNone(self.call(self.payload("Read", file_path=".")))

    def test_scan_cap_fails_open(self):
        with open(os.path.join(self.cwd, "one-line.txt"), "w", encoding="utf-8") as file:
            file.write("x" * 9000)
        with patch.object(routing, "MAX_SCAN_BYTES", 1):
            self.assertIsNone(self.call(self.payload("Read", file_path="one-line.txt")))

    def test_simple_bash(self):
        self.assertIsNotNone(self.call(self.payload("Bash", command="/bin/cat large.txt")))
        self.assertIsNotNone(self.call(self.payload("Bash", command="cat large.txt final.txt")))
        self.assertIsNone(self.call(self.payload("Bash", command="head -n 10 large.txt")))
        self.assertIsNotNone(self.call(self.payload("Bash", command="head large.txt"), {"CLAUDE_BULK_READ_MIN_LINES": "5"}))
        self.assertIsNotNone(self.call(self.payload("Bash", command="tail --lines=351 large.txt")))
        self.assertIsNotNone(self.call(self.payload("Bash", command="tail +10 large.txt")))
        self.assertIsNotNone(self.call(self.payload("Bash", command="tail -n +10 large.txt")))
        self.assertIsNotNone(self.call(self.payload("Bash", command="tail --lines=+10 large.txt")))
        self.assertIsNotNone(self.call(self.payload("Bash", command="tail -- +10"), {"CLAUDE_BULK_READ_MIN_LINES": "5"}))
        self.assertIsNone(self.call(self.payload("Bash", command="cat large.txt | wc -l")))


if __name__ == "__main__":
    unittest.main()
