/// Immutable query builder for constructing SELECT queries in a type-safe way.
/// Follows the design pattern of Ecto.Query with method chaining for ClickHouse.
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import sparkling/expr.{type Expr}

/// Represents a SELECT query with various clauses.
/// All fields are optional to support incremental query building.
pub type Query {
  Query(
    from: Option(String),
    select: List(Expr),
    where: List(Expr),
    group_by: List(Expr),
    having: List(Expr),
    order_by: List(OrderBy),
    limit: Option(Int),
    offset: Option(Int),
    distinct: Bool,
  )
}

/// Order by clause with direction.
pub type OrderBy {
  OrderBy(expr: Expr, direction: OrderDirection)
}

/// Sort direction for ORDER BY.
pub type OrderDirection {
  Asc
  Desc
}

/// Create a new empty query.
pub fn new() -> Query {
  Query(
    from: None,
    select: [],
    where: [],
    group_by: [],
    having: [],
    order_by: [],
    limit: None,
    offset: None,
    distinct: False,
  )
}

/// Set the FROM clause (table name).
pub fn from(query: Query, table: String) -> Query {
  Query(..query, from: Some(table))
}

/// Add expressions to the SELECT clause.
/// Can be called multiple times to add more expressions.
pub fn select(query: Query, exprs: List(Expr)) -> Query {
  Query(..query, select: list.append(query.select, exprs))
}

/// Add a single expression to the SELECT clause.
pub fn select_expr(query: Query, expr: Expr) -> Query {
  Query(..query, select: list.append(query.select, [expr]))
}

/// Add a WHERE condition (AND-ed with existing conditions).
pub fn where(query: Query, condition: Expr) -> Query {
  Query(..query, where: list.append(query.where, [condition]))
}

/// Add multiple WHERE conditions (AND-ed with existing conditions).
pub fn where_all(query: Query, conditions: List(Expr)) -> Query {
  Query(..query, where: list.append(query.where, conditions))
}

/// Add expressions to the GROUP BY clause.
pub fn group_by(query: Query, exprs: List(Expr)) -> Query {
  Query(..query, group_by: list.append(query.group_by, exprs))
}

/// Add a HAVING condition (AND-ed with existing HAVING conditions).
pub fn having(query: Query, condition: Expr) -> Query {
  Query(..query, having: list.append(query.having, [condition]))
}

/// Add an ORDER BY clause.
pub fn order_by(query: Query, expr: Expr, direction: OrderDirection) -> Query {
  let order = OrderBy(expr, direction)
  Query(..query, order_by: list.append(query.order_by, [order]))
}

/// Add an ORDER BY ASC clause.
pub fn order_by_asc(query: Query, expr: Expr) -> Query {
  order_by(query, expr, Asc)
}

/// Add an ORDER BY DESC clause.
pub fn order_by_desc(query: Query, expr: Expr) -> Query {
  order_by(query, expr, Desc)
}

/// Set the LIMIT clause.
pub fn limit(query: Query, count: Int) -> Query {
  Query(..query, limit: Some(count))
}

/// Set the OFFSET clause.
pub fn offset(query: Query, count: Int) -> Query {
  Query(..query, offset: Some(count))
}

/// Set DISTINCT flag.
pub fn distinct(query: Query) -> Query {
  Query(..query, distinct: True)
}

/// Convert a Query to a SQL string for ClickHouse.
/// Validates that required clauses (FROM, SELECT) are present.
pub fn to_sql(query: Query) -> Result(String, String) {
  // Validate required clauses
  case query.from {
    None -> Error("Query must have a FROM clause")
    Some(_) ->
      case query.select {
        [] -> Error("Query must have at least one SELECT expression")
        _ -> Ok(build_sql(query))
      }
  }
}

/// Build the SQL string from a validated query.
fn build_sql(query: Query) -> String {
  let assert Some(table) = query.from

  // SELECT clause
  let select_clause = case query.distinct {
    True -> "SELECT DISTINCT "
    False -> "SELECT "
  }

  let select_exprs = list.map(query.select, expr.to_sql) |> string.join(", ")

  // FROM clause
  let from_clause = " FROM " <> escape_table_name(table)

  // WHERE clause
  let where_clause = case query.where {
    [] -> ""
    conditions -> {
      let combined = combine_conditions_with_and(conditions)
      " WHERE " <> expr.to_sql(combined)
    }
  }

  // GROUP BY clause
  let group_by_clause = case query.group_by {
    [] -> ""
    exprs -> {
      let exprs_sql = list.map(exprs, expr.to_sql) |> string.join(", ")
      " GROUP BY " <> exprs_sql
    }
  }

  // HAVING clause
  let having_clause = case query.having {
    [] -> ""
    conditions -> {
      let combined = combine_conditions_with_and(conditions)
      " HAVING " <> expr.to_sql(combined)
    }
  }

  // ORDER BY clause
  let order_by_clause = case query.order_by {
    [] -> ""
    orders -> {
      let orders_sql =
        list.map(orders, fn(order) {
          let direction_str = case order.direction {
            Asc -> " ASC"
            Desc -> " DESC"
          }
          expr.to_sql(order.expr) <> direction_str
        })
        |> string.join(", ")
      " ORDER BY " <> orders_sql
    }
  }

  // LIMIT clause
  let limit_clause = case query.limit {
    None -> ""
    Some(n) -> " LIMIT " <> string.inspect(n)
  }

  // OFFSET clause
  let offset_clause = case query.offset {
    None -> ""
    Some(n) -> " OFFSET " <> string.inspect(n)
  }

  select_clause
  <> select_exprs
  <> from_clause
  <> where_clause
  <> group_by_clause
  <> having_clause
  <> order_by_clause
  <> limit_clause
  <> offset_clause
}

/// Combine multiple conditions with AND.
fn combine_conditions_with_and(conditions: List(Expr)) -> Expr {
  case conditions {
    [] -> expr.bool(True)
    [single] -> single
    [first, ..rest] -> {
      list.fold(rest, first, fn(acc, condition) { expr.and(acc, condition) })
    }
  }
}

/// Escape a table name for ClickHouse.
/// Uses the same logic as expr.escape_identifier (via Field).
fn escape_table_name(name: String) -> String {
  expr.to_sql(expr.Field(name))
}
