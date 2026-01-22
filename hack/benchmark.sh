#!/usr/bin/env bash
#
# Benchmark teerr variants
#
# Measures throughput by piping data through each variant
# and timing how long it takes. Randomizes order to reduce bias.
#
# Usage:
#   ./hack/benchmark.sh              # benchmark all variants
#   ./hack/benchmark.sh --quick      # fewer iterations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
VARIANTS_DIR="$ROOT_DIR/variants"
BINDIR="$VARIANTS_DIR/bin"

SIZE_MB=500
ITERATIONS=10

if [[ "$1" == "--quick" ]]; then
    ITERATIONS=3
fi

echo "=== teerr benchmark ==="
echo "Data size: ${SIZE_MB}MB, Iterations: $ITERATIONS (randomized order)"
echo ""

# Build main teerr if not present
if [[ ! -x "$ROOT_DIR/teerr" ]]; then
    echo "Building teerr..."
    (cd "$ROOT_DIR" && make build)
fi

# Build variants if available
if [[ -d "$VARIANTS_DIR" ]] && [[ -f "$VARIANTS_DIR/Makefile" ]]; then
    echo "Building variants..."
    (cd "$VARIANTS_DIR" && make all 2>/dev/null) || true
fi

# Find all binaries to test
BINS=()
[[ -x "$ROOT_DIR/teerr" ]] && BINS+=("$ROOT_DIR/teerr")
if [[ -d "$BINDIR" ]]; then
    for bin in "$BINDIR"/*; do
        [[ -x "$bin" ]] && BINS+=("$bin")
    done
fi

if [[ ${#BINS[@]} -eq 0 ]]; then
    echo "Error: No binaries found."
    exit 1
fi

# Generate test data once
TESTDATA=$(mktemp)
RESULTS=$(mktemp)
trap "rm -f $TESTDATA $RESULTS" EXIT
echo "Generating ${SIZE_MB}MB test data..."
dd if=/dev/urandom of="$TESTDATA" bs=1M count="$SIZE_MB" 2>/dev/null

echo ""
echo "=== Running $ITERATIONS iterations with randomized order ==="
echo ""

for i in $(seq 1 $ITERATIONS); do
    # Shuffle the binaries for this iteration
    shuffled=($(printf '%s\n' "${BINS[@]}" | sort -R))
    
    echo -n "Iteration $i: "
    for bin in "${shuffled[@]}"; do
        name=$(basename "$bin")
        echo -n "$name "
        
        # Time the operation
        start=$(python3 -c 'import time; print(time.time())')
        cat "$TESTDATA" | "$bin" >/dev/null 2>/dev/null
        end=$(python3 -c 'import time; print(time.time())')
        
        elapsed=$(python3 -c "print($end - $start)")
        echo "$name $elapsed" >> "$RESULTS"
    done
    echo ""
done

echo ""
echo "=== Results (averaged over $ITERATIONS runs) ==="
echo ""

# Use Python to aggregate and display results
python3 << EOF
from collections import defaultdict

times = defaultdict(list)
with open("$RESULTS") as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) == 2:
            name, elapsed = parts
            times[name].append(float(elapsed))

size_mb = $SIZE_MB
results = []
for name, elapsed_list in times.items():
    avg = sum(elapsed_list) / len(elapsed_list)
    throughput = size_mb * 2 / avg
    results.append((throughput, avg, name))

results.sort(reverse=True)

print(f"{'VARIANT':<20} {'AVG TIME':>12} {'THROUGHPUT':>12}")
print(f"{'-------':<20} {'--------':>12} {'----------':>12}")
for throughput, avg, name in results:
    print(f"{name:<20} {avg:>10.4f}s {throughput:>10.1f} MB/s")
EOF

echo ""
echo "=== Binary sizes ==="
for bin in "${BINS[@]}"; do
    size=$(ls -lh "$bin" | awk '{print $5}')
    name=$(basename "$bin")
    echo -e "$size\t$name"
done | sort -h
