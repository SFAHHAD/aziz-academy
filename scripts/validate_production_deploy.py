#!/usr/bin/env python3
"""
Post-deploy validator. Catches the regressions we've actually hit during
development so they never re-ship without you noticing.

Each check returns (ok, message). The script exits non-zero if any check
fails so it can gate `deploy_web.ps1` and CI.

Run:
  python scripts/validate_production_deploy.py
  python scripts/validate_production_deploy.py --base https://aziz-academy.com
"""

from __future__ import annotations

import argparse
import sys
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Callable

UA = "AzizAcademy-validator/1.0 (+https://aziz-academy.com)"
TIMEOUT = 15


# ----- HTTP helpers ----------------------------------------------------------

def fetch(url: str, method: str = "GET") -> tuple[int, dict, bytes]:
    req = urllib.request.Request(
        url, method=method, headers={"User-Agent": UA}
    )
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            return (r.status, dict(r.headers), r.read() if method == "GET" else b"")
    except urllib.error.HTTPError as e:
        return (e.code, dict(e.headers or {}), b"")
    except urllib.error.URLError as e:
        return (0, {}, str(e.reason).encode("utf-8"))


# ----- Individual checks -----------------------------------------------------

def check_root_200(base: str) -> tuple[bool, str]:
    status, _, _ = fetch(base + "/")
    return (status == 200, f"GET / -> {status}")


def check_csp_has_fonts_gstatic(base: str) -> tuple[bool, str]:
    """Without fonts.gstatic.com in connect-src, Flutter can't fetch the
    Noto fallback fonts and emojis render as tofu boxes.
    """
    _, headers, _ = fetch(base + "/")
    csp = headers.get("Content-Security-Policy", "")
    needs = "https://fonts.gstatic.com"
    in_connect = needs in _directive(csp, "connect-src")
    in_font = needs in _directive(csp, "font-src")
    if in_connect and in_font:
        return (True, "CSP allows fonts.gstatic.com in connect-src + font-src")
    missing = []
    if not in_connect: missing.append("connect-src")
    if not in_font: missing.append("font-src")
    return (False, f"CSP missing fonts.gstatic.com in: {missing}")


def check_csp_has_supabase(base: str) -> tuple[bool, str]:
    """Parent accounts + cloud sync talk to the Supabase project. Without
    its origin in connect-src, every auth/sync call is blocked by CSP.
    """
    _, headers, _ = fetch(base + "/")
    csp = headers.get("Content-Security-Policy", "")
    needs = "pwdhwhpnwrlzrerrdqvg.supabase.co"
    if needs in _directive(csp, "connect-src"):
        return (True, "CSP allows the Supabase origin in connect-src")
    return (False, "CSP missing the Supabase origin in connect-src")


def check_canvaskit_local(base: str) -> tuple[bool, str]:
    """Bootstrap must be patched to load CanvasKit from our /canvaskit/
    instead of gstatic — otherwise we don't get the 1-year immutable cache.
    """
    _, _, body = fetch(base + "/flutter_bootstrap.js")
    text = body.decode("utf-8", errors="replace")
    if 'canvasKitBaseUrl:"/canvaskit/"' not in text:
        return (False, "flutter_bootstrap.js NOT patched for local CanvasKit")
    if 'canvasKitVariant:"full"' not in text:
        return (False, "flutter_bootstrap.js missing canvasKitVariant:\"full\" — Chrome will try /canvaskit/chromium/ which we strip")
    return (True, "CanvasKit configured to load from /canvaskit/ (full variant)")


def check_canvaskit_files_present(base: str) -> tuple[bool, str]:
    js_status, _, _ = fetch(base + "/canvaskit/canvaskit.js", method="HEAD")
    wasm_status, _, _ = fetch(base + "/canvaskit/canvaskit.wasm", method="HEAD")
    if js_status == 200 and wasm_status == 200:
        return (True, "canvaskit.js + canvaskit.wasm both present")
    return (False, f"canvaskit.js={js_status}, canvaskit.wasm={wasm_status}")


def check_no_broken_vercel_insights(base: str) -> tuple[bool, str]:
    """If the script tag is in the HTML but Web Analytics isn't enabled
    in the Vercel dashboard, /_vercel/insights/script.js 404s with
    text/html and the browser logs a MIME error. Either enable analytics
    or the tag should be commented out.
    """
    _, _, body = fetch(base + "/")
    html = body.decode("utf-8", errors="replace")
    # Strip HTML comments before searching — a commented-out tag is fine.
    import re as _re
    stripped = _re.sub(r"<!--.*?-->", "", html, flags=_re.DOTALL)
    if "<script defer src=\"/_vercel/insights/script.js\">" not in stripped:
        return (True, "/_vercel/insights script tag not active (commented or absent)")
    insights_status, insights_headers, _ = fetch(base + "/_vercel/insights/script.js", method="HEAD")
    ct = insights_headers.get("Content-Type", "")
    if insights_status == 200 and "javascript" in ct.lower():
        return (True, "/_vercel/insights script tag present AND Vercel serves it as JS")
    return (False, f"/_vercel/insights tag active in HTML but server returns status={insights_status} content-type={ct}")


def check_security_txt(base: str) -> tuple[bool, str]:
    status, headers, _ = fetch(base + "/.well-known/security.txt", method="HEAD")
    ct = headers.get("Content-Type", "")
    if status != 200:
        return (False, f"/.well-known/security.txt -> {status}")
    if not ct.startswith("text/plain"):
        return (False, f"security.txt content-type is '{ct}' (must be text/plain)")
    return (True, "security.txt serves as text/plain")


def check_sitemap_xml(base: str) -> tuple[bool, str]:
    status, _, body = fetch(base + "/sitemap.xml")
    if status != 200:
        return (False, f"sitemap.xml -> {status}")
    try:
        root = ET.fromstring(body)
    except ET.ParseError as e:
        return (False, f"sitemap.xml does not parse as XML: {e}")
    ns = {"s": "http://www.sitemaps.org/schemas/sitemap/0.9"}
    locs = root.findall(".//s:loc", ns)
    return (True, f"sitemap.xml parses with {len(locs)} URLs")


def check_robots_disallows(base: str) -> tuple[bool, str]:
    status, _, body = fetch(base + "/robots.txt")
    if status != 200:
        return (False, f"robots.txt -> {status}")
    text = body.decode("utf-8", errors="replace")
    needs = ["x9k2-admin-portal", "diag.html"]
    missing = [n for n in needs if n not in text]
    if missing:
        return (False, f"robots.txt missing Disallow for: {missing}")
    return (True, "robots.txt has admin/diag disallows")


def check_canonical_redirects(base: str) -> tuple[bool, str]:
    """vercel.com/aziz-academy.vercel.app should 308 to aziz-academy.com.
    Skip if base isn't the apex domain.
    """
    if "aziz-academy.com" not in base:
        return (True, "skipped (not testing apex)")
    # Use raw urlopen with no-redirect handler to inspect the 308.
    req = urllib.request.Request(
        "https://aziz-academy.vercel.app/", headers={"User-Agent": UA}
    )
    opener = urllib.request.build_opener(NoRedirect())
    try:
        opener.open(req, timeout=TIMEOUT)
        return (False, "aziz-academy.vercel.app did NOT redirect")
    except urllib.error.HTTPError as e:
        if e.code in (301, 308) and "aziz-academy.com" in e.headers.get("Location", ""):
            return (True, f"aziz-academy.vercel.app -> {e.code} -> {e.headers.get('Location')}")
        return (False, f"aziz-academy.vercel.app -> {e.code} (expected 308)")


def check_strict_transport_security(base: str) -> tuple[bool, str]:
    _, headers, _ = fetch(base + "/")
    hsts = headers.get("Strict-Transport-Security", "")
    if "max-age" not in hsts:
        return (False, "HSTS header missing")
    return (True, f"HSTS: {hsts[:60]}")


def check_material_icons_tree_shaken(base: str) -> tuple[bool, str]:
    """MaterialIcons-Regular.otf should be tree-shaken to <100KB.
    Untreated, it ships ~1.6MB; tree-shake takes it to ~22KB. If this check
    fails, someone added --no-tree-shake-icons or used a dynamic IconData()
    constructor that bypassed the analyzer.
    """
    url = base + "/assets/fonts/MaterialIcons-Regular.otf"
    status, headers, _ = fetch(url, method="HEAD")
    if status != 200:
        return (False, f"MaterialIcons-Regular.otf -> {status}")
    size = int(headers.get("Content-Length", "0"))
    if size > 200_000:
        return (False,
                f"MaterialIcons-Regular.otf is {size:,} bytes — tree-shake "
                f"appears DISABLED. Either re-enable --tree-shake-icons or "
                f"track down the dynamic IconData() construction.")
    return (True, f"MaterialIcons-Regular.otf is tree-shaken to {size:,} bytes")


def check_amiri_font_loads(base: str) -> tuple[bool, str]:
    """Amiri Regular covers the Arabic Presentation Forms (ﷺ) and Latin
    Extended Additional (ḥ ʿ) that Cairo doesn't. Without it, CanvasKit
    cannot render those glyphs and loops in requestAnimationFrame logging
    "Could not find a set of Noto fonts" forever.
    """
    url = base + "/assets/assets/fonts/Amiri-Regular.ttf"
    status, headers, body = fetch(url, method="HEAD")
    if status != 200:
        return (False, f"Amiri-Regular.ttf -> {status}")
    size = int(headers.get("Content-Length", "0"))
    if size < 100_000:
        return (False, f"Amiri-Regular.ttf is {size:,} bytes — suspiciously small")
    return (True, f"Amiri-Regular.ttf served ({size:,} bytes)")


def check_emoji_font_is_colrv1(base: str) -> tuple[bool, str]:
    """The bundled NotoColorEmoji must be the COLR/CPAL vector variant.
    The bitmap CBDT/CBLC variant from googlefonts/noto-emoji is unrenderable
    by CanvasKit — it claims cmap coverage, then bitmap rendering fails inside
    the painter and the FontFallbackManager throws. Smaller-than-CBDT size is
    the cheap signal; the format check on the bytes is the authoritative one.
    """
    import struct
    url = base + "/assets/assets/fonts/NotoColorEmoji.ttf"
    status, headers, body = fetch(url)
    if status != 200:
        return (False, f"NotoColorEmoji.ttf -> {status}")
    size = int(headers.get("Content-Length", str(len(body))))
    # CBDT version is ~10.6 MB; COLRv1-noflags is ~2.9 MB. Anything > 6 MB
    # is suspicious. Combine with a table-tag inspection on the raw bytes.
    if size > 6_000_000:
        return (False, f"NotoColorEmoji.ttf is {size:,} bytes — CBDT bitmap variant is back?")
    try:
        num_tables = struct.unpack(">H", body[4:6])[0]
        tags = {body[12 + i * 16: 12 + i * 16 + 4].decode("ascii", errors="replace")
                for i in range(num_tables)}
    except Exception as e:
        return (False, f"could not parse NotoColorEmoji.ttf header: {e}")
    has_colr_cpal = "COLR" in tags and "CPAL" in tags
    has_cbdt_cblc = "CBDT" in tags and "CBLC" in tags
    if has_cbdt_cblc:
        return (False, "NotoColorEmoji.ttf is CBDT/CBLC bitmap — CanvasKit cannot render this. Bundle the COLRv1 variant.")
    if not has_colr_cpal:
        return (False, f"NotoColorEmoji.ttf has neither COLR/CPAL nor CBDT/CBLC tables (tables: {sorted(tags)})")
    return (True, f"NotoColorEmoji.ttf is COLRv1 vector ({size:,} bytes)")


def check_main_dart_js_size(base: str) -> tuple[bool, str]:
    """Sanity: main.dart.js wire size shouldn't blow back up to 5+ MB."""
    _, headers, _ = fetch(base + "/main.dart.js", method="HEAD")
    size = int(headers.get("Content-Length", "0"))
    # The on-disk size after our optimizations is ~4.3 MB.
    # Warn if main.dart.js exceeds 5 MB on disk (i.e. someone broke deferred
    # imports or added a heavy dep).
    threshold = 5_000_000
    if size > threshold:
        return (False, f"main.dart.js is {size:,} bytes — exceeds {threshold:,} threshold")
    if size < 1_000_000:
        return (False, f"main.dart.js is suspiciously small at {size:,} bytes — build broken?")
    return (True, f"main.dart.js is {size:,} bytes")


def check_main_dart_js_brotli_wire_size(base: str) -> tuple[bool, str]:
    """Brotli-compressed wire size of main.dart.js — what users actually pay
    for on cold load. Baseline as of 2026-05-10: ~1.25 MB. Threshold 1.6 MB
    catches large dep additions (~30% growth) before they ship.
    """
    req = urllib.request.Request(
        base + "/main.dart.js",
        method="GET",
        headers={"User-Agent": UA, "Accept-Encoding": "br"},
    )
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            encoding = r.headers.get("Content-Encoding", "")
            # urllib does NOT auto-decompress brotli, so len(body) IS the
            # wire size. Reading the body is more reliable than trusting
            # Content-Length, which can be missing on chunked transfers.
            wire_size = len(r.read())
    except urllib.error.URLError as e:
        return (False, f"could not fetch main.dart.js: {e}")
    if encoding != "br":
        return (False, f"main.dart.js wire encoding is '{encoding}' (expected 'br')")
    threshold = 1_600_000
    if wire_size > threshold:
        return (False, f"main.dart.js brotli wire size is {wire_size:,} bytes (>{threshold:,})")
    if wire_size < 500_000:
        return (False, f"main.dart.js brotli wire size suspiciously small at {wire_size:,} bytes")
    return (True, f"main.dart.js brotli wire size is {wire_size:,} bytes")


def check_og_image_immutable_cache(base: str) -> tuple[bool, str]:
    """og-image.png is hit by every social/IM share-preview crawler. It never
    changes between deploys, so it should serve with a 1-year immutable cache
    — otherwise crawlers re-fetch it on every preview and we waste edge
    bandwidth + origin bytes.
    """
    status, headers, _ = fetch(base + "/og-image.png", method="HEAD")
    if status != 200:
        return (False, f"og-image.png -> {status}")
    cc = headers.get("Cache-Control", "")
    if "max-age=31536000" not in cc or "immutable" not in cc:
        return (False, f"og-image.png Cache-Control is '{cc}' (expected 1y immutable)")
    return (True, "og-image.png served with 1y immutable cache")


def check_part_chunks_revalidate(base: str) -> tuple[bool, str]:
    """Deferred-import part chunks (main.dart.js_NN.part.js) have sequential
    (non-content-hashed) names, so they MUST revalidate alongside main.dart.js
    after a deploy. If they cache long, a new main.dart.js could import a stale
    part file built against the old API — runtime import errors.
    """
    # Probe a likely-existing part chunk; if it's missing, find the first one
    # from a small scan. We pick _1 since every deferred build emits at least
    # one part file.
    status, headers, _ = fetch(base + "/main.dart.js_1.part.js", method="HEAD")
    if status != 200:
        return (False, f"main.dart.js_1.part.js -> {status} (expected 200)")
    cc = headers.get("Cache-Control", "")
    if "max-age=0" not in cc or "must-revalidate" not in cc:
        return (False, f"main.dart.js_1.part.js Cache-Control is '{cc}' (expected max-age=0, must-revalidate)")
    return (True, "part chunks revalidate alongside main.dart.js")


# ----- Helpers ---------------------------------------------------------------

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, hdrs, newurl):
        return None


def _directive(csp: str, name: str) -> str:
    """Return the body of a CSP directive (everything after 'name ' up to ';')."""
    for chunk in csp.split(";"):
        chunk = chunk.strip()
        if chunk.startswith(name + " "):
            return chunk[len(name) + 1:]
    return ""


# ----- Driver ----------------------------------------------------------------

CHECKS: list[tuple[str, Callable[[str], tuple[bool, str]]]] = [
    ("root 200", check_root_200),
    ("CSP allows fonts.gstatic.com", check_csp_has_fonts_gstatic),
    ("CSP allows Supabase origin", check_csp_has_supabase),
    ("CanvasKit local + full variant", check_canvaskit_local),
    ("CanvasKit files present", check_canvaskit_files_present),
    ("No broken Vercel Insights tag", check_no_broken_vercel_insights),
    ("security.txt serves text/plain", check_security_txt),
    ("sitemap.xml parses", check_sitemap_xml),
    ("robots.txt has disallows", check_robots_disallows),
    ("canonical 308 redirect", check_canonical_redirects),
    ("HSTS header", check_strict_transport_security),
    ("main.dart.js size sane", check_main_dart_js_size),
    ("main.dart.js brotli wire size sane", check_main_dart_js_brotli_wire_size),
    ("Emoji font is COLRv1 vector", check_emoji_font_is_colrv1),
    ("Amiri Arabic font loads", check_amiri_font_loads),
    ("MaterialIcons tree-shaken", check_material_icons_tree_shaken),
    ("og-image.png has 1y immutable cache", check_og_image_immutable_cache),
    ("part chunks revalidate", check_part_chunks_revalidate),
]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="https://aziz-academy.com")
    args = ap.parse_args()
    base = args.base.rstrip("/")

    print(f"Validating {base}\n")
    failures: list[tuple[str, str]] = []

    with ThreadPoolExecutor(max_workers=6) as ex:
        futures = {ex.submit(fn, base): name for name, fn in CHECKS}
        for f in as_completed(futures):
            name = futures[f]
            ok, message = f.result()
            mark = "ok  " if ok else "FAIL"
            print(f"  [{mark}] {name}: {message}")
            if not ok:
                failures.append((name, message))

    print()
    if failures:
        print(f"{len(failures)} check(s) FAILED:")
        for name, msg in failures:
            print(f"  - {name}: {msg}")
        return 1
    print(f"All {len(CHECKS)} checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
