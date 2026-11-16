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
local reply, processes
package.loaded["luci.http"] = {}
package.loaded["luci.dispatcher"] = {build_url = function() return "/auth" end}
package.loaded["luci.model.linkease.apps_openwrt"] = {new = function() return {} end}
package.loaded["luci.model.linkease.apps_compat"] = {new = function() return {
    legacy_status = function(_, id, fields) assert(id == "kaiplus"); reply = fields end
} end}
package.loaded["luci.model.uci"] = {cursor = function() return {
    get_first = function() return "8189" end, get = function() return "192.168.30.7" end
} end}
package.loaded["luci.model.kaiplus.classic"] = {installed = function() return false end}
package.loaded["luci.sys"] = {call = function(cmd)
    local names = assert(cmd:match("^pidof (.-) >[ /%w]+$"), cmd)
    for name in names:gmatch("%S+") do if processes[name] then return 0 end end
    return 1
end}
local env = setmetatable({module = function() end}, {__index = _G})
local chunk = assert(loadstring(source)); setfenv(chunk, env); chunk()
for _, case in ipairs({
    {name="kaiplus_bin", processes={kaiplus_bin=true}, expected=true},
    {name="kaiplus", processes={kaiplus=true}, expected=true},
    {name="stopped", processes={}, expected=false},
    {name="classic-only", processes={kai_bin=true}, expected=false}
}) do
    processes = case.processes; env.kaiplus_status()
    assert(reply.running == case.expected, case.name .. " reported " .. tostring(reply.running))
    print(tostring(reply.running))
end
'''
        result = subprocess.run(shlex.split(command), input="local source = [====[" + controller + "]====]\n" + harness,
                                text=True, capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        states = [line == "true" for line in result.stdout.splitlines()]
        self.assertEqual(states, [True, True, False, False])

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
for (const running of states) {
    poll(null, {running, proxy_prefix_enabled: true, app_entry_running: true});
    assert.equal(elements['kaiplus-open'].style.display, running ? '' : 'none');
    assert.ok(elements.kaiplus_status.innerHTML.includes(running ? 'service is running.' : 'service is not running.'));
    assert.ok(elements.kaiplus_status.innerHTML.includes('LinkEase Desktop proxy.'));
}
'''
        result = subprocess.run(["node", "-e", "const source = " + json.dumps(script) + "; const states = " + json.dumps(states) + ";\n" + browser],
                                text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
