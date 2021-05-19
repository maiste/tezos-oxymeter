module Smartpower = Smartpower

module Blind = struct
  let observe () =
    let time = Unix.gettimeofday () in
    let json = `Assoc [ ("type", `Int 0); ("time", `Float time) ] in
    Lwt.return json
end

type observer = Smartpower of Smartpower.station Lwt.t | Blind

let observe = function
  | Smartpower smartpower -> Smartpower.observe smartpower
  | Blind -> Blind.observe ()

let to_string = Yojson.show
