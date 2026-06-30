class_name ExampleEcsDependencies extends Resource

## Контейнер внешних зависимостей (Resource-реестры) для [ECSSystemStrategy].
## Игра наследует: `GameEcsDependencies` — nav_path_registry, audio_pool и т.д.

@export var node_registry: ECSNodeRegistry
