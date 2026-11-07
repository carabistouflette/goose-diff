# API and contracts

Import the root as `diff`; `import diff.unified;` also provides namespace `patch`.
Supported API: Error, Kind, Edit, Limits, diff::compare, patch::unified and hard
limit constants. Other module-visible helpers assume validated internal arguments
and are unsupported implementation details.

```goose
fn compare(old: const u8[:], fresh: const u8[:], out: Edit[>..]&, limits: Limits) -> Error
fn unified(old: const u8[:], fresh: const u8[:], out: u8[>..]&, limits: diff::Limits, output_limit: i64) -> diff::Error
```

Error is None, InvalidOptions, or LimitExceeded. Every call clears output first;
all recoverable failures leave its logical length zero. The caller owns output;
clearing may retain capacity. Inputs are borrowed only during the call. Runtime
allocation failure policy applies; OOM is not a recoverable library error.

## Lines and edits

LF belongs to its preceding line. Empty bytes have zero lines. A final LF adds
no phantom line. Final newline presence is significant. CRLF, NUL, invalid UTF-8
and control bytes are opaque byte data; there is no normalization.

Edit contains kind (Equal, Delete, Insert) and zero-based, half-open line ranges
old_start..old_end, new_start..new_end. Insert has an empty old range, Delete an
empty new range, Equal equal-length byte-identical line ranges. Runs cover both
inputs monotonically and adjacent identical kinds are merged. The result owns
only indices: keep exact input bytes to interpret them.

The result minimizes inserted plus deleted lines, without substitution or moves.
Equal prefix/suffix lines are retained. Reconstruction of the remaining LCS table
prefers deletion when alternative costs tie; this is not a global lexicographic
tie-break across every possible optimal script.

## Limits

All limits are nonnegative. Negative or above-hard-bound options return
InvalidOptions before inspecting input. Valid but insufficient budgets return
LimitExceeded; there is no approximate fallback or partial diff.

| Limit | Default | Hard maximum | Meaning |
| --- | ---: | ---: | --- |
| max_bytes | 1048576 | 1048576 | Each input separately |
| max_lines | 16384 | 16384 | Each input separately |
| max_cells | 1048576 | 4194304 | Trimmed matrix, including sentinel row/column |
| max_work | 16777216 | 67108864 | Byte-pair comparisons |
| output_limit | Required | 8388608 | Raw unified output bytes |

Byte comparisons in trimming, DP and reconstruction all consume max_work;
different line lengths cost no comparisons. Exact exhaustion succeeds if no
further comparisons are required. Input scans and matrix operations are separately
bounded by max_bytes/max_lines/max_cells; max_work is not an instruction count.
Empty-sided middles need no matrix and allow zero cells. Zero work allows only
paths requiring no byte comparisons. Input/line limits apply before trimming.

The algorithm scans O(input bytes), trims equal edges, then uses O(n*m) cells for
unresolved middle lengths n,m. Each cell may compare line bytes until mismatch
or budget exhaustion. Logical matrix storage is 8 bytes per cell (default at
most 8 MiB, hard at most 32 MiB). Two token lists use 16 bytes per line; edits
use 40 bytes per run, at most old_lines + new_lines runs. These exclude allocator
capacity growth, runtime overhead and caller-retained buffers. No recursion,
hashing, hidden cache, I/O or native backend is used.

## Unified rendering

patch::unified computes its own edits and emits one full-file unified hunk,
including all equal context. Identical inputs emit no bytes. Labels are fixed
a/input and b/input. Ranges include explicit counts; empty ranges start at zero,
nonempty ranges at one. Missing-final-LF lines receive the standard
`\ No newline at end of file` marker. No timestamps or custom labels are accepted.

Output contains raw bytes: escape before terminal display. Binary bytes remain
unmodified, without claiming compatibility with every external patch tool.
Rendering adds scans bounded by both input sizes and appends at most output_limit
bytes. It accepts no caller-constructed edit script. Output storage must be
distinct from input storage; Goose borrow rules enforce the supported pattern.
Patch application, context selection, intra-line differences and Unicode
segmentation are outside v1.
