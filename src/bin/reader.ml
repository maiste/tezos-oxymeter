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

open Utils.Infix

module Info = struct
  type measure = Energy | Time

  type t = { date : string; time : string; measure : measure; json : Ezjsonm.t }

  let create ~date ~time measure json = { date; time; measure; json }

  let date { date; _ } = date

  let time { time; _ } = time

  let measure { measure; _ } = measure

  let json { json; _ } = json
end

module Data = struct
  type t = { energy : Info.t list; time : Info.t list }

  let empty = { energy = []; time = [] }

  let energy { energy; _ } = energy

  let time { time; _ } = time
end

let open_opt file =
  try open_in file |> Result.ok
  with _ -> Result.error "Sorry, we can't open this file."

let get_json_from file =
  let* cin = open_opt file in
  try
    let res = Ezjsonm.from_channel cin |> Result.ok in
    let () = close_in cin in
    res
  with Ezjsonm.Parse_error _ ->
    Result.error "Sorry, we are not able to parse the JSON file."

let check_dir dir = Sys.file_exists dir && Sys.is_directory dir

let enumerate_files path =
  if check_dir path then
    try Sys.readdir path |> Result.ok
    with _ -> Result.error "Sorry, we can't read the directory you specified."
  else Result.error "Sorry, the path you specify is not an existing directory."

let is_well_format file =
  let rex =
    Re.Pcre.regexp "^[0-9]{8}-[0-9]{2}:[0-9]{2}:[0-9]{2}_(energy|time).json$"
  in
  Re.Pcre.pmatch ~rex file

let extract_info_r path =
  let file = Filename.basename path in
  if is_well_format file then
    let* json = get_json_from path in
    let name = Filename.remove_extension file in
    match String.split_on_char '-' name with
    | [ date; tail ] -> (
        match String.split_on_char '_' tail with
        | [ time; "energy" ] ->
            Info.create ~date ~time Info.Energy json |> Result.ok
        | [ time; "time" ] ->
            Info.create ~date ~time Info.Time json |> Result.ok
        | _ -> Result.error "Sorry, your file is not well-formatted.")
    | _ -> Result.error "Sorry, your file is not well-formatted."
  else
    Result.error
      "Your file is not well-formatted: it should be \
       YYYYMMDD-HH:MM:SS_[energy|time].json"

let extract_data_from_r path =
  let* dir = enumerate_files path in
  let dir = Array.to_list dir in
  let iterator acc l =
    let path = Filename.concat path l in
    acc >>= fun acc ->
    let* info = extract_info_r path in
    match info.measure with
    | Energy -> Result.ok Data.{ acc with energy = info :: acc.energy }
    | Time -> Result.ok Data.{ acc with time = info :: acc.time }
  in
  List.fold_left iterator (Result.ok Data.empty) dir
