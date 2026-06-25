# Safety refactor handoff

> **Архив.** Рефакторинг выполнен; актуальная модель — [DESIGN.md](../DESIGN.md) §0.3 и [FRAMEWORK.md](../FRAMEWORK.md).

## Выполнено (все 5 батчей)

1. **Ключи архетипов** — `ECSArchetypeKey`, реестр по `PackedInt64Array`, `archetype_id` на сущность; `bit_hash()` не используется как ключ словаря.
2. **Sparse chunks** — `Dictionary[int, Chunk]` в `ECSArchetype` и `ECSComponentBaseArray`; итерация через `get_chunk_indices()`.
3. **GC** — `_live_count`, auto-eviction пустых архетипов/чанков, `reset()`, `gc_empty_archetypes()`.
4. **Query API** — pooled chunk views: `begin_chunk_run`, `for_each_chunk`, `collect_chunks(out, true)` / `get_chunks()`; не хранить views между вызовами; `collect_chunks(out, false)` — независимые snapshot.
5. **Docs + minor** — `FRAMEWORK.md`, `DESIGN.md` §0.3, `MIGRATION.md`, debug scratch guards, `is_valid_handle` + generation.

## Новые тесты

- `tests/unit/ecs_archetype_key_test.gd`
- `tests/unit/ecs_archetype_gc_test.gd`
- `tests/unit/ecs_query_test.gd` — `test_get_chunks_snapshots_do_not_alias`

## Quality gates

```powershell
& $godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
$env:PGDECS_RUN_PERF = "1"
& $godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
```

## Не трогали

- `CHUNK_SIZE = 256`, slot formula
- Codegen / `components/generated/`
- `example/bootstrap.gd` (pre-existing parse error)
