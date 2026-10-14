import base64
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

from helpers import require_tool

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'bin/claude-notify'
ENCODED = re.compile(r"Decode '([A-Za-z0-9+/=]*)'")
# PowerShell ends single-quoted strings at any of ' ‘ ’ ‚ ‛.
HOSTILE = ("Done’; Start-Process calc; ’ ‘a‚b‛ 'quote' \"double\" $(id) `tick`\n"
           "'@\nTiếng Việt")
PARSE = r'''
param([string]$Path)
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
$commands = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true) |
    ForEach-Object { $_.GetCommandName() } | Sort-Object -Unique
[pscustomobject]@{ errors = @($errors | ForEach-Object { $_.Message }); commands = @($commands) } |
    ConvertTo-Json -Compress
'''


class NotifyTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.directory = Path(directory.name)
        self.capture = self.directory / 'arguments.json'
        stub = self.directory / 'mock powershell.exe'
        stub.write_text('#!/usr/bin/env python3\nimport json, os, sys\n'
                        'with open(os.environ["NOTIFY_TEST_CAPTURE"], "w") as f:\n'
                        '    json.dump(sys.argv[1:], f)\n')
        stub.chmod(0o755)
        self.env = dict(os.environ, CLAUDE_NOTIFY_POWERSHELL=str(stub),
                        NOTIFY_TEST_CAPTURE=str(self.capture))

    def generate(self, *args):
        result = subprocess.run(['bash', str(SCRIPT), *args], env=self.env,
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        arguments = json.loads(self.capture.read_text())
        self.assertEqual(arguments[:2], ['-NoProfile', '-Command'])
        self.assertEqual(len(arguments), 3)
        return arguments[2]

    def decoded(self, script):
        return [base64.b64decode(text).decode() for text in ENCODED.findall(script)]

    def test_text_round_trips_through_base64(self):
        for force in [False, True]:
            with self.subTest(force=force):
                script = self.generate("It’s ready", HOSTILE, *(['--force'] if force else []))
                self.assertEqual(self.decoded(script), ["It’s ready", HOSTILE])
                self.assertIn('if (-not $true)' if force else 'if (-not $false)', script)
                self.assertNotIn('’', script)

    def test_defaults(self):
        self.assertEqual(self.decoded(self.generate()), ['Claude Code', 'Notification'])

    def test_text_cannot_change_script_structure(self):
        plain = ENCODED.sub("Decode ''", self.generate('Title', 'Message'))
        hostile = ENCODED.sub("Decode ''", self.generate(HOSTILE, HOSTILE))
        self.assertEqual(plain, hostile)

    def test_generated_powershell_parses(self):
        pwsh = require_tool('pwsh')
        script = self.directory / 'notify.ps1'
        script.write_text(self.generate(HOSTILE, HOSTILE))
        parser = self.directory / 'parse.ps1'
        parser.write_text(PARSE)
        result = subprocess.run([pwsh, '-NoProfile', '-NonInteractive', '-File', str(parser),
                                 str(script)], capture_output=True, text=True, timeout=120)
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads(result.stdout)
        self.assertEqual(report['errors'], [])
        self.assertEqual(set(report['commands']), {'Add-Type', 'Decode', 'Get-Process',
                                                   'New-Object', 'Out-Null', 'Select-Object'})

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
