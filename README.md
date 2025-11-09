# Sparkling

<p align="center">
  <img src="assets/image.png" alt="Sparkling logo" width="240" />
</p>

[![License](https://img.shields.io/badge/license-Apache%202.0-yellow.svg)](LICENSE) [![Built with Gleam](https://img.shields.io/badge/Built%20with-Gleam-ffaff3)](https://gleam.run)

**Sparkling** is a *lightweight*, **type-safe** data layer for **ClickHouse** written in Gleam. It provides a small, focused API for defining schemas, building queries, and encoding/decoding ClickHouse formats.

*No magic*, just small, composable functions that play nicely in Gleam apps.

> Why "Sparkling"? One rainy Tuesday a tiny inflatable rubber duck stole a shooting pink star and decided to become a freelance data wrangler, and it now guides queries through the night, humming 8-bit lullabies. Totally plausible.

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