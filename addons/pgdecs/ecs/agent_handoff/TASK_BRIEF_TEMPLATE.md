# Task Brief Template (Composer)

Скопируй блок ниже в промпт Composer и заполни поля перед каждым запуском.

---

## Task Brief

**Batch:** `A | B | C | D` (только один)

**Обязательно прочитать перед кодом:** [`AI_CODE_PATTERNS.md`](AI_CODE_PATTERNS.md)

**Goal (1-2 предложения):**
- ...

**Scope (точные файлы):**
- `addons/pgdecs/ecs/...`
- ...

**Non-goals (запрещено менять):**
- Публичный API (если не указано иное)
- Файлы вне Scope
- План-файлы в `.cursor/plans/`
- Object/registry bridge (`OBJECT_COMPONENTS.md`)

**Behavioral requirements:**
- ...

**Definition of Done:**
- [ ] Изменения только в Scope
- [ ] Unit tests: `run_unit_tests_headless.gd` — green
- [ ] Perf gate (если Batch A perf): `PGDECS_RUN_PERF=1` + `run_composer_gates_headless.gd`
- [ ] Self-check: [`SELF_CHECK.md`](SELF_CHECK.md)
- [ ] Handoff report (см. формат ниже)

**Validation commands (PowerShell):**
```powershell
$godot = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
& $godot --headless --path . --script res://addons/pgdecs/ecs/tests/run_composer_gates_headless.gd
```

---

## Handoff Report Format (обязательный ответ Composer)

1. **Changed files** — список путей
2. **Behavioral impact** — что изменилось для пользователя ECS
3. **Validation evidence** — вывод тестов / метрик
4. **Known risks** — что не покрыто, edge cases
