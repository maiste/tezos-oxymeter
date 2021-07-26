module Smartpower = Smartpower

module Mammut = Mammut_oxymeter

module Blind = struct
  let observe () =
    let time = Unix.gettimeofday () in
    let report = Report.create time in
    Lwt.return report
end

module Mock = struct
  let () = Random.self_init ()

  let observe () =
    let time = Unix.gettimeofday () in
    let joule = Random.float 8200.0 in
    let volt = Random.float 5.0 in
    let ampere = Random.float 4.0 in
    let power = Random.float 0.2 in
    let watt_hour = Random.float 0.5 in
    let report = Report.create ~joule ~volt ~ampere ~power ~watt_hour time in
    Lwt.return report
end

type observer =
  | Blind
  | Mock
  | Smartpower of Smartpower.station Lwt.t
  | Mammut of string option

let create = function
  | [] | ["off"] -> Blind
  | ["mock"] -> Mock
  | ["msr"] -> Mammut None
  | ["power" ; host ; port ] ->
      let port = match int_of_string_opt port with
      | Some port -> port
      | None -> 23
      in
      let station = Smartpower.create host port in
      Smartpower station
  | _ -> raise Not_found

let observe = function
  | Blind -> Blind.observe ()
  | Mock -> Mock.observe ()
  | Mammut _ -> Mammut.observe ()
  | Smartpower smartpower -> Smartpower.observe smartpower

let to_string report =
  Report.json_of_t report
  |> Data_encoding.Json.to_string ~newline:true ~minify:false

let pp ppf = function
  | Blind -> Format.fprintf ppf "blind"
  | Mock -> Format.fprintf ppf "mock"
  | Smartpower _ -> Format.fprintf ppf "smartpower"
  | Mammut _ -> Format.fprintf ppf "mammut"
