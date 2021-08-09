(lang dune 2.0)
(generate_opam_files true)

(name tezos_oxymeter)
(license MIT)
(source (github maiste/tezos-oxymeter))
(authors "Étienne Marais <etienne.marais@nomadic-labs.com")
(maintainers "Étienne Marais <etienne.marais@nomadic-labs.com")

(package
 (name tezos_oxymeter)
 (synopsis "Library to gather information about consumption")
 (description "Gather informations about consumption from smartpowers and msr registers.")
 (depends
   (ocaml (>= 4.12.0))
   (dune (>= 2.5))
   lwt
   re
   (yojson (>= 1.5.0))
    ezjsonm
   (data-encoding (>= 0.4))
   (odoc :with-doc))
)

(package
  (name ppx-tezos_oxymeter)
  (synopsis "Ppx for Tezos-oxymeter")
  (description "A simple ppx for tezos_oxymeter.")
  (depends
    (ocaml (>= 4.12.0))
    (dune (>= 2.5))
    ppxlib
  ))

