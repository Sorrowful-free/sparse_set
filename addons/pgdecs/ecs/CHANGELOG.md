# Changelog

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
