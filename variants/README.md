# teerr variants

This directory contains implementations of `teerr` in multiple languages for benchmarking and comparison purposes.

## Variants

| Directory | Language | Description |
|-----------|----------|-------------|
| `go-minimal/` | Go | Minimal version (stdout + stderr only) |
| `go-fd-strconv/` | Go | FD variant using strconv.Atoi |
| `c-minimal/` | C | Minimal C implementation |
| `c-fd/` | C | C with optional FD argument |
| `rust-minimal/` | Rust | Minimal Rust implementation |
| `rust-fd/` | Rust | Rust with optional FD argument |

Note: The main `teerr` program is built with TinyGo for optimal size/speed balance.

## Building

```bash
make all        # build all variants
make clean      # remove binaries
make sizes      # show binary sizes
```

Requires:
- Go 1.21+
- TinyGo 0.34+ (optional, for tinygo-minimal)
- A C compiler (cc/gcc/clang)
- Rust/Cargo (optional, for Rust variants)

## Benchmark Results

Tested on Apple Silicon (M-series), 500MB random data, 10 iterations with randomized ordering:

| Variant | Throughput | Binary Size |
|---------|------------|-------------|
| teerr (main, TinyGo) | 8524 MB/s | 182K |
| Go (standard) | 8742 MB/s | 1.9M |
| C | 8321 MB/s | 33K |
| Rust | 6197 MB/s | 280K |
| `tee >(cat >&2)` | 628 MB/s | — |

## Analysis

### Why Go beats C on throughput

At 500MB data sizes (beyond L3 cache), Go's `io.Copy` with `io.MultiWriter` outperforms our simple C implementation:

- Go uses 32KB internal buffers with optimized copy paths
- Go's runtime can leverage `io.ReaderFrom` / `io.WriterTo` interfaces
- The C implementation uses a straightforward 8KB read/write loop

The C version could potentially be made faster with larger buffers or `writev()` for batched syscalls, but the goal was simplicity.

### Why TinyGo is the sweet spot

| Metric | TinyGo | Go | C |
|--------|--------|-----|---|
| Binary size | 182K | 1.9M | 33K |
| Throughput | 8524 MB/s | 8742 MB/s | 8321 MB/s |
| Size vs Go | 11x smaller | baseline | 58x smaller |
| Speed vs Go | 97% | 100% | 95% |

TinyGo achieves nearly identical performance to standard Go while producing binaries 11x smaller. The only thing smaller is C, but C is actually slightly slower.

### Why Rust lags

Rust's `std::io` uses locked handles (`stdin.lock()`, etc.) which add synchronization overhead. At high throughput (8+ GB/s), this overhead becomes measurable. A Rust implementation using raw file descriptors would likely match Go/C performance.
