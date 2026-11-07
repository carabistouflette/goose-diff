# Bounded Myers experiment — not production API

Question: can a small-edit-distance backend recover useful goose-check diffs when
sparse, distant changes exceed the alpha.2 LCS matrix budget, without unbounded
search or silently changing public contracts?

Named consumer: goose-check --diff at 9524439 (full source/binary identity in
fixtures/manifest.json). Eight frozen cases retain all inputs and actual CLI
stderr. Four sparse cases contain distant replacements in generated text, actual
pinned-compiler diagnostic blocks, or repeated lines. Equal/single-edit cases
and dense rewrites are controls. All fit the consumer's existing input bounds.
These are reproducible representative command fixtures, not claimed user incidents.

## Gates fixed before timing analysis

1. The actual alpha.2 CLI must reproduce omission for the four sparse cases under
   65,536 input bytes, 4,096 lines, 262,144 matrix cells and 1,048,576 byte comparisons.
2. A successful candidate must reconstruct all bytes with complete, monotonic,
   coalesced edits and independently verified minimal insertion/deletion cost.
   Sparse costs are 4, 6, 8 and 4. Higher-budget LCS is the algorithmic oracle;
   exhaustive short cases additionally use an independent exponential oracle.
3. Candidate input/line and actual compared-byte bounds stay the same. Explicit
   max_states counts every retained int64 trace slot, including unreachable and
   unvisited final-row slots, before admitting a full layer. Consumer-profile
   cap 262,144 means 2 MiB logical trace, not a process-memory guarantee.
4. Every failure clears output. Invalid options, empty/unequal inputs, off-grid
   paths, byte/work boundaries, repeated lines and state-bound hostile rewrites
   need positive and negative tests plus GCC/Clang and ASan/UBSan qualification.
5. Sparse candidate success must fit the existing context-rendering output cap
   and apply independently. Bounded-LCS rejection timing is a capability control,
   never a successful-throughput denominator. Successful matched-profile cases,
   dense regressions, every raw sample, source/compiler identities and RSS remain
   retained. No universal speedup or heap-size claim follows from shared-host data.
6. Default adoption requires preserving existing budget meanings and deterministic
   script contracts. A different equally minimal script is an API difference.
   max_cells cannot silently become a frontier budget. If these gates fail,
   retain the prototype out of main; any production path needs an explicit,
   independently reviewed opt-in API/resource contract.

## Prototype bounds

experiments/myers.goose is evaluation code on the experiment branch. It reuses
internal validated line/equality helpers, but has an independent search and
backtracking algorithm. The stable compare function and renderer are unchanged.
max_cells is validated as part of Limits but unused in this experimental call;
max_states 0..4194304 is separate and must not be represented as equivalent.

For nonempty trimmed middles at edit distance D, complete retained rows occupy
(D+1)*(D+2)/2 slots. Empty-sided middles need no trace. Every frontier visit is
bounded by stored slots; snakes consume the common compared-byte budget. Trace
slots use 8 logical bytes. Token buffers use 16 bytes per input line; reverse and
output scripts each use at most 40 * (old_lines+new_lines) logical bytes. Allocator
capacity, runtime overhead, retained pages and allocation failure are separate.
Backtracking does not compare bytes again. No recursion or approximate fallback.

Farthest candidate-x predecessor wins; equal candidate x selects deletion.
This frontier rule does not imply LCS's returned-script tie rule. Tests retain
counterexamples instead of normalizing away an observable difference.

## Reproduce

Use the exact compiler in GOOSE_REVISION. The experiment branch wires its tests
and qualification into the existing Make/CI matrix; main has no experiment API.

```sh
make check test test-debug test-gcc test-clang test-patch sanitize experiment-verify
make experiment-build
python3 experiments/benchmark.py --binary .build/myers-measure --goose /absolute/pinned/goose --out .build/myers-samples
```

Run with a clean source tree. Consumer profile matches current input/byte-work
bounds and uses separately named equal logical-slot ceilings for each backend.
Wide profile gives both backends 4,194,304 int64 slots and 67,108,864 compared-byte
pairs to obtain successful controls. These are not interchangeable API counters.
Modes alternate order. Failed calls stay labeled; compare successful calls only
within the same profile/input. Timing excludes file reads and independent script
verification. RSS includes runtime, preflight and repeated calls; it is not heap
accounting or a single CLI invocation. Keep every raw sample and slower result.

To reproduce CLI baselines, build goose-check at the full source in the fixture
manifest and run experiments/fixtures.py --consumer /absolute/goose-check. This
rewrites frozen fixtures and is deliberately outside timed measurements/CI.
