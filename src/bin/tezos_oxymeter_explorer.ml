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

open Cmdliner
open Utils.Infix

let term_of_result = function
  | Result.Ok r -> `Ok r
  | Error e -> `Error (false, e)

type copts = { verbose : bool; path : string }

let copts verbose path = { verbose; path }

let copts_t =
  let docs = Manpage.s_common_options in
  let verbose =
    let doc = "Give a verbose output." in
    Arg.(value & flag & info [ "v"; "verbose" ] ~docs ~doc)
  in
  let path =
    let doc = "Specify the path where the report is store if needed." in
    Arg.(
      value
      & opt string "/tmp/oxymeter-report"
      & info [ "p"; "path" ] ~doc ~docs)
  in
  Term.(const copts $ verbose $ path)

let show copts =
  let verbose = copts.verbose in
  Reader.extract_data_from_r copts.path
  >>= (fun data -> Printer.show_data ~verbose data |> Result.ok)
  |> term_of_result

let show_cmd =
  let doc = "Show the repository context." in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  (Term.(const show $ copts_t), Term.info "show" ~doc ~sdocs ~exits)

let cmds = [ show_cmd ]

let default_cmd =
  let doc = "an explorer for ppx-tezos_oxymeter results" in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  ( Term.(ret (const (fun _ -> `Help (`Pager, None)) $ copts_t)),
    Term.info "tzoeplorer" ~doc ~sdocs ~version:"0.1.0" ~exits )

let () = Term.(exit @@ eval_choice default_cmd cmds)
