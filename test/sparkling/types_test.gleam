import gleam/option
import gleeunit/should
import sparkling/types

// ============================================================================
// Decimal tests
// ============================================================================

pub fn decimal_basic_test() {
  let result = types.decimal("123.45")
  result
  |> should.be_ok

  case result {
    Ok(d) -> {
      types.decimal_to_string(d)
      |> should.equal("123.45")
    }
    Error(_) -> should.fail()
  }
}

pub fn decimal_from_int_test() {
  let d = types.decimal_from_int(12_345)
  types.decimal_to_string(d)
  |> should.equal("12345")
}

pub fn decimal_invalid_format_test() {
  types.decimal("abc")
  |> should.be_error

  types.decimal("")
  |> should.be_error
}

pub fn decimal_negative_test() {
  let result = types.decimal("-123.45")
  result
  |> should.be_ok

  case result {
    Ok(d) -> {
      types.decimal_to_string(d)
      |> should.equal("-123.45")
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// DateTime64 tests
// ============================================================================

pub fn datetime64_basic_test() {
  let result =
    types.datetime64("2024-01-15 10:30:45.123", 3, option.Some("UTC"))
  result
  |> should.be_ok

  case result {
    Ok(dt) -> {
      types.datetime64_to_string(dt)
      |> should.equal("2024-01-15 10:30:45.123")

      types.datetime64_timezone(dt)
      |> should.equal(option.Some("UTC"))
    }
    Error(_) -> should.fail()
  }
}

pub fn datetime64_from_epoch_test() {
  let result = types.datetime64_from_epoch(1_705_315_845, 0, option.None)
  result
  |> should.be_ok

  case result {
    Ok(dt) -> {
      types.datetime64_to_string(dt)
      |> should.equal("1705315845")
    }
    Error(_) -> should.fail()
  }
}

pub fn datetime64_invalid_precision_test() {
  types.datetime64("2024-01-15 10:30:45", 10, option.None)
  |> should.be_error

  types.datetime64("2024-01-15 10:30:45", -1, option.None)
  |> should.be_error

  types.datetime64("2024-01-15", 0, option.None)
  |> should.be_ok

  types.datetime64("2024-01-15", 9, option.None)
  |> should.be_ok
}

// ============================================================================
// UUID tests
// ============================================================================

pub fn uuid_basic_test() {
  let result = types.uuid("550e8400-e29b-41d4-a716-446655440000")
  result
  |> should.be_ok

  case result {
    Ok(u) -> {
      types.uuid_to_string(u)
      |> should.equal("550e8400-e29b-41d4-a716-446655440000")
    }
    Error(_) -> should.fail()
  }
}

pub fn uuid_invalid_format_test() {
  types.uuid("invalid-uuid")
  |> should.be_error

  types.uuid("550e8400-e29b-41d4-a716")
  |> should.be_error
}

// ============================================================================
// LowCardinality tests
// ============================================================================

pub fn low_cardinality_test() {
  let lc = types.low_cardinality_string("active")
  types.low_cardinality_value(lc)
  |> should.equal("active")
}

// ============================================================================
// Enum tests
// ============================================================================

pub fn enum8_from_string_test() {
  let mappings = [#("active", 1), #("inactive", 2), #("pending", 3)]

  types.enum8_from_string(mappings, "active")
  |> should.be_ok
  |> should.equal(1)

  types.enum8_from_string(mappings, "inactive")
  |> should.be_ok
  |> should.equal(2)

  types.enum8_from_string(mappings, "invalid")
  |> should.be_error
}

pub fn enum16_from_string_test() {
  let mappings = [#("small", 100), #("medium", 200), #("large", 300)]

  types.enum16_from_string(mappings, "medium")
  |> should.be_ok
  |> should.equal(200)

  types.enum16_from_string(mappings, "invalid")
  |> should.be_error
}
