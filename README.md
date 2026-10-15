# PGDECS

> **Packed Entity-Component-System for Godot 4.x**

A data-oriented ECS in GDScript: entities are stored via a sparse set, components are packed into dense arrays (SoA) grouped by archetypes and chunks. The project grew out of [GECS](https://github.com/csprance/gecs), but was rewritten from scratch — different API, different storage model, different trade-offs.

## Key features

- **Packed storage** — component values live in `Packed*Array` / typed `Array`; iteration runs over dense buffers with no per-entity boxing
- **Archetypes and chunks** — entities are grouped by component set; queries return chunks, not lists of objects
- **Command buffer** — structural changes (spawn/destroy, add/remove components) are deferred and applied in bulk after a system
- **System groups and scheduler** — systems are bound to `_process` / `_physics_process` hooks, frequency (Hz) and `execution_order`
- **Worker Thread Pool** — chunk systems can run in parallel (`use_worker_pool`)
- **Code generation** — typed component arrays for built-in types and Godot nodes are generated from the editor
- **Entity/Scene blueprints** — entity descriptions as resources, entity assembly from marker nodes in a scene
- **Intent pipeline** — lifecycle of external objects (nodes, resources) via intent tags and reference components

## Requirements

Godot 4.x (project on 4.7, Mobile renderer).

## Installation

1. Copy `addons/pgdecs/` into your project.
2. Enable the plugin: **Project → Project Settings → Plugins → PGDEcs**.

The plugin adds a **Project → Tools → PGDECS: Regenerate Components** menu item for regenerating typed component arrays.

## Quick start

Minimal path — `ECSManager` without `ECSWorld`:

```gdscript
var ecs := ECSManager.new()
ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)

var runner := ECSSystemRunner.new()
runner.add_system(MyMovementSystem.new(ecs))

func _process(delta: float) -> void:
	runner.run(delta)
```

A full world with profile, strategies and scheduler:

```gdscript
var world := ECSDemoWorld.new()
add_child(world)      # recommended before bootstrap (visual host)
world.bootstrap(1000) # profile + strategies + spawn
```

A chunk system (the primary way to iterate):

```gdscript
extends ECSSystemChunkBase
class_name MyMovementSystem

func build_query() -> ECSQuery:
	return ECSQueryBuilder.new()\
		.with_component(MyWorld.Component.POSITION)\
		.build(get_ecs_manager())

func process_chunk(chunk: ECSQueryChunk, delta: float) -> void:
	var pos_chunk := chunk.get_component_chunk(
		MyWorld.Component.POSITION
	) as ECSComponentVector2ArrayChunk
	if pos_chunk == null:
		return

	var slots: PackedInt32Array = chunk.get_dense_slots()
	var pos_buf: PackedVector2Array = pos_chunk.get_values_buffer()

	for i: int in range(chunk.get_entity_count()):
		var slot: int = slots[i]
		pos_chunk.set_value_at_slot(slot, pos_buf[slot] + Vector2.RIGHT * delta)
```

> The buffer is indexed by **slot**, not `i` — the most common mistake. Details in [CHEATSHEET.md](addons/pgdecs/CHEATSHEET.md).

## Performance vs GECS

Measured with `addons/gecs/tests/run_compare_frameworks_headless.tscn` — both frameworks on the same machine, `iterations=25000` (query metrics are ×100 runs over a 25k-entity world; median of 5 runs). Full report: [tests/reports/perf_compare_gecs_25000.md](addons/pgdecs/ecs/tests/reports/perf_compare_gecs_25000.md).

Environment: Godot 4.7.2 headless, AMD Ryzen 7 7735HS, Linux.

| Metric | PGDECS | GECS | Result |
|--------|-------:|-----:|--------|
| create_entity ×25000 | 0.162 s | 2.427 s | **PGDECS ~15×** |
| destroy_entity ×25000 | 0.146 s | 0.607 s | **PGDECS ~4.2×** |
| create_entities batch (25k total) | 0.075 s | 2.315 s | **PGDECS ~31×** |
| destroy_entities batch (25k total) | 0.097 s | 0.446 s | **PGDECS ~4.6×** |
| query.get_entity_ids ×100 | 0.068 s | <0.001 s | GECS\* |
| query.for_each_chunk iterate ×100 | 0.010 s | <0.001 s | GECS\* |
| iterate entities+components, fast path ×100 | 0.209 s | 2.411 s | **PGDECS ~11.5×** |
| iterate entities+components, slot API ×100 | 1.887 s | 2.411 s | PGDECS ~1.3× (unfair pair) |
| iterate entities+components, WorkerThreadPool ×100 | 0.017 s | 0.002 s | GECS\* |
| for_each_chunk, WorkerThreadPool ×100 | 0.017 s | 0.002 s | GECS\* |
| add/remove_component ×5000 | 0.126 s | 0.497 s | **PGDECS ~4×** |
| command_buffer execute (1000 creates) | 0.010 s | 0.025 s | **PGDECS ~2.5×** |
| command_buffer coalescing frame | 0.023 s | 0.180 s | **PGDECS ~7.8×** |
| system, change_detection steady (no writes) ×100 | 0.040 s | 2.418 s | **PGDECS ~60×** |
| system, scattered writes ×100 | 1.436 s (ON) / 1.398 s (OFF) | 2.508 s | **PGDECS ~1.8×** |
| system, hot-chunks writes ×100 | 0.088 s (ON) / 1.348 s (OFF) | 2.441 s | **PGDECS ~28×** (ON) |

How to read this:

- **Fast path** = PGDECS `dense_slots` + packed buffers vs GECS `archetype.get_column` iterate — the fair pair.
- **\*** GECS wins where it has almost no work: the benchmark world is a **single archetype** in GECS, so `archetypes()`/`execute()` and one WTP task are nearly free. PGDECS splits the same 25k entities into ~98 archetype-chunks and batches them into ~13 WTP tasks.
- **Change detection** is the biggest win: with no writes PGDECS skips clean chunks entirely, while GECS always visits every entity.
- Components are not equivalent: PGDECS stores `Vector2`/`int32` in packed SoA buffers; GECS stores `Resource` components (`BenchPosition`, `BenchHealth`).

Reproduce:

```bash
godot --headless --path . --main-scene res://addons/gecs/tests/run_compare_frameworks_headless.tscn
```

More on the hot path and methodology: [PERFORMANCE.md](addons/pgdecs/ecs/PERFORMANCE.md).

## Repository layout

```
addons/pgdecs/          # the addon (copied into a project as a whole)
├── plugin.cfg          # plugin manifest
├── CHEATSHEET.md       # working minimum of the API on one page
├── AGENTS.md           # instructions for AI agents
└── ecs/
    ├── ecs_manager.gd      # core: entities, components, archetypes
    ├── ecs_world.gd        # Node wrapper: profile, scheduler, groups
    ├── components/         # component arrays + generated
    ├── systems/            # system base classes, runner, scheduler, WTP
    ├── queries/            # ECSQuery / ECSQueryBuilder / query chunks
    ├── config/             # profile, strategies, blueprints
    ├── examples/           # working samples (demo world, intent, nodes)
    └── tests/              # unit and perf tests, headless runners

example/                # minimal usage example
addons/gecs/            # original GECS — kept for reference/benchmarks, not part of pgdecs
addons/gut/             # test framework
```

## Documentation

Start with:

- **[CHEATSHEET.md](addons/pgdecs/CHEATSHEET.md)** — ~90% of API usage on one page
- **[addons/pgdecs/README.md](addons/pgdecs/README.md)** — API overview and entry points

Going deeper:

- [FRAMEWORK.md](addons/pgdecs/ecs/FRAMEWORK.md) — full guide (API, systems, queries)
- [DESIGN.md](addons/pgdecs/ecs/DESIGN.md) — architecture: chunks, archetypes, membership
- [PERFORMANCE.md](addons/pgdecs/ecs/PERFORMANCE.md) — hot path, benchmarks, change detection
- [INTENT_PIPELINE.md](addons/pgdecs/ecs/INTENT_PIPELINE.md) — intent tags and reference components
- [OBJECT_COMPONENTS.md](addons/pgdecs/ecs/OBJECT_COMPONENTS.md) — storage types, value/reference components
- [CHANGELOG.md](addons/pgdecs/ecs/CHANGELOG.md) — version history (current: 2.6.3)

## Tests

```bash
godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_performance_tests_headless.gd
```

Expected gates result: `failed: 0`. Details — [tests/README.md](addons/pgdecs/ecs/tests/README.md).

## For AI agents

The addon carries its own rules — no `.cursor/` needed in the game project root:

- [AGENTS.md](addons/pgdecs/AGENTS.md) — brief instructions
- [.cursor/rules/](addons/pgdecs/.cursor/rules/) — project rules
- [agent_handoff/](addons/pgdecs/ecs/agent_handoff/) — generation patterns, quality gates

## License

CC0 1.0 Universal — see [LICENSE](LICENSE).
