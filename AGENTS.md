# AGENTS.md

## Repository Rules

- Keep `main` clean; do implementation work on a separate branch.
- Include a co-authored-by trailer when creating commits.
- Do not hard wrap Markdown files.

## OCaml Project Conventions

- Use `dune` as the build and test driver.
- Use `Alcotest` for tests.
- Use `ocamlformat` with the repository `.ocamlformat`; formatting should pass `dune build @fmt`.
- Run `dune build`, `dune runtest`, and `dune build @install` before committing changes.

## Library Design Conventions

- Keep the core `Scribe` library focused on value-based structured logging: levels, fields, events, the sink abstraction, and loggers.
- Keep common concrete sinks outside the core library in `scribe.sinks`.
