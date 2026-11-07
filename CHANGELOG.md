# Changelog

## v0.1.0

- Freeze the documented supported API and behavior for compatible v0.1.x patches.
- Check every supported entry point from a fresh external consumer directory.
- Preserve alpha.3 implementation bytes, LCS defaults and explicit sparse selection.
- Clarify pre-1.0 scope, runtime failure policy and platform qualification.

## v0.1.0-alpha.3

- Add explicit sparse comparison with a separate trace-state Limits type.
- Add transactional sparse context output with documented deterministic ties.
- Preserve LCS defaults, budget meanings and legacy output; no automatic selection.

## v0.1.0-alpha.2

- Add configurable bounded context hunks; preserve the legacy full-file renderer.
- Check exact hunk coordinates and independent no-fuzz patch application.

## v0.1.0-alpha.1

- Experimental bounded byte-exact line comparison and unified patch rendering.
- Portable core with explicit input, line, matrix, comparison and output limits.
