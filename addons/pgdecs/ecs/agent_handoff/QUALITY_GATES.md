# Quality Gates

## Gate 1 — Unit (всегда)

**Скрипт:** [`tests/run_composer_gates_headless.gd`](../tests/run_composer_gates_headless.gd)

```powershell
$godot = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
& $godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
```

**Критерий:** `failed: 0` в Summary.

---

## Gate 2 — Performance (только Batch A / perf-задачи)

Установить переменную окружения и запустить тот же gates-скрипт:

```powershell
$env:PGDECS_RUN_PERF = "1"
& $godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
```

**Критерий:**
- perf-скрипт завершается без ошибок;
- в handoff report — краткое сравнение с [`tests/reports/refactor_baseline_vs_after.md`](../tests/reports/refactor_baseline_vs_after.md) или новый multirun.

---

## Gate 3 — CI (на PR)

Workflow: [`.github/workflows/ecs-tests.yml`](../../../../.github/workflows/ecs-tests.yml) — unit headless на `addons/pgdecs/**`.

---

## Блокер policy

Если любой gate красный — **не сдавать «готово»**. Вернуть список блокеров и шаги воспроизведения.
