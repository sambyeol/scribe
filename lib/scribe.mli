(** Value-based structured logging.

    A [t] logger is an ordinary value that carries its own level, sink, and context fields, so logging never touches process-wide state. Library code can accept an optional logger and fall back to one backed by a discarding sink. *)

module Level : sig
  (** Log verbosity.

      Levels are ordered from least verbose to most verbose: [App], [Error], [Warning], [Info], then [Debug]. A logger configured at [Warning] emits [App], [Error], and [Warning] events, and filters [Info] and [Debug]. *)

  type t =
    | App
    | Error
    | Warning
    | Info
    | Debug

  (** [to_string level] returns the stable lowercase representation used by JSON sinks. *)
  val to_string : t -> string
end

module Field : sig
  (** Structured fields attached to log events. *)

  type value =
    | String of string
    | Int of int
    | Bool of bool

  (** A key-value field. *)
  type t

  (** [string key value] creates a string field. *)
  val string : string -> string -> t

  (** [int key value] creates an integer field. *)
  val int : string -> int -> t

  (** [bool key value] creates a boolean field. *)
  val bool : string -> bool -> t

  (** [key field] returns the field key. *)
  val key : t -> string

  (** [value field] returns the field value. *)
  val value : t -> value
end

module Event : sig
  (** Events delivered to sinks. *)

  (** A fully materialized log event. *)
  type t

  (** [level event] returns the event level. *)
  val level : t -> Level.t

  (** [message event] returns the event message. *)
  val message : t -> string

  (** [fields event] returns merged context and call-site fields. *)
  val fields : t -> Field.t list
end

module Sink : sig
  (** Event destinations. *)

  (** A sink consumes emitted events. *)
  type t

  (** [make emit] creates a sink from an event callback. *)
  val make : (Event.t -> unit) -> t
end

(** A logger value. *)
type t

(** [create ~level ~sink] creates a logger with no context fields. *)
val create : level:Level.t -> sink:Sink.t -> t

(** [with_field field logger] returns [logger] with [field] appended to its context. *)
val with_field : Field.t -> t -> t

(** [with_fields fields logger] returns [logger] with [fields] appended to its context in order. *)
val with_fields : Field.t list -> t -> t

(** [log logger level message fields] emits an event when [level] is enabled for [logger]. Logger context fields are merged before call-site [fields], and later fields override earlier fields with the same key. *)
val log : t -> Level.t -> string -> Field.t list -> unit

(** Emit an application-level event. *)
val app : t -> string -> Field.t list -> unit

(** Emit an error event. *)
val error : t -> string -> Field.t list -> unit

(** Emit a warning event. *)
val warn : t -> string -> Field.t list -> unit

(** Emit an informational event. *)
val info : t -> string -> Field.t list -> unit

(** Emit a debug event. *)
val debug : t -> string -> Field.t list -> unit
