# Explicit sparse strategy

LCS remains the default. Its Limits, max_cells meaning, selected edit scripts and
existing rendering functions do not change. Import `diff.sparse` to opt in:

```goose
// Root declares: import diff from "carabistouflette/goose-diff@VERSION";
import diff.sparse;
import diff.unified;
// sparse::compare(old, fresh, edits, sparse::Limits { .. }) -> diff::Error
// patch::unified_sparse_context(old, fresh, out, sparse::Limits { .. }, output_limit, context_lines) -> diff::Error
```

Only sparse::Limits, sparse::compare, MAX_BYTES/MAX_LINES/MAX_STATES/MAX_WORK and
patch::unified_sparse_context are supported. Other helpers assume validated
internal arguments. See README for the current version/import and API.md for
common Edit ownership, opaque LF byte semantics and context rendering rules.

| Sparse limit | Default | Hard maximum |
| --- | ---: | ---: |
| max_bytes | 1048576 | 1048576 |
| max_lines | 16384 | 16384 |
| max_states | 1048576 | 4194304 |
| max_work | 16777216 | 67108864 |

Bytes/lines apply per input. max_states is a separately named trace/frontier
bound, never LCS max_cells. All fields allow zero; negative or above-hard values
return InvalidOptions, including empty calls. Insufficient valid budgets return
LimitExceeded. Every recoverable failure clears all logical output. There is no
approximate result, partial script, or automatic fallback between algorithms.

Prefix/suffix trimming and snake equality charge every compared byte pair to
max_work. Different lengths require no byte comparisons. Backtracking uses saved
states without comparing bytes again. Actual counter consumption can differ from
LCS. Each whole distance-d row admits d+1 slots before allocation, including
unreachable or unvisited final-row slots. No separate frontier escapes the cap.
A successful nonempty trimmed middle at distance D occupies (D+1)*(D+2)/2 slots;
an empty-sided middle needs no trace and may succeed with zero states. Frontier
work is bounded by admitted slots even when mismatches consume zero byte work.

Trace slots use 8 logical bytes each; tokens use 16 bytes per input line. Reverse
and output edit scripts each use at most 40*(old_lines+new_lines) logical bytes.
Context rendering adds its existing bounded row/hunk scratch and one shared
output cap. Capacity growth, runtime overhead and retained pages are separate;
these are not RSS guarantees. Allocation failure follows runtime policy. No I/O,
global cache, recursion or native backend is added.

Results minimize inserted plus deleted lines, with the common complete monotonic
range/coalescing contract. Sparse ties are deterministic: the farther candidate x
BEFORE its matching snake wins; equal candidate x chooses deletion. Backtracking
uses that same rule. This does not promise deletion first in the final script.
For `a\nb\n` -> `b\na\n`, sparse can emit Insert/Equal/Delete while LCS emits
Delete/Equal/Insert, both cost 2. Simple replacement ordering can differ too.
Callers needing LCS's exact output should keep LCS.

unified_sparse_context validates context/output options up front and computes its
own script. It preserves fixed labels, raw bytes, significant final LF, context
window rules, empty-range coordinates and transactional all-hunk output. Raw
patches still need terminal escaping. Different minimal scripts may yield
different valid hunks; no caller-supplied scripts are accepted.

Sparse is useful for distant changes with low edit distance. Dense rewrites can
be slower, use more trace memory or hit their state cap. The retained experiment
at b6253d0 documents those losses; it is not a universal performance claim.
Selection is explicit. No automatic strategy selection is supplied.
