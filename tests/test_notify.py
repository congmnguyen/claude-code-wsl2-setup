import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'bin/claude-notify'


class NotifyTests(unittest.TestCase):
    def test_powershell_arguments_preserve_text_and_force(self):
        with tempfile.TemporaryDirectory() as directory:
            capture = Path(directory) / 'arguments.json'
            stub = Path(directory) / 'mock powershell.exe'
            stub.write_text('#!/usr/bin/env python3\nimport json, os, sys\n'
                            'with open(os.environ["NOTIFY_TEST_CAPTURE"], "w") as f:\n'
                            '    json.dump(sys.argv[1:], f)\n')
            stub.chmod(0o755)
            env = dict(os.environ, CLAUDE_NOTIFY_POWERSHELL=str(stub),
                       NOTIFY_TEST_CAPTURE=str(capture))
            for force in [False, True]:
                result = subprocess.run(
                    ['bash', str(SCRIPT), "It's ready", 'Hello $world; `literal`\nTiếng Việt']
                    + (['--force'] if force else []), env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                args = json.loads(capture.read_text())
                self.assertEqual(args[:2], ['-NoProfile', '-Command'])
                self.assertEqual(len(args), 3)
                self.assertIn("$notification.BalloonTipTitle = 'It''s ready'", args[2])
                self.assertIn("Hello $world; `literal`\nTiếng Việt", args[2])
                self.assertIn('if (-not $true)' if force else 'if (-not $false)', args[2])

    def test_missing_powershell_is_explicit(self):
        result = subprocess.run(['bash', str(SCRIPT)], text=True, capture_output=True,
                                env=dict(os.environ, CLAUDE_NOTIFY_POWERSHELL='/nonexistent/powershell.exe'))
        self.assertEqual(result.returncode, 1)
        self.assertIn('Windows PowerShell not found', result.stderr)

    def test_invalid_option(self):
        result = subprocess.run(['bash', str(SCRIPT), 'title', 'body', '--invalid'],
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn('unknown option', result.stderr)

    def test_documented_hooks_are_valid_and_portable(self):
        doc = (ROOT / 'claude-notify.md').read_text()
        config = json.loads(re.search(r'```json\n(.*?)\n```', doc, re.DOTALL)[1])
        notifications = config['hooks']['Notification']
        self.assertEqual(len(notifications), 4)
        for entry in notifications:
            hook = entry['hooks'][0]
            self.assertTrue(hook['command'].startswith('"$HOME/bin/claude-notify" '))
            self.assertTrue(hook['async'])
            self.assertNotIn('args', hook)
            result = subprocess.run(['bash', '-n', '-c', hook['command']], capture_output=True)
            self.assertEqual(result.returncode, 0)
