.PHONY: all
all: build

.PHONY: mammut
mammut:
	sh scripts/dependencies

.PHONY: deps
deps:
	sh scripts/build-switch

.PHONY: dev-deps
dev-deps: deps
	eval $(opam env)
	opam install ocaml-lsp-server merlin ocamlformat

.PHONY: build
build:
	eval $(opam env)
	dune build @default

.PHONY: clean
clean:
	rm -f mammut_types.c
	eval $(opam env)
	dune clean

.PHONY: cleanall
cleanall: clean
	rm -rf _opam

.PHONY: run-example
run-example: build
	eval $(opam env)
	dune exec examples/main.exe
