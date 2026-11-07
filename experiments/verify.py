#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Qualify frozen sparse cases, independent LCS costs and no-fuzz patch apply."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--binary', required=True, type=Path)
parser.add_argument('--out', required=True, type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
binary = args.binary.resolve()
fixtures = root / 'experiments/fixtures'
manifest = json.loads((fixtures / 'manifest.json').read_text())
results = []
with tempfile.TemporaryDirectory(prefix='goose-myers-verify-') as temporary:
    target = Path(temporary) / 'input'
    for case in manifest['cases']:
        name = case['name']
        a, b = fixtures / name / 'old.bin', fixtures / name / 'new.bin'
        for profile in ['consumer', 'wide']:
            for backend in ['lcs', 'myers']:
                command = [str(binary), backend, profile, str(a), str(b), '1']
                run = subprocess.run(command, check=True, capture_output=True, text=True, timeout=30)
                elapsed, error, cost, runs, checksum = run.stdout.strip().split('\t')
                cost = int(cost)
                limited = (profile == 'consumer' and
                    (case['baseline_omitted'] if backend == 'lcs' else name.startswith('dense_')))
                assert error == ('Error.LimitExceeded' if limited else 'Error.None'), (name, profile, backend, run.stdout)
                if limited:
                    assert cost == -1
                    rejected = subprocess.run([*command, '--patch'], capture_output=True, timeout=15)
                    assert rejected.returncode == 3 and rejected.stdout == b''
                else:
                    assert cost == case['expected_min_edits'], (name, profile, backend, cost)
                    patch = subprocess.run([*command, '--patch'], check=True, capture_output=True, timeout=30).stdout
                    assert len(patch) <= 16384
                    # Verify that the current consumer's escaping policy fits too.
                    escaped = sum(1 if c == 10 or 32 <= c <= 126 and c != 92 else 4 for c in patch)
                    assert escaped + 80 <= 16384, (name, escaped)
                    if patch:
                        target.write_bytes(a.read_bytes())
                        applied = subprocess.run(['patch', '--batch', '--silent', '--binary', '--forward', '--fuzz=0', str(target)],
                            input=patch, capture_output=True, timeout=15)
                        assert applied.returncode == 0, (name, profile, backend, applied.stderr)
                        assert (target.read_bytes() if target.exists() else b'') == b.read_bytes()
                    else:
                        assert a.read_bytes() == b.read_bytes()
                results.append({'workload': name, 'profile': profile, 'backend': backend,
                    'error': error, 'min_edits': cost, 'patch_applied': not limited})
args.out.parent.mkdir(parents=True, exist_ok=True)
args.out.write_text(json.dumps({'cases': results}, indent=2) + '\n')
print(f'Qualified {len(results)} backend/profile cases; successful patches apply with fuzz=0.')
