# GECS — тесты производительности (сравнение с PGDECS)

Бенчмарки повторяют набор PGDECS (`addons/pgdecs/ecs/tests/performance/ecs_benchmark.gd`) на тех же шкалах и с теми же именами метрик, чтобы можно было сравнивать логи напрямую.

## Запуск

Редактор: открыть `run_performance_tests.gd` → **Run** (EditorScript).

Headless (три шкалы 5000 / 15000 / 25000). Нужен autoload `ECS` в `project.godot` (уже добавлен). Запуск через main scene — autoload не подхватывается в режиме `--script`:

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --import
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --main-scene res://addons/gecs/tests/run_performance_tests_headless.tscn
```

Быстрая проверка (500 итераций):

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --main-scene res://addons/gecs/tests/run_performance_smoke_headless.tscn
```

Оба фреймворка подряд (только `iterations=25000`); в конце печатается **Compare summary** с fair/unfair парами:

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path . --main-scene res://addons/gecs/tests/run_compare_frameworks_headless.tscn
```

PGDECS отдельно: `--script res://addons/pgdecs/ecs/tests/run_performance_tests_headless.gd`.

## Метрики

Совпадают с PGDECS (кроме system-блока — см. ниже):

- `create_entity` / `destroy_entity`
- `create_entities batch` / `destroy_entities batch`
- `query.get_entity_ids`
- `query.for_each_chunk iterate` (GECS: `QueryBuilder.archetypes()`)
- `query iterate entities+components [slot API]` — PGDECS slow path (handle/slot per entity)
- `query iterate entities+components FAST [dense_slots+buffers]` — PGDECS fast path (сравнивать с GECS)
- `query iterate entities+components [column iterate]` — GECS fast path (`archetype.get_column`)
- WorkerThreadPool варианты (см. compare summary: разная гранулярность задач)
- `add/remove_component`
- `command_buffer execute` / `command_buffer coalescing frame`
- `system change_detection steady`

## Отличия от PGDECS

| PGDECS | GECS |
|--------|------|
| Packed SoA (`Vector2` / `int32` в чанках) | `Resource`-компоненты (`BenchPosition`, `BenchHealth`) |
| `change_detection scattered/hot-chunks ON/OFF` | `system process scattered` / `system process hot-chunks` — GECS всегда обходит все сущности; dirty-skip чанков нет |
| Coalesce destroy/create в command buffer | Команды выполняются по порядку без coalesce |

Для сравнения system с записью: PGDECS `scattered OFF` / `hot-chunks OFF` ↔ GECS `system process scattered` / `system process hot-chunks`.

## Multirun и агрегация

Сохраняйте ≥5 прогонов в `tests/reports/multirun_gecs/run_1.log` … `run_5.log` (блок `--- GECS Performance (iterations=25000) ---`).

Автоматический multirun (5 прогонов + median):

```powershell
cd addons/gecs/tests/reports
.\run_multirun_gecs.ps1 -Runs 5
```

Вручную:
cd addons/gecs/tests/reports
.\aggregate_multirun.ps1 -Directory multirun_gecs -Framework GECS -Markdown
.\compare_frameworks.ps1 -PgdecsDirectory ../../pgdecs/ecs/tests/reports/multirun_post_transition -GecsDirectory multirun_gecs -Markdown
```

Компоненты бенчмарка: `performance/bench_components/bench_position.gd`, `bench_health.gd`.
