/// Advanced ClickHouse type wrappers and conversions.
///
/// This module provides typed wrappers for complex ClickHouse types that don't
/// have direct Gleam equivalents.
///
/// # Type Mapping Strategy
///
/// - Simple types (Int, Float, String, Bool) → native Gleam types
/// - Complex types → opaque wrappers with conversion functions
/// - Precision-critical types (Decimal) → string-based with validation
/// - Temporal types (DateTime64) → structured with timezone support
/// - Collections (Array, Map, Tuple) → typed Gleam collections
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string

// ============================================================================
// Decimal types - precision-safe string representation
// ============================================================================

/// Decimal value with precision and scale preservation.
///
/// Stored as string to avoid floating-point precision loss.
/// Use helper functions to convert to/from numeric types when needed.
pub opaque type Decimal {
  Decimal(value: String)
}

/// Create a Decimal from a string representation.
pub fn decimal(value: String) -> Result(Decimal, String) {
  case validate_decimal_string(value) {
    True -> Ok(Decimal(value))
    False -> Error("Invalid decimal format: " <> value)
  }
}

/// Get the string representation of a Decimal.
pub fn decimal_to_string(d: Decimal) -> String {
  d.value
}

/// Create a Decimal from an integer.
pub fn decimal_from_int(value: Int) -> Decimal {
  Decimal(int.to_string(value))
}

/// Create a Decimal from a float. Returns an error for values that cannot
/// be represented as a plain decimal string (e.g. very large floats).
/// Note: floats may lose precision; prefer decimal/1 with an explicit string.
pub fn decimal_from_float(value: Float) -> Result(Decimal, String) {
  decimal(float.to_string(value))
}

/// Validate decimal string format: optional leading minus, digits, at most one dot.
fn validate_decimal_string(s: String) -> Bool {
  case string.trim(s) {
    "" -> False
    trimmed -> {
      let body = case string.starts_with(trimmed, "-") {
        True -> string.drop_start(trimmed, 1)
        False -> trimmed
      }
      validate_positive_decimal(body)
    }
  }
}

fn validate_positive_decimal(s: String) -> Bool {
  case string.split(s, ".") {
    [integer_part] ->
      string.length(integer_part) > 0 && all_digits(integer_part)
    [integer_part, decimal_part] ->
      string.length(integer_part) > 0
      && string.length(decimal_part) > 0
      && all_digits(integer_part)
      && all_digits(decimal_part)
    _ -> False
  }
}

fn is_digit(char: String) -> Bool {
  string.contains("0123456789", char)
}

fn all_digits(s: String) -> Bool {
  string.to_graphemes(s) |> list.all(is_digit)
}

// ============================================================================
// DateTime64 - high-precision timestamps with timezone
// ============================================================================

/// DateTime64 with configurable precision and timezone.
///
/// Precision: 0-9 digits after decimal point (subsecond precision).
/// Timezone: optional timezone identifier (e.g. "UTC", "America/New_York").
pub type DateTime64 {
  DateTime64(value: String, precision: Int, timezone: Option(String))
}

/// Create a DateTime64 from an ISO 8601 string or epoch string.
pub fn datetime64(
  value: String,
  precision: Int,
  timezone: Option(String),
) -> Result(DateTime64, String) {
  case precision >= 0 && precision <= 9 {
    True -> Ok(DateTime64(value, precision, timezone))
    False ->
      Error("Invalid precision: must be 0-9, got " <> int.to_string(precision))
  }
}

/// Create a DateTime64 from Unix epoch (seconds).
pub fn datetime64_from_epoch(
  epoch_seconds: Int,
  precision: Int,
  timezone: Option(String),
) -> Result(DateTime64, String) {
  datetime64(int.to_string(epoch_seconds), precision, timezone)
}

/// Get the string representation of a DateTime64.
pub fn datetime64_to_string(dt: DateTime64) -> String {
  dt.value
}

/// Get the timezone of a DateTime64.
pub fn datetime64_timezone(dt: DateTime64) -> Option(String) {
  dt.timezone
}

// ============================================================================
// UUID - universally unique identifier
// ============================================================================

/// UUID type (128-bit identifier).
///
/// Standard format: 8-4-4-4-12 hex digits (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx).
pub opaque type UUID {
  UUID(value: String)
}

/// Create a UUID from string representation.
pub fn uuid(value: String) -> Result(UUID, String) {
  case validate_uuid_format(value) {
    True -> Ok(UUID(value))
    False -> Error("Invalid UUID format: " <> value)
  }
}

/// Get the string representation of a UUID.
pub fn uuid_to_string(u: UUID) -> String {
  u.value
}

/// Validate UUID format: 8-4-4-4-12 pattern with hex characters only.
fn validate_uuid_format(s: String) -> Bool {
  let parts = string.split(s, "-")
  case parts {
    [a, b, c, d, e] ->
      string.length(a) == 8
      && all_hex(a)
      && string.length(b) == 4
      && all_hex(b)
      && string.length(c) == 4
      && all_hex(c)
      && string.length(d) == 4
      && all_hex(d)
      && string.length(e) == 12
      && all_hex(e)
    _ -> False
  }
}

fn is_hex_char(char: String) -> Bool {
  string.contains("0123456789abcdefABCDEF", char)
}

fn all_hex(s: String) -> Bool {
  string.to_graphemes(s) |> list.all(is_hex_char)
}

// ============================================================================
// LowCardinality - optimized string storage
// ============================================================================

/// LowCardinality wrapper for values with low cardinality.
///
/// This is a performance hint to ClickHouse for storage optimization.
pub opaque type LowCardinality {
  LowCardinality(value: String)
}

/// Create a LowCardinality from a string value.
pub fn low_cardinality_string(value: String) -> LowCardinality {
  LowCardinality(value)
}

/// Get the value from a LowCardinality wrapper.
pub fn low_cardinality_value(lc: LowCardinality) -> String {
  lc.value
}

// ============================================================================
// Enum - enumerated values
// ============================================================================

/// Enum8 type mapping (Int8 range: -128..127).
pub type Enum8 {
  Enum8(mappings: List(#(String, Int)))
}

/// Enum16 type mapping (Int16 range: -32768..32767).
pub type Enum16 {
  Enum16(mappings: List(#(String, Int)))
}

/// Look up an Enum8 value by string label.
/// Returns an error if the label is not found or the mapped value is out of
/// Int8 range [-128, 127].
pub fn enum8_from_string(
  mappings: List(#(String, Int)),
  value: String,
) -> Result(Int, String) {
  use code <- result.try(enum_lookup(mappings, value))
  case code >= -128 && code <= 127 {
    True -> Ok(code)
    False ->
      Error(
        "Enum8 value out of Int8 range [-128, 127]: " <> int.to_string(code),
      )
  }
}

/// Look up an Enum16 value by string label.
/// Returns an error if the label is not found or the mapped value is out of
/// Int16 range [-32768, 32767].
pub fn enum16_from_string(
  mappings: List(#(String, Int)),
  value: String,
) -> Result(Int, String) {
  use code <- result.try(enum_lookup(mappings, value))
  case code >= -32_768 && code <= 32_767 {
    True -> Ok(code)
    False ->
      Error(
        "Enum16 value out of Int16 range [-32768, 32767]: "
        <> int.to_string(code),
      )
  }
}

fn enum_lookup(
  mappings: List(#(String, Int)),
  value: String,
) -> Result(Int, String) {
  list.find(mappings, fn(pair) { pair.0 == value })
  |> result.map(fn(pair) { pair.1 })
  |> result.replace_error("Invalid enum value: " <> value)
}
