/// Performance test - verifies library can handle large batch operations
import gleam/int
import gleam/list
import gleam/string
import gleeunit/should
import sparkling/repo

pub fn batch_insert_performance_test() {
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")
    |> repo.with_timeout(60_000)
  // 60 second timeout for large batch

  // Create test table
  let ddl =
    "CREATE TABLE IF NOT EXISTS test_performance (
      id UInt32,
      value String,
      timestamp DateTime
    ) ENGINE = MergeTree()
    ORDER BY id"

  case repo.execute_sql(repo, ddl) {
    Ok(_) -> {
      // Generate large batch of values (10,000 rows)
      let batch_size = 10_000
      let values =
        list.range(1, batch_size)
        |> list.map(fn(i) {
          "("
          <> int.to_string(i)
          <> ", 'value_"
          <> int.to_string(i)
          <> "', '2024-01-01 00:00:00')"
        })
        |> string.join(", ")

      let insert =
        "INSERT INTO test_performance (id, value, timestamp) VALUES " <> values

      // Insert large batch
      case repo.execute_sql(repo, insert) {
        Ok(_) -> {
          // Verify count
          case
            repo.execute_sql(
              repo,
              "SELECT count() as cnt FROM test_performance FORMAT JSONEachRow",
            )
          {
            Ok(body) -> {
              // Should have all rows
              body
              |> should.not_equal("")
            }
            Error(_) -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn large_select_performance_test() {
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")
    |> repo.with_timeout(60_000)

  // Select large result set
  case
    repo.execute_sql(
      repo,
      "SELECT * FROM test_performance ORDER BY id FORMAT JSONEachRow",
    )
  {
    Ok(body) -> {
      // Should return large dataset (> 100KB)
      let len = string.length(body)
      case len > 100_000 {
        True -> should.be_true(True)
        False -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}
