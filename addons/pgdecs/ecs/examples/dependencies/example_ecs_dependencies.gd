class_name ExampleEcsDependencies extends Resource

## Контейнер внешних зависимостей (Resource-**сервисы**, не реестры-хранилища) для [ECSSystemStrategy].
## Игра наследует: `GameEcsDependencies` — пул нод, navmesh, audio bus, `NET_ID`-маппинг и т.д.
##
## Per-entity данные живут в компонентах (`NODE2D`, `REFCOUNTED`), а не в side-table по int-slot.

@export var node_pool: ECSNodePool
