# Tests — Quick reference

This document explains how tests are organised in the repository and how to run them locally and in CI.

Directory layout

- `test/sparkling/` — unit and component tests that do not require external services (fast).
- `test/smoke/` — smoke/sanity tests. Quick checks that the test runner and a minimal API behave as expected.
- `test/integration/` — integration tests that require external services (e.g. ClickHouse). These are slower and should not run on every PR.

Running tests locally

- Run the full test suite (if you have required services available):

```bash
# from the project root
gleam test
```

- Run unit tests only (recommended for PRs):

```bash
# if your test runner accepts paths:
gleam test test/sparkling
```

If your runner does not accept paths, run `gleam test` locally and ensure integration tests are not executed by default (integration tests should be placed under `test/integration/`).

- Run integration tests (requires ClickHouse or other external services):

```bash
# Start ClickHouse (example using Docker)
docker run -d --name clickhouse-server -p 8123:8123 -p 9000:9000 clickhouse/clickhouse-server:latest

# Run integration tests
gleam test test/integration

# When finished, stop/remove the container
docker stop clickhouse-server && docker rm clickhouse-server
```

Environment variables

- Use environment variables to configure integration endpoints (example):

```bash
export CLICKHOUSE_URL=http://localhost:8123
```

Document required variables in `test/integration/README.md`.

CI guidance

- Pull Requests: run unit tests only.
- Integration tests: run in separate CI jobs (manual trigger, nightly, or on release tags). Ensure the CI environment has access to required services and secrets before enabling integration jobs.

Best practices and PR checklist

- [ ] Unit tests pass locally (`gleam test`).
- [ ] Integration tests are documented in `test/integration/README.md` with clear prerequisites and run instructions.
- [ ] Do not add CI workflows that perform sensitive operations (publishing) in the import PR. Add automation in a separate PR after the code is stable.
- [ ] Keep a lightweight smoke test under `test/smoke/` to validate the test runner and minimal API surface.