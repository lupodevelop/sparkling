/// Expression AST for building SQL expressions in a type-safe way.
/// Supports literals, column references, comparisons, logical operators,
/// functions, and aggregates for ClickHouse queries.
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// SQL expression AST node
pub type Expr {
  // Literals
  IntLiteral(Int)
  FloatLiteral(Float)
  StringLiteral(String)
  BoolLiteral(Bool)
  Null

  // Column reference
  Field(String)

  // Comparison operators
  Eq(Expr, Expr)
  Ne(Expr, Expr)
  Lt(Expr, Expr)
  Le(Expr, Expr)
  Gt(Expr, Expr)
  Ge(Expr, Expr)

  // Logical operators
  And(Expr, Expr)
  Or(Expr, Expr)
  Not(Expr)

  // Arithmetic operators
  Add(Expr, Expr)
  Sub(Expr, Expr)
  Mul(Expr, Expr)
  Div(Expr, Expr)

  // Aggregate functions
  Count(Option(Expr))
  Sum(Expr)
  Avg(Expr)
  Min(Expr)
  Max(Expr)

  // Functions
  FunctionCall(name: String, args: List(Expr))

  // Array and tuple literals
  ArrayLiteral(List(Expr))
  TupleLiteral(List(Expr))

  // IN operator
  In(Expr, List(Expr))

  // BETWEEN operator
  Between(Expr, Expr, Expr)

  // IS NULL / IS NOT NULL
  IsNull(Expr)
  IsNotNull(Expr)

  // CASE expression
  Case(
    expr: Option(Expr),
    when_clauses: List(#(Expr, Expr)),
    else_clause: Option(Expr),
  )

  // CAST
  Cast(Expr, String)

  // Alias (for SELECT expressions)
  As(Expr, String)
}

/// Convert an expression AST to ClickHouse SQL string.
/// This function ensures proper escaping and ClickHouse-safe syntax.
pub fn to_sql(expr: Expr) -> String {
  case expr {
    IntLiteral(n) -> int.to_string(n)
    FloatLiteral(f) -> float.to_string(f)
    StringLiteral(s) -> "'" <> escape_string(s) <> "'"
    BoolLiteral(True) -> "true"
    BoolLiteral(False) -> "false"
    Null -> "NULL"

    Field(name) -> escape_identifier(name)

    Eq(left, right) -> to_sql(left) <> " = " <> to_sql(right)
    Ne(left, right) -> to_sql(left) <> " != " <> to_sql(right)
    Lt(left, right) -> to_sql(left) <> " < " <> to_sql(right)
    Le(left, right) -> to_sql(left) <> " <= " <> to_sql(right)
    Gt(left, right) -> to_sql(left) <> " > " <> to_sql(right)
    Ge(left, right) -> to_sql(left) <> " >= " <> to_sql(right)

    And(left, right) -> "(" <> to_sql(left) <> " AND " <> to_sql(right) <> ")"
    Or(left, right) -> "(" <> to_sql(left) <> " OR " <> to_sql(right) <> ")"
    Not(e) -> "NOT (" <> to_sql(e) <> ")"

    Add(left, right) -> "(" <> to_sql(left) <> " + " <> to_sql(right) <> ")"
    Sub(left, right) -> "(" <> to_sql(left) <> " - " <> to_sql(right) <> ")"
    Mul(left, right) -> "(" <> to_sql(left) <> " * " <> to_sql(right) <> ")"
    Div(left, right) -> "(" <> to_sql(left) <> " / " <> to_sql(right) <> ")"

    Count(None) -> "COUNT(*)"
    Count(Some(e)) -> "COUNT(" <> to_sql(e) <> ")"
    Sum(e) -> "SUM(" <> to_sql(e) <> ")"
    Avg(e) -> "AVG(" <> to_sql(e) <> ")"
    Min(e) -> "MIN(" <> to_sql(e) <> ")"
    Max(e) -> "MAX(" <> to_sql(e) <> ")"

    FunctionCall(name, args) -> {
      let args_sql = list.map(args, to_sql) |> string.join(", ")
      name <> "(" <> args_sql <> ")"
    }

    ArrayLiteral(items) -> {
      let items_sql = list.map(items, to_sql) |> string.join(", ")
      "[" <> items_sql <> "]"
    }

    TupleLiteral(items) -> {
      let items_sql = list.map(items, to_sql) |> string.join(", ")
      "(" <> items_sql <> ")"
    }

    In(expr, values) -> {
      let values_sql = list.map(values, to_sql) |> string.join(", ")
      to_sql(expr) <> " IN (" <> values_sql <> ")"
    }

    Between(expr, low, high) ->
      to_sql(expr) <> " BETWEEN " <> to_sql(low) <> " AND " <> to_sql(high)

    IsNull(e) -> to_sql(e) <> " IS NULL"
    IsNotNull(e) -> to_sql(e) <> " IS NOT NULL"

    Case(expr, when_clauses, else_clause) -> {
      let case_start = case expr {
        Some(e) -> "CASE " <> to_sql(e)
        None -> "CASE"
      }

      let when_parts =
        list.map(when_clauses, fn(clause) {
          let #(condition, result) = clause
          " WHEN " <> to_sql(condition) <> " THEN " <> to_sql(result)
        })
        |> string.join("")

      let else_part = case else_clause {
        Some(e) -> " ELSE " <> to_sql(e)
        None -> ""
      }

      case_start <> when_parts <> else_part <> " END"
    }

    Cast(e, type_name) -> "CAST(" <> to_sql(e) <> " AS " <> type_name <> ")"

    As(e, alias) -> to_sql(e) <> " AS " <> escape_identifier(alias)
  }
}

/// Escape a string literal for ClickHouse SQL (single quotes).
/// ClickHouse uses backslash escaping for special characters.
fn escape_string(s: String) -> String {
  s
  |> string.replace("\\", "\\\\")
  |> string.replace("'", "\\'")
  |> string.replace("\n", "\\n")
  |> string.replace("\r", "\\r")
  |> string.replace("\t", "\\t")
}

/// Escape an identifier (column name, table name) for ClickHouse.
/// ClickHouse uses backticks for identifiers that need escaping.
/// For simple alphanumeric names (and underscores), no escaping is needed.
/// Reference: https://clickhouse.com/docs/en/sql-reference/syntax#identifiers
fn escape_identifier(name: String) -> String {
  case needs_escaping(name) {
    True -> "`" <> string.replace(name, "`", "``") <> "`"
    False -> name
  }
}

/// Check if an identifier needs escaping (contains special chars or is a reserved keyword).
fn needs_escaping(name: String) -> Bool {
  is_reserved_keyword(name) || contains_special_chars(name)
}

/// Check if a name is a ClickHouse reserved keyword.
/// List based on ClickHouse documentation (non-exhaustive, common keywords).
/// Reference: https://clickhouse.com/docs/en/sql-reference/syntax#keywords
fn is_reserved_keyword(name: String) -> Bool {
  let lowercase = string.lowercase(name)
  case lowercase {
    "select"
    | "from"
    | "where"
    | "and"
    | "or"
    | "not"
    | "in"
    | "as"
    | "on"
    | "join"
    | "left"
    | "right"
    | "inner"
    | "outer"
    | "cross"
    | "full"
    | "group"
    | "by"
    | "order"
    | "having"
    | "limit"
    | "offset"
    | "union"
    | "all"
    | "distinct"
    | "case"
    | "when"
    | "then"
    | "else"
    | "end"
    | "null"
    | "is"
    | "between"
    | "like"
    | "ilike"
    | "exists"
    | "any"
    | "array"
    | "tuple"
    | "cast"
    | "extract"
    | "interval"
    | "date"
    | "time"
    | "timestamp"
    | "datetime"
    | "table"
    | "database"
    | "create"
    | "drop"
    | "alter"
    | "insert"
    | "into"
    | "values"
    | "update"
    | "delete"
    | "set"
    | "truncate"
    | "rename"
    | "describe"
    | "explain"
    | "show"
    | "use"
    | "grant"
    | "revoke"
    | "if"
    | "primary"
    | "key"
    | "index"
    | "default"
    | "materialized"
    | "view"
    | "engine"
    | "partition"
    | "sample"
    | "final"
    | "prewhere"
    | "global"
    | "with"
    | "totals"
    | "format"
    | "settings"
    | "optimize"
    | "check"
    | "attach"
    | "detach"
    | "system"
    | "kill"
    | "query"
    | "mutation" -> True
    _ -> False
  }
}

/// Check if a name contains characters that require escaping.
/// Safe characters: alphanumeric (a-z, A-Z, 0-9) and underscore (_).
/// First character must be a letter or underscore.
fn contains_special_chars(name: String) -> Bool {
  case name {
    "" -> True
    _ -> {
      let graphemes = string.to_graphemes(name)
      case graphemes {
        [] -> True
        [first, ..rest] -> {
          let first_valid = is_letter_or_underscore(first)
          let rest_valid = list.all(rest, is_alphanumeric_or_underscore)
          !first_valid || !rest_valid
        }
      }
    }
  }
}

/// Check if a grapheme is a letter (a-z, A-Z) or underscore.
fn is_letter_or_underscore(grapheme: String) -> Bool {
  case grapheme {
    "a"
    | "b"
    | "c"
    | "d"
    | "e"
    | "f"
    | "g"
    | "h"
    | "i"
    | "j"
    | "k"
    | "l"
    | "m"
    | "n"
    | "o"
    | "p"
    | "q"
    | "r"
    | "s"
    | "t"
    | "u"
    | "v"
    | "w"
    | "x"
    | "y"
    | "z"
    | "A"
    | "B"
    | "C"
    | "D"
    | "E"
    | "F"
    | "G"
    | "H"
    | "I"
    | "J"
    | "K"
    | "L"
    | "M"
    | "N"
    | "O"
    | "P"
    | "Q"
    | "R"
    | "S"
    | "T"
    | "U"
    | "V"
    | "W"
    | "X"
    | "Y"
    | "Z"
    | "_" -> True
    _ -> False
  }
}

/// Check if a grapheme is alphanumeric (a-z, A-Z, 0-9) or underscore.
fn is_alphanumeric_or_underscore(grapheme: String) -> Bool {
  case grapheme {
    "a"
    | "b"
    | "c"
    | "d"
    | "e"
    | "f"
    | "g"
    | "h"
    | "i"
    | "j"
    | "k"
    | "l"
    | "m"
    | "n"
    | "o"
    | "p"
    | "q"
    | "r"
    | "s"
    | "t"
    | "u"
    | "v"
    | "w"
    | "x"
    | "y"
    | "z"
    | "A"
    | "B"
    | "C"
    | "D"
    | "E"
    | "F"
    | "G"
    | "H"
    | "I"
    | "J"
    | "K"
    | "L"
    | "M"
    | "N"
    | "O"
    | "P"
    | "Q"
    | "R"
    | "S"
    | "T"
    | "U"
    | "V"
    | "W"
    | "X"
    | "Y"
    | "Z"
    | "0"
    | "1"
    | "2"
    | "3"
    | "4"
    | "5"
    | "6"
    | "7"
    | "8"
    | "9"
    | "_" -> True
    _ -> False
  }
}

/// Helper: create a field reference
pub fn field(name: String) -> Expr {
  Field(name)
}

/// Helper: create an integer literal
pub fn int(n: Int) -> Expr {
  IntLiteral(n)
}

/// Helper: create a float literal
pub fn float(f: Float) -> Expr {
  FloatLiteral(f)
}

/// Helper: create a string literal
pub fn string(s: String) -> Expr {
  StringLiteral(s)
}

/// Helper: create a boolean literal
pub fn bool(b: Bool) -> Expr {
  BoolLiteral(b)
}

/// Helper: create a NULL literal
pub fn null() -> Expr {
  Null
}

/// Helper: create an equality comparison
pub fn eq(left: Expr, right: Expr) -> Expr {
  Eq(left, right)
}

/// Helper: create a not-equal comparison
pub fn ne(left: Expr, right: Expr) -> Expr {
  Ne(left, right)
}

/// Helper: create a less-than comparison
pub fn lt(left: Expr, right: Expr) -> Expr {
  Lt(left, right)
}

/// Helper: create a greater-than comparison
pub fn gt(left: Expr, right: Expr) -> Expr {
  Gt(left, right)
}

/// Helper: create an AND expression
pub fn and(left: Expr, right: Expr) -> Expr {
  And(left, right)
}

/// Helper: create an OR expression
pub fn or(left: Expr, right: Expr) -> Expr {
  Or(left, right)
}

/// Helper: create a NOT expression
pub fn not(e: Expr) -> Expr {
  Not(e)
}

/// Helper: create an alias
pub fn alias(e: Expr, alias_name: String) -> Expr {
  As(e, alias_name)
}

/// Helper: create a COUNT aggregate
pub fn count(expr: Option(Expr)) -> Expr {
  Count(expr)
}

/// Helper: create a COUNT(*) aggregate
pub fn count_all() -> Expr {
  Count(None)
}
