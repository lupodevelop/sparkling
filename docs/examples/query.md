# Query Builder

`sparkling/query` builds SQL SELECT queries immutably. `query.to_sql` validates and returns `Result(String, String)`.

## Basic SELECT

```gleam
import sparkling/expr
import sparkling/query

let q =
  query.new()
  |> query.from("users")
  |> query.select([expr.field("id"), expr.field("name")])
  |> query.limit(10)

case query.to_sql(q) {
  Ok(sql) -> io.println(sql)
  // => SELECT `id`, `name` FROM `users` LIMIT 10
  Error(msg) -> io.println("invalid query: " <> msg)
}
```

## WHERE conditions

Conditions added with `query.where` are AND-ed together.

```gleam
let q =
  query.new()
  |> query.from("events")
  |> query.select([expr.field("id"), expr.field("type")])
  |> query.where(expr.eq(expr.field("type"), expr.string("click")))
  |> query.where(expr.gt(expr.field("created_at"), expr.string("2024-01-01")))
```

Multiple conditions at once:

```gleam
let q =
  query.new()
  |> query.from("events")
  |> query.where_all([
    expr.eq(expr.field("type"), expr.string("click")),
    expr.gt(expr.field("score"), expr.int(50)),
  ])
```

## GROUP BY and HAVING

```gleam
let q =
  query.new()
  |> query.from("events")
  |> query.select([
    expr.field("user_id"),
    expr.As(expr.count_all(), "total"),
  ])
  |> query.group_by([expr.field("user_id")])
  |> query.having(expr.gt(expr.count_all(), expr.int(5)))
```

## ORDER BY

```gleam
let q =
  query.new()
  |> query.from("users")
  |> query.select([expr.field("id"), expr.field("name")])
  |> query.order_by_desc(expr.field("created_at"))
  |> query.order_by_asc(expr.field("name"))
```

## DISTINCT, LIMIT, OFFSET

```gleam
let q =
  query.new()
  |> query.from("users")
  |> query.select([expr.field("country")])
  |> query.distinct()
  |> query.limit(20)
  |> query.offset(40)
```

## Expressions reference

```gleam
// Literals
expr.int(42)
expr.float(3.14)
expr.string("hello")
expr.bool(True)
expr.null()

// Column reference
expr.field("user_id")

// Comparisons
expr.eq(expr.field("status"), expr.string("active"))
expr.ne(expr.field("status"), expr.string("deleted"))
expr.lt(expr.field("age"), expr.int(18))
expr.le(expr.field("age"), expr.int(18))
expr.gt(expr.field("score"), expr.float(9.5))
expr.ge(expr.field("score"), expr.float(9.5))

// Logical
expr.and(expr.field("a"), expr.field("b"))
expr.or(expr.field("a"), expr.field("b"))
expr.not(expr.field("a"))

// NULL checks
expr.IsNull(expr.field("deleted_at"))
expr.IsNotNull(expr.field("name"))

// IN / BETWEEN
expr.In(expr.field("status"), [expr.string("active"), expr.string("pending")])
expr.Between(expr.field("age"), expr.int(18), expr.int(65))

// Aggregates
expr.count_all()
expr.count(Some(expr.field("user_id")))
expr.Sum(expr.field("amount"))
expr.Avg(expr.field("score"))
expr.Min(expr.field("price"))
expr.Max(expr.field("price"))

// Alias
expr.alias(expr.count_all(), "total")

// Cast
expr.Cast(expr.field("ts"), "DateTime64(3)")

// Arbitrary function call
expr.FunctionCall("toDate", [expr.field("created_at")])
```
