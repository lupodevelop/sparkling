/// Decoding JSON from ClickHouse formats (JSONEachRow, etc.) into Gleam values.
/// Uses gleam/json for parsing and gleam/dynamic/decode for decoding.
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string

/// Decode a single JSON string into a value of type `a` using the provided decoder.
pub fn decode_json(
  json_string: String,
  decoder: decode.Decoder(a),
) -> Result(a, json.DecodeError) {
  json.parse(from: json_string, using: decoder)
}

/// Decode JSONEachRow format (newline-separated JSON objects) into a list of values.
/// Each line is parsed independently and decoded using the provided decoder.
/// Error messages include line index and excerpt (first 100 chars) for large lines.
pub fn decode_json_each_row(
  json_each_row: String,
  decoder: decode.Decoder(a),
) -> Result(List(a), String) {
  json_each_row
  |> string.split("\n")
  |> list.filter(fn(line) { !string.is_empty(string.trim(line)) })
  |> list.index_map(fn(line, index) { #(index, line) })
  |> list.try_map(fn(pair) {
    let #(index, line) = pair
    decode_json(line, decoder)
    |> result.map_error(fn(err) {
      let excerpt = case string.length(line) > 100 {
        True -> string.slice(line, 0, 100) <> "..."
        False -> line
      }
      "Failed to decode line "
      <> int.to_string(index + 1)
      <> ": "
      <> excerpt
      <> " - "
      <> string.inspect(err)
    })
  })
}

/// Decode JSONEachRow format into raw JSON values (List(json.Json)).
/// Useful for debugging, tools, and cases where you don't have a specific decoder.
/// Each line is parsed as json.Json without further type conversion.
pub fn decode_json_each_row_raw(
  json_each_row: String,
) -> Result(List(json.Json), String) {
  json_each_row
  |> string.split("\n")
  |> list.filter(fn(line) { !string.is_empty(string.trim(line)) })
  |> list.index_map(fn(line, index) { #(index, line) })
  |> list.try_map(fn(pair) {
    let #(index, line) = pair
    json.parse(from: line, using: decode.dynamic)
    |> result.map(dynamic_to_json)
    |> result.map_error(fn(err) {
      let excerpt = case string.length(line) > 100 {
        True -> string.slice(line, 0, 100) <> "..."
        False -> line
      }
      "Failed to parse line "
      <> int.to_string(index + 1)
      <> ": "
      <> excerpt
      <> " - "
      <> string.inspect(err)
    })
  })
}

/// Decode JSONEachRow as list of dictionaries (for dynamic access without custom decoder).
/// Useful for tools, debugging, or when schema is not known upfront.
pub fn decode_json_each_row_dict(
  json_each_row: String,
) -> Result(List(Dict(String, json.Json)), String) {
  json_each_row
  |> string.split("\n")
  |> list.filter(fn(line) { !string.is_empty(string.trim(line)) })
  |> list.index_map(fn(line, idx) {
    case json.parse(from: line, using: decode.dynamic) {
      Ok(dyn) -> {
        // Convert dynamic to dict by trying to decode as object
        case dynamic_to_string_json_dict(dyn) {
          Ok(dict) -> Ok(dict)
          Error(_) ->
            Error(
              "Line "
              <> int.to_string(idx + 1)
              <> " is not a JSON object: "
              <> string_preview(line),
            )
        }
      }
      Error(_) ->
        Error(
          "Line "
          <> int.to_string(idx + 1)
          <> " - Invalid JSON: "
          <> string_preview(line),
        )
    }
  })
  |> result.all
}

/// Streaming decoder for JSONEachRow format - processes lines lazily.
/// Calls the callback function for each successfully decoded line.
/// Returns the count of successfully processed lines or an error.
/// 
/// This is memory-efficient for large responses as it doesn't load all data into a list.
/// 
/// Example moved to: docs/examples/decode_examples.md
pub fn decode_json_each_row_streaming(
  json_each_row: String,
  decoder: decode.Decoder(a),
  callback: fn(a) -> Nil,
) -> Result(Int, String) {
  json_each_row
  |> string.split("\n")
  |> list.filter(fn(line) { !string.is_empty(string.trim(line)) })
  |> list.index_fold(Ok(0), fn(acc, line, idx) {
    case acc {
      Error(e) -> Error(e)
      Ok(count) -> {
        case decode_json(line, decoder) {
          Ok(value) -> {
            callback(value)
            Ok(count + 1)
          }
          Error(_err) -> {
            Error(
              "Line "
              <> int.to_string(idx + 1)
              <> " - Failed to decode: "
              <> string_preview(line),
            )
          }
        }
      }
    }
  })
}

// ============================================================================
// Helper functions
// ============================================================================

/// Create a preview string (first 100 characters) for error messages.
fn string_preview(s: String) -> String {
  case string.length(s) > 100 {
    True -> string.slice(s, 0, 100) <> "..."
    False -> s
  }
}

/// Convert Dynamic to Dict(String, json.Json) - for decode_json_each_row_dict.
fn dynamic_to_string_json_dict(
  dyn: Dynamic,
) -> Result(Dict(String, json.Json), Nil) {
  case decode.run(dyn, decode.dict(decode.string, decode.dynamic)) {
    Ok(d) ->
      Ok(
        dict.to_list(d)
        |> list.map(fn(pair) { #(pair.0, dynamic_to_json(pair.1)) })
        |> dict.from_list,
      )
    Error(_) -> Error(Nil)
  }
}

/// Convert Dynamic to json.Json with proper structure preservation.
/// Handles primitives (String, Int, Float, Bool, Null) and complex types (List, Dict).
fn dynamic_to_json(dyn: Dynamic) -> json.Json {
  case dynamic.classify(dyn) {
    "String" -> {
      case decode.run(dyn, decode.string) {
        Ok(s) -> json.string(s)
        Error(_) -> json.null()
      }
    }
    "Int" -> {
      case decode.run(dyn, decode.int) {
        Ok(i) -> json.int(i)
        Error(_) -> json.null()
      }
    }
    "Float" -> {
      case decode.run(dyn, decode.float) {
        Ok(f) -> json.float(f)
        Error(_) -> json.null()
      }
    }
    "Bool" -> {
      case decode.run(dyn, decode.bool) {
        Ok(b) -> json.bool(b)
        Error(_) -> json.null()
      }
    }
    "List" -> {
      case decode.run(dyn, decode.list(decode.dynamic)) {
        Ok(items) -> json.array(items, of: dynamic_to_json)
        Error(_) -> json.array([], of: fn(x) { x })
      }
    }
    "Map" | "Dict" -> {
      case decode.run(dyn, decode.dict(decode.string, decode.dynamic)) {
        Ok(d) ->
          json.object(
            dict.to_list(d)
            |> list.map(fn(pair) { #(pair.0, dynamic_to_json(pair.1)) }),
          )
        Error(_) -> json.object([])
      }
    }
    "Null" | "Nil" -> json.null()
    _ -> json.null()
  }
}
