# PGDECS

> **Packed Entity-Component-System для Godot 4.x**

Data-oriented ECS на GDScript: хранение сущностей через sparse set, компоненты упакованы в плотные массивы (SoA) по архетипам и чанкам. Проект вырос из [GECS](https://github.com/csprance/gecs), но переписан с нуля — другой API, другая модель хранения, другие компромиссы.

## Ключевые особенности

- **Packed storage** — значения компонентов лежат в `Packed*Array` / типизированных `Array`, итерация идёт по плотным буферам без боксов на сущность
- **Архетипы и чанки** — сущности группируются по набору компонентов; запросы возвращают чанки, а не списки объектов
- **Command buffer** — структурные изменения (spawn/destroy, add/remove компонентов) откладываются и применяются планово после системы
- **System groups и планировщик** — системы привязываются к хукам `_process` / `_physics_process`, частоте (Hz) и `execution_order`
- **Worker Thread Pool** — чанк-системы могут исполняться параллельно (`use_worker_pool`)
- **Кодогенерация** — типизированные компонентные массивы для встроенных типов и нод Godot генерируются из редактора
- **Entity/Scene blueprints** — описание сущностей ресурсами, сборка сущностей из marker-нод в сцене
- **Intent-пайплайн** — lifecycle внешних объектов (ноды, ресурсы) через intent-теги и reference-компоненты

## Требования

Godot 4.x (проект на 4.7, renderer — Mobile).

## Установка

1. Скопировать `addons/pgdecs/` в свой проект.
2. Включить плагин: **Project → Project Settings → Plugins → PGDEcs**.

Плагин добавляет пункт меню **Project → Tools → PGDECS: Regenerate Components** для перегенерации типизированных компонентных массивов.

## Быстрый старт

Минимальный путь — `ECSManager` без `ECSWorld`:

```gdscript
var ecs := ECSManager.new()
ecs.register_component(POSITION_ID, ECSComponent.Type.PACKED_VECTOR2)

var runner := ECSSystemRunner.new()
runner.add_system(MyMovementSystem.new(ecs))

func _process(delta: float) -> void:
	runner.run(delta)
```

Полноценный мир с profile, стратегиями и планировщиком:

```gdscript
var world := ECSDemoWorld.new()
add_child(world)      # рекомендуется до bootstrap (visual host)
world.bootstrap(1000) # profile + стратегии + спавн
```

Система над чанками (основной способ итерации):

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

> Буфер индексируется **слотом**, а не `i` — самая частая ошибка. Подробности в [CHEATSHEET.md](addons/pgdecs/CHEATSHEET.md).

## Структура репозитория

```
addons/pgdecs/          # аддон (переносится в проект целиком)
├── plugin.cfg          # манифест плагина
├── CHEATSHEET.md       # рабочий минимум API на одной странице
├── AGENTS.md           # инструкции для ИИ-агентов
└── ecs/
    ├── ecs_manager.gd      # ядро: сущности, компоненты, архетипы
    ├── ecs_world.gd        # Node-обёртка: profile, scheduler, группы
    ├── components/         # компонентные массивы + generated
    ├── systems/            # базовые классы систем, runner, scheduler, WTP
    ├── queries/            # ECSQuery / ECSQueryBuilder / чанки запросов
    ├── config/             # profile, стратегии, blueprints
    ├── examples/           # рабочие образцы (демо-мир, intent, ноды)
    └── tests/              # юнит- и perf-тесты, headless-раннеры

example/                # минимальный пример использования
addons/gecs/            # исходный GECS — оставлен для справки, не часть pgdecs
addons/gut/             # фреймворк тестов
```

## Документация

Начинать с:

- **[CHEATSHEET.md](addons/pgdecs/CHEATSHEET.md)** — ~90% обращений к API на одной странице
- **[addons/pgdecs/README.md](addons/pgdecs/README.md)** — обзор API и точки входа

Углубление:

- [FRAMEWORK.md](addons/pgdecs/ecs/FRAMEWORK.md) — полное руководство (API, системы, запросы)
- [DESIGN.md](addons/pgdecs/ecs/DESIGN.md) — архитектура: чанки, архетипы, membership
- [PERFORMANCE.md](addons/pgdecs/ecs/PERFORMANCE.md) — hot path, бенчмарки, change detection
- [INTENT_PIPELINE.md](addons/pgdecs/ecs/INTENT_PIPELINE.md) — intent-теги и reference-компоненты
- [OBJECT_COMPONENTS.md](addons/pgdecs/ecs/OBJECT_COMPONENTS.md) — типы хранилищ, value/reference-компоненты
- [CHANGELOG.md](addons/pgdecs/ecs/CHANGELOG.md) — история версий (текущая: 2.6.3)

## Тесты

```bash
godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_performance_tests_headless.gd
```

Ожидание gates: `failed: 0`. Подробности — [tests/README.md](addons/pgdecs/ecs/tests/README.md).

## Для ИИ-агентов

Аддон несёт свои правила с собой — не нужен `.cursor/` в корне игрового проекта:

- [AGENTS.md](addons/pgdecs/AGENTS.md) — краткие инструкции
- [.cursor/rules/](addons/pgdecs/.cursor/rules/) — project rules
- [agent_handoff/](addons/pgdecs/ecs/agent_handoff/) — паттерны генерации, quality gates

## Лицензия

CC0 1.0 Universal — см. [LICENSE](LICENSE).
