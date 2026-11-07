# Context rendering qualification

Context implementation checkpoint: `3613d54`; benchmark harness and measured source:
`c4ed872` (full identity and compiler/binary hashes in retained provenance).
Comparison core and legacy full-file rendering are unchanged from alpha.1.

Independent implementation and contract/security reviews checked bounded hunk
planning, coordinate arithmetic, window union, zero-count ranges, monotonic byte
scanning, missing-final-newline handling and output rollback. Normal/debug tests,
GCC/Clang debug executables, ASan/UBSan and 5,325 no-fuzz GNU patch round trips pass.
The pre-existing exponential minimality/reconstruction oracle is retained.

[All75 raw samples and inputs](../bench/results/context-alpha2/) are retained.
The pinned compiler produced actual diagnostic blocks; the harness aggregates
independent compilation units with one changed unit. Other cases include generated
text, scattered edits, dense rewrites and repeated long lines. Every call uses the
consumer's fixed comparison budgets and raw16KiB cap, with rotating mode order.

For the diagnostic transcript and generated middle edit, comparison succeeds but
full-file output exceeds the cap; context rendering succeeds. Scattered edits
succeed in both renderers. Dense/long-line cases still fail comparison budgets in
all modes. Context therefore addresses output volume, not larger unresolved LCS
middles or comparison-byte cost.

Core-only and whole-call timings are separate observations, not isolated internal
CPU phases. Shared-host variation, allocation and input shape limit interpretation;
no subtraction-based attribution, throughput ranking or universal speedup is
claimed. No alternative algorithm was measured. Retain bounded LCS and its
independent correctness oracle in this release; Myers is deferred until a named
workload needs larger unresolved middles and can justify separate work/memory
contracts, comparative profiles and independent minimality tests.

This is local evidence. Hosted CI and public release identity are separate gates
recorded in the PR and catalog receipt; local results are not relabeled as CI.
