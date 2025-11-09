/// TabSeparated format handler - tab-separated values
/// Simple format where fields are separated by tabs, rows by newlines.
import gleam/dict.{type Dict}
import gleam/int
import gleam/json
import gleam/list
import gleam/string
import sparkling/format/registry

/// Create TabSeparated format handler
pub fn handler() -> registry.FormatHandler {
  registry.FormatHandler(name: "TabSeparated", encode: encode, decode: decode)
}

/// Encode list of records to TabSeparated format
/// Note: This assumes all records have the same keys in the same order
fn encode(records: List(Dict(String, json.Json))) -> Result(String, String) {
  case records {
    [] -> Ok("")
    [first, ..] -> {
      let keys = dict.keys(first)

      records
      |> list.map(fn(record) { encode_record(record, keys) })
      |> string.join("\n")
      |> Ok
    }
  }
}

/// Encode single record to tab-separated string
fn encode_record(record: Dict(String, json.Json), keys: List(String)) -> String {
  keys
  |> list.map(fn(key) {
    case dict.get(record, key) {
      Ok(value) -> json_to_simple_string(value)
      Error(_) -> ""
    }
  })
  |> string.join("\t")
}

/// Convert json.Json to simple string representation
fn json_to_simple_string(value: json.Json) -> String {
  // Simplified: just use json.to_string
  // In production, would handle escaping and special characters
  json.to_string(value)
}

/// Decode TabSeparated format to list of records
/// Note: First line is assumed to be header with column names
fn decode(data: String) -> Result(List(Dict(String, json.Json)), String) {
  let lines =
    data
    |> string.split("\n")
    |> list.filter(fn(line) { !string.is_empty(string.trim(line)) })

  case lines {
    [] -> Ok([])
    [header, ..rows] -> {
      let keys = string.split(header, "\t")
      rows
      |> list.index_map(fn(row, index) { #(row, index) })
      |> list.try_map(fn(row_with_index) { decode_row(row_with_index, keys) })
    }
  }
}

/// Decode single row with error context
fn decode_row(
  row_with_index: #(String, Int),
  keys: List(String),
) -> Result(Dict(String, json.Json), String) {
  let #(row, index) = row_with_index
  let values = string.split(row, "\t")

  case list.length(values) == list.length(keys) {
    True -> {
      list.zip(keys, values)
      |> list.map(fn(pair) {
        let #(key, value) = pair
        #(key, json.string(value))
      })
      |> dict.from_list
      |> Ok
    }
    False ->
      Error(
        "Row "
        <> int.to_string(index + 1)
        <> ": Column count mismatch. Expected "
        <> int.to_string(list.length(keys))
        <> ", got "
        <> int.to_string(list.length(values)),
      )
  }
}
