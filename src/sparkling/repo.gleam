/// Repository layer for executing queries against ClickHouse via HTTP.
/// Supports retries and event hooks for observability.
/// Reference: https://clickhouse.com/docs/en/interfaces/http
import gleam/bit_array
import gleam/http
import gleam/http/request.{type Request}
import gleam/httpc
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/uri
import sparkling/retry.{type RetryConfig}

/// Repository configuration and state
pub type Repo {
  Repo(
    base_url: String,
    database: Option(String),
    user: Option(String),
    password: Option(String),
    on_event: fn(Event) -> Nil,
    retry_config: RetryConfig,
    timeout_ms: Int,
  )
}

/// Events emitted by the repo for observability (logging, metrics, tracing)
pub type Event {
  QueryStart(sql: String)
  QueryEnd(sql: String, duration_ms: Int)
  QueryError(sql: String, error: String)
  RetryAttempt(sql: String, attempt: Int, error: String)
}

/// Error types for repository operations
pub type RepoError {
  HttpError(message: String)
  ParseError(message: String)
  ConnectionError(message: String)
  ClickHouseError(message: String, code: Option(Int))
}

/// Create a new Repo with default configuration
pub fn new(base_url: String) -> Repo {
  Repo(
    base_url: base_url,
    database: None,
    user: None,
    password: None,
    on_event: fn(_event) { Nil },
    retry_config: retry.default_config(),
    timeout_ms: 30_000,
  )
}

/// Set the database name for queries
pub fn with_database(repo: Repo, database: String) -> Repo {
  Repo(..repo, database: Some(database))
}

/// Set authentication credentials
pub fn with_credentials(repo: Repo, user: String, password: String) -> Repo {
  Repo(..repo, user: Some(user), password: Some(password))
}

/// Set event handler for observability
pub fn with_event_handler(repo: Repo, handler: fn(Event) -> Nil) -> Repo {
  Repo(..repo, on_event: handler)
}

/// Set max retries for failed queries
pub fn with_max_retries(repo: Repo, retries: Int) -> Repo {
  let config = retry.RetryConfig(..repo.retry_config, max_attempts: retries)
  Repo(..repo, retry_config: config)
}

/// Set retry configuration for advanced control
pub fn with_retry_config(repo: Repo, config: RetryConfig) -> Repo {
  Repo(..repo, retry_config: config)
}

/// Set query timeout in milliseconds
pub fn with_timeout(repo: Repo, timeout_ms: Int) -> Repo {
  Repo(..repo, timeout_ms: timeout_ms)
}

/// Execute a SQL query and return the response body as a string.
/// This is the low-level interface; higher-level functions will parse the response.
pub fn execute_sql(repo: Repo, sql: String) -> Result(String, RepoError) {
  // Emit QueryStart event
  let start_time = erlang_monotonic_time()
  repo.on_event(QueryStart(sql))

  // Build request
  case build_request(repo, sql) {
    Ok(req) -> {
      // Execute with retries
      case execute_with_retries(repo, req) {
        Ok(body) -> {
          let duration = calculate_duration(start_time)
          repo.on_event(QueryEnd(sql, duration))
          Ok(body)
        }
        Error(err) -> {
          repo.on_event(QueryError(sql, error_to_string(err)))
          Error(err)
        }
      }
    }
    Error(err) -> {
      repo.on_event(QueryError(sql, error_to_string(err)))
      Error(err)
    }
  }
}

/// Execute a query and parse the response using a decoder.
/// This is a higher-level interface that combines execute_sql with decoding.
pub fn query(
  repo: Repo,
  sql: String,
  decoder: fn(String) -> Result(a, String),
) -> Result(a, RepoError) {
  use body <- result.try(execute_sql(repo, sql))
  decoder(body)
  |> result.map_error(fn(err) { ParseError(err) })
}

/// Build an HTTP request for ClickHouse
fn build_request(repo: Repo, sql: String) -> Result(Request(String), RepoError) {
  // Parse base URL
  case uri.parse(repo.base_url) {
    Error(_) -> Error(ConnectionError("Invalid base URL: " <> repo.base_url))
    Ok(base) -> {
      // Build query parameters
      let query_params = case repo.database {
        Some(db) -> [#("database", db)]
        None -> []
      }

      // Create POST request
      let req =
        request.new()
        |> request.set_method(http.Post)
        |> request.set_host(base.host |> option.unwrap("localhost"))
        |> request.set_path(base.path)
        |> request.set_body(sql)
        |> request.set_scheme(case base.scheme {
          Some("https") -> http.Https
          _ -> http.Http
        })

      // Set port if specified
      let req = case base.port {
        Some(port) -> request.set_port(req, port)
        None -> req
      }

      // Set query parameters if present
      let req = case query_params {
        [] -> req
        params -> request.set_query(req, params)
      }

      // Add authentication if set
      let req = case repo.user, repo.password {
        Some(user), Some(pass) -> {
          let credentials = user <> ":" <> pass
          let auth =
            "Basic " <> bit_array_to_base64(bit_array.from_string(credentials))
          request.set_header(req, "authorization", auth)
        }
        _, _ -> req
      }

      Ok(req)
    }
  }
}

/// Execute request with retry logic
fn execute_with_retries(
  repo: Repo,
  req: Request(String),
) -> Result(String, RepoError) {
  let operation = fn() {
    // Use direct httpc
    case httpc.send(req) {
      Ok(response) -> {
        // Check HTTP status code
        case response.status {
          200 -> {
            // Success - return body as string
            Ok(response.body)
          }
          status -> {
            // ClickHouse error - try to extract error message from body
            let error_msg = case string.is_empty(response.body) {
              True -> "HTTP " <> int.to_string(status)
              False -> response.body
            }
            Error(ClickHouseError(error_msg, Some(status)))
          }
        }
      }
      Error(_) -> Error(ConnectionError("Network error"))
    }
  }

  let is_retryable_error = fn(err: RepoError) {
    case err {
      ConnectionError(_) -> True
      HttpError(_) -> True
      // Don't retry ClickHouse errors (4xx/5xx with response)
      ClickHouseError(_, _) -> False
      // Don't retry parse errors
      ParseError(_) -> False
    }
  }

  retry.with_retry(repo.retry_config, operation, is_retryable_error)
}

/// Convert error to string for logging
fn error_to_string(error: RepoError) -> String {
  case error {
    HttpError(msg) -> "HTTP error: " <> msg
    ParseError(msg) -> "Parse error: " <> msg
    ConnectionError(msg) -> "Connection error: " <> msg
    ClickHouseError(msg, code) ->
      "ClickHouse error: "
      <> msg
      <> case code {
        Some(c) -> " (code: " <> int.to_string(c) <> ")"
        None -> ""
      }
  }
}

/// Get monotonic time for duration calculation
@external(erlang, "erlang", "monotonic_time")
fn erlang_monotonic_time() -> Int

/// Calculate duration in milliseconds from start time
fn calculate_duration(start_time: Int) -> Int {
  let end_time = erlang_monotonic_time()
  let duration_native = end_time - start_time
  // Convert to milliseconds (native unit is typically nanoseconds)
  duration_native / 1_000_000
}

/// Base64 encode using Erlang's base64 module
@external(erlang, "base64", "encode")
fn bit_array_to_base64(input: BitArray) -> String
