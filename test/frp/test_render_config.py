import importlib.util
import json
import os
import subprocess
from pathlib import Path
import tempfile
import tomllib
import unittest

spec = importlib.util.spec_from_file_location("renderer", Path(__file__).parents[2] / "modules/services/frp/render-config.py")
renderer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderer)


class RenderTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.template = self.root / "template"
        self.paths = self.root / "paths.json"
        self.secret = self.root / "secret"
        self.output = self.root / "config.toml"
        self.paths.write_text(json.dumps({"FRP_TOKEN": str(self.secret)}))
        self.template.write_text('[auth]\ntoken = "@FRP_TOKEN@"\n')

    def render(self):
        renderer.render(self.template, self.paths, self.output)

    def test_toml_escaping_and_private_output(self):
        value = 'quote" backslash\\ tab\t snow雪'
        self.secret.write_text(value + '\n')
        self.render()
        self.assertEqual(tomllib.loads(self.output.read_text())["auth"]["token"], value)
        self.assertEqual(self.output.stat().st_mode & 0o777, 0o600)

    def test_missing_secret_preserves_previous_config(self):
        self.output.write_text("previous")
        with self.assertRaises(FileNotFoundError): self.render()
        self.assertEqual(self.output.read_text(), "previous")

    def test_rejects_empty_and_multiline_secrets(self):
        for value in ['', '\n', 'one\ntwo', 'one\r', 'one\0']:
            with self.subTest(value=value):
                self.secret.write_text(value)
                with self.assertRaises(ValueError): self.render()

    def test_rejects_unresolved_channel_key(self):
        self.secret.write_text('token')
        self.template.write_text('secretKey = "@FRP_SCREEN_KEY@"\n')
        with self.assertRaises(ValueError): self.render()

    def test_rejects_shared_runtime_directory(self):
        self.secret.write_text('token')
        self.root.chmod(0o755)
        with self.assertRaises(ValueError): self.render()

    def test_output_symlink_does_not_overwrite_target(self):
        target = self.root / 'unrelated'
        target.write_text('keep')
        self.output.symlink_to(target)
        self.secret.write_text('token')
        self.render()
        self.assertEqual(target.read_text(), 'keep')
        self.assertFalse(self.output.is_symlink())

    def test_rotation_replaces_complete_config(self):
        for value in ['first', 'second']:
            self.secret.write_text(value)
            self.render()
            self.assertEqual(tomllib.loads(self.output.read_text())['auth']['token'], value)

    @unittest.skipUnless(os.environ.get("FRP_TEST_AGE"), "Set FRP_TEST_AGE for age integration")
    def test_decrypts_ciphertext_at_service_start(self):
        age = os.environ["FRP_TEST_AGE"]
        identity = self.root / "identity"
        subprocess.run([age + "-keygen", "-o", str(identity)], capture_output=True, check=True)
        public = subprocess.check_output([age + "-keygen", "-y", str(identity)], text=True).strip()
        encrypted = subprocess.run([age, "--encrypt", "-r", public], input=b"test-token\n", capture_output=True, check=True).stdout
        self.secret.write_bytes(encrypted)
        renderer.render(self.template, self.paths, self.output, age, str(identity))
        self.assertEqual(tomllib.loads(self.output.read_text())["auth"]["token"], "test-token")

    @unittest.skipUnless(os.environ.get("FRP_TEST_AGE"), "Set FRP_TEST_AGE for age integration")
    def test_failed_decryption_preserves_previous_output(self):
        self.output.write_text("previous")
        self.secret.write_bytes(b"invalid encrypted input")
        with self.assertRaises(subprocess.CalledProcessError):
            renderer.render(self.template, self.paths, self.output,
                            os.environ["FRP_TEST_AGE"], str(self.root / "missing-identity"))
        self.assertEqual(self.output.read_text(), "previous")


if __name__ == '__main__': unittest.main()
