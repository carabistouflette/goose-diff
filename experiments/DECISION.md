# Verdict: sparse capability demonstrated; no default replacement

Measured source: 6760e7b (full source/compiler/binary hashes in results/provenance.json).
The supported alpha.2 comparison and rendering sources are unchanged. This branch
is a retained experiment, not a proposed release or supported backend API.

## Gates and observations

- Four frozen sparse cases that the actual goose-check CLI omitted now reconstruct
  with minimal costs 4, 6, 8 and 4 under the same consumer input/line/compared-byte
  limits and an explicit 262,144-slot trace cap. Context output fits the existing
  raw/escaped cap and applies independently with GNU patch --fuzz=0.
- All 32 backend/profile preflight cases pass: wide-profile LCS independently
  confirms minimal costs; successful scripts reconstruct and patches apply.
- Independent tests cover 961 exhaustive short pairs, 64 byte cases, 1,000 seeded
  longer LCS comparisons, off-grid/unequal inputs, deterministic paths, exact
  storage/work limits, hard input bounds and hostile rewrites. A reviewed gap
  now tests zero-byte-cost, different-length rewrites stopped by the state cap.
- Normal/debug, GCC/Clang, ASan/UBSan and the unchanged 5,325 full/context patch
  oracle pass locally. Independent design/source and test reviews found no blocker
  to the bounded experiment. These checks do not prove all inputs correct.
- All 160 raw timing/RSS samples remain retained. In the matched wide profile,
  sparse cases favor Myers; both dense rewrites are slower and use more process
  RSS than LCS. Equal and single-edit controls show small mixed differences.
  [Interactive exact ranges](report.html) keep consumer rejection paths separate.

## Why the default stays LCS

The replacement gate fails independently of timing. The retained swap
`a\nb\n` -> `b\na\n` produces Delete/Equal/Insert in LCS and
Insert/Equal/Delete in this Myers implementation; both cost 2. Even a simple
replacement can order insert/delete differently. Moreover, the prototype's
explicit max_states cannot silently inherit the existing max_cells meaning or
rejection thresholds. No normalization or hidden fallback is added to conceal
these observable differences.

A future production path should be explicit opt-in with reviewed strategy,
trace/frontier work/storage limits and deterministic tie semantics. It should
retain LCS as an independent oracle and retain dense controls. That API decision
is separate from this experiment; no default switch, release, consumer vendor
update or parent catalog pin is made here.

## Measurement limits

Five rounds per backend/profile/fixture, 20 repeated calls each, alternate backend
order on one GCC -O2 binary. Timing excludes file reads and independent validation.
RSS is GNU time's whole-process peak, including runtime/preflight/repeated calls;
not algorithm heap usage or an end-to-end CLI memory bound. Logical i64-slot
ceilings do not include allocator capacity, tokens or reverse/output buffers.
The host is uncontrolled. No universal speedup, latency percentile or production
consumer speed claim follows. Dense losses and every error-path sample remain
published rather than discarded.
