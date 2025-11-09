/// Format compatibility test - verifies all supported formats work correctly
import gleeunit/should
import sparkling/repo

pub fn json_each_row_format_test() {
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")

  // Query with JSONEachRow format (default)
  case
    repo.execute_sql(
      repo,
      "SELECT number, toString(number) as text FROM numbers(3) FORMAT JSONEachRow",
    )
  {
    Ok(body) -> {
      // Should return newline-separated JSON objects
      body
      |> should.not_equal("")
    }
    Error(_) -> should.fail()
  }
}

pub fn tab_separated_format_test() {
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")

  // Query with TabSeparated format
  case
    repo.execute_sql(
      repo,
      "SELECT number, toString(number) FROM numbers(3) FORMAT TabSeparated",
    )
  {
    Ok(body) -> {
      // Should return tab-separated values
      body
      |> should.not_equal("")
    }
    Error(_) -> should.fail()
  }
}

pub fn csv_format_test() {
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")

  // Query with CSV format
  case
    repo.execute_sql(
      repo,
      "SELECT number, toString(number) FROM numbers(3) FORMAT CSV",
    )
  {
    Ok(body) -> {
      // Should return comma-separated values
      body
      |> should.not_equal("")
    }
    Error(_) -> should.fail()
  }
}

pub fn json_format_test() {
  let repo =
    repo.new("http://localhost:8123")
    |> repo.with_credentials("test_user", "test_password")
    |> repo.with_database("test_db")

  // Query with JSON format (single JSON object with metadata)
  case repo.execute_sql(repo, "SELECT number FROM numbers(3) FORMAT JSON") {
    Ok(body) -> {
      // Should return single JSON object with "data" array
      body
      |> should.not_equal("")
    }
    Error(_) -> should.fail()
  }
}
