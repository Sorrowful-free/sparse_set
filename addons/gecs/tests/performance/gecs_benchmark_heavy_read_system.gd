extends "res://addons/gecs/ecs/system.gd"

const BenchPosition := preload("res://addons/gecs/tests/performance/bench_components/bench_position.gd")
const BenchHealth := preload("res://addons/gecs/tests/performance/bench_components/bench_health.gd")

var processed_archetypes: int = 0
var acc: float = 0.0

func query():
	return q.with_all([BenchPosition, BenchHealth]).iterate([BenchPosition, BenchHealth])

func process(entities: Array[Entity], components: Array, _delta: float) -> void:
	processed_archetypes += 1
	var positions: Array = components[0]
	var healths: Array = components[1]
	for i in range(entities.size()):
		var pos = positions[i]
		var health = healths[i]
		if pos == null || health == null:
			continue
		acc += pos.position.x + pos.position.y + float(health.amount)
