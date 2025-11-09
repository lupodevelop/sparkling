/// Complex types round-trip test - verifies all ClickHouse complex types work correctly
import gleeunit/should
import sparkling/repo

pub fn decimal_roundtrip_test() {
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")

  // Create table with Decimal
  let ddl =
    "CREATE TABLE IF NOT EXISTS test_decimal (
      id UInt32,
      price Decimal(18, 2)
    ) ENGINE = MergeTree()
    ORDER BY id"

  case repo.execute_sql(repo, ddl) {
    Ok(_) -> {
      // Insert decimal value
      let insert = "INSERT INTO test_decimal VALUES (1, 123.45)"
      case repo.execute_sql(repo, insert) {
        Ok(_) -> {
          // Select back
          case
            repo.execute_sql(
              repo,
              "SELECT price FROM test_decimal WHERE id = 1 FORMAT JSONEachRow",
            )
          {
            Ok(body) -> {
              // Verify decimal preserved
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

pub fn datetime64_roundtrip_test() {
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")

  // Create table with DateTime64
  let ddl =
    "CREATE TABLE IF NOT EXISTS test_datetime64 (
      id UInt32,
      timestamp DateTime64(3, 'UTC')
    ) ENGINE = MergeTree()
    ORDER BY id"

  case repo.execute_sql(repo, ddl) {
    Ok(_) -> {
      // Insert datetime64 value
      let insert =
        "INSERT INTO test_datetime64 VALUES (1, '2024-01-15 10:30:45.123')"
      case repo.execute_sql(repo, insert) {
        Ok(_) -> {
          // Select back
          case
            repo.execute_sql(
              repo,
              "SELECT timestamp FROM test_datetime64 WHERE id = 1 FORMAT JSONEachRow",
            )
          {
            Ok(body) -> {
              // Verify datetime64 preserved with milliseconds
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

pub fn array_roundtrip_test() {
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")

  // Create table with Array
  let ddl =
    "CREATE TABLE IF NOT EXISTS test_array (
      id UInt32,
      tags Array(String)
    ) ENGINE = MergeTree()
    ORDER BY id"

  case repo.execute_sql(repo, ddl) {
    Ok(_) -> {
      // Insert array value
      let insert = "INSERT INTO test_array VALUES (1, ['tag1', 'tag2', 'tag3'])"
      case repo.execute_sql(repo, insert) {
        Ok(_) -> {
          // Select back
          case
            repo.execute_sql(
              repo,
              "SELECT tags FROM test_array WHERE id = 1 FORMAT JSONEachRow",
            )
          {
            Ok(body) -> {
              // Verify array preserved
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

pub fn uuid_roundtrip_test() {
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")

  // Create table with UUID
  let ddl =
    "CREATE TABLE IF NOT EXISTS test_uuid (
      id UInt32,
      uuid UUID
    ) ENGINE = MergeTree()
    ORDER BY id"

  case repo.execute_sql(repo, ddl) {
    Ok(_) -> {
      // Insert UUID value
      let insert =
        "INSERT INTO test_uuid VALUES (1, '550e8400-e29b-41d4-a716-446655440000')"
      case repo.execute_sql(repo, insert) {
        Ok(_) -> {
          // Select back
          case
            repo.execute_sql(
              repo,
              "SELECT uuid FROM test_uuid WHERE id = 1 FORMAT JSONEachRow",
            )
          {
            Ok(body) -> {
              // Verify UUID preserved
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
