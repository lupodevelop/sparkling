/// Encoding Gleam values to JSON for ClickHouse formats (JSONEachRow, etc.)
/// Uses gleam/json for encoding primitives and supports complex ClickHouse types.
import gleam/dict.{type Dict}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import sparkling/types

/// Encode a record (represented as a Dict) to a JSON object.
/// This is useful for JSONEachRow format where each row is a JSON object.
pub fn encode_record(record: Dict(String, Json)) -> String {
  json.object(dict.to_list(record))
  |> json.to_string
}

/// Encode multiple records to JSONEachRow format (newline-separated JSON objects).
/// Uses efficient string.join for better performance with large batches.
pub fn encode_json_each_row(records: List(Dict(String, Json))) -> String {
  records
  |> list.map(encode_record)
  |> string.join("\n")
}

/// Helper: create a JSON field for a nullable value.
pub fn nullable(value: Option(Json)) -> Json {
  case value {
    Some(v) -> v
    None -> json.null()
  }
}

/// Helper: encode a list of values.
pub fn array(items: List(a), encoder: fn(a) -> Json) -> Json {
  json.array(items, of: encoder)
}

// ============================================================================
// Complex ClickHouse Types Encoders
// ============================================================================

/// Encode Decimal to JSON string (preserves precision)
pub fn decimal(d: types.Decimal) -> Json {
  json.string(types.decimal_to_string(d))
}

/// Encode DateTime64 to JSON string (ISO 8601 format)
pub fn datetime64(dt: types.DateTime64) -> Json {
  json.string(types.datetime64_to_string(dt))
}

/// Generic encoder for maps where keys are strings
pub fn clickhouse_map_from_dict(m: Dict(String, Json)) -> Json {
  m
  |> dict.to_list
  |> list.map(fn(pair) { #(pair.0, pair.1) })
  |> json.object
}

/// Encode Tuple represented as List(Json) to JSON array
pub fn clickhouse_tuple(elements: List(Json)) -> Json {
  json.array(elements, of: fn(x) { x })
}

/// Encode Nested structure represented as Dict(String, Json) to JSON object
pub fn nested_from_dict(fields: Dict(String, Json)) -> Json {
  json.object(dict.to_list(fields))
}

/// Encode UUID to JSON string
pub fn uuid(u: types.UUID) -> Json {
  json.string(types.uuid_to_string(u))
}

/// Encode LowCardinality(String) to JSON string
pub fn low_cardinality_string(lc: types.LowCardinality) -> Json {
  json.string(types.low_cardinality_value(lc))
}

/// Encode Enum by underlying integer value
pub fn enum_value(v: Int) -> Json {
  json.int(v)
}
