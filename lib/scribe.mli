(** Value-based structured logging.

    A [t] logger is an ordinary value that carries its own level, sink, and context fields. Library code can accept an optional logger and default to [noop] without touching process-wide logging state. *)

module Level : sig
  (** Log verbosity.

      Levels are ordered from least verbose to most verbose: [App], [Error], [Warning], [Info], then [Debug]. A logger configured at [Warning] emits [App], [Error], and [Warning] events, and filters [Info] and [Debug]. *)

  type t = App | Error | Warning | Info | Debug
  (** The level of a log event. *)

  val to_string : t -> string
  (** [to_string level] returns the stable lowercase representation used by JSON sinks. *)
end

module Field : sig
  (** Structured fields attached to log events. *)

  type value = String of string | Int of int | Bool of bool
  (** Supported field values. *)

  type t
  (** A key-value field. *)

  val string : string -> string -> t
  (** [string key value] creates a string field. *)

  val int : string -> int -> t
  (** [int key value] creates an integer field. *)

  val bool : string -> bool -> t
  (** [bool key value] creates a boolean field. *)

  val key : t -> string
  (** [key field] returns the field key. *)

  val value : t -> value
  (** [value field] returns the field value. *)
end

module Event : sig
  (** Events delivered to sinks. *)

  type t
  (** A fully materialized log event. *)

  val level : t -> Level.t
  (** [level event] returns the event level. *)

  val message : t -> string
  (** [message event] returns the event message. *)

  val fields : t -> Field.t list
  (** [fields event] returns merged context and call-site fields. *)
end

module Sink : sig
  (** Event destinations. *)

  type t
  (** A sink consumes emitted events. *)

  val make : (Event.t -> unit) -> t
  (** [make emit] creates a sink from an event callback. *)

  val noop : t
  (** A sink that discards every event. *)

  val channel_json : out_channel -> t
  (** [channel_json channel] writes each event as one JSON object followed by a newline, then flushes [channel]. *)

  val stderr_json : unit -> t
  (** [stderr_json ()] writes JSON lines to [stderr]. *)

  val test_capture : unit -> t * (unit -> Event.t list)
  (** [test_capture ()] returns a sink and a snapshot function for assertions. Events are returned in emission order. *)
end

type t
(** A logger value. *)

val noop : t
(** A logger that discards every event. *)

val create : level:Level.t -> sink:Sink.t -> t
(** [create ~level ~sink] creates a logger with no context fields. *)

val with_field : Field.t -> t -> t
(** [with_field field logger] returns [logger] with [field] appended to its context. *)

val with_fields : Field.t list -> t -> t
(** [with_fields fields logger] returns [logger] with [fields] appended to its context in order. *)

val log : t -> Level.t -> string -> Field.t list -> unit
(** [log logger level message fields] emits an event when [level] is enabled for [logger]. Logger context fields are merged before call-site [fields], and later fields override earlier fields with the same key. *)

val app : t -> string -> Field.t list -> unit
(** Emit an application-level event. *)

val error : t -> string -> Field.t list -> unit
(** Emit an error event. *)

val warn : t -> string -> Field.t list -> unit
(** Emit a warning event. *)

val info : t -> string -> Field.t list -> unit
(** Emit an informational event. *)

val debug : t -> string -> Field.t list -> unit
(** Emit a debug event. *)
