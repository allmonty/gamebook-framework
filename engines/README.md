# Engines

| Engine | Language | Versions | Conformance | Maintainer |
|---|---|---|---|---|
| [dart](dart/README.md) | Dart | 1-5 | all cases | reference engine |

## Adding an engine in another language
New engines are welcome: TypeScript for the web, Python for tools, C# for Unity, anything.

1. Make a folder `engines/<language>/` (one per language; lowercase, e.g. `typescript`, `python`).
2. Implement the spec ([../spec/framework.md](../spec/framework.md) Part B) for the versions you choose, starting at 1. Keep the engine **pure**: no UI and no file or network I/O in its core, and **randomness passed in**, so tests can script the dice.
3. Write a runner for the [conformance cases](../conformance/README.md). It reads the JSON files in place (do not copy them), so new cases reach every engine. `dart/test/conformance_test.dart` is about 150 lines and a good model.
4. Add a CI job for it in `.github/workflows/ci.yml` (build, lint, its own tests, the conformance runner).
5. Add its row to the table above, with the versions it supports and passes. An engine may skip cases for versions it does not claim; it must pass all the others.
6. A `README.md` in the folder: how to install, use and test it.

The Dart engine is the reference: where the spec is unclear, its behavior is the tie-breaker until the spec is fixed. If you find such a place, open an issue; that is a spec bug.
