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
end
