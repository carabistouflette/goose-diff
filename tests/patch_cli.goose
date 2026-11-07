// SPDX-License-Identifier: Apache-2.0
import diff from "..";
import diff.unified;
import std;
import os;
fn main() {
    let argv = args(); assert(argv.len == 3);
    var out: u8[>..] = [];
    assert(patch::unified(argv[1], argv[2], out, diff::Limits { .. }, patch::MAX_OUTPUT_BYTES) == diff::Error.None);
    write_stdout(out); flush_stdout();
}
