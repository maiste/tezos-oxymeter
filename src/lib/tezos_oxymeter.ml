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

module Smartpower = Smartpower
module Mammut = Mammut_oxymeter
module Report = Report

module Blind = struct
  let observe () =
    let time = Unix.gettimeofday () in
    let report = Report.create time in
    Lwt.return report
end

module Mock = struct
  let () = Random.self_init ()

  let observe () =
    let time = Unix.gettimeofday () in
    let joule = Random.float 8200.0 in
    let volt = Random.float 5.0 in
    let ampere = Random.float 4.0 in
    let power = Random.float 0.2 in
    let watt_hour = Random.float 0.5 in
    let report = Report.create ~joule ~volt ~ampere ~power ~watt_hour time in
    Lwt.return report
end

type observer =
  | Blind
  | Mock
  | Smartpower of Smartpower.station Lwt.t
  | Mammut of string option

let observe = function
  | Blind -> Blind.observe ()
  | Mock -> Mock.observe ()
  | Mammut _ -> Mammut.observe ()
  | Smartpower smartpower -> Smartpower.observe smartpower

let to_string report =
  Report.json_of_t report
  |> Data_encoding.Json.to_string ~newline:true ~minify:false

let pp ppf = function
  | Blind -> Format.fprintf ppf "blind"
  | Mock -> Format.fprintf ppf "mock"
  | Smartpower _ -> Format.fprintf ppf "smartpower"
  | Mammut _ -> Format.fprintf ppf "mammut"
