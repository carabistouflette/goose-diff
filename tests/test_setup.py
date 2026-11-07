# SPDX-License-Identifier: Apache-2.0
"""Compiler setup must reject altered sources before any fetch/build."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class SetupGuards(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "scripts").mkdir()
        source = Path(__file__).resolve().parents[1] / "scripts/setup-goose.sh"
        shutil.copy2(source, self.root / "scripts/setup-goose.sh")
        (self.root / "GOOSE_REVISION").write_text("a" * 40 + "\n")
        self.compiler = self.root / ".toolchain/goose"
        self.compiler.mkdir(parents=True)
        self.git("init", "-q")
        (self.compiler / "source").write_text("original\n")
        self.git("add", "source")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "fixture")

    def git(self, *args):
        subprocess.run(["git", "-C", str(self.compiler), *args], check=True, capture_output=True)

    def rejected(self, diagnostic):
        run = subprocess.run(["bash", "scripts/setup-goose.sh"], cwd=self.root, capture_output=True, text=True, timeout=5)
        self.assertNotEqual(run.returncode, 0)
        self.assertIn(diagnostic, run.stderr)
        self.assertNotIn("fatal:", run.stderr)  # rejection precedes fetch without origin

    def test_invalid_pin(self):
        (self.root / "GOOSE_REVISION").write_text("main\n")
        self.rejected("full lowercase 40-character")

    def test_modified_source(self):
        (self.compiler / "source").write_text("modified\n")
        self.rejected("Compiler source is modified")

    def test_untracked_source(self):
        (self.compiler / "extra").write_text("unexpected\n")
        self.rejected("Compiler source is modified")

    def test_assume_unchanged(self):
        self.git("update-index", "--assume-unchanged", "source")
        self.rejected("Compiler index hides source checks")

    def test_skip_worktree(self):
        self.git("update-index", "--skip-worktree", "source")
        self.rejected("Compiler index hides source checks")


if __name__ == "__main__":
    unittest.main()
