# v0.1 release contract

v0.1.0 is the first release without an alpha suffix. It retains alpha.3's
implementation and freezes the supported API listed in [API.md](API.md) for
v0.1.x patch releases. LCS remains the default; sparse stays an explicit opt-in
with separate limits and deterministic ordering. No automatic fallback is added.

Within v0.1.x, preserve supported names/signatures, enum variants, field names and
defaults, hard maxima and budget units, documented ownership, error/output
semantics and selected edit ordering. Patch releases may fix behavior that
violates the documented contract; such corrections must be described in the
changelog and tested. New capabilities must preserve existing supported calls.
A change to this contract requires a new minor version and migration notes.

This is a project compatibility commitment for the v0.1.x series, not a claim
that pre-1.0 Semantic Versioning requires a stable API. Internal helpers, generated
code, compiler ABI/layout and allocation capacity are outside the contract.
Qualification currently covers Linux x86-64/glibc with the exact compiler in
GOOSE_REVISION, GCC and Clang. Other compilers/platforms remain unqualified.
There is no support SLA or universal performance/RSS guarantee.

Every supported call clears its output first. Invalid options return
InvalidOptions before input processing; insufficient valid budgets return
LimitExceeded. Both leave logical output empty, even after partial work.
Zero budgets are valid and succeed only when the operation needs none of that
resource. Allocation failure follows the runtime policy and is not recoverable
through diff::Error. Raw patch bytes require terminal escaping. See API.md and
SPARSE.md for the exact resource and ordering contracts.

## Qualification and publication

1. Use a clean standalone clone and the compiler pinned in GOOSE_REVISION.
   Run `make setup`, then
   `make check test test-debug test-gcc test-clang test-patch test-consumer sanitize bench`.
   Retain exact source/compiler identities and full results. If the system temp
   directory lacks space, set TMPDIR to a writable directory with sufficient space.
2. Obtain independent API/security and release-readiness reviews. Resolve findings
   and obtain green hosted CI for the exact reviewed candidate before tagging.
3. Check a public import from a fresh consumer directory:
   `python3 tests/consumer.py .toolchain/goose/build/goose --import-source carabistouflette/goose-diff@FULL_COMMIT`.
   The test uses an empty isolated GOOSE_HOME package cache and removes its
   temporary directory. Pass `--expected-revision FULL_COMMIT` to verify the
   resolved package identity.
4. Create an immutable v0.1.0 tag and a GitHub release without the prerelease flag.
   Never move an existing tag. Repeat the external consumer command with
   `--import-source carabistouflette/goose-diff@v0.1.0` and verify the resolved
   source matches the tag. Record public CI/release and catalog pins in the catalog
   receipt, which can include evidence collected after the immutable tag.

Historical alpha results retain their original identities. This release makes
no new comparative performance claim. The benchmark target is a smoke check.
