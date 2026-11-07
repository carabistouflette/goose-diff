#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Check imports and the supported API from a fresh external consumer directory."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("compiler", type=Path)
    parser.add_argument("--import-source", help="Published Goose import; defaults to this checkout")
    parser.add_argument("--expected-revision", help="Require this resolved public package commit")
    args = parser.parse_args()
    if args.expected_revision and not args.import_source:
        parser.error("--expected-revision requires --import-source")
    compiler = args.compiler.resolve(strict=True)
    root = Path(__file__).resolve().parent.parent
    source = args.import_source or str(root)
    program = (root / "tests/consumer.goose").read_text()
    program = program.replace('import diff from "..";', f"import diff from {json.dumps(source)};", 1)
    with tempfile.TemporaryDirectory(prefix="goose-diff-consumer-") as directory:
        work = Path(directory)
        (work / "main.goose").write_text(program)
        env = dict(os.environ, GOOSE_HOME=str(work / "cache"))
        for mode in (["check"], ["run"], ["run", "--debug"]):
            subprocess.run([str(compiler), mode[0], "main.goose", *mode[1:]], cwd=work, env=env, check=True)
        if args.import_source:
            packages = list((work / "cache/pkg").rglob(".git"))
            if len(packages) != 1:
                raise RuntimeError(f"Expected one resolved package, found {len(packages)}")
            revision = subprocess.check_output(["git", "-C", str(packages[0].parent), "rev-parse", "HEAD"], text=True).strip()
            if args.expected_revision and revision != args.expected_revision:
                raise RuntimeError(f"Resolved {revision}, expected {args.expected_revision}")
            print(f"Resolved public package: {revision}", flush=True)
        for cc in ("gcc", "clang"):
            executable = work / f"consumer-{cc}"
            subprocess.run([str(compiler), "build", "main.goose", "--cc", cc, "--debug", "-o", str(executable)],
                           cwd=work, env=env, check=True)
            subprocess.run([str(executable)], cwd=work, env=env, check=True)
    print(f"External consumer passed: {source}", flush=True)


if __name__ == "__main__":
    main()
