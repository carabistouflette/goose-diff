# Security

This local experimental project has no public vulnerability reporting endpoint
yet. Report suspected vulnerabilities privately to the repository owner; do not
include sensitive fixtures in public issues. Publication requires a configured
private reporting channel and an updated policy with its exact destination.

The core accepts arbitrary bytes, including NUL, invalid UTF-8 and terminal
control sequences. It performs no I/O. Input, token, matrix and byte-comparison
limits bound algorithmic work; they are not process isolation or a wall-clock
limit. Allocation failure follows the compiler/runtime policy, not a recoverable
library error. Caller-owned output can retain capacity after being cleared.

Unified output contains raw input bytes. It is suitable for files or explicit
patch consumers; it must be escaped by a terminal renderer before display.
No input-controlled filenames or labels are accepted. No patch application is
provided. See docs/API.md for exact limits and failure behavior.
