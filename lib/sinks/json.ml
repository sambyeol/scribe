let json_of_value = function
  | Scribe.Field.String value -> `String value
  | Scribe.Field.Int value -> `Int value
  | Scribe.Field.Bool value -> `Bool value
;;

let json_of_field field = Scribe.Field.key field, json_of_value (Scribe.Field.value field)

let json_of_event event =
  `Assoc
    [ "level", `String (Scribe.Level.to_string (Scribe.Event.level event))
    ; "message", `String (Scribe.Event.message event)
    ; "fields", `Assoc (List.map json_of_field (Scribe.Event.fields event))
    ]
;;

let string_of_event event = Yojson.Safe.to_string (json_of_event event)

let channel output =
  Scribe.Sink.make (fun event ->
    output_string output (string_of_event event);
    output_char output '\n';
    flush output)
;;

let stderr () = channel stderr
