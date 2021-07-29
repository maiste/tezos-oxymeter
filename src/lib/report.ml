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

type t =
  { time : float;
    joule : float;
    volt : float;
    ampere : float;
    power : float;
    watt_hour : float
  }

let create ?(joule = 0.0) ?(volt = 0.0) ?(ampere = 0.0) ?(power = 0.0)
    ?(watt_hour = 0.0) time =
  { time; joule; volt; ampere; power; watt_hour }

let diff r1 r2 =
  { time = r1.time -. r2.time;
    joule = r1.joule -. r2.joule;
    volt = r1.volt -. r2.volt;
    ampere = r1.ampere -. r2.ampere;
    power = r1.power -. r2.power;
    watt_hour = r1.watt_hour -. r2.watt_hour
  }

let encoding =
  let open Data_encoding in
  conv
    (fun { time; joule; volt; ampere; power; watt_hour } ->
      (time, joule, volt, ampere, power, watt_hour))
    (fun (time, joule, volt, ampere, power, watt_hour) ->
      { time; joule; volt; ampere; power; watt_hour })
    (obj6
       (req "time" float)
       (req "joule" float)
       (req "volt" float)
       (req "ampere" float)
       (req "power" float)
       (req "watt_hour" float))

let string_of_t t =
  let open Data_encoding in
  Json.construct encoding t |> Json.to_string ~newline:true ~minify:false

let pp ppf t =
  let json_str = string_of_t t in
  Format.fprintf ppf "%s" json_str

let json_of_t t =
  let open Data_encoding in
  Json.construct encoding t

let ezjsonm_of_t t =
  let json_float t = `Float t in
  let wrap_in_array lst = `A lst in
  let t_list = [ t.time; t.joule; t.volt; t.ampere; t.power; t.watt_hour ] in
  List.map json_float t_list |> wrap_in_array
