# Encode

`sparkling/encode` converts Gleam values to JSONEachRow (and other formats) for ClickHouse inserts.

## encode_json_each_row

Takes a list of `Dict(String, json.Json)` records and produces a newline-separated JSON string.

```gleam
import gleam/dict
import gleam/json
import sparkling/encode

let rows = [
  dict.from_list([
    #("id", json.int(1)),
    #("name", json.string("Alice")),
    #("active", json.bool(True)),
  ]),
  dict.from_list([
    #("id", json.int(2)),
    #("name", json.string("Bob")),
    #("active", json.bool(False)),
  ]),
]

let body = encode.encode_json_each_row(rows)
// => {"id":1,"name":"Alice","active":true}
//    {"id":2,"name":"Bob","active":false}
```

## encode_record

Encode a single record.

```gleam
let row = dict.from_list([
  #("id", json.int(42)),
  #("status", json.string("active")),
])

encode.encode_record(row)
// => {"id":42,"status":"active"}
```

## ClickHouse type encoders

```gleam
import sparkling/types

// Decimal — encoded as string to preserve precision
let assert Ok(price) = types.decimal("123.456")
encode.decimal(price)  // => json.string("123.456")

// DateTime64
let assert Ok(ts) = types.datetime64("2024-01-15 10:30:45.123", 3, Some("UTC"))
encode.datetime64(ts)  // => json.string("2024-01-15 10:30:45.123")

// UUID
let assert Ok(uid) = types.uuid("550e8400-e29b-41d4-a716-446655440000")
encode.uuid(uid)  // => json.string("550e8400-e29b-41d4-a716-446655440000")

// LowCardinality
let status = types.low_cardinality_string("active")
encode.low_cardinality_string(status)  // => json.string("active")

// Enum — encode as underlying int
encode.enum_value(1)  // => json.int(1)
```

## Nullable

```gleam
encode.nullable(Some(json.int(42)))  // => json.int(42)
encode.nullable(None)                // => json.null()
```

## Arrays

```gleam
encode.array([1, 2, 3], json.int)
// => json.array([json.int(1), json.int(2), json.int(3)])
```

## Map / Tuple / Nested

```gleam
// ClickHouse Map
encode.clickhouse_map_from_dict(
  dict.from_list([#("key", json.string("value"))])
)

// ClickHouse Tuple (encoded as JSON array)
encode.clickhouse_tuple([json.int(1), json.string("hello")])

// Nested structure
encode.nested_from_dict(
  dict.from_list([#("field", json.string("value"))])
)
```
