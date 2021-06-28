(*****************************************************************************)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Étienne Marais <etienne.marais@nomadic-labs.com>       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

(** Main module for the [Tezos_oxymeter]. It exposes the different modules and
    wrap the behaviour for the energy consumption observation. *)

(** Wrapper for the {!Smartpower} module .*)
module Smartpower = Smartpower

(** Wrapper for the {!Report} module. *)
module Report = Report

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

(** Takes an {!observer} and returns the report obtained. *)
val observe : observer -> Report.t Lwt.t

(** [to_string report] converts a {!Report.t} into a sendable string. *)
val to_string : Report.t -> string

(** [pp ppf observer] is used to pretty print an {!observer}. *)
val pp : Format.formatter -> observer -> unit
