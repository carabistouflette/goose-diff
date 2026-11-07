// SPDX-License-Identifier: Apache-2.0
import diff from "..";
import diff.unified;
import std;
import os;
fn main() {
    let argv = args(); assert(argv.len == 3 || argv.len == 4);
    var out: u8[>..] = [];
    if argv.len == 3 {
        assert(patch::unified(argv[1], argv[2], out, diff::Limits { .. }, patch::MAX_OUTPUT_BYTES) == diff::Error.None);
    } else {
        let context, ok = parse_int(argv[3], 10); assert(ok);
        assert(patch::unified_context(argv[1], argv[2], out, diff::Limits { .. }, patch::MAX_OUTPUT_BYTES, context) == diff::Error.None);
    }
    write_stdout(out); flush_stdout();
}
