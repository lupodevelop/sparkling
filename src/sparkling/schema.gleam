/// Schema definition for ClickHouse tables and fields.
///
/// This module provides typed representations of ClickHouse tables and columns,
/// supporting the major ClickHouse data types and nullable/array wrappers.
///
/// See: https://clickhouse.com/docs/en/sql-reference/data-types/
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/string
import sparkling/expr

/// ClickHouse field types supported by sparkling.
pub type FieldType {
  // Integer types
  UInt8
  UInt16
  UInt32
  UInt64
  Int8
  Int16
  Int32
  Int64

  // Floating point
  Float32
  Float64

  // String types
  String
  FixedString(size: Int)

  // Date/Time types
  Date
  Date32
  DateTime
  DateTime64(precision: Int)

  // Decimal (precision, scale)
  Decimal(precision: Int, scale: Int)

  // Boolean
  Bool

  // UUID
  UUID

  // Nullable wrapper
  Nullable(of: FieldType)

  // Array
  Array(of: FieldType)

  // LowCardinality wrapper (optimization)
  LowCardinality(of: FieldType)

  // JSON (experimental in ClickHouse)
  JSON

  // Tuple (fixed-size heterogeneous)
  Tuple(fields: List(FieldType))

  // Enum8/Enum16 (represented as name-value pairs)
  Enum8(values: List(#(String, Int)))
  Enum16(values: List(#(String, Int)))
}

/// A field (column) definition in a ClickHouse table.
pub type Field {
  Field(name: String, typ: FieldType)
}

/// A table definition with name and fields.
pub type Table {
  Table(name: String, fields: List(Field))
}

/// Create a new table definition.
pub fn table(name: String, fields: List(Field)) -> Table {
  Table(name: name, fields: fields)
}

/// Create a new field definition.
pub fn field(name: String, typ: FieldType) -> Field {
  Field(name: name, typ: typ)
}

/// Get the SQL representation of a field type for CREATE TABLE DDL.
pub fn field_type_to_sql(typ: FieldType) -> String {
  case typ {
    UInt8 -> "UInt8"
    UInt16 -> "UInt16"
    UInt32 -> "UInt32"
    UInt64 -> "UInt64"
    Int8 -> "Int8"
    Int16 -> "Int16"
    Int32 -> "Int32"
    Int64 -> "Int64"
    Float32 -> "Float32"
    Float64 -> "Float64"
    String -> "String"
    FixedString(size) -> "FixedString(" <> int.to_string(size) <> ")"
    Date -> "Date"
    Date32 -> "Date32"
    DateTime -> "DateTime"
    DateTime64(precision) -> "DateTime64(" <> int.to_string(precision) <> ")"
    Decimal(precision, scale) ->
      "Decimal("
      <> int.to_string(precision)
      <> ", "
      <> int.to_string(scale)
      <> ")"
    Bool -> "Bool"
    UUID -> "UUID"
    Nullable(of) -> "Nullable(" <> field_type_to_sql(of) <> ")"
    Array(of) -> "Array(" <> field_type_to_sql(of) <> ")"
    LowCardinality(of) -> "LowCardinality(" <> field_type_to_sql(of) <> ")"
    JSON -> "JSON"
    Tuple(fields) -> {
      let inner =
        fields
        |> list.map(field_type_to_sql)
        |> string.join(", ")
      "Tuple(" <> inner <> ")"
    }
    Enum8(values) -> {
      let inner =
        values
        |> list.map(fn(pair) {
          // Escape single quotes in enum labels using SQL double-quote style ('')
          let escaped = string.replace(pair.0, "'", "''")
          "'" <> escaped <> "' = " <> int.to_string(pair.1)
        })
        |> string.join(", ")
      "Enum8(" <> inner <> ")"
    }
    Enum16(values) -> {
      let inner =
        values
        |> list.map(fn(pair) {
          let escaped = string.replace(pair.0, "'", "''")
          "'" <> escaped <> "' = " <> int.to_string(pair.1)
        })
        |> string.join(", ")
      "Enum16(" <> inner <> ")"
    }
  }
}

/// Generate a CREATE TABLE statement for a table definition.
/// Table and field names are properly escaped for ClickHouse.
///
/// Note: This is a minimal DDL generator. For production use, specify engine,
/// partition key, order by, etc., using ClickHouse-specific syntax.
pub fn to_create_table_sql(tbl: Table, engine engine: String) -> String {
  let field_defs =
    tbl.fields
    |> list.map(fn(f) {
      expr.to_sql(expr.Field(f.name)) <> " " <> field_type_to_sql(f.typ)
    })
    |> string.join(", ")

  "CREATE TABLE "
  <> expr.to_sql(expr.Field(tbl.name))
  <> " ("
  <> field_defs
  <> ") ENGINE = "
  <> engine
}

/// Find a field in a table by name.
pub fn find_field(tbl: Table, field_name: String) -> Option(Field) {
  tbl.fields
  |> list.find(fn(f) { f.name == field_name })
  |> option.from_result
}

/// Get all field names from a table.
pub fn field_names(tbl: Table) -> List(String) {
  tbl.fields |> list.map(fn(f) { f.name })
}
