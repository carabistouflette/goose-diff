# Validation

Use the clean compiler source revision recorded in GOOSE_REVISION.

```sh
make setup
make check test test-debug test-gcc test-clang test-patch sanitize bench
```

Core tests enumerate 961 short sequence pairs using an independent exponential
edit-cost oracle and independent line boundaries. They check minimality,
reconstruction, complete monotonic coverage, equality, coalescing and determinism.
Additional cases cover binary bytes, final LF, CRLF, stale output, invalid options,
exact/one-below budgets, hard byte/line boundaries and adversarial long lines.
Unified tests check exact bytes and output boundaries. `test-patch` independently
applies generated small textual patches with GNU patch (install `patch`). GCC/Clang builds and
ASan/UBSan exercise generated native code; checks do not prove every input safe.

CI uses an immutable checkout action and read-only permissions. Hosted CI has
not run until this standalone repository is published. Before release validate
an exact-source standalone clone, obtain independent review, and document
source/toolchain identities. No public release or consumer migration is implied.

[Retained local results](RESULTS.md) record tested source and limitations.

Context rendering adds exact coordinate, merged/separate hunk, binary/newline,
invalid-option and all-hunk rollback tests. The independent GNU patch oracle
uses --fuzz=0 and checks 5,325 legacy/context round trips. Retained representative
call timings and the algorithm decision are in [context evidence](CONTEXT_RESULTS.md).
