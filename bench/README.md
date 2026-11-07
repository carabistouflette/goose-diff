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
