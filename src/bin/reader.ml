let ( >>= ) = Result.bind

let ( let* ) = Result.bind

module Info = struct
  type category = Energy | Time

  type t =
    { date : string; time : string; category : category; json : Ezjsonm.t }

  let create ~date ~time category json = { date; time; category; json }

  let date { date; _ } = date

  let time { time; _ } = time

  let category { category; _ } = category

  let json { json; _ } = json
end

module Data = struct
  type t = { energy : Info.t list; time : Info.t list }

  let empty = { energy = []; time = [] }

  let energy { energy; _ } = energy

  let time { time; _ } = time
end

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

let extract_info_r path =
  let file = Filename.basename path in
  if is_well_format file then
    let* json = get_json_from path in
    let name = Filename.remove_extension file in
    match String.split_on_char '-' name with
    | [ date; tail ] -> (
        match String.split_on_char '_' tail with
        | [ time; "energy" ] ->
            Info.create ~date ~time Info.Energy json |> Result.ok
        | [ time; "time" ] ->
            Info.create ~date ~time Info.Time json |> Result.ok
        | _ -> Result.error "Sorry, your file is not well-formatted.")
    | _ -> Result.error "Sorry, your file is not well-formatted."
  else
    Result.error
      "Your file is not well-formatted: it should be \
       YYYYMMDD-HH:MM:SS_[energy|time].json"

let extract_data_from_r path =
  let* dir = enumerate_files path in
  let dir = Array.to_list dir in
  let iterator acc l =
    let path = Filename.concat path l in
    acc >>= fun acc ->
    let* info = extract_info_r path in
    match info.category with
    | Energy -> Result.ok Data.{ acc with energy = info :: acc.energy }
    | Time -> Result.ok Data.{ acc with time = info :: acc.time }
  in
  List.fold_left iterator (Result.ok Data.empty) dir
