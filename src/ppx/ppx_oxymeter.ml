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

let time_header loc =
  let path =
    Ast_builder.Default.estring ~loc (Tezos_oxymeter.Args.want_path ())
  in
  let name =
    Ast_builder.Default.estring ~loc Tezos_oxymeter.Metrics.TimeMeasure.file
  in
  let exit_handler =
    [%stri
      at_exit (fun () ->
          Tezos_oxymeter.Metrics.TimeMetrics.generate_report [%e path] [%e name])]
  in
  ([ exit_handler ], [])

let energy_header loc power =
  let path =
    Ast_builder.Default.estring ~loc (Tezos_oxymeter.Args.want_path ())
  in
  let name =
    Ast_builder.Default.estring ~loc Tezos_oxymeter.Metrics.EnergyMeasure.file
  in
  let args = Ast_builder.Default.estring ~loc power in
  let exit_handler =
    [%stri
      Tezos_oxymeter.Metrics.EnergyMeasure.init [ [%e args] ] ;
      at_exit (fun () ->
          Tezos_oxymeter.Metrics.EnergyMetrics.generate_report
            [%e path]
            [%e name])]
  in
  ([ exit_handler ], [])

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
      else [%expr Format.printf "No time signal handler.@."]
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
      else [%expr Format.printf "No power signal handler.@."]
    in
    ( [ [%stri
          Sys.signal
            Sys.sigusr1
            (Sys.Signal_handle
               (fun _ ->
                 [%e time] ;
                 [%e power]))]
      ],
      [] )
  else ([], [])

let merge_header time energy signal = (fst time @ fst energy @ fst signal, [])

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

let wrap_time_expr loc expr name =
  let fun_name = Ast_builder.Default.estring ~loc name in
  let file = Ast_builder.Default.estring ~loc loc.loc_start.pos_fname in
  [%expr
    Tezos_oxymeter.Metrics.TimeMetrics.insert [%e file] [%e fun_name] `Start ;
    let oxymeter_save_my_return =
      try [%e expr]
      with except ->
        Tezos_oxymeter.Metrics.TimeMetrics.insert [%e file] [%e fun_name] `Stop ;
        raise except
    in
    Tezos_oxymeter.Metrics.TimeMetrics.insert [%e file] [%e fun_name] `Stop ;
    oxymeter_save_my_return]

let wrap_energy_expr loc expr name =
  let fun_name = Ast_builder.Default.estring ~loc name in
  let file = Ast_builder.Default.estring ~loc loc.loc_start.pos_fname in
  [%expr
    Tezos_oxymeter.Metrics.EnergyMetrics.insert [%e file] [%e fun_name] `Start ;
    let oxymeter_save_my_return =
      try [%e expr]
      with except ->
        Tezos_oxymeter.Metrics.EnergyMetrics.insert
          [%e file]
          [%e fun_name]
          `Stop ;
        raise except
    in
    Tezos_oxymeter.Metrics.EnergyMetrics.insert [%e file] [%e fun_name] `Stop ;
    oxymeter_save_my_return]

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

let () =
  let (power_key, power_spec, power_doc) = Args.power_spec in
  let (time_key, time_spec, time_doc) = Args.time_spec in
  let (signal_key, signal_spec, signal_doc) = Args.signal_spec in
  let (path_key, path_spec, path_doc) = Args.path_spec in
  Driver.add_arg power_key power_spec ~doc:power_doc ;
  Driver.add_arg time_key time_spec ~doc:time_doc ;
  Driver.add_arg signal_key signal_spec ~doc:signal_doc ;
  Driver.add_arg path_key path_spec ~doc:path_doc ;
  let ast_mapper = new oxymeter_mapper_v3 in
  let impl = ast_mapper#structure in
  Driver.register_transformation
    "ppx-oxymeter"
    ~impl
    ~enclose_impl:header_insertion