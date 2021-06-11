module Smartpower = Smartpower

module Blind : sig
  val observe : unit -> Yojson.t Lwt.t
end

module Mock : sig
  val observe : unit -> Yojson.t Lwt.t
end

type observer =
  | Smartpower of Smartpower.station Lwt.t
  | Mock
  | Blind
  | Mammut of string option

val observe : observer -> Yojson.t Lwt.t

val to_string : Yojson.t -> string
