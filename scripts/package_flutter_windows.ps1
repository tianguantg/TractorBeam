param(
  [string]$Version = '0.5.2',
  [int]$BuildNumber = 2,
  [string]$ReleaseVersion = '0.5.2-tb.2'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:TB_RELEASE_VERSION = $ReleaseVersion
$repoRoot = Split-Path -Parent $PSScriptRoot
$flutterRoot = Join-Path $repoRoot 'apps/tractor-beam-flutter'
$releaseRoot = Join-Path $flutterRoot 'build/windows/x64/runner/Release'
$bundleRoot = Join-Path $repoRoot 'dist/TractorBeamFlutter'
$archive = Join-Path $repoRoot 'dist/TractorBeam-Client-Flutter-Windows-x86_64.zip'
$repoPrefix = [System.IO.Path]::GetFullPath($repoRoot).TrimEnd('\') + '\'
$bundleFullPath = [System.IO.Path]::GetFullPath($bundleRoot)
if (-not $bundleFullPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Refusing to replace bundle outside the repository: $bundleFullPath"
}

Push-Location $flutterRoot
try {
  if (Test-Path -LiteralPath (Join-Path $flutterRoot 'build/flutter_assets')) {
    Remove-Item -LiteralPath (Join-Path $flutterRoot 'build/flutter_assets') -Recurse -Force
  }
  if (Test-Path -LiteralPath (Join-Path $flutterRoot 'build/windows/x64/runner/Release')) {
    Remove-Item -LiteralPath (Join-Path $flutterRoot 'build/windows/x64/runner/Release') -Recurse -Force
  }
  flutter pub get
  flutter analyze
  flutter test
  $debugSymbols = Join-Path $flutterRoot 'build/debug_symbols'
  if (Test-Path -LiteralPath $debugSymbols) {
    Remove-Item -LiteralPath $debugSymbols -Recurse -Force
  }
  flutter build windows --release --build-name $Version --build-number $BuildNumber --split-debug-info=$debugSymbols --tree-shake-icons
} finally {
  Pop-Location
}

Push-Location $repoRoot
try {
  rustup target add i686-pc-windows-msvc
  cargo build --locked --release -p tractor-beam-isaac-injector --target i686-pc-windows-msvc
  cargo build --locked --release -p tractor-beam-native-hook --target i686-pc-windows-msvc
} finally {
  Pop-Location
}

if (Test-Path -LiteralPath $bundleRoot) {
  Remove-Item -LiteralPath $bundleRoot -Recurse -Force
}
if (Test-Path -LiteralPath $archive) {
  Remove-Item -LiteralPath $archive -Force
}
New-Item -ItemType Directory -Force $bundleRoot | Out-Null
Copy-Item (Join-Path $releaseRoot '*') $bundleRoot -Recurse
if (Test-Path -LiteralPath (Join-Path $bundleRoot 'logs')) {
  Remove-Item -LiteralPath (Join-Path $bundleRoot 'logs') -Recurse -Force
}
if (Test-Path -LiteralPath (Join-Path $bundleRoot 'room_history.dat')) {
  Remove-Item -LiteralPath (Join-Path $bundleRoot 'room_history.dat') -Force
}
Copy-Item (Join-Path $repoRoot 'target/i686-pc-windows-msvc/release/tractor-beam-isaac-injector.exe') $bundleRoot
Copy-Item (Join-Path $repoRoot 'target/i686-pc-windows-msvc/release/tractor_beam_native_hook.dll') $bundleRoot
Copy-Item (Join-Path $repoRoot 'deploy/client.config.toml') (Join-Path $bundleRoot 'config.toml')
Copy-Item (Join-Path $repoRoot 'LICENSE') $bundleRoot
if (Test-Path -LiteralPath (Join-Path $repoRoot 'LICENSES')) {
  Copy-Item (Join-Path $repoRoot 'LICENSES') $bundleRoot -Recurse
}
Copy-Item (Join-Path $repoRoot 'THIRD_PARTY_NOTICES.md') $bundleRoot

$required = @(
  'config.toml',
  'data/flutter_assets/AssetManifest.bin',
  'data/flutter_assets/NativeAssetsManifest.json',
  'flutter_windows.dll',
  'LICENSE',
  'THIRD_PARTY_NOTICES.md',
  'tractor-beam-isaac-injector.exe',
  'tractor_beam_flutter.exe',
  'tractor_beam_flutter_bridge.dll',
  'tractor_beam_native_hook.dll'
)
foreach ($relative in $required) {
  if (-not (Test-Path -LiteralPath (Join-Path $bundleRoot $relative))) {
    throw "Flutter Client bundle is missing $relative"
  }
}
if (Test-Path -LiteralPath $archive) {
  Remove-Item -LiteralPath $archive -Force
}
$sevenZip = Get-Command 7z.exe -ErrorAction SilentlyContinue
if ($sevenZip) {
  & $sevenZip.Source a -tzip -mx=9 $archive (Join-Path $bundleRoot '*') | Out-Null
} else {
  Compress-Archive -Path (Join-Path $bundleRoot '*') -DestinationPath $archive
}
Write-Output $archive
