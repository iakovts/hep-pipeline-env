#!/usr/bin/env python3
"""Regenerate README.md from docs/ (the single source of truth).

Concatenates docs/*.md in ORDER under a short marker and rewrites intra-doc
links so they resolve from the repository root on GitHub. Wired to the
pre-commit hook at .githooks/pre-commit; run manually with:

    python scripts/build_readme.py
"""

from __future__ import annotations

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
DOCS_DIR = REPO_ROOT / "docs"

ORDER = [
    "index.md",
    "apptainer.md",
    "docker.md",
    "running-the-pipeline.md",
    "troubleshooting.md",
]

MARKER = "<!-- Generated from docs/ by scripts/build_readme.py — do not edit directly. -->"

# Rewrite relative links to sibling docs so they work from the repo root.
LINK_RE = re.compile(r"\]\((?!/)([\w./-]+)\.md(#[^)]*)?\)")


def rewrite_links(text: str) -> str:
    return LINK_RE.sub(
        lambda m: f"](docs/{m.group(1)}.md{m.group(2) or ''})", text
    )


def main() -> None:
    parts = [MARKER]
    for name in ORDER:
        path = DOCS_DIR / name
        if not path.exists():
            print(f"warning: missing {path}")
            continue
        parts.append("")
        parts.append(rewrite_links(path.read_text().rstrip()))
    (REPO_ROOT / "README.md").write_text("\n".join(parts).rstrip() + "\n")
    print("wrote README.md")


if __name__ == "__main__":
    main()
