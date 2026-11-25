import json
import os
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest

APP = Path(__file__).resolve().parents[1]
CONTROLLER = APP.parent / "luci-app-agentflow/luasrc/controller/agentflow.lua"

CONTROLLER_HARNESS = r'''
local json=require('cjson')
local scenario=os.getenv('SCENARIO')
local calls,writes={},{}
local status,response
local form={agent='codexcli',token='fixture-token'}
if scenario=='invalid-agent'then form.agent='codexcli; touch unexpected'end
if scenario=='bad-token'then form.token='bad'end
if scenario=='recover'then form.operation='recover'end
package.loaded['luci.http']={
 getenv=function()return scenario=='get'and'GET'or'POST'end,
 formvalue=function(k)return form[k]end,
 status=function(code)status=code end,prepare_content=function()end,
 write_json=function(value)response=value end
}
package.loaded['luci.dispatcher']={context={authsession='fixture-session',authtoken='fixture-token'}}
package.loaded['luci.util']={
 ubus=function()return{access=scenario~='readonly'}end,
 shellquote=function(v)return "'"..v:gsub("'","'\\''").."'"end
}
package.loaded['nixio.fs']={
 access=function()return true end,lstat=function()return scenario=='existing-script'and{}or nil end,
 writefile=function(path,data)writes[#writes+1]={path=path,data=data};return true end,unlink=function()end
}
package.loaded.nixio={getpid=function()return 4312 end}
package.loaded['luci.model.uci']={cursor=function()return{get_first=function()return '/mnt/data/Configs/AgentFlow'end}end}
package.loaded['luci.jsonc']={parse=function(v)local ok,result=pcall(json.decode,v);return ok and result or nil end}
package.loaded['luci.sys']={
 exec=function()return scenario=='busy'and'{"running":true}'or'{}'end,
 call=function(cmd)calls[#calls+1]=cmd;return scenario=='prepare-failed'and 1 or 0 end
}
dofile(os.getenv('CONTROLLER'))
luci.controller.agentflow.agentflow_agent_install()
print(json.encode({response=response,status=status,calls=calls,writes=writes}))
'''


class ControllerBoundary(unittest.TestCase):
    def run_case(self, scenario):
        result = subprocess.run(["lua", "-"], input=CONTROLLER_HARNESS, text=True,
            env={**os.environ, "CONTROLLER": str(CONTROLLER), "SCENARIO": scenario},
            capture_output=True, check=True)
        return json.loads(result.stdout)

    def test_csrf_method_and_readonly_reject_before_side_effects(self):
        for scenario, status in [("get",405),("bad-token",403),("readonly",403)]:
            with self.subTest(scenario=scenario):
                value=self.run_case(scenario)
                self.assertEqual(value["status"],status)
                self.assertFalse(value["response"]["ok"])
                self.assertFalse(value["calls"])
                self.assertFalse(value["writes"])

    def test_unknown_agent_cannot_reach_a_shell(self):
        value=self.run_case("invalid-agent")
        self.assertFalse(value["response"]["ok"])
        self.assertFalse(value["calls"])
        self.assertFalse(value["writes"])

    def test_busy_task_does_not_overwrite_its_script(self):
        value=self.run_case("busy")
        self.assertTrue(value["response"]["busy"])
        self.assertFalse(value["writes"])

    def test_prepare_failure_or_old_task_file_prevents_submission(self):
        for scenario in ("prepare-failed","existing-script"):
            value=self.run_case(scenario)
            self.assertFalse(value["response"]["ok"])
            self.assertFalse(value["writes"])
            self.assertFalse(any("task_add" in x for x in value["calls"]))

    def test_valid_install_submits_local_task_using_protected_application_path(self):
        value=self.run_case("install")
        self.assertTrue(value["response"]["ok"])
        self.assertEqual(len(value["writes"]),1)
        script=value["writes"][0]
        self.assertTrue(script["path"].startswith("/mnt/data/Configs/AgentFlow/.runtime/work/"))
        self.assertIn("/usr/libexec/agentflow-runtime install",script["data"])
        self.assertIn("'codexcli'",script["data"])
        self.assertNotIn("https://",script["data"])
        self.assertNotIn("node@lts",script["data"])
        self.assertTrue(any("task_add agentflow-agent-install" in x for x in value["calls"]))

    def test_recovery_uses_fixed_helper_and_no_arbitrary_task_script(self):
        value=self.run_case("recover")
        self.assertTrue(value["response"]["ok"])
        self.assertEqual(len(value["calls"]),1)
        self.assertTrue(value["calls"][0].startswith("/usr/libexec/agentflow-runtime recover "))
        self.assertFalse(value["writes"])


class NativeInterpreter(unittest.TestCase):
    def inspect(self, content):
        with tempfile.TemporaryDirectory() as temp:
            p=Path(temp)/"elf";p.write_bytes(content)
            code=r'''
package.path=os.getenv('SHARE')..'/?.lua;'..package.path
package.loaded.system={fs={},nixio={},need=function(v,_,message)assert(v,message);return v end}
package.loaded.store={};package.loaded.contract={}
local ok,value=pcall(require('agentflow-agents').interpreter,os.getenv('ELF'))
print(require('cjson').encode({ok=ok,interpreter=ok and value or nil}))
'''
            result=subprocess.run(["lua","-"],input=code,text=True,capture_output=True,check=True,
                env={**os.environ,"SHARE":str(APP/"files"),"ELF":str(p)})
            return json.loads(result.stdout)

    @staticmethod
    def elf(interpreter=None):
        header=bytearray(64);header[:6]=b"\x7fELF\x02\x01"
        struct.pack_into("<Q",header,32,64)
        struct.pack_into("<HH",header,54,56,1 if interpreter else 0)
        if not interpreter:return header
        raw=interpreter.encode()+b"\0";ph=bytearray(56)
        struct.pack_into("<I",ph,0,3);struct.pack_into("<Q",ph,8,120);struct.pack_into("<Q",ph,32,len(raw))
        return header+ph+raw

    def test_recognizes_gnu_and_musl_interpreters(self):
        for interp in ("/lib64/ld-linux-x86-64.so.2","/lib/ld-linux-aarch64.so.1","/lib/ld-musl-x86_64.so.1"):
            self.assertEqual(self.inspect(self.elf(interp))["interpreter"],interp)

    def test_static_files_and_scripts_are_not_native_loader_candidates(self):
        for value in (self.elf(),b"#!/bin/sh\necho example\n",b"{}"):
            result=self.inspect(value);self.assertTrue(result["ok"]);self.assertNotIn("interpreter",result)

    def test_corrupt_program_headers_fail_closed(self):
        value=self.elf("/lib64/ld-linux-x86-64.so.2")
        self.assertFalse(self.inspect(value[:70])["ok"])

    def test_install_owner_need_not_be_a_session_leader(self):
        code=r'''
package.path=os.getenv('SHARE')..'/?.lua;'..package.path
local live={pid=23,start='100',boot='fixture',group=7,state='S'}
package.loaded.system={fs={},nixio={},process=function()return live end}
package.loaded.store={};package.loaded.contract={}
local runtime=require('agentflow-runtime')
assert(runtime.alive({pid=23,start='100',boot='fixture'}))
assert(not runtime.alive({pid=23,start='99',boot='fixture'}))
assert(not runtime.alive({pid=23,start='100',boot='other-boot'}))
live.state='Z';assert(not runtime.alive({pid=23,start='100',boot='fixture'}))
'''
        subprocess.run(["lua","-"],input=code,text=True,check=True,
            env={**os.environ,"SHARE":str(APP/"files")},capture_output=True)

    def test_opencode_chooses_installed_gnu_baseline_without_host_libc_detection(self):
        code=r'''
package.path=os.getenv('SHARE')..'/?.lua;'..package.path
local base='/mnt/test/AgentFlow';local dir=base..'/.runtime/agents/opencode/releases/fixture'
local binary=dir..'/global/lib/node_modules/opencode-ai/node_modules/opencode-linux-x64-baseline/bin/opencode'
local written={}
package.loaded.system={
 fs={realpath=function(path)return path==binary and path or nil end},
 nixio={uname=function()return{machine='x86_64'}end},
 need=function(v,_,message)assert(v,message);return v end,
 decode=function()return{version='1.19.6'}end,
 write=function(path,value)written[path]=value end
}
package.loaded.store={};package.loaded.contract={}
assert(require('agentflow-agents').finish(base,dir,{id='opencode',version='1.19.6'}))
assert(written[dir..'/global/lib/node_modules/opencode-ai/bin/opencode.exe']:find(binary,1,true))
'''
        subprocess.run(["lua","-"],input=code,text=True,check=True,
            env={**os.environ,"SHARE":str(APP/"files")},capture_output=True)


if __name__ == "__main__":
    unittest.main()
