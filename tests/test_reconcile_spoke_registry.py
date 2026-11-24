import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "reconcile_spoke_registry.py"
sys.path.insert(0, str(SCRIPT.parent))
from reconcile_spoke_registry import reconcile


class ReconcileSpokeRegistryTests(unittest.TestCase):
    def test_removes_only_missing_resource_groups(self):
        registry = {"live": 1, "protected": 2, "stale": 3}
        groups = ["RG-Spoke-live-SBX", "RG-Spoke-protected-SBX", "RG-Hub-SBX"]
        self.assertEqual(reconcile(registry, groups), {"live": 1, "protected": 2})

    def test_matches_resource_groups_case_insensitively(self):
        self.assertEqual(reconcile({"Mixed": 9}, ["rg-spoke-mIxEd-sbx"]), {"Mixed": 9})

    def test_empty_registry_and_empty_group_list(self):
        self.assertEqual(reconcile({}, ["RG-Spoke-live-SBX"]), {})
        self.assertEqual(reconcile({"missing": 5}, []), {})

    def test_invalid_input_is_rejected(self):
        for registry, groups in [
            ([], []),
            ({"valid": 1}, {}),
            ({"valid": 1}, [None]),
            ({"valid": 1}, [""]),
            ({"": 1}, []),
        ]:
            with self.subTest(registry=registry, groups=groups):
                with self.assertRaises(ValueError):
                    reconcile(registry, groups)

    def test_command_preserves_output_when_input_invalid(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            registry = path / "registry.json"
            groups = path / "groups.json"
            output = path / "output.json"
            registry.write_text(json.dumps({"live": 1}), encoding="utf-8")
            groups.write_text("not json", encoding="utf-8")
            output.write_text("untouched", encoding="utf-8")
            result = subprocess.run(
                [sys.executable, "-B", str(SCRIPT), str(registry), str(groups), str(output)],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(output.read_text(encoding="utf-8"), "untouched")

    def test_command_writes_reconciled_registry(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            registry = path / "registry.json"
            groups = path / "groups.json"
            output = path / "output.json"
            registry.write_text(json.dumps({"live": 4, "stale": 5}), encoding="utf-8")
            groups.write_text(json.dumps(["RG-Spoke-live-SBX"]), encoding="utf-8")
            result = subprocess.run(
                [sys.executable, "-B", str(SCRIPT), str(registry), str(groups), str(output)],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(output.read_text(encoding="utf-8")), {"live": 4})


if __name__ == "__main__":
    unittest.main()
