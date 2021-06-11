module Smartpower = Smartpower
module Mammut = Mammut_oxymeter

module Blind = struct
  let observe () =
    let time = Unix.gettimeofday () in
    let json = `Assoc [ ("type", `Int 0); ("time", `Float time) ] in
    Lwt.return json
end

module Mock = struct
  let () = Random.self_init ()

  let observe () =
    let time = Unix.gettimeofday () in
    let json =
      `Assoc
        [ ("type", `Int 2);
          ("time", `Float time);
          ("joule", `Float (Random.float 8200.0));
          ("tension", `Float (Random.float 5.0));
          ("ampere", `Float (Random.float 4.0));
          ("power", `Float (Random.float 0.20));
          ("watt_hour", `Float (Random.float 0.50))
        ]
    in
    Lwt.return json
end

type observer =
  | Smartpower of Smartpower.station Lwt.t
  | Mock
  | Blind
  | Mammut of string option

let observe = function
  | Smartpower smartpower -> Smartpower.observe smartpower
  | Mock -> Mock.observe ()
  | Blind -> Blind.observe ()
  | Mammut _ -> Mammut.observe ()

let to_string = Yojson.show
