# Contributing

Use focused branches and Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`,
`perf:`, `chore:`). Each commit should describe one coherent change. Never commit
compiler caches, binaries, credentials or private coordination notes.

Use the exact compiler in GOOSE_REVISION. Run `make setup`, `make format`, then
`make check test test-debug test-gcc test-clang test-patch sanitize`. Behavior changes need
independent review and positive, failure and boundary tests. Preserve empty
output on errors and all documented byte, line, memory and work limits.

Keep the core portable and free of I/O. Profile before optimizing; record exact
source/compiler identities, workload, flags and raw samples. Retain regressions
and slower results. CI checks behavior, not speed thresholds. Do not claim
comparative performance without equivalent workloads and measured evidence.

Before publication, validate a standalone clone, obtain independent review,
complete exact-source CI, and configure a private vulnerability reporting channel.
Use semantic versions and never move a published tag. This API is experimental.
