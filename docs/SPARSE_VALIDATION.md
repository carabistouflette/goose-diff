# Sparse strategy qualification

The search, predecessor selection and backtracking kernels are byte-identical
to retained experiment b6253d0. The supported API replaces its experimental
resource adapter with a separate sparse::Limits type and independent validation;
there is no unused max_cells field. The LCS core remains byte-unchanged.

Independent contract/security review and independently authored tests check
minimality, byte reconstruction, monotonic/coalesced ranges, tie differences,
invalid/empty inputs, exact trace/work bounds, off-grid paths and binary/final-LF
semantics. A zero-byte-cost different-length rewrite is bounded by trace states.
Context tests include multi-hunk rollback and exact output boundaries.

Local normal/debug, GCC/Clang and ASan/UBSan validation passes. The expanded
independent GNU patch --fuzz=0 oracle passes 9,585 LCS/sparse round trips. Existing
LCS and context goldens remain unchanged. The runnable sparse example validates
two distant replacements with the consumer-sized byte/line/state/work budgets.

Experimental performance samples remain available on branch experiment/bounded-myers.
They include all 160 samples, dense losses and RSS limitations; this promotion
does not relabel those timings as production or end-to-end consumer measurements.
No universal speedup, memory guarantee or automatic selection is claimed.

Hosted exact-source CI, public-clone qualification, tagged import and the final
release/consumer pins are separate publication gates recorded in the PR and
catalog receipt. This file records local results only.
