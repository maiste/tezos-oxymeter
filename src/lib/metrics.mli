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

(** This module defines a mechanism to gather information from observer
    during an observation process. *)

(** {1 Measure}

    Measures are defined as a unit you want to get when you observer
    the consumption. *)

(** Module that represents a measure unit. *)
module type MEASURE = sig
  (** Abstract type to represent a measure. *)
  type t

  (** The name of file where the measure are exported. *)
  val file : string

  (** Initialize the instrument. *)
  val init : string list -> unit

  (** Gets a measure. *)
  val getMeasure : unit -> t Lwt.t

  (** [diff x y] computes the difference between x and y. *)
  val diff : t -> t -> t Lwt.t

  (** Returns the representation of the {!t} value as a
      string. *)
  val to_string_lwt : t -> string Lwt.t

  (** Returns the representation of the {!t} value as
      an {!Ezjsonm.value}. *)
  val to_ezjsonm_lwt : t -> Ezjsonm.value Lwt.t
end

(** Module with informations about the energy measure. *)
module EnergyMeasure : MEASURE

(** Module with informations about the time measure .*)
module TimeMeasure : MEASURE

(** {1 Metrics}

    Metrics are the way to record measures until the end of the program or
    when a signal is triggered. *)

(** Module that represents an instrument to take and save
    mesures. *)
module type METRICS = sig
  (** [insert file fun_name state] inserts a new entry into
      the database, referenced as file.fun_name. It's either
      the starting of a measure or the end. *)
  val insert : string -> string -> [< `Start | `Stop ] -> unit Lwt.t

  (** [exist file fun_name] checks if there is already a
      reference to file.fun_name in the database. *)
  val exist : string -> string -> bool

  (** [generate_report path name] builds a JSON report to [path]/[name] from
      the values present in the database. It creates the path if it doesn't
      exist.*)
  val generate_report : string -> string -> unit Lwt.t

  (** [generate_report_on_signal path name] is the same as {!generate_report}
      with, in addition, a mecanism to refill the queue with a value. We want
      to keep the report structure consistent. *)
  val generate_report_on_signal : string -> string -> unit Lwt.t
end

(** Functor to create an instrument to get {!METRICS} from
    a {!MEASURE} unit. *)
module MakeMetrics : functor (M : MEASURE) -> METRICS

(** Module to gather metrics about time. *)
module TimeMetrics : METRICS

(** Module to gather metrics about consumption. *)
module EnergyMetrics : METRICS
