# Решения по архитектуре ECS (Фаза 0)

## 0.1. Размер чанка

**Решение: фиксированный размер 256.**

- Используется константа `EntityIdsUtils.CHUNK_SIZE` (256) везде: архетипы, компоненты, утилиты.
- Сигнатура `EntityIdsUtils.get_chunk_entity_index(entity_id)` — один аргумент. Формула: `entity_id & 0xFF`, `get_chunk_index(entity_id)` = `entity_id >> 8`.
- Не вводим параметр `chunk_capacity` в ECSManager, Archetype, ComponentFactory — меньше путаницы и проще код.

При необходимости настраиваемого размера чанка можно будет ввести позже через единую точку (константа или настройка в ECSManager).

---

## 0.2. Контракт компонентов

**Решение: вариант A — у компонента есть add_entity / remove_entity / has_entity.**

- **add_entity(entity_id: int)** — менеджер вызывает при добавлении сущности в архетип с данным компонентом. Компонент резервирует слот в чанке и записывает значение по умолчанию для типа (0, 0.0, Vector2.ZERO и т.д.).
- **remove_entity(entity_id: int)** — менеджер вызывает при удалении сущности из архетипа (в т.ч. при destroy_entity). Компонент освобождает слот.
- **has_entity(entity_id: int)** — проверка, есть ли у компонента данные для этой сущности (для Query и has_component в ECSManager).

Существующие методы **add_component(entity_id, value)**, **remove_component(entity_id)**, **set_component**, **get_component** остаются для работы с уже добавленными сущностями (установка/чтение значения). Внутри add_entity можно вызывать добавление в чанк с дефолтным значением; remove_component и remove_entity согласовать так, чтобы оба пути корректно удаляли сущность из компонента.

Менеджер при create_entity / add_component сначала обновляет архетип, затем для каждого затронутого компонента вызывает add_entity; при remove_component / destroy_entity — сначала архетип, затем remove_entity у компонентов.

---

# План фазы 1: базовые классы и утилиты

Фаза опирается на решения фазы 0: размер чанка 256 (`EntityIdsUtils.CHUNK_SIZE`), контракт компонентов add_entity / remove_entity / has_entity.

Порядок выполнения: 1.1 → 1.2 → 1.3 → 1.4 → 1.5 (архетип и менеджер можно править после 1.1 параллельно с 1.2–1.3).

---

## 1.1. EntityIdsUtils

**Файл:** `ecs/entities/entity_ids_utils.gd`

**Что сделать:**
- Оставить как есть: сигнатуры с одним аргументом `get_chunk_index(entity_id)` и `get_chunk_entity_index(entity_id)`.
- Убедиться, что константы `CHUNK_SIZE`, `GET_CHUNK_INDEX_BIT`, `GET_ENTITY_LOCAL_INDEX_BIT_MASK` согласованы (256, 8, 0xFF).

**Итог:** Никаких изменений кода, только проверка. Вся остальная фаза использует только эти однопараметровые вызовы.

---

## 1.2. ComponentBaseArrayChunk

**Файл:** `ecs/components/base/component_base_array_chunk.gd`

**Текущее состояние:** Есть только `_entity_ids: PackedInt32Array`, `get_size()`, `get_entity_ids()`, `clear()`. Нет `_init()`, нет методов для использования из базового компонента при remove_entity / has_entity.

**Что сделать:**

1. **Инициализация**  
   Добавить `func _init() -> void:`, в нём инициализировать `_entity_ids = PackedInt32Array()` (если ещё не инициализировано при объявлении — перепроверить, в GDScript переменные с типом могут быть null). Явная инициализация в `_init()` гарантирует корректное состояние.

2. **Метод для освобождения слота при remove_entity**  
   Добавить абстрактный метод `remove_component(index: int) -> void`.  
   - Смысл: базовый `ComponentBaseArray.remove_entity(entity_id)` будет получать чанк, вычислять индекс через `EntityIdsUtils.get_chunk_entity_index(entity_id)` и вызывать `chunk.remove_component(index)`.  
   - В сгенерированных чанках (фаза 2) реализация: записать в слот значение по умолчанию для типа (0, 0.0, Vector2.ZERO и т.д.). При необходимости помечать слот как пустой (если позже введём отдельный массив «занятости»), либо считать слот пустым по дефолтному значению.

3. **Метод для проверки наличия сущности в чанке**  
   Добавить абстрактный метод `has_component(entity_id: int) -> bool`.  
   - Смысл: базовый `ComponentBaseArray.has_entity(entity_id)` будет вызывать `get_chunk(entity_id)` и, если чанк не null, вызывать `chunk.has_component(entity_id)`.  
   - В сгенерированных чанках реализация уже есть по смыслу (проверка по `_entity_ids` или по индексу); нужно будет привести сигнатуру и использование к единому контракту в фазе 2.

**Итог:** Базовый чанк не хранит `_capacity` и не принимает параметр в `_init()` — размер чанка задаётся в наследниках через `EntityIdsUtils.CHUNK_SIZE` при resize массивов (в фазе 2).

---

## 1.3. ComponentBaseArray

**Файл:** `ecs/components/base/component_base_array.gd`

**Текущее состояние:** `_entities_ids` не инициализируется в `_init()`. Нет методов add_entity / remove_entity / has_entity, которые вызывает ECSManager.

**Что сделать:**

1. **Инициализация**  
   В `_init()` добавить инициализацию: `_entities_ids = PackedInt64Array()`.

2. **add_entity(entity_id: int) -> void**  
   Объявить как абстрактный метод (`@abstract func add_entity(entity_id: int) -> void`).  
   Реализация в сгенерированных классах (фаза 2): получить или создать чанк через `get_or_create_chunk(entity_id)`, записать в чанк значение по умолчанию для типа в слот `EntityIdsUtils.get_chunk_entity_index(entity_id)`, добавить `entity_id` в `_entities_ids` (если список сущностей ведётся на уровне компонента). Логика «добавить слот с дефолтом» — в наследниках.

3. **remove_entity(entity_id: int) -> void**  
   Реализовать в базе (не абстрактный):  
   - Удалить `entity_id` из `_entities_ids` (одно вхождение).  
   - Получить чанк по `get_chunk(entity_id)`; если чанк не null — вызвать `chunk.remove_component(EntityIdsUtils.get_chunk_entity_index(entity_id))`.  
   Таким образом, освобождение слота и типизированный «дефолт» инкапсулированы в чанке через `remove_component(index)`.

4. **has_entity(entity_id: int) -> bool**  
   Реализовать в базе: получить чанк по `get_chunk(entity_id)`; вернуть `chunk != null && chunk.has_component(entity_id)`.

**Итог:** Контракт с ECSManager выполнен: у компонента есть add_entity (в наследниках), remove_entity и has_entity (в базе). Фаза 2 допишет реализации add_entity в сгенерированных компонентах и приведёт чанки к контракту базы (remove_component(index), has_component).

---

## 1.4. ECSManager

**Файл:** `ecs/ecs_manager.gd`

**Что сделать:**

1. **Убрать использование необъявленной переменной chunk_capacity**  
   Во всех местах, где при создании архетипа передаётся `chunk_capacity`, заменить на константу `EntityIdsUtils.CHUNK_SIZE`.  
   Места (по текущему коду):  
   - создание архетипа в `create_entity` (одно место);  
   - создание архетипа в `create_entities` (одно место);  
   - создание нового архетипа в `add_component` (одно место);  
   - создание нового архетипа в `remove_component` (одно место).  
   Итого: четыре замены `chunk_capacity` → `EntityIdsUtils.CHUNK_SIZE`.

2. **Проверка вызовов к компонентам**  
   Убедиться, что менеджер вызывает только:  
   - `component.add_entity(entity_id)` при добавлении сущности в архетип с данным компонентом;  
   - `component.remove_entity(entity_id)` при удалении из архетипа / destroy;  
   - `component.has_entity(entity_id)` в has_component.  
   Дополнительных изменений в логике не требуется — вызовы уже соответствуют контракту.

**Итог:** Менеджер не ссылается на несуществующую переменную и везде использует единый размер чанка из EntityIdsUtils.

---

## 1.5. Archetype

**Файл:** `ecs/archetype.gd`

**Текущее состояние:** Используются вызовы `EntityIdsUtils.get_chunk_index(entity, _chunk_capacity)` и `EntityIdsUtils.get_chunk_entity_index(entity, _chunk_capacity)` — в EntityIdsUtils таких сигнатур с двумя аргументами нет, что приводит к ошибке.

**Что сделать:**

1. **Перейти на однопараметровые вызовы**  
   Во всех местах заменить:  
   - `EntityIdsUtils.get_chunk_index(entity, _chunk_capacity)` → `EntityIdsUtils.get_chunk_index(entity)`;  
   - `EntityIdsUtils.get_chunk_entity_index(entity, _chunk_capacity)` → `EntityIdsUtils.get_chunk_entity_index(entity)`.

2. **Размер чанка при создании архетипа**  
   Конструктор архетипа по-прежнему принимает `chunk_capacity: int` (для размера создаваемых массивов чанков). ECSManager будет передавать `EntityIdsUtils.CHUNK_SIZE` (см. 1.4). Внутри архетипа `_chunk_capacity` используется только при создании нового чанка (`chunk.resize(_chunk_capacity)` и `chunk.fill(-1)`). Логика индексации — только через однопараметровые функции EntityIdsUtils.

3. **Проверить get_chunk(entity)**  
   Сейчас в архетипе используется `get_chunk_index(entity, _chunk_capacity)`. После замены на `get_chunk_index(entity)` нужно убедиться, что обращение к `_chunks[chunk_index]` не выходит за границы до вызова `get_or_create_chunk` (get_or_create_chunk уже расширяет массив чанков при необходимости).

**Итог:** Архетип не вызывает несуществующие перегрузки EntityIdsUtils и согласован с фиксированным размером чанка 256.

---

## 1.6. ComponentFactory

**Файл:** `ecs/components/component_factory.gd`

**Что сделать:**
- Сигнатуру не менять: `create_component(component_type: Variant.Type)` без второго параметра (размер чанка фиксирован в EntityIdsUtils, сгенерированные компоненты в фазе 2 будут создаваться без аргумента в конструкторе или с константой внутри).
- Проверить, что все типы из match по-прежнему соответствуют сгенерированным классам (ComponentByteArray, ComponentInt32Array, …). После фазы 2 убедиться, что конструкторы этих классов вызываются без аргументов (или с теми, что фабрика передаёт).

**Итог:** Фаза 1 для фабрики — без изменений кода, только явная проверка. При необходимости правки конструкторов сгенерированных компонентов — в фазе 2.

---

## Чек-лист по завершении фазы 1

- [ ] EntityIdsUtils: сигнатуры без изменений, константы проверены.
- [ ] ComponentBaseArrayChunk: есть `_init()`, объявлены абстрактные `remove_component(index)` и `has_component(entity_id)`.
- [ ] ComponentBaseArray: в `_init()` инициализирован `_entities_ids`; добавлены абстрактный `add_entity(entity_id)` и реализованные `remove_entity(entity_id)` и `has_entity(entity_id)`.
- [ ] ECSManager: везде вместо `chunk_capacity` используется `EntityIdsUtils.CHUNK_SIZE` (4 места).
- [ ] Archetype: все вызовы EntityIdsUtils — с одним аргументом (entity); конструктор по-прежнему принимает chunk_capacity, передаётся CHUNK_SIZE из ECSManager.
- [ ] ComponentFactory: без изменений, готов к использованию с обновлёнными базовыми классами.

После выполнения фазы 1 сгенерированные компоненты (int32, byte, vector2 и т.д.) ещё не будут соответствовать новой базе — их приведение в соответствие (add_entity, чанки с remove_component(index) и has_component, шаблоны, перегенерация) выполняется в фазе 2.

---

# План фазы 2: шаблоны и сгенерированные компоненты

Цель: привести шаблоны и сгенерированный код в соответствие с базовыми классами фазы 1. После фазы 2 все компоненты (Byte, Int32, Int64, Float32, Float64, Vector2/3/4, Color) должны реализовывать `add_entity`, чанки — `remove_component(index)` и `has_component(entity_id)`, конструкторы — без аргументов, везде однопараметровые вызовы `EntityIdsUtils.get_chunk_entity_index(entity_id)`.

Порядок: 2.1 шаблон чанка → 2.2 шаблон компонента → 2.3 кодогенератор → 2.4 проверка.

---

## 2.1. Шаблон чанка `{component_type_array_chunk}.gdt`

**Файл:** `ecs/editor/templates/{component_type_array_chunk}.gdt`

**Текущие проблемы:**
- В `add_component` лишняя запятая: `get_chunk_entity_index(entity_id,)` — оставить один аргумент.
- Метод `remove_component(entity_id: int)` в шаблоне принимает entity_id и сам вычисляет index; база ожидает **`remove_component(index: int)`** (очистка слота по индексу). Нужна одна реализация с сигнатурой по индексу.
- Для корректной работы `has_component(entity_id)` и `remove_component(index)` чанк должен хранить «занятость» слотов по индексу. Сейчас `_entity_ids` — список (append), при очистке по индексу мы не знаем, какой entity_id убрать из списка.

**Решение по хранению в чанке:**
- Сделать **`_entity_ids` фиксированным массивом размера CHUNK_SIZE** (`PackedInt32Array`, resize и fill(-1) в `_init()`). Слот занят, если `_entity_ids[index] != -1`, значение entity там хранится.
- **add_component(entity_id, value):** `index = EntityIdsUtils.get_chunk_entity_index(entity_id)`, `_entity_ids[index] = entity_id`, `_components_values[index] = value`.
- **remove_component(index: int):** реализация абстрактного метода базы: `_entity_ids[index] = -1`, `_components_values[index] = {default_value}`.
- **has_component(entity_id: int):** `index = EntityIdsUtils.get_chunk_entity_index(entity_id)`, `return _entity_ids[index] == entity_id`.
- **get_size():** в базе возвращает `_entity_ids.size()` (после перехода на фиксированный массив это будет CHUNK_SIZE). В шаблоне чанка **переопределить get_size()**: цикл по `_entity_ids`, подсчёт слотов, где `_entity_ids[i] != -1` — так получаем реальное число сущностей в чанке (нужно для логики «удалять пустой чанк» в компоненте, если она есть).

**Что править в шаблоне:**
1. `_init()`: оставить `super()`, инициализировать `_components_values` и **`_entity_ids`** — resize до `EntityIdsUtils.CHUNK_SIZE`, fill(-1).
2. Убрать лишнюю запятую в `get_chunk_entity_index(entity_id,)`.
3. Заменить `remove_component(entity_id: int)` на **`remove_component(index: int)`**: присвоить `_entity_ids[index] = -1`, `_components_values[index] = {default_value}`.
4. **add_component(entity_id, value):** не делать `_entity_ids.append(entity_id)`; вместо этого `index = EntityIdsUtils.get_chunk_entity_index(entity_id)`, `_entity_ids[index] = entity_id`, `_components_values[index] = value`.
5. **has_component(entity_id):** `var index = EntityIdsUtils.get_chunk_entity_index(entity_id)`; `return _entity_ids[index] == entity_id` (с учётом границ, если нужно).
6. **get_size():** при необходимости переопределить: цикл по `_entity_ids`, подсчёт `!= -1`.
7. **set_component / get_component:** оставить, использовать `EntityIdsUtils.get_chunk_entity_index(entity_id)` с одним аргументом.
8. **clear():** кроме `super.clear()`, обнулить массивы или заполнить -1 / default, в зависимости от выбранной семантики.

**Итог:** чанк реализует абстрактные `remove_component(index)` и `has_component(entity_id)`, хранит занятость по индексу в `_entity_ids` фиксированного размера.

---

## 2.2. Шаблон компонента `{component_type_array}.gdt`

**Файл:** `ecs/editor/templates/{component_type_array}.gdt`

**Что сделать:**

1. **Добавить реализацию `add_entity(entity_id: int)`** (абстрактный метод базы):
   - `var chunk = get_or_create_chunk(entity_id)`
   - Вызвать добавление в чанк с дефолтным значением: `chunk.add_component(entity_id, {default_value})` (в чанке add_component уже кладёт по индексу и помечает слот).
   - `_entities_ids.append(entity_id)`.

2. **create_chunk():** оставить без аргументов: `return {component_array_chunk_type}.new()` (конструктор чанка без параметров, размер из EntityIdsUtils.CHUNK_SIZE внутри чанка).

3. **remove_component(entity_id):** уже вызывает `chunk.remove_component(chunk_entity_index)` — передаётся индекс. После правки шаблона чанка сигнатура совпадёт: чанк принимает `index`.

4. **has_component(entity_id):** оставить вызов `chunk.has_component(entity_id)` — база и чанк совпадают по контракту.

5. Во всех вызовах **EntityIdsUtils.get_chunk_entity_index(entity_id)** — один аргумент (без второго параметра и без лишних запятых).

**Итог:** у сгенерированного компонента есть `add_entity`, `create_chunk()` без аргументов, все вызовы утилит — однопараметровые.

---

## 2.3. Кодогенератор и перегенерация

**Файл:** `ecs/editor/ecs_code_gen.gd`

**Что сделать:**
- Убедиться, что скрипт подставляет пути к шаблонам `{component_type_array}.gdt` и `{component_type_array_chunk}.gdt` (или актуальные имена файлов шаблонов) и что в списке `components` все нужные типы (Byte, Int32, Int64, Float32, Float64, Vector2, Vector3, Vector4, Color) с правильными `part_name`, `value_type`, `default_value`, `packed_type`.
- Запустить генерацию (EditorScript или вручную), чтобы перезаписать все файлы в `ecs/components/generated/<type>/`:
  - `component_<type>_array.gd`
  - `component_<type>_chunk_array.gd`

**Итог:** все сгенерированные компоненты и чанки пересозданы из обновлённых шаблонов.

---

## 2.4. ComponentFactory и конструкторы

**Файл:** `ecs/components/component_factory.gd`

- Сгенерированные компоненты после фазы 2 имеют `_init()` без параметров (вызов `super()` без аргументов). Фабрика создаёт их через `ComponentXXXArray.new()` — без аргументов. Проверить, что вызовы `ComponentByteArray.new()`, `ComponentInt32Array.new()` и т.д. не передают параметров.

**Итог:** проект собирается, регистрация и создание компонентов через фабрику работают без ошибок.

---

## Чек-лист по завершении фазы 2

- [ ] Шаблон чанка: `_entity_ids` фиксированного размера CHUNK_SIZE, fill(-1); `remove_component(index: int)`; `has_component(entity_id)` по индексу; все вызовы get_chunk_entity_index с одним аргументом.
- [ ] Шаблон компонента: добавлен `add_entity(entity_id)` с вызовом `chunk.add_component(entity_id, default_value)` и `_entities_ids.append(entity_id)`; `create_chunk()` без аргументов.
- [ ] Кодогенератор запущен, все типы перегенерированы.
- [ ] ComponentFactory создаёт компоненты через `.new()` без аргументов.
- [ ] Ручная проверка: создание сущности с компонентом, add_component/set/get, remove_component, destroy_entity — без ошибок.

---

# Фаза 3: Архетипы и запросы

**3.1. Archetype** — исправлен в фазе 1 (однопараметровые вызовы EntityIdsUtils, проверка границ в get_chunk).

**3.2. Query** (`ecs/queries/query.gd`):
- **Проблема:** BitMask создавалась с размером `component_ids.size()` и `without_component_ids.size()`, а затем вызывалось `bit_set(component_id, true)` — индекс бита это **component_id**, который может быть большим (например, 10 или 100). Размер маски оказывался недостаточным.
- **Решение:** Вычислить `max_component_id` по всем with/without, задать единый размер масок `mask_capacity = max(1, max_component_id + 1)` и создавать обе BitMask с этой ёмкостью.

---

# Фаза 4: Системы и command buffer

**4.1. SystemBase** (`ecs/systems/system_base.gd`):
- Заменён удалённый класс `CommandBuffer` на `ECSCommandBuffer`.
- Добавлено поле `var _command_buffer: ECSCommandBuffer`, в `_init()` создаётся `ECSCommandBuffer.new(ecs_manager)`.

**4.2. ECSCommandBuffer** (`ecs/ecs_command_buffer.gd`):
- Исправлена совместимость с varargs в ECSManager: вызовы `create_entity` и `create_entities` переведены на `.callv(...)`, чтобы передавать аргументы из массива как отдельные параметры (вместо одного аргумента-массива).

---

# Фаза 5: Пример и проверка

**5.1. ECSManager** — добавлен метод **get_component_array(component_id: int) -> ComponentBaseArray** для доступа к зарегистрированному компоненту по id (возвращает null, если компонент не зарегистрирован).

**5.2. Пример (example/)** — приведён к рабочему API без класса ComponentBaseView:
- **GameComponents:** регистрирует компонент Position (id=1, TYPE_PACKED_VECTOR2_ARRAY), сохраняет типизированную ссылку `PositionComponent: ComponentVector2Array` через `get_component_array(1) as ComponentVector2Array`; константа `POSITION_COMPONENT_ID` для использования в сценах.
- **Bootstrap:** в `_ready()` создаёт GameComponents, создаёт сущность с компонентом позиции (`create_entity(GameComponents.POSITION_COMPONENT_ID)`), устанавливает позицию через `PositionComponent.set_component(entity_id, Vector2(100, 200))`.

**5.3. Проверка** — после запуска сцены с Bootstrap сущность создаётся, компонент записывается без ошибок. Существующие тесты (например, bit_mask_test) не затрагиваются.
