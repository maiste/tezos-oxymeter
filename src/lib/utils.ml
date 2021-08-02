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
  (* TODO: Improve error. *)
end

module Name = struct
  let timestamp_name name =
    let time = Unix.time () |> Unix.localtime in
    let year = time.tm_year + 1900 |> string_of_int in
    let month = time.tm_mon + 1 |> Format.sprintf "%.2d" in
    let day = time.tm_mday |> Format.sprintf "%.2d" in
    let hour = time.tm_hour |> string_of_int in
    let minute = time.tm_min |> string_of_int in
    let second = time.tm_sec |> string_of_int in
    let timestamp =
      year ^ month ^ day ^ "-" ^ hour ^ ":" ^ minute ^ ":" ^ second
    in
    timestamp ^ "_" ^ name
end

module Args = struct
  let time = ref false

  let power = ref "off"

  let want_time () = !time

  let want_power () =
    let power = !power in
    if power = "off" then None else Some power

  let power_spec =
    ( "-energy",
      Arg.Set_string power,
      "Specify the energy source: [mock|power:<ip>:<port>]." )

  let time_spec = ("-time", Arg.Set time, "Request to have time metric.")
end
