GOOSE ?= .toolchain/goose/build/goose
SOURCES = diff.goose unified.goose tests examples bench
.PHONY: setup format check test test-debug test-gcc test-clang sanitize bench
setup:
	./scripts/setup-goose.sh
format:
	"$(GOOSE)" format $(SOURCES)
check:
	python3 -m unittest discover -s tests -p 'test_*.py'
	"$(GOOSE)" format --check $(SOURCES)
	"$(GOOSE)" check tests/core.goose
	"$(GOOSE)" check tests/unified.goose
	"$(GOOSE)" check tests/context.goose
	"$(GOOSE)" check examples/compare.goose
	"$(GOOSE)" check bench/bench.goose
	"$(GOOSE)" check tests/patch_cli.goose
test:
	"$(GOOSE)" run tests/core.goose
	"$(GOOSE)" run tests/unified.goose
	"$(GOOSE)" run tests/context.goose
	"$(GOOSE)" run examples/compare.goose
test-debug:
	"$(GOOSE)" run tests/core.goose --debug
	"$(GOOSE)" run tests/unified.goose --debug
	"$(GOOSE)" run tests/context.goose --debug
test-gcc test-clang:
	mkdir -p .build
	"$(GOOSE)" build tests/core.goose --cc $(patsubst test-%,%,$@) --debug -o .build/core-$@
	.build/core-$@
	"$(GOOSE)" build tests/unified.goose --cc $(patsubst test-%,%,$@) --debug -o .build/unified-$@
	.build/unified-$@
	"$(GOOSE)" build tests/context.goose --cc $(patsubst test-%,%,$@) --debug -o .build/context-$@
	.build/context-$@
sanitize:
	mkdir -p .build
	"$(GOOSE)" build tests/core.goose --cc ./scripts/sanitizer-cc.sh --debug -o .build/core-sanitize
	ASAN_OPTIONS=detect_leaks=1 UBSAN_OPTIONS=halt_on_error=1 .build/core-sanitize
	"$(GOOSE)" build tests/unified.goose --cc ./scripts/sanitizer-cc.sh --debug -o .build/unified-sanitize
	ASAN_OPTIONS=detect_leaks=1 UBSAN_OPTIONS=halt_on_error=1 .build/unified-sanitize
	"$(GOOSE)" build tests/context.goose --cc ./scripts/sanitizer-cc.sh --debug -o .build/context-sanitize
	ASAN_OPTIONS=detect_leaks=1 UBSAN_OPTIONS=halt_on_error=1 .build/context-sanitize
bench:
	mkdir -p .build
	"$(GOOSE)" build bench/bench.goose --cc gcc -O2 -o .build/bench
	./.build/bench 100

.PHONY: test-patch
test-patch:
	mkdir -p .build
	"$(GOOSE)" build tests/patch_cli.goose --cc gcc --debug -o .build/patch-cli
	python3 tests/patch_roundtrip.py .build/patch-cli
