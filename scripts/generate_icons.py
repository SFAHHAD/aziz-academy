#!/usr/bin/env python3
"""Generate the iOS + Android + Web app-icon matrix from a single master.

Source: ``assets/images/logo_final.png`` (square, ideally >=1024px)
Output:
  - ``ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png`` (15 sizes)
  - ``android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png``
  - Foreground + background for Android 8.0 adaptive icons (XML and PNGs)
  - ``web/icons/Icon-{192,512}.png`` and ``web/favicon.png``

Run from repo root:  python scripts/generate_icons.py
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "images" / "logo_final.png"

# (filename, size) — derived from Apple's standard AppIcon.appiconset.
IOS_ICONS = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]
IOS_OUT = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

ANDROID_DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}
# Adaptive-icon foreground sizes are 108dp at each density (so the system can
# crop a circle/squircle/teardrop without clipping content).
ANDROID_ADAPTIVE_FG_SIZES = {
    "mdpi": 108,
    "hdpi": 162,
    "xhdpi": 216,
    "xxhdpi": 324,
    "xxxhdpi": 432,
}
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"


def load_master() -> Image.Image:
    if not SRC.exists():
        sys.exit(f"missing master at {SRC}")
    im = Image.open(SRC).convert("RGBA")
    if im.size[0] != im.size[1]:
        sys.exit(f"master is not square: {im.size}")
    if im.size[0] < 1024:
        # Upsample once with bicubic to feed the larger renderings; small
        # downscales below this line all use LANCZOS for sharpness.
        im = im.resize((1024, 1024), Image.BICUBIC)
    return im


def write_png(im: Image.Image, dest: Path, size: int, *, mode: str = "RGB") -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    out = im.resize((size, size), Image.LANCZOS)
    if mode == "RGB":
        bg = Image.new("RGB", out.size, (255, 255, 255))
        bg.paste(out, mask=out.split()[3])
        out = bg
    out.save(dest, format="PNG", optimize=True)


def write_adaptive_fg(im: Image.Image, dest: Path, size: int) -> None:
    """Adaptive foreground: master inset to 66% on a transparent canvas."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inset = int(size * 0.66)
    fg = im.resize((inset, inset), Image.LANCZOS)
    off = (size - inset) // 2
    canvas.paste(fg, (off, off), fg)
    canvas.save(dest, format="PNG", optimize=True)


def write_adaptive_bg_xml() -> None:
    """Solid brand background XML for Android adaptive icons."""
    values_dir = ANDROID_RES / "values"
    values_dir.mkdir(parents=True, exist_ok=True)
    (values_dir / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#0F2445</color>\n'
        "</resources>\n",
        encoding="utf-8",
    )
    aniv26 = ANDROID_RES / "mipmap-anydpi-v26"
    aniv26.mkdir(parents=True, exist_ok=True)
    (aniv26 / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n",
        encoding="utf-8",
    )


def main() -> None:
    master = load_master()

    print("• iOS")
    for name, size in IOS_ICONS:
        write_png(master, IOS_OUT / name, size, mode="RGB")
        print(f"  - {name} ({size}px)")

    print("• Android legacy launcher")
    for density, size in ANDROID_DENSITIES.items():
        dest = ANDROID_RES / f"mipmap-{density}" / "ic_launcher.png"
        write_png(master, dest, size, mode="RGB")
        print(f"  - mipmap-{density}/ic_launcher.png ({size}px)")

    print("• Android adaptive foreground")
    for density, size in ANDROID_ADAPTIVE_FG_SIZES.items():
        dest = ANDROID_RES / f"mipmap-{density}" / "ic_launcher_foreground.png"
        write_adaptive_fg(master, dest, size)
        print(f"  - mipmap-{density}/ic_launcher_foreground.png ({size}px)")
    write_adaptive_bg_xml()
    print("  - values/ic_launcher_background.xml")
    print("  - mipmap-anydpi-v26/ic_launcher.xml")

    print("• Web")
    web = ROOT / "web"
    write_png(master, web / "icons" / "Icon-192.png", 192, mode="RGB")
    write_png(master, web / "icons" / "Icon-512.png", 512, mode="RGB")
    write_png(master, web / "icons" / "Icon-maskable-192.png", 192, mode="RGB")
    write_png(master, web / "icons" / "Icon-maskable-512.png", 512, mode="RGB")
    write_png(master, web / "favicon.png", 64, mode="RGB")
    print("  - icons/Icon-192.png, Icon-512.png, maskable variants, favicon.png")

    print("done.")


if __name__ == "__main__":
    main()
