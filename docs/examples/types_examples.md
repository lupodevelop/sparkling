# Examples extracted from sparkling/src/sparkling/types.gleam

## Decimal examples

```gleam
let price = Decimal("123.45")
let amount = Decimal("0.000001")
```

## DateTime64 example

```gleam
let timestamp = DateTime64("2024-01-15 10:30:45.123", 3, Some("UTC"))
```

## UUID example

```gleam
let id = UUID("550e8400-e29b-41d4-a716-446655440000")
```

## LowCardinality example

```gleam
let status = low_cardinality_string("active")
```

## Enum example

```gleam
let status = Enum8([#("active", 1), #("inactive", 2)])
```
