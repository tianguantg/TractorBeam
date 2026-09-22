# TractorBeam Flutter client

Windows x64 Flutter front end for TractorBeam. Rust remains the only owner of
application, room, session, Hook, configuration, diagnostic, and log state;
Flutter owns presentation-only state such as form drafts, filters, pagination,
and animation controllers.

This client is maintained in the
[tianguantg/TractorBeam](https://github.com/tianguantg/TractorBeam) fork of the
[official upstream project](https://github.com/mcthesw/TractorBeam). Code is
licensed under AGPL-3.0-or-later; asset-specific notices and redistribution
requirements are documented in the repository root
[`THIRD_PARTY_NOTICES.md`](../../THIRD_PARTY_NOTICES.md).

## Pinned toolchain

- Rust 1.97.0 (from the workspace `rust-toolchain.toml`)
- Flutter 3.41.6 / Dart 3.11.4
- flutter_rust_bridge 2.13.0

## Develop and test

From this directory:

```powershell
flutter pub get
flutter analyze
flutter test
```

Because Isaac and its Native Hook are 32-bit, the Windows CMake build
automatically builds the i686 Injector and Hook and places them beside the x64
Flutter executable. A normal `flutter run -d windows` is therefore runnable.
The repository helper remains available for a clean end-to-end debug build:

```powershell
./scripts/build_flutter_windows_debug.ps1 -Run
```

Native Assets builds `crates/flutter-bridge` automatically. After changing its
public API, regenerate both sides from the repository root:

```powershell
./scripts/generate_flutter_bridge.ps1
```

## Windows release

From the repository root:

```powershell
./scripts/package_flutter_windows.ps1
```

The script tests the Flutter application, builds its x64 runner and FFI DLL,
builds the i686 Injector and Native Hook, validates the bundle, and writes
`dist/TractorBeam-Client-Flutter-Windows-x86_64.zip`. The bundle has its own
`config.toml` and does not migrate or reuse the egui client's configuration.

The Flutter release intentionally does not perform update checks while upstream
releases only contain the egui client. Never add session credentials, resume
keys, connection IDs, or path tokens to bridge DTOs, logs, or diagnostics.

## PNG asset normalization

PNG asset rules live in `tool/asset_specs.json`. The pipeline is deliberately
non-destructive: it reads the shipping assets and writes normalized previews,
an audit report, and a visual contact sheet below `build/normalized_assets/`.

```powershell
python tool/asset_pipeline.py all --strict
```

Review `build/normalized_assets/contact_sheet.png`,
`build/normalized_assets/paper_contact_sheet.png`, and the Flutter goldens before
copying any generated preview into `assets/`. Paper assets are measured at their
actual fixed-board render size, while icons use alpha-aware optical centering.
The source alpha silhouette is retained for paper cards so torn edges and shadow
geometry are not changed by border normalization.

Paper generation is intentionally `audit-only`. Torn fibres, ink antialiasing,
and semi-transparent shadows overlap in these raster sources; automatic
threshold/inpainting rewrites create visible bands. The audit identifies stroke
outliers, but a paper edge is only changed after a reviewed per-asset mask (or a
new source export) is available. Icon normalization remains fully automatic.
