#!/usr/bin/env python3
"""Validate JSON/JSONC files, stripping comments and handling empty files."""
import json
import sys
from pathlib import Path


def _skip_line_comment(text, i):
    """Advance past a // comment to end of line. Returns new index."""
    n = len(text)
    while i < n and text[i] != '\n':
        i += 1
    return i


def _skip_block_comment(text, i):
    """Advance past a /* */ comment. Returns new index."""
    n = len(text)
    i += 2  # skip /*
    while i + 1 < n and not (text[i] == '*' and text[i + 1] == '/'):
        i += 1
    return i + 2  # skip */


def strip_jsonc_comments(text):
    """Strip // and /* */ comments from JSONC text, respecting string boundaries."""
    result = []
    i = 0
    n = len(text)
    in_string = False
    escape_next = False

    while i < n:
        ch = text[i]

        if escape_next:
            result.append(ch)
            escape_next = False
            i += 1
            continue

        if in_string:
            if ch == '\\':
                escape_next = True
            result.append(ch)
            if ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            result.append(ch)
            i += 1
            continue

        if ch == '/' and i + 1 < n and text[i + 1] == '/':
            i = _skip_line_comment(text, i)
            continue

        if ch == '/' and i + 1 < n and text[i + 1] == '*':
            i = _skip_block_comment(text, i)
            continue

        result.append(ch)
        i += 1

    return ''.join(result)


errors = []
for f in Path("Configs").rglob("*"):
    if f.suffix not in (".json", ".jsonc"):
        continue
    if "node_modules" in str(f):
        continue
    if not f.is_file():
        continue
    print(f"Checking {f}...")
    content = f.read_text()
    if not content.strip():
        print(f"  SKIP (empty): {f}")
        continue
    cleaned = strip_jsonc_comments(content)
    try:
        json.loads(cleaned)
    except json.JSONDecodeError as e:
        errors.append(f"  {f}: {e}")

if errors:
    print("JSON validation errors:")
    for e in errors:
        print(e)
    sys.exit(1)
print("JSON validation: OK")
