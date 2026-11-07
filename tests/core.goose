// SPDX-License-Identifier: Apache-2.0
import diff from "..";
import std;

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
fn verify(a: const u8[:], b: const u8[:]) {
    let ae = boundaries(a);
    let be = boundaries(b);
    var edits: diff::Edit[>..] = [];
    assert(diff::compare(a, b, edits, diff::Limits { .. }) == diff::Error.None);
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
    assert(cost == oracle(a, b, ae, be, 0, 0));
    var again: diff::Edit[>..] = [];
    assert(diff::compare(a, b, again, diff::Limits { .. }) == diff::Error.None);
    assert(again.len == edits.len);
    for edit, i in edits {
        assert(edit.kind == again[i].kind && edit.old_start == again[i].old_start &&
               edit.old_end == again[i].old_end && edit.new_start == again[i].new_start &&
               edit.new_end == again[i].new_end);
    }
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
                    verify(a, b);
                }
            }
            right_variants *= 2;
        }
        left_variants *= 2;
    }
}
fn rejected(a: const u8[:], b: const u8[:], limits: diff::Limits, expected: diff::Error) {
    var edits: diff::Edit[>..] = [];
    assert(diff::compare("stale\n", "stale\n", edits, diff::Limits { .. }) == diff::Error.None);
    assert(edits.len > 0);
    assert(diff::compare(a, b, edits, limits) == expected);
    assert(edits.len == 0);
    assert(diff::compare("ok", "ok", edits, diff::Limits { .. }) == diff::Error.None);
    assert(edits.len == 1 && edits[0].kind == diff::Kind.Equal);
}
fn budgets() {
    var limits = diff::Limits { .. };
    limits.max_bytes = -1;
    rejected("", "", limits, diff::Error.InvalidOptions);
    limits = diff::Limits { .. }; limits.max_lines = -1;
    rejected("", "", limits, diff::Error.InvalidOptions);
    limits = diff::Limits { .. }; limits.max_cells = -1;
    rejected("", "", limits, diff::Error.InvalidOptions);
    limits = diff::Limits { .. }; limits.max_work = -1;
    rejected("", "", limits, diff::Error.InvalidOptions);
    limits = diff::Limits { .. }; limits.max_bytes = 1048577;
    rejected("", "", limits, diff::Error.InvalidOptions);
    limits = diff::Limits { .. }; limits.max_lines = 16385;
    rejected("", "", limits, diff::Error.InvalidOptions);
    limits = diff::Limits { .. }; limits.max_cells = 4194305;
    rejected("", "", limits, diff::Error.InvalidOptions);
    limits = diff::Limits { .. }; limits.max_work = 67108865;
    rejected("", "", limits, diff::Error.InvalidOptions);
    limits = diff::Limits { .. }; limits.max_bytes = 1;
    rejected("aa", "", limits, diff::Error.LimitExceeded);
    rejected("", "aa", limits, diff::Error.LimitExceeded);
    limits = diff::Limits { .. }; limits.max_lines = 1;
    rejected("a\nb\n", "", limits, diff::Error.LimitExceeded);
    rejected("", "a\nb\n", limits, diff::Error.LimitExceeded);
    limits = diff::Limits { .. }; limits.max_lines = 0;
    rejected("\n", "", limits, diff::Error.LimitExceeded);
    limits = diff::Limits { .. }; limits.max_cells = 0;
    rejected("a\n", "b\n", limits, diff::Error.LimitExceeded);
    limits = diff::Limits { .. }; limits.max_work = 0;
    rejected("a\n", "b\n", limits, diff::Error.LimitExceeded);

    // Discover exact minimum accepted budgets, then exercise one-below. This
    // avoids coupling tests to a private work-accounting implementation.
    var minimum_cells = -1;
    var edits: diff::Edit[>..] = [];
    for cap in 32 {
        limits = diff::Limits { .. }; limits.max_cells = cap;
        let error = diff::compare("a\nb\n", "b\na\n", edits, limits);
        if error == diff::Error.None { minimum_cells = cap; break; }
        assert(error == diff::Error.LimitExceeded && edits.len == 0);
    }
    assert(minimum_cells > 0);
    limits = diff::Limits { .. }; limits.max_cells = minimum_cells - 1;
    rejected("a\nb\n", "b\na\n", limits, diff::Error.LimitExceeded);
    var minimum_work = -1;
    for cap in 256 {
        limits = diff::Limits { .. }; limits.max_work = cap;
        let error = diff::compare("a\nb\n", "b\na\n", edits, limits);
        if error == diff::Error.None { minimum_work = cap; break; }
        assert(error == diff::Error.LimitExceeded && edits.len == 0);
    }
    assert(minimum_work > 0);
    limits = diff::Limits { .. }; limits.max_work = minimum_work - 1;
    rejected("a\nb\n", "b\na\n", limits, diff::Error.LimitExceeded);
    limits = diff::Limits { max_bytes: 0, max_lines: 0, max_cells: 0, max_work: 0 };
    assert(diff::compare("", "", edits, limits) == diff::Error.None && edits.len == 0);
    limits = diff::Limits { .. }; limits.max_bytes = 2; limits.max_lines = 1;
    assert(diff::compare("a\n", "a\n", edits, limits) == diff::Error.None);
}
fn hard_boundaries() {
    var bytes: u8[>..] = [];
    for i in 1048576 { bytes.push('a'); }
    var edits: diff::Edit[>..] = [];
    assert(diff::compare(bytes, bytes, edits, diff::Limits { .. }) == diff::Error.None);
    assert(edits.len == 1 && edits[0].kind == diff::Kind.Equal && edits[0].old_end == 1);
    var limits = diff::Limits { .. }; limits.max_work = 1048575;
    rejected(bytes, bytes, limits, diff::Error.LimitExceeded);
    limits.max_work = 1048576;
    assert(diff::compare(bytes, bytes, edits, limits) == diff::Error.None);
    bytes.push('b');
    rejected(bytes, "", diff::Limits { .. }, diff::Error.LimitExceeded);
    rejected("", bytes, diff::Limits { .. }, diff::Error.LimitExceeded);
    bytes.clear();
    for i in 16384 { bytes.push('\n'); }
    assert(diff::compare(bytes, bytes, edits, diff::Limits { .. }) == diff::Error.None);
    assert(edits.len == 1 && edits[0].old_end == 16384);
    bytes.push('\n');
    rejected(bytes, "", diff::Limits { .. }, diff::Error.LimitExceeded);
    rejected("", bytes, diff::Limits { .. }, diff::Error.LimitExceeded);
    // Long equal-prefix lines with mismatching last bytes consume real byte
    // comparisons even when the unresolved DP rectangle is tiny.
    bytes.clear();
    for i in 4096 { bytes.push('a'); }
    var fresh = copy(bytes);
    bytes.push('b'); fresh.push('c');
    limits = diff::Limits { .. }; limits.max_work = 4096;
    rejected(bytes, fresh, limits, diff::Error.LimitExceeded);
    verify(bytes, fresh);
}
fn main() {
    exhaustive();
    for a in ["", "\n", "\n\n", "x", "x\n", "x\r\n", "\0\xff\n", "a\nb\na\n"] {
        for b in ["", "\n", "\n\n", "x", "x\n", "x\r\n", "\0\xff\n", "a\nb\na\n"] {
            verify(a, b);
        }
    }
    budgets();
    hard_boundaries();
    print("core: exhaustive minimality, reconstruction, byte semantics and limits passed");
}
