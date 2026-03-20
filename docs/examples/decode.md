# Decode

`sparkling/decode` parses ClickHouse response bodies (JSONEachRow and others).

## decode_json_each_row

Parses a newline-separated JSONEachRow response with a custom decoder.

```gleam
import gleam/dynamic/decode as dyn
import sparkling/decode

type User {
  User(id: Int, name: String)
}

let user_decoder =
  dyn.map2(User, dyn.field("id", dyn.int), dyn.field("name", dyn.string))

let body = "{\"id\":1,\"name\":\"Alice\"}\n{\"id\":2,\"name\":\"Bob\"}"

case decode.decode_json_each_row(body, user_decoder) {
  Ok(users) -> io.println(int.to_string(list.length(users)) <> " users")
  Error(msg) -> io.println("decode error: " <> msg)
}
```

## decode_json_each_row_dict

Parses each line to `Dict(String, json.Json)` — useful when you don't have a fixed type.

```gleam
case decode.decode_json_each_row_dict(body) {
  Ok(records) ->
    list.each(records, fn(row) {
      case dict.get(row, "id") {
        Ok(id) -> io.println(json.to_string(id))
        Error(_) -> Nil
      }
    })
  Error(msg) -> io.println("error: " <> msg)
}
```

## decode_json_each_row_raw

Returns raw `json.Json` values for each line.

```gleam
case decode.decode_json_each_row_raw(body) {
  Ok(jsons) -> io.println(int.to_string(list.length(jsons)) <> " values")
  Error(msg) -> io.println("error: " <> msg)
}
```

## decode_json_each_row_streaming

Memory-efficient streaming: processes each row via callback instead of building a list.
Returns `Result(Int, String)` where `Int` is the number of rows processed.

```gleam
case decode.decode_json_each_row_streaming(large_body, user_decoder, fn(user) {
  io.println("processing: " <> user.name)
}) {
  Ok(count) -> io.println(int.to_string(count) <> " rows processed")
  Error(msg) -> io.println("error: " <> msg)
}
```

## decode_json

Parses a single JSON value.

```gleam
case decode.decode_json("{\"id\":1}", dyn.field("id", dyn.int)) {
  Ok(id) -> io.println(int.to_string(id))
  Error(_) -> io.println("decode failed")
}
```
