// SPDX-License-Identifier: Apache-2.0
import std;
import os;
import diff from "..";
fn sample(name: const u8[:], a: const u8[:], b: const u8[:], iterations: i64, expected: diff::Error) -> i64 {
    var edits: diff::Edit[>..] = []; var checksum = 0;
    assert(diff::compare(a, b, edits, diff::Limits { .. }) == expected);
    let start = clock_ns();
    for i in iterations {
        let error = diff::compare(a, b, edits, diff::Limits { .. });
        assert(error == expected); checksum += edits.len + 1;
    }
    print(name, "\t", clock_ns() - start, "\t", iterations, "\t", a.len, "\t", b.len, "\t", checksum);
    return checksum;
}
fn main() {
    let argv = args(); var iterations = 100;
    if argv.len > 1 {
        let n, ok = parse_int(argv[1], 10); assert(ok && n > 0 && n <= 1000000); iterations = n;
    }
    var a: u8[>..] = [];
    for i in 1000 { a.append("same repeated line\n"); }
    var middle = copy(a); middle[middle.len / 2] = 'X';
    var appended = copy(a); appended.append("extra\n");
    var x: u8[>..] = []; var y: u8[>..] = [];
    for i in 200 { x.append("abcdefghij\n"); y.append("abcdefghiZ\n"); }
    var long_a: u8[>..] = []; var long_b: u8[>..] = [];
    for i in 200 {
        for j in 4096 { long_a.push('a'); long_b.push('a'); }
        long_a.append("x\n"); long_b.append("y\n");
    }
    var checksum = sample("equal", a, a, iterations, diff::Error.None);
    checksum += sample("middle_edit", a, middle, iterations, diff::Error.None);
    checksum += sample("append", a, appended, iterations, diff::Error.None);
    checksum += sample("delete", appended, a, iterations, diff::Error.None);
    checksum += sample("different", x, y, iterations, diff::Error.None);
    checksum += sample("long_repeated_limit", long_a, long_b, iterations, diff::Error.LimitExceeded);
    print("checksum\t", checksum);
}
