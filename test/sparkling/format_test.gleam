import gleam/list
import gleeunit
import gleeunit/should
import sparkling/format.{
  DecodeError, EncodeError, FormatHandler, HandlerNotFound, decode, default,
  encode, get_handler, list_formats, new, register,
}

pub fn main() {
  gleeunit.main()
}

// Test: create empty registry
pub fn new_registry_test() {
  let registry = new()
  list_formats(registry) |> should.equal([])
}

// Test: register a handler
pub fn register_handler_test() {
  let handler =
    FormatHandler(name: "CSV", encode: fn(data) { Ok(data) }, decode: fn(data) {
      Ok(data)
    })

  let registry = new() |> register(handler)

  list_formats(registry) |> should.equal(["CSV"])
}

// Test: get handler by name
pub fn get_handler_test() {
  let handler =
    FormatHandler(name: "CSV", encode: fn(data) { Ok(data) }, decode: fn(data) {
      Ok(data)
    })

  let registry = new() |> register(handler)

  get_handler(registry, "CSV")
  |> should.be_ok
  |> fn(h) { h.name }
  |> should.equal("CSV")
}

// Test: get non-existent handler
pub fn get_handler_not_found_test() {
  let registry = new()

  get_handler(registry, "NonExistent")
  |> should.be_error
  |> should.equal(HandlerNotFound("NonExistent"))
}

// Test: encode using format handler
pub fn encode_test() {
  let handler =
    FormatHandler(
      name: "CSV",
      encode: fn(data) { Ok("csv:" <> data) },
      decode: fn(data) { Ok(data) },
    )

  let registry = new() |> register(handler)

  encode(registry, "CSV", "test")
  |> should.be_ok
  |> should.equal("csv:test")
}

// Test: encode with non-existent format
pub fn encode_format_not_found_test() {
  let registry = new()

  encode(registry, "CSV", "test")
  |> should.be_error
  |> should.equal(HandlerNotFound("CSV"))
}

// Test: encode error from handler
pub fn encode_error_test() {
  let handler =
    FormatHandler(
      name: "Broken",
      encode: fn(_data) { Error("encoding failed") },
      decode: fn(data) { Ok(data) },
    )

  let registry = new() |> register(handler)

  encode(registry, "Broken", "test")
  |> should.be_error
  |> should.equal(EncodeError("encoding failed"))
}

// Test: decode using format handler
pub fn decode_test() {
  let handler =
    FormatHandler(name: "CSV", encode: fn(data) { Ok(data) }, decode: fn(data) {
      Ok("decoded:" <> data)
    })

  let registry = new() |> register(handler)

  decode(registry, "CSV", "test")
  |> should.be_ok
  |> should.equal("decoded:test")
}

// Test: decode with non-existent format
pub fn decode_format_not_found_test() {
  let registry = new()

  decode(registry, "CSV", "test")
  |> should.be_error
  |> should.equal(HandlerNotFound("CSV"))
}

// Test: decode error from handler
pub fn decode_error_test() {
  let handler =
    FormatHandler(
      name: "Broken",
      encode: fn(data) { Ok(data) },
      decode: fn(_data) { Error("decoding failed") },
    )

  let registry = new() |> register(handler)

  decode(registry, "Broken", "test")
  |> should.be_error
  |> should.equal(DecodeError("decoding failed"))
}

// Test: default registry has JSONEachRow
pub fn default_registry_test() {
  let registry = default()

  list_formats(registry) |> should.equal(["JSONEachRow"])
}

// Test: default registry can encode/decode
pub fn default_registry_encode_decode_test() {
  let registry = default()

  encode(registry, "JSONEachRow", "test")
  |> should.be_ok
  |> should.equal("test")

  decode(registry, "JSONEachRow", "test")
  |> should.be_ok
  |> should.equal("test")
}

// Test: register multiple handlers
pub fn register_multiple_handlers_test() {
  let handler1 =
    FormatHandler(name: "CSV", encode: fn(data) { Ok(data) }, decode: fn(data) {
      Ok(data)
    })

  let handler2 =
    FormatHandler(name: "TSV", encode: fn(data) { Ok(data) }, decode: fn(data) {
      Ok(data)
    })

  let registry =
    new()
    |> register(handler1)
    |> register(handler2)

  let formats = list_formats(registry)
  list.contains(formats, "CSV") |> should.be_true
  list.contains(formats, "TSV") |> should.be_true
}

// Test: overwrite existing handler
pub fn overwrite_handler_test() {
  let handler1 =
    FormatHandler(
      name: "CSV",
      encode: fn(data) { Ok("v1:" <> data) },
      decode: fn(data) { Ok(data) },
    )

  let handler2 =
    FormatHandler(
      name: "CSV",
      encode: fn(data) { Ok("v2:" <> data) },
      decode: fn(data) { Ok(data) },
    )

  let registry =
    new()
    |> register(handler1)
    |> register(handler2)

  encode(registry, "CSV", "test")
  |> should.be_ok
  |> should.equal("v2:test")
}
