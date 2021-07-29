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
    else if not (Sys.is_directory path) then ()
    else failwith "Can't create a directory: conflict with filename"
  (* TODO: Improve error. *)
end

module Name = struct
  let timestamp_name name =
    let timestamp = Unix.gettimeofday () |> string_of_float in
    timestamp ^ "_" ^ name
end
