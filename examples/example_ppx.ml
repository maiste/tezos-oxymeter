let call () =
  Unix.sleep 30 ;
  Format.printf "I'm here!"

let () =
  Format.printf "Call no loop@." ;
  call ()

let () =
  Format.printf "Call in loop@." ;
  let rec loop k =
    if k < 3 then (
      Format.printf "Loop: %d@." k ;
      call () ;
      loop (k + 1))
    else ()
  in
  loop 0
