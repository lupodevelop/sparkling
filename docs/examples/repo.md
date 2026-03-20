# Repository

`sparkling/repo` executes SQL against ClickHouse over HTTP.

## Setup

```gleam
import sparkling/repo

let r =
  repo.new("http://localhost:8123")
  |> repo.with_database("mydb")
  |> repo.with_credentials("default", "")
```

## execute_sql

Returns the raw response body as `Result(String, RepoError)`.

```gleam
case repo.execute_sql(r, "SELECT 1 FORMAT JSONEachRow") {
  Ok(body) -> io.println(body)          // => {"1":1}
  Error(repo.HttpError(msg)) -> io.println("http error: " <> msg)
  Error(repo.ParseError(msg)) -> io.println("parse error: " <> msg)
  Error(repo.ConnectionError(msg)) -> io.println("connection error: " <> msg)
  Error(repo.ClickHouseError(msg, code)) ->
    io.println("clickhouse error [" <> int.to_string(option.unwrap(code, 0)) <> "]: " <> msg)
}
```

## query (with decoder)

```gleam
import sparkling/decode

case repo.query(r, "SELECT id, name FROM users FORMAT JSONEachRow", fn(body) {
  decode.decode_json_each_row(body, my_decoder)
}) {
  Ok(rows) -> io.println(int.to_string(list.length(rows)) <> " rows")
  Error(_) -> io.println("failed")
}
```

## Retry config

```gleam
import sparkling/retry

// Use built-in configs
let r = repo.new("http://localhost:8123")
  |> repo.with_retry_config(retry.network_config())

// Or customize
let config = retry.RetryConfig(
  max_attempts: 5,
  base_delay_ms: 200,
  max_delay_ms: 30_000,
  jitter_factor: 0.2,
)
let r = repo.new("http://localhost:8123")
  |> repo.with_retry_config(config)
```

## Observability (event handler)

```gleam
let r =
  repo.new("http://localhost:8123")
  |> repo.with_event_handler(fn(event) {
    case event {
      repo.QueryStart(sql) -> io.println("start: " <> sql)
      repo.QueryEnd(sql, duration_ms) ->
        io.println("done in " <> int.to_string(duration_ms) <> "ms")
      repo.QueryError(sql, err) -> io.println("error: " <> err)
      repo.RetryAttempt(sql, attempt, err) ->
        io.println("retry #" <> int.to_string(attempt) <> ": " <> err)
    }
  })
```

## Timeout

```gleam
let r =
  repo.new("http://localhost:8123")
  |> repo.with_timeout(5000)  // 5 seconds
```
