"""Regenerate sitemap_paths.txt from web/sitemap.xml.

This text file is a flat list of every public path that should be
crawlable. It is not loaded at runtime — it's a human-readable
companion to the XML sitemap, useful for grepping, diffing across
releases, and pasting into Vercel's deployment notes.

Usage:
  python scripts/regenerate_sitemap_paths.py
"""

from __future__ import annotations

import re
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
SITEMAP = ROOT / "web" / "sitemap.xml"
OUT = ROOT / "sitemap_paths.txt"


def main() -> int:
    ns = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
    root = ET.parse(SITEMAP).getroot()
    paths: list[str] = []
    for loc in root.findall(".//sm:url/sm:loc", ns):
        url = (loc.text or "").strip()
        m = re.search(r"https?://[^/]+(/.*)?", url)
        path = (m.group(1) if m and m.group(1) else "/")
        paths.append(path)
    paths.sort()
    OUT.write_text("\n".join(paths) + "\n", encoding="utf-8")
    print(f"wrote {len(paths)} paths to {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
