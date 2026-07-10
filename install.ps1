param(
    [string]$Target = "$env:APPDATA\mpv"
)

$ErrorActionPreference = "Stop"
$Source = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Installing mpv settings..."
Write-Host "Source: $Source"
Write-Host "Target: $Target"

if (-not (Test-Path $Target)) {
    New-Item -ItemType Directory -Path $Target | Out-Null
}

$items = @(
    "mpv.conf",
    "input.conf",
    "script-opts",
    "scripts",
    "shaders",
    "fonts"
)

foreach ($item in $items) {
    $src = Join-Path $Source $item
    $dst = Join-Path $Target $item
    if (Test-Path $src) {
        if (Test-Path $dst) {
            Remove-Item $dst -Recurse -Force
        }
        Copy-Item $src $dst -Recurse -Force
    }
}

Write-Host "Done. Restart mpv to apply changes."
Write-Host "Note: Large CJK fonts are not bundled. See README.md for Resource Han Rounded font installation."
