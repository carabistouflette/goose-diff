#!/usr/bin/env python3
"""Independent GNU patch application oracle for generated textual diffs."""
import itertools
from pathlib import Path
import subprocess
import sys
import tempfile

binary = str(Path(sys.argv[1]).resolve())
texts = {""}
for count in range(1, 4):
    for lines in itertools.product(("a\n", "b\n"), repeat=count):
        text = "".join(lines)
        texts.update((text, text[:-1]))
texts.update(("a\r\n", "b\r\na\r\n", "@@ -1,1 +1,1 @@\n", "--- a/input\n"))
count = 0
with tempfile.TemporaryDirectory(prefix="goose-diff-patch-") as directory:
    target = Path(directory) / "input"
    for old, new in itertools.product(sorted(texts), repeat=2):
        result = subprocess.run([binary, old, new], check=True, stdout=subprocess.PIPE, timeout=10)
        if old == new:
            assert result.stdout == b""
            continue
        target.write_bytes(old.encode())
        applied = subprocess.run(
            ["patch", "--batch", "--silent", "--binary", "--forward", str(target)],
            input=result.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10,
        )
        assert applied.returncode == 0, (old, new, result.stdout, applied.stdout, applied.stderr)
        assert (target.read_bytes() if target.exists() else b"") == new.encode(), (old, new)
        count += 1
print(f"GNU patch independent round trips passed: {count}")
