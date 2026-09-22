#!/usr/bin/env python3
"""
Subset Xiaolai-Regular.ttf to common Chinese character sets and project texts.
Reduces font file size from ~21.2 MB to ~2.9 MB while retaining all project UI text,
GB2312 simplified Chinese charset (6763 Hanzi), ASCII, punctuation, and gaming symbols.
"""
from __future__ import annotations

import pathlib
import sys
from fontTools import subset


def collect_project_characters(root_dir: pathlib.Path) -> set[str]:
    chars: set[str] = set()

    # 1. Printable ASCII (0x20..0x7E)
    chars.update(chr(i) for i in range(0x20, 0x7F))

    # 2. GB2312 standard Chinese charset (6,763 common Hanzi)
    for b1 in range(0xB0, 0xF8):
        for b2 in range(0xA1, 0xFF):
            try:
                chars.add(bytes([b1, b2]).decode("gb2312"))
            except UnicodeDecodeError:
                pass

    # 3. Common typography, symbols, full-width punctuation
    for i in range(0x2000, 0x2070):
        chars.add(chr(i))
    for i in range(0x3000, 0x3040):
        chars.add(chr(i))
    for i in range(0xFF00, 0xFF60):
        chars.add(chr(i))

    # 4. Extract all text from project files
    for ext in ("*.dart", "*.arb", "*.yaml", "*.md", "*.json"):
        for path in (root_dir / "apps" / "tractor-beam-flutter").rglob(ext):
            try:
                chars.update(path.read_text(encoding="utf-8"))
            except Exception:
                pass

    return chars


def subset_font(
    input_font: pathlib.Path,
    output_font: pathlib.Path,
    chars: set[str],
) -> int:
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_languages = ["*"]
    options.passthrough_tables = True

    font = subset.load_font(str(input_font), options)
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text="".join(sorted(chars)))
    subsetter.subset(font)
    subset.save_font(font, str(output_font), options)
    font.close()

    return output_font.stat().st_size


def main() -> int:
    repo_root = pathlib.Path(__file__).resolve().parent.parent
    font_path = (
        repo_root
        / "apps"
        / "tractor-beam-flutter"
        / "assets"
        / "fonts"
        / "Xiaolai-Regular.ttf"
    )

    if not font_path.is_file():
        print(f"Error: Font not found at {font_path}", file=sys.stderr)
        return 1

    orig_size = font_path.stat().st_size
    print(f"Collecting character set for subsetting...")
    chars = collect_project_characters(repo_root)
    print(f"Collected {len(chars)} unique characters.")

    tmp_out = font_path.with_suffix(".tmp.ttf")
    new_size = subset_font(font_path, tmp_out, chars)

    tmp_out.replace(font_path)
    print(f"Original size : {orig_size / 1024 / 1024:.2f} MB ({orig_size} bytes)")
    print(f"Subsetted size: {new_size / 1024 / 1024:.2f} MB ({new_size} bytes)")
    print(f"Savings       : {(1 - new_size / orig_size) * 100:.2f}% reduction")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
