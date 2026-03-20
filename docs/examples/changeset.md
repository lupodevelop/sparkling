# Changeset

`sparkling/changeset` provides Ecto-style data casting and validation.

## Basic usage

```gleam
import gleam/option.{None, Some}
import sparkling/changeset

type UserData {
  UserData(name: String, email: String, age: Int)
}

let data = UserData(name: "", email: "", age: 0)

let cs =
  changeset.new(data)
  |> changeset.put_change("name", "Alice")
  |> changeset.put_change("email", "alice@example.com")
  |> changeset.put_change("age", "28")
  |> changeset.validate_required("name")
  |> changeset.validate_required("email")
  |> changeset.validate_email("email")
  |> changeset.validate_length("name", Some(2), Some(100))
  |> changeset.validate_number("age", Some(0), Some(120))

case changeset.apply(cs) {
  Ok(_) -> io.println("valid!")
  Error(errors) -> io.println(changeset.format_errors(errors))
}
```

## Validators

```gleam
// Required — field must be present in changes
|> changeset.validate_required("name")

// Length — min/max for string fields
|> changeset.validate_length("name", Some(2), Some(100))
|> changeset.validate_length("bio", None, Some(500))  // max only

// Number — min/max for int fields (value parsed from change string)
|> changeset.validate_number("age", Some(0), Some(120))

// Email format
|> changeset.validate_email("email")

// Not empty string
|> changeset.validate_not_empty("name")

// Custom format check
|> changeset.validate_format("slug", fn(v) {
  string.all(v, fn(c) { c == "-" || c >= "a" && c <= "z" || c >= "0" && c <= "9" })
}, "must contain only lowercase letters, digits, and hyphens")
```

## Reading changes and errors

```gleam
changeset.is_valid(cs)     // => True / False
changeset.get_changes(cs)  // => Dict(String, String)
changeset.get_errors(cs)   // => List(FieldError)

case changeset.get_change(cs, "name") {
  Ok(name) -> io.println("name is: " <> name)
  Error(Nil) -> io.println("name not set")
}
```

## Manual errors

```gleam
let cs =
  changeset.new(data)
  |> changeset.put_change("email", "alice@example.com")
  |> changeset.add_error("email", "already taken")

changeset.format_errors(changeset.get_errors(cs))
// => "email: already taken"
```
