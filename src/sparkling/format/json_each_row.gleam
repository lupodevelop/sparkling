/// JSONEachRow format handler - default ClickHouse JSON format.
/// Each row is a separate JSON object on its own line.
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/string
import sparkling/decode as sparkling_decode
import sparkling/format/registry

/// Create JSONEachRow format handler.
pub fn handler() -> registry.FormatHandler {
  registry.FormatHandler(name: "JSONEachRow", encode: encode, decode: do_decode)
}

/// Encode list of records to JSONEachRow format (one JSON object per line).
fn encode(records: List(Dict(String, json.Json))) -> Result(String, String) {
  records
  |> list.map(fn(record) {
    json.object(dict.to_list(record))
    |> json.to_string
  })
  |> string.join("\n")
  |> Ok
}

/// Decode JSONEachRow format to list of records.
fn do_decode(data: String) -> Result(List(Dict(String, json.Json)), String) {
  data
  |> string.split("\n")
  |> list.filter(fn(line) { !string.is_empty(string.trim(line)) })
  |> list.index_map(fn(line, index) { #(line, index) })
  |> list.try_map(decode_line)
}

fn decode_line(
  line_with_index: #(String, Int),
) -> Result(Dict(String, json.Json), String) {
  let #(line, index) = line_with_index

  case json.parse(from: line, using: decode.dynamic) {
    Ok(dynamic_value) -> {
      case sparkling_decode.dynamic_to_string_json_dict(dynamic_value) {
        Ok(d) -> Ok(d)
        Error(_) ->
          Error(
            "Line "
            <> int.to_string(index + 1)
            <> ": Not a JSON object - "
            <> string_excerpt(line, 100),
          )
      }
    }
    Error(_) ->
      Error(
        "Line "
        <> int.to_string(index + 1)
        <> ": Invalid JSON - "
        <> string_excerpt(line, 100),
      )
  }
}

fn string_excerpt(str: String, max_len: Int) -> String {
  case string.length(str) > max_len {
    True -> string.slice(str, 0, max_len) <> "..."
    False -> str
  }
}
