# Local validation evidence

Implementation and harness source: `4a76b8d` (full identity in benchmark provenance).
Core and renderer behavior are unchanged by the subsequent compiler-setup fix.
Compiler: `eadca409f68210893f366e60d0c2f0dc29a339be`, clean source checkout.
Platform/toolchain versions: [benchmark provenance](../bench/results/local-smoke/provenance.json).

Passed locally and in a separate standalone Git clone with an explicitly selected
matching compiler:

- Formatting and source checks.
- Normal and debug interpreter tests.
- GCC and Clang compiled debug tests.
- AddressSanitizer and UndefinedBehaviorSanitizer tests, including leak detection.
- Independent GNU patch application: 1,056 textual round trips.

The tests include 961 exhaustive short sequence pairs with an independent
minimality oracle, byte-level cases and exact resource boundaries. Benchmark smoke
runs pass and retain all three raw samples; they establish no comparative ranking.

Independent reviews at design, core and renderer checkpoints checked bounds,
minimality, resource behavior, output semantics and build security. Review-driven
tests cover partial-output clearing, newline transitions and independent patch
application. Final build review found that setup could reuse modified compiler
sources; commit `866156e` rejects dirty sources, hidden index flags and invalid
pins. Five isolated regression tests for these guards pass.

These are local results. Hosted CI, publication, consumer integration and platforms
other than Linux x86-64 remain unverified. Runtime allocation failure is outside
recoverable library errors. The algorithm may reject large unrelated files within
its documented budgets.
