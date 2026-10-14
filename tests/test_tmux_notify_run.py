import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

from helpers import require_tool

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'bin/tmux-notify-run'


class TmuxNotifyRunTests(unittest.TestCase):
    def setUp(self):
        require_tool('tmux')
        require_tool('setsid')
        # A short base keeps the tmux socket path under the UNIX socket limit.
        directory = tempfile.TemporaryDirectory(
            prefix='tnr-', dir='/tmp' if os.path.isdir('/tmp') else None,
            ignore_cleanup_errors=True)
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.capture = self.root / 'notify-args'
        notify = self.root / 'notify'
        notify.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$NOTIFY_CAPTURE.tmp"\n'
                          'mv "$NOTIFY_CAPTURE.tmp" "$NOTIFY_CAPTURE"\n')
        notify.chmod(0o755)
        self.env = {key: value for key, value in os.environ.items()
                    if not key.startswith('TMUX')}
        self.env.update(HOME=str(self.root), XDG_CONFIG_HOME=str(self.root / 'config'),
                        XDG_STATE_HOME=str(self.root / 'state'), TMUX_TMPDIR=str(self.root),
                        TMUX_NOTIFY_COMMAND=str(notify), NOTIFY_CAPTURE=str(self.capture))
        self.addCleanup(subprocess.run, ['tmux', 'kill-server'], env=self.env,
                        capture_output=True, timeout=10)

    def helper(self, *args, returncode=0):
        result = subprocess.run(['bash', str(SCRIPT), *args], env=self.env,
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, returncode, result.stderr)
        return result

    def job(self, session, name):
        return self.root / 'state/tmux-notify-run' / session / name

    def wait_for(self, read):
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            value = read()
            if value:
                return value
            time.sleep(0.05)
        self.fail('timed out waiting for the job')

    def finished_status(self, session):
        status = self.job(session, 'status')

        def read():
            text = status.read_text().strip() if status.exists() else ''
            return text if text not in ('', 'running') else None
        return self.wait_for(read)

    def notification(self):
        return self.wait_for(lambda: self.capture.exists() and self.capture.read_text()).splitlines()

    def test_failed_job_keeps_arguments_cwd_and_environment(self):
        work = self.root / 'work dir'
        work.mkdir()
        self.env['TNR_VALUE'] = 'two  spaces \'single\' "double"'
        program = ('import os, sys; print(sys.argv[1:]); print(os.getcwd()); '
                   'print(os.environ["TNR_VALUE"]); print("TMUX" in os.environ); sys.exit(3)')
        self.helper('job-fail', '--title', 'Build ’done’', '--cwd', str(work), '--',
                    'python3', '-c', program, 'a b', '$HOME', "it's")
        self.assertEqual(self.finished_status('job-fail'), '3')
        self.assertEqual(self.job('job-fail', 'job.log').read_text().splitlines(),
                         [str(['a b', '$HOME', "it's"]), str(work), self.env['TNR_VALUE'], 'False'])
        self.assertIn('exit_code=3', self.job('job-fail', 'meta').read_text())
        self.assertEqual(self.notification(), ['Build ’done’', 'Failed with exit code 3', '--force'])

    def test_log_is_complete_when_status_is_written(self):
        self.helper('job-ok', '--', 'python3', '-c', 'for i in range(20000): print(i)')
        self.assertEqual(self.finished_status('job-ok'), '0')
        log = self.job('job-ok', 'job.log').read_text().splitlines()
        self.assertEqual((len(log), log[-1]), (20000, '19999'))
        self.assertEqual(self.notification(), ['tmux: job-ok', 'Completed successfully', '--force'])

    def test_status_hides_finished_jobs_unless_named(self):
        self.helper('job-done', '--', 'true')
        self.assertEqual(self.finished_status('job-done'), '0')
        self.assertIn('0 unfinished, 1 finished job(s) not shown', self.helper('--status').stdout)
        self.assertTrue(self.helper('--status', 'job-done').stdout.startswith('exit=0 '))

    def test_status_marks_dead_jobs_orphaned(self):
        dead = subprocess.Popen(['true'])
        dead.wait()
        self.job('ghost', '').mkdir(parents=True)
        self.job('ghost', 'status').write_text('running\n')
        self.job('ghost', 'meta').write_text(f'session=ghost\npid={dead.pid}\n')
        self.assertRegex(self.helper('--status').stdout, r'(?m)^orphaned .* ghost$')
        self.assertEqual(self.job('ghost', 'status').read_text(), 'orphaned\n')

    def test_refuses_a_running_session(self):
        self.helper('job-busy', '--', 'sleep', '30')
        result = self.helper('job-busy', '--', 'true', returncode=2)
        self.assertIn('tmux session already exists', result.stderr)

    def test_rejects_invalid_invocations(self):
        cases = [
            (['bad name', '--', 'true'], 'SESSION may contain only'),
            (['job'], 'missing COMMAND'),
            (['job', '--title'], '--title requires a value'),
            (['job', '--bogus', '--', 'true'], 'unknown option'),
            (['job', '--cwd', str(self.root / 'missing'), '--', 'true'], 'working directory does not exist'),
        ]
        for args, message in cases:
            with self.subTest(args=args):
                self.assertIn(message, self.helper(*args, returncode=2).stderr)
