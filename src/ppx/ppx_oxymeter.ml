open Ppxlib
open Tezos_oxymeter

let wrap_time_expr loc expr name =
  let fun_name = Ast_builder.Default.estring ~loc name in
  let file = Ast_builder.Default.estring ~loc loc.loc_start.pos_fname in
  [%expr
    Metrics.TimeMetrics.insert [%e file] [%e fun_name] `Start ;
    let save = [%e expr] in
    Metrics.TimeMetrics.insert [%e file] [%e fun_name] `Stop ;
    save]

class oxymeter_mapper_v3 =
  object (_self)
    inherit Ast_traverse.map as super

    method! expression expr =
      let expr = super#expression expr in
      let loc = expr.pexp_loc in
      match expr.pexp_desc with
      | Pexp_apply
          ({ pexp_desc = Pexp_ident { txt = Lident name; _ }; _ }, _args) ->
          if Metrics.TimeMetrics.exist loc.loc_start.pos_fname name then
            let new_expr = wrap_time_expr loc expr name in
            new_expr
          else expr
      | _ -> expr
  end

let () =
  let (power_key, power_spec, power_doc) = Args.power_spec in
  let (time_key, time_spec, time_doc) = Args.time_spec in
  Driver.add_arg power_key power_spec ~doc:power_doc ;
  Driver.add_arg time_key time_spec ~doc:time_doc ;
  let ast_mapper = new oxymeter_mapper_v3 in
  let impl = ast_mapper#structure in
  Driver.register_transformation "ppx-oxymeter" ~impl
