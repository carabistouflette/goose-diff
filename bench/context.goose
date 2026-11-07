// SPDX-License-Identifier: Apache-2.0
import diff from "..";
import diff.unified;
import std;
import os;
fn invoke(mode: const u8[:], old: const u8[:], fresh: const u8[:], edits: diff::Edit[>..]&, out: u8[>..]&) -> diff::Error {
    let limits = diff::Limits { max_bytes: 65536, max_lines: 4096, max_cells: 262144, max_work: 1048576 };
    if mode == "core" { return diff::compare(old, fresh, edits, limits); }
    if mode == "full" { return patch::unified(old, fresh, out, limits, 16384); }
    return patch::unified_context(old, fresh, out, limits, 16384, 3);
}
fn main() {
    let argv = args(); assert(argv.len == 5);
    let mode = argv[1]; assert(mode == "core" || mode == "full" || mode == "context");
    let iterations, ok = parse_int(argv[4], 10); assert(ok && iterations > 0 && iterations <= 100000);
    var old: u8[>..] = []; var fresh: u8[>..] = [];
    assert(read_file(argv[2], old) && read_file(argv[3], fresh));
    var edits: diff::Edit[>..] = []; var out: u8[>..] = [];
    let expected = invoke(mode, old, fresh, edits, out);
    let size = out.len; let runs = edits.len;
    var checksum = 0; let start = clock_ns();
    for i in iterations {
        assert(invoke(mode, old, fresh, edits, out) == expected);
        assert(out.len == size && edits.len == runs); checksum += out.len + edits.len + 1;
    }
    print(clock_ns() - start, "\t", size, "\t", expected, "\t", checksum);
}
