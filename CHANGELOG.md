# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- (Unreleased changes go here)

## [0.1.0] - 2025-11-09

### Added

- Initial release of sparkling — Gleam ClickHouse client
- Type-safe query builder with composable DSL
- Schema reflection and metadata discovery
- Multiple format support (JSONEachRow, TabSeparated, CSV)
- Changeset validation (Ecto-style)
- HTTP resilience with exponential backoff retry
- Hook system for extensibility and observability
- Comprehensive test suite (unit + integration)
- Docker setup for testing with ClickHouse
- Query Module: composable SELECT/INSERT queries with type safety
- Schema Module: table/column reflection via DESCRIBE queries
- Repo Module: HTTP execution with authentication and error handling
- Encode/Decode: format registry with pluggable handlers
- Changeset: data validation and casting pipeline
- Retry: automatic failure recovery with configurable backoff

### Supported ClickHouse types

- Primitives: UInt/Int 8/16/32/64, Float32/64, String, Bool
- Date/Time: Date, Date32, DateTime, DateTime64
- Complex: Array(T), Tuple(...), Map(K,V), Nested
- Special: UUID, Enum8/16, Nullable(T), Decimal

### Architecture

- HTTP-only communication (no native protocol)
- Zero external dependencies
- Immutable, functional design
- Hook-based extensibility
- Comprehensive error handling

### Testing

- Unit tests with HTTP mocking
- Integration tests with ClickHouse Docker
- Round-trip tests for type safety
- CI/CD with GitHub Actions

### Documentation

- API reference and examples
- Quick start guide
- Style guide for contributions

<!-- Link references for versions -->
[Unreleased]: https://github.com/lupodevelop/sparkling/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/lupodevelop/sparkling/releases/tag/v0.1.0
