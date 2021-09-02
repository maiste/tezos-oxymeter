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

open Reader
open Utils.Unix

let to_string_info ?(verbose = false) info =
  let date = Info.date info in
  let time = Info.time info in
  let measure = Info.measure info in
  let json = Info.json info in
  let json_s =
    if verbose then Format.sprintf "%s\n" (Ezjsonm.to_string ~minify:false json)
    else ""
  in
  match measure with
  | Energy -> Format.sprintf "- %s %s\n%s" date time json_s
  | Time -> Format.sprintf "- %s %s\n%s" date time json_s

let to_string_data ?verbose data =
  let energy_str =
    let energy = Data.energy data in
    if energy <> [] then
      let energy_head = Format.sprintf "=== Energy data ===\n" in
      List.fold_left
        (fun acc info -> acc ^ to_string_info ?verbose info)
        energy_head
        (energy |> List.rev)
    else ""
  in
  let time_str =
    let time = Data.time data in
    if time <> [] then
      let time_head = Format.sprintf "===  Time data  ===\n" in
      List.fold_left
        (fun acc info -> acc ^ to_string_info ?verbose info)
        time_head
        (Data.time data |> List.rev)
    else ""
  in
  let footer = "====================\n" in
  energy_str ^ time_str ^ footer

let show_info ?verbose info = Format.printf "%s" (to_string_info ?verbose info)

let show_data ?verbose data =
  Format.printf "%s@." (to_string_data ?verbose data)

let show_filter_data ?(verbose = false) ~date ~time ~measure data =
  let data =
    match measure with
    | Some Info.Energy -> Data.set_time [] data
    | Some Info.Time -> Data.set_energy [] data
    | None -> data
  in
  let data =
    match date with
    | Some date ->
        let time_info =
          List.filter (fun elt -> Info.date elt = date) (Data.time data)
        in
        let energy_info =
          List.filter (fun elt -> Info.date elt = date) (Data.energy data)
        in
        Data.set_energy energy_info data |> Data.set_time time_info
    | None -> data
  in
  let data =
    match time with
    | Some time ->
        let time_info =
          List.filter (fun elt -> Info.time elt = time) (Data.time data)
        in
        let energy_info =
          List.filter (fun elt -> Info.time elt = time) (Data.energy data)
        in
        Data.set_energy energy_info data |> Data.set_time time_info
    | None -> data
  in
  show_data ~verbose data

let export ?(verbose = false) path data =
  if Filename.dirname path |> check_dir then (
    let cout = open_out path in
    if verbose then show_data ~verbose:false data ;
    output_string cout (to_string_data ~verbose:true data) ;
    Result.ok (close_out cout))
  else Result.error "Sorry, we can't export to this directory"
