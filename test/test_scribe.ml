let pp_level formatter level =
  Format.pp_print_string formatter (Scribe.Level.to_string level)

let level = Alcotest.testable pp_level ( = )

let pp_field_value formatter = function
  | Scribe.Field.String value -> Format.fprintf formatter "String %S" value
  | Scribe.Field.Int value -> Format.fprintf formatter "Int %d" value
  | Scribe.Field.Bool value -> Format.fprintf formatter "Bool %b" value

let field_value = Alcotest.testable pp_field_value ( = )
let field_pair = Alcotest.pair Alcotest.string field_value

let read_file path =
  let channel = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () ->
      let length = in_channel_length channel in
      really_input_string channel length)

let require_one events =
  match events with
  | [ event ] -> event
  | events -> Alcotest.failf "expected one event, got %d" (List.length events)

let event_field_pair field = (Scribe.Field.key field, Scribe.Field.value field)

let capture_sink () =
  let events = ref [] in
  let sink = Scribe.Sink.make (fun event -> events := event :: !events) in
  (sink, fun () -> List.rev !events)

let test_level_filtering () =
  let sink, events = capture_sink () in
  let logger = Scribe.create ~level:Scribe.Level.Warning ~sink in
  Scribe.app logger "app" [];
  Scribe.error logger "error" [];
  Scribe.warn logger "warn" [];
  Scribe.info logger "info" [];
  Scribe.debug logger "debug" [];
  let levels = List.map Scribe.Event.level (events ()) in
  Alcotest.(check (list level))
    "emitted levels"
    [ Scribe.Level.App; Scribe.Level.Error; Scribe.Level.Warning ]
    levels

let test_context_and_override () =
  let sink, events = capture_sink () in
  let logger =
    Scribe.create ~level:Scribe.Level.Debug ~sink
    |> Scribe.with_field (Scribe.Field.string "component" "parser")
    |> Scribe.with_field (Scribe.Field.string "request_id" "context")
  in
  Scribe.warn logger "metadata parse failed"
    [ Scribe.Field.string "request_id" "call"
    ; Scribe.Field.int "line" 42
    ];
  let event = require_one (events ()) in
  let fields = List.map event_field_pair (Scribe.Event.fields event) in
  Alcotest.(check (list field_pair))
    "merged fields"
    [ ("component", Scribe.Field.String "parser")
    ; ("request_id", Scribe.Field.String "call")
    ; ("line", Scribe.Field.Int 42)
    ]
    fields

let test_json_sink () =
  let path = Filename.temp_file "scribe-json-" ".log" in
  let channel = open_out_bin path in
  let sink = Scribe_sinks.json channel in
  let logger = Scribe.create ~level:Scribe.Level.Warning ~sink in
  Scribe.warn logger "metadata\nparse failed"
    [ Scribe.Field.string "reason" "malformed \"directive\""
    ; Scribe.Field.int "line" 42
    ; Scribe.Field.bool "ok" false
    ];
  close_out channel;
  let output = read_file path in
  Sys.remove path;
  Alcotest.(check string)
    "json line"
    "{\"level\":\"warning\",\"message\":\"metadata\\nparse failed\",\"fields\":{\"reason\":\"malformed \\\"directive\\\"\",\"line\":42,\"ok\":false}}\n"
    output

let test_noop () =
  Scribe.warn Scribe.noop "ignored" [ Scribe.Field.string "component" "test" ];
  Scribe.info Scribe.noop "ignored" []

let test_noop_sink () =
  let logger = Scribe.create ~level:Scribe.Level.Debug ~sink:(Scribe_sinks.noop ()) in
  Scribe.debug logger "ignored" []

let () =
  Alcotest.run "scribe"
    [ ( "logger"
      , [ Alcotest.test_case "level filtering" `Quick test_level_filtering
        ; Alcotest.test_case "context fields and override" `Quick test_context_and_override
        ; Alcotest.test_case "noop logger" `Quick test_noop
        ] )
    ; ( "sink"
      , [ Alcotest.test_case "json sink" `Quick test_json_sink
        ; Alcotest.test_case "noop sink" `Quick test_noop_sink
        ] )
    ]
