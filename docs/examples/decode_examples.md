# Examples extracted from sparkling/src/sparkling/decode.gleam

## decode_json_each_row_streaming (usage example)

```gleam
let count = decode_json_each_row_streaming(
  large_response,
  my_decoder,
  fn(user) { io.println("Processing: " <> user.name) }
)
```
