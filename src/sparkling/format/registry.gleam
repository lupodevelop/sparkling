/// Format registry for pluggable encoder/decoder handlers.
/// Allows registration of custom format handlers for different ClickHouse formats.
import gleam/dict.{type Dict}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// Format handler for a specific ClickHouse format
pub type FormatHandler {
  FormatHandler(
    name: String,
    encode: fn(List(Dict(String, json.Json))) -> Result(String, String),
    decode: fn(String) -> Result(List(Dict(String, json.Json)), String),
  )
}

/// Global registry of format handlers
pub opaque type FormatRegistry {
  FormatRegistry(handlers: Dict(String, FormatHandler))
}

/// Create a new empty format registry
pub fn new() -> FormatRegistry {
  FormatRegistry(handlers: dict.new())
}

/// Register a format handler
pub fn register(
  registry: FormatRegistry,
  handler: FormatHandler,
) -> FormatRegistry {
  FormatRegistry(handlers: dict.insert(registry.handlers, handler.name, handler))
}

/// Get a format handler by name
pub fn get_handler(
  registry: FormatRegistry,
  format_name: String,
) -> Option(FormatHandler) {
  case dict.get(registry.handlers, format_name) {
    Ok(handler) -> Some(handler)
    Error(_) -> None
  }
}

/// List all registered format names
pub fn list_formats(registry: FormatRegistry) -> List(String) {
  dict.keys(registry.handlers)
}

/// Encode data using the specified format
pub fn encode(
  registry: FormatRegistry,
  format_name: String,
  data: List(Dict(String, json.Json)),
) -> Result(String, String) {
  case get_handler(registry, format_name) {
    Some(handler) -> handler.encode(data)
    None ->
      Error(
        "Format '"
        <> format_name
        <> "' not registered. Available formats: "
        <> format_list_string(registry),
      )
  }
}

/// Decode data using the specified format
pub fn decode(
  registry: FormatRegistry,
  format_name: String,
  data: String,
) -> Result(List(Dict(String, json.Json)), String) {
  case get_handler(registry, format_name) {
    Some(handler) -> handler.decode(data)
    None ->
      Error(
        "Format '"
        <> format_name
        <> "' not registered. Available formats: "
        <> format_list_string(registry),
      )
  }
}

/// Create default registry with all available format handlers
/// Includes: JSONEachRow, TabSeparated, CSV
pub fn default_registry() -> FormatRegistry {
  new()
  |> register_all_formats
}

/// Register all available format handlers
fn register_all_formats(registry: FormatRegistry) -> FormatRegistry {
  registry
  |> register(json_each_row_handler())
  |> register(tab_separated_handler())
  |> register(csv_handler())
}

/// JSONEachRow format handler
fn json_each_row_handler() -> FormatHandler {
  // Import and use the handler from format/json_each_row module
  // For now, return a minimal handler
  FormatHandler(
    name: "JSONEachRow",
    encode: fn(records) {
      list.map(records, fn(record) {
        json.object(dict.to_list(record))
        |> json.to_string
      })
      |> string.join("\n")
      |> Ok
    },
    decode: fn(_data) {
      // Simplified - actual implementation in format/json_each_row
      Error("Use decode.decode_json_each_row for full functionality")
    },
  )
}

/// TabSeparated format handler
fn tab_separated_handler() -> FormatHandler {
  FormatHandler(
    name: "TabSeparated",
    encode: fn(_records) {
      Error("TabSeparated encoding - use format/tab_separated module")
    },
    decode: fn(_data) {
      Error("TabSeparated decoding - use format/tab_separated module")
    },
  )
}

/// CSV format handler
fn csv_handler() -> FormatHandler {
  FormatHandler(
    name: "CSV",
    encode: fn(_records) { Error("CSV encoding - use format/csv module") },
    decode: fn(_data) { Error("CSV decoding - use format/csv module") },
  )
}

/// Helper to format list of available formats
fn format_list_string(registry: FormatRegistry) -> String {
  case list_formats(registry) {
    [] -> "none"
    formats -> string.join(formats, ", ")
  }
}
