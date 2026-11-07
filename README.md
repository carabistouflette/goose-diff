# goose-diff

Bounded, byte-exact line comparison for Goose. Apache-2.0, pure
Goose with no runtime dependency beyond stdlib. Returns minimal insertion/deletion
edits with deterministic ordering and explicit resource limits. LCS is the default;
explicit `diff.sparse` supplies a separately bounded sparse strategy. Context and
full-file renderers produce raw patch bytes requiring separate terminal escaping.

v0.1.0 is the first release without an alpha suffix. The supported v0.1.x API
has a [patch-release compatibility policy](docs/RELEASE.md). It remains pre-1.0;
platform qualification is limited to the pinned compiler on Linux x86-64/glibc.

## Quickstart

Install Git, Make, CMake 3.27+, Python 3.11+ and a
C/C++20 toolchain, then:

```sh
git clone --branch v0.1.0 https://github.com/carabistouflette/goose-diff.git
cd goose-diff
make setup
.toolchain/goose/build/goose run examples/compare.goose
.toolchain/goose/build/goose run examples/sparse.goose
make check test test-debug test-gcc test-clang test-patch test-consumer sanitize
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

The import assumes a neighboring local checkout. For a published version use
`import diff from "carabistouflette/goose-diff@v0.1.0";` instead.
`goose-check` adoption is validated separately with an immutable vendored source
pin. The library performs no filesystem, process or terminal I/O.

[API and limits](docs/API.md) · [opt-in sparse strategy](docs/SPARSE.md) · [validation](docs/VALIDATION.md) ·
[benchmarks](bench/README.md) · [contributing](CONTRIBUTING.md) ·
[security](SECURITY.md)
