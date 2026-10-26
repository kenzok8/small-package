from pathlib import Path
import json
import os
import re
import shlex
import shutil
import subprocess
import tempfile
import unittest


APP_DIR = Path(__file__).resolve().parents[1]


class ClassicKaiEntryContractTest(unittest.TestCase):
    def test_classic_runtime_remains_an_optional_install(self):
        makefile = (APP_DIR / "Makefile").read_text()
        deps = re.search(r"^LUCI_DEPENDS:=(.*)$", makefile, re.M).group(1).split()
        self.assertIn("+kaiplus", deps)
        self.assertIn("+luci-lib-taskd", deps)
        for package in ("kai", "kai_session", "kai-agent", "luci-app-kai"):
            self.assertNotIn("+" + package, deps)

    def test_lua_routes_installation_and_configuration(self):
        command = os.environ.get("LUA_COMMAND")
        if not command:
            lua = shutil.which("lua5.1") or shutil.which("lua") or shutil.which("luajit")
            if not lua:
                self.skipTest("Lua 5.1 required; LUA_COMMAND can use an SSH interpreter")
            command = shlex.quote(lua) + " -"
        paths = {
            "controller": "luasrc/controller/kaiplus.lua",
            "classic": "luasrc/model/kaiplus/classic.lua",
            "paths": "luasrc/model/kaiplus.lua",
            "form": "luasrc/model/cbi/kaiplus/classic.lua",
        }
        sources = "local sources = {}\n"
        for name, relative in paths.items():
            body = (APP_DIR / relative).read_text()
            self.assertNotIn("]====]", body)
            sources += f"sources.{name} = [====[{body}]====]\n"
        harness = (APP_DIR / "tests/classic_kai_runtime.lua").read_text()
        result = subprocess.run(shlex.split(command), input=sources + harness,
                                text=True, capture_output=True, timeout=45)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("classic KAI runtime checks passed", result.stdout)

    def test_installation_ui_retries_and_reloads_the_embedded_form(self):
        node = shutil.which("node")
        if not node:
            self.skipTest("Node.js required for browser behavior checks")
        template = (APP_DIR / "luasrc/view/kaiplus/classic_status.htm").read_text()
        script = re.search(r"<script[^>]*>(.*?)</script>", template, re.S).group(1)
        script = re.sub(r'<%=\s*installed and "true" or "false"\s*%>', "PAGE_INSTALLED", script)
        script = re.sub(r'<%=url\("([^"]+)"\)%>', r"/cgi-bin/luci/\1", script)
        script = re.sub(r"<%:([^%]+)%>", r"\1", script)
        self.assertNotIn("<%", script)
        harness = (APP_DIR / "tests/classic_kai_browser.cjs").read_text()
        result = subprocess.run([node, "-e", "const source = " + json.dumps(script) + ";\n" + harness],
                                text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_package_updates_preserve_state_and_stop_on_failure(self):
        source = (APP_DIR / "root/usr/libexec/kaiplus-classic").read_text()
        with tempfile.TemporaryDirectory(prefix="classic-kai-test-") as directory:
            root = Path(directory)
            stub = '''#!/bin/sh
case "${0##*/}" in
  pidof) [ "$TEST_RUNNING" = 1 ]; exit $?;;
  uci) printf '%s\\n' "$TEST_ENABLED"; exit 0;;
esac
printf '%s %s\\n' "${0##*/}" "$*" >> "$TEST_LOG"
if [ "$TEST_FAIL" = "${0##*/}:$1" ]; then exit 1; fi
'''
            for name in ("is-opkg", "kai", "pidof", "uci"):
                path = root / name
                path.write_text(stub)
                path.chmod(0o755)
            script = source.replace("/bin/is-opkg", shlex.quote(str(root / "is-opkg")))
            script = script.replace("/etc/init.d/kai", shlex.quote(str(root / "kai")))
            path = root / "helper.sh"
            path.write_text(script)

            def run(action, running="1", enabled="1", fail=""):
                log = root / "commands.log"
                log.write_text("")
                env = {**os.environ, "PATH": str(root) + os.pathsep + os.environ["PATH"],
                       "TEST_LOG": str(log), "TEST_RUNNING": running,
                       "TEST_ENABLED": enabled, "TEST_FAIL": fail}
                result = subprocess.run(["sh", str(path), action], env=env,
                                        text=True, capture_output=True, timeout=10)
                return result, log.read_text().splitlines()

            result, commands = run("install")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(commands, ["is-opkg install kai"])
            for running, enabled in (("1", "1"), ("0", "1"), ("1", "0"), ("0", "0")):
                with self.subTest(running=running, enabled=enabled):
                    result, commands = run("update", running, enabled)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    operation = "restart" if running == enabled == "1" else "stop"
                    self.assertEqual(commands, ["is-opkg update", "is-opkg upgrade kai kai_session", "kai " + operation])
            for failure, count in (("is-opkg:update", 1), ("is-opkg:upgrade", 2), ("kai:restart", 3)):
                with self.subTest(failure=failure):
                    result, commands = run("update", fail=failure)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(len(commands), count)
                    self.assertNotIn("update completed", result.stdout)
            result, commands = run("unknown")
            self.assertEqual(result.returncode, 2)
            self.assertEqual(commands, [])


if __name__ == "__main__":
    unittest.main()
