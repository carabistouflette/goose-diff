#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Retain matched-profile core timings and whole-process RSS, including failures."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import platform
import subprocess
import tempfile
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--binary', type=Path, required=True)
parser.add_argument('--goose', type=Path, required=True)
parser.add_argument('--out', type=Path, required=True)
parser.add_argument('--rounds', type=int, default=5)
parser.add_argument('--iterations', type=int, default=20)
args = parser.parse_args()
if not 1 <= args.rounds <= 100 or not 1 <= args.iterations <= 10000:
    parser.error('invalid rounds or iterations')
root = Path(__file__).resolve().parents[1]
binary, goose = args.binary.resolve(), args.goose.resolve()
def git(*arguments, cwd=root):
    return subprocess.check_output(['git', '-C', str(cwd), *arguments], text=True).strip()
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
source = git('rev-parse', 'HEAD')
assert git('status', '--porcelain') == '', 'benchmark requires clean source'
compiler_source = goose.parent.parent
compiler_pin = (root / 'GOOSE_REVISION').read_text().strip()
assert git('rev-parse', 'HEAD', cwd=compiler_source) == compiler_pin
assert git('status', '--porcelain', cwd=compiler_source) == ''
args.out = args.out.resolve()
args.out.mkdir(parents=True, exist_ok=False)
manifest = json.loads((root / 'experiments/fixtures/manifest.json').read_text())
metadata = {'source': source, 'status': '', 'binary_sha256': digest(binary),
    'compiler_revision': compiler_pin, 'compiler_status': '', 'compiler_binary_sha256': digest(goose),
    'gcc': subprocess.check_output(['gcc', '--version'], text=True),
    'platform': platform.platform(), 'machine': platform.machine(),
    'cpu': next((line.split(':', 1)[1].strip() for line in Path('/proc/cpuinfo').read_text().splitlines() if line.startswith('model name')), ''),
    'checked_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'flags': 'Goose build --cc gcc -O2', 'rounds': args.rounds, 'iterations': args.iterations,
    'profiles': {'consumer': {'max_bytes': 65536, 'max_lines': 4096, 'max_cells': 262144, 'max_states': 262144, 'max_work': 1048576},
        'wide': {'max_bytes': 65536, 'max_lines': 4096, 'max_cells': 4194304, 'max_states': 4194304, 'max_work': 67108864}},
    'scope': 'Direct repeated comparison calls, read/verification excluded from timed loop. RSS is GNU time process peak including preflight/runtime. Shared host; no end-to-end consumer or universal speed claim. Failed searches are not successful throughput.',
    'fixtures': manifest['cases']}
(args.out / 'provenance.json').write_text(json.dumps(metadata, indent=2) + '\n')
with tempfile.TemporaryDirectory(prefix='myers-rss-') as temporary:
    rss = Path(temporary) / 'rss'
    with (args.out / 'samples.jsonl').open('w') as output:
        for case in manifest['cases']:
            name = case['name']
            a, b = root / 'experiments/fixtures' / name / 'old.bin', root / 'experiments/fixtures' / name / 'new.bin'
            assert digest(a) == case['old_sha256'] and digest(b) == case['new_sha256']
            for profile in ['consumer', 'wide']:
                for round_number in range(args.rounds):
                    for backend in (['lcs', 'myers'] if round_number % 2 == 0 else ['myers', 'lcs']):
                        command = ['/usr/bin/time', '-f', '%M', '-o', str(rss), str(binary), backend, profile, str(a), str(b), str(args.iterations)]
                        run = subprocess.run(command, check=True, capture_output=True, text=True, timeout=120)
                        elapsed, error, cost, runs, checksum = run.stdout.strip().split('\t')
                        limited = profile == 'consumer' and (case['baseline_omitted'] if backend == 'lcs' else name.startswith('dense_'))
                        assert error == ('Error.LimitExceeded' if limited else 'Error.None'), (name, backend, error)
                        assert int(cost) == (-1 if limited else case['expected_min_edits'])
                        output.write(json.dumps({'workload': name, 'profile': profile, 'round': round_number,
                            'backend': backend, 'elapsed_ns': int(elapsed), 'iterations': args.iterations,
                            'max_rss_kib': int(rss.read_text().strip()), 'error': error,
                            'min_edits': int(cost), 'runs': int(runs), 'checksum': int(checksum)}) + '\n')
                        output.flush()
assert git('rev-parse', 'HEAD') == source and git('status', '--porcelain') == ''
assert digest(binary) == metadata['binary_sha256'] and digest(goose) == metadata['compiler_binary_sha256']
print(f'Retained {len(manifest["cases"]) * 2 * args.rounds * 2} samples with stable source and binaries.')
