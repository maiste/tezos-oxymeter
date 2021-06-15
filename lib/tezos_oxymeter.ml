module Smartpower = Smartpower
module Mammut = Mammut_oxymeter
module Report = Report

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

let observe = function
  | Blind -> Blind.observe ()
  | Mammut _ -> Mammut.observe ()
  | Smartpower smartpower -> Smartpower.observe smartpower
  | Mock -> Mock.observe ()

let to_string report =
  Report.json_of_t report
  |> Data_encoding.Json.to_string ~newline:true ~minify:false
