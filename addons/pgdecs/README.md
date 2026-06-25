# PGDECS

Data-oriented ECS для Godot 4.x (GDScript).

## Правило итерации в системах

| Ситуация | API |
|----------|-----|
| Система **только меняет значения** компонентов и **не создаёт** новых сущностей в этом проходе | **Fast-path:** `get_dense_slots()` + `get_values_buffer()` |
| Система **создаёт/удаляет** сущности, **меняет набор компонентов** или нужен **handle** | **Slot API:** `slot_from_handle(dense[i])` или `get_component(entity_id)` |

Подробно: [ecs/FRAMEWORK.md](ecs/FRAMEWORK.md#ключевое-правило-fast-path-vs-slot-api).

## Быстрый старт

```gdscript
var world := ECSDemoWorld.new()
add_child(world)          # рекомендуется до bootstrap (visual host)
world.bootstrap(1000)     # profile + DemoMovementStrategy + spawn
```

`bootstrap()` до `add_child` тоже работает: visual strategies без host переустанавливаются в `_enter_tree()`.

Подробнее: [ecs/FRAMEWORK.md](ecs/FRAMEWORK.md#configuration-profile-registry-strategies).

## Минимальный путь (без ECSWorld)

Для прототипа или тестов — без сцены, profile и visual:

```gdscript
var ecs := ECSManager.new()
ecs.register_component(POSITION_ID, TYPE_PACKED_VECTOR2_ARRAY)
var runner := ECSSystemRunner.new()
runner.add_system(MyMovementSystem.new(ecs))
# каждый кадр:
runner.run(delta)
```

`ECSWorld` нужен, когда хотите `@export profile`, дочерний `ECSVisualHost`, `_process` и visual sync из коробки.

## API

**Внешний (удобный):** типизированный `Array[int]`, `PackedInt64Array` создаётся внутри.

- `create_entity([POSITION_ID, HEALTH_ID])`
- `create_entities(count, [POSITION_ID])`
- `destroy_entities([id1, id2])`
- `precache_archetype([POSITION_ID, HEALTH_ID])`
- `prepare_archetype([...])` → нормализованный `PackedInt64Array` для hot-path

**Hot path:** переиспользуйте результат `prepare_archetype` с `*_packed`:

```gdscript
var PLAYER := ecs.prepare_archetype([POSITION_ID, HEALTH_ID])
ecs.create_entities_packed(100, player_arch)
ecs.destroy_entities_packed(survivor_ids)
```

**ECSQueryBuilder** — одиночные и пакетные фильтры:

```gdscript
ECSQueryBuilder.new()
    .with_components([POSITION_ID, HEALTH_ID])
    .without_components([TAG_ID])
    .build(ecs)
```

**ECSCommandBuffer** — тот же двухслойный API, что у менеджера:

```gdscript
buf.create_entity([POSITION_ID])
buf.create_entity_packed(player_arch)
buf.destroy_entities([id_a, id_b])
buf.destroy_entities_packed(batch_ids)
```

## Документация

- **[FRAMEWORK.md](ecs/FRAMEWORK.md)** — полное руководство по фреймворку (API, системы, query, правило fast-path)
- [DESIGN.md](ecs/DESIGN.md) — архитектурные решения, чанки, membership
- [PERFORMANCE.md](ecs/PERFORMANCE.md) — hot path, бенчмарки, change detection
- [OBJECT_COMPONENTS.md](ecs/OBJECT_COMPONENTS.md) — Node/String через реестры
- [MIGRATION.md](ecs/MIGRATION.md) — внешний API (`Array[int]`) и hot path (`*_packed`)
- [NAMING.md](ecs/NAMING.md) — префиксы и имена классов
- [agent_handoff/](ecs/agent_handoff/README.md) — шаблоны для Composer (батчи, gates, self-check)
- [tests/README.md](ecs/tests/README.md) — юнит- и perf-тесты

## Cursor / ИИ (переиспользование аддона)

Правила для агентов **внутри аддона**, не в корне игрового проекта:

- [AGENTS.md](AGENTS.md) — краткие инструкции (автоподхват при работе в `addons/pgdecs/`)
- [.cursor/rules/](.cursor/README.md) — project rules (`.mdc`)
- [ecs/agent_handoff/AI_CODE_PATTERNS.md](ecs/agent_handoff/AI_CODE_PATTERNS.md) — полная спецификация codegen

## Тесты

```powershell
$godot = (Get-Command godot -ErrorAction SilentlyContinue).Source
if (-not $godot) { $godot = "godot" }
& $godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
& $godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_performance_tests_headless.gd
```

## Demo

См. [ecs/examples/demo_world.gd](ecs/examples/demo_world.gd) — bootstrap 1000 сущностей с `DemoMovementStrategy`.
