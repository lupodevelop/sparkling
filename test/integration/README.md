# Integration tests

Integration tests that exercise the code against a real ClickHouse instance.

This document explains how to run integration tests locally and how to wire them into CI in a safe way.

Prerequisites

- Docker (used for the example below).
- docker-compose (optional, if you prefer a compose-based setup).

Recommended local setup (Docker Compose)

1. Start ClickHouse with docker-compose (example):

```bash
# from the repository root, if you have a docker-compose.yml configured
docker-compose up -d
```

2. Wait for the server to be ready:

```bash
docker-compose ps
```

3. Run only the integration tests:

```bash
# from the repository root
gleam test test/integration
```

4. Tear down the environment when finished:

```bash
docker-compose down -v
```

Quick single-container alternative (no compose)

```bash
docker run -d --name clickhouse-server -p 8123:8123 -p 9000:9000 clickhouse/clickhouse-server:latest
# wait for readiness, then run tests
gleam test test/integration
docker stop clickhouse-server && docker rm clickhouse-server
```

Connection details (local defaults)

- URL: http://localhost:8123
- Database: test_db (tests may create/drop their own DBs)
- User: test_user
- Password: test_password

If your tests require different credentials or endpoints, set the appropriate environment variables (see the `Environment variables` section below).

Implemented integration tests

- `basic_connectivity_test.gleam` — verifies connection and basic queries
- `complex_types_roundtrip_test.gleam` — round-trip tests for complex ClickHouse types
- `format_compatibility_test.gleam` — tests different I/O formats (JSONEachRow, CSV, TabSeparated)
- `performance_test.gleam` — optional performance/load checks (may be slow)

Environment variables

Use environment variables to configure endpoints and credentials for integration tests. Example:

```bash
export CLICKHOUSE_URL=http://localhost:8123
export CLICKHOUSE_USER=test_user
export CLICKHOUSE_PASSWORD=test_password
```

Document required environment variables and secrets clearly before enabling integration jobs in CI.

CI guidance

- Integration tests should not run by default on every PR. Run them in separate CI jobs, e.g. on manual dispatch, nightly builds, or release tags.
- Example GitHub Actions job (run in a dedicated workflow or as a separate job):

```yaml
- name: Integration tests (optional)
  run: |
    docker-compose up -d
    # optionally wait / healthcheck
    sleep 10
    gleam test test/integration
    docker-compose down -v
  # do not fail the whole pipeline if integration env is missing
  continue-on-error: true
```

Notes and recommendations

- Keep integration tests isolated and idempotent: tests should create and drop any resources they need.
- Mark expensive or flaky tests (e.g. `performance_test.gleam`) so CI can skip them unless explicitly requested.
- Before enabling integration tests in CI, ensure any required secrets or credentials are set in the CI environment.
