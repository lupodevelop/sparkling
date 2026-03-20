# Types

Advanced ClickHouse type wrappers in `sparkling/types`.

## Decimal

`Decimal` is opaque — construct via `types.decimal/1` (returns `Result`).

```gleam
import sparkling/types

// From string (preserves precision)
case types.decimal("123.45") {
  Ok(d) -> types.decimal_to_string(d)  // => "123.45"
  Error(msg) -> panic as msg
}

// From int
let d = types.decimal_from_int(100)
types.decimal_to_string(d)  // => "100"

// From float
case types.decimal_from_float(3.14) {
  Ok(d) -> types.decimal_to_string(d)
  Error(msg) -> panic as msg
}
```

## DateTime64

```gleam
// From string value (validates precision 0-9)
case types.datetime64("2024-01-15 10:30:45.123", 3, Some("UTC")) {
  Ok(dt) -> types.datetime64_to_string(dt)  // => "2024-01-15 10:30:45.123"
  Error(msg) -> panic as msg
}

// From epoch seconds
case types.datetime64_from_epoch(1_705_316_100, 0, None) {
  Ok(dt) -> types.datetime64_to_string(dt)
  Error(msg) -> panic as msg
}

// Read timezone
let tz = types.datetime64_timezone(dt)  // => Some("UTC") or None
```

## UUID

`UUID` is opaque — construct via `types.uuid/1`. Validates 8-4-4-4-12 hex format.

```gleam
case types.uuid("550e8400-e29b-41d4-a716-446655440000") {
  Ok(u) -> types.uuid_to_string(u)  // => "550e8400-e29b-41d4-a716-446655440000"
  Error(msg) -> panic as msg
}

// Invalid format returns Error
types.uuid("not-a-uuid")
// => Error("Invalid UUID format: ...")
```

## LowCardinality

`LowCardinality` is a storage-optimization hint for low-cardinality string columns.

```gleam
let status = types.low_cardinality_string("active")
types.low_cardinality_value(status)  // => "active"
```

## Enum8 / Enum16

```gleam
let mappings = [#("active", 1), #("inactive", 2), #("pending", 3)]

// Lookup by name -> numeric value (validates range [-128, 127] for Enum8)
types.enum8_from_string(mappings, "active")   // => Ok(1)
types.enum8_from_string(mappings, "unknown")  // => Error("Value not found in enum: unknown")

// Enum16 supports range [-32768, 32767]
types.enum16_from_string(mappings, "pending")  // => Ok(3)
```
