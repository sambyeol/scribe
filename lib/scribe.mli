(** Value-based structured logging. *)

module Level : sig
  type t = App | Error | Warning | Info | Debug

  val to_string : t -> string
end

module Field : sig
  type value = String of string | Int of int | Bool of bool
  type t

  val string : string -> string -> t
  val int : string -> int -> t
  val bool : string -> bool -> t
  val key : t -> string
  val value : t -> value
end

module Event : sig
  type t

  val level : t -> Level.t
  val message : t -> string
  val fields : t -> Field.t list
end

module Sink : sig
  type t

  val make : (Event.t -> unit) -> t
  val noop : t
  val channel_json : out_channel -> t
  val stderr_json : unit -> t
  val test_capture : unit -> t * (unit -> Event.t list)
end

type t

val noop : t
val create : level:Level.t -> sink:Sink.t -> t
val with_field : Field.t -> t -> t
val with_fields : Field.t list -> t -> t
val log : t -> Level.t -> string -> Field.t list -> unit
val app : t -> string -> Field.t list -> unit
val error : t -> string -> Field.t list -> unit
val warn : t -> string -> Field.t list -> unit
val info : t -> string -> Field.t list -> unit
val debug : t -> string -> Field.t list -> unit
