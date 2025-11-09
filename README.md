# Sparkling

<p align="center">
  <img src="assets/image.png" alt="Sparkling logo" width="240" />
</p>

[![CI](https://github.com/lupodevelop/sparkling/actions/workflows/ci.yml/badge.svg)](https://github.com/lupodevelop/sparkling/actions/workflows/ci.yml) [![License](https://img.shields.io/badge/license-Apache%202.0-yellow.svg)](LICENSE) [![Built with Gleam](https://img.shields.io/badge/Built%20with-Gleam-ffaff3)](https://gleam.run) [![Gleam Version](https://img.shields.io/badge/gleam-%3E%3D1.13.0-ffaff3)](https://gleam.run)

**Sparkling** is a *lightweight*, **type-safe** data layer for **ClickHouse** written in Gleam. It provides a small, focused API for defining schemas, building queries, and encoding/decoding ClickHouse formats.

*No magic*, just small, composable functions that play nicely in Gleam apps.

> Why "Sparkling"? One rainy Tuesday a tiny inflatable rubber duck stole a shooting pink star and decided to become a freelance data wrangler, and it now guides queries through the night, humming 8-bit lullabies. Totally plausible.

## Quick start

See the extracted quick start example: `docs/quickstart.md` it contains a short walkthrough (define schema, build a query, execute it with a repo).

Minimal example:

```gleam
import sparkling/repo

let r = repo.new("http://localhost:8123")
  |> repo.with_database("mydb")

case r.execute_sql(r, "SELECT 1 as result FORMAT JSONEachRow") {
  Ok(body) -> io.println(body)
  Error(_) -> io.println("query failed")
}
```

## What you'll find here

- `sparkling/schema` — typed table & column definitions
- `sparkling/query` — immutable query builder (to_sql)
- `sparkling/repo` — HTTP executor with retry hooks
- `sparkling/encode` / `sparkling/decode` — format handlers (JSONEachRow default)
- `sparkling/types` — helpers for Decimal, DateTime64, UUID, LowCardinality

For more examples see `docs/examples/` and `docs/quickstart.md`.

**Design note:** Sparkling's API and composable query builder were partly inspired by *Ecto*; 
many ideas about schema definition and query composition borrow from its approach while keeping a small, Gleam-friendly surface.

## Development

Run tests and format/check locally:

```sh
# format and check
gleam format --check

# build
gleam build

# run the test suite
gleam test
```

## Contributing

Contributions are welcome. Open an issue or a PR with a short description of the change. Keep commits small and add tests where appropriate.

## License

Apache-2.0 --- see the top-level `LICENSE` file for the full text.

Enjoy. May your queries be fast and your schemas tidy!