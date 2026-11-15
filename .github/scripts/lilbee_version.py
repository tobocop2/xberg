#!/usr/bin/env python3
"""Stamp the Python package version in pyproject.toml with a +lilbee local version. Idempotent."""

import os
import re
import sys
from pathlib import Path

PYPROJECT = Path("packages/python/pyproject.toml")


def main() -> int:
    text = PYPROJECT.read_text(encoding="utf-8")
    match = re.search(r'^version = "([^"]+)"', text, re.M)
    if not match:
        print("no version line in packages/python/pyproject.toml", file=sys.stderr)
        return 1
    base = match.group(1).split("+", 1)[0]
    version = f"{base}+lilbee"
    PYPROJECT.write_text(text.replace(match.group(0), f'version = "{version}"', 1), encoding="utf-8")
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a", encoding="utf-8") as handle:
            handle.write(f"lilbee_version={version}\n")
    print(f"stamped {PYPROJECT} -> {version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
