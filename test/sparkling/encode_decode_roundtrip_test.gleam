/// Encoding tests for complex ClickHouse types
/// Verifies correct JSON serialization without precision loss
import gleam/dict
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import sparkling/encode
import sparkling/types

// ============================================================================
// Decimal encoding tests
// ============================================================================

pub fn decimal_encode_test() {
  let assert Ok(dec) = types.decimal("123.456")
  let encoded = encode.decimal(dec)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("123.456")
  |> should.be_true()
}

pub fn decimal_large_precision_test() {
  let assert Ok(dec) = types.decimal("999999999999999.123456789")
  let encoded = encode.decimal(dec)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("999999999999999.123456789")
  |> should.be_true()
}

pub fn decimal_negative_test() {
  let assert Ok(dec) = types.decimal("-123.45")
  let encoded = encode.decimal(dec)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("-123.45")
  |> should.be_true()
}

// ============================================================================
// DateTime64 encoding tests
// ============================================================================

pub fn datetime64_roundtrip_test() {
  // DateTime64 with precision and timezone
  case types.datetime64("2024-11-07 15:30:45.123", 3, option.Some("UTC")) {
    Ok(dt) -> {
      let encoded = encode.datetime64(dt)
      let json_str = json.to_string(encoded)

      // Verify encoding produces valid string
      json_str
      |> string.contains("2024-11-07")
      |> should.be_true
    }
    Error(e) -> panic as { "Failed to create DateTime64: " <> e }
  }
}

pub fn datetime64_with_timezone_test() {
  case types.datetime64("2024-01-15 10:30:45", 0, Some("UTC")) {
    Ok(dt) -> {
      let encoded = encode.datetime64(dt)
      let json_str = json.to_string(encoded)

      json_str
      |> string.contains("2024-01-15")
      |> should.be_true()
    }
    Error(e) -> panic as { "Failed to create DateTime64: " <> e }
  }
}

pub fn datetime64_from_epoch_test() {
  case types.datetime64_from_epoch(1_705_315_845, 0, None) {
    Ok(dt) -> {
      let encoded = encode.datetime64(dt)
      let json_str = json.to_string(encoded)

      json_str
      |> string.contains("1705315845")
      |> should.be_true()
    }
    Error(e) -> panic as { "Failed to create DateTime64: " <> e }
  }
}

// ============================================================================
// UUID encoding tests
// ============================================================================

pub fn uuid_encode_test() {
  let assert Ok(uuid) = types.uuid("550e8400-e29b-41d4-a716-446655440000")
  let encoded = encode.uuid(uuid)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("550e8400-e29b-41d4-a716-446655440000")
  |> should.be_true()
}

// ============================================================================
// Array encoding tests
// ============================================================================

pub fn array_int_encode_test() {
  let arr = [1, 2, 3, 4, 5]
  let encoded = encode.array(arr, json.int)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("1")
  |> should.be_true()

  json_str
  |> string.contains("5")
  |> should.be_true()
}

pub fn array_string_encode_test() {
  let arr = ["hello", "world", "test"]
  let encoded = encode.array(arr, json.string)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("hello")
  |> should.be_true()

  json_str
  |> string.contains("world")
  |> should.be_true()
}

pub fn array_nested_encode_test() {
  let arr = [[1, 2], [3, 4], [5, 6]]
  let encoded = encode.array(arr, fn(inner) { encode.array(inner, json.int) })
  let json_str = json.to_string(encoded)

  // Should contain nested structure
  json_str
  |> string.contains("[")
  |> should.be_true()
}

// ============================================================================
// Map encoding tests
// ============================================================================

pub fn map_string_int_encode_test() {
  let map =
    dict.from_list([
      #("one", json.int(1)),
      #("two", json.int(2)),
      #("three", json.int(3)),
    ])

  let encoded = encode.clickhouse_map_from_dict(map)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("one")
  |> should.be_true()

  json_str
  |> string.contains("1")
  |> should.be_true()
}

pub fn map_string_string_encode_test() {
  let map =
    dict.from_list([
      #("name", json.string("Alice")),
      #("city", json.string("Rome")),
      #("country", json.string("Italy")),
    ])

  let encoded = encode.clickhouse_map_from_dict(map)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("Alice")
  |> should.be_true()

  json_str
  |> string.contains("Rome")
  |> should.be_true()
}

// ============================================================================
// Tuple encoding tests
// ============================================================================

pub fn tuple_mixed_types_test() {
  let elements = [
    json.int(42),
    json.string("hello"),
    json.bool(True),
    json.float(3.14),
  ]

  let encoded = encode.clickhouse_tuple(elements)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("42")
  |> should.be_true()

  json_str
  |> string.contains("hello")
  |> should.be_true()
}

// ============================================================================
// Nested structure encoding tests
// ============================================================================

pub fn nested_structure_encode_test() {
  let nested =
    dict.from_list([
      #("id", json.int(1)),
      #("name", json.string("Test")),
      #("active", json.bool(True)),
      #(
        "metadata",
        json.object([
          #("version", json.int(2)),
          #("tags", json.array(["a", "b", "c"], json.string)),
        ]),
      ),
    ])

  let encoded = encode.nested_from_dict(nested)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("Test")
  |> should.be_true()

  json_str
  |> string.contains("metadata")
  |> should.be_true()
}

// ============================================================================
// LowCardinality encoding tests
// ============================================================================

pub fn low_cardinality_encode_test() {
  let lc = types.low_cardinality_string("active")
  let encoded = encode.low_cardinality_string(lc)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("active")
  |> should.be_true()
}

// ============================================================================
// Nullable encoding tests
// ============================================================================

pub fn nullable_some_value_test() {
  let nullable = Some(json.int(42))
  let encoded = encode.nullable(nullable)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("42")
  |> should.be_true()
}

pub fn nullable_none_value_test() {
  let nullable = None
  let encoded = encode.nullable(nullable)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("null")
  |> should.be_true()
}

// ============================================================================
// Enum encoding tests
// ============================================================================

pub fn enum8_encode_test() {
  // Enum8 just holds mappings, we encode the integer value directly
  let encoded = encode.enum_value(1)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("1")
  |> should.be_true()
}

pub fn enum16_encode_test() {
  // Enum16 just holds mappings, we encode the integer value directly
  let encoded = encode.enum_value(200)
  let json_str = json.to_string(encoded)

  json_str
  |> string.contains("200")
  |> should.be_true()
}

// ============================================================================
// Complex composite encoding test
// ============================================================================

pub fn complex_record_encode_test() {
  // Simulate a complex record with multiple types
  let assert Ok(decimal_price) = types.decimal("99.99")
  let assert Ok(uuid_id) = types.uuid("550e8400-e29b-41d4-a716-446655440000")
  let assert Ok(created_at) = types.datetime64("2024-01-15 10:30:45", 0, None)
  let status = types.low_cardinality_string("active")

  let record =
    dict.from_list([
      #("id", encode.uuid(uuid_id)),
      #("price", encode.decimal(decimal_price)),
      #("created_at", encode.datetime64(created_at)),
      #("status", encode.low_cardinality_string(status)),
      #("tags", encode.array(["tag1", "tag2"], json.string)),
      #(
        "metadata",
        json.object([
          #("version", json.int(1)),
        ]),
      ),
    ])

  let encoded = encode.encode_record(record)

  // Verify all fields present
  encoded
  |> string.contains("550e8400")
  |> should.be_true()

  encoded
  |> string.contains("99.99")
  |> should.be_true()

  encoded
  |> string.contains("active")
  |> should.be_true()

  encoded
  |> string.contains("tag1")
  |> should.be_true()
}

// ============================================================================
// JSONEachRow batch encoding test
// ============================================================================

pub fn json_each_row_batch_encode_test() {
  let assert Ok(dec1) = types.decimal("10.50")
  let assert Ok(dec2) = types.decimal("20.75")

  let records = [
    dict.from_list([
      #("id", json.int(1)),
      #("price", encode.decimal(dec1)),
    ]),
    dict.from_list([
      #("id", json.int(2)),
      #("price", encode.decimal(dec2)),
    ]),
  ]

  let encoded = encode.encode_json_each_row(records)

  // Should have newline-separated rows
  encoded
  |> string.contains("10.50")
  |> should.be_true()

  encoded
  |> string.contains("20.75")
  |> should.be_true()

  encoded
  |> string.contains("\n")
  |> should.be_true()
}
