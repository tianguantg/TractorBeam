param(
  [Parameter(Mandatory = $true)]
  [string]$Configuration,
  [Parameter(Mandatory = $true)]
  [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$repoRoot = Split-Path -Parent $PSScriptRoot
$targetTriple = 'i686-pc-windows-msvc'
$cargoProfile = if ($Configuration -eq 'Debug') { 'debug' } else { 'release' }
$cargoArguments = @(
  'build',
  '--locked',
  '-p', 'tractor-beam-isaac-injector',
  '-p', 'tractor-beam-native-hook',
  '--target', $targetTriple
)
if ($cargoProfile -eq 'release') {
  $cargoArguments += '--release'
}

Push-Location $repoRoot
try {
  & rustup target add $targetTriple
  & cargo @cargoArguments
} finally {
  Pop-Location
}

$nativeRoot = Join-Path $repoRoot "target/$targetTriple/$cargoProfile"
$components = @(
  'tractor-beam-isaac-injector.exe',
  'tractor_beam_native_hook.dll'
)

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
foreach ($component in $components) {
  $source = Join-Path $nativeRoot $component
  if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Injection component was not produced: $source"
  }
  Copy-Item -LiteralPath $source -Destination (Join-Path $OutputDirectory $component) -Force
}
