param(
  [switch]$Run
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$repoRoot = Split-Path -Parent $PSScriptRoot
$flutterRoot = Join-Path $repoRoot 'apps/tractor-beam-flutter'
$debugRoot = Join-Path $flutterRoot 'build/windows/x64/runner/Debug'
$nativeRoot = Join-Path $repoRoot 'target/i686-pc-windows-msvc/debug'

Push-Location $repoRoot
try {
  rustup target add i686-pc-windows-msvc
  cargo build --locked -p tractor-beam-isaac-injector --target i686-pc-windows-msvc
  cargo build --locked -p tractor-beam-native-hook --target i686-pc-windows-msvc
} finally {
  Pop-Location
}

Push-Location $flutterRoot
try {
  flutter pub get
  flutter build windows --debug
} finally {
  Pop-Location
}

Copy-Item -LiteralPath (Join-Path $nativeRoot 'tractor-beam-isaac-injector.exe') -Destination $debugRoot -Force
Copy-Item -LiteralPath (Join-Path $nativeRoot 'tractor_beam_native_hook.dll') -Destination $debugRoot -Force

$required = @(
  'tractor_beam_flutter.exe',
  'tractor_beam_flutter_bridge.dll',
  'tractor-beam-isaac-injector.exe',
  'tractor_beam_native_hook.dll'
)
foreach ($name in $required) {
  if (-not (Test-Path -LiteralPath (Join-Path $debugRoot $name))) {
    throw "Flutter debug bundle is missing $name"
  }
}

if ($Run) {
  Push-Location $flutterRoot
  try {
    flutter run -d windows
  } finally {
    Pop-Location
  }
} else {
  Write-Output (Join-Path $debugRoot 'tractor_beam_flutter.exe')
}
