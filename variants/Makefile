# Builds all teerr variants for benchmarking

BINDIR := bin

# Go variants
GO_MINIMAL    := $(BINDIR)/go-minimal
GO_FD_STRCONV := $(BINDIR)/go-fd-strconv

# TinyGo variants (optional)
TINYGO_MINIMAL := $(BINDIR)/tinygo-minimal

# C variants
C_MINIMAL := $(BINDIR)/c-minimal
C_FD      := $(BINDIR)/c-fd

# Rust variants (optional)
RUST_MINIMAL := $(BINDIR)/rust-minimal
RUST_FD      := $(BINDIR)/rust-fd

# Check if cargo is available
HAVE_CARGO := $(shell command -v cargo 2>/dev/null)

# Check if tinygo is available
HAVE_TINYGO := $(shell command -v tinygo 2>/dev/null)

CORE_BINS := $(GO_MINIMAL) $(GO_FD_STRCONV) $(C_MINIMAL) $(C_FD)

ALL_BINS := $(CORE_BINS)

ifdef HAVE_TINYGO
ALL_BINS += $(TINYGO_MINIMAL)
endif

ifdef HAVE_CARGO
ALL_BINS += $(RUST_MINIMAL) $(RUST_FD)
endif

.PHONY: all clean sizes rust

all: $(ALL_BINS)
ifndef HAVE_CARGO
	@echo ""
	@echo "Note: Rust variants skipped (cargo not found)"
endif

$(BINDIR):
	mkdir -p $(BINDIR)

# Go builds
$(GO_MINIMAL): go-minimal/main.go | $(BINDIR)
	cd go-minimal && go build -o ../$(GO_MINIMAL)

$(GO_FD_STRCONV): go-fd-strconv/main.go | $(BINDIR)
	cd go-fd-strconv && go build -o ../$(GO_FD_STRCONV)

# TinyGo builds
$(TINYGO_MINIMAL): go-minimal/main.go | $(BINDIR)
	cd go-minimal && tinygo build -o ../$(TINYGO_MINIMAL) .

# C builds (optimized)
$(C_MINIMAL): c-minimal/teerr.c | $(BINDIR)
	$(CC) -O2 -Wall -o $(C_MINIMAL) c-minimal/teerr.c

$(C_FD): c-fd/teerr.c | $(BINDIR)
	$(CC) -O2 -Wall -o $(C_FD) c-fd/teerr.c

# Rust builds (release mode)
rust: $(RUST_MINIMAL) $(RUST_FD)

$(RUST_MINIMAL): rust-minimal/src/main.rs rust-minimal/Cargo.toml | $(BINDIR)
	cd rust-minimal && cargo build --release
	cp rust-minimal/target/release/teerr $(RUST_MINIMAL)

$(RUST_FD): rust-fd/src/main.rs rust-fd/Cargo.toml | $(BINDIR)
	cd rust-fd && cargo build --release
	cp rust-fd/target/release/teerr $(RUST_FD)

clean:
	rm -rf $(BINDIR)
	rm -rf rust-minimal/target rust-fd/target

sizes: all
	@echo "=== Binary sizes ==="
	@ls -lhS $(ALL_BINS) | awk '{print $$5 "\t" $$9}'
