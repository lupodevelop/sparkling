/// Format registry for pluggable encoder/decoder handlers.
/// Allows registration of custom format handlers for different ClickHouse formats.
import gleam/dict.{type Dict}
import gleam/json
import gleam/result
import gleam/string

/// Format handler for a specific ClickHouse format.
/// encode: List(Dict) → serialized string
/// decode: serialized string → List(Dict)
pub type FormatHandler {
  FormatHandler(
    name: String,
    encode: fn(List(Dict(String, json.Json))) -> Result(String, String),
    decode: fn(String) -> Result(List(Dict(String, json.Json)), String),
  )
}

/// Registry of format handlers (opaque).
pub opaque type FormatRegistry {
  FormatRegistry(handlers: Dict(String, FormatHandler))
}

/// Create a new empty format registry.
pub fn new() -> FormatRegistry {
  FormatRegistry(handlers: dict.new())
}

/// Register a format handler. Overwrites any existing handler with the same name.
pub fn register(
  registry: FormatRegistry,
  handler: FormatHandler,
) -> FormatRegistry {
  FormatRegistry(handlers: dict.insert(registry.handlers, handler.name, handler))
}

/// Get a format handler by name. Returns an error string if not found.
pub fn get_handler(
  registry: FormatRegistry,
  format_name: String,
) -> Result(FormatHandler, String) {
  dict.get(registry.handlers, format_name)
  |> result.replace_error(
    "Format '"
    <> format_name
    <> "' not registered. Available: "
    <> available_formats_string(registry),
  )
}

/// List all registered format names.
pub fn list_formats(registry: FormatRegistry) -> List(String) {
  dict.keys(registry.handlers)
}

/// Encode data using the specified format handler.
pub fn encode(
  registry: FormatRegistry,
  format_name: String,
  data: List(Dict(String, json.Json)),
) -> Result(String, String) {
  use handler <- result.try(get_handler(registry, format_name))
  handler.encode(data)
}

/// Decode data using the specified format handler.
pub fn decode(
  registry: FormatRegistry,
  format_name: String,
  data: String,
) -> Result(List(Dict(String, json.Json)), String) {
  use handler <- result.try(get_handler(registry, format_name))
  handler.decode(data)
}

fn available_formats_string(registry: FormatRegistry) -> String {
  case list_formats(registry) {
    [] -> "none"
    formats -> string.join(formats, ", ")
  }
}
