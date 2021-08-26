let ( >>= ) = Result.bind

let ( let* ) = Result.bind

type category = Energy | Time

type info =
  { date : string; time : string; category : category; json : Ezjsonm.t }

let create_res_info date time category json =
  Result.ok { date; time; category; json }

type data = { energy : info list; time : info list }

let empty_res_data = Result.ok { energy = []; time = [] }

let open_opt file =
  try open_in file |> Result.ok
  with _ -> Result.error "Sorry, we can't open this file."

let get_json_from file =
  let* cin = open_opt file in
  try
    let res = Ezjsonm.from_channel cin |> Result.ok in
    let () = close_in cin in
    res
  with Ezjsonm.Parse_error _ ->
    Result.error "Sorry, we are not able to parse the JSON file."

let check_dir dir = Sys.file_exists dir && Sys.is_directory dir

let enumerate_files path =
  if check_dir path then
    try Sys.readdir path |> Result.ok
    with _ -> Result.error "Sorry, we can't read the directory you specified."
  else Result.error "Sorry, the path you specify is not an existing directory."

let is_well_format file =
  let rex =
    Re.Pcre.regexp "^[0-9]{8}-[0-9]{2}:[0-9]{2}:[0-9]{2}_(energy|time).json$"
  in
  Re.Pcre.pmatch ~rex file

let extract_info path =
  let file = Filename.basename path in
  if is_well_format file then
    let* json = get_json_from path in
    let name = Filename.remove_extension file in
    match String.split_on_char '-' name with
    | [ date; tail ] -> (
        match String.split_on_char '_' tail with
        | [ time; "energy" ] -> create_res_info date time Energy json
        | [ time; "time" ] -> create_res_info date time Time json
        | _ -> Result.error "Sorry, your file is not well-formatted.")
    | _ -> Result.error "Sorry, your file is not well-formatted."
  else
    Result.error
      "Your file is not well-formatted: it should be \
       YYYYMMDD-HH:MM:SS_[energy|time].json"

let extract_data_from path =
  let* dir = enumerate_files path in
  let dir = Array.to_list dir in
  let iterator acc l =
    let path = Filename.concat path l in
    acc >>= fun acc ->
    let* info = extract_info path in
    match info.category with
    | Energy -> Result.ok { acc with energy = info :: acc.energy }
    | Time -> Result.ok { acc with time = info :: acc.time }
  in
  List.fold_left iterator empty_res_data dir

let debug_info ?(verbose = false) { date; time; category; json } =
  let json_s =
    if verbose then Format.sprintf "%s\n" (Ezjsonm.to_string ~minify:true json)
    else ""
  in
  match category with
  | Energy -> Format.printf "- %s %s\n%s" date time json_s
  | Time -> Format.printf "- %s %s\n%s" date time json_s

let debug_data ?(verbose = false) data =
  Format.printf "=== Energy data ===\n" ;
  List.iter (debug_info ~verbose) data.energy ;
  Format.printf "===  Time data  ===\n" ;
  List.iter (debug_info ~verbose) data.time ;
  Format.printf "===================@."
