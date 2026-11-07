#!/usr/bin/env bash
set -euo pipefail
exec "${SANITIZER_CC:-clang}" -fsanitize=address,undefined -fno-omit-frame-pointer "$@"
