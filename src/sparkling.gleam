// Core imports (must come before re-exports)
/// Sparkling - An Ecto-like data layer for ClickHouse in Gleam
/// 
/// This library provides a type-safe, composable API for working with ClickHouse:
/// - Schema definitions with typed tables and fields
/// - Query builder DSL for SELECT/INSERT operations
/// - Repository pattern with HTTP transport
/// - Encode/decode for multiple formats (JSONEachRow, TabSeparated, CSV)
/// - Changeset validation pipeline
/// - Support for complex ClickHouse types (Decimal, DateTime64, Array, Map, UUID, etc.)
/// 
/// Examples: docs/quickstart.md
///
/// # Main Modules
/// 
/// - `sparkling/schema` - Table and field definitions
/// - `sparkling/expr` - SQL expression AST
/// - `sparkling/query` - Query builder DSL
/// - `sparkling/repo` - Repository with HTTP transport
/// - `sparkling/encode` - Encoding to ClickHouse formats
/// - `sparkling/decode` - Decoding from ClickHouse formats
/// - `sparkling/changeset` - Validation pipeline
/// - `sparkling/types` - Complex ClickHouse types (Decimal, DateTime64, etc.)
/// - `sparkling/format` - Format handlers registry
import sparkling/changeset
import sparkling/expr
import sparkling/format
import sparkling/query
import sparkling/repo
import sparkling/schema
import sparkling/types

// Re-export main types for convenience
pub type Repo =
  repo.Repo

pub type RepoError =
  repo.RepoError

pub type Query =
  query.Query

pub type Table =
  schema.Table

pub type Field =
  schema.Field

pub type FieldType =
  schema.FieldType

pub type Expr =
  expr.Expr

pub type Changeset(a) =
  changeset.Changeset(a)

pub type FormatHandler =
  format.FormatHandler

// Re-export common complex types
pub type Decimal =
  types.Decimal

pub type DateTime64 =
  types.DateTime64

pub type UUID =
  types.UUID

pub type LowCardinality =
  types.LowCardinality

pub type Enum8 =
  types.Enum8

pub type Enum16 =
  types.Enum16
