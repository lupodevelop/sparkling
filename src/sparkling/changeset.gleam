/// Changeset module for casting and validating data before inserts/updates.
/// Provides an Ecto-like changeset pipeline for type-safe data manipulation.
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/string

/// Represents a changeset with changes, errors, and validation state
pub type Changeset(data) {
  Changeset(
    data: data,
    changes: Dict(String, String),
    errors: List(FieldError),
    valid: Bool,
  )
}

/// Represents a validation error for a specific field
pub type FieldError {
  FieldError(field: String, message: String)
}

/// Validator function type
pub type Validator(a) =
  fn(a) -> Result(a, String)

/// Create a new changeset from initial data
pub fn new(data: data) -> Changeset(data) {
  Changeset(data: data, changes: dict.new(), errors: [], valid: True)
}

/// Put a change (string value) into the changeset
pub fn put_change(
  changeset: Changeset(data),
  field: String,
  value: String,
) -> Changeset(data) {
  let changes = dict.insert(changeset.changes, field, value)
  Changeset(..changeset, changes: changes)
}

/// Validate that a field is required (must be present in changes)
pub fn validate_required(
  changeset: Changeset(data),
  field: String,
) -> Changeset(data) {
  case dict.get(changeset.changes, field) {
    Ok(_) -> changeset
    Error(_) ->
      add_error(changeset, field, "Field '" <> field <> "' is required")
  }
}

/// Validate string length (min and max)
pub fn validate_length(
  changeset: Changeset(data),
  field: String,
  min: Option(Int),
  max: Option(Int),
) -> Changeset(data) {
  case dict.get(changeset.changes, field) {
    Ok(value) -> {
      let len = string.length(value)
      case min, max {
        option.Some(min_len), _ if len < min_len ->
          add_error(
            changeset,
            field,
            "Field '"
              <> field
              <> "' must be at least "
              <> int.to_string(min_len)
              <> " characters",
          )
        _, option.Some(max_len) if len > max_len ->
          add_error(
            changeset,
            field,
            "Field '"
              <> field
              <> "' must be at most "
              <> int.to_string(max_len)
              <> " characters",
          )
        _, _ -> changeset
      }
    }
    Error(_) -> changeset
  }
}

/// Validate number is within range (min and max)
pub fn validate_number(
  changeset: Changeset(data),
  field: String,
  min: Option(Int),
  max: Option(Int),
) -> Changeset(data) {
  case dict.get(changeset.changes, field) {
    Ok(value_str) -> {
      case int.parse(value_str) {
        Ok(value) -> {
          case min, max {
            option.Some(min_val), _ if value < min_val ->
              add_error(
                changeset,
                field,
                "Field '"
                  <> field
                  <> "' must be at least "
                  <> int.to_string(min_val),
              )
            _, option.Some(max_val) if value > max_val ->
              add_error(
                changeset,
                field,
                "Field '"
                  <> field
                  <> "' must be at most "
                  <> int.to_string(max_val),
              )
            _, _ -> changeset
          }
        }
        Error(_) ->
          add_error(
            changeset,
            field,
            "Field '" <> field <> "' must be a number",
          )
      }
    }
    Error(_) -> changeset
  }
}

/// Validate string format (simple pattern matching)
pub fn validate_format(
  changeset: Changeset(data),
  field: String,
  check: fn(String) -> Bool,
  message: String,
) -> Changeset(data) {
  case dict.get(changeset.changes, field) {
    Ok(value) -> {
      case check(value) {
        True -> changeset
        False -> add_error(changeset, field, message)
      }
    }
    Error(_) -> changeset
  }
}

/// Add an error to the changeset
pub fn add_error(
  changeset: Changeset(data),
  field: String,
  message: String,
) -> Changeset(data) {
  let error = FieldError(field: field, message: message)
  Changeset(..changeset, errors: [error, ..changeset.errors], valid: False)
}

/// Get a change value by field name
pub fn get_change(
  changeset: Changeset(data),
  field: String,
) -> Result(String, Nil) {
  dict.get(changeset.changes, field)
}

/// Get all changes as a dict
pub fn get_changes(changeset: Changeset(data)) -> Dict(String, String) {
  changeset.changes
}

/// Get all errors
pub fn get_errors(changeset: Changeset(data)) -> List(FieldError) {
  changeset.errors
}

/// Check if changeset is valid
pub fn is_valid(changeset: Changeset(data)) -> Bool {
  changeset.valid
}

/// Apply changes to data (returns Result with errors if invalid)
pub fn apply(
  changeset: Changeset(data),
) -> Result(Changeset(data), List(FieldError)) {
  case changeset.valid {
    True -> Ok(changeset)
    False -> Error(changeset.errors)
  }
}

/// Format errors as a human-readable string
pub fn format_errors(errors: List(FieldError)) -> String {
  errors
  |> list.map(fn(err) { err.field <> ": " <> err.message })
  |> string.join(", ")
}

/// Helper: validate email format (simple check)
pub fn validate_email(
  changeset: Changeset(data),
  field: String,
) -> Changeset(data) {
  validate_format(
    changeset,
    field,
    fn(email) { string.contains(email, "@") && string.contains(email, ".") },
    "Invalid email format",
  )
}

/// Helper: validate that a string is not empty
pub fn validate_not_empty(
  changeset: Changeset(data),
  field: String,
) -> Changeset(data) {
  case dict.get(changeset.changes, field) {
    Ok(value) -> {
      case string.trim(value) {
        "" ->
          add_error(changeset, field, "Field '" <> field <> "' cannot be empty")
        _ -> changeset
      }
    }
    Error(_) -> changeset
  }
}
