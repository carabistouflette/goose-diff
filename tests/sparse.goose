// SPDX-License-Identifier: Apache-2.0
import diff from "..";
import diff.sparse;
import diff.unified;
import std;

fn state_limits(limits: sparse::Limits, states: i64) -> sparse::Limits {
    var selected = limits; selected.max_states = states; return selected;
}

// Independent line boundaries and exponential shortest-edit oracle. These do
// not share the implementation's tokenization or dynamic-programming table.
fn boundaries(text: const u8[:]) -> i64[>..] {
    var ends: i64[>..] = [0];
    for byte, at in text {
        if byte == '\n' { ends.push(at + 1); }
    }
    if ends[ends.len - 1] != text.len { ends.push(text.len); }
    ends
}
recursive fn oracle(a: const u8[:], b: const u8[:], ae: const i64[:], be: const i64[:], i: i64, j: i64) -> i64 {
    if i + 1 == ae.len { return be.len - 1 - j; }
    if j + 1 == be.len { return ae.len - 1 - i; }
    if a[ae[i]..ae[i + 1]] == b[be[j]..be[j + 1]] {
        return oracle(a, b, ae, be, i + 1, j + 1);
    }
    let deletion = oracle(a, b, ae, be, i + 1, j);
    let insertion = oracle(a, b, ae, be, i, j + 1);
    return 1 + (if deletion < insertion { deletion } else { insertion });
}
fn verify(a: const u8[:], b: const u8[:], independent: bool) -> i64 {
    let ae = boundaries(a);
    let be = boundaries(b);
    var edits: diff::Edit[>..] = [];
    assert(sparse::compare(a, b, edits, state_limits(sparse::Limits { .. }, 4194304)) == diff::Error.None);
    var old_at = 0;
    var new_at = 0;
    var cost = 0;
    var rebuilt: u8[>..] = [];
    for edit, at in edits {
        assert(edit.old_start == old_at && edit.new_start == new_at);
        assert(edit.old_end >= old_at && edit.old_end < ae.len);
        assert(edit.new_end >= new_at && edit.new_end < be.len);
        if at > 0 { assert(edit.kind != edits[at - 1].kind); }
        if edit.kind == diff::Kind.Equal {
            assert(edit.old_end > old_at && edit.old_end - old_at == edit.new_end - new_at);
            for offset in edit.old_end - old_at {
                assert(a[ae[old_at + offset]..ae[old_at + offset + 1]] ==
                       b[be[new_at + offset]..be[new_at + offset + 1]]);
            }
            rebuilt.append(a[ae[old_at]..ae[edit.old_end]]);
        } else if edit.kind == diff::Kind.Delete {
            assert(edit.old_end > old_at && edit.new_end == new_at);
            cost += edit.old_end - old_at;
        } else {
            assert(edit.kind == diff::Kind.Insert);
            assert(edit.old_end == old_at && edit.new_end > new_at);
            cost += edit.new_end - new_at;
            rebuilt.append(b[be[new_at]..be[edit.new_end]]);
        }
        old_at = edit.old_end;
        new_at = edit.new_end;
    }
    assert(old_at == ae.len - 1 && new_at == be.len - 1);
    assert(rebuilt == b);
    if independent { assert(cost == oracle(a, b, ae, be, 0, 0)); }
    else {
        var lcs: diff::Edit[>..] = [];
        assert(diff::compare(a, b, lcs, diff::Limits { .. }) == diff::Error.None);
        var lcs_cost = 0;
        for edit in lcs {
            if edit.kind == diff::Kind.Delete { lcs_cost += edit.old_end - edit.old_start; }
            if edit.kind == diff::Kind.Insert { lcs_cost += edit.new_end - edit.new_start; }
        }
        assert(cost == lcs_cost);
    }
    var again: diff::Edit[>..] = [];
    assert(sparse::compare(a, b, again, state_limits(sparse::Limits { .. }, 4194304)) == diff::Error.None);
    assert(again.len == edits.len);
    for edit, i in edits {
        assert(edit.kind == again[i].kind && edit.old_start == again[i].old_start &&
               edit.old_end == again[i].old_end && edit.new_start == again[i].new_start &&
               edit.new_end == again[i].new_end);
    }
    return cost;
}
fn sequence(code: i64, count: i64) -> u8[>..] {
    var bytes: u8[>..] = [];
    var bits = code;
    for i in count {
        bytes.push(if bits % 2 == 0 { 'a' } else { 'b' });
        bytes.push('\n');
        bits /= 2;
    }
    bytes
}
fn exhaustive() {
    var left_variants = 1;
    for left_count in 5 {
        var right_variants = 1;
        for right_count in 5 {
            for left in left_variants {
                let a = sequence(left, left_count);
                for right in right_variants {
                    let b = sequence(right, right_count);
                    verify(a, b, true);
                }
            }
            right_variants *= 2;
        }
        left_variants *= 2;
    }
}
fn rejected(a: const u8[:], b: const u8[:], limits: sparse::Limits, states: i64, expected: diff::Error) {
    var edits: diff::Edit[>..] = [];
    assert(sparse::compare("stale\n", "stale\n", edits, state_limits(sparse::Limits { .. }, 4194304)) == diff::Error.None);
    assert(edits.len > 0);
    assert(sparse::compare(a, b, edits, state_limits(limits, states)) == expected);
    assert(edits.len == 0);
    assert(sparse::compare("ok", "ok", edits, state_limits(sparse::Limits { .. }, 0)) == diff::Error.None);
    assert(edits.len == 1 && edits[0].kind == diff::Kind.Equal);
}
fn budgets() {
    for states in [-1, 4194305] { rejected("", "", sparse::Limits { .. }, states, diff::Error.InvalidOptions); }
    rejected("", "", sparse::Limits { max_bytes: -1, .. }, 0, diff::Error.InvalidOptions);
    rejected("", "", sparse::Limits { max_lines: -1, .. }, 0, diff::Error.InvalidOptions);
    rejected("", "", sparse::Limits { max_work: -1, .. }, 0, diff::Error.InvalidOptions);
    rejected("", "", sparse::Limits { max_bytes: 1048577, .. }, 0, diff::Error.InvalidOptions);
    rejected("", "", sparse::Limits { max_lines: 16385, .. }, 0, diff::Error.InvalidOptions);
    rejected("", "", sparse::Limits { max_work: 67108865, .. }, 0, diff::Error.InvalidOptions);
    rejected("aa", "", sparse::Limits { max_bytes: 1, .. }, 4194304, diff::Error.LimitExceeded);
    rejected("", "aa", sparse::Limits { max_bytes: 1, .. }, 4194304, diff::Error.LimitExceeded);
    rejected("a\nb\n", "", sparse::Limits { max_lines: 1, .. }, 4194304, diff::Error.LimitExceeded);
    rejected("", "a\nb\n", sparse::Limits { max_lines: 1, .. }, 4194304, diff::Error.LimitExceeded);
    rejected("\n", "", sparse::Limits { max_lines: 0, .. }, 4194304, diff::Error.LimitExceeded);
    rejected("a\n", "b\n", sparse::Limits { .. }, 0, diff::Error.LimitExceeded);
    rejected("same\na\n", "same\nb\n", sparse::Limits { .. }, 0, diff::Error.LimitExceeded);
    rejected("a\n", "b\n", sparse::Limits { max_work: 0, .. }, 4194304, diff::Error.LimitExceeded);
    var edits: diff::Edit[>..] = [];
    assert(sparse::compare("", "a\n", edits, state_limits(sparse::Limits { max_work: 0, .. }, 0)) == diff::Error.None);
    assert(sparse::compare("a\n", "", edits, state_limits(sparse::Limits { max_work: 0, .. }, 0)) == diff::Error.None);
    assert(sparse::compare("", "", edits, state_limits(sparse::Limits { max_bytes: 0, max_lines: 0, max_work: 0 }, 0)) == diff::Error.None);
    // The shortest script for a replacement has distance two. Whole-layer
    // admission stores 1+2+3 slots, including unreachable frontier positions.
    assert(sparse::compare("a\n", "b\n", edits, state_limits(sparse::Limits { .. }, 6)) == diff::Error.None);
    rejected("a\n", "b\n", sparse::Limits { .. }, 5, diff::Error.LimitExceeded);
    // Discover the exact byte-comparison requirement independently of traversal.
    var minimum = -1;
    for cap in 512 {
        let error = sparse::compare("a\nb\n", "b\na\n", edits, state_limits(sparse::Limits { max_work: cap, .. }, 4194304));
        if error == diff::Error.None { minimum = cap; break; }
        assert(error == diff::Error.LimitExceeded && edits.len == 0);
    }
    assert(minimum > 0);
    rejected("a\nb\n", "b\na\n", sparse::Limits { max_work: minimum - 1, .. }, 4194304, diff::Error.LimitExceeded);
    assert(sparse::compare("a\nb\n", "b\na\n", edits, state_limits(sparse::Limits { max_work: minimum, .. }, 4194304)) == diff::Error.None);
}
fn randomized() {
    var seed: i64 = 173;
    for sample in 1000 {
        seed = (seed * 48271) % 2147483647; let left_count = seed % 33;
        seed = (seed * 48271) % 2147483647; let right_count = seed % 33;
        var a: u8[>..] = []; var b: u8[>..] = [];
        for i in left_count {
            seed = (seed * 48271) % 2147483647;
            a.append(if seed % 4 == 0 { "\0\xff\n" } else if seed % 4 == 1 { "a\n" } else if seed % 4 == 2 { "b\r\n" } else { "c\n" });
        }
        for i in right_count {
            seed = (seed * 48271) % 2147483647;
            b.append(if seed % 4 == 0 { "\0\xff\n" } else if seed % 4 == 1 { "a\n" } else if seed % 4 == 2 { "b\r\n" } else { "c\n" });
        }
        verify(a, b, false);
    }
}
fn hard_boundaries() {
    var bytes: u8[>..] = [];
    for i in 1048576 { bytes.push('a'); }
    var edits: diff::Edit[>..] = [];
    assert(sparse::compare(bytes, bytes, edits, state_limits(sparse::Limits { max_work: 1048576, .. }, 0)) == diff::Error.None);
    rejected(bytes, bytes, sparse::Limits { max_work: 1048575, .. }, 4194304, diff::Error.LimitExceeded);
    bytes.push('b');
    rejected(bytes, "", sparse::Limits { .. }, 4194304, diff::Error.LimitExceeded);
    rejected("", bytes, sparse::Limits { .. }, 4194304, diff::Error.LimitExceeded);
    bytes.clear();
    for i in 16384 { bytes.push('\n'); }
    assert(sparse::compare(bytes, bytes, edits, state_limits(sparse::Limits { .. }, 0)) == diff::Error.None);
    bytes.push('\n');
    rejected(bytes, "", sparse::Limits { .. }, 4194304, diff::Error.LimitExceeded);
    rejected("", bytes, sparse::Limits { .. }, 4194304, diff::Error.LimitExceeded);
    bytes.clear();
    for i in 4096 { bytes.push('a'); }
    var changed = copy(bytes); bytes.push('b'); changed.push('c');
    rejected(bytes, changed, sparse::Limits { max_work: 4096, .. }, 4194304, diff::Error.LimitExceeded);
    verify(bytes, changed, true);
    // Trace storage, rather than byte work, terminates a high-distance rewrite.
    var a: u8[>..] = []; var b: u8[>..] = [];
    for i in 3000 { a.append("a\n"); b.append("b\n"); }
    rejected(a, b, sparse::Limits { max_work: 67108864, .. }, 4194304, diff::Error.LimitExceeded);
    // Unequal line lengths cost no compared bytes. Only the state cap can
    // terminate this high-distance search; max_work remains exactly zero.
    b.clear();
    for i in 3000 { b.append("bb\n"); }
    rejected(a, b, sparse::Limits { max_work: 0, .. }, 64, diff::Error.LimitExceeded);
}
fn sparse_case() {
    var a: u8[>..] = []; var b: u8[>..] = [];
    for i in 1200 {
        a.append(str("line ", i, "\n"));
        b.append(if i == 100 || i == 1100 { str("changed ", i, "\n") } else { str("line ", i, "\n") });
    }
    var edits: diff::Edit[>..] = [];
    let limits = sparse::Limits { max_bytes: 65536, max_lines: 4096, max_work: 1048576 };
    assert(diff::compare(a, b, edits, diff::Limits { max_bytes: 65536, max_lines: 4096, max_cells: 262144, max_work: 1048576 }) == diff::Error.LimitExceeded && edits.len == 0);
    assert(sparse::compare(a, b, edits, state_limits(limits, 262144)) == diff::Error.None);
    let ae = boundaries(a); let be = boundaries(b);
    var old_at = 0; var new_at = 0; var cost = 0; var rebuilt: u8[>..] = [];
    for edit in edits {
        assert(edit.old_start == old_at && edit.new_start == new_at);
        if edit.kind == diff::Kind.Equal {
            assert(a[ae[old_at]..ae[edit.old_end]] == b[be[new_at]..be[edit.new_end]]);
            rebuilt.append(a[ae[old_at]..ae[edit.old_end]]);
        } else if edit.kind == diff::Kind.Delete { cost += edit.old_end - old_at; }
        else { cost += edit.new_end - new_at; rebuilt.append(b[be[new_at]..be[edit.new_end]]); }
        old_at = edit.old_end; new_at = edit.new_end;
    }
    assert(old_at == 1200 && new_at == 1200 && cost == 4 && rebuilt == b);
    assert(sparse::compare(a, b, edits, state_limits(limits, 15)) == diff::Error.None);
    rejected(a, b, limits, 14, diff::Error.LimitExceeded);
}
// A deterministic minimal script need not match LCS's documented tie behavior.
fn tie_counterexample() {
    var lcs: diff::Edit[>..] = []; var candidate: diff::Edit[>..] = [];
    assert(diff::compare("a\nb\n", "b\na\n", lcs, diff::Limits { .. }) == diff::Error.None);
    assert(sparse::compare("a\nb\n", "b\na\n", candidate, state_limits(sparse::Limits { .. }, 4194304)) == diff::Error.None);
    assert(lcs.len == 3 && candidate.len == 3);
    assert(lcs[0].kind == diff::Kind.Delete && lcs[1].kind == diff::Kind.Equal && lcs[2].kind == diff::Kind.Insert);
    assert(candidate[0].kind == diff::Kind.Insert && candidate[1].kind == diff::Kind.Equal && candidate[2].kind == diff::Kind.Delete);
    assert(verify("a\nb\n", "b\na\n", true) == 2);
}
fn main() {
    exhaustive(); tie_counterexample();
    for a in ["", "\n", "\n\n", "x", "x\n", "x\r\n", "\0\xff\n", "a\nb\na\n"] {
        for b in ["", "\n", "\n\n", "x", "x\n", "x\r\n", "\0\xff\n", "a\nb\na\n"] { verify(a, b, true); }
    }
    for a in ["a\nb\nc\nd\ne\n", "a\na\na\na\n", "\0\n"] {
        for b in ["x\n", "a\nb\nx\nc\nd\ne\n", "a\na\na\na\na\na\n", ""] { verify(a, b, false); }
    }
    randomized(); budgets(); hard_boundaries(); sparse_case(); patches();
    print("sparse: independent minimality, reconstruction, deterministic paths, budgets and sparse consumer case passed");
}
fn patch_golden(a: const u8[:], b: const u8[:], context: i64, expected: const u8[:]) {
    var out: u8[>..] = [99];
    assert(patch::unified_sparse_context(a, b, out, sparse::Limits { .. }, expected.len, context) == diff::Error.None);
    assert(out == expected);
    if expected.len > 0 {
        assert(patch::unified_sparse_context(a, b, out, sparse::Limits { .. }, expected.len - 1, context) == diff::Error.LimitExceeded);
        assert(out.len == 0);
    }
}
fn patches() {
    patch_golden("", "", 0, "");
    patch_golden("same\n", "same\n", 3, "");
    patch_golden("a\n", "b\n", 0, "--- a/input\n+++ b/input\n@@ -1,1 +1,1 @@\n+b\n-a\n");
    patch_golden("a\nb\n", "b\na\n", 1, "--- a/input\n+++ b/input\n@@ -1,2 +1,2 @@\n+b\n a\n-b\n");
    patch_golden("a\nb\n", "b\na\n", 0, "--- a/input\n+++ b/input\n@@ -0,0 +1,1 @@\n+b\n@@ -2,1 +2,0 @@\n-b\n");
    patch_golden("a\nx\nz\n", "a\ny\nz\n", 0, "--- a/input\n+++ b/input\n@@ -2,1 +2,1 @@\n+y\n-x\n");
    patch_golden("x", "y", 3, "--- a/input\n+++ b/input\n@@ -1,1 +1,1 @@\n+y\n\\ No newline at end of file\n-x\n\\ No newline at end of file\n");
    patch_golden("a\r\n", "b\r\n", 3, "--- a/input\n+++ b/input\n@@ -1,1 +1,1 @@\n+b\r\n-a\r\n");
    patch_golden("\0\xff\n", "\x1b\n", 3, "--- a/input\n+++ b/input\n@@ -1,1 +1,1 @@\n+\x1b\n-\0\xff\n");
    var out: u8[>..] = [99];
    for context in [-1, 16385] {
        assert(patch::unified_sparse_context("", "", out, sparse::Limits { .. }, 1000, context) == diff::Error.InvalidOptions && out.len == 0);
        out.push(99);
    }
    for cap in [-1, 8388609] {
        assert(patch::unified_sparse_context("", "", out, sparse::Limits { .. }, cap, 0) == diff::Error.InvalidOptions && out.len == 0);
        out.push(99);
    }
    assert(patch::unified_sparse_context("same\na\n", "same\nb\n", out, sparse::Limits { max_states: 0, .. }, 1000, 0) == diff::Error.LimitExceeded && out.len == 0);
    out.push(99);
    assert(patch::unified_sparse_context("", "", out, sparse::Limits { max_states: -1, .. }, 1000, 0) == diff::Error.InvalidOptions && out.len == 0);
    var edits: diff::Edit[>..] = [];
    assert(sparse::compare("a\n", "b\n", edits, sparse::Limits { .. }) == diff::Error.None);
}
