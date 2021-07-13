module type MEASURE = sig
  type t

  val getMeasure : unit -> t

  val diff : t -> t -> t

  val to_string : t -> string

  val to_json : t -> Ezjsonm.value
end

module type METRICS = sig
  val insert : string -> string -> [< `Start | `Stop ] -> unit

  val exist : string -> string -> bool

  val generate_report : unit -> Ezjsonm.value
end

module TimeMeasure : MEASURE = struct
  type t = float

  let getMeasure () = Unix.gettimeofday ()

  let diff x y = x -. y

  let to_string = string_of_float

  let to_json t = `Float t
end

let build_new_archive_table () =
  let module JSON = Utils.JSON in
  match JSON.parse_metrics_config () with
  | None -> Hashtbl.create 0 (* To content the type system. *)
  | Some json ->
      let files_list = JSON.extract_from_obj json in
      let files = Hashtbl.create (List.length files_list) in
      let () =
        (* Build a hash table according to the json specification. *)
        List.iter
          (fun (file, value) ->
            let functions_list = JSON.extract_from_array value in
            let functions = Hashtbl.create (List.length functions_list) in
            let () =
              List.iter
                (fun fun_name ->
                  let fun_name = JSON.extract_from_string fun_name in
                  Hashtbl.add functions fun_name (Queue.create ()))
                functions_list
            in
            Hashtbl.add files file functions)
          files_list
      in
      files

module MakeMetrics (M : MEASURE) : METRICS = struct
  type state = Start of M.t | Stop of M.t

  type functions = (string, state Queue.t) Hashtbl.t

  let files : (string, functions) Hashtbl.t = build_new_archive_table ()

  let insert file fun_name state =
    let metric =
      let measure = M.getMeasure () in
      match state with `Start -> Start measure | `Stop -> Stop measure
    in
    match Hashtbl.find_opt files file with
    | Some functions -> (
        match Hashtbl.find_opt functions fun_name with
        | Some track -> Queue.push metric track
        | None -> raise Not_found)
    | None -> raise Not_found
  (* TODO improve error *)

  let exist file fun_name =
    match Hashtbl.find_opt files file with
    | Some functions -> Hashtbl.mem functions fun_name
    | None -> false

  let extract_from_states track =
    let rec iter last_start acc =
      if not (Queue.is_empty track) then
        let state = Queue.pop track in
        match (last_start, state) with
        | (Some start, Stop stop) ->
            let diff = M.diff stop start in
            let json = M.to_json diff in
            let acc = json :: acc in
            iter None acc
        | (None, Start start) -> iter (Some start) acc
        | _ -> iter last_start acc
      else acc
    in
    iter None []

  (* This fonction can be called later to extract information as JSON
     from the files hashtable. *)
  let generate_report () : Ezjsonm.value =
    let obj_list =
      Hashtbl.fold
        (fun file functions report ->
          let obj_list =
            Hashtbl.fold
              (fun fun_name track report ->
                let metric_list = extract_from_states track in
                (fun_name, `A metric_list) :: report)
              functions
              []
          in
          (file, `O obj_list) :: report)
        files
        []
    in
    `O obj_list
end

module TimeMetrics = MakeMetrics (TimeMeasure)
