/// Schema definition for ClickHouse tables and fields.
/// 
/// This module provides typed representations of ClickHouse tables and columns,
/// supporting the major ClickHouse data types and nullable/array wrappers.
/// 
/// See: https://clickhouse.com/docs/en/sql-reference/data-types/
import gleam/list
import gleam/option.{type Option}
import gleam/string

/// ClickHouse field types supported by sparkling.
/// Examples: docs/examples/schema_examples.md
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
/// Examples: docs/examples/schema_examples.md
pub fn table(name: String, fields: List(Field)) -> Table {
  Table(name: name, fields: fields)
}

/// Create a new field definition.
/// Examples: docs/examples/schema_examples.md
pub fn field(name: String, typ: FieldType) -> Field {
  Field(name: name, typ: typ)
}

/// Get the SQL representation of a field type for CREATE TABLE DDL.
/// Examples: docs/examples/schema_examples.md
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
    FixedString(size) -> "FixedString(" <> string.inspect(size) <> ")"
    Date -> "Date"
    Date32 -> "Date32"
    DateTime -> "DateTime"
    DateTime64(precision) -> "DateTime64(" <> string.inspect(precision) <> ")"
    Decimal(precision, scale) ->
      "Decimal("
      <> string.inspect(precision)
      <> ", "
      <> string.inspect(scale)
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
          "'" <> pair.0 <> "' = " <> string.inspect(pair.1)
        })
        |> string.join(", ")
      "Enum8(" <> inner <> ")"
    }
    Enum16(values) -> {
      let inner =
        values
        |> list.map(fn(pair) {
          "'" <> pair.0 <> "' = " <> string.inspect(pair.1)
        })
        |> string.join(", ")
      "Enum16(" <> inner <> ")"
    }
  }
}

/// Generate a CREATE TABLE statement for a table definition.
/// 
/// Note: This is a minimal DDL generator. For production use, specify engine,
/// partition key, order by, etc., using ClickHouse-specific syntax.
/// Examples: docs/examples/schema_examples.md
pub fn to_create_table_sql(tbl: Table, engine engine: String) -> String {
  let field_defs =
    tbl.fields
    |> list.map(fn(f) { f.name <> " " <> field_type_to_sql(f.typ) })
    |> string.join(", ")

  "CREATE TABLE " <> tbl.name <> " (" <> field_defs <> ") ENGINE = " <> engine
}

/// Find a field in a table by name.
/// Examples: docs/examples/schema_examples.md
pub fn find_field(tbl: Table, field_name: String) -> Option(Field) {
  tbl.fields
  |> list.find(fn(f) { f.name == field_name })
  |> option.from_result
}

/// Get all field names from a table.
/// Examples: docs/examples/schema_examples.md
pub fn field_names(tbl: Table) -> List(String) {
  tbl.fields |> list.map(fn(f) { f.name })
}
