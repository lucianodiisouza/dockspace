#!/usr/bin/env python3
"""
Generates placeholder Dockspace app icons at all macOS-required sizes.

Output: Resources/Assets.xcassets/AppIcon.appiconset/appicon-{size}.png
Existing files are overwritten.

Run from the repo root:
    python3 Scripts/generate-icon.py
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = "Resources/Assets.xcassets/AppIcon.appiconset"

# (size in px) — Apple's macOS icon spec
SIZES = [
    (16, 1),
    (16, 2),
    (32, 1),
    (32, 2),
    (128, 1),
    (128, 2),
    (256, 1),
    (256, 2),
    (512, 1),
    (512, 2),
]

# macOS uses sRGB. Dockspace's brand color is a warm coral from the
# Dockset reference design — enough to read as "ours" without claiming
# their exact hue.
BG_COLOR = (255, 107, 107, 255)
FG_COLOR = (255, 255, 255, 230)


def make_base_icon(size: int) -> Image.Image:
    """Renders a single base icon at the given pixel size."""
    # Render at 4x and downscale for crispness.
    render = size * 4
    img = Image.new("RGBA", (render, render), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Rounded square background using alpha mask.
    radius = int(render * 0.225)  # ~macOS squircle ratio
    draw.rounded_rectangle(
        (0, 0, render - 1, render - 1),
        radius=radius,
        fill=BG_COLOR,
    )

    # Three "dock" bars to evoke a Dock-like row.
    bar_w = int(render * 0.62)
    bar_h = int(render * 0.12)
    bar_x = (render - bar_w) // 2
    bar_y = int(render * 0.40)
    for i in range(3):
        y = bar_y + i * int(bar_h * 1.4)
        draw.rounded_rectangle(
            (bar_x, y, bar_x + bar_w, y + bar_h),
            radius=int(bar_h * 0.4),
            fill=FG_COLOR,
        )

    return img.resize((size, size), Image.LANCZOS)


def main() -> int:
    if not os.path.isdir(OUT_DIR):
        print(f"✗ output dir not found: {OUT_DIR}", file=sys.stderr)
        return 1

    for size, scale in SIZES:
        out_path = os.path.join(OUT_DIR, f"appicon-{size}x{size}@{scale}x.png")
        img = make_base_icon(size)
        img.save(out_path, "PNG", optimize=True)
        print(f"  {out_path}")

    print(f"✓ generated {len(SIZES)} icon variants in {OUT_DIR}")
    print("  next: open the project in Xcode and drag these into the")
    print("  AppIcon slot, or reference them from the Contents.json.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
