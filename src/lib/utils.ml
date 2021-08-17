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

let metrics_config_path =
  match Sys.getenv_opt "METRICS_CONFIG_PATH" with
  | Some path -> path
  | None -> "metrics_config.json"

module JSON = struct
  let parse_file file =
    try
      let source = open_in file in
      Some (Ezjsonm.from_channel source)
    with _ -> None

  let parse_metrics_config () = parse_file metrics_config_path

  let extract_from_array : Ezjsonm.value -> Ezjsonm.value list = function
    | `A lst -> lst
    | _ -> []

  let extract_from_obj : Ezjsonm.value -> (string * Ezjsonm.value) list =
    function
    | `O objs -> objs
    | _ -> []

  let extract_from_string = Ezjsonm.get_string

  let export_to ~path json =
    let cout = open_out path in
    let jsont = Ezjsonm.wrap json in
    Ezjsonm.to_channel cout jsont ;
    close_out cout
end

module Sys = struct
  let create_opt ?(mode = 0o755) path =
    if not (Sys.file_exists path) then Sys.mkdir path mode
    else if Sys.is_directory path then ()
    else failwith "Can't create a directory: conflict with filename"
end

module Name = struct
  let timestamp_name name =
    let time = Unix.time () |> Unix.localtime in
    let year = time.tm_year + 1900 |> string_of_int in
    let month = time.tm_mon + 1 |> Format.sprintf "%.2d" in
    let day = time.tm_mday |> Format.sprintf "%.2d" in
    let hour = time.tm_hour |> Format.sprintf "%.2d" in
    let minute = time.tm_min |> Format.sprintf "%.2d" in
    let second = time.tm_sec |> Format.sprintf "%.2d" in
    let timestamp =
      year ^ month ^ day ^ "-" ^ hour ^ ":" ^ minute ^ ":" ^ second
    in
    timestamp ^ "_" ^ name
end

module Args = struct
  let time = ref false

  let power = ref "off"

  let signal = ref false

  let path = ref "/tmp/oxymeter-report/"

  let lwt_context = ref false

  let want_time () = !time

  let want_power () =
    let power = !power in
    if power = "off" then None else Some power

  let want_signal () = !signal

  let want_path () = !path

  let want_lwt () = !lwt_context

  let power_spec =
    ( "-energy",
      Arg.Set_string power,
      "Specify the energy source: [mock|power:<ip>:<port>]." )

  let time_spec = ("-time", Arg.Set time, "Request to have time metric.")

  let signal_spec =
    ("-signal", Arg.Set signal, "Request to have a signal handler.")

  let path_spec =
    ( "-path",
      Arg.Set_string path,
      "Specify a new path for the report. Default is /tmp/oxymeter-report." )

  let lwt_spec =
    ( "-lwt-context",
      Arg.Set lwt_context,
      "Specify if the ppx is executed in a PPX context or not." )
end
