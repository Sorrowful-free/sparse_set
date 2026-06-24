#Requires -Version 5.1
<#
.SYNOPSIS
  Агрегирует multirun perf-логи Godot (median / min / max по run_*.log).

.DESCRIPTION
  Парсит блок "--- ECS Performance (iterations=N) ---" и строки "  name: 0.123 s".
  По умолчанию берёт iterations=25000 и все run_*.log в указанной папке.

.EXAMPLE
  .\aggregate_multirun.ps1 -Directory multirun_foreach_rerun

.EXAMPLE
  .\aggregate_multirun.ps1 -Directory multirun_coalesce_bench -Markdown

.EXAMPLE
  .\aggregate_multirun.ps1 -Directory multirun_foreach_rerun -CompareDirectory multirun_rerun -Markdown
#>
[CmdletBinding()]
param(
	[Parameter(Position = 0)]
	[string] $Directory = ".",

	[int] $Iterations = 25000,

	[string] $CompareDirectory = "",

	[ValidateSet("ECS", "GECS")]
	[string] $Framework = "ECS",

	[switch] $Markdown
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-Median {
	param([double[]] $Values)
	if ($Values.Count -eq 0) {
		return [double]::NaN
	}
	$sorted = $Values | Sort-Object
	$n = $sorted.Count
	if ($n % 2 -eq 1) {
		return $sorted[[int](($n - 1) / 2)]
	}
	return ($sorted[$n / 2 - 1] + $sorted[$n / 2]) / 2.0
}

function Format-Seconds {
	param([double] $Seconds)
	if ([double]::IsNaN($Seconds)) {
		return "n/a"
	}
	return "{0:F3}" -f $Seconds
}

function Format-DeltaPercent {
	param(
		[double] $Current,
		[double] $Baseline
	)
	if ([double]::IsNaN($Current) -or [double]::IsNaN($Baseline) -or $Baseline -eq 0.0) {
		return "n/a"
	}
	$pct = (($Current - $Baseline) / $Baseline) * 100.0
	return "{0:+0.0;-0.0;0.0}%" -f $pct
}

function Normalize-BenchmarkName {
	param([string] $Name)
	$aliases = @{
		"query.get_chunks() iterate" = "query.for_each_chunk iterate"
		"query chunks WorkerThreadPool" = "query.for_each_chunk WorkerThreadPool"
	}
	if ($aliases.ContainsKey($Name)) {
		return $aliases[$Name]
	}
	return $Name
}

function Read-MultirunLogs {
	param(
		[string] $Dir,
		[int] $TargetIterations,
		[string] $Framework = "ECS"
	)

	$resolved = Resolve-Path -LiteralPath $Dir
	$logs = Get-ChildItem -LiteralPath $resolved -Filter "run_*.log" | Sort-Object Name
	if ($logs.Count -eq 0) {
		throw "No run_*.log files in $resolved"
	}

	$header = if ($Framework -eq "GECS") {
		"--- GECS Performance (iterations=$TargetIterations) ---"
	} else {
		"--- ECS Performance (iterations=$TargetIterations) ---"
	}
	$byBenchmark = @{}

	foreach ($log in $logs) {
		$text = Get-Content -LiteralPath $log.FullName -Raw
		$idx = $text.IndexOf($header)
		if ($idx -lt 0) {
			Write-Warning "Skip $($log.Name): block '$header' not found"
			continue
		}
		$rest = $text.Substring($idx + $header.Length)
		$end = $rest.IndexOf("---")
		if ($end -ge 0) {
			$rest = $rest.Substring(0, $end)
		}
		foreach ($line in ($rest -split "`n")) {
			$m = [regex]::Match($line.TrimEnd(), '^\s{2}(.+?):\s+([0-9.]+)\s+s\s*$')
			if (-not $m.Success) {
				continue
			}
			$name = Normalize-BenchmarkName -Name $m.Groups[1].Value
			$value = [double]$m.Groups[2].Value
			if (-not $byBenchmark.ContainsKey($name)) {
				$byBenchmark[$name] = [System.Collections.Generic.List[double]]::new()
			}
			$byBenchmark[$name].Add($value)
		}
	}

	$rows = @()
	foreach ($name in ($byBenchmark.Keys | Sort-Object)) {
		$vals = $byBenchmark[$name].ToArray()
		$rows += [PSCustomObject]@{
			Benchmark = $name
			Runs      = $vals.Count
			Min       = ($vals | Measure-Object -Minimum).Minimum
			Median    = Get-Median -Values $vals
			Max       = ($vals | Measure-Object -Maximum).Maximum
		}
	}
	return [PSCustomObject]@{
		Directory = $resolved.Path
		Rows      = $rows
		LogCount  = $logs.Count
	}
}

function Write-Table {
	param(
		$Summary,
		$CompareSummary = $null
	)

	Write-Host ""
	Write-Host "Directory: $($Summary.Directory)"
	Write-Host "Logs: $($Summary.LogCount)  |  iterations=$Iterations"
	Write-Host ""

	if ($Markdown) {
		if ($null -ne $CompareSummary) {
			Write-Host '| Benchmark | Baseline med | Current med | delta med | min | max |'
			Write-Host '|---|---:|---:|---:|---:|---:|'
			$baselineMap = @{}
			foreach ($row in $CompareSummary.Rows) {
				$baselineMap[$row.Benchmark] = $row.Median
			}
			foreach ($row in $Summary.Rows) {
				$baseMed = if ($baselineMap.ContainsKey($row.Benchmark)) { $baselineMap[$row.Benchmark] } else { [double]::NaN }
				$delta = Format-DeltaPercent -Current $row.Median -Baseline $baseMed
				Write-Host ("| {0} | {1} | **{2}** | {3} | {4} | {5} |" -f `
					$row.Benchmark, (Format-Seconds $baseMed), (Format-Seconds $row.Median), $delta, `
					(Format-Seconds $row.Min), (Format-Seconds $row.Max))
			}
		}
		else {
			Write-Host '| Benchmark | runs | min | **med** | max |'
			Write-Host '|---|---:|---:|---:|---:|'
			foreach ($row in $Summary.Rows) {
				Write-Host ("| {0} | {1} | {2} | **{3}** | {4} |" -f `
					$row.Benchmark, $row.Runs, (Format-Seconds $row.Min), (Format-Seconds $row.Median), (Format-Seconds $row.Max))
			}
		}
	}
	else {
		if ($null -ne $CompareSummary) {
			$baselineMap = @{}
			foreach ($row in $CompareSummary.Rows) {
				$baselineMap[$row.Benchmark] = $row.Median
			}
			$display = foreach ($row in $Summary.Rows) {
				$baseMed = if ($baselineMap.ContainsKey($row.Benchmark)) { $baselineMap[$row.Benchmark] } else { [double]::NaN }
				[PSCustomObject]@{
					Benchmark    = $row.Benchmark
					BaselineMed  = Format-Seconds $baseMed
					CurrentMed   = Format-Seconds $row.Median
					DeltaMed     = Format-DeltaPercent -Current $row.Median -Baseline $baseMed
					Min          = Format-Seconds $row.Min
					Max          = Format-Seconds $row.Max
				}
			}
			$display | Format-Table -AutoSize
		}
		else {
			$display = foreach ($row in $Summary.Rows) {
				[PSCustomObject]@{
					Benchmark = $row.Benchmark
					Runs      = $row.Runs
					Min       = Format-Seconds $row.Min
					Median    = Format-Seconds $row.Median
					Max       = Format-Seconds $row.Max
				}
			}
			$display | Format-Table -AutoSize
		}
	}
}

$summary = Read-MultirunLogs -Dir $Directory -TargetIterations $Iterations -Framework $Framework
$compareSummary = $null
if ($CompareDirectory -ne "") {
	$compareSummary = Read-MultirunLogs -Dir $CompareDirectory -TargetIterations $Iterations -Framework $Framework
	Write-Host "Compare baseline: $($compareSummary.Directory)"
}
Write-Table -Summary $summary -CompareSummary $compareSummary
