# Examples extracted from sparkling/src/sparkling/schema.gleam

## FieldType examples

```gleam
UInt32
Nullable(of: String)
Array(of: Int32)
Decimal(precision: 18, scale: 2)
DateTime64(precision: 3)
```

## table/field examples

```gleam
table("users", [
  field("id", UInt64),
  field("email", String),
  field("created_at", DateTime64(3)),
])

field("user_id", UInt64)
field("name", Nullable(of: String))
```

## field_type_to_sql examples

```gleam
field_type_to_sql(UInt32)
// => "UInt32"

field_type_to_sql(Nullable(of: String))
// => "Nullable(String)"

field_type_to_sql(Array(of: Int32))
// => "Array(Int32)"
```

## to_create_table_sql example

```gleam
let users_table = table("users", [
  field("id", UInt64),
  field("email", String),
])

to_create_table_sql(users_table, engine: "MergeTree()")
// => "CREATE TABLE users (id UInt64, email String) ENGINE = MergeTree()"
```

## find_field / field_names examples

```gleam
let tbl = table("users", [field("id", UInt64)])
find_field(tbl, "id")
// => Some(Field("id", UInt64))

find_field(tbl, "unknown")
// => None

let tbl = table("users", [field("id", UInt64), field("name", String)])
field_names(tbl)
// => ["id", "name"]
```
