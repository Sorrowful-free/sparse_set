# Changelog

## [2.2.1]

### Changed

- Codegen: папки/файлы сгенерированных компонентов — snake_case (`generated/packedvector4/` → `generated/packed_vector4/`, `ecs_component_packed_vector4_array.gd`; также `nodepath` → `node_path`, `stringname` → `string_name`, `packedscene` → `packed_scene`, `refcounted` → `ref_counted`). Имена классов (`ECSComponentPackedVector4Array`) **не меняются** — только пути.

## [2.2.0]

### Added

- Новые строготипизированные хранилища `Array[T]`: `BOOL`, `INT`, `FLOAT`, `PLANE`, `VECTOR2`, `VECTOR3`, `VECTOR4`, `COLOR`, `STRINGNAME`, `STRING`, `NODEPATH`, `RID` — в `ECSComponent.Type`, `ECSComponentFactory` и codegen. Всего 38 типов хранилищ.
- `ECSComponent.Type`: порядок групп повторяет список кодогенерации; `Object` остаётся generic (untyped `Array`).

### Changed (breaking)

- Сгенерированные классы packed-компонентов переименованы: `ECSComponent<X>Array` → `ECSComponentPacked<X>Array` (Byte, Int32, Int64, Float32, Float64, Vector2, Vector3, Vector4, Color, String) и их `…ArrayChunk`. Имена `ECSComponentVector2/3/4Array`, `ECSComponentColorArray`, `ECSComponentStringArray` теперь закреплены за непакованными `Array[T]`-типами.
- Codegen: ключ конфигурации `packed_type` → `array_type` (тип буфера: `Packed*Array` или `Array[T]`); шаблон чанка `{packed_type}` → `{array_type}`.

### Fixed

- Codegen defaults: `NodePath` `@""` → `^""` (синтаксис Godot 4; `@""` — Godot 3), `StringName` `""` → `&""`.

### Documentation

- OBJECT_COMPONENTS: полная таблица 38 типов (packed / value / reference), пометка о дублях packed ↔ `Array[T]`, RID, `StringName`/`NodePath`.
- MIGRATION: раздел 2.2 (переименование классов, новые типы, `array_type`).
- FRAMEWORK / DESIGN: списки типов приведены к текущим.

### Migration

См. [MIGRATION.md](MIGRATION.md#22--packed-компоненты-переименование-классов--новые-типы-breaking).

## [2.1.1]

### Fixed

- Перф-бенчмарк больше не зависит от аддона gecs: `preload` общего `CompareMetricNames` заменён локальными константами имён метрик. pgdecs парсится и запускает перф-тесты автономно.

### Documentation

- PERFORMANCE: сравнение с GECS помечено как требующее аддон gecs.

## [2.1.0]

### Added

- `ECSComponent.Type` — собственный enum типов хранилищ вместо `Variant.Type`; различает Object-подтипы и value-типы без `Packed*Array`.
- Строготипизированные компоненты: `AABB`, `RECT2`, `QUATERNION`, `BASIS`, `TRANSFORM2D`, `TRANSFORM3D`, `VECTOR2I`, `VECTOR3I`, `VECTOR4I` (буфер `Array[T]`); `NODE`, `NODE2D`, `NODE3D`, `RESOURCE`, `PACKED_SCENE`, `REF_COUNTED` (буфер `Array[T]`, default `null`); generic `OBJECT`.
- Codegen: конфигурации новых типов и инициализация буфера через `{buffer_init}` (`Packed*Array()` для packed, `[]` для `Array[T]`).

### Changed (breaking)

- `ECSManager.register_component(id, component_type)` принимает `ECSComponent.Type`, а не `Variant.Type`.
- `ECSComponentRegistryStrategy.get_components()` → `Dictionary[int, ECSComponent.Type]`.

### Documentation

- OBJECT_COMPONENTS: таблица всех типов хранилищ, семантика по ссылке и `duplicate(true)`, производительность `Array[T]`.
- MIGRATION: раздел 2.1.

## [2.0.2]

### Changed

- `ExampleEcsServices` → `ExampleEcsDependencies`; поле `services` → `dependencies` в intent-примерах и strategies.
- Примеры: layout `examples/{demo,schema,intent,dependencies,registries}/`; `object_registry_demo.gd` → `registries/ecs_node_registry.gd`.

### Documentation

- FRAMEWORK: малый vs модульный layout игры (`R_<Module>Dependencies`), profile как wiring hub.
- NAMING: мостик `ExampleEcsDependencies` / `GameEcsDependencies` / `R_*Dependencies`.
- OBJECT_COMPONENTS: slot-based vs handle-based реестры.
- README, AGENTS, INTENT_PIPELINE, AI_CODE_PATTERNS — синхронизация терминологии.

## [2.0.0]

### Removed (breaking)

- Весь bridge-слой: `ECSBridgeHost`, `ECSBridgeBackend`, `ECSBridgeRegistry`, orchestrator/sync systems и bridge strategies.
- `ECSWorld.get_bridge_registry()` / `set_bridge_registry()`.
- `ECSWorldProfile.bridge_registry_strategy`; `apply_to_world(world, bridge_host)` → `apply_to_world(world)`.

### Added

- [INTENT_PIPELINE.md](INTENT_PIPELINE.md) — паттерн Intent-теги + Resource-реестры.
- Stub examples: bind / sync / release / destroy sweep (`examples/intent/`).

### Migration

См. [MIGRATION.md](MIGRATION.md#20--bridge-layer-removed-breaking).
