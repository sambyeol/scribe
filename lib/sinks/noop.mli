(** Sink that discards events. *)

(** [create ()] returns a sink that discards every event. *)
val create : unit -> Scribe.Sink.t
