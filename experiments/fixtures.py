#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Freeze sparse consumer cases and reproduce alpha.2 omission through the CLI."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--consumer', type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
folder = root / 'experiments/fixtures'
folder.mkdir(exist_ok=True)
transcript = (root / 'bench/results/context-alpha2/compiler_transcript/old.bin').read_bytes()
first = transcript.split(b'compilation unit 1\n', 1)[0].split(b'\n', 1)[1]
old_diag = b''.join(f'compilation unit {i}\n'.encode() + first for i in range(200))
new_diag = b''.join(f'compilation unit {i}\n'.encode() + (first.replace(b'missing_old', b'missing_new') if i in (10, 190) else first) for i in range(200))
lines = [f'field_{i:04d}=unchanged\n'.encode() for i in range(1200)]
def generated(indices):
    fresh = lines.copy()
    for i in indices:
        fresh[i] = fresh[i].replace(b'unchanged', b'updated!!')
    return b''.join(lines), b''.join(fresh)
repeated = b'a\nb\n' * 600
repeat_lines = repeated.splitlines(keepends=True)
repeat_lines[80] = b'x\n'; repeat_lines[1120] = b'y\n'
cases = [('generated_two_far', *generated((80, 1120)), 4, True),
    ('generated_three_far', *generated((80, 600, 1120)), 6, True),
    ('compiler_two_far', old_diag, new_diag, 8, True),
    ('repeated_two_far', repeated, b''.join(repeat_lines), 4, True),
    ('equal', *generated(()), 0, False),
    ('single_middle', *generated((600,)), 2, False),
    ('dense_rewrite', b'a\n' * 600, b'b\n' * 600, 1200, True),
    ('dense_different_lengths', b'a\n' * 700, b'bb\n' * 700, 1400, True)]
consumer = args.consumer.resolve()
manifest = {'consumer': 'goose-check --diff at alpha.2 adoption',
    'consumer_binary_sha256': hashlib.sha256(consumer.read_bytes()).hexdigest(),
    'consumer_source': '9524439d57a8d75457dd8c98ea56ff823aac2e05',
    'bounds': {'max_bytes': 65536, 'max_lines': 4096, 'max_cells': 262144, 'max_work': 1048576, 'max_states': 262144},
    'cases': []}
for name, old, fresh, cost, omitted in cases:
    target = folder / name
    target.mkdir(exist_ok=True)
    a, b = target / 'old.bin', target / 'new.bin'
    a.write_bytes(old); b.write_bytes(fresh)
    run = subprocess.run([str(consumer), '--diff', '--stdout', str(a.resolve()),
        '--stdin', str(b.resolve()), '--output-limit', '1048576', '--', '/bin/cat'], capture_output=True, timeout=15)
    assert run.returncode == (0 if old == fresh else 1), (name, run.stderr)
    assert run.stdout == b''
    assert (b'stdout diff omitted (resource limit)' in run.stderr) == omitted, (name, run.stderr)
    (target / 'baseline-stderr.txt').write_bytes(run.stderr)
    manifest['cases'].append({'name': name, 'old_bytes': len(old), 'new_bytes': len(fresh),
        'old_lines': len(old.splitlines(keepends=True)), 'new_lines': len(fresh.splitlines(keepends=True)),
        'old_sha256': hashlib.sha256(old).hexdigest(), 'new_sha256': hashlib.sha256(fresh).hexdigest(),
        'expected_min_edits': cost, 'baseline_omitted': omitted})
(folder / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print('Frozen 8 consumer fixtures; sparse omissions reproduced with actual goose-check.')
