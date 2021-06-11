open Lwt.Infix
open Tezos_oxymeter

let observe_smart () =
  let open Lwt.Infix in
  let smartpower = Smartpower.create "127.0.0.1" 50500 in
  let obs = Smartpower smartpower in
  let nb_iter = 10 in
  let () = Format.printf "Observe smartpower@." in
  let rec aux k =
    if k < nb_iter then (
      Format.printf "Loop %d@." k ;
      (observe obs >|= fun content -> Format.printf "%s@." (to_string content))
      >>= fun () -> aux (k + 1))
    else Lwt.return_unit
  in
  aux 0

let observe_blind () =
  let obs = Blind in
  let () = Format.printf "Observe bind@." in
  (observe obs >|= fun json -> to_string json) >|= fun str ->
  Format.printf "%s@." str

let observe_mock () =
  let obs = Mock in
  let () = Format.printf "Observe mock@." in
  (observe obs >|= fun json -> to_string json) >|= fun str ->
  Format.printf "%s@." str

let observe_mammut () =
  let obs = Mammut None in
  let () = Format.printf "Observe mammut@." in
  (observe obs >|= fun json -> to_string json) >|= fun str ->
  Format.printf "%s@." str

let test_suite = [ observe_blind; (*observe_smart;*) observe_mock ]

let () = List.iter (fun test -> Lwt_main.run @@ test ()) test_suite
