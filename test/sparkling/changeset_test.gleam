import gleam/dict
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import sparkling/changeset.{
  FieldError, add_error, apply, format_errors, get_change, get_changes,
  get_errors, is_valid, new, put_change, validate_email, validate_format,
  validate_length, validate_not_empty, validate_number, validate_required,
}

pub fn main() {
  gleeunit.main()
}

// Simple data type for testing
pub type User {
  User(name: String, age: Int)
}

// Test: create new changeset
pub fn new_changeset_test() {
  let user = User("Alice", 30)
  let cs = new(user)

  is_valid(cs) |> should.be_true
  get_errors(cs) |> should.equal([])
}

// Test: put change
pub fn put_change_test() {
  let user = User("Alice", 30)
  let cs = new(user) |> put_change("name", "Bob")

  get_change(cs, "name") |> should.be_ok |> should.equal("Bob")
}

// Test: validate required (field present)
pub fn validate_required_present_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("name", "Bob")
    |> validate_required("name")

  is_valid(cs) |> should.be_true
}

// Test: validate required (field missing)
pub fn validate_required_missing_test() {
  let user = User("Alice", 30)
  let cs = new(user) |> validate_required("name")

  is_valid(cs) |> should.be_false
  get_errors(cs)
  |> should.equal([FieldError("name", "Field 'name' is required")])
}

// Test: validate length (min)
pub fn validate_length_min_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("name", "Bo")
    |> validate_length("name", Some(3), None)

  is_valid(cs) |> should.be_false
  get_errors(cs)
  |> should.equal([
    FieldError("name", "Field 'name' must be at least 3 characters"),
  ])
}

// Test: validate length (max)
pub fn validate_length_max_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("name", "VeryLongName")
    |> validate_length("name", None, Some(10))

  is_valid(cs) |> should.be_false
  get_errors(cs)
  |> should.equal([
    FieldError("name", "Field 'name' must be at most 10 characters"),
  ])
}

// Test: validate length (valid)
pub fn validate_length_valid_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("name", "Bob")
    |> validate_length("name", Some(2), Some(5))

  is_valid(cs) |> should.be_true
}

// Test: validate number (min)
pub fn validate_number_min_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("age", "17")
    |> validate_number("age", Some(18), None)

  is_valid(cs) |> should.be_false
  get_errors(cs)
  |> should.equal([FieldError("age", "Field 'age' must be at least 18")])
}

// Test: validate number (max)
pub fn validate_number_max_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("age", "100")
    |> validate_number("age", None, Some(99))

  is_valid(cs) |> should.be_false
  get_errors(cs)
  |> should.equal([FieldError("age", "Field 'age' must be at most 99")])
}

// Test: validate number (valid)
pub fn validate_number_valid_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("age", "25")
    |> validate_number("age", Some(18), Some(65))

  is_valid(cs) |> should.be_true
}

// Test: validate number (invalid format)
pub fn validate_number_invalid_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("age", "not_a_number")
    |> validate_number("age", None, None)

  is_valid(cs) |> should.be_false
  get_errors(cs)
  |> should.equal([FieldError("age", "Field 'age' must be a number")])
}

// Test: validate format (valid)
pub fn validate_format_valid_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("code", "ABC123")
    |> validate_format("code", fn(v) { v == "ABC123" }, "Invalid code")

  is_valid(cs) |> should.be_true
}

// Test: validate format (invalid)
pub fn validate_format_invalid_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("code", "XYZ")
    |> validate_format("code", fn(v) { v == "ABC123" }, "Invalid code")

  is_valid(cs) |> should.be_false
  get_errors(cs) |> should.equal([FieldError("code", "Invalid code")])
}

// Test: validate email (valid)
pub fn validate_email_valid_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("email", "alice@example.com")
    |> validate_email("email")

  is_valid(cs) |> should.be_true
}

// Test: validate email (invalid)
pub fn validate_email_invalid_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("email", "invalid-email")
    |> validate_email("email")

  is_valid(cs) |> should.be_false
  get_errors(cs) |> should.equal([FieldError("email", "Invalid email format")])
}

// Test: validate not empty (valid)
pub fn validate_not_empty_valid_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("name", "Bob")
    |> validate_not_empty("name")

  is_valid(cs) |> should.be_true
}

// Test: validate not empty (invalid)
pub fn validate_not_empty_invalid_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("name", "   ")
    |> validate_not_empty("name")

  is_valid(cs) |> should.be_false
  get_errors(cs)
  |> should.equal([FieldError("name", "Field 'name' cannot be empty")])
}

// Test: multiple validations (all valid)
pub fn multiple_validations_valid_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("name", "Bob")
    |> put_change("age", "25")
    |> validate_required("name")
    |> validate_required("age")
    |> validate_length("name", Some(2), Some(10))
    |> validate_number("age", Some(18), Some(65))

  is_valid(cs) |> should.be_true
}

// Test: multiple validations (some invalid)
pub fn multiple_validations_invalid_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("name", "X")
    |> put_change("age", "17")
    |> validate_required("name")
    |> validate_required("age")
    |> validate_length("name", Some(2), Some(10))
    |> validate_number("age", Some(18), Some(65))

  is_valid(cs) |> should.be_false
  // Should have 2 errors
  get_errors(cs) |> should.not_equal([])
}

// Test: apply (valid changeset)
pub fn apply_valid_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("name", "Bob")
    |> validate_required("name")

  apply(cs) |> should.be_ok
}

// Test: apply (invalid changeset)
pub fn apply_invalid_test() {
  let user = User("Alice", 30)
  let cs = new(user) |> validate_required("name")

  apply(cs) |> should.be_error
}

// Test: format errors
pub fn format_errors_test() {
  let errors = [
    FieldError("name", "Name is required"),
    FieldError("age", "Age must be at least 18"),
  ]

  format_errors(errors)
  |> should.equal("name: Name is required, age: Age must be at least 18")
}

// Test: add error manually
pub fn add_error_test() {
  let user = User("Alice", 30)
  let cs = new(user) |> add_error("custom", "Custom error message")

  is_valid(cs) |> should.be_false
  get_errors(cs)
  |> should.equal([FieldError("custom", "Custom error message")])
}

// Test: get changes
pub fn get_changes_test() {
  let user = User("Alice", 30)
  let cs =
    new(user)
    |> put_change("name", "Bob")
    |> put_change("age", "25")

  let changes = get_changes(cs)
  dict.size(changes) |> should.equal(2)
}
