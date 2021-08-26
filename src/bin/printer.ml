open Reader

let show_info ?(verbose = false) info =
  let date = Info.date info in
  let time = Info.time info in
  let category = Info.category info in
  let json = Info.json info in
  let json_s =
    if verbose then Format.sprintf "%s\n" (Ezjsonm.to_string ~minify:true json)
    else ""
  in
  match category with
  | Energy -> Format.printf "- %s %s\n%s" date time json_s
  | Time -> Format.printf "- %s %s\n%s" date time json_s

let show_data ?(verbose = false) data =
  Format.printf "=== Energy data ===\n" ;
  List.iter (show_info ~verbose) (Data.energy data) ;
  Format.printf "===  Time data  ===\n" ;
  List.iter (show_info ~verbose) (Data.time data) ;
  Format.printf "===================@."
