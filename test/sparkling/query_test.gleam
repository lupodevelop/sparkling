import gleam/option.{Some}
import gleeunit
import gleeunit/should
import sparkling/expr
import sparkling/query.{
  distinct, from, group_by, having, limit, new, offset, order_by_asc,
  order_by_desc, select, select_expr, to_sql, where, where_all,
}

pub fn main() {
  gleeunit.main()
}

// Test: basic SELECT with FROM
pub fn basic_select_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id"), expr.field("name")])

  to_sql(q) |> should.be_ok |> should.equal("SELECT id, name FROM users")
}

// Test: SELECT with single expression helper
pub fn select_expr_test() {
  let q =
    new()
    |> from("users")
    |> select_expr(expr.field("id"))
    |> select_expr(expr.field("name"))

  to_sql(q) |> should.be_ok |> should.equal("SELECT id, name FROM users")
}

// Test: SELECT with WHERE
pub fn select_with_where_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id"), expr.field("name")])
    |> where(expr.eq(expr.field("active"), expr.bool(True)))

  to_sql(q)
  |> should.be_ok
  |> should.equal("SELECT id, name FROM users WHERE active = true")
}

// Test: SELECT with multiple WHERE conditions (AND-ed)
pub fn select_with_multiple_where_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id")])
    |> where(expr.gt(expr.field("age"), expr.int(18)))
    |> where(expr.eq(expr.field("active"), expr.bool(True)))

  to_sql(q)
  |> should.be_ok
  |> should.equal("SELECT id FROM users WHERE (age > 18 AND active = true)")
}

// Test: SELECT with where_all
pub fn select_with_where_all_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id")])
    |> where_all([
      expr.gt(expr.field("age"), expr.int(18)),
      expr.eq(expr.field("active"), expr.bool(True)),
    ])

  to_sql(q)
  |> should.be_ok
  |> should.equal("SELECT id FROM users WHERE (age > 18 AND active = true)")
}

// Test: SELECT with ORDER BY ASC
pub fn select_with_order_by_asc_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id"), expr.field("name")])
    |> order_by_asc(expr.field("name"))

  to_sql(q)
  |> should.be_ok
  |> should.equal("SELECT id, name FROM users ORDER BY name ASC")
}

// Test: SELECT with ORDER BY DESC
pub fn select_with_order_by_desc_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id"), expr.field("name")])
    |> order_by_desc(expr.field("created_at"))

  to_sql(q)
  |> should.be_ok
  |> should.equal("SELECT id, name FROM users ORDER BY created_at DESC")
}

// Test: SELECT with multiple ORDER BY
pub fn select_with_multiple_order_by_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id")])
    |> order_by_asc(expr.field("name"))
    |> order_by_desc(expr.field("age"))

  to_sql(q)
  |> should.be_ok
  |> should.equal("SELECT id FROM users ORDER BY name ASC, age DESC")
}

// Test: SELECT with LIMIT
pub fn select_with_limit_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id")])
    |> limit(10)

  to_sql(q) |> should.be_ok |> should.equal("SELECT id FROM users LIMIT 10")
}

// Test: SELECT with OFFSET
pub fn select_with_offset_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id")])
    |> offset(20)

  to_sql(q) |> should.be_ok |> should.equal("SELECT id FROM users OFFSET 20")
}

// Test: SELECT with LIMIT and OFFSET
pub fn select_with_limit_and_offset_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id")])
    |> limit(10)
    |> offset(20)

  to_sql(q)
  |> should.be_ok
  |> should.equal("SELECT id FROM users LIMIT 10 OFFSET 20")
}

// Test: SELECT DISTINCT
pub fn select_distinct_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("country")])
    |> distinct()

  to_sql(q)
  |> should.be_ok
  |> should.equal("SELECT DISTINCT country FROM users")
}

// Test: SELECT with GROUP BY
pub fn select_with_group_by_test() {
  let q =
    new()
    |> from("orders")
    |> select([expr.field("user_id"), expr.count_all()])
    |> group_by([expr.field("user_id")])

  to_sql(q)
  |> should.be_ok
  |> should.equal("SELECT user_id, COUNT(*) FROM orders GROUP BY user_id")
}

// Test: SELECT with GROUP BY and HAVING
pub fn select_with_group_by_having_test() {
  let q =
    new()
    |> from("orders")
    |> select([expr.field("user_id"), expr.count_all()])
    |> group_by([expr.field("user_id")])
    |> having(expr.gt(expr.count_all(), expr.int(5)))

  to_sql(q)
  |> should.be_ok
  |> should.equal(
    "SELECT user_id, COUNT(*) FROM orders GROUP BY user_id HAVING COUNT(*) > 5",
  )
}

// Test: Complex query with all clauses
pub fn complex_query_test() {
  let q =
    new()
    |> from("orders")
    |> select([
      expr.field("user_id"),
      expr.alias(expr.Sum(expr.field("amount")), "total"),
    ])
    |> where(expr.gt(expr.field("amount"), expr.int(0)))
    |> where(expr.eq(expr.field("status"), expr.string("completed")))
    |> group_by([expr.field("user_id")])
    |> having(expr.gt(expr.Sum(expr.field("amount")), expr.int(100)))
    |> order_by_desc(expr.Sum(expr.field("amount")))
    |> limit(10)

  to_sql(q)
  |> should.be_ok
  |> should.equal(
    "SELECT user_id, SUM(amount) AS total FROM orders WHERE (amount > 0 AND status = 'completed') GROUP BY user_id HAVING SUM(amount) > 100 ORDER BY SUM(amount) DESC LIMIT 10",
  )
}

// Test: Query with aggregate functions
pub fn query_with_aggregates_test() {
  let q =
    new()
    |> from("sales")
    |> select([
      expr.alias(expr.count_all(), "count"),
      expr.alias(expr.Sum(expr.field("revenue")), "total_revenue"),
      expr.alias(expr.Max(expr.field("price")), "max_price"),
    ])

  to_sql(q)
  |> should.be_ok
  |> should.equal(
    "SELECT COUNT(*) AS count, SUM(revenue) AS total_revenue, MAX(price) AS max_price FROM sales",
  )
}

// Test: Query with reserved keyword table name (should be escaped)
pub fn query_with_reserved_table_name_test() {
  let q =
    new()
    |> from("select")
    |> select([expr.field("id")])

  to_sql(q)
  |> should.be_ok
  |> should.equal("SELECT id FROM `select`")
}

// Test: Error when FROM is missing
pub fn error_missing_from_test() {
  let q = new() |> select([expr.field("id")])

  to_sql(q) |> should.be_error |> should.equal("Query must have a FROM clause")
}

// Test: Error when SELECT is missing
pub fn error_missing_select_test() {
  let q = new() |> from("users")

  to_sql(q)
  |> should.be_error
  |> should.equal("Query must have at least one SELECT expression")
}

// Test: Query with function calls
pub fn query_with_function_calls_test() {
  let q =
    new()
    |> from("events")
    |> select([
      expr.field("id"),
      expr.FunctionCall("toDate", [expr.field("event_time")]),
    ])
    |> where(expr.eq(
      expr.FunctionCall("toYear", [expr.field("event_time")]),
      expr.int(2023),
    ))

  to_sql(q)
  |> should.be_ok
  |> should.equal(
    "SELECT id, toDate(event_time) FROM events WHERE toYear(event_time) = 2023",
  )
}

// Test: Query with CASE expression
pub fn query_with_case_expression_test() {
  let q =
    new()
    |> from("users")
    |> select([
      expr.field("id"),
      expr.Case(
        Some(expr.field("status")),
        [
          #(expr.string("active"), expr.int(1)),
          #(expr.string("inactive"), expr.int(0)),
        ],
        Some(expr.int(-1)),
      ),
    ])

  to_sql(q)
  |> should.be_ok
  |> should.equal(
    "SELECT id, CASE status WHEN 'active' THEN 1 WHEN 'inactive' THEN 0 ELSE -1 END FROM users",
  )
}

// Test: Query with IN operator
pub fn query_with_in_operator_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id"), expr.field("name")])
    |> where(
      expr.In(expr.field("status"), [
        expr.string("active"),
        expr.string("pending"),
      ]),
    )

  to_sql(q)
  |> should.be_ok
  |> should.equal(
    "SELECT id, name FROM users WHERE status IN ('active', 'pending')",
  )
}

// Test: Query with BETWEEN
pub fn query_with_between_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id")])
    |> where(expr.Between(expr.field("age"), expr.int(18), expr.int(65)))

  to_sql(q)
  |> should.be_ok
  |> should.equal("SELECT id FROM users WHERE age BETWEEN 18 AND 65")
}

// Test: Query with IS NULL
pub fn query_with_is_null_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id")])
    |> where(expr.IsNull(expr.field("deleted_at")))

  to_sql(q)
  |> should.be_ok
  |> should.equal("SELECT id FROM users WHERE deleted_at IS NULL")
}

// Test: Method chaining (fluent interface)
pub fn method_chaining_test() {
  let q =
    new()
    |> from("users")
    |> select([expr.field("id")])
    |> where(expr.gt(expr.field("age"), expr.int(18)))
    |> order_by_asc(expr.field("name"))
    |> limit(10)

  to_sql(q)
  |> should.be_ok
  |> should.equal(
    "SELECT id FROM users WHERE age > 18 ORDER BY name ASC LIMIT 10",
  )
}
