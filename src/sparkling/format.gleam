/// Format handler registry for pluggable encode/decode formats.
/// Allows registration of custom format handlers
/// while providing JSONEachRow as the default format.
import gleam/dict.{type Dict}
import gleam/result

/// Format handler that encodes/decodes data in a specific format
pub type FormatHandler {
  FormatHandler(
    name: String,
    encode: fn(String) -> Result(String, String),
    decode: fn(String) -> Result(String, String),
  )
}

/// Registry of format handlers
pub opaque type FormatRegistry {
  FormatRegistry(handlers: Dict(String, FormatHandler))
}

/// Error type for format operations
pub type FormatError {
  HandlerNotFound(String)
  EncodeError(String)
  DecodeError(String)
}

/// Create a new empty format registry
pub fn new() -> FormatRegistry {
  FormatRegistry(handlers: dict.new())
}

/// Register a format handler in the registry
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
) -> Result(FormatHandler, FormatError) {
  registry.handlers
  |> dict.get(format_name)
  |> result.replace_error(HandlerNotFound(format_name))
}

/// Encode data using the specified format handler
pub fn encode(
  registry: FormatRegistry,
  format_name: String,
  data: String,
) -> Result(String, FormatError) {
  use handler <- result.try(get_handler(registry, format_name))
  handler.encode(data)
  |> result.map_error(EncodeError)
}

/// Decode data using the specified format handler
pub fn decode(
  registry: FormatRegistry,
  format_name: String,
  data: String,
) -> Result(String, FormatError) {
  use handler <- result.try(get_handler(registry, format_name))
  handler.decode(data)
  |> result.map_error(DecodeError)
}

/// List all registered format names
pub fn list_formats(registry: FormatRegistry) -> List(String) {
  dict.keys(registry.handlers)
}

/// Create a default registry with JSONEachRow handler
pub fn default() -> FormatRegistry {
  new()
  |> register(json_each_row_handler())
}

/// JSONEachRow format handler (default for ClickHouse)
/// 
/// This handler expects:
/// - encode: receives a JSONEachRow string (already formatted) and returns it as-is
/// - decode: receives a JSONEachRow string and returns it as-is for further processing
/// 
/// The actual encoding/decoding to Gleam types happens in the encode/decode modules
/// via encode_json_each_row and decode_json_each_row functions.
fn json_each_row_handler() -> FormatHandler {
  FormatHandler(
    name: "JSONEachRow",
    encode: fn(data) {
      // Pass through: assumes data is already in JSONEachRow format
      // (created via encode.encode_json_each_row in user code)
      Ok(data)
    },
    decode: fn(data) {
      // Pass through: returns raw JSONEachRow for user to decode
      // (via decode.decode_json_each_row with custom decoder)
      Ok(data)
    },
  )
}
