/// Basic connectivity test - verifies ClickHouse is reachable and responds to queries
import gleeunit/should
import sparkling/repo

pub fn clickhouse_connection_test() {
  // Create repo pointing to docker-compose ClickHouse
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")

  // Test simple SELECT 1
  case repo.execute_sql(repo, "SELECT 1 as result FORMAT JSONEachRow") {
    Ok(body) -> {
      body
      |> should.equal("{\"result\":1}\n")
    }
    Error(_) -> {
      // Fail test with error message
      should.fail()
    }
  }
}

pub fn clickhouse_create_table_test() {
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")

  // Create test table
  let ddl =
    "CREATE TABLE IF NOT EXISTS test_basic (
      id UInt32,
      name String,
      created DateTime
    ) ENGINE = MergeTree()
    ORDER BY id"

  case repo.execute_sql(repo, ddl) {
    Ok(_) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

pub fn clickhouse_insert_select_test() {
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")

  // Insert data
  let insert =
    "INSERT INTO test_basic (id, name, created) VALUES (1, 'test', '2024-01-01 00:00:00')"

  case repo.execute_sql(repo, insert) {
    Ok(_) -> {
      // Select data back
      case
        repo.execute_sql(
          repo,
          "SELECT * FROM test_basic WHERE id = 1 FORMAT JSONEachRow",
        )
      {
        Ok(body) -> {
          // Verify we got data back
          should.not_equal(body, "")
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}
