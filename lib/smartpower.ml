open Lwt.Infix
open Lwt_unix

let ( let* ) x f = Lwt.bind x f

type station = file_descr

let create ip_addr port =
  let inet_addr = Unix.inet_addr_of_string ip_addr in
  let sock_addr = ADDR_INET (inet_addr, port) in
  let domain = Unix.domain_of_sockaddr sock_addr in
  let sock = socket domain SOCK_STREAM 0 in
  connect sock sock_addr >|= fun () -> sock

let delete sock = sock >|= fun sock -> shutdown sock SHUTDOWN_ALL

let float_re = Re.Str.regexp "[0-9]+[.][0-9]+"

let filter raw_data =
  let splitted_raw_data =
    String.split_on_char ',' raw_data |> List.map String.trim
  in
  let length = List.length splitted_raw_data in
  if length <> 4 then
    raise
      (Failure
         Format.(
           sprintf "Got list of size %d instead of 4 : %s" length raw_data))
  else
    let filter_float raw_data =
      let open Re.Str in
      if string_match float_re raw_data 0 then
        matched_string raw_data |> Float.of_string
      else raise (Failure ("Data can't be parse: " ^ raw_data))
    in
    List.map filter_float splitted_raw_data

let get_data_from sock =
  let* sock = sock in
  let size = 512 in
  let buffer = Bytes.create size in
  let* data = recv sock buffer 0 size [] in
  let bytes = Bytes.sub buffer 0 data in
  Lwt.return (Bytes.to_string bytes)

let observe_raw sock =
  let* raw_data = get_data_from sock in
  let energy_data = filter raw_data in
  Lwt.return energy_data

let json_of_report energy_report =
  let tag = ("type", `Int 1) in
  let energy_report_json =
    List.map (fun (name, value) -> (name, `Float value)) energy_report
  in
  `Assoc (tag :: energy_report_json)

let observe sock =
  let time = Unix.gettimeofday () in
  let* energy_data = observe_raw sock in
  let energy_array = Array.of_list energy_data in
  let time = ("time", time) in
  let volt = ("tension", energy_array.(0)) in
  let ampere = ("ampere", energy_array.(1)) in
  let power = ("power", energy_array.(2)) in
  let watt_hour = ("watt_hour", energy_array.(3)) in
  let energy_report = [ time; volt; ampere; power; watt_hour ] in
  let energy_report_json = json_of_report energy_report in
  Lwt.return energy_report_json
