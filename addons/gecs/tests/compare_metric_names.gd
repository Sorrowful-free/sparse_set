extends RefCounted
class_name CompareMetricNames

## Общие имена метрик для сравнения PGDECS vs GECS (логи, aggregate, compare summary).

const QUERY_E_C_SLOT := "query iterate entities+components [slot API]"
const QUERY_E_C_FAST := "query iterate entities+components FAST [dense_slots+buffers]"
const QUERY_E_C_COLUMN := "query iterate entities+components [column iterate]"
const QUERY_E_C_WTP := "query iterate entities+components WorkerThreadPool"
const QUERY_CHUNKS_WTP := "query.for_each_chunk WorkerThreadPool"
