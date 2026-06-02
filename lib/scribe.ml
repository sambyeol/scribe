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
  let emit sink event = sink event
end

type t =
  { level : Level.t
  ; sink : Sink.t
  ; fields : Field.t list
  }

let noop = { level = Level.Debug; sink = Sink.make (fun _event -> ()); fields = [] }
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
