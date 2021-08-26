open Cmdliner

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
  let open Reader in
  let verbose = copts.verbose in
  extract_data_from copts.path
  >>= (fun data -> debug_data ~verbose data |> Result.ok)
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
