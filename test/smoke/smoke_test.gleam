import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// Smoke test: ensures the test runner is wired and performs a minimal API check.
pub fn smoke_api_check_test() {
  let name = "Sparkling"
  let greeting = "Hello, " <> name <> "!"

  assert greeting == "Hello, Sparkling!"
}
