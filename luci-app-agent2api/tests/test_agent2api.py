"""Isolated regressions; Docker and UCI calls never reach the host services."""

import ctypes
import ctypes.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


APP = Path(__file__).resolve().parents[1]
SCRIPT = APP / "root/usr/libexec/istorec/agent2api.sh"


class LifecycleTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="agent2api-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.log = self.root / "docker-calls"
        self.log.touch()
        self.env = dict(os.environ, PATH=str(self.root) + ":" + os.environ["PATH"])
        self.env.update(
            REVIEW_LOG=str(self.log),
            REVIEW_CONFIG=str(self.root / "data"),
            REVIEW_IMAGE="aimodcc/agent2api:latest",
            REVIEW_PORT="3065",
            REVIEW_TZ="Asia/Shanghai",
            REVIEW_PULL_RESULT="0",
            REVIEW_RUN_RESULT="0",
        )
        self.env.pop("money", None)
        self.stub("uci", """#!/bin/sh
case "$2" in
  *config_path) printf '%s\\n' "$REVIEW_CONFIG" ;;
  *image_name) printf '%s\\n' "$REVIEW_IMAGE" ;;
  *http_port) printf '%s\\n' "$REVIEW_PORT" ;;
  *zonename) printf '%s\\n' "$REVIEW_TZ" ;;
esac
""")
        self.stub("docker", """#!/usr/bin/env python3
import json, os, sys
with open(os.environ['REVIEW_LOG'], 'a') as log:
    log.write(json.dumps(sys.argv[1:]) + '\\n')
action = sys.argv[1]
if action == 'pull':
    sys.exit(int(os.environ['REVIEW_PULL_RESULT']))
if action == 'run':
    sys.exit(int(os.environ['REVIEW_RUN_RESULT']))
if action == 'ps':
    print('0.0.0.0:43065->3065/tcp' if '{{.Ports}}' in sys.argv else 'running')
""")
        # Keep failure diagnostics isolated as well.
        self.stub("pgrep", "#!/bin/sh\nexit 1\n")

    def stub(self, name, content):
        path = self.root / name
        path.write_text(content)
        path.chmod(0o755)

    def execute(self, action="install", direct=False):
        self.log.write_text("")
        command = [str(SCRIPT), action]
        if not direct:
            command.insert(0, "sh")
        return subprocess.run(command, env=self.env, cwd=self.root,
                              text=True, capture_output=True)

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_entrypoint_and_lifecycle_actions(self):
        for action in ("install", "upgrade", "start", "stop", "restart", "rm", "status", "port"):
            with self.subTest(action=action):
                result = self.execute(action, direct=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                if action in ("install", "upgrade"):
                    self.assertEqual([call[0] for call in self.calls()], ["pull", "rm", "run"])
                elif action == "status":
                    self.assertEqual(result.stdout.strip(), "running")
                elif action == "port":
                    self.assertEqual(result.stdout.strip(), "43065")
                else:
                    expected = ["rm", "-f", "agent2api"] if action == "rm" else [action, "agent2api"]
                    self.assertEqual(self.calls(), [expected])

    def test_mount_path_is_literal(self):
        for name in ("with spaces", "config$money", 'config"quote', "config'quote",
                     "config$(touch injected)", "config`touch injected`"):
            with self.subTest(name=name):
                self.env["REVIEW_CONFIG"] = str(self.root / name)
                result = self.execute()
                self.assertEqual(result.returncode, 0, result.stderr)
                run = self.calls()[-1]
                self.assertEqual(run[run.index("-v") + 1], self.env["REVIEW_CONFIG"] + ":/data")
                self.assertTrue(Path(self.env["REVIEW_CONFIG"]).is_dir())
                self.assertFalse((self.root / "injected").exists())

    def test_image_and_timezone_are_literal_arguments(self):
        self.env.update(REVIEW_IMAGE="custom$(touch injected):latest",
                        REVIEW_TZ="Custom$(touch${IFS}injected)")
        result = self.execute()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls()[0], ["pull", self.env["REVIEW_IMAGE"]])
        run = self.calls()[-1]
        self.assertEqual(run[-1], self.env["REVIEW_IMAGE"])
        self.assertIn("TZ=" + self.env["REVIEW_TZ"], run)
        self.assertFalse((self.root / "injected").exists())

    def test_defaults_and_optional_timezone(self):
        self.env.update(REVIEW_PORT="", REVIEW_IMAGE="", REVIEW_TZ="")
        result = self.execute()
        self.assertEqual(result.returncode, 0, result.stderr)
        run = self.calls()[-1]
        self.assertEqual(run[-1], "aimodcc/agent2api:latest")
        self.assertEqual(run[run.index("-p") + 1], "3065:3065")
        self.assertFalse(any(arg.startswith("TZ=") for arg in run))
        self.assertIn("AGENT2API_IMAGE_CACHE_MB=64", run)
        self.assertIn("AGENT2API_IMAGE_COMPRESS_CACHE_MB=64", run)

    def test_empty_config_stops_before_docker(self):
        self.env["REVIEW_CONFIG"] = ""
        self.assertNotEqual(self.execute().returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_pull_failure_preserves_existing_container(self):
        self.env["REVIEW_PULL_RESULT"] = "1"
        result = self.execute()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [["pull", self.env["REVIEW_IMAGE"]]])

    def test_run_failure_is_reported(self):
        self.env["REVIEW_RUN_RESULT"] = "125"
        self.assertEqual(self.execute().returncode, 125)


class ConfigPathTests(unittest.TestCase):
    def test_quickstart_defaults_and_disk_candidates(self):
        # Use Lua 5.1, matching LuCI, without requiring an installed Lua CLI.
        name = ctypes.util.find_library("luajit-5.1") or ctypes.util.find_library("lua5.1")
        if not name:
            self.skipTest("Lua 5.1 or LuaJIT shared library is required")
        lua = ctypes.CDLL(name)
        lua.luaL_newstate.restype = ctypes.c_void_p
        lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
        lua.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
        lua.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
        lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
        lua.lua_tolstring.restype = ctypes.c_char_p
        lua.lua_close.argtypes = [ctypes.c_void_p]
        state = lua.luaL_newstate()
        self.addCleanup(lua.lua_close, state)
        lua.luaL_openlibs(state)
        code = """
local values = {}
package.preload['luci.jsonc'] = function() return {} end
package.preload['luci.model.uci'] = function()
  return {cursor=function() return {get_first=function(_, _, _, key, default)
    return values[key] or default
  end} end}
end
local model = dofile(%s)
local function check(blocks, settings, expected)
  values = settings
  local paths, default = model.find_paths(blocks, model.home(), 'Configs')
  assert(default == expected, 'wrong default: ' .. default)
  local found = false
  for _, path in ipairs(paths) do if path == default then found = true end end
  assert(found, 'default must be selectable')
  for _, block in ipairs(blocks) do
    found = false
    for _, path in ipairs(paths) do
      if path == block .. '/Configs/Agent2API' then found = true end
    end
    assert(found, 'missing disk candidate')
  end
  local seen = {}
  for _, path in ipairs(paths) do
    assert(not seen[path], 'duplicate candidate')
    seen[path] = true
  end
end
check({'/mnt/disk'}, {conf_dir='/mnt/custom'}, '/mnt/custom/Agent2API')
check({}, {conf_dir='/mnt/custom'}, '/mnt/custom/Agent2API')
check({}, {}, '/root/Configs/Agent2API')
check({}, {main_dir='/mnt/main'}, '/mnt/main/Configs/Agent2API')
check({'/mnt/first', '/mnt/second'}, {}, '/mnt/first/Configs/Agent2API')
check({'/mnt/disk'}, {conf_dir='/mnt/disk/Configs'}, '/mnt/disk/Configs/Agent2API')
check({'/mnt/disk'}, {main_dir='/mnt/main'}, '/mnt/main/Configs/Agent2API')
""" % json.dumps(str(APP / "luasrc/model/agent2api.lua"))
        result = lua.luaL_loadstring(state, code.encode())
        if result == 0:
            result = lua.lua_pcall(state, 0, 0, 0)
        self.assertEqual(result, 0, lua.lua_tolstring(state, -1, None))


if __name__ == "__main__":
    unittest.main(verbosity=2)
