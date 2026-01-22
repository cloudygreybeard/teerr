# teerr

Copy standard input to both standard output and standard error.

```bash
value=$(command | teerr)
```

## Why

Shell pipelines hide intermediate values. When debugging or logging, you often want to see what's flowing through a pipeline without disrupting it.

The traditional approach is:

```bash
export VAR=$(command | tee >(cat >&2))
```

This works, but it's awkward to type and surprisingly slow. `teerr` exists to replace it.

## Installation

### Homebrew (macOS/Linux)

```bash
brew install cloudygreybeard/tap/teerr
```

### Go install

```bash
go install github.com/cloudygreybeard/teerr@latest
```

### From source

```bash
git clone https://github.com/cloudygreybeard/teerr
cd teerr
make
```

## Usage

```bash
# Capture output in a variable while echoing to stderr
value=$(command | teerr)

# Observe pipeline output without altering flow
generate | teerr | consume

# Write to a different file descriptor instead of stderr
command | teerr 3    # writes to stdout and fd 3

# Version and help
teerr --version
teerr --help
```

## Performance

`teerr` is **2.5x faster** than `tee >(cat >&2)`.

Tested on Apple Silicon, 500MB random data, 10 iterations with randomized ordering:

| Variant | Throughput | Binary Size |
|---------|------------|-------------|
| **teerr (Go)** | **8742 MB/s** | 1.9M |
| C | 8321 MB/s | 33K |
| Rust | 6197 MB/s | 280K |
| `tee >(cat >&2)` | 628 MB/s | — |

All compiled variants are **10-14x faster** than the shell construct.

See [variants/](variants/) for implementations in Go, C, and Rust used for benchmarking.

## Manual

```
TEERR(1)                         User Commands                         TEERR(1)

NAME
     teerr — copy standard input to standard output and standard error

SYNOPSIS
     teerr [fd]
     teerr --version
     teerr --help

DESCRIPTION
     teerr reads data from the standard input and writes it unchanged
     to both the standard output and the standard error (or an alternate
     file descriptor if specified).

OPTIONS
     -V, --version    Print version information and exit
     -h, --help       Print usage information and exit

ARGUMENTS
     fd    File descriptor to write to instead of stderr (default: 2)

EXAMPLES
     Capture output in a variable while echoing to standard error:

           value=$(command | teerr)

     Observe pipeline output without altering the pipeline:

           generate | teerr | consume

     Write to file descriptor 3 instead of stderr:

           command | teerr 3

EXIT STATUS
     teerr exits 0 on success.
     A non-zero exit status indicates an I/O error.

SEE ALSO
     tee(1), sh(1), cat(1)
```

## License

Apache 2.0. See [LICENSE](LICENSE).
