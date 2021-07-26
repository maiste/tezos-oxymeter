(** Wrapper for the {!Smartpower} module .*)
module Smartpower = Smartpower

(** Wrapper for the {!Mammut_oxymeter} module *)
module Mammut = Mammut_oxymeter

(** Module that represents an observation without any metric returned. *)
module Blind : sig
  (** [observe ()] generates a blank report. *)
  val observe : unit -> Report.t Lwt.t
end

(** Module to generate random number when you observe it. *)
module Mock : sig
  (** [observe ()] generates a random report for a test purpose. *)
  val observe : unit -> Report.t Lwt.t
end

(** Wrapper type to define the way to observe the consumption. *)
type observer =
  | Blind  (** Return a report with 0 everywhere. *)
  | Mock  (** Return a report with random numbers. For test purpose.*)
  | Smartpower of Smartpower.station Lwt.t
      (** Return a report from smartpower. *)
  | Mammut of string option  (** Return a report from MSR registers. *)

(** Create an observer from an argument list. *)
val create : string list -> observer

(** Takes an {!observer} and returns the report obtained. *)
val observe : observer -> Report.t Lwt.t

(** [to_string report] converts a {!Report.t} into a sendable string. *)
val to_string : Report.t -> string

(** [pp ppf observer] is used to pretty print an {!observer}. *)
val pp : Format.formatter -> observer -> unit
