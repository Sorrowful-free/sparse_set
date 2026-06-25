extends SceneTree

## Сравнение WTP-политик: AUTO cpt=8 vs AUTO cpt=256 (main-fallback) vs for_each_chunk main.

const _Benchmark := preload("res://addons/pgdecs/ecs/tests/performance/ecs_benchmark.gd")

func _initialize() -> void:
	var iterations: int = 25000
	var chunk_count: int = ceili(float(iterations) / float(ECSEntityIdsUtils.CHUNK_SIZE))
	print("=== WTP policy compare (iterations=%d, ~%d chunks) ===" % [iterations, chunk_count])
	print("")
	var rows: Array[Dictionary] = []
	_add_row(rows, "for_each_chunk main (Callable baseline)", _run(iterations, "for_each_main"))
	_add_row(rows, "begin_chunk_run main (no Callable)", _run(iterations, "begin_chunk_run_main"))
	_add_row(rows, "dispatch AUTO cpt=8 (WTP)", _run(iterations, "wtp_auto"))
	_add_row(rows, "dispatch AUTO cpt=256 (main-fallback)", _run(iterations, "wtp_main_fallback"))
	_add_row(rows, "chunk-count dispatch AUTO cpt=8", _run(iterations, "chunk_wtp_auto"))
	_add_row(rows, "chunk-count dispatch AUTO cpt=256", _run(iterations, "chunk_wtp_main_fallback"))
	print("")
	print("--- Summary (e+c slot API, fresh world per row) ---")
	var baseline: float = rows[0]["seconds"]
	for row: Dictionary in rows:
		var ratio: String = "baseline" if row["label"] == rows[0]["label"] else "%.2fx vs baseline" % (row["seconds"] / baseline)
		print("  %s: %.3f s  (%s)" % [row["label"], row["seconds"], ratio])
	var auto8: float = rows[1]["seconds"]
	var main_fb: float = rows[2]["seconds"]
	print("")
	print("  main-fallback vs AUTO cpt=8 (e+c): %.2fx (%s)" % [
		main_fb / auto8,
		"faster" if main_fb < auto8 else "slower"
	])
	print("--- Done ---")
	quit()

func _run(iterations: int, kind: String) -> float:
	var bench: ECSBenchmark = ECSBenchmark.new(ECSManager.new(), iterations)
	match kind:
		"for_each_main":
			return bench.benchmark_query_iterate_entities_with_components_for_each_chunk_main()
		"begin_chunk_run_main":
			return bench.benchmark_query_iterate_entities_with_components_begin_chunk_run()
		"wtp_auto":
			return bench.benchmark_query_iterate_entities_with_components_worker_pool()
		"wtp_main_fallback":
			return bench.benchmark_query_iterate_entities_with_components_worker_pool_main_fallback()
		"chunk_wtp_auto":
			return bench.benchmark_query_worker_pool()
		"chunk_wtp_main_fallback":
			return bench.benchmark_query_worker_pool_main_fallback()
	return 0.0

func _add_row(rows: Array[Dictionary], label: String, seconds: float) -> void:
	rows.append({"label": label, "seconds": seconds})
	print("  %s: %.3f s" % [label, seconds])
