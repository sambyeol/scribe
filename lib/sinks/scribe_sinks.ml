let noop = Scribe.Sink.make (fun _event -> ())

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

let add_value buffer = function
  | Scribe.Field.String value -> add_json_string buffer value
  | Scribe.Field.Int value -> Buffer.add_string buffer (string_of_int value)
  | Scribe.Field.Bool value -> Buffer.add_string buffer (string_of_bool value)

let add_fields buffer fields =
  Buffer.add_char buffer '{';
  List.iteri
    (fun index field ->
      if index > 0 then Buffer.add_char buffer ',';
      add_json_string buffer (Scribe.Field.key field);
      Buffer.add_char buffer ':';
      add_value buffer (Scribe.Field.value field))
    fields;
  Buffer.add_char buffer '}'

let json_string_of_event event =
  let buffer = Buffer.create 128 in
  Buffer.add_string buffer "{\"level\":";
  add_json_string buffer (Scribe.Level.to_string (Scribe.Event.level event));
  Buffer.add_string buffer ",\"message\":";
  add_json_string buffer (Scribe.Event.message event);
  Buffer.add_string buffer ",\"fields\":";
  add_fields buffer (Scribe.Event.fields event);
  Buffer.add_char buffer '}';
  Buffer.contents buffer

let json output =
  Scribe.Sink.make (fun event ->
    output_string output (json_string_of_event event);
    output_char output '\n';
    flush output)

let stderr_json () = json stderr
