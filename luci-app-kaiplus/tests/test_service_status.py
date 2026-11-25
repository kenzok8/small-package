"""Run with LUA_COMMAND='ssh root@192.168.30.7 lua -' when Lua is remote."""
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import unittest


APP = Path(__file__).resolve().parents[1]


class ServiceStatusTest(unittest.TestCase):
    def test_readiness_probes_tcp_and_unix_with_retries(self):
        command = os.environ.get("LUA_COMMAND")
        if not command:
            lua = shutil.which("lua5.1") or shutil.which("lua")
            if not lua:
                self.skipTest("Lua 5.1 required; set LUA_COMMAND for SSH")
            command = shlex.quote(lua) + " -"
        model = (APP / "luasrc/model/kaiplus.lua").read_text()
        harness = r'''
local calls, pauses = 0, 0
package.loaded["nixio"] = {
  socket = function(family, kind)
    assert((family == "inet" or family == "unix") and kind == "stream")
    return {
      setopt = function(_, level, option, value)
        assert(level == "socket" and option == "sndtimeo" and value == 1)
      end,
      connect = function(_, host, port)
        if family == "unix" then assert(host == "/var/run/kaiplus.sock" and port == nil)
        else assert(host == "127.0.0.1" and port == 8189) end
        calls = calls + 1
        return calls >= 3
      end,
      close = function() end
    }
  end,
  nanosleep = function(seconds, nanoseconds)
    assert(seconds == 0 and nanoseconds == 500000000)
    pauses = pauses + 1
  end
}
local chunk = assert(loadstring(source))
local model = chunk()
assert(model.wait_ready("8189", 5, 500) == true)
assert(calls == 3 and pauses == 2)
calls = 0
assert(model.wait_ready("invalid", 2, 0) == false)
assert(calls == 0)
calls, pauses = 0, 0
assert(model.wait_socket_ready("/var/run/kaiplus.sock", 5, 500) == true)
assert(calls == 3 and pauses == 2)
calls = 0
assert(model.wait_socket_ready("relative.sock", 2, 0) == false)
assert(calls == 0)
print("ready")
'''
        result = subprocess.run(shlex.split(command), input="local source = [====[" + model + "]====]\n" + harness,
                                text=True, capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout.strip(), "ready")

    def test_real_controller_and_status_button_for_both_binary_names(self):
        command = os.environ.get("LUA_COMMAND")
        if not command:
            lua = shutil.which("lua5.1") or shutil.which("lua")
            if not lua:
                self.skipTest("Lua 5.1 required; set LUA_COMMAND for SSH")
            command = shlex.quote(lua) + " -"
        controller = (APP / "luasrc/controller/kaiplus.lua").read_text()
        self.assertNotIn("]====]", controller)
        harness = r'''
local reply, processes, service_ready
package.loaded["luci.http"] = {}
package.loaded["luci.dispatcher"] = {build_url = function() return "/auth" end}
package.loaded["luci.model.linkease.apps_openwrt"] = {new = function() return {} end}
package.loaded["luci.model.linkease.apps_compat"] = {new = function() return {
    legacy_status = function(_, id, fields) assert(id == "kaiplus"); reply = fields end
} end}
package.loaded["luci.model.uci"] = {cursor = function() return {
    get_first = function() return "/var/run/kaiplus.sock" end, get = function() return "192.168.30.7" end
} end}
package.loaded["luci.model.kaiplus.classic"] = {installed = function() return false end}
package.loaded["luci.model.kaiplus"] = {socket_ready = function(path)
    assert(path == "/var/run/kaiplus.sock")
    return service_ready
end}
package.loaded["luci.sys"] = {call = function(cmd)
    local names = assert(cmd:match("^pidof (.-) >[ /%w]+$"), cmd)
    for name in names:gmatch("%S+") do if processes[name] then return 0 end end
    return 1
end}
local env = setmetatable({module = function() end}, {__index = _G})
local chunk = assert(loadstring(source)); setfenv(chunk, env); chunk()
for _, case in ipairs({
    {name="kaiplus_bin", processes={kaiplus_bin=true}, ready=true, expected=true},
    {name="kaiplus", processes={kaiplus=true}, ready=true, expected=true},
    {name="starting", processes={kaiplus_bin=true}, ready=false, expected=true},
    {name="stopped", processes={}, ready=false, expected=false},
    {name="classic-only", processes={kai_bin=true}, ready=false, expected=false}
}) do
    processes = case.processes; service_ready = case.ready; env.kaiplus_status()
    assert(reply.running == case.expected, case.name .. " reported " .. tostring(reply.running))
    assert(reply.ready == case.ready, case.name .. " readiness reported " .. tostring(reply.ready))
    print(tostring(reply.running) .. ":" .. tostring(reply.ready))
end
'''
        result = subprocess.run(shlex.split(command), input="local source = [====[" + controller + "]====]\n" + harness,
                                text=True, capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        states = [line.split(":") == ["true", "true"] for line in result.stdout.splitlines()]
        self.assertEqual(states, [True, True, False, False, False])

        template = (APP / "luasrc/view/kaiplus/kaiplus_status.htm").read_text()
        script = re.search(r"<script[^>]*>(.*?)</script>", template, re.S).group(1)
        script = re.sub(r'<%=url\("([^"]+)"\)%>', r"/cgi-bin/luci/\1", script)
        script = re.sub(r"<%:([^%]+)%>", r"\1", script)
        self.assertNotIn("<%", script)
        browser = r'''
const vm = require('node:vm'), assert = require('node:assert/strict');
const elements = {'kaiplus_status': {}, 'kaiplus-open': {style: {}}};
let poll;
vm.runInNewContext(source, {
    XHR: {poll: (_, url, data, callback) => {poll = callback;}},
    document: {getElementById: id => elements[id]}
});
for (const state of states) {
    poll(null, {...state, access: {available: state.entry}});
    assert.equal(elements['kaiplus-open'].style.display, state.ready && state.entry ? '' : 'none');
    const expected = state.ready ? 'service is running.' : state.running ? 'service is starting.' : 'service is not running.';
    assert.ok(elements.kaiplus_status.innerHTML.includes(expected));
    assert.ok(elements.kaiplus_status.innerHTML.includes(state.entry ? 'Application entry is available.' : 'Application entry is unavailable.'));
}
'''
        browser_states = [
            {"running": True, "ready": True, "entry": True},
            {"running": True, "ready": True, "entry": False},
            {"running": True, "ready": False, "entry": True},
            {"running": False, "ready": False, "entry": False},
        ]
        result = subprocess.run(["node", "-e", "const source = " + json.dumps(script) + "; const states = " + json.dumps(browser_states) + ";\n" + browser],
                                text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        form = (APP / "luasrc/model/cbi/kaiplus.lua").read_text()
        self.assertIn("kaiplus_model.wait_socket_ready", form)
        self.assertNotRegex(form, r"\bsleep\s+8\b")


if __name__ == "__main__":
    unittest.main()
