# Security

Report suspected vulnerabilities privately through
[GitHub private vulnerability reporting](https://github.com/carabistouflette/goose-diff/security/advisories/new).
Include affected source/compiler revisions, platform and a minimal reproducer.
Do not include sensitive fixtures or vulnerability details in public issues.
The supported v0.1.x API follows the [compatibility policy](docs/RELEASE.md).
This pre-1.0 project provides no support SLA or platform guarantees beyond its
documented qualification. Report issues against the latest v0.1.x patch release.

The core accepts arbitrary bytes, including NUL, invalid UTF-8 and terminal
control sequences. It performs no I/O. Input, token, matrix/trace and byte-comparison
limits bound algorithmic work; they are not process isolation or a wall-clock
limit. Allocation failure follows the compiler/runtime policy, not a recoverable
library error. Caller-owned output can retain capacity after being cleared.

Unified output contains raw input bytes. It is suitable for files or explicit
patch consumers; it must be escaped by a terminal renderer before display.
No input-controlled filenames or labels are accepted. No patch application is
provided. See docs/API.md for exact limits and failure behavior.

The explicit [sparse strategy](docs/SPARSE.md) counts every retained trace slot
before layer allocation; byte-free mismatches remain bounded by its state cap.
Sparse and LCS limits are distinct, with no automatic fallback.
