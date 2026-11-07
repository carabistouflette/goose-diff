// SPDX-License-Identifier: Apache-2.0
import diff from "..";
import std;

fn main() {
    var edits: diff::Edit[>..] = [];
    let error = diff::compare("one\ntwo\n", "one\nthree\n", edits, diff::Limits { .. });
    if error != diff::Error.None { print("comparison failed"); return; }
    // Report metadata only. Raw input and patch bytes may contain terminal
    // controls or secrets; displaying them is an application policy decision.
    for edit in edits {
        print("kind=", edit.kind, " old=", edit.old_start, "..", edit.old_end,
              " new=", edit.new_start, "..", edit.new_end);
    }
}
