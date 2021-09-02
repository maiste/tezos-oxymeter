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

## Explore PPX reports

When you install `ppx-tezos_oxymeter`, the library comes with a small explorer
named `tzoexplorer`. Indeed, as the time spent generating report increases, you
can have many files in the report directory. You can use this explorer to
navigate the different reports you've produced.

### Show the reports available

```sh
  $ tzoexplorer show [--path -p path] [--verbose -v]
```

### Export the reports in one file

```sh
 $ tzoexplorer export [--path -p path] [--verbose -v] PATH
```

### Show specific parts

```sh
  $ tzoexplorer explore [--path -p path] [--verbose -v] [--date -d YYYYMMJJ]\
    [--time -t HH:MM:SS] [--measure --m <energy | time> ]
```
