# scribe

`scribe` is a small structured logging library for OCaml. A logger is an ordinary value that carries its level, sink, and context fields, so application code can compose loggers and library code can accept `?logger` without touching process-wide logging state.

## Quick Start

```ocaml
let logger =
  Scribe.create
    ~level:Scribe.Level.Warning
    ~sink:(Scribe.Sink.stderr_json ())
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
  Scribe.create ~level:Scribe.Level.Info ~sink:(Scribe.Sink.stderr_json ())
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

The first version focuses on value-based structured logging, JSON lines, stderr output, and test capture sinks. Adapters for other logging systems are intentionally left out of the MVP.
