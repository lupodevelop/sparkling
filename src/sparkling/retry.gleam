//// Retry logic with exponential backoff and jitter for resilient operations.
//// Used by both repo and transport layers to handle transient failures.

import gleam/erlang/process
import gleam/float
import gleam/int

/// Configuration for retry behavior
pub type RetryConfig {
  RetryConfig(
    /// Maximum number of retry attempts
    max_attempts: Int,
    /// Base delay in milliseconds for exponential backoff
    base_delay_ms: Int,
    /// Maximum delay between retries
    max_delay_ms: Int,
    /// Jitter factor (0.0 = no jitter, 1.0 = full jitter)
    jitter_factor: Float,
  )
}

/// Default retry configuration suitable for most operations
pub fn default_config() -> RetryConfig {
  RetryConfig(
    max_attempts: 3,
    base_delay_ms: 100,
    max_delay_ms: 10_000,
    jitter_factor: 0.1,
  )
}

/// Configuration optimized for network operations (longer delays)
pub fn network_config() -> RetryConfig {
  RetryConfig(
    max_attempts: 5,
    base_delay_ms: 200,
    max_delay_ms: 30_000,
    jitter_factor: 0.2,
  )
}

/// Execute an operation with retry logic
/// Returns the result of the first successful attempt, or the last error
pub fn with_retry(
  config: RetryConfig,
  operation: fn() -> Result(a, b),
  is_retryable_error: fn(b) -> Bool,
) -> Result(a, b) {
  do_retry(config, operation, is_retryable_error, 0)
}

/// Internal retry implementation
fn do_retry(
  config: RetryConfig,
  operation: fn() -> Result(a, b),
  is_retryable_error: fn(b) -> Bool,
  attempt: Int,
) -> Result(a, b) {
  case operation() {
    Ok(result) -> Ok(result)
    Error(err) -> {
      case attempt < config.max_attempts && is_retryable_error(err) {
        True -> {
          // Calculate delay with exponential backoff and jitter
          let delay = calculate_delay(config, attempt)
          process.sleep(delay)

          // Retry with incremented attempt counter
          do_retry(config, operation, is_retryable_error, attempt + 1)
        }
        False -> Error(err)
      }
    }
  }
}

/// Calculate delay with exponential backoff and jitter
fn calculate_delay(config: RetryConfig, attempt: Int) -> Int {
  // Exponential backoff: base_delay * 2^attempt
  let exponential_delay = config.base_delay_ms * int_pow(2, attempt)

  // Cap at maximum delay
  let capped_delay = int.min(exponential_delay, config.max_delay_ms)

  // Add jitter to avoid thundering herd
  let jitter_range =
    float.round(int.to_float(capped_delay) *. config.jitter_factor)
  let jitter = case jitter_range > 0 {
    True -> erlang_system_time() % jitter_range
    False -> 0
  }

  capped_delay + jitter
}

/// Integer power function (simple recursive implementation)
fn int_pow(base: Int, exponent: Int) -> Int {
  case exponent {
    0 -> 1
    n if n > 0 -> base * int_pow(base, n - 1)
    _ -> 1
    // Negative exponents not supported
  }
}

/// Get system time for jitter calculation
@external(erlang, "erlang", "system_time")
fn erlang_system_time() -> Int
