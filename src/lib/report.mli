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

(** Utilities used by the entire library to represent a report. Once it's
    created, it can't be ereased. *)

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

(** It provides an encoding used by tezos to transform data in JSON format. *)
val encoding : t Data_encoding.t

(** [pp ppf report] is used to pretty print the report. *)
val pp : Format.formatter -> t -> unit

(** [json_of_t report] converts a {!t} report into a Json, usable by
    Data_encoding. *)
val json_of_t : t -> Data_encoding.json
