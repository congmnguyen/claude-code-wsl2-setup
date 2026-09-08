#!/usr/bin/env python3
"""Check inline local Markdown links, heading anchors, and HTML image paths.

Fenced examples and external URLs are deliberately excluded. No network access.
"""
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]


def prose(text):
    return re.sub(r"^(`{3,}|~{3,})[^\n]*\n.*?^\1\s*$", "", text,
                  flags=re.MULTILINE | re.DOTALL)


def anchors(text):
    found = set()
    counts = {}
    for title in re.findall(r"^#{1,6}\s+(.+?)\s*#*\s*$", prose(text), re.MULTILINE):
        slug = re.sub(r"[^\w\- ]", "", title.lower()).replace(" ", "-")
        count = counts.get(slug, 0)
        counts[slug] = count + 1
        found.add(f"{slug}-{count}" if count else slug)
    return found


def check():
    errors = []
    files = [p for p in ROOT.rglob('*.md') if '.git' not in p.parts]
    for file in files:
        text = prose(file.read_text())
        links = re.findall(r"\[[^\]\n]*\]\((<[^>]+>|[^)\s]+)(?:\s+\"[^\"]*\")?\)", text)
        links += re.findall(r'<(?:img|a)\b[^>]*\b(?:src|href)="([^"]+)"', text)
        for link in links:
            link = link.strip('<>')
            parsed = urlsplit(link)
            if parsed.scheme or parsed.netloc:
                continue
            target = (file.parent / unquote(parsed.path)).resolve() if parsed.path else file
            if not target.exists():
                errors.append(f'{file.relative_to(ROOT)}: missing {link}')
            elif parsed.fragment and target.suffix == '.md':
                if unquote(parsed.fragment) not in anchors(target.read_text()):
                    errors.append(f'{file.relative_to(ROOT)}: missing heading {link}')
    if errors:
        print('\n'.join(errors), file=sys.stderr)
        return 1
    print(f'Local links and heading anchors OK ({len(files)} Markdown files).')
    return 0


if __name__ == '__main__':
    sys.exit(check())
