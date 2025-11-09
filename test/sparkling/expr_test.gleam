import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import sparkling/expr.{
  Add, And, ArrayLiteral, As, Between, BoolLiteral, Case, Cast, Count, Div, Eq,
  Field, FloatLiteral, FunctionCall, Ge, Gt, In, IntLiteral, IsNotNull, IsNull,
  Le, Lt, Max, Mul, Ne, Not, Null, Or, StringLiteral, Sub, Sum, TupleLiteral,
  alias, and, bool, count_all, eq, field, float, gt, int, lt, ne, not, null, or,
  string, to_sql,
}

pub fn main() {
  gleeunit.main()
}

// Test: literals
pub fn int_literal_test() {
  to_sql(IntLiteral(42)) |> should.equal("42")
  to_sql(int(100)) |> should.equal("100")
}

pub fn float_literal_test() {
  to_sql(FloatLiteral(3.14)) |> should.equal("3.14")
  to_sql(float(2.5)) |> should.equal("2.5")
}

pub fn string_literal_test() {
  to_sql(StringLiteral("hello")) |> should.equal("'hello'")
  to_sql(string("world")) |> should.equal("'world'")
}

pub fn string_escape_test() {
  to_sql(string("it's")) |> should.equal("'it\\'s'")
  to_sql(string("line\\break")) |> should.equal("'line\\\\break'")
}

pub fn bool_literal_test() {
  to_sql(BoolLiteral(True)) |> should.equal("true")
  to_sql(BoolLiteral(False)) |> should.equal("false")
  to_sql(bool(True)) |> should.equal("true")
}

pub fn null_literal_test() {
  to_sql(Null) |> should.equal("NULL")
  to_sql(null()) |> should.equal("NULL")
}

// Test: field references (simple identifiers - no escaping needed)
pub fn field_simple_test() {
  to_sql(Field("id")) |> should.equal("id")
  to_sql(field("email")) |> should.equal("email")
  to_sql(field("user_id")) |> should.equal("user_id")
  to_sql(field("_private")) |> should.equal("_private")
}

// Test: field references with reserved keywords (need escaping)
pub fn field_keyword_test() {
  to_sql(Field("select")) |> should.equal("`select`")
  to_sql(field("from")) |> should.equal("`from`")
  to_sql(field("where")) |> should.equal("`where`")
  to_sql(field("table")) |> should.equal("`table`")
}

// Test: field references with special characters (need escaping)
pub fn field_special_chars_test() {
  to_sql(Field("user-id")) |> should.equal("`user-id`")
  to_sql(field("email@domain")) |> should.equal("`email@domain`")
  to_sql(field("my field")) |> should.equal("`my field`")
  to_sql(field("123abc")) |> should.equal("`123abc`")
  // starts with number
}

// Test: field with backticks in name (double-escape)
pub fn field_with_backticks_test() {
  to_sql(Field("field`name")) |> should.equal("`field``name`")
}

// Test: comparison operators
pub fn eq_test() {
  to_sql(Eq(field("id"), int(1))) |> should.equal("id = 1")
  to_sql(eq(field("name"), string("Alice"))) |> should.equal("name = 'Alice'")
}

pub fn ne_test() {
  to_sql(Ne(field("status"), string("inactive")))
  |> should.equal("status != 'inactive'")
  to_sql(ne(field("count"), int(0))) |> should.equal("count != 0")
}

pub fn lt_test() {
  to_sql(Lt(field("age"), int(30))) |> should.equal("age < 30")
  to_sql(lt(field("price"), float(100.0))) |> should.equal("price < 100.0")
}

pub fn le_test() {
  to_sql(Le(field("age"), int(30))) |> should.equal("age <= 30")
}

pub fn gt_test() {
  to_sql(Gt(field("score"), int(80))) |> should.equal("score > 80")
  to_sql(gt(field("value"), int(10))) |> should.equal("value > 10")
}

pub fn ge_test() {
  to_sql(Ge(field("balance"), float(0.0)))
  |> should.equal("balance >= 0.0")
}

// Test: logical operators
pub fn and_test() {
  to_sql(And(eq(field("active"), bool(True)), gt(field("age"), int(18))))
  |> should.equal("(active = true AND age > 18)")
  to_sql(and(eq(field("x"), int(1)), eq(field("y"), int(2))))
  |> should.equal("(x = 1 AND y = 2)")
}

pub fn or_test() {
  to_sql(Or(
    eq(field("status"), string("new")),
    eq(field("status"), string("pending")),
  ))
  |> should.equal("(status = 'new' OR status = 'pending')")
  to_sql(or(lt(field("age"), int(18)), gt(field("age"), int(65))))
  |> should.equal("(age < 18 OR age > 65)")
}

pub fn not_test() {
  to_sql(Not(eq(field("deleted"), bool(True))))
  |> should.equal("NOT (deleted = true)")
  to_sql(not(eq(field("x"), int(0)))) |> should.equal("NOT (x = 0)")
}

// Test: arithmetic operators
pub fn add_test() {
  to_sql(Add(field("a"), field("b"))) |> should.equal("(a + b)")
}

pub fn sub_test() {
  to_sql(Sub(field("total"), field("discount")))
  |> should.equal("(total - discount)")
}

pub fn mul_test() {
  to_sql(Mul(field("price"), field("quantity")))
  |> should.equal("(price * quantity)")
}

pub fn div_test() {
  to_sql(Div(field("sum"), int(2))) |> should.equal("(sum / 2)")
}

// Test: aggregates
pub fn count_all_test() {
  to_sql(Count(None)) |> should.equal("COUNT(*)")
  to_sql(count_all()) |> should.equal("COUNT(*)")
}

pub fn count_field_test() {
  to_sql(Count(Some(field("id")))) |> should.equal("COUNT(id)")
}

pub fn sum_test() {
  to_sql(Sum(field("amount"))) |> should.equal("SUM(amount)")
}

pub fn max_test() {
  to_sql(Max(field("score"))) |> should.equal("MAX(score)")
}

// Test: function calls
pub fn function_call_test() {
  to_sql(FunctionCall("toDate", [string("2023-01-01")]))
  |> should.equal("toDate('2023-01-01')")
  to_sql(FunctionCall("now", [])) |> should.equal("now()")
  to_sql(FunctionCall("substr", [field("name"), int(1), int(5)]))
  |> should.equal("substr(name, 1, 5)")
}

// Test: array literals
pub fn array_literal_test() {
  to_sql(ArrayLiteral([int(1), int(2), int(3)]))
  |> should.equal("[1, 2, 3]")
  to_sql(ArrayLiteral([string("a"), string("b")]))
  |> should.equal("['a', 'b']")
  to_sql(ArrayLiteral([])) |> should.equal("[]")
}

// Test: tuple literals
pub fn tuple_literal_test() {
  to_sql(TupleLiteral([int(1), string("test")]))
  |> should.equal("(1, 'test')")
  to_sql(TupleLiteral([field("x"), field("y")]))
  |> should.equal("(x, y)")
}

// Test: IN operator
pub fn in_test() {
  to_sql(In(field("status"), [string("active"), string("pending")]))
  |> should.equal("status IN ('active', 'pending')")
  to_sql(In(field("id"), [int(1), int(2), int(3)]))
  |> should.equal("id IN (1, 2, 3)")
}

// Test: BETWEEN operator
pub fn between_test() {
  to_sql(Between(field("age"), int(18), int(65)))
  |> should.equal("age BETWEEN 18 AND 65")
}

// Test: IS NULL / IS NOT NULL
pub fn is_null_test() {
  to_sql(IsNull(field("deleted_at"))) |> should.equal("deleted_at IS NULL")
}

pub fn is_not_null_test() {
  to_sql(IsNotNull(field("email"))) |> should.equal("email IS NOT NULL")
}

// Test: CASE expression
pub fn case_simple_test() {
  to_sql(Case(
    None,
    [#(eq(field("x"), int(1)), string("one"))],
    Some(string("other")),
  ))
  |> should.equal("CASE WHEN x = 1 THEN 'one' ELSE 'other' END")
}

pub fn case_with_expr_test() {
  to_sql(Case(
    Some(field("status")),
    [#(string("active"), int(1)), #(string("inactive"), int(0))],
    None,
  ))
  |> should.equal("CASE status WHEN 'active' THEN 1 WHEN 'inactive' THEN 0 END")
}

// Test: CAST
pub fn cast_test() {
  to_sql(Cast(field("id"), "String")) |> should.equal("CAST(id AS String)")
  to_sql(Cast(string("123"), "UInt64"))
  |> should.equal("CAST('123' AS UInt64)")
}

// Test: AS (alias)
pub fn alias_test() {
  to_sql(As(field("user_id"), "uid")) |> should.equal("user_id AS uid")
  to_sql(alias(Count(None), "total")) |> should.equal("COUNT(*) AS total")
}

// Test: complex nested expressions
pub fn complex_nested_test() {
  // (age > 18 AND status = 'active') OR (role = 'admin')
  let expr =
    or(
      and(gt(field("age"), int(18)), eq(field("status"), string("active"))),
      eq(field("role"), string("admin")),
    )

  to_sql(expr)
  |> should.equal("((age > 18 AND status = 'active') OR role = 'admin')")
}

pub fn arithmetic_nested_test() {
  // (price * quantity) - discount
  let expr = Sub(Mul(field("price"), field("quantity")), field("discount"))

  to_sql(expr)
  |> should.equal("((price * quantity) - discount)")
}

// Test: edge cases
pub fn empty_array_test() {
  to_sql(ArrayLiteral([])) |> should.equal("[]")
}

pub fn empty_tuple_test() {
  to_sql(TupleLiteral([])) |> should.equal("()")
}

pub fn nested_array_test() {
  // Array of arrays
  to_sql(ArrayLiteral([ArrayLiteral([int(1), int(2)]), ArrayLiteral([int(3)])]))
  |> should.equal("[[1, 2], [3]]")
}
