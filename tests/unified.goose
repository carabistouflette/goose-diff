// SPDX-License-Identifier: Apache-2.0
import diff from "..";
import diff.unified;
import std;

fn golden(a: const u8[:], b: const u8[:], expected: const u8[:]) {
    golden("x", "x\n", "--- a/input\n+++ b/input\n@@ -1,1 +1,1 @@\n-x\n\\ No newline at end of file\n+x\n");
    golden("x", "a\nx", "--- a/input\n+++ b/input\n@@ -1,1 +1,2 @@\n+a\n x\n\\ No newline at end of file\n");
    golden("a\nx", "x", "--- a/input\n+++ b/input\n@@ -1,2 +1,1 @@\n-a\n x\n\\ No newline at end of file\n");
    var out: u8[>..] = [99];
    assert(patch::unified(a, b, out, diff::Limits { .. }, expected.len) == diff::Error.None);
    assert(out == expected);
    if expected.len > 0 {
        assert(patch::unified(a, b, out, diff::Limits { .. }, expected.len - 1) == diff::Error.LimitExceeded);
        assert(out.len == 0);
    }
}
fn main() {
    golden("", "", "");
    golden("same\n", "same\n", "");
    golden("a\nb\nc\n", "a\nx\nc\n", "--- a/input\n+++ b/input\n@@ -1,3 +1,3 @@\n a\n-b\n+x\n c\n");
    golden("", "x\n", "--- a/input\n+++ b/input\n@@ -0,0 +1,1 @@\n+x\n");
    golden("x\n", "", "--- a/input\n+++ b/input\n@@ -1,1 +0,0 @@\n-x\n");
    golden("x", "y", "--- a/input\n+++ b/input\n@@ -1,1 +1,1 @@\n-x\n\\ No newline at end of file\n+y\n\\ No newline at end of file\n");
    golden("x\n", "x", "--- a/input\n+++ b/input\n@@ -1,1 +1,1 @@\n-x\n+x\n\\ No newline at end of file\n");
    golden("a\r\n", "b\r\n", "--- a/input\n+++ b/input\n@@ -1,1 +1,1 @@\n-a\r\n+b\r\n");
    golden("\0\xFF\n", "\x1B\n", "--- a/input\n+++ b/input\n@@ -1,1 +1,1 @@\n-\0\xFF\n+\x1B\n");
    golden("a\nx", "b\nx", "--- a/input\n+++ b/input\n@@ -1,2 +1,2 @@\n-a\n+b\n x\n\\ No newline at end of file\n");
    var out: u8[>..] = [99];
    assert(patch::unified("a", "b", out, diff::Limits { .. }, -1) == diff::Error.InvalidOptions && out.len == 0);
    out.push(99);
    assert(patch::unified("a", "b", out, diff::Limits { .. }, 8388609) == diff::Error.InvalidOptions && out.len == 0);
    out.push(99);
    assert(patch::unified("a", "b", out, diff::Limits { max_work: 0, .. }, 1000) == diff::Error.LimitExceeded && out.len == 0);
    out.push(99);
    assert(patch::unified("a", "b", out, diff::Limits { max_lines: -1, .. }, 1000) == diff::Error.InvalidOptions && out.len == 0);
    print("unified: exact output, budgets, byte semantics and stale errors passed");
}
