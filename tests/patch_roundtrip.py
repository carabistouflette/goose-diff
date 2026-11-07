#!/usr/bin/env python3
"""Independent GNU patch application oracle for full-file and context hunks."""
import itertools
from pathlib import Path
import subprocess
import sys
import tempfile

binary = str(Path(sys.argv[1]).resolve())
texts = {""}
for line_count in range(1, 4):
    for lines in itertools.product(("a\n", "b\n"), repeat=line_count):
        text = "".join(lines)
        texts.update((text, text[:-1]))
texts.update(("a\r\n", "b\r\na\r\n", "@@ -1,1 +1,1 @@\n", "--- a/input\n"))
cases = list(itertools.product(sorted(texts), repeat=2))
# Larger inputs exercise separated hunks, changing cumulative line offsets and
# patch-looking content without sharing the implementation's hunk planner.
old_lines = [f"src/item_{i:03d}.goose:12: error: expected value\n" for i in range(80)]
new_lines = old_lines.copy()
for at in (2, 20, 60):
    new_lines[at] = new_lines[at].replace("expected value", "unexpected token")
cases.append(("".join(old_lines), "".join(new_lines)))
old_lines = [f'setting_{i:03d} = "{i:03d}"\n' for i in range(128)]
new_lines = ["# inserted header\n", *old_lines[:40], 'setting_040 = "changed"\n',
             *old_lines[41:100], *old_lines[101:], "# inserted footer\n"]
cases.extend((("".join(old_lines), "".join(new_lines)), ("".join(new_lines), "".join(old_lines))))
old_lines = [f"line {i:02d}" for i in range(20)]
new_lines = old_lines.copy()
for at in (0, 10, 19):
    new_lines[at] += " modified"
cases.append(("\r\n".join(old_lines) + "\r\n", "\r\n".join(new_lines)))
for gap in (1, 2, 3, 6, 7):
    middle = "".join(f"context {i}\n" for i in range(gap))
    cases.append(("before\nold1\n" + middle + "old2\nafter",
                  "before\nnew1\n" + middle + "new2\nafter"))
contexts = (None, 0, 1, 3, 16384)
count = 0
with tempfile.TemporaryDirectory(prefix="goose-diff-patch-") as directory:
    target = Path(directory) / "input"
    for backend, context in [("lcs", c) for c in contexts] + [("sparse", c) for c in contexts if c is not None]:
        for old, new in cases:
            command = [binary, old, new]
            if context is not None:
                command.append(str(context))
            if backend == "sparse":
                command.append("sparse")
            result = subprocess.run(command, check=True, stdout=subprocess.PIPE, timeout=10)
            if old == new:
                assert result.stdout == b"", context
                continue
            target.write_bytes(old.encode())
            applied = subprocess.run(
                ["patch", "--batch", "--silent", "--binary", "--forward", "--fuzz=0", str(target)],
                input=result.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10,
            )
            assert applied.returncode == 0, (context, old, new, result.stdout, applied.stdout, applied.stderr)
            assert (target.read_bytes() if target.exists() else b"") == new.encode(), (context, old, new)
            count += 1
print(f"GNU patch independent LCS/sparse full/context round trips passed: {count}")
