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

open Lwt.Infix
open Lwt_unix

let ( let* ) x f = Lwt.bind x f

type station = file_descr

let create ip_addr port =
  let inet_addr = Unix.inet_addr_of_string ip_addr in
  let sock_addr = ADDR_INET (inet_addr, port) in
  let domain = Unix.domain_of_sockaddr sock_addr in
  let sock = socket domain SOCK_STREAM 0 in
  connect sock sock_addr >|= fun () -> sock

let delete sock = sock >|= fun sock -> shutdown sock SHUTDOWN_ALL

let float_re = Re.Str.regexp "[0-9]+[.][0-9]+"

let filter_raw str =
  let buf = Buffer.create 512 in
  let char_stream = Stream.of_string str in
  let rec fill_buffer () =
    match Stream.next char_stream with
    | '\r' | '\n' | (exception Stream.Failure) -> Buffer.contents buf
    | c ->
        Buffer.add_char buf c ;
        fill_buffer ()
  in
  fill_buffer ()

let filter raw_data =
  let splitted_raw_data =
    filter_raw raw_data |> String.split_on_char ',' |> List.map String.trim
  in
  let length = List.length splitted_raw_data in
  if length <> 4 then
    raise
      (Failure
         Format.(
           sprintf "Got list of size %d instead of 4 : %s" length raw_data))
  else
    let filter_float raw_data =
      let open Re.Str in
      if string_match float_re raw_data 0 then
        matched_string raw_data |> Float.of_string
      else raise (Failure ("Data can't be parse: " ^ raw_data))
    in
    List.map filter_float splitted_raw_data

let get_data_from sock =
  let* sock = sock in
  let size = 512 in
  let buffer = Bytes.create size in
  let* data = recv sock buffer 0 size [] in
  let bytes = Bytes.sub buffer 0 data in
  Lwt.return (Bytes.to_string bytes)

let observe_raw sock =
  let* raw_data = get_data_from sock in
  let energy_data = filter raw_data in
  Lwt.return energy_data

let observe sock =
  let time = Unix.gettimeofday () in
  let* energy_data = observe_raw sock in
  let energy_array = Array.of_list energy_data in
  let joule = energy_array.(3) *. 3600. in
  let volt = energy_array.(0) in
  let ampere = energy_array.(1) in
  let power = energy_array.(2) in
  let watt_hour = energy_array.(3) in
  let report = Report.create ~joule ~volt ~ampere ~power ~watt_hour time in
  Lwt.return report
