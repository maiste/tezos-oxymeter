type t =
  { time : float;
    joule : float;
    volt : float;
    ampere : float;
    power : float;
    watt_hour : float
  }

let create ?(joule = 0.0) ?(volt = 0.0) ?(ampere = 0.0) ?(power = 0.0)
    ?(watt_hour = 0.0) time =
  { time; joule; volt; ampere; power; watt_hour }

let encode =
  let open Data_encoding in
  conv
    (fun { time; joule; volt; ampere; power; watt_hour } ->
      (time, joule, volt, ampere, power, watt_hour))
    (fun (time, joule, volt, ampere, power, watt_hour) ->
      { time; joule; volt; ampere; power; watt_hour })
    (obj6
       (req "time" float)
       (req "joule" float)
       (req "volt" float)
       (req "ampere" float)
       (req "power" float)
       (req "watt_hour" float))

let pp ppf t =
  let json_str =
    Data_encoding.Json.construct encode t
    |> Data_encoding.Json.to_string ~newline:true ~minify:false
  in
  Format.fprintf ppf "%s" json_str

let json_of_t t =
  let open Data_encoding in
  Json.construct encode t
