import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import sparkling/schema.{
  Array, Bool, Date, DateTime, DateTime64, Decimal, Enum16, Enum8, FixedString,
  Float32, Float64, Int32, Int64, LowCardinality, Nullable, String, Tuple,
  UInt32, UInt64, UUID, field, field_names, field_type_to_sql, find_field, table,
  to_create_table_sql,
}

pub fn main() {
  gleeunit.main()
}

// Test: creating a table and field
pub fn table_creation_test() {
  let tbl =
    table("users", [
      field("id", UInt64),
      field("email", String),
      field("created_at", DateTime64(3)),
    ])

  tbl.name |> should.equal("users")
  tbl.fields |> list.length |> should.equal(3)
}

// Test: field_type_to_sql for simple types
pub fn field_type_to_sql_simple_test() {
  field_type_to_sql(UInt32) |> should.equal("UInt32")
  field_type_to_sql(Int64) |> should.equal("Int64")
  field_type_to_sql(Float32) |> should.equal("Float32")
  field_type_to_sql(String) |> should.equal("String")
  field_type_to_sql(Bool) |> should.equal("Bool")
  field_type_to_sql(UUID) |> should.equal("UUID")
  field_type_to_sql(Date) |> should.equal("Date")
  field_type_to_sql(DateTime) |> should.equal("DateTime")
}

// Test: field_type_to_sql for DateTime64
pub fn field_type_to_sql_datetime64_test() {
  field_type_to_sql(DateTime64(3)) |> should.equal("DateTime64(3)")
  field_type_to_sql(DateTime64(6)) |> should.equal("DateTime64(6)")
}

// Test: field_type_to_sql for Decimal
pub fn field_type_to_sql_decimal_test() {
  field_type_to_sql(Decimal(18, 2)) |> should.equal("Decimal(18, 2)")
  field_type_to_sql(Decimal(10, 4)) |> should.equal("Decimal(10, 4)")
}

// Test: field_type_to_sql for Nullable
pub fn field_type_to_sql_nullable_test() {
  field_type_to_sql(Nullable(of: String)) |> should.equal("Nullable(String)")
  field_type_to_sql(Nullable(of: UInt64)) |> should.equal("Nullable(UInt64)")
}

// Test: field_type_to_sql for Array
pub fn field_type_to_sql_array_test() {
  field_type_to_sql(Array(of: Int32)) |> should.equal("Array(Int32)")
  field_type_to_sql(Array(of: String)) |> should.equal("Array(String)")
  field_type_to_sql(Array(of: Nullable(of: UInt32)))
  |> should.equal("Array(Nullable(UInt32))")
}

// Test: field_type_to_sql for LowCardinality
pub fn field_type_to_sql_lowcardinality_test() {
  field_type_to_sql(LowCardinality(of: String))
  |> should.equal("LowCardinality(String)")
}

// Test: field_type_to_sql for Tuple
pub fn field_type_to_sql_tuple_test() {
  field_type_to_sql(Tuple([UInt32, String]))
  |> should.equal("Tuple(UInt32, String)")
  field_type_to_sql(Tuple([Int64, Float64, Bool]))
  |> should.equal("Tuple(Int64, Float64, Bool)")
}

// Test: field_type_to_sql for Enum8
pub fn field_type_to_sql_enum8_test() {
  field_type_to_sql(Enum8([#("active", 1), #("inactive", 2)]))
  |> should.equal("Enum8('active' = 1, 'inactive' = 2)")
}

// Test: field_type_to_sql for Enum16
pub fn field_type_to_sql_enum16_test() {
  field_type_to_sql(Enum16([#("status_ok", 1), #("status_error", 2)]))
  |> should.equal("Enum16('status_ok' = 1, 'status_error' = 2)")
}

// Test: field_type_to_sql for FixedString
pub fn field_type_to_sql_fixedstring_test() {
  field_type_to_sql(FixedString(16)) |> should.equal("FixedString(16)")
}

// Test: to_create_table_sql
pub fn to_create_table_sql_test() {
  let tbl =
    table("events", [
      field("id", UInt64),
      field("event_type", String),
      field("timestamp", DateTime64(3)),
    ])

  let sql = to_create_table_sql(tbl, engine: "MergeTree()")
  sql
  |> should.equal(
    "CREATE TABLE events (id UInt64, event_type String, timestamp DateTime64(3)) ENGINE = MergeTree()",
  )
}

// Test: find_field success
pub fn find_field_success_test() {
  let tbl = table("users", [field("id", UInt64), field("name", String)])

  case find_field(tbl, "id") {
    Some(f) -> {
      f.name |> should.equal("id")
      f.typ |> should.equal(UInt64)
    }
    None -> should.fail()
  }
}

// Test: find_field not found
pub fn find_field_not_found_test() {
  let tbl = table("users", [field("id", UInt64)])

  find_field(tbl, "unknown") |> should.equal(None)
}

// Test: field_names
pub fn field_names_test() {
  let tbl =
    table("users", [
      field("id", UInt64),
      field("email", String),
      field("age", Nullable(of: UInt32)),
    ])

  field_names(tbl) |> should.equal(["id", "email", "age"])
}

// Test: nested nullable array
pub fn nested_nullable_array_test() {
  let typ = Array(of: Nullable(of: String))
  field_type_to_sql(typ) |> should.equal("Array(Nullable(String))")
}

// Test: complex tuple
pub fn complex_tuple_test() {
  let typ = Tuple([UInt64, Nullable(of: String), Array(of: Int32)])
  field_type_to_sql(typ)
  |> should.equal("Tuple(UInt64, Nullable(String), Array(Int32))")
}
