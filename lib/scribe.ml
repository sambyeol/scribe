module Level = struct
  type t = App | Error | Warning | Info | Debug

  let rank = function
    | App -> 0
    | Error -> 1
    | Warning -> 2
    | Info -> 3
    | Debug -> 4

  let enabled ~configured level = rank level <= rank configured

  let to_string = function
    | App -> "app"
    | Error -> "error"
    | Warning -> "warning"
    | Info -> "info"
    | Debug -> "debug"
end

module Field = struct
  type value = String of string | Int of int | Bool of bool
  type t = { key : string; value : value }

  let make key value = { key; value }
  let string key value = make key (String value)
  let int key value = make key (Int value)
  let bool key value = make key (Bool value)
  let key field = field.key
  let value field = field.value
end

module Event = struct
  type t =
    { level : Level.t
    ; message : string
    ; fields : Field.t list
    }

  let make ~level ~message ~fields = { level; message; fields }
  let level event = event.level
  let message event = event.message
  let fields event = event.fields
end

module Sink = struct
  type t = Event.t -> unit

  let make emit = emit
  let noop _event = ()
  let emit sink event = sink event

  let add_json_string buffer value =
    Buffer.add_char buffer '"';
    String.iter
      (fun char ->
        match char with
        | '"' -> Buffer.add_string buffer "\\\""
        | '\\' -> Buffer.add_string buffer "\\\\"
        | '\b' -> Buffer.add_string buffer "\\b"
        | '\012' -> Buffer.add_string buffer "\\f"
        | '\n' -> Buffer.add_string buffer "\\n"
        | '\r' -> Buffer.add_string buffer "\\r"
        | '\t' -> Buffer.add_string buffer "\\t"
        | char when Char.code char < 0x20 -> Buffer.add_string buffer (Printf.sprintf "\\u%04x" (Char.code char))
        | char -> Buffer.add_char buffer char)
      value;
    Buffer.add_char buffer '"'

  let add_json_value buffer = function
    | Field.String value -> add_json_string buffer value
    | Field.Int value -> Buffer.add_string buffer (string_of_int value)
    | Field.Bool value -> Buffer.add_string buffer (string_of_bool value)

  let add_fields buffer fields =
    Buffer.add_char buffer '{';
    List.iteri
      (fun index field ->
        if index > 0 then Buffer.add_char buffer ',';
        add_json_string buffer (Field.key field);
        Buffer.add_char buffer ':';
        add_json_value buffer (Field.value field))
      fields;
    Buffer.add_char buffer '}'

  let event_to_json event =
    let buffer = Buffer.create 128 in
    Buffer.add_string buffer "{\"level\":";
    add_json_string buffer (Level.to_string (Event.level event));
    Buffer.add_string buffer ",\"message\":";
    add_json_string buffer (Event.message event);
    Buffer.add_string buffer ",\"fields\":";
    add_fields buffer (Event.fields event);
    Buffer.add_char buffer '}';
    Buffer.contents buffer

  let channel_json channel event =
    output_string channel (event_to_json event);
    output_char channel '\n';
    flush channel

  let stderr_json () = channel_json stderr

  let test_capture () =
    let events = ref [] in
    let sink event = events := event :: !events in
    (sink, fun () -> List.rev !events)
end

type t =
  { level : Level.t
  ; sink : Sink.t
  ; fields : Field.t list
  }

let noop = { level = Level.Debug; sink = Sink.noop; fields = [] }
let create ~level ~sink = { level; sink; fields = [] }
let with_field field logger = { logger with fields = logger.fields @ [ field ] }
let with_fields fields logger = { logger with fields = logger.fields @ fields }

let merge_fields logger_fields call_fields =
  let seen = Hashtbl.create 16 in
  let merge acc field =
    let key = Field.key field in
    if Hashtbl.mem seen key then acc
    else (
      Hashtbl.add seen key ();
      field :: acc)
  in
  List.fold_left merge [] (List.rev_append call_fields (List.rev logger_fields))

let log logger level message fields =
  if Level.enabled ~configured:logger.level level then
    let fields = merge_fields logger.fields fields in
    Sink.emit logger.sink (Event.make ~level ~message ~fields)

let app logger message fields = log logger Level.App message fields
let error logger message fields = log logger Level.Error message fields
let warn logger message fields = log logger Level.Warning message fields
let info logger message fields = log logger Level.Info message fields
let debug logger message fields = log logger Level.Debug message fields
