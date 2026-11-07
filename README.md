# goose-diff

Bounded, byte-exact line comparison for Goose. Experimental, Apache-2.0, pure
Goose with no runtime dependency beyond stdlib. Returns minimal insertion/deletion
edits with deterministic ordering and explicit resource limits. Optional unified
rendering produces bounded raw patch bytes.

## Quickstart

From a standalone checkout, install Git, Make, CMake 3.27+, Python 3.11+ and a
C/C++20 toolchain, then:

```sh
make setup
.toolchain/goose/build/goose run examples/compare.goose
make check test test-debug test-gcc test-clang test-patch sanitize
```

Setup fetches the full compiler revision in GOOSE_REVISION. With a compatible
existing compiler pass `GOOSE=/absolute/path/to/goose` to Make. GCC and Clang
are needed for their respective validation targets; sanitizers default to Clang.
Local validation targets Linux x86-64/glibc. Other platforms remain unqualified.

```goose
import diff from "./goose-diff";
import std;
fn main() {
    var edits: diff::Edit[>..] = [];
    let error = diff::compare("old\n", "new\n", edits, diff::Limits { .. });
    if error == diff::Error.None { print("edit runs: ", edits.len); }
}
```

The import assumes a neighboring local checkout. No public URL or release is
claimed yet. `goose-check` is the proposed first consumer; integration has not
been performed. The library performs no filesystem, process or terminal I/O.

[API and limits](docs/API.md) · [validation](docs/VALIDATION.md) ·
[benchmarks](bench/README.md) · [contributing](CONTRIBUTING.md) ·
[security](SECURITY.md)
