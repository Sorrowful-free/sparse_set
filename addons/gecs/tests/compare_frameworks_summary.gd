extends RefCounted
class_name CompareFrameworksSummary

const _MetricNames := preload("res://addons/gecs/tests/compare_metric_names.gd")

static func print_summary(pgdecs: Dictionary, gecs: Dictionary, iterations: int) -> void:
	print("")
	print("--- Compare summary (iterations=%d) ---" % iterations)
	var chunk_count: int = ceili(float(iterations) / float(ECSEntityIdsUtils.CHUNK_SIZE))
	print("  WTP granularity: PGDECS ~%d archetype-chunks, GECS ~1 archetype (homogeneous world)" % chunk_count)
	print("")
	_print_pair(
		"Fair: fast-path iteration (PGDECS dense_slots+buffers vs GECS column iterate)",
		_lookup(pgdecs, _MetricNames.QUERY_E_C_FAST, "query iterate entities+components FAST"),
		_lookup(gecs, _MetricNames.QUERY_E_C_COLUMN, "query iterate entities+components")
	)
	_print_pair(
		"Unfair: PGDECS slot API vs GECS column iterate (do not compare as equals)",
		_lookup(pgdecs, _MetricNames.QUERY_E_C_SLOT, "query iterate entities+components"),
		_lookup(gecs, _MetricNames.QUERY_E_C_COLUMN, "query iterate entities+components")
	)
	_print_pair(
		"WorkerThreadPool e+c (overhead dominates; PGDECS ~%d tasks/run)" % chunk_count,
		_lookup(pgdecs, _MetricNames.QUERY_E_C_WTP),
		_lookup(gecs, _MetricNames.QUERY_E_C_WTP)
	)
	_print_pair(
		"WorkerThreadPool chunk count only",
		_lookup(pgdecs, _MetricNames.QUERY_CHUNKS_WTP),
		_lookup(gecs, _MetricNames.QUERY_CHUNKS_WTP)
	)

static func _lookup(results: Dictionary, primary: String, legacy: String = "") -> float:
	if results.has(primary):
		return float(results[primary])
	if not legacy.is_empty() and results.has(legacy):
		return float(results[legacy])
	return -1.0

static func _print_pair(label: String, pgdecs_s: float, gecs_s: float) -> void:
	print("  %s" % label)
	if pgdecs_s < 0.0 or gecs_s < 0.0:
		print("    (missing metrics)")
		return
	var ratio: float = pgdecs_s / gecs_s if gecs_s > 0.0 else 0.0
	var winner: String
	if absf(pgdecs_s - gecs_s) < 0.0005:
		winner = "tie (~same)"
	elif pgdecs_s < gecs_s:
		winner = "PGDECS %.2fx faster" % (gecs_s / pgdecs_s)
	else:
		winner = "GECS %.2fx faster" % ratio
	print("    PGDECS %.3f s  |  GECS %.3f s  →  %s" % [pgdecs_s, gecs_s, winner])
