# Tezos-oxymeter

## Purpose

The project aims to provide an interface to compute the energy consumption for
Tezos. It comes with two tools:
 - `tezos_oxymeter`, a library to reach systems to compute energy.
 - `ppx-tezos_oxymeter`, a ppx to instrument portion of code.

This code is released during my internship at Nomadic Labs. It's a research
project.

The documentation is available [online](https://maiste.github.io/tezos-oxymeter/)

## Build the project

To develop the project, you need to build.

```sh
  $ opam switch create . --empty
  $ opam install . --deps-only
  $ dune build
```
