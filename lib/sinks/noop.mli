(** Sink that discards events. *)

val create : unit -> Scribe.Sink.t
(** [create ()] returns a sink that discards every event. *)
