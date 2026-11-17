#!/usr/bin/env python3
"""Validate dots.toml and restore_cfg.lst consistency."""
import os
import sys

try:
    import tomllib
except ImportError:
    import tomli as tomllib

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

errors = []

manifest_path = os.path.join(REPO_ROOT, "dots.toml")
restore_list_path = os.path.join(REPO_ROOT, "Scripts", "restore_cfg.lst")

with open(manifest_path, "rb") as f:
    manifest = tomllib.load(f)

# Collect all source paths from manifest
manifest_sources = set()
for section in manifest.values():
    for entry in section.values():
        src = entry["source"].replace("Configs/", "")
        manifest_sources.add(src)

# Check all manifest sources exist
for src in sorted(manifest_sources):
    full_path = os.path.join(REPO_ROOT, "Configs", src)
    if not os.path.exists(full_path):
        errors.append(f"Missing: {src}")

# Check restore_cfg.lst sources match manifest
restore_sources = set()
with open(restore_list_path) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        source_rel = line.split("->")[0].strip()
        restore_sources.add(source_rel)

for src in sorted(restore_sources - manifest_sources):
    errors.append(f"In restore_cfg.lst but not in dots.toml: {src}")

for src in sorted(manifest_sources - restore_sources):
    errors.append(f"In dots.toml but not in restore_cfg.lst: {src}")

if errors:
    print("MANIFEST ERRORS:")
    for e in errors:
        print(f"  {e}")
    sys.exit(1)
else:
    print("Manifest consistency: OK")
