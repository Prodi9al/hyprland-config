#!/usr/bin/env python3
"""Validate JSON/JSONC files, stripping comments and handling empty files."""
import json
import re
import sys
from pathlib import Path

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
    content = re.sub(r"//.*", "", content)
    content = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)
    try:
        json.loads(content)
    except json.JSONDecodeError as e:
        errors.append(f"  {f}: {e}")

if errors:
    print("JSON validation errors:")
    for e in errors:
        print(e)
    sys.exit(1)
print("JSON validation: OK")
