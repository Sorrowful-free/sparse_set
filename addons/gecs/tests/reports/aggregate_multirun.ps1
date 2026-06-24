#Requires -Version 5.1
<#
.SYNOPSIS
  Агрегирует multirun perf-логи GECS (median / min / max по run_*.log).
#>
[CmdletBinding()]
param(
	[Parameter(Position = 0)]
	[string] $Directory = ".",

	[int] $Iterations = 25000,

	[string] $CompareDirectory = "",

	[switch] $Markdown
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$aggregateScript = Join-Path $PSScriptRoot "..\..\..\pgdecs\ecs\tests\reports\aggregate_multirun.ps1"
if (-not (Test-Path -LiteralPath $aggregateScript)) {
	throw "Missing aggregate script: $aggregateScript"
}

$params = @{
	Directory   = $Directory
	Iterations  = $Iterations
	Framework   = "GECS"
}
if ($CompareDirectory -ne "") {
	$params.CompareDirectory = $CompareDirectory
}
if ($Markdown) {
	$params.Markdown = $true
}

& $aggregateScript @params
