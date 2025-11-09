import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import sparkling/decode as sparkling_decode
import sparkling/encode

pub fn main() {
  gleeunit.main()
}

// Define a simple User type for testing
pub type User {
  User(id: Int, name: String, email: String, active: Bool)
}

// Test: encode and decode a simple record with primitives
pub fn encode_decode_simple_record_test() {
  let record =
    dict.from_list([
      #("id", json.int(1)),
      #("name", json.string("Alice")),
      #("active", json.bool(True)),
    ])

  let encoded = encode.encode_record(record)

  // Decode it back
  let user_decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    use active <- decode.field("active", decode.bool)
    decode.success(#(id, name, active))
  }

  sparkling_decode.decode_json(encoded, user_decoder)
  |> should.be_ok
  |> should.equal(#(1, "Alice", True))
}

// Test: encode and decode with nullable field
pub fn encode_decode_nullable_test() {
  let record_with_null =
    dict.from_list([
      #("id", json.int(2)),
      #("name", json.string("Bob")),
      #("email", encode.nullable(None)),
    ])

  let encoded = encode.encode_record(record_with_null)

  let decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    use email <- decode.field("email", decode.optional(decode.string))
    decode.success(#(id, name, email))
  }

  sparkling_decode.decode_json(encoded, decoder)
  |> should.be_ok
  |> should.equal(#(2, "Bob", None))
}

// Test: encode and decode with nullable field (Some)
pub fn encode_decode_nullable_some_test() {
  let record_with_value =
    dict.from_list([
      #("id", json.int(3)),
      #("name", json.string("Charlie")),
      #("email", encode.nullable(Some(json.string("charlie@example.com")))),
    ])

  let encoded = encode.encode_record(record_with_value)

  let decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    use email <- decode.field("email", decode.optional(decode.string))
    decode.success(#(id, name, email))
  }

  sparkling_decode.decode_json(encoded, decoder)
  |> should.be_ok
  |> should.equal(#(3, "Charlie", Some("charlie@example.com")))
}

// Test: encode and decode an array
pub fn encode_decode_array_test() {
  let record =
    dict.from_list([
      #("id", json.int(4)),
      #("tags", encode.array(["gleam", "clickhouse", "sql"], json.string)),
    ])

  let encoded = encode.encode_record(record)

  let decoder = {
    use id <- decode.field("id", decode.int)
    use tags <- decode.field("tags", decode.list(decode.string))
    decode.success(#(id, tags))
  }

  sparkling_decode.decode_json(encoded, decoder)
  |> should.be_ok
  |> should.equal(#(4, ["gleam", "clickhouse", "sql"]))
}

// Test: encode and decode JSONEachRow format (multiple records)
pub fn encode_decode_json_each_row_test() {
  let records = [
    dict.from_list([#("id", json.int(1)), #("name", json.string("Alice"))]),
    dict.from_list([#("id", json.int(2)), #("name", json.string("Bob"))]),
    dict.from_list([#("id", json.int(3)), #("name", json.string("Charlie"))]),
  ]

  let encoded = encode.encode_json_each_row(records)

  let decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    decode.success(#(id, name))
  }

  sparkling_decode.decode_json_each_row(encoded, decoder)
  |> should.be_ok
  |> should.equal([#(1, "Alice"), #(2, "Bob"), #(3, "Charlie")])
}

// Test: encode float and decode
pub fn encode_decode_float_test() {
  let record =
    dict.from_list([
      #("id", json.int(5)),
      #("price", json.float(19.99)),
      #("discount", json.float(0.1)),
    ])

  let encoded = encode.encode_record(record)

  let decoder = {
    use id <- decode.field("id", decode.int)
    use price <- decode.field("price", decode.float)
    use discount <- decode.field("discount", decode.float)
    decode.success(#(id, price, discount))
  }

  sparkling_decode.decode_json(encoded, decoder)
  |> should.be_ok
  |> should.equal(#(5, 19.99, 0.1))
}

// Test: round-trip with nested array of objects (list of records)
pub fn encode_decode_nested_array_test() {
  let record =
    dict.from_list([
      #("id", json.int(6)),
      #(
        "items",
        json.array(
          [
            json.object([#("name", json.string("item1")), #("qty", json.int(2))]),
            json.object([#("name", json.string("item2")), #("qty", json.int(5))]),
          ],
          of: fn(x) { x },
        ),
      ),
    ])

  let encoded = encode.encode_record(record)

  let item_decoder = {
    use name <- decode.field("name", decode.string)
    use qty <- decode.field("qty", decode.int)
    decode.success(#(name, qty))
  }

  let decoder = {
    use id <- decode.field("id", decode.int)
    use items <- decode.field("items", decode.list(item_decoder))
    decode.success(#(id, items))
  }

  sparkling_decode.decode_json(encoded, decoder)
  |> should.be_ok
  |> should.equal(#(6, [#("item1", 2), #("item2", 5)]))
}

// Test: decode_json_each_row_raw returns List(json.Json)
pub fn decode_json_each_row_raw_test() {
  let json_each_row =
    "{\"id\":1,\"name\":\"Alice\"}\n{\"id\":2,\"name\":\"Bob\"}\n{\"id\":3,\"name\":\"Charlie\"}"

  let result = sparkling_decode.decode_json_each_row_raw(json_each_row)

  result
  |> should.be_ok

  // Verify we got 3 items
  case result {
    Ok(items) -> {
      list.length(items)
      |> should.equal(3)
    }
    Error(_) -> should.fail()
  }
}

// Test: decode_json_each_row_dict returns List(Dict(String, json.Json))
pub fn decode_json_each_row_dict_test() {
  let json_each_row =
    "{\"id\":1,\"name\":\"Alice\",\"active\":true}\n{\"id\":2,\"name\":\"Bob\",\"active\":false}"

  let result = sparkling_decode.decode_json_each_row_dict(json_each_row)

  result
  |> should.be_ok

  case result {
    Ok(items) -> {
      list.length(items)
      |> should.equal(2)

      // Verify first item has expected keys
      case items {
        [first, ..] -> {
          dict.has_key(first, "id")
          |> should.be_true

          dict.has_key(first, "name")
          |> should.be_true

          dict.has_key(first, "active")
          |> should.be_true
        }
        [] -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test: improved error messages with line index and excerpt
pub fn decode_json_each_row_error_message_test() {
  let json_each_row =
    "{\"id\":1,\"name\":\"Alice\"}\n{\"id\":\"invalid\",\"name\":\"Bob\"}\n{\"id\":3,\"name\":\"Charlie\"}"

  let decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    decode.success(#(id, name))
  }

  let result = sparkling_decode.decode_json_each_row(json_each_row, decoder)

  result
  |> should.be_error

  // Verify error message contains line number
  case result {
    Error(msg) -> {
      string.contains(msg, "line 2")
      |> should.be_true
    }
    Ok(_) -> should.fail()
  }
}

// Test: error message truncates long lines
pub fn decode_json_each_row_long_line_error_test() {
  // Create a very long line (> 100 chars)
  let long_line =
    "{\"id\":\"not_an_int\",\"data\":\"" <> string.repeat("x", 200) <> "\"}"

  let decoder = {
    use id <- decode.field("id", decode.int)
    decode.success(id)
  }

  let result = sparkling_decode.decode_json(long_line, decoder)

  // Just verify it doesn't crash with long input
  result
  |> should.be_error
}

// Test: streaming decoder processes all lines successfully
pub fn decode_json_each_row_streaming_test() {
  let json_each_row =
    "{\"id\":1,\"name\":\"Alice\"}\n{\"id\":2,\"name\":\"Bob\"}\n{\"id\":3,\"name\":\"Charlie\"}"

  let decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    decode.success(#(id, name))
  }

  let result =
    sparkling_decode.decode_json_each_row_streaming(
      json_each_row,
      decoder,
      fn(_user) { Nil },
    )

  result
  |> should.be_ok

  case result {
    Ok(count) -> {
      count
      |> should.equal(3)
    }
    Error(_) -> should.fail()
  }
}

// Test: streaming decoder stops on first error
pub fn decode_json_each_row_streaming_error_test() {
  let json_each_row =
    "{\"id\":1,\"name\":\"Alice\"}\n{invalid json}\n{\"id\":3,\"name\":\"Charlie\"}"

  let decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    decode.success(#(id, name))
  }

  let result =
    sparkling_decode.decode_json_each_row_streaming(
      json_each_row,
      decoder,
      fn(_user) { Nil },
    )

  result
  |> should.be_error

  case result {
    Error(msg) -> {
      // Should mention line 2 where the error occurred
      string.contains(msg, "Line 2")
      |> should.be_true
    }
    Ok(_) -> should.fail()
  }
}
