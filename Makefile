BINARY := teerr
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "none")
DATE := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

LDFLAGS := -s -w \
	-X main.version=$(VERSION) \
	-X main.commit=$(COMMIT) \
	-X main.date=$(DATE)

.PHONY: all build test clean install snapshot

all: build

build:
	go build -o $(BINARY) -ldflags="$(LDFLAGS)"

test:
	go test -v ./...

clean:
	rm -f $(BINARY) $(BINARY)-*
	rm -rf dist/

install: build
	install -m 755 $(BINARY) $(DESTDIR)$(PREFIX)/bin/$(BINARY)

# GoReleaser snapshot (for testing releases locally)
snapshot:
	goreleaser release --snapshot --clean

# Cross-compilation
.PHONY: build-all build-linux build-darwin

build-linux:
	GOOS=linux GOARCH=amd64 go build -o $(BINARY)-linux-amd64 -ldflags="$(LDFLAGS)"
	GOOS=linux GOARCH=arm64 go build -o $(BINARY)-linux-arm64 -ldflags="$(LDFLAGS)"

build-darwin:
	GOOS=darwin GOARCH=amd64 go build -o $(BINARY)-darwin-amd64 -ldflags="$(LDFLAGS)"
	GOOS=darwin GOARCH=arm64 go build -o $(BINARY)-darwin-arm64 -ldflags="$(LDFLAGS)"

build-all: build-linux build-darwin
