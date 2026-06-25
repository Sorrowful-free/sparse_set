#Requires -Version 5.1
<#
.SYNOPSIS
  Сравнивает median PGDECS vs GECS по multirun-логам.

.EXAMPLE
  .\compare_frameworks.ps1 -PgdecsDirectory ..\..\pgdecs\ecs\tests\reports\multirun_post_transition -GecsDirectory multirun_gecs -Markdown
#>
[CmdletBinding()]
param(
	[string] $PgdecsDirectory,

	[string] $GecsDirectory,

	[int] $Iterations = 25000,

	[switch] $Markdown
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$aggregateScript = Join-Path $PSScriptRoot "..\..\..\pgdecs\ecs\tests\reports\aggregate_multirun.ps1"

function Get-Summary {
	param(
		[string] $Dir,
		[string] $Framework
	)
	& $aggregateScript -Directory $Dir -Iterations $Iterations -Framework $Framework 2>&1 | Out-Null
	# Re-parse via dot-sourcing helper logic — invoke Read-MultirunLogs through nested script block
	$header = if ($Framework -eq "GECS") {
		"--- GECS Performance (iterations=$Iterations) ---"
	} else {
		"--- ECS Performance (iterations=$Iterations) ---"
	}
	$resolved = Resolve-Path -LiteralPath $Dir
	$logs = Get-ChildItem -LiteralPath $resolved -Filter "run_*.log" | Sort-Object Name
	$byBenchmark = @{}
	foreach ($log in $logs) {
		$text = Get-Content -LiteralPath $log.FullName -Raw
		$idx = $text.IndexOf($header)
		if ($idx -lt 0) { continue }
		$rest = $text.Substring($idx + $header.Length)
		$end = $rest.IndexOf("---")
		if ($end -ge 0) { $rest = $rest.Substring(0, $end) }
		foreach ($line in ($rest -split "`n")) {
			$m = [regex]::Match($line.TrimEnd(), '^\s{2}(.+?):\s+([0-9.]+)\s+s\s*$')
			if (-not $m.Success) { continue }
			$name = $m.Groups[1].Value
			$value = [double]$m.Groups[2].Value
			if (-not $byBenchmark.ContainsKey($name)) {
				$byBenchmark[$name] = [System.Collections.Generic.List[double]]::new()
			}
			$byBenchmark[$name].Add($value)
		}
	}
	function Get-Median([double[]] $Values) {
		if ($Values.Count -eq 0) { return [double]::NaN }
		$sorted = $Values | Sort-Object
		$n = $sorted.Count
		if ($n % 2 -eq 1) { return $sorted[[int](($n - 1) / 2)] }
		return ($sorted[$n / 2 - 1] + $sorted[$n / 2]) / 2.0
	}
	$rows = @{}
	foreach ($name in $byBenchmark.Keys) {
		$vals = $byBenchmark[$name].ToArray()
		$rows[$name] = Get-Median -Values $vals
	}
	return $rows
}

$pgdecs = Get-Summary -Dir $PgdecsDirectory -Framework "ECS"
$gecs = Get-Summary -Dir $GecsDirectory -Framework "GECS"

$aliases = @{
	"system change_detection scattered OFF" = "system process scattered"
	"system change_detection hot-chunks OFF" = "system process hot-chunks"
}

# Новые имена метрик + legacy из старых логов (до пометок slow/fast path).
$metricAliases = @{
	"query iterate entities+components [slot API]" = @(
		"query iterate entities+components [slot API]",
		"query iterate entities+components"
	)
	"query iterate entities+components FAST [dense_slots+buffers]" = @(
		"query iterate entities+components FAST [dense_slots+buffers]",
		"query iterate entities+components FAST"
	)
	"query iterate entities+components [column iterate]" = @(
		"query iterate entities+components [column iterate]",
		"query iterate entities+components"
	)
}

function Get-MetricValue {
	param(
		[hashtable] $Rows,
		[string] $Name
	)
	if ($metricAliases.ContainsKey($Name)) {
		foreach ($candidate in $metricAliases[$Name]) {
			if ($Rows.ContainsKey($candidate)) {
				return $Rows[$candidate]
			}
		}
	}
	if ($Rows.ContainsKey($Name)) {
		return $Rows[$Name]
	}
	return [double]::NaN
}

$fairPairs = @(
	@{
		Label = "Fair: PGDECS FAST vs GECS column iterate"
		Pgdecs = "query iterate entities+components FAST [dense_slots+buffers]"
		Gecs = "query iterate entities+components [column iterate]"
	},
	@{
		Label = "Unfair: PGDECS slot API vs GECS column iterate"
		Pgdecs = "query iterate entities+components [slot API]"
		Gecs = "query iterate entities+components [column iterate]"
	}
)

$allNames = [System.Collections.Generic.HashSet[string]]::new()
foreach ($k in $pgdecs.Keys) { [void]$allNames.Add($k) }
foreach ($k in $gecs.Keys) { [void]$allNames.Add($k) }

function Format-Sec([double] $s) {
	if ([double]::IsNaN($s)) { return "n/a" }
	return "{0:F3}" -f $s
}

function Format-Ratio([double] $Pgdecs, [double] $Gecs) {
	if ([double]::IsNaN($Pgdecs) -or [double]::IsNaN($Gecs) -or $Gecs -eq 0.0) { return "n/a" }
	return "{0:F2}x" -f ($Pgdecs / $Gecs)
}

Write-Host ""
Write-Host "PGDECS: $PgdecsDirectory"
Write-Host "GECS:   $GecsDirectory"
Write-Host "iterations=$Iterations"
Write-Host ""

if ($Markdown) {
	Write-Host '| Benchmark | PGDECS med | GECS med | PGDECS/GECS |'
	Write-Host '|---|---:|---:|---:|'
}
else {
	Write-Host ("{0,-48} {1,10} {2,10} {3,10}" -f "Benchmark", "PGDECS", "GECS", "ratio")
}

foreach ($name in ($allNames | Sort-Object)) {
	$pVal = Get-MetricValue -Rows $pgdecs -Name $name
	$gName = if ($aliases.ContainsKey($name)) { $aliases[$name] } else { $name }
	$gVal = Get-MetricValue -Rows $gecs -Name $gName
	if ([double]::IsNaN($gVal)) {
		$gVal = Get-MetricValue -Rows $gecs -Name $name
	}
	if ($Markdown) {
		Write-Host ("| {0} | {1} | {2} | {3} |" -f $name, (Format-Sec $pVal), (Format-Sec $gVal), (Format-Ratio $pVal $gVal))
	}
	else {
		Write-Host ("{0,-48} {1,10} {2,10} {3,10}" -f $name, (Format-Sec $pVal), (Format-Sec $gVal), (Format-Ratio $pVal $gVal))
	}
}

Write-Host ""
Write-Host "--- Fair / unfair iteration pairs ---"
foreach ($pair in $fairPairs) {
	$pVal = Get-MetricValue -Rows $pgdecs -Name $pair.Pgdecs
	$gVal = Get-MetricValue -Rows $gecs -Name $pair.Gecs
	$note = if ([double]::IsNaN($pVal) -or [double]::IsNaN($gVal)) {
		"n/a"
	} elseif ($pVal -lt $gVal) {
		"PGDECS {0:F2}x faster" -f ($gVal / $pVal)
	} elseif ($gVal -lt $pVal) {
		"GECS {0:F2}x faster" -f ($pVal / $gVal)
	} else {
		"tie"
	}
	Write-Host ("  {0}" -f $pair.Label)
	Write-Host ("    PGDECS {0}  |  GECS {1}  ->  {2}" -f (Format-Sec $pVal), (Format-Sec $gVal), $note)
}
