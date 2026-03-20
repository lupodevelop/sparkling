# Quick Start

A typical workflow: define a schema, build a query, execute it via the repo.

```gleam
import sparkling/expr
import sparkling/query
import sparkling/repo
import sparkling/schema

// 1. Define the schema
let users_table = schema.table("users", [
  schema.field("id", schema.UInt32),
  schema.field("name", schema.String),
  schema.field("email", schema.String),
  schema.field("created_at", schema.DateTime64(3)),
])

// 2. Create a repository
let r =
  repo.new("http://localhost:8123")
  |> repo.with_database("mydb")
  |> repo.with_credentials("default", "")

// 3. Build a query
let q =
  query.new()
  |> query.from("users")
  |> query.select([expr.field("id"), expr.field("name")])
  |> query.where(expr.gt(expr.field("id"), expr.int(100)))
  |> query.limit(10)

// 4. Generate SQL and execute
case query.to_sql(q) {
  Ok(sql) ->
    case repo.execute_sql(r, sql) {
      Ok(body) -> io.println(body)
      Error(_err) -> io.println("query failed")
    }
  Error(msg) -> io.println("invalid query: " <> msg)
}
```

## Related examples

- [Schema](examples/schema.md)
- [Query builder](examples/query.md)
- [Types](examples/types.md)
- [Repository](examples/repo.md)
- [Encode](examples/encode.md)
- [Decode](examples/decode.md)
- [Changeset](examples/changeset.md)
