"""Manifest-driven, non-destructive PNG normalization and audit pipeline.

The source assets are never overwritten. Generated previews, a machine-readable
audit report, and contact sheets are written below ``build/normalized_assets``.
After visual/golden review, selected generated files can be copied into the
shipping asset folders in a separate, deliberate change.

Usage (from apps/tractor-beam-flutter):
  python tool/asset_pipeline.py audit
  python tool/asset_pipeline.py generate
  python tool/asset_pipeline.py contact-sheet
  python tool/asset_pipeline.py all
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import sys
from typing import Any

import numpy as np
from PIL import Image, ImageDraw, ImageFont


APP_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SPEC = Path(__file__).with_name("asset_specs.json")
REPORT_PATH = APP_ROOT / "build" / "normalized_assets" / "audit.json"
CONTACT_SHEET_PATH = APP_ROOT / "build" / "normalized_assets" / "contact_sheet.png"
PAPER_CONTACT_SHEET_PATH = (
    APP_ROOT / "build" / "normalized_assets" / "paper_contact_sheet.png"
)


@dataclass(frozen=True)
class VisibleGeometry:
    box: tuple[int, int, int, int]
    centroid: tuple[float, float]
    visible_pixels: int


def _load_spec(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if data.get("schemaVersion") != 1:
        raise ValueError("Unsupported asset specification schema")
    return data


def _path(value: str) -> Path:
    return APP_ROOT / Path(value)


def _rgba(path: Path) -> Image.Image:
    with Image.open(path) as image:
        return image.convert("RGBA")


def _visible_geometry(image: Image.Image, threshold: int) -> VisibleGeometry | None:
    alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
    mask = alpha > threshold
    ys, xs = np.nonzero(mask)
    if xs.size == 0:
        return None
    weights = alpha[ys, xs].astype(np.float64)
    return VisibleGeometry(
        box=(int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1),
        centroid=(float(np.average(xs, weights=weights)), float(np.average(ys, weights=weights))),
        visible_pixels=int(xs.size),
    )


def _hex_rgb(value: str) -> tuple[int, int, int]:
    value = value.removeprefix("#")
    if len(value) != 6:
        raise ValueError(f"Invalid RGB color: {value}")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))  # type: ignore[return-value]


def _icon_rule(spec: dict[str, Any], name: str) -> dict[str, Any]:
    rule = dict(spec["icons"]["defaults"])
    rule.update(spec["icons"].get("overrides", {}).get(name, {}))
    canvas = rule["canvas"]
    rule["canvas"] = [canvas, canvas] if isinstance(canvas, int) else canvas
    return rule


def normalize_icon(
    image: Image.Image,
    rule: dict[str, Any],
    *,
    threshold: int,
    ink_color: tuple[int, int, int],
) -> Image.Image:
    """Normalize visible scale and optical centre while retaining antialiasing."""
    geometry = _visible_geometry(image, threshold)
    if geometry is None:
        raise ValueError("Image has no visible pixels")
    left, top, right, bottom = geometry.box
    # Include every antialiased pixel adjacent to the threshold-derived bounds.
    left, top = max(0, left - 2), max(0, top - 2)
    right, bottom = min(image.width, right + 2), min(image.height, bottom + 2)
    crop = image.crop((left, top, right, bottom))

    canvas_width, canvas_height = map(int, rule["canvas"])
    if rule.get("kind") == "stretch":
        normalized = crop.resize((canvas_width, canvas_height), Image.Resampling.LANCZOS)
    else:
        visible_ratio = float(rule.get("visibleRatio", 0.78))
        available_width = max(1, round(canvas_width * visible_ratio))
        available_height = max(1, round(canvas_height * visible_ratio))
        scale = min(available_width / crop.width, available_height / crop.height)
        target = (
            max(1, round(crop.width * scale)),
            max(1, round(crop.height * scale)),
        )
        normalized = crop.resize(target, Image.Resampling.LANCZOS)

    if rule.get("normalizeInk", True):
        alpha = normalized.getchannel("A")
        solid = Image.new("RGBA", normalized.size, (*ink_color, 255))
        solid.putalpha(alpha)
        normalized = solid

    canvas = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
    geometry = _visible_geometry(normalized, 0)
    assert geometry is not None
    if rule.get("opticalCenter", True):
        offset_x = round(canvas_width / 2 - geometry.centroid[0])
        offset_y = round(canvas_height / 2 - geometry.centroid[1])
    else:
        offset_x = (canvas_width - normalized.width) // 2
        offset_y = (canvas_height - normalized.height) // 2
    # Keep all antialiasing inside the destination even after centroid correction.
    offset_x = min(max(offset_x, 0), canvas_width - normalized.width)
    offset_y = min(max(offset_y, 0), canvas_height - normalized.height)
    canvas.alpha_composite(normalized, (offset_x, offset_y))
    return canvas


def _edge_runs(mask: np.ndarray, stroke: np.ndarray, axis: int, reverse: bool) -> list[int]:
    values: list[int] = []
    primary, secondary = mask.shape if axis == 0 else mask.T.shape
    oriented_mask = mask if axis == 0 else mask.T
    oriented_stroke = stroke if axis == 0 else stroke.T
    indices = range(primary - 1, -1, -1) if reverse else range(primary)
    for secondary_index in range(secondary // 4, 3 * secondary // 4, 5):
        started = False
        run = 0
        for primary_index in indices:
            if not oriented_mask[primary_index, secondary_index]:
                if started:
                    break
                continue
            started = True
            if oriented_stroke[primary_index, secondary_index]:
                run += 1
            elif run:
                break
        if 0 < run < 40:
            values.append(run)
    return values


def measure_paper_edges(image: Image.Image, render_size: tuple[int, int]) -> dict[str, float | None]:
    """Measure four screen-space border medians; shadows are excluded by darkness."""
    rendered = image.resize(render_size, Image.Resampling.LANCZOS)
    pixels = np.asarray(rendered, dtype=np.uint8)
    alpha = pixels[:, :, 3]
    rgb = pixels[:, :, :3].astype(np.float32)
    luminance = rgb[:, :, 0] * 0.299 + rgb[:, :, 1] * 0.587 + rgb[:, :, 2] * 0.114
    paper = alpha > 40
    stroke = paper & (luminance < 95)
    samples = {
        "top": _edge_runs(paper, stroke, axis=0, reverse=False),
        "bottom": _edge_runs(paper, stroke, axis=0, reverse=True),
        "left": _edge_runs(paper, stroke, axis=1, reverse=False),
        "right": _edge_runs(paper, stroke, axis=1, reverse=True),
    }
    return {
        name: (round(float(np.median(values)), 3) if values else None)
        for name, values in samples.items()
    }


def generate(spec: dict[str, Any]) -> list[Path]:
    generated: list[Path] = []
    threshold = int(spec["alphaThreshold"])
    ink_color = _hex_rgb(spec["inkColor"])
    icon_source = _path(spec["icons"]["source"])
    icon_output = _path(spec["icons"]["output"])
    icon_output.mkdir(parents=True, exist_ok=True)
    for source in sorted(icon_source.glob("*.png")):
        result = normalize_icon(
            _rgba(source),
            _icon_rule(spec, source.name),
            threshold=threshold,
            ink_color=ink_color,
        )
        output = icon_output / source.name
        result.save(output, optimize=True)
        generated.append(output)

    paper_source = _path(spec["papers"]["source"])
    paper_output = _path(spec["papers"]["output"])
    paper_output.mkdir(parents=True, exist_ok=True)
    # Paper edges combine ink, antialiasing, torn fibres and a semi-transparent
    # shadow. Threshold-based rewriting cannot reliably separate those layers
    # and produces banding. Keep paper generation audit-only until an asset has
    # an explicit, reviewed mask authored for it.
    paper_mode = spec["papers"].get("mode", "audit-only")
    if paper_mode != "audit-only":
        raise ValueError(
            "Paper pixel rewriting is disabled; use audit-only and author "
            "reviewed edge masks for individual outliers"
        )
    for name, rule in spec["papers"]["items"].items():
        source = paper_source / name
        if not source.exists():
            continue
        output = paper_output / name
        _rgba(source).save(output, optimize=True)
        generated.append(output)
    return generated


def audit(spec: dict[str, Any], *, strict: bool) -> dict[str, Any]:
    threshold = int(spec["alphaThreshold"])
    warnings: list[str] = []
    errors: list[str] = []
    icons: list[dict[str, Any]] = []
    papers: list[dict[str, Any]] = []

    icon_source = _path(spec["icons"]["source"])
    for source in sorted(icon_source.glob("*.png")):
        image = _rgba(source)
        geometry = _visible_geometry(image, threshold)
        if geometry is None:
            errors.append(f"{source.name}: no visible pixels")
            continue
        left, top, right, bottom = geometry.box
        margins = [left, top, image.width - right, image.height - bottom]
        if min(margins) == 0:
            warnings.append(f"{source.name}: visible pixels touch the source canvas edge")
        rule = _icon_rule(spec, source.name)
        item: dict[str, Any] = {
                "name": source.name,
                "sourceSize": [image.width, image.height],
                "kind": rule["kind"],
                "targetCanvas": rule["canvas"],
                "visibleBounds": list(geometry.box),
                "visibleAreaRatio": round(geometry.visible_pixels / (image.width * image.height), 5),
                "sourceMargins": margins,
            }
        generated = _path(spec["icons"]["output"]) / source.name
        if generated.exists():
            generated_image = _rgba(generated)
            generated_geometry = _visible_geometry(generated_image, threshold)
            if generated_geometry is not None:
                gl, gt, gr, gb = generated_geometry.box
                item["generatedMargins"] = [
                    gl,
                    gt,
                    generated_image.width - gr,
                    generated_image.height - gb,
                ]
        icons.append(item)

    expected_icons = set(spec["icons"].get("overrides", {}))
    missing_overrides = expected_icons - {item["name"] for item in icons}
    errors.extend(f"Missing icon declared by manifest: {name}" for name in sorted(missing_overrides))

    paper_source = _path(spec["papers"]["source"])
    declared_papers = set(spec["papers"]["items"])
    actual_papers = {path.name for path in paper_source.glob("*.png")}
    errors.extend(f"Unspecified paper asset: {name}" for name in sorted(actual_papers - declared_papers))
    errors.extend(f"Missing paper asset: {name}" for name in sorted(declared_papers - actual_papers))
    for name, rule in spec["papers"]["items"].items():
        source = paper_source / name
        if not source.exists():
            continue
        image = _rgba(source)
        render_size = tuple(map(int, rule["renderSize"]))
        item = {
                "name": name,
                "sourceSize": [image.width, image.height],
                "renderSize": list(render_size),
                "strokeClass": rule["strokeClass"],
                "screenStroke": measure_paper_edges(image, render_size),
                "normalized": rule.get("normalize", True),
            }
        generated = _path(spec["papers"]["output"]) / name
        if generated.exists():
            item["generatedScreenStroke"] = measure_paper_edges(
                _rgba(generated), render_size
            )
        papers.append(item)

    report = {
        "schemaVersion": 1,
        "paperMode": spec["papers"].get("mode", "audit-only"),
        "icons": icons,
        "papers": papers,
        "warnings": warnings,
        "errors": errors,
    }
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Audit: {len(icons)} icons, {len(papers)} papers, {len(warnings)} warnings, {len(errors)} errors")
    print(f"Report: {REPORT_PATH}")
    for message in warnings:
        print(f"[warning] {message}")
    for message in errors:
        print(f"[error] {message}", file=sys.stderr)
    if strict and errors:
        raise SystemExit(1)
    return report


def contact_sheet(spec: dict[str, Any], *, prefer_generated: bool) -> Path:
    generated_root = _path(spec["icons"]["output"])
    source_root = _path(spec["icons"]["source"])
    root = generated_root if prefer_generated and generated_root.exists() else source_root
    files = sorted(root.glob("*.png"))
    cell_width, cell_height, columns = 180, 190, 6
    rows = max(1, (len(files) + columns - 1) // columns)
    sheet = Image.new("RGB", (cell_width * columns, cell_height * rows), "#d9cfca")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, path in enumerate(files):
        image = _rgba(path)
        image.thumbnail((128, 128), Image.Resampling.LANCZOS)
        x = (index % columns) * cell_width
        y = (index // columns) * cell_height
        tile = Image.new("RGBA", (cell_width, cell_height), (255, 248, 243, 255))
        tile.alpha_composite(image, ((cell_width - image.width) // 2, 10 + (128 - image.height) // 2))
        sheet.paste(tile.convert("RGB"), (x, y))
        draw.text((x + 8, y + 150), path.name, fill="#3b3032", font=font)
    CONTACT_SHEET_PATH.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT_SHEET_PATH, optimize=True)
    print(f"Contact sheet: {CONTACT_SHEET_PATH}")
    return CONTACT_SHEET_PATH


def paper_contact_sheet(spec: dict[str, Any]) -> Path:
    """Write a compact source/preview comparison for every paper surface."""
    source_root = _path(spec["papers"]["source"])
    generated_root = _path(spec["papers"]["output"])
    names = list(spec["papers"]["items"])
    row_height, label_width, preview_width = 150, 220, 330
    sheet = Image.new(
        "RGB",
        (label_width + preview_width * 2, row_height * len(names) + 42),
        "#d9cfca",
    )
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    draw.text((label_width + 105, 14), "source", fill="#3b3032", font=font)
    draw.text(
        (label_width + preview_width + 105, 14),
        "safe preview (edge preserved)",
        fill="#3b3032",
        font=font,
    )
    for index, name in enumerate(names):
        y = 42 + index * row_height
        draw.rectangle(
            (0, y, sheet.width, y + row_height - 1),
            fill="#fff8f3" if index % 2 == 0 else "#f2e9e4",
        )
        draw.text((10, y + 12), name, fill="#3b3032", font=font)
        for column, root in enumerate((source_root, generated_root)):
            path = root / name
            if not path.exists():
                continue
            image = _rgba(path)
            image.thumbnail((preview_width - 24, row_height - 24), Image.Resampling.LANCZOS)
            x = label_width + column * preview_width + (preview_width - image.width) // 2
            image_y = y + (row_height - image.height) // 2
            sheet.paste(image, (x, image_y), image)
    PAPER_CONTACT_SHEET_PATH.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(PAPER_CONTACT_SHEET_PATH, optimize=True)
    print(f"Paper contact sheet: {PAPER_CONTACT_SHEET_PATH}")
    return PAPER_CONTACT_SHEET_PATH


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("audit", "generate", "contact-sheet", "all"), nargs="?", default="audit")
    parser.add_argument("--spec", type=Path, default=DEFAULT_SPEC)
    parser.add_argument("--strict", action="store_true", help="Fail when manifest coverage errors are found")
    args = parser.parse_args()
    spec = _load_spec(args.spec.resolve())
    if args.command in ("generate", "all"):
        generated = generate(spec)
        print(f"Generated {len(generated)} preview assets (shipping assets were not modified)")
    if args.command in ("audit", "all"):
        audit(spec, strict=args.strict)
    if args.command in ("contact-sheet", "all"):
        contact_sheet(spec, prefer_generated=args.command == "all")
        paper_contact_sheet(spec)


if __name__ == "__main__":
    main()
