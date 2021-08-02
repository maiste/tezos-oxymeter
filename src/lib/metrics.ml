open Lwt.Infix

module type MEASURE = sig
  type t

  val file : string

  val wanted : unit -> bool

  val init : string option -> unit

  val getMeasure : unit -> t Lwt.t

  val diff : t -> t -> t Lwt.t

  val to_string_lwt : t -> string Lwt.t

  val to_ezjsonm_lwt : t -> Ezjsonm.value Lwt.t
end

module type METRICS = sig
  val insert : string -> string -> [< `Start | `Stop ] -> unit

  val exist : string -> string -> bool

  val generate_report : string -> string -> unit
end

module TimeMeasure : MEASURE = struct
  type t = float

  let file = "time.json"

  let flag_on = ref false

  let wanted () = !flag_on

  let init _args = flag_on := Utils.Args.want_time ()

  let getMeasure () = Unix.gettimeofday () |> Lwt.return

  let diff x y = Lwt.return (x -. y)

  let to_string_lwt t = Lwt.return (string_of_float t)

  let to_ezjsonm_lwt t = Lwt.return (`Float t)
end

module EnergyMeasure : MEASURE = struct
  type t = Report.t

  let file = "energy.json"

  let flag_on = ref false

  let wanted () = !flag_on

  let observer = ref Observer.Blind

  let init _args =
    match Utils.Args.want_power () with
    | None -> ()
    | Some power ->
        flag_on := true ;
        let obs = Observer.create (String.split_on_char ':' power) in
        observer := obs

  let getMeasure () =
    let observer = !observer in
    Observer.observe observer

  let diff r1 r2 = Lwt.return (Report.diff r1 r2)

  let to_ezjsonm_lwt t = Lwt.return (Report.ezjsonm_of_t t)

  let to_string_lwt t = Lwt.return (Report.string_of_t t)
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
    Lwt_main.run
    @@ ( ( M.getMeasure () >|= fun measure ->
           match state with `Start -> Start measure | `Stop -> Stop measure )
       >|= fun metric ->
         match Hashtbl.find_opt files file with
         | Some functions -> (
             match Hashtbl.find_opt functions fun_name with
             | Some track -> Queue.push metric track
             | None -> raise Not_found)
         | None -> raise Not_found )

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
            acc >>= fun acc ->
            M.diff stop start >>= fun diff ->
            M.to_ezjsonm_lwt diff >>= fun json ->
            let acc = json :: acc in
            iter None (Lwt.return acc)
        | (None, Start start) -> iter (Some start) acc
        | _ -> iter last_start acc
      else acc
    in
    iter None (Lwt.return [])

  (* This fonction can be called later to extract information as JSON
     from the files hashtable. *)
  let generate_report path name =
    let () = Utils.Sys.create_opt path in
    let name = Utils.Name.timestamp_name name in
    let json_path = Filename.concat path name in
    let build_local_report fun_name track report =
      report >>= fun report ->
      extract_from_states track >>= fun metric_list ->
      Lwt.return ((fun_name, `A metric_list) :: report)
    in
    let global_report =
      Hashtbl.fold
        (fun file functions global_report ->
          Hashtbl.fold build_local_report functions (Lwt.return [])
          >>= fun local_report ->
          global_report >|= fun global_report ->
          (file, `O local_report) :: global_report)
        files
        (Lwt.return [])
    in
    Lwt_main.run
    @@ ( global_report >|= fun global_report ->
         let global_report = `O global_report in
         Utils.JSON.export_to ~path:json_path global_report )
end

module TimeMetrics = MakeMetrics (TimeMeasure)
module EnergyMetrics = MakeMetrics (EnergyMeasure)
