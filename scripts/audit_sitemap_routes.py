"""
Pre-deploy guard: every <loc> in web/sitemap.xml must correspond to a real
route declared in lib/core/router/app_router.dart, and every public route
should be discoverable from the sitemap.

Why this matters at launch:
  1. A sitemap that lists a route that no longer exists ships a 404 to
     Googlebot. Google penalises that against crawl budget and drops the
     domain in rankings — exactly the wrong launch-week signal.
  2. A new public route added to the router without a sitemap entry is
     invisible to organic discovery. The whole point of having 90+ games
     is the long tail of `aziz academy {game}` queries.

Sub-routes (e.g. /capitals/quiz), private parent-area routes, and admin
URLs are deliberately excluded from the sitemap; the SKIP_PREFIXES list
below documents which ones, so the audit doesn't false-alarm on them.

Usage:
  python scripts/audit_sitemap_routes.py

Exit codes:
  0  — sitemap and router agree
  1  — sitemap references a route the router does not have (broken link)
  2  — router has a public route missing from the sitemap (allow-list it
       in SKIP_PREFIXES below if intentional)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
SITEMAP = ROOT / "web" / "sitemap.xml"
ROUTER = ROOT / "lib" / "core" / "router" / "app_router.dart"

# Path prefixes that should NEVER appear in the sitemap even though they
# exist in the router. Each entry has a short reason.
SKIP_PREFIXES: list[tuple[str, str]] = [
    ("/x9k2-", "internal admin routes — not for crawlers"),
    ("/dev/", "developer-only widget gallery"),
    ("/welcome", "first-launch onboarding — entered via /, not directly"),
    ("/review-mode", "in-app review surface, no organic value"),
]

# Specific full paths that we keep out of the sitemap by design. Sub-route
# quiz paths funnel through their parent module page (e.g. /capitals →
# /capitals/quiz), so indexing the deep link adds duplicate-content noise.
SKIP_EXACT: set[str] = {
    "/capitals/quiz",
    "/flags/quiz",
    "/math/quiz",
    "/sciences/quiz",
    "/iq/quiz",
    "/iq/category",
    "/iq/daily",
    "/iq/champion",
    "/general-quiz/quiz",
    "/school-quiz",
    "/trophy",
    "/trophy/certificate",
    "/parent/digest",
    "/parent/report",
    "/parent/worksheet",
    "/parent/family-compare",
    "/parent/curriculum",
    # Private account-management screen — guest identity / parent sign-in.
    # No public content; not for crawlers.
    "/account",
    # Premium upgrade screen — reached from the account area, not a
    # public landing page.
    "/plus",
    # Internal deep-link target for the v2 home's hero cards
    # (/browse?cat=…). Renders the same activity grid as the home, just
    # pre-filtered — no unique content, so it stays out of the sitemap.
    "/browse",
}


def sitemap_paths(xml_path: Path) -> list[str]:
    ns = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
    root = ET.parse(xml_path).getroot()
    out: list[str] = []
    for loc in root.findall(".//sm:url/sm:loc", ns):
        url = (loc.text or "").strip()
        # Strip the hostname; sitemap may use fully-qualified URLs.
        m = re.search(r"https?://[^/]+(/.*)?", url)
        path = (m.group(1) if m and m.group(1) else "/").rstrip("/") or "/"
        out.append(path)
    return out


def router_paths(dart_path: Path) -> list[str]:
    src = dart_path.read_text(encoding="utf-8")
    # `static const someName = '/some/path';` inside AppRoutes.
    return re.findall(r"static const \w+\s*=\s*'(/[^']*)'", src)


def is_skipped(path: str) -> bool:
    if path in SKIP_EXACT:
        return True
    return any(path.startswith(prefix) for prefix, _ in SKIP_PREFIXES)


def main() -> int:
    if not SITEMAP.exists():
        print(f"FATAL: {SITEMAP} not found", file=sys.stderr)
        return 1
    if not ROUTER.exists():
        print(f"FATAL: {ROUTER} not found", file=sys.stderr)
        return 1

    sm = sitemap_paths(SITEMAP)
    rt = router_paths(ROUTER)
    rt_set = set(rt)
    sm_set = set(sm)

    broken = [p for p in sm if p not in rt_set]
    undiscovered = [p for p in rt if p not in sm_set and not is_skipped(p)]

    print(f"Sitemap entries: {len(sm)}")
    print(f"Router paths:    {len(rt)}")

    if broken:
        print()
        print(f"FAIL: {len(broken)} sitemap entries point to missing routes:")
        for p in broken:
            print(f"  - {p}")
        print("       Fix: remove the entry from web/sitemap.xml, or add the")
        print("       missing route to AppRoutes in app_router.dart.")
        return 1

    if undiscovered:
        print()
        print(
            f"FAIL: {len(undiscovered)} public routes are not listed in the sitemap:"
        )
        for p in undiscovered:
            print(f"  - {p}")
        print("       Fix: either add a <url> entry to web/sitemap.xml, or")
        print("       allow-list the prefix in SKIP_PREFIXES / SKIP_EXACT.")
        return 2

    print()
    print("OK — sitemap and router agree.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
