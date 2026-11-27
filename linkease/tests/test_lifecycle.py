import os
import re
import subprocess
import unittest
from pathlib import Path


PACKAGE = Path(__file__).resolve().parents[1]
INIT = PACKAGE / "files/linkease.init"
MAKEFILE = PACKAGE / "Makefile"


def run_conflicting_start(apk_script=None):
    harness = INIT.read_text() + r'''
config_load() { :; }
config_foreach() { :; }
linkeasefull_enabled() { return 0; }
enabled=1
PROG=/bin/true
start_service
'''
    env = dict(os.environ)
    if apk_script is None:
        env.pop("APK_SCRIPT", None)
    else:
        env["APK_SCRIPT"] = apk_script
    return subprocess.run(
        ["sh", "-s"],
        input=harness,
        text=True,
        env=env,
        capture_output=True,
    )


class Lifecycle(unittest.TestCase):
    def test_apk_lifecycle_skips_conflicting_start_without_failing_install(self):
        for phase in ["post-install", "post-upgrade"]:
            with self.subTest(phase=phase):
                result = run_conflicting_start(phase)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("linkeasefull is enabled", result.stderr)

    def test_manual_start_still_reports_the_conflict(self):
        result = run_conflicting_start()
        self.assertEqual(result.returncode, 1)
        self.assertIn("linkeasefull is enabled", result.stderr)

    def test_package_revision_and_postinstall_contract(self):
        recipe = MAKEFILE.read_text()
        self.assertRegex(recipe, r"(?m)^PKG_RELEASE:=3$")
        body = re.search(
            r"define Package/\$\(PKG_NAME\)/postinst\n(.*?)\nendef",
            recipe,
            re.S,
        ).group(1)
        self.assertRegex(body, r"(?m)^exit 0$")


if __name__ == "__main__":
    unittest.main()
