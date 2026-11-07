// SPDX-License-Identifier: Apache-2.0
import diff from "..";
import diff.sparse;
import diff.unified;
import std;
fn main() {
    var old: u8[>..] = []; var fresh: u8[>..] = [];
    for i in 1200 {
        old.append(str("field_", i, "=same\n"));
        fresh.append(str("field_", i, if i == 80 || i == 1120 { "=changed\n" } else { "=same\n" }));
    }
    var edits: diff::Edit[>..] = [];
    let limits = sparse::Limits { max_bytes: 65536, max_lines: 4096, max_states: 262144, max_work: 1048576 };
    assert(sparse::compare(old, fresh, edits, limits) == diff::Error.None);
    var cost = 0;
    for edit in edits {
        if edit.kind == diff::Kind.Delete { cost += edit.old_end - edit.old_start; }
        else if edit.kind == diff::Kind.Insert { cost += edit.new_end - edit.new_start; }
    }
    assert(cost == 4);
    var raw: u8[>..] = [];
    assert(patch::unified_sparse_context(old, fresh, raw, limits, 16384, 3) == diff::Error.None);
    // Raw patch bytes must be escaped before terminal display.
    print("minimal edits=", cost, ", raw patch bytes=", raw.len);
}
