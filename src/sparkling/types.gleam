/// Advanced ClickHouse type wrappers and conversions.
/// 
/// This module provides typed wrappers for complex ClickHouse types that don't
/// have direct Gleam equivalents, following the patterns documented
/// 
/// # Type Mapping Strategy
/// 
/// - Simple types (Int, Float, String, Bool) → native Gleam types
/// - Complex types → opaque wrappers with conversion functions
/// - Precision-critical types (Decimal) → string-based with validation
/// - Temporal types (DateTime64) → structured with timezone support
/// - Collections (Array, Map, Tuple) → typed Gleam collections
/// 
/// # Plugin API
/// 
/// Custom encoders/decoders can be registered for specialized handling of
/// complex types (e.g., native Decimal libraries, custom timezone handling).
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
/// Examples: docs/examples/types_examples.md
pub opaque type Decimal {
  Decimal(value: String)
}

/// Create a Decimal from a string representation
pub fn decimal(value: String) -> Result(Decimal, String) {
  // Basic validation: check for valid decimal format
  case validate_decimal_string(value) {
    True -> Ok(Decimal(value))
    False -> Error("Invalid decimal format: " <> value)
  }
}

/// Get the string representation of a Decimal
pub fn decimal_to_string(d: Decimal) -> String {
  d.value
}

/// Create a Decimal from an integer
pub fn decimal_from_int(value: Int) -> Decimal {
  Decimal(int.to_string(value))
}

/// Create a Decimal from a float (may lose precision)
pub fn decimal_from_float(value: Float) -> Decimal {
  Decimal(float_to_string(value))
}

/// Validate decimal string format
fn validate_decimal_string(s: String) -> Bool {
  // Allow: digits, optional decimal point, optional leading minus
  // Reject empty strings and non-numeric characters
  case s {
    "" -> False
    _ -> {
      let trimmed = string.trim(s)
      case trimmed {
        "" -> False
        _ -> {
          // Check for valid characters: digits, minus, and decimal point
          let has_invalid_chars =
            string.to_graphemes(trimmed)
            |> list.any(fn(char) {
              char != "-" && char != "." && !is_digit(char)
            })

          case has_invalid_chars {
            True -> False
            False -> {
              // Further validation: minus only at start, single decimal point
              case string.starts_with(trimmed, "-") {
                True -> validate_positive_decimal(string.drop_start(trimmed, 1))
                False -> validate_positive_decimal(trimmed)
              }
            }
          }
        }
      }
    }
  }
}

fn is_digit(char: String) -> Bool {
  char == "0"
  || char == "1"
  || char == "2"
  || char == "3"
  || char == "4"
  || char == "5"
  || char == "6"
  || char == "7"
  || char == "8"
  || char == "9"
}

fn validate_positive_decimal(s: String) -> Bool {
  case s {
    "" -> False
    _ -> {
      // Check if contains only digits and at most one decimal point
      let parts = string.split(s, ".")
      case parts {
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
  }
}

fn all_digits(s: String) -> Bool {
  string.to_graphemes(s)
  |> list.all(is_digit)
}

// ============================================================================
// DateTime64 - high-precision timestamps with timezone
// ============================================================================

/// DateTime64 with configurable precision and timezone.
/// 
/// Precision: 0-9 digits after decimal point (subsecond precision)
/// Timezone: optional timezone identifier (e.g., "UTC", "America/New_York")
/// Examples: docs/examples/types_examples.md
pub type DateTime64 {
  DateTime64(
    /// ISO 8601 timestamp or epoch string
    value: String,
    /// Precision (0-9 for subsecond digits)
    precision: Int,
    /// Optional timezone identifier
    timezone: Option(String),
  )
}

/// Create a DateTime64 from ISO 8601 string
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

/// Create a DateTime64 from Unix epoch (seconds)
pub fn datetime64_from_epoch(
  epoch_seconds: Int,
  precision: Int,
  timezone: Option(String),
) -> Result(DateTime64, String) {
  datetime64(int.to_string(epoch_seconds), precision, timezone)
}

/// Get the string representation of a DateTime64
pub fn datetime64_to_string(dt: DateTime64) -> String {
  dt.value
}

/// Get the timezone of a DateTime64
pub fn datetime64_timezone(dt: DateTime64) -> Option(String) {
  dt.timezone
}

// ============================================================================
// UUID - universally unique identifier
// ============================================================================

/// UUID type (128-bit identifier)
/// 
/// Standard format: 8-4-4-4-12 hex digits (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
/// Examples: docs/examples/types_examples.md
pub opaque type UUID {
  UUID(value: String)
}

/// Create a UUID from string representation
pub fn uuid(value: String) -> Result(UUID, String) {
  case validate_uuid_format(value) {
    True -> Ok(UUID(value))
    False -> Error("Invalid UUID format: " <> value)
  }
}

/// Get the string representation of a UUID
pub fn uuid_to_string(u: UUID) -> String {
  u.value
}

/// Validate UUID format (basic check)
fn validate_uuid_format(s: String) -> Bool {
  // Check for 8-4-4-4-12 pattern
  let parts = string.split(s, "-")
  case parts {
    [a, b, c, d, e] ->
      string.length(a) == 8
      && string.length(b) == 4
      && string.length(c) == 4
      && string.length(d) == 4
      && string.length(e) == 12
    _ -> False
  }
}

// ============================================================================
// LowCardinality - optimized string storage
// ============================================================================

/// LowCardinality wrapper for values with low cardinality.
/// 
/// This is a performance hint to ClickHouse for storage optimization.
/// In Gleam, we wrap the value with its type information.
/// Examples: docs/examples/types_examples.md
pub opaque type LowCardinality {
  LowCardinality(value: String)
}

/// Create a LowCardinality from a string value
pub fn low_cardinality_string(value: String) -> LowCardinality {
  LowCardinality(value)
}

/// Get the value from a LowCardinality wrapper
pub fn low_cardinality_value(lc: LowCardinality) -> String {
  lc.value
}

// ============================================================================
// Enum - enumerated values
// ============================================================================

/// Enum8/Enum16 type mapping
/// 
/// Maps string values to integer codes.
/// Examples: docs/examples/types_examples.md
pub type Enum8 {
  Enum8(mappings: List(#(String, Int)))
}

pub type Enum16 {
  Enum16(mappings: List(#(String, Int)))
}

/// Create an Enum8 from string value
pub fn enum8_from_string(
  mappings: List(#(String, Int)),
  value: String,
) -> Result(Int, String) {
  list.find(mappings, fn(pair) { pair.0 == value })
  |> result.map(fn(pair) { pair.1 })
  |> result.replace_error("Invalid enum value: " <> value)
}

/// Create an Enum16 from string value
pub fn enum16_from_string(
  mappings: List(#(String, Int)),
  value: String,
) -> Result(Int, String) {
  list.find(mappings, fn(pair) { pair.0 == value })
  |> result.map(fn(pair) { pair.1 })
  |> result.replace_error("Invalid enum value: " <> value)
}

// ============================================================================
// Helper functions
// ============================================================================

/// Convert float to string (helper for decimal_from_float)
@external(erlang, "erlang", "float_to_list")
fn float_to_list(f: Float) -> List(Int)

fn float_to_string(f: Float) -> String {
  // Convert float to string representation
  // This is a simplified implementation; use proper formatting library in production
  let chars = float_to_list(f)
  list_to_string(chars)
}

@external(erlang, "erlang", "list_to_binary")
fn list_to_string(chars: List(Int)) -> String
