# scribe

`scribe` is a small structured logging library for OCaml. A logger is an ordinary value that carries its level, sink, and context fields, so application code can compose loggers and library code can accept `?logger` without touching process-wide logging state.

## Installation

`scribe` is distributed through Git tags; pin it with opam.

Pin the latest release:

```sh
LATEST=$(git ls-remote --tags --refs --sort=-v:refname https://github.com/sambyeol/scribe.git | head -n1 | sed 's|.*/||')
opam pin add scribe "https://github.com/sambyeol/scribe.git#$LATEST"
```

Or pin a specific version:

```sh
opam pin add scribe "https://github.com/sambyeol/scribe.git#v0.1.0"
```

Then depend on the libraries from your dune file:

```
(libraries scribe scribe.sinks)
```

## Quick Start

Use the core logger with the JSON adapter:

```ocaml
let logger =
  Scribe.create
    ~level:Scribe.Level.Warning
    ~sink:(Scribe_sinks.Json.stderr ())
  |> Scribe.with_field (Scribe.Field.string "component" "mir.parser")

let () =
  Scribe.warn logger "metadata parse failed"
    [ Scribe.Field.string "reason" "malformed directive"
    ; Scribe.Field.string "file" path
    ]
```

The JSON sink writes one object per line:

```json
{"level":"warning","message":"metadata parse failed","fields":{"component":"mir.parser","reason":"malformed directive","file":"example.md"}}
```

## Logger Values

`Scribe.create` returns a self-contained logger value. `Scribe.with_field` and `Scribe.with_fields` add reusable context to that value, and call-site fields can override earlier context fields with the same key.

```ocaml
let logger =
  Scribe.create ~level:Scribe.Level.Info ~sink:(Scribe_sinks.Json.stderr ())
  |> Scribe.with_field (Scribe.Field.string "component" "worker")

let job_logger =
  logger
  |> Scribe.with_field (Scribe.Field.string "job_id" job_id)
```

## Library-Friendly Use

Libraries should accept an optional logger and default to `Scribe.noop`.

```ocaml
let parse ?(logger = Scribe.noop) path =
  Scribe.debug logger "parse started"
    [ Scribe.Field.string "file" path ];
  (* parsing work *)
  ()
```

## MVP Scope

The first version focuses on value-based structured logging and a small sink collection with noop and JSON lines sinks. Other logging adapters are intentionally left out of the MVP.
