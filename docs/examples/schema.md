# Schema

## Defining a table

```gleam
import sparkling/schema

let users_table = schema.table("users", [
  schema.field("id", schema.UInt64),
  schema.field("email", schema.String),
  schema.field("score", schema.Float64),
  schema.field("created_at", schema.DateTime64(3)),
])
```

## FieldType variants

```gleam
// Integers
schema.UInt8
schema.UInt16
schema.UInt32
schema.UInt64
schema.Int8
schema.Int16
schema.Int32
schema.Int64

// Floats
schema.Float32
schema.Float64

// Strings
schema.String
schema.FixedString(36)

// Dates and times
schema.Date
schema.Date32
schema.DateTime
schema.DateTime64(3)          // precision 0-9

// Decimals
schema.Decimal(18, 2)         // precision, scale

// Boolean and UUID
schema.Bool
schema.UUID

// Wrappers
schema.Nullable(schema.String)
schema.Array(schema.Int32)
schema.LowCardinality(schema.String)

// Complex types
schema.Enum8([#("active", 1), #("inactive", 2)])
schema.Enum16([#("pending", 1), #("done", 2)])
schema.Tuple([schema.UInt32, schema.String])
schema.JSON
```

## field_type_to_sql

```gleam
schema.field_type_to_sql(schema.UInt32)
// => "UInt32"

schema.field_type_to_sql(schema.Nullable(schema.String))
// => "Nullable(String)"

schema.field_type_to_sql(schema.Array(schema.Int32))
// => "Array(Int32)"

schema.field_type_to_sql(schema.Decimal(18, 2))
// => "Decimal(18, 2)"

schema.field_type_to_sql(schema.DateTime64(3))
// => "DateTime64(3)"

schema.field_type_to_sql(schema.LowCardinality(schema.String))
// => "LowCardinality(String)"
```

## to_create_table_sql

```gleam
let tbl = schema.table("events", [
  schema.field("id", schema.UInt64),
  schema.field("name", schema.String),
  schema.field("occurred_at", schema.DateTime64(3)),
])

schema.to_create_table_sql(tbl, "MergeTree() ORDER BY id")
// => "CREATE TABLE events (id UInt64, name String, occurred_at DateTime64(3)) ENGINE = MergeTree() ORDER BY id"
```

## find_field / field_names

```gleam
let tbl = schema.table("users", [
  schema.field("id", schema.UInt64),
  schema.field("name", schema.String),
])

schema.find_field(tbl, "id")
// => Some(Field("id", UInt64))

schema.find_field(tbl, "unknown")
// => None

schema.field_names(tbl)
// => ["id", "name"]
```
