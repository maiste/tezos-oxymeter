module Smartpower = Smartpower
module Report = Report

module Blind : sig
  val observe : unit -> Report.t Lwt.t
end

module Mock : sig
  val observe : unit -> Report.t Lwt.t
end

type observer =
  | Blind
  | Mock
  | Smartpower of Smartpower.station Lwt.t
  | Mammut of string option

val observe : observer -> Report.t Lwt.t

val to_string : Report.t -> string

val pp : Format.formatter -> observer -> unit
