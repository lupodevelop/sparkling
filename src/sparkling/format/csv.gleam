/// CSV format handler - comma-separated values with RFC 4180 quoting.
import gleam/dict.{type Dict}
import gleam/int
import gleam/json
import gleam/list
import gleam/string
import sparkling/format/registry

/// Create CSV format handler.
pub fn handler() -> registry.FormatHandler {
  registry.FormatHandler(name: "CSV", encode: encode, decode: decode)
}

/// Encode list of records to CSV format (header row + data rows).
fn encode(records: List(Dict(String, json.Json))) -> Result(String, String) {
  case records {
    [] -> Ok("")
    [first, ..] -> {
      let keys = dict.keys(first)
      // Column names go as plain strings in the header (not JSON-encoded)
      let header = keys |> list.map(csv_escape_string) |> string.join(",")
      let rows =
        records
        |> list.map(fn(record) { encode_record_csv(record, keys) })
        |> string.join("\n")
      Ok(header <> "\n" <> rows)
    }
  }
}

/// Encode single record to CSV row (values extracted from json.Json).
fn encode_record_csv(
  record: Dict(String, json.Json),
  keys: List(String),
) -> String {
  keys
  |> list.map(fn(key) {
    let value = case dict.get(record, key) {
      Ok(v) -> json_to_plain_string(v)
      Error(_) -> ""
    }
    csv_escape_string(value)
  })
  |> string.join(",")
}

/// Extract a plain string representation from a json.Json value.
/// JSON strings are unwrapped (quotes removed); other types use their
/// JSON representation (e.g. 42, true, null).
fn json_to_plain_string(value: json.Json) -> String {
  let s = json.to_string(value)
  // JSON strings are wrapped in double-quotes: strip them
  case
    string.starts_with(s, "\"")
    && string.ends_with(s, "\"")
    && string.length(s) >= 2
  {
    True -> string.slice(s, 1, string.length(s) - 2)
    False -> s
  }
}

/// Escape a plain string for CSV: wrap in double-quotes if it contains
/// commas, double-quotes, or newlines. Double-quotes inside are doubled ("").
fn csv_escape_string(s: String) -> String {
  case
    string.contains(s, ",")
    || string.contains(s, "\"")
    || string.contains(s, "\n")
    || string.contains(s, "\r")
  {
    True -> "\"" <> string.replace(s, "\"", "\"\"") <> "\""
    False -> s
  }
}

/// Decode CSV format to list of records.
/// First row is the header (column names); subsequent rows are data.
fn decode(data: String) -> Result(List(Dict(String, json.Json)), String) {
  let lines =
    data
    |> string.split("\n")
    |> list.filter(fn(line) { !string.is_empty(string.trim(line)) })

  case lines {
    [] -> Ok([])
    [header, ..rows] -> {
      case parse_csv_row(header) {
        Ok(keys) ->
          rows
          |> list.index_map(fn(row, index) { #(row, index) })
          |> list.try_map(fn(row_with_index) {
            decode_csv_row(row_with_index, keys)
          })
        Error(err) -> Error("Header parse error: " <> err)
      }
    }
  }
}

fn decode_csv_row(
  row_with_index: #(String, Int),
  keys: List(String),
) -> Result(Dict(String, json.Json), String) {
  let #(row, index) = row_with_index

  case parse_csv_row(row) {
    Ok(values) -> {
      case list.length(values) == list.length(keys) {
        True ->
          list.zip(keys, values)
          |> list.map(fn(pair) { #(pair.0, json.string(pair.1)) })
          |> dict.from_list
          |> Ok
        False ->
          Error("Row " <> int.to_string(index + 1) <> ": Column count mismatch")
      }
    }
    Error(err) -> Error("Row " <> int.to_string(index + 1) <> ": " <> err)
  }
}

/// Parse a CSV row according to RFC 4180.
/// Handles quoted fields (with embedded commas, newlines, and escaped quotes "").
fn parse_csv_row(row: String) -> Result(List(String), String) {
  do_parse_csv(string.to_graphemes(row), False, "", [])
}

fn do_parse_csv(
  chars: List(String),
  in_quotes: Bool,
  current: String,
  acc: List(String),
) -> Result(List(String), String) {
  case chars, in_quotes {
    // End of input
    [], False -> Ok(list.reverse([current, ..acc]))
    [], True -> Error("Unterminated quoted field")
    // Two consecutive quotes inside a quoted field → escaped quote char
    ["\"", "\"", ..rest], True ->
      do_parse_csv(rest, True, current <> "\"", acc)
    // Opening quote (start of a quoted field)
    ["\"", ..rest], False ->
      do_parse_csv(rest, True, current, acc)
    // Closing quote
    ["\"", ..rest], True ->
      do_parse_csv(rest, False, current, acc)
    // Field separator (outside quotes)
    [",", ..rest], False ->
      do_parse_csv(rest, False, "", [current, ..acc])
    // Any other character
    [c, ..rest], _ ->
      do_parse_csv(rest, in_quotes, current <> c, acc)
  }
}
