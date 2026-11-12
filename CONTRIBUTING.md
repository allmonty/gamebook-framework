# Contributing

Thanks for helping. Three kinds of change, three paths.

## Spec changes
The spec is the source of truth: if an engine and [spec/framework.md](spec/framework.md) Part B disagree, one of them has a bug, and the fix starts in the spec.
- Open an issue first for anything new. Say what a story author can do with it that they cannot today, with a short story example.
- A new feature needs: the text in Part B, a `schema` version bump (with the rule that older stories using it are rejected with `needs "schema": N`), a line in [spec/CHANGELOG.md](spec/CHANGELOG.md), a section on the site's versions page for authors (`site/pages/{en,pt}/versions.md`), the JSON Schema, at least one conformance case, and the reference engine. Then regenerate the LLM kit (`dart run gamebook_engine:llm_kit` in `engines/dart`); a test fails while it is out of date. One pull request per feature.
- Versions only add. A story valid in version N stays valid, and plays the same, in every later version.
- Where randomness is involved, say in which order the dice are rolled (B8, "Order of rolls").
- Write plainly: Part A is read by people who never programmed.

## Conformance cases
See [conformance/README.md](conformance/README.md). Work out the expected result from the spec, not from an engine. One case, one idea.

## Engines
See [engines/README.md](engines/README.md). Each engine follows its language's usual style and must run the conformance cases in CI.

For the Dart engine: `dart format`, `dart analyze --fatal-infos` and `dart test` must be green; every bug fix adds the test that fails without it; tests never sleep and script or seed the dice.

## Commits
Small and self-contained: one change each, tests passing at every commit. A short imperative summary line, then a body that says what changed and why.

## License
By contributing you agree that your contribution is licensed like the rest of the repository: CC BY 4.0 for spec text, MIT for everything else ([LICENSE](LICENSE)).
