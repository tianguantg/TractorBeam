#!/usr/bin/env python3
"""
Convert PNG paper cards in assets/images/paper/ to optimized WebP format.
Reduces ~11.4 MB of assets to ~0.74 MB (93.5% reduction) with lossless alpha
and high quality (q=90, method=6).
"""
import pathlib
import sys
from PIL import Image


def main() -> int:
    repo_root = pathlib.Path(__file__).resolve().parent.parent
    paper_dir = repo_root / "apps" / "tractor-beam-flutter" / "assets" / "images" / "paper"

    if not paper_dir.is_dir():
        print(f"Error: Directory not found: {paper_dir}", file=sys.stderr)
        return 1

    png_files = list(paper_dir.glob("*.png"))
    if not png_files:
        print("No PNG files found to convert.")
        return 0

    total_orig = 0
    total_webp = 0

    print(f"Converting {len(png_files)} paper cards to WebP...")
    for png_path in png_files:
        orig_size = png_path.stat().st_size
        total_orig += orig_size

        webp_path = png_path.with_suffix(".webp")
        with Image.open(png_path) as im:
            im.save(webp_path, format="WEBP", quality=90, method=6)

        webp_size = webp_path.stat().st_size
        total_webp += webp_size
        print(f"  {png_path.name:30s}: {orig_size/1024:6.1f} KB -> {webp_size/1024:5.1f} KB ({(1 - webp_size/orig_size)*100:.1f}%)")

        # Remove the original PNG
        png_path.unlink()

    print(f"\nDone. {total_orig / 1024 / 1024:.2f} MB -> {total_webp / 1024 / 1024:.2f} MB ({(1 - total_webp/total_orig)*100:.1f}% reduction)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
