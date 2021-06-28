let observe () =
  let time = Unix.gettimeofday () in
  let counter = Mammut.Energy.getCounter () in
  let joule : float = Mammut.Energy.Counter.getJoules counter in
  let watt_hour = joule /. 3600. in
  let report = Report.create ~joule ~watt_hour time in
  Lwt.return report
