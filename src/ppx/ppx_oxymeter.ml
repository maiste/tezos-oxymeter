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

open Ppxlib
open Tezos_oxymeter

(** Wrap the exit expression with Lwt. *)
let exit_expr loc expr =
  if Args.want_lwt () then [%stri at_exit (fun () -> Lwt_main.run @@ [%e expr])]
  else [%stri Lwt_main.at_exit (fun () -> [%e expr])]

(** Wrap the signal handler with Lwt. *)
let signal_expr loc time power =
  if Args.want_lwt () then
    ( [ [%stri
          Sys.signal
            Sys.sigusr1
            (Sys.Signal_handle
               (fun _ ->
                 Lwt_main.run @@ [%e time] ;
                 Lwt_main.run [%e power]))]
      ],
      [] )
  else
    ( [ [%stri
          Lwt_unix.on_signal Sys.sigusr1 (fun _ ->
              ignore [%e time] ;
              ignore [%e power])]
      ],
      [] )

(** Wrap the insert call with Lwt. *)
let insert_expr loc expr =
  if Args.want_lwt () then [%expr Lwt_main.run @@ [%e expr]]
  else [%expr ignore [%e expr]]

(** Create the init header for the time metric. *)
let time_header loc =
  let path =
    Ast_builder.Default.estring ~loc (Tezos_oxymeter.Args.want_path ())
  in
  let name =
    Ast_builder.Default.estring ~loc Tezos_oxymeter.Metrics.TimeMeasure.file
  in
  let exit_handler =
    exit_expr
      loc
      [%expr
        Tezos_oxymeter.Metrics.TimeMetrics.generate_report [%e path] [%e name]]
  in
  ([ exit_handler ], [])

(** Create the init header for the energy metric. *)
let energy_header loc power =
  let path =
    Ast_builder.Default.estring ~loc (Tezos_oxymeter.Args.want_path ())
  in
  let name =
    Ast_builder.Default.estring ~loc Tezos_oxymeter.Metrics.EnergyMeasure.file
  in
  let args = Ast_builder.Default.estring ~loc power in
  let init_phase =
    [%stri Tezos_oxymeter.Metrics.EnergyMeasure.init [ [%e args] ]]
  in
  let exit_handler =
    exit_expr
      loc
      [%expr
        Tezos_oxymeter.Metrics.EnergyMetrics.generate_report [%e path] [%e name]]
  in
  ([ init_phase; exit_handler ], [])

(** Install a signal handler to generate the report. *)
let signal_header loc =
  if Args.want_signal () then
    let path =
      Ast_builder.Default.estring ~loc (Tezos_oxymeter.Args.want_path ())
    in
    let time_name =
      Ast_builder.Default.estring ~loc Tezos_oxymeter.Metrics.TimeMeasure.file
    in
    let time =
      if Args.want_time () then
        [%expr
          Tezos_oxymeter.Metrics.TimeMetrics.generate_report_on_signal
            [%e path]
            [%e time_name]]
      else
        [%expr
          Format.printf "No time signal handler.@." ;
          Lwt.return_unit]
    in
    let power_name =
      Ast_builder.Default.estring ~loc Tezos_oxymeter.Metrics.EnergyMeasure.file
    in
    let power =
      if Option.is_some (Args.want_power ()) then
        [%expr
          Tezos_oxymeter.Metrics.EnergyMetrics.generate_report_on_signal
            [%e path]
            [%e power_name]]
      else
        [%expr
          Format.printf "No power signal handler.@." ;
          Lwt.return_unit]
    in
    signal_expr loc time power
  else ([], [])

(** Merge the header for time, energy and signal. *)
let merge_header time energy signal = (fst time @ fst energy @ fst signal, [])

(** Specify the insertion for the header. *)
let header_insertion = function
  | None -> ([], [])
  | Some loc ->
      let time = if Args.want_time () then time_header loc else ([], []) in
      let energy =
        let power =
          match Args.want_power () with None -> "off" | Some power -> power
        in
        if power <> "off" then energy_header loc power else ([], [])
      in
      let signal = signal_header loc in
      merge_header time energy signal

(** Wrap fun call with time metric gathering. *)
let wrap_time_expr loc expr name =
  let fun_name = Ast_builder.Default.estring ~loc name in
  let file = Ast_builder.Default.estring ~loc loc.loc_start.pos_fname in
  let insert_start =
    insert_expr
      loc
      [%expr
        Tezos_oxymeter.Metrics.TimeMetrics.insert [%e file] [%e fun_name] `Start]
  in
  let insert_stop =
    insert_expr
      loc
      [%expr
        Tezos_oxymeter.Metrics.TimeMetrics.insert [%e file] [%e fun_name] `Stop]
  in
  [%expr
    [%e insert_start] ;
    let oxymeter_save_my_return =
      try [%e expr]
      with except ->
        [%e insert_stop] ;
        raise except
    in
    [%e insert_stop] ;
    oxymeter_save_my_return]

(** Wrap fun call with energy metric gathering. *)
let wrap_energy_expr loc expr name =
  let fun_name = Ast_builder.Default.estring ~loc name in
  let file = Ast_builder.Default.estring ~loc loc.loc_start.pos_fname in
  let insert_start =
    insert_expr
      loc
      [%expr
        Tezos_oxymeter.Metrics.EnergyMetrics.insert
          [%e file]
          [%e fun_name]
          `Start]
  in
  let insert_stop =
    insert_expr
      loc
      [%expr
        Tezos_oxymeter.Metrics.EnergyMetrics.insert
          [%e file]
          [%e fun_name]
          `Stop]
  in
  [%expr
    [%e insert_start] ;
    let oxymeter_save_my_return =
      try [%e expr]
      with except ->
        [%e insert_stop] ;
        raise except
    in
    [%e insert_stop] ;
    oxymeter_save_my_return]

(** AST Traverse redefinition for expression to get fun call. *)
class oxymeter_mapper_v3 =
  object (_self)
    inherit Ast_traverse.map as super

    method! expression expr =
      let expr = super#expression expr in
      let loc = expr.pexp_loc in
      match expr.pexp_desc with
      | Pexp_apply
          ({ pexp_desc = Pexp_ident { txt = Lident name; _ }; _ }, _args) ->
          let expr =
            if
              Args.want_time ()
              && Metrics.TimeMetrics.exist loc.loc_start.pos_fname name
            then wrap_time_expr loc expr name
            else expr
          in
          if
            Option.is_some (Args.want_power ())
            && Metrics.EnergyMetrics.exist loc.loc_start.pos_fname name
          then wrap_energy_expr loc expr name
          else expr
      | _ -> expr
  end

(** PPX Creation with args. *)
let () =
  let (power_key, power_spec, power_doc) = Args.power_spec in
  let (time_key, time_spec, time_doc) = Args.time_spec in
  let (signal_key, signal_spec, signal_doc) = Args.signal_spec in
  let (path_key, path_spec, path_doc) = Args.path_spec in
  let (lwt_key, lwt_spec, lwt_doc) = Args.lwt_spec in
  Driver.add_arg power_key power_spec ~doc:power_doc ;
  Driver.add_arg time_key time_spec ~doc:time_doc ;
  Driver.add_arg signal_key signal_spec ~doc:signal_doc ;
  Driver.add_arg path_key path_spec ~doc:path_doc ;
  Driver.add_arg lwt_key lwt_spec ~doc:lwt_doc ;
  let ast_mapper = new oxymeter_mapper_v3 in
  let impl = ast_mapper#structure in
  Driver.register_transformation
    "ppx-oxymeter"
    ~impl
    ~enclose_impl:header_insertion
