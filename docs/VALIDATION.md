# Validation

Use the clean compiler source revision recorded in GOOSE_REVISION.

```sh
make setup
make check test test-debug test-gcc test-clang test-patch test-consumer sanitize bench
```

Core tests enumerate 961 short sequence pairs using an independent exponential
edit-cost oracle and independent line boundaries. They check minimality,
reconstruction, complete monotonic coverage, equality, coalescing and determinism.
Additional cases cover binary bytes, final LF, CRLF, stale output, invalid options,
exact/one-below budgets, hard byte/line boundaries and adversarial long lines.
Unified tests check exact bytes and output boundaries. `test-patch` independently
applies generated small textual patches with GNU patch (install `patch`). GCC/Clang builds and
ASan/UBSan exercise generated native code; checks do not prove every input safe.

CI uses an immutable checkout action and read-only permissions. Alpha.3 was
published with green exact-source hosted CI and validated goose-check adoption.
For each subsequent release, validate an exact-source standalone clone, obtain
independent review and green exact-source CI, and record source/toolchain
identities. See the [release qualification procedure](RELEASE.md).

[Retained local results](RESULTS.md) record tested source and limitations.

Context rendering adds exact coordinate, merged/separate hunk, binary/newline,
invalid-option and all-hunk rollback tests. The independent GNU patch oracle
uses --fuzz=0 and checks 5,325 legacy/context round trips. Retained representative
call timings and the algorithm decision are in [context evidence](CONTEXT_RESULTS.md).

Sparse qualification adds independent exponential/LCS minimality oracles, seeded
comparisons, exact trace/work bounds, invalid/empty inputs and zero-byte-cost
hostile rewrites. Sparse context shares the independent GNU patch oracle, now
9,585 LCS/sparse cases. Existing LCS and context goldens remain unchanged. The
retained experimental branch b6253d0 provides earlier performance evidence; its
results are historical and not a universal speed or memory claim.

The external consumer target copies a standalone program into a fresh temporary
directory outside the checkout. It imports the root and both submodules, checks
all supported entry points, constants/defaults, distinct LCS/sparse tie behavior,
raw binary/final-LF rendering and empty output after errors. It runs normal/debug
and GCC/Clang compiled checks. A separate published import check can select an
immutable revision or tag with `--import-source`; see RELEASE.md.
