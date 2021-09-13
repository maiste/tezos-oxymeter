open Lwt.Infix
open Tezos_oxymeter

let observe_smart () =
  let open Lwt.Infix in
  let smartpower = Observer.Smartpower.create "127.0.0.1" 50500 in
  let obs = Observer.Smartpower smartpower in
  let nb_iter = 10 in
  let () = Format.printf "Observe smartpower@." in
  let rec aux k =
    if k < nb_iter then (
      Format.printf "Loop %d@." k ;
      ( Observer.observe obs >|= fun content ->
        Format.printf "%s@." (Observer.to_string content) )
      >>= fun () -> aux (k + 1))
    else Lwt.return_unit
  in
  aux 0

let observe_blind () =
  let obs = Observer.Blind in
  let () = Format.printf "Observe bind@." in
  (Observer.observe obs >|= fun json -> Observer.to_string json) >|= fun str ->
  Format.printf "%s@." str

let observe_mock () =
  let obs = Observer.Mock in
  let () = Format.printf "Observe mock@." in
  (Observer.observe obs >|= fun json -> Observer.to_string json) >|= fun str ->
  Format.printf "%s@." str

let () =
  Lwt_main.run @@ observe_blind () ;
  Lwt_main.run @@ observe_mock ()
(*Lwt_main.run @@ observe_smart () ;*)
