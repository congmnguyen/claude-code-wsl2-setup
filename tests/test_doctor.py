import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'scripts/doctor.sh'


def snapshot(root):
    return {path.relative_to(root): (path.stat().st_mode, path.read_bytes())
            for path in sorted(root.rglob('*')) if path.is_file()}


class DoctorTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.home = Path(directory.name) / 'home'
        (self.home / 'bin').mkdir(parents=True)
        (self.home / '.claude').mkdir()
        powershell = Path(directory.name) / 'powershell.exe'
        powershell.write_text('#!/bin/sh\nexit 0\n')
        powershell.chmod(0o755)
        self.env = {'HOME': str(self.home), 'PATH': '/usr/bin:/bin', 'LANG': 'C.UTF-8',
                    'WSL_DISTRO_NAME': 'Test', 'CLAUDE_NOTIFY_POWERSHELL': str(powershell)}

    def doctor(self, returncode):
        result = subprocess.run(['bash', str(SCRIPT)], env=self.env, capture_output=True,
                                text=True, timeout=60)
        self.assertEqual(result.returncode, returncode, result.stdout + result.stderr)
        return result.stdout

    def write(self, relative, text, mode=0o644):
        path = self.home / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        path.chmod(mode)

    def test_clean_home_has_no_problems(self):
        shutil.copy(ROOT / 'bin/claude-notify', self.home / 'bin/claude-notify')
        output = self.doctor(0)
        self.assertIn('ok    claude-notify: matches bin/claude-notify', output)
        self.assertIn('No problems found.', output)

    def test_reports_known_setup_mistakes_without_writing(self):
        self.write('bin/claude-notify', '#!/bin/sh\nmessage=$(printf %s "$2" | sed "s/\'/\'\'/g")\n', 0o755)
        self.write('.claude/statusline-command.sh', '#!/bin/sh\necho old\n')
        self.write('.claude/keybindings.json', '[{"context": "Chat"}]')
        self.write('.claude/settings.json', json.dumps({
            'statusLine': {'type': 'command', 'command': 'bash ~/.claude/statusline-command.sh'},
            'hooks': {
                'Notification': [
                    {'matcher': 'idle_prompt', 'hooks': [
                        {'type': 'command', 'command': '"$HOME/bin/claude-notify" a b', 'async': True}]},
                    {'matcher': 'permission_prompt', 'hooks': [
                        {'type': 'command', 'command': '"$HOME/bin/claude-notify" a b'}]},
                ],
                'SessionStart': [{'hooks': [
                    {'type': 'command', 'command': 'wsl-screenshot-cli start --daemon'}]}],
            },
        }))
        self.write('.config/systemd/user/wsl-screenshot-cli.service', '[Service]\n')
        self.write('.bashrc', 'wsl-screenshot-cli start --daemon 2>/dev/null\n')
        self.write('.codex/config.toml', '[tui]\nnotifications = true\nnotify = ["bash"]\n')
        self.env['BROWSER'] = '/mnt/c/Users/alice/missing/brave.exe'
        before = snapshot(self.home)

        output = self.doctor(1)

        self.assertEqual(snapshot(self.home), before)
        for expected in [
            'FAIL  claude-notify: this older copy puts message text inside PowerShell string literals',
            'warn  statusline: ~/.claude/statusline-command.sh differs from bin/statusline-command.sh',
            'ok    statusLine runs statusline-command.sh',
            'ok    Notification hooks call claude-notify: idle_prompt, permission_prompt',
            'FAIL  claude-notify hooks without "async": true block Claude Code while the balloon is open: permission_prompt',
            'FAIL  Claude hooks run wsl-screenshot-cli (SessionStart) while the systemd service owns it',
            'FAIL  ~/.claude/keybindings.json must be an object with a "bindings" array',
            'FAIL  ~/.bashrc starts wsl-screenshot-cli',
            'FAIL  notify (line 3) follows the table header on line 1',
            'FAIL  BROWSER is not executable: /mnt/c/Users/<user>/missing/brave.exe',
            '7 problem(s) found.',
        ]:
            self.assertIn(expected, output)
        self.assertNotIn('alice', output)
        self.assertNotIn(str(self.home), output)

    @unittest.skipIf('microsoft' in Path('/proc/sys/kernel/osrelease').read_text().lower()
                     if Path('/proc/sys/kernel/osrelease').exists() else False,
                     'running under WSL')
    def test_outside_wsl_skips_windows_checks(self):
        del self.env['WSL_DISTRO_NAME']
        output = self.doctor(0)
        self.assertIn('warn  not running under WSL; Windows checks are skipped', output)
