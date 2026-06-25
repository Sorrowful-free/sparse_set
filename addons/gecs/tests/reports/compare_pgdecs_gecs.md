# PGDECS vs GECS — сравнение итерации (iterations=25000)

## Имена метрик (с 2025-06)

| Метрика | Фреймворк | Путь |
|---|---|---|
| `query iterate entities+components [slot API]` | PGDECS | Slow: `get_entity_id_at` → `slot_from_handle` → `get_value_at_slot` |
| `query iterate entities+components FAST [dense_slots+buffers]` | PGDECS | Fast: `get_dense_slots()` + `get_values_buffer()` |
| `query iterate entities+components [column iterate]` | GECS | Fast: `archetype.get_column()` + индекс `i` |

**Честное сравнение hot-path итерации:** PGDECS FAST ↔ GECS column iterate.

**Нечестное (информативное):** PGDECS slot API ↔ GECS column — GECS почти всегда быстрее, т.к. сравниваются разные API.

## WorkerThreadPool

При однородном мире (25k сущностей, один архетип компонентов):

- PGDECS: ~98 archetype-chunks (256 слотов) → ~98 group tasks на прогон
- GECS: ~1 archetype → 1 group task

Overhead `add_group_task` / `wait_for_group_task_completion` доминирует — GECS выигрывает, это не показатель «лучшего ECS».

## Запуск

```powershell
& godot --headless --path . --main-scene res://addons/gecs/tests/run_compare_frameworks_headless.tscn
```

В конце лога — блок `--- Compare summary ---` с fair/unfair парами.

Multirun median:

```powershell
cd addons/gecs/tests/reports
.\compare_frameworks.ps1 -PgdecsDirectory multirun_pgdecs -GecsDirectory multirun_gecs -Markdown
```

Скрипт поддерживает legacy-имена метрик из старых логов (`query iterate entities+components` без суффикса).

## Шаблон таблицы (заполнить после прогона)

| Benchmark | PGDECS | GECS | Примечание |
|---|---:|---:|---|
| **FAST vs column (fair)** | | | PGDECS FAST / GECS column |
| slot API vs column (unfair) | | | не сравнивать как равные |
| WTP e+c | | | PGDECS ~98 tasks vs GECS 1 |
| create_entity | | | PGDECS обычно >> быстрее |
| system hot-chunks ON | | | change_detection |

Перегенерировать median-таблицу: `.\compare_frameworks.ps1 ... -Markdown`
