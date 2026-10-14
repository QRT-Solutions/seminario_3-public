"""QRT Solutions: offline checks for credential handling; never register test tokens."""

import hashlib
import json
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'seminario_3/supabase/scripts/crear_credencial.py'


class CredentialFilesTest(unittest.TestCase):
    def setUp(self):
        (ROOT / '.local').mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='credential-test-', dir=ROOT / '.local')
        self.addCleanup(self.temp.cleanup)
        self.target = Path(self.temp.name) / 'device'

    def run_generator(self, target=None):
        return subprocess.run(
            [sys.executable, str(SCRIPT), '--project-ref', 'a' * 20, '--login', '101',
             '--broker', "Example's Broker", '--server', 'Demo', '--output',
             str(target or self.target)],
            cwd=ROOT, capture_output=True, text=True, check=False,
        )

    def test_private_files_and_hash_only_registration(self):
        result = self.run_generator()
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads((self.target / 'connection.json').read_text())
        token = data['token']
        self.assertEqual(data['token_sha256'], hashlib.sha256(token.encode()).hexdigest())
        self.assertNotIn(token, result.stdout + result.stderr)
        register = (self.target / 'register.sql').read_text()
        self.assertNotIn(token, register)
        self.assertIn("Example''s Broker", register)
        self.assertIn(data['token_sha256'], register)
        params = json.loads((self.target / 'parameters.json').read_text())
        self.assertEqual(params['InpEnableKillSwitch'], 'false')
        self.assertIn(token, (self.target / 'MT5_Telemetry_Supabase.set').read_text(encoding='utf-16'))
        if os.name != 'nt':
            for path in self.target.iterdir():
                self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)

    def test_existing_credential_is_never_overwritten(self):
        self.assertEqual(self.run_generator().returncode, 0)
        before = (self.target / 'connection.json').read_bytes()
        self.assertNotEqual(self.run_generator().returncode, 0)
        self.assertEqual((self.target / 'connection.json').read_bytes(), before)

    def test_unignored_destination_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            target = Path(folder) / 'public-device'
            self.assertNotEqual(self.run_generator(target).returncode, 0)
            self.assertFalse(target.exists())


if __name__ == '__main__':
    unittest.main()
