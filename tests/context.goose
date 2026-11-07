// SPDX-License-Identifier: Apache-2.0
import diff from "..";
import diff.unified;
import std;

fn golden(a: const u8[:], b: const u8[:], context: i64, expected: const u8[:]) {
    var out: u8[>..] = [99];
    assert(patch::unified_context(a, b, out, diff::Limits { .. }, expected.len, context) == diff::Error.None);
    assert(out == expected);
    if expected.len > 0 {
        assert(patch::unified_context(a, b, out, diff::Limits { .. }, expected.len - 1, context) == diff::Error.LimitExceeded);
        assert(out.len == 0);
    }
}
fn main() {
    golden("", "", 0, "");
    golden("same\n", "same\n", 3, "");
    golden("a\nb\nc\n", "a\nB\nc\n", 0,
           "--- a/input\n+++ b/input\n@@ -2,1 +2,1 @@\n-b\n+B\n");
    golden("a\nb\nc\n", "a\nB\nc\n", 1,
           "--- a/input\n+++ b/input\n@@ -1,3 +1,3 @@\n a\n-b\n+B\n c\n");
    // An equal gap of three lines splits context=1 into two windows.
    golden("a\nb\nc\nd\ne\nf\ng\n", "a\nB\nc\nd\ne\nF\ng\n", 1,
           "--- a/input\n+++ b/input\n@@ -1,3 +1,3 @@\n a\n-b\n+B\n c\n@@ -5,3 +5,3 @@\n e\n-f\n+F\n g\n");
    // Exactly twice the context touches; overlap and touching both merge.
    golden("a\nb\nc\nd\ne\nf\n", "a\nB\nc\nd\nE\nf\n", 1,
           "--- a/input\n+++ b/input\n@@ -1,6 +1,6 @@\n a\n-b\n+B\n c\n d\n-e\n+E\n f\n");
    golden("a\nb\nc\nd\ne\n", "a\nB\nc\nD\ne\n", 1,
           "--- a/input\n+++ b/input\n@@ -1,5 +1,5 @@\n a\n-b\n+B\n c\n-d\n+D\n e\n");
    golden("a\nb\nc\nd\ne\nf\ng\nh\ni\n", "a\nb\nc\nd\nE\nf\ng\nh\ni\n", 3,
           "--- a/input\n+++ b/input\n@@ -2,7 +2,7 @@\n b\n c\n d\n-e\n+E\n f\n g\n h\n");
    // Zero-count ranges name the preceding line, not the following one.
    golden("", "x\n", 0, "--- a/input\n+++ b/input\n@@ -0,0 +1,1 @@\n+x\n");
    golden("x\n", "", 0, "--- a/input\n+++ b/input\n@@ -1,1 +0,0 @@\n-x\n");
    golden("a\nb\n", "x\na\nb\n", 0, "--- a/input\n+++ b/input\n@@ -0,0 +1,1 @@\n+x\n");
    golden("a\nb\n", "a\nx\nb\n", 0, "--- a/input\n+++ b/input\n@@ -1,0 +2,1 @@\n+x\n");
    golden("a\nb\n", "a\nb\nx\n", 0, "--- a/input\n+++ b/input\n@@ -2,0 +3,1 @@\n+x\n");
    golden("x\na\nb\n", "a\nb\n", 0, "--- a/input\n+++ b/input\n@@ -1,1 +0,0 @@\n-x\n");
    golden("a\nx\nb\n", "a\nb\n", 0, "--- a/input\n+++ b/input\n@@ -2,1 +1,0 @@\n-x\n");
    golden("a\nb\nx\n", "a\nb\n", 0, "--- a/input\n+++ b/input\n@@ -3,1 +2,0 @@\n-x\n");
    // Missing LF is metadata only for lines retained in the hunk.
    golden("a\nx", "b\nx", 0, "--- a/input\n+++ b/input\n@@ -1,1 +1,1 @@\n-a\n+b\n");
    golden("a\nx", "b\nx", 1, "--- a/input\n+++ b/input\n@@ -1,2 +1,2 @@\n-a\n+b\n x\n\\ No newline at end of file\n");
    golden("a\nx", "a\nx\n", 0, "--- a/input\n+++ b/input\n@@ -2,1 +2,1 @@\n-x\n\\ No newline at end of file\n+x\n");
    golden("a\nx\n", "a\nx", 0, "--- a/input\n+++ b/input\n@@ -2,1 +2,1 @@\n-x\n+x\n\\ No newline at end of file\n");
    golden("a\n\0\xFF\r\nx", "a\n\x1B\r\nx", 0,
           "--- a/input\n+++ b/input\n@@ -2,1 +2,1 @@\n-\0\xFF\r\n+\x1B\r\n");
    var out: u8[>..] = [99];
    for context in [-1, diff::MAX_LINES + 1, 9223372036854775807] {
        assert(patch::unified_context("", "", out, diff::Limits { .. }, 0, context) == diff::Error.InvalidOptions);
        assert(out.len == 0); out.push(99);
    }
    assert(patch::unified_context("a", "b", out, diff::Limits { .. }, -1, 3) == diff::Error.InvalidOptions && out.len == 0);
    out.push(99);
    assert(patch::unified_context("a", "b", out, diff::Limits { .. }, patch::MAX_OUTPUT_BYTES + 1, 3) == diff::Error.InvalidOptions && out.len == 0);
    out.push(99);
    assert(patch::unified_context("same\na\n", "same\nb\n", out, diff::Limits { max_cells: 0, .. }, 1000, 1) == diff::Error.LimitExceeded && out.len == 0);
    // Maximum context is an exact compatibility oracle for full-file output.
    var legacy: u8[>..] = [];
    assert(patch::unified("a\nb\nc\nd\ne\nf\ng\n", "a\nB\nc\nd\ne\nF\ng\n", legacy, diff::Limits { .. }, 1000) == diff::Error.None);
    assert(patch::unified_context("a\nb\nc\nd\ne\nf\ng\n", "a\nB\nc\nd\ne\nF\ng\n", out, diff::Limits { .. }, 1000, diff::MAX_LINES) == diff::Error.None);
    assert(out == legacy);
    var old: u8[>..] = []; var fresh: u8[>..] = [];
    for i in 1000 { old.append("same\n"); fresh.append("same\n"); }
    old.append("old\n"); fresh.append("new\n");
    for i in 1000 { old.append("same\n"); fresh.append("same\n"); }
    assert(patch::unified(old, fresh, out, diff::Limits { .. }, 128) == diff::Error.LimitExceeded && out.len == 0);
    assert(patch::unified_context(old, fresh, out, diff::Limits { .. }, 128, 3) == diff::Error.None);
    assert(out.len > 0 && out.len <= 128);
    print("context: goldens, hunk windows, zero ranges, byte semantics and budgets passed");
}
