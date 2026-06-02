(** JSON line sinks. *)

(** [string_of_event event] renders [event] as a compact JSON object. *)
val string_of_event : Scribe.Event.t -> string

(** [channel output] writes each event as one JSON object followed by a newline, then flushes [output]. *)
val channel : out_channel -> Scribe.Sink.t

(** [stderr ()] writes JSON lines to standard error. *)
val stderr : unit -> Scribe.Sink.t
