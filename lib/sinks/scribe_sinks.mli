(** Common sinks for Scribe. *)

val noop : Scribe.Sink.t
(** A sink that discards every event. *)

val json_string_of_event : Scribe.Event.t -> string
(** [json_string_of_event event] renders [event] as a compact JSON object. *)

val json : out_channel -> Scribe.Sink.t
(** [json output] writes each event as one JSON object followed by a newline, then flushes [output]. *)

val stderr_json : unit -> Scribe.Sink.t
(** [stderr_json ()] writes JSON lines to standard error. *)
