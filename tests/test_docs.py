import json
import os
from pathlib import Path
import re
import struct
import subprocess
import tempfile
import textwrap
import time
import tomllib
import unittest
import zlib

from helpers import require_tool

ROOT = Path(__file__).resolve().parents[1]
FENCE = re.compile(r'^(?P<indent> *)```(?P<lang>[\w-]*)[^\n]*\n(?P<body>.*?)^(?P=indent)```[ \t]*$',
                   re.MULTILINE | re.DOTALL)


def code_blocks(*languages):
    for doc in sorted(ROOT.rglob('*.md')):
        if '.git' in doc.parts:
            continue
        for match in FENCE.finditer(doc.read_text()):
            if match['lang'] in languages:
                yield doc.relative_to(ROOT), textwrap.dedent(match['body'])


def png_size_and_first_pixel(path):
    data = path.read_bytes()
    # IHDR is always the first chunk, right after the 8-byte signature.
    width, height, depth, color = struct.unpack('>IIBB', data[16:26])
    position, compressed = 8, b''
    while position < len(data):
        length, kind = struct.unpack('>I4s', data[position:position + 8])
        if kind == b'IDAT':
            compressed += data[position + 8:position + 8 + length]
        position += length + 12
    channels = {2: 3, 6: 4}[color]
    assert depth == 8, f'{path.name}: unsupported bit depth {depth}'
    # Byte 0 is the row filter. Every filter leaves the first pixel of the first
    # row unchanged, because it has no left or upper neighbour.
    first_row = zlib.decompressobj().decompress(compressed, 1 + channels)
    return width, height, first_row[1:1 + channels]


class DocumentationSnippetTests(unittest.TestCase):
    def test_json_snippets_parse(self):
        for doc, body in code_blocks('json', 'jsonc'):
            with self.subTest(doc=str(doc), start=body[:40]):
                try:
                    json.loads(body)
                except json.JSONDecodeError:
                    # Fragments such as `"key": value` must parse as object members.
                    json.loads('{' + body + '}')

    def test_toml_snippets_parse(self):
        for doc, body in code_blocks('toml'):
            with self.subTest(doc=str(doc)):
                tomllib.loads(body)

    def test_bash_snippets_have_valid_syntax(self):
        for doc, body in code_blocks('bash'):
            with self.subTest(doc=str(doc), start=body[:40]):
                result = subprocess.run(['bash', '-n'], input=body, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_zsh_snippets_have_valid_syntax(self):
        zsh = require_tool('zsh')
        blocks = list(code_blocks('zsh'))
        self.assertTrue(blocks)
        for doc, body in blocks:
            with self.subTest(doc=str(doc)):
                result = subprocess.run([zsh, '-f', '-n'], input=body, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_codex_notify_command(self):
        require_tool('jq')
        snippet = next(body for doc, body in code_blocks('toml') if doc.name == 'codex-notify.md')
        command = tomllib.loads(snippet)['notify']
        reply = 'Đã xong ’ ' + 'é' * 200
        cases = [
            (json.dumps({'type': 'agent-turn-complete', 'last-assistant-message': reply}), reply[:120]),
            (json.dumps({'type': 'agent-turn-complete'}), 'Done!'),
            ('not json', 'Done!'),
        ]
        with tempfile.TemporaryDirectory() as home:
            capture = Path(home) / 'args'
            notify = Path(home) / 'bin/claude-notify'
            notify.parent.mkdir()
            notify.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$HOME/args.tmp"\n'
                              'mv "$HOME/args.tmp" "$HOME/args"\n')
            notify.chmod(0o755)
            for payload, expected in cases:
                with self.subTest(expected=expected[:20]):
                    capture.unlink(missing_ok=True)
                    subprocess.run(command + [payload], env=dict(os.environ, HOME=home),
                                   check=True, timeout=10)
                    deadline = time.monotonic() + 10
                    while not capture.exists() and time.monotonic() < deadline:
                        time.sleep(0.02)
                    self.assertEqual(capture.read_text().splitlines(), ['Codex', expected])


class PreviewImageTests(unittest.TestCase):
    def test_previews_use_the_normalized_canvas(self):
        previews = sorted((ROOT / 'assets').glob('preview-*.png'))
        self.assertTrue(previews)
        for path in previews:
            with self.subTest(image=path.name):
                width, height, pixel = png_size_and_first_pixel(path)
                self.assertEqual((width, height), (1220, 788))
                self.assertEqual(pixel[:3].hex(), '0d1117')

    def test_readme_renders_previews_at_720(self):
        tags = re.findall(r'<img\b[^>]*\bsrc="assets/preview-[^"]*"[^>]*>',
                          (ROOT / 'README.md').read_text())
        self.assertTrue(tags)
        for tag in tags:
            self.assertIn('width="720"', tag)
