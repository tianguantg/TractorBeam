$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$repoRoot = Split-Path -Parent $PSScriptRoot
$crateRoot = Join-Path $repoRoot 'crates/flutter-bridge'
$dartOutput = Join-Path $repoRoot 'apps/tractor-beam-flutter/lib/bridge/generated'
$cOutput = Join-Path $repoRoot 'apps/tractor-beam-flutter/windows/runner/frb_generated.h'
# FRB 2.13 canonicalizes the crate root to the Windows extended-path form.
# Supplying the Rust output in the same form avoids a false path mismatch.
$rustOutput = "\\?\$crateRoot\src\frb_generated.rs"

Push-Location $crateRoot
try {
  # FRB and the normalization pass below shell out to rustfmt resolved through
  # this crate's pinned toolchain; minimal CI images lack its rustfmt component.
  rustup component add rustfmt
  flutter_rust_bridge_codegen generate `
    --rust-input crate::api `
    --rust-root . `
    --rust-output $rustOutput `
    --dart-output $dartOutput `
    --c-output $cOutput `
    --stop-on-error
  # FRB emits valid Rust with its own import ordering. Normalize the generated
  # Rust with the workspace toolchain so `cargo fmt --check` and regeneration
  # consistency use the same canonical output.
  rustfmt --edition 2024 $rustOutput
} finally {
  Pop-Location
}
