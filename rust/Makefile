CARGO ::= cargo '--config=source.system.directory="/usr/share/cargo/registry"' \
         '--config=source.crates-io.replace-with="system"' \
         --offline
all: qubes-utils-sys/src/rust_bindings.rs
	$(CARGO) build
check: all
	$(CARGO) test

qubes-utils-sys/src/rust_bindings.rs: ../qrexec-lib/pure.h Makefile
	bindgen --depfile=rust_bindings.dep '--allowlist-item=^qubes_pure.*' $< > $@.tmp
	mv $@.tmp $@
.PHONY: all check
-include rust_bindings.dep
-include target/*/*.d
