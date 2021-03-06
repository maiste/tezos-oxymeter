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

(** Utility used by the entire library to represent a report. Once it's
    created, it can't be ereased. *)

(** {1 Representation}

    A report is a representation of the state of an {!Observer.observer}
    at a given time. *)

(** Abstract representation for a report. To get the content, it's recommanded
    to use the encoding system. *)
type t

(** [create] builds a report with the information provide.

    Usage: [create ~joule ~volt ~ampere ~power ~watt_hour time]
     - [joule] is the instant energy (default is 0).
     - [volt] represents the voltage (default is 0).
     - [ampere] represents the intensity (default is 0).
     - [power] refers to the power consumption (default is 0).
     - [watt_hour] is the energy per time consumption (default is 0).
     - [time] is a UNIX timestamp. *)
val create :
  ?joule:float ->
  ?volt:float ->
  ?ampere:float ->
  ?power:float ->
  ?watt_hour:float ->
  float ->
  t

(** {1 Manipulation}

    Even if the {!t} type is immutable, you can execute some actions on
    it and generates new reports. *)

(**  [diff r1 r2] creates a new report which represents the difference
      between the two reports (r1 - r2), field by field. *)
val diff : t -> t -> t

(** [pp ppf report] is used to pretty print the report. *)
val pp : Format.formatter -> t -> unit

(** {1 Conversion}

    The report can convert to various to be:
    - send through the network
    - print as a string
    - use as a normalize representation *)

(** It provides an encoding used by tezos to transform data in JSON format. *)
val encoding : t Data_encoding.t

(** [string_ot_t] converts {!t} report into a readable string. *)
val string_of_t : t -> string

(** [json_of_t report] converts a {!t} report into a JSON, usable by
    Data_encoding. *)
val json_of_t : t -> Data_encoding.json

(** [ezjsonm_of_t report] converts {!t} report into a JSON, usable bytes
    Ezjsonm. *)
val ezjsonm_of_t : t -> Ezjsonm.value
