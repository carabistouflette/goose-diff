# Benchmarks

`make bench` builds with the pinned compiler, GCC and `-O2`, then runs 100
iterations of each deterministic workload. Columns: workload, elapsed nanoseconds,
iterations, old bytes, new bytes, checksum. Timing includes tokenization, matrix
allocation, comparisons and edit production; inputs are constructed outside it.
Output storage is reused; internal scratch storage is allocated per call.

Workloads cover equal files, one middle edit, append, deletion, entirely different
lines, and repeated long lines that exhaust the byte-comparison budget. The last
case measures explicit rejection, not successful diff throughput.

For retained runs record `git rev-parse HEAD`, the compiler's exact source revision
and clean status, `gcc --version`, `uname -a`, CPU model, build flags, iteration
count, and all raw samples. Run multiple rounds without concurrent heavy jobs.
Do not infer cross-language or cross-machine speed from these smoke measurements.
No comparative performance claim is made. Changes to algorithms need identical
fixtures and budgets, including retained slower results.

## Context workloads

```sh
make bench-context-build
python3 bench/context.py --binary .build/context-bench --goose /absolute/pinned/goose --out .build/context-samples
```

The source tree must be clean. This captures real pinned-compiler diagnostics,
aggregates independent compilation units with one changed unit, and constructs
large generated text, scattered edits, dense rewrites and long-line fixtures.
The exact inputs, raw samples and provenance are retained. All modes use the
consumer's byte/line/matrix/work budgets and 16 KiB output cap. Modes rotate order
across rounds. Core-only timing and whole rendering-call timing are separate
observations; subtraction is not an isolated internal-phase profiler. Rejection
paths remain labeled and must not be compared as successful throughput.

Context reduces rendered output, not comparison work or supported input size.
These shared-host measurements establish no universal speedup or ranking and do
not justify replacing bounded LCS without a concrete workload and acceptance gate.
