"""Tests for bash/.config/bash/entire-local-hooks.py.

Each test builds a throwaway git repo, commits a .claude/settings.json, simulates what
`entire enable` writes (no real `entire` needed) and runs the script from the repo root.

Run: python3 -m unittest discover -s tests -v
"""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "bash/.config/bash/entire-local-hooks.py"
DENY = "Read(./.entire/metadata/**)"
ENV = {**os.environ, "GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_NOSYSTEM": "1"}


def entire_hook(name: str) -> dict:
    return {
        "type": "command",
        "command": f"sh -c 'if ! command -v entire >/dev/null 2>&1; then exit 0; fi; exec entire hooks claude-code {name}'",
    }


def simulate_entire_enable(settings: dict) -> dict:
    """Add hooks and the deny rule the way `entire enable` does."""
    hooks = settings.setdefault("hooks", {})
    hooks.setdefault("SessionStart", []).append({"hooks": [entire_hook("session-start")]})
    hooks.setdefault("Stop", []).append({"hooks": [entire_hook("stop")]})
    hooks.setdefault("PreToolUse", []).append({"matcher": "Agent", "hooks": [entire_hook("pre-task")]})
    perms = settings.setdefault("permissions", {})
    perms.setdefault("allow", [])
    perms.setdefault("deny", []).append(DENY)
    return settings


def entire_commands(settings: dict) -> list:
    return [
        h["command"]
        for groups in settings.get("hooks", {}).values()
        for g in groups
        for h in g.get("hooks", [])
        if "entire hooks " in h.get("command", "")
    ]


class EntireLocalHooksTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self._tmp.name)
        self.git("init", "-q")
        (self.repo / ".claude").mkdir()
        self.settings = self.repo / ".claude/settings.json"
        self.local = self.repo / ".claude/settings.local.json"

    def tearDown(self):
        self._tmp.cleanup()

    def git(self, *args):
        return subprocess.run(
            ["git", "-c", "user.name=t", "-c", "user.email=t@example.com", *args],
            cwd=self.repo, env=ENV, capture_output=True, text=True, check=True,
        )

    def commit(self, text: str):
        self.settings.write_text(text)
        self.git("add", ".claude/settings.json")
        self.git("commit", "-q", "-m", "settings")

    def write(self, data: dict):
        self.settings.write_text(json.dumps(data, indent=2) + "\n")

    def run_script(self):
        return subprocess.run([sys.executable, "-I", str(SCRIPT)], cwd=self.repo, env=ENV, capture_output=True, text=True)

    def read(self, path: Path) -> dict:
        return json.loads(path.read_text())

    def assert_clean(self):
        diff = subprocess.run(["git", "diff", "--quiet", "--", ".claude/settings.json"], cwd=self.repo, env=ENV)
        self.assertEqual(diff.returncode, 0, "settings.json differs from the committed version")

    # criterion 1
    def test_keeps_uncommitted_user_change(self):
        self.commit(json.dumps({"permissions": {"allow": ["Bash(ls)"]}}, indent=2) + "\n")
        data = self.read(self.settings)
        data["permissions"]["allow"].append("Bash(npm test)")
        self.write(simulate_entire_enable(data))

        res = self.run_script()

        self.assertEqual(res.returncode, 0, res.stderr)
        after = self.read(self.settings)
        self.assertEqual(after, {"permissions": {"allow": ["Bash(ls)", "Bash(npm test)"]}})
        self.assertEqual(entire_commands(after), [])
        self.assertNotIn(DENY, after["permissions"].get("deny", []))

    def test_keeps_user_change_outside_permissions(self):
        self.commit('{\n    "model": "opus"\n}\n')
        data = self.read(self.settings)
        data["env"] = {"FOO": "1"}
        self.write(simulate_entire_enable(data))

        res = self.run_script()

        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(self.read(self.settings), {"model": "opus", "env": {"FOO": "1"}})
        self.assertTrue(self.settings.read_text().startswith('{\n    "model"'), "indentation not kept")

    # criterion 2
    def test_restores_committed_bytes_when_only_entire_changed(self):
        original = '{\n  "permissions": {\n    "allow": ["Bash(ls)"]\n  },\n  "model": "opus"\n}\n'
        self.commit(original)
        self.write(simulate_entire_enable(self.read(self.settings)))

        res = self.run_script()

        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(self.settings.read_text(), original)
        self.assert_clean()

    # criterion 3
    def test_moves_entire_parts_to_local_without_duplicates(self):
        self.commit('{\n  "model": "opus"\n}\n')
        enabled = simulate_entire_enable(self.read(self.settings))
        for _ in range(2):
            self.write(enabled)
            res = self.run_script()
            self.assertEqual(res.returncode, 0, res.stderr)

        local = self.read(self.local)
        commands = entire_commands(local)
        self.assertEqual(len(commands), 3)
        self.assertEqual(len(commands), len(set(commands)))
        self.assertEqual(local["permissions"]["deny"], [DENY])
        self.assert_clean()

    def test_keeps_existing_local_settings(self):
        self.commit('{\n  "model": "opus"\n}\n')
        self.local.write_text(json.dumps({
            "permissions": {"allow": ["Bash(make)"]},
            "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "echo mine"}]}]},
        }))
        self.write(simulate_entire_enable(self.read(self.settings)))

        res = self.run_script()

        self.assertEqual(res.returncode, 0, res.stderr)
        local = self.read(self.local)
        self.assertEqual(local["permissions"]["allow"], ["Bash(make)"])
        self.assertIn("echo mine", json.dumps(local["hooks"]["Stop"]))
        self.assertEqual(len(entire_commands(local)), 3)

    # criterion 4
    def test_keeps_non_entire_hooks_also_in_mixed_group(self):
        own = {"type": "command", "command": "echo repo-hook"}
        other = {"type": "command", "command": "echo other"}
        self.commit(json.dumps({"hooks": {
            "Stop": [{"hooks": [own]}],
            "PreToolUse": [{"matcher": "Bash", "hooks": [other]}],
        }}, indent=2) + "\n")
        data = self.read(self.settings)
        data["hooks"]["Stop"][0]["hooks"].append(entire_hook("stop"))  # mixed group
        data["hooks"]["PreToolUse"][0]["hooks"].append({"type": "command", "command": "echo user-new"})
        self.write(simulate_entire_enable(data))

        res = self.run_script()

        self.assertEqual(res.returncode, 0, res.stderr)
        after = self.read(self.settings)
        self.assertEqual(entire_commands(after), [])
        self.assertEqual(after["hooks"]["Stop"], [{"hooks": [own]}])
        self.assertEqual(after["hooks"]["PreToolUse"], [{"matcher": "Bash", "hooks": [other, {"type": "command", "command": "echo user-new"}]}])
        self.assertNotIn("SessionStart", after["hooks"])
        self.assertNotIn("permissions", after)

    def test_mixed_group_only_entire_changed_is_clean(self):
        own = {"type": "command", "command": "echo repo-hook"}
        self.commit(json.dumps({"hooks": {"Stop": [{"hooks": [own]}]}}, indent=2) + "\n")
        data = self.read(self.settings)
        data["hooks"]["Stop"][0]["hooks"].append(entire_hook("stop"))
        self.write(simulate_entire_enable(data))

        res = self.run_script()

        self.assertEqual(res.returncode, 0, res.stderr)
        self.assert_clean()

    def test_keeps_committed_entire_hooks(self):
        committed = {"hooks": {"Stop": [{"hooks": [entire_hook("stop")]}]}, "permissions": {"deny": [DENY]}}
        self.commit(json.dumps(committed, indent=2) + "\n")
        data = self.read(self.settings)
        data["model"] = "opus"
        self.write(data)

        res = self.run_script()

        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(self.read(self.settings), {**committed, "model": "opus"})
        self.assertFalse(self.local.exists())

    def test_keeps_committed_empty_event(self):
        original = '{\n  "hooks": {\n    "Stop": []\n  }\n}\n'
        self.commit(original)
        self.write(simulate_entire_enable(self.read(self.settings)))

        res = self.run_script()

        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(self.settings.read_text(), original)
        self.assert_clean()

    # security: a committed symlink at a predictable temp path must not redirect the write
    def test_does_not_follow_symlinked_temp_paths(self):
        outside = tempfile.TemporaryDirectory()
        self.addCleanup(outside.cleanup)
        victims = []
        for name in ("settings.local.json.tmp", "settings.json.tmp"):
            victim = Path(outside.name) / name
            victim.write_text("precious\n")
            (self.repo / ".claude" / name).symlink_to(victim)
            victims.append(victim)
        self.git("add", ".claude")
        self.commit(json.dumps({"model": "opus"}, indent=2) + "\n")
        data = self.read(self.settings)
        data["env"] = {"FOO": "1"}  # forces a rewrite of settings.json as well
        self.write(simulate_entire_enable(data))

        res = self.run_script()

        self.assertEqual(res.returncode, 0, res.stderr)
        for victim in victims:
            self.assertEqual(victim.read_text(), "precious\n")
        self.assertFalse(self.local.is_symlink())
        self.assertFalse(self.settings.is_symlink())
        self.assertEqual(len(entire_commands(self.read(self.local))), 3)
        self.assertEqual(self.read(self.settings), {"model": "opus", "env": {"FOO": "1"}})
        leftovers = [p.name for p in (self.repo / ".claude").iterdir() if p.name.startswith(".settings")]
        self.assertEqual(leftovers, [])

    def test_rewrite_keeps_file_mode(self):
        self.commit('{\n  "model": "opus"\n}\n')
        self.settings.chmod(0o644)
        data = self.read(self.settings)
        data["env"] = {"FOO": "1"}
        self.write(simulate_entire_enable(data))

        res = self.run_script()

        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(self.settings.stat().st_mode & 0o777, 0o644)
        self.assertEqual(self.local.stat().st_mode & 0o777, 0o644)

    # criterion 6
    def test_unparseable_settings_left_untouched(self):
        self.commit('{\n  "model": "opus"\n}\n')
        broken = '{\n  "model": "opus",\n  "hooks": {"Stop": [{"hooks": [{"command": "entire hooks x"}]}]\n'
        self.settings.write_text(broken)

        res = self.run_script()

        self.assertNotEqual(res.returncode, 0)
        self.assertIn("entire_local", res.stderr)
        self.assertEqual(self.settings.read_text(), broken)
        self.assertFalse(self.local.exists())

    def test_untracked_settings_is_noop(self):
        enabled = json.dumps(simulate_entire_enable({}), indent=2) + "\n"
        self.settings.write_text(enabled)

        res = self.run_script()

        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(self.settings.read_text(), enabled)
        self.assertFalse(self.local.exists())


if __name__ == "__main__":
    unittest.main()
