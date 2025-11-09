/// CSV format handler - comma-separated values with optional quoting
/// Standard CSV format with comma delimiters and quote escaping.
import gleam/dict.{type Dict}
import gleam/int
import gleam/json
import gleam/list
import gleam/string
import sparkling/format/registry

/// Create CSV format handler
pub fn handler() -> registry.FormatHandler {
  registry.FormatHandler(name: "CSV", encode: encode, decode: decode)
}

/// Encode list of records to CSV format
fn encode(records: List(Dict(String, json.Json))) -> Result(String, String) {
  case records {
    [] -> Ok("")
    [first, ..] -> {
      let keys = dict.keys(first)
      let header = encode_csv_row(list.map(keys, json.string))

      let rows =
        records
        |> list.map(fn(record) { encode_record_csv(record, keys) })
        |> string.join("\n")

      Ok(header <> "\n" <> rows)
    }
  }
}

/// Encode single record to CSV row
fn encode_record_csv(
  record: Dict(String, json.Json),
  keys: List(String),
) -> String {
  keys
  |> list.map(fn(key) {
    case dict.get(record, key) {
      Ok(value) -> value
      Error(_) -> json.string("")
    }
  })
  |> encode_csv_row
}

/// Encode list of json values to CSV row with proper escaping
fn encode_csv_row(values: List(json.Json)) -> String {
  values
  |> list.map(csv_escape)
  |> string.join(",")
}

/// Escape value for CSV format
fn csv_escape(value: json.Json) -> String {
  let str = json.to_string(value)

  // If contains comma, quote, or newline, wrap in quotes and escape quotes
  case
    string.contains(str, ",")
    || string.contains(str, "\"")
    || string.contains(str, "\n")
  {
    True -> {
      let escaped = string.replace(str, "\"", "\"\"")
      "\"" <> escaped <> "\""
    }
    False -> str
  }
}

/// Decode CSV format to list of records
fn decode(data: String) -> Result(List(Dict(String, json.Json)), String) {
  let lines =
    data
    |> string.split("\n")
    |> list.filter(fn(line) { !string.is_empty(string.trim(line)) })

  case lines {
    [] -> Ok([])
    [header, ..rows] -> {
      case parse_csv_row(header) {
        Ok(keys) -> {
          rows
          |> list.index_map(fn(row, index) { #(row, index) })
          |> list.try_map(fn(row_with_index) {
            decode_csv_row(row_with_index, keys)
          })
        }
        Error(err) -> Error("Header parse error: " <> err)
      }
    }
  }
}

/// Decode single CSV row
fn decode_csv_row(
  row_with_index: #(String, Int),
  keys: List(String),
) -> Result(Dict(String, json.Json), String) {
  let #(row, index) = row_with_index

  case parse_csv_row(row) {
    Ok(values) -> {
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
          Error("Row " <> int.to_string(index + 1) <> ": Column count mismatch")
      }
    }
    Error(err) -> Error("Row " <> int.to_string(index + 1) <> ": " <> err)
  }
}

/// Parse CSV row handling quoted values
/// Simplified parser: splits by comma. For RFC 4180 full compliance with quoted fields,
/// escaped quotes, and embedded newlines, use a dedicated CSV parsing library.
fn parse_csv_row(row: String) -> Result(List(String), String) {
  // Basic split by comma - adequate for simple CSV without quoted delimiters
  // For production with complex CSV (quotes, escapes), integrate a proper CSV parser
  Ok(string.split(row, ",") |> list.map(string.trim))
}
