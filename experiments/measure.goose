// SPDX-License-Identifier: Apache-2.0
// EXPERIMENT adapter. Trusted fixture file reads are outside timed calls.
import diff from "..";
import diff.experiments.myers;
import diff.unified;
import std;
import os;
fn boundaries(text: const u8[:]) -> i64[>..] {
    var ends: i64[>..] = [0];
    for byte, at in text { if byte == '\n' { ends.push(at + 1); } }
    if ends[ends.len - 1] != text.len { ends.push(text.len); }
    return ends;
}
fn verify(old: const u8[:], fresh: const u8[:], edits: const diff::Edit[:]) -> i64 {
    let a = boundaries(old); let b = boundaries(fresh);
    var x = 0; var y = 0; var cost = 0; var rebuilt: u8[>..] = [];
    for edit, i in edits {
        assert(edit.old_start == x && edit.new_start == y);
        assert(edit.old_end >= x && edit.old_end < a.len && edit.new_end >= y && edit.new_end < b.len);
        if i > 0 { assert(edits[i - 1].kind != edit.kind); }
        if edit.kind == diff::Kind.Equal {
            assert(edit.old_end > x && edit.old_end - x == edit.new_end - y);
            assert(old[a[x]..a[edit.old_end]] == fresh[b[y]..b[edit.new_end]]);
            rebuilt.append(old[a[x]..a[edit.old_end]]);
        } else if edit.kind == diff::Kind.Delete {
            assert(edit.old_end > x && edit.new_end == y); cost += edit.old_end - x;
        } else {
            assert(edit.old_end == x && edit.new_end > y); cost += edit.new_end - y;
            rebuilt.append(fresh[b[y]..b[edit.new_end]]);
        }
        x = edit.old_end; y = edit.new_end;
    }
    assert(x == a.len - 1 && y == b.len - 1 && rebuilt == fresh);
    return cost;
}
fn invoke(backend: const u8[:], old: const u8[:], fresh: const u8[:], out: diff::Edit[>..]&, limits: diff::Limits, max_states: i64) -> diff::Error {
    if backend == "lcs" { return diff::compare(old, fresh, out, limits); }
    return myers::compare(old, fresh, out, limits, max_states);
}
fn main() {
    let argv = args(); assert(argv.len == 6 || argv.len == 7);
    let backend = argv[1]; let profile = argv[2];
    assert(backend == "lcs" || backend == "myers"); assert(profile == "consumer" || profile == "wide");
    let iterations, ok = parse_int(argv[5], 10); assert(ok && iterations > 0 && iterations <= 10000);
    let limits = diff::Limits { max_bytes: 65536, max_lines: 4096,
        max_cells: if profile == "consumer" { 262144 } else { 4194304 },
        max_work: if profile == "consumer" { 1048576 } else { 67108864 } };
    // Matched logical-slot ceilings are experimental controls, not API aliases.
    let max_states = if profile == "consumer" { 262144 } else { 4194304 };
    var old: u8[>..] = []; var fresh: u8[>..] = [];
    assert(read_file(argv[3], old) && read_file(argv[4], fresh));
    var edits: diff::Edit[>..] = [];
    let error = invoke(backend, old, fresh, edits, limits, max_states);
    let cost = if error == diff::Error.None { verify(old, fresh, edits) } else { -1 };
    if error != diff::Error.None { assert(edits.len == 0); }
    if argv.len == 7 {
        assert(argv[6] == "--patch"); if error != diff::Error.None { exit(3); }
        var raw: u8[>..] = [];
        if !patch::render_context(old, fresh, edits, raw, 16384, 3) { raw.clear(); exit(4); }
        write_stdout(raw); flush_stdout(); return;
    }
    let runs = edits.len; var checksum = 0; let start = clock_ns();
    for i in iterations {
        assert(invoke(backend, old, fresh, edits, limits, max_states) == error && edits.len == runs);
        checksum += edits.len + 1;
    }
    print(clock_ns() - start, "\t", error, "\t", cost, "\t", runs, "\t", checksum);
}
