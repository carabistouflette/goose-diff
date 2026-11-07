#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Compare bounded core/full/context calls; retain every sample and fixture."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--binary', type=Path, required=True)
parser.add_argument('--goose', type=Path, required=True)
parser.add_argument('--out', type=Path, required=True)
parser.add_argument('--rounds', type=int, default=5)
parser.add_argument('--iterations', type=int, default=100)
args = parser.parse_args()
if not 1 <= args.rounds <= 100 or not 1 <= args.iterations <= 100000:
    parser.error('invalid rounds or iterations')
root = Path(__file__).resolve().parents[1]
binary, goose = args.binary.resolve(), args.goose.resolve()
def git(*arguments):
    return subprocess.check_output(['git', '-C', str(root), *arguments], text=True).strip()
status = git('status', '--porcelain')
if status:
    raise SystemExit('benchmark requires a clean source tree')
args.out = args.out.resolve()
args.out.mkdir(parents=True, exist_ok=False)
metadata = {'source': git('rev-parse', 'HEAD'), 'status': status,
    'binary_sha256': hashlib.sha256(binary.read_bytes()).hexdigest(),
    'compiler_revision': (root / 'GOOSE_REVISION').read_text().strip(),
    'compiler_binary_sha256': hashlib.sha256(goose.read_bytes()).hexdigest(),
    'gcc': subprocess.check_output(['gcc', '--version'], text=True),
    'platform': platform.platform(), 'flags': 'Goose build --cc gcc -O2',
    'rounds': args.rounds, 'iterations': args.iterations,
    'cpu': next((line.split(':', 1)[1].strip() for line in Path('/proc/cpuinfo').read_text().splitlines() if line.startswith('model name')), ''),
    'scope': 'Shared host. core is direct comparison; full/context include comparison and rendering. Subtraction is not an isolated internal profiler.'}
(args.out / 'provenance.json').write_text(json.dumps(metadata, indent=2) + '\n')
(root / '.build').mkdir(exist_ok=True)
diags = []
for name in ('old', 'new'):
    relative = Path('.build') / f'context-diagnostic-{name}.goose'
    source = f'import std;\nfn main() {{ missing_{name}(); }}\n'.encode()
    (root / relative).write_bytes(source)
    run = subprocess.run([str(goose), 'check', str(relative)], cwd=root, capture_output=True, timeout=15)
    assert run.returncode != 0
    diagnostic = run.stdout + run.stderr
    assert diagnostic
    diags.append(diagnostic)
    (args.out / f'diagnostic-{name}.goose').write_bytes(source)
old_diag = b''.join(f'compilation unit {i}\n'.encode() + diags[0] for i in range(100))
new_diag = b''.join(f'compilation unit {i}\n'.encode() + diags[1 if i == 50 else 0] for i in range(100))
old_generated = b''.join(f'  field_{i:04d} = "unchanged value"\n'.encode() for i in range(1200))
new_generated = old_generated.replace(b'field_0600 = "unchanged value"', b'field_0600 = "updated value"')
old_scatter = b''.join(f'key_{i:04d}=value\n'.encode() for i in range(360))
new_scatter = old_scatter
for i in (40, 160, 300):
    new_scatter = new_scatter.replace(f'key_{i:04d}=value'.encode(), f'key_{i:04d}=other'.encode())
workloads = [('compiler_transcript', old_diag, new_diag),
    ('generated_middle', old_generated, new_generated),
    ('scattered_changes', old_scatter, new_scatter),
    ('dense_rewrite', b'a\n' * 600, b'b\n' * 600),
    ('long_lines', (b'a' * 2997 + b'x\n') * 20, (b'a' * 2997 + b'y\n') * 20)]
with (args.out / 'samples.jsonl').open('w') as output:
    for name, old, fresh in workloads:
        fixture = args.out / name
        fixture.mkdir()
        a, b = fixture / 'old.bin', fixture / 'new.bin'
        a.write_bytes(old); b.write_bytes(fresh)
        for round_number in range(args.rounds):
            modes = ['core', 'full', 'context']
            offset = round_number % len(modes)
            for mode in modes[offset:] + modes[:offset]:
                run = subprocess.run([str(binary), mode, str(a), str(b), str(args.iterations)], check=True, capture_output=True, text=True, timeout=120)
                elapsed, size, error, checksum = run.stdout.strip().split('\t')
                output.write(json.dumps({'workload': name, 'round': round_number, 'mode': mode,
                    'elapsed_ns': int(elapsed), 'output_bytes': int(size), 'error': error,
                    'checksum': int(checksum), 'old_bytes': len(old), 'new_bytes': len(fresh)}) + '\n')
print(f'retained {len(workloads) * args.rounds * 3} samples at {args.out}')
