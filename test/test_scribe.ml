let assert_equal expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "expected %s, got %s" expected actual)

let assert_int_equal expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "expected %d, got %d" expected actual)

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
  | events -> failwith (Printf.sprintf "expected one event, got %d" (List.length events))

let field_pair field = (Scribe.Field.key field, Scribe.Field.value field)

let test_level_filtering () =
  let sink, events = Scribe.Sink.test_capture () in
  let logger = Scribe.create ~level:Scribe.Level.Warning ~sink in
  Scribe.app logger "app" [];
  Scribe.error logger "error" [];
  Scribe.warn logger "warn" [];
  Scribe.info logger "info" [];
  Scribe.debug logger "debug" [];
  let levels = List.map Scribe.Event.level (events ()) in
  assert (levels = [ Scribe.Level.App; Scribe.Level.Error; Scribe.Level.Warning ])

let test_context_and_override () =
  let sink, events = Scribe.Sink.test_capture () in
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
  let fields = List.map field_pair (Scribe.Event.fields event) in
  assert (
    fields
    = [ ("component", Scribe.Field.String "parser")
      ; ("request_id", Scribe.Field.String "call")
      ; ("line", Scribe.Field.Int 42)
      ])

let test_json_sink () =
  let path = Filename.temp_file "scribe-json-" ".log" in
  let channel = open_out_bin path in
  let sink = Scribe.Sink.channel_json channel in
  let logger = Scribe.create ~level:Scribe.Level.Warning ~sink in
  Scribe.warn logger "metadata\nparse failed"
    [ Scribe.Field.string "reason" "malformed \"directive\""
    ; Scribe.Field.int "line" 42
    ; Scribe.Field.bool "ok" false
    ];
  close_out channel;
  let output = read_file path in
  Sys.remove path;
  assert_equal
    "{\"level\":\"warning\",\"message\":\"metadata\\nparse failed\",\"fields\":{\"reason\":\"malformed \\\"directive\\\"\",\"line\":42,\"ok\":false}}\n"
    output

let test_noop () =
  Scribe.warn Scribe.noop "ignored" [ Scribe.Field.string "component" "test" ];
  Scribe.info Scribe.noop "ignored" []

let () =
  test_level_filtering ();
  test_context_and_override ();
  test_json_sink ();
  test_noop ();
  assert_int_equal 1 1
