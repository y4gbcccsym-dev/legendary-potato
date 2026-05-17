from pathlib import Path
import re
import unittest

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "scripts" / "PLXULTIMATEX.ps1"
README = REPO_ROOT / "README.md"


class PlxUltimateXStaticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.script = SCRIPT.read_text(encoding="utf-8")
        cls.readme = README.read_text(encoding="utf-8")

    def test_documented_version_matches_script(self):
        version_match = re.search(r'\$script:AppVersion = "([^"]+)"', self.script)
        self.assertIsNotNone(version_match)
        version = version_match.group(1)
        self.assertIn(f"version {version}", self.readme)
        self.assertIn(f"`{version}`", self.readme)

    def test_single_core_mode_menu_is_preserved(self):
        self.assertEqual(self.script.count("Activate ULTIMATEXPLUS CORE MODE"), 1)
        self.assertNotIn('Write-Host "2)', self.script)
        self.assertIn('"1" { Preset-UltimateXPLUS }', self.script)

    def test_safety_layers_exist_before_tuning(self):
        required = [
            "function Check-Admin",
            "function New-SystemRestoreCheckpointSafe",
            "function Backup-RegistryKey",
            "function Initialize-RunLog",
            "function Export-RunManifest",
            "[void](Backup-RegistryKey -Path $Path)",
        ]
        for token in required:
            with self.subTest(token=token):
                self.assertIn(token, self.script)

    def test_god_pvp_latency_and_input_tuning_are_present(self):
        required = [
            "function Optimize-GodPvpNetworkLatency",
            "TcpAckFrequency",
            "TCPNoDelay",
            "TcpDelAckTicks",
            "function Optimize-GodPvpInputQueue",
            "KeyboardDataQueueSize",
            "MouseDataQueueSize",
            "Apply GOD PVP network latency profile",
            "Apply GOD PVP input queue profile",
        ]
        for token in required:
            with self.subTest(token=token):
                self.assertIn(token, self.script)

    def test_manifest_tracks_step_results_and_runtime_metadata(self):
        required = [
            "[System.Diagnostics.Stopwatch]::StartNew()",
            "$script:StepResults += [ordered]@",
            "DurationMs",
            "RestoreCheckpointCreated",
            "ConvertTo-Json -Depth 5",
            "ProgramData\\ULTIMATEXPLUS\\Reports\\<run-id>.json",
        ]
        combined = self.script + "\n" + self.readme
        for token in required:
            with self.subTest(token=token):
                self.assertIn(token, combined)


if __name__ == "__main__":
    unittest.main()
