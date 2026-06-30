# Changelog

## [2.0.0]

### Removed (breaking)

- Весь bridge-слой: `ECSBridgeHost`, `ECSBridgeBackend`, `ECSBridgeRegistry`, orchestrator/sync systems и bridge strategies.
- `ECSWorld.get_bridge_registry()` / `set_bridge_registry()`.
- `ECSWorldProfile.bridge_registry_strategy`; `apply_to_world(world, bridge_host)` → `apply_to_world(world)`.

### Added

- [INTENT_PIPELINE.md](INTENT_PIPELINE.md) — паттерн Intent-теги + Resource-реестры.
- Stub examples: bind / sync / release / destroy sweep (`examples/intent/`).
- `ExampleEcsDependencies` (было `ExampleEcsServices`); layout `examples/{demo,schema,intent,dependencies,registries}/`.

### Migration

См. [MIGRATION.md](MIGRATION.md#20--bridge-layer-removed-breaking).
