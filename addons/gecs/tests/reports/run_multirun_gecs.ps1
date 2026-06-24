#Requires -Version 5.1
param(
	[int] $Runs = 5,
	[string] $Godot = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")
$outDir = Join-Path $PSScriptRoot "multirun_gecs"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

if (-not (Test-Path -LiteralPath $Godot)) {
	throw "Godot not found: $Godot"
}

$scene = "res://addons/gecs/tests/run_gecs_multirun_once_headless.tscn"

Write-Host "GECS multirun: $Runs x iterations=25000"
Write-Host "Output: $outDir"
Write-Host ""

for ($i = 1; $i -le $Runs; $i++) {
	$log = Join-Path $outDir ("run_{0}.log" -f $i)
	Write-Host "Run $i/$Runs -> $log"
	& $Godot --headless --path $repoRoot --main-scene $scene 2>&1 | Tee-Object -FilePath $log | Out-Null
}

Write-Host ""
Write-Host "Aggregating..."
& (Join-Path $PSScriptRoot "aggregate_multirun.ps1") -Directory multirun_gecs -Markdown
