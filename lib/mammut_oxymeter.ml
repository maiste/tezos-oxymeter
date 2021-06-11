let observe () =
  let time = Unix.gettimeofday () in
  let counter = Mammut.Energy.getCounter () in
  let raw_joule : float = Mammut.Energy.Counter.getJoules counter in
  let time = ("time", `Float time) in
  let joule = ("joule", `Float raw_joule) in
  let volt = ("volt", `Float 0.) in
  let ampere = ("ampere", `Float 0.) in
  let power = ("power", `Float 0.) in
  let watt_hour = ("watt_hour", `Float (raw_joule /. 3600.)) in
  let energy_report = [ time; joule; volt; ampere; power; watt_hour ] in
  Lwt.return (`Assoc (("type", `Int 3) :: energy_report))
