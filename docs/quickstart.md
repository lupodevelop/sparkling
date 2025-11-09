# Quick Start

This quick start shows a typical workflow using Sparkling's API in Gleam.

```gleam
import sparkling/query
import sparkling/schema
import sparkling/types

// 1. Define your schema
let users_table = schema.table("users", [
  schema.field("id", schema.UInt32),
  schema.field("name", schema.String),
  schema.field("email", schema.String),
  schema.field("created_at", schema.DateTime64),
])

// 2. Create a repository
let repo = repo.new("http://localhost:8123")
  |> repo.with_database("mydb")

// 3. Build and execute queries
let query = query.from(users_table)
  |> query.select([expr.field("id"), expr.field("name")])
  |> query.where_(expr.gt(expr.field("age"), expr.value("18")))
  |> query.limit(10)

// 4. Execute with repo
let sql = query.to_sql(query)
case repo.execute_sql(repo, sql) {
  Ok(result) -> // parse result
  Error(err) -> // handle error
}
```

## Related examples
- `docs/examples/schema_examples.md`
- `docs/examples/types_examples.md`
- `docs/examples/decode_examples.md`
