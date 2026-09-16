class_name ExampleIntentIds extends RefCounted

## Соглашение об id intent-тегов и ссылочного компонента (пример; игра — свой enum).

const INTENT_BIND_NODE: int = 110
const INTENT_RELEASE: int = 111
const INTENT_DESTROY: int = 112

## Reference-компонент: в SoA лежит сама ссылка (`ECSComponent.Type.NODE2D`), без int-slot.
const NODE: int = 20
