import itertools
import json
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'bin/statusline-command.sh'
ANSI = re.compile(r'\x1b\[[0-9;]*m')


class StatuslineTests(unittest.TestCase):
    def render(self, payload, cwd=None):
        result = subprocess.run(['bash', str(SCRIPT)], input=json.dumps(payload),
                                text=True, capture_output=True, cwd=cwd)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, '')
        return ANSI.sub('', result.stdout).rstrip('\n')

    def test_missing_fields_never_shift_labels(self):
        for context, five, week in itertools.product([None, 0, 34], repeat=3):
            with self.subTest(context=context, five=five, week=week):
                payload = {
                    'workspace': {'current_dir': '/tmp'},
                    'context_window': {'used_percentage': context},
                    'rate_limits': {'five_hour': {'used_percentage': five},
                                    'seven_day': {'used_percentage': week}},
                }
                output = self.render(payload)
                self.assertEqual('] ' in output, context is not None)
                if context is not None:
                    self.assertIn(f'] {context}%', output)
                for label, value in [('5h:', five), ('W:', week)]:
                    self.assertEqual(label in output, value is not None)
                    if value is not None:
                        self.assertIn(f'{label}{value}%', output)

    def test_absent_objects_and_cwd_fallback(self):
        with tempfile.TemporaryDirectory() as directory:
            output = self.render({}, cwd=directory)
            self.assertEqual(output, f'📁 {Path(directory).name}')
            self.assertEqual(self.render({'cwd': directory}), output)

    def test_literal_path_characters(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'project with space\\new\ttab'
            path.mkdir()
            self.assertEqual(self.render({'workspace': {'current_dir': str(path)}}),
                             f'📁 {path.name}')

    def test_rounding_and_context_cap(self):
        output = self.render({'cwd': '/tmp', 'context_window': {'used_percentage': 150},
                              'rate_limits': {'five_hour': {'used_percentage': 34.6}}})
        self.assertIn('[██████████] 100%', output)
        self.assertIn('5h:35%', output)

    def test_invalid_percentages_are_omitted(self):
        for invalid in ['.', '1.2.3', -1, 'oops', [], {}]:
            with self.subTest(invalid=invalid):
                output = self.render({'cwd': '/tmp',
                                      'context_window': {'used_percentage': invalid},
                                      'rate_limits': {'seven_day': {'used_percentage': 56}}})
                self.assertNotIn('] ', output)
                self.assertIn('W:56%', output)

    def test_invalid_json_fails_without_display(self):
        for raw in ['{broken', 'null', '[]', '']:
            result = subprocess.run(['bash', str(SCRIPT)], input=raw,
                                    text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(result.stdout, '')

    def test_git_branch_and_detached_head(self):
        with tempfile.TemporaryDirectory() as directory:
            def git(*args):
                return subprocess.check_output(['git', '-C', directory, *args],
                                               text=True, stderr=subprocess.DEVNULL).strip()
            git('init', '-b', 'test-branch')
            git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                '-c', 'commit.gpgsign=false', 'commit', '--allow-empty', '-m', 'fixture')
            self.assertIn('🌿 test-branch', self.render({'cwd': directory}))
            git('checkout', '--detach', 'HEAD')
            self.assertIn(f'🌿 {git("rev-parse", "--short", "HEAD")}',
                          self.render({'cwd': directory}))
