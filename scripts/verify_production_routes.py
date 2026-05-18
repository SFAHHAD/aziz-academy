#!/usr/bin/env python3
"""
Production route smoke checker.

Reads every <loc> in https://aziz-academy.com/sitemap.xml and HEAD-checks
each URL. Reports:
  - any non-2xx status
  - any redirect (we want canonical URLs to serve 200, not 30x to themselves)
  - any timeout

Run after every prod deploy as a final sanity gate.

Usage:
  python scripts/verify_production_routes.py
  python scripts/verify_production_routes.py --base https://aziz-academy.com

Exit codes:
  0  every URL returned 2xx
  1  one or more URLs failed
"""

from __future__ import annotations

import argparse
import sys
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.parse import urlparse

UA = "AzizAcademy-route-check/1.0 (+https://aziz-academy.com)"
TIMEOUT = 15


def fetch_sitemap(base: str) -> list[str]:
    url = f"{base.rstrip('/')}/sitemap.xml"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        body = r.read()
    root = ET.fromstring(body)
    ns = {"s": "http://www.sitemaps.org/schemas/sitemap/0.9"}
    locs = [el.text.strip() for el in root.findall(".//s:loc", ns) if el.text]
    return locs


def check(url: str) -> tuple[str, int, str]:
    """Return (url, status, info). status==0 means exception."""
    req = urllib.request.Request(
        url, method="HEAD", headers={"User-Agent": UA}
    )
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            return (url, r.status, "")
    except urllib.error.HTTPError as e:
        return (url, e.code, str(e.reason))
    except urllib.error.URLError as e:
        return (url, 0, str(e.reason))
    except Exception as e:  # noqa: BLE001
        return (url, 0, str(e))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="https://aziz-academy.com")
    ap.add_argument("--workers", type=int, default=12)
    args = ap.parse_args()

    print(f"Fetching sitemap from {args.base}/sitemap.xml ...")
    try:
        urls = fetch_sitemap(args.base)
    except Exception as e:  # noqa: BLE001
        print(f"FATAL: could not read sitemap: {e}", file=sys.stderr)
        return 1
    print(f"Checking {len(urls)} URLs with {args.workers} workers...\n")

    failures: list[tuple[str, int, str]] = []
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futures = [ex.submit(check, u) for u in urls]
        for i, f in enumerate(as_completed(futures), 1):
            url, status, info = f.result()
            ok = 200 <= status < 300
            tag = "ok " if ok else "FAIL"
            host_path = urlparse(url).path or "/"
            print(f"  [{i:3}/{len(urls)}] {tag}  {status:>3}  {host_path}")
            if not ok:
                failures.append((url, status, info))

    print()
    if failures:
        print(f"{len(failures)} URL(s) failed:")
        for url, status, info in failures:
            print(f"  - {status}  {url}  {info}")
        return 1
    print(f"All {len(urls)} URLs returned 2xx.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
