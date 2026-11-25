import json
import os
from pathlib import Path
import subprocess
import unittest


APP = Path(__file__).resolve().parents[1]
PROVIDERS = APP / "luasrc/model/agentflow/providers.lua"


HARNESS = r'''
local cjson=require('cjson')
local module=dofile(os.getenv('PROVIDERS'))
local names={'codex.json','ignored.json'}
local index=0
local descriptors={
 ['codex.json']=cjson.encode({schemaVersion=1,id='codex',name='OpenAI Codex',kind='cli',
  command='/usr/bin/codex',statusCommand={'/usr/libexec/codex-runtime','provider-status'},
  ownerPackage='codex',manageUrl='/cgi-bin/luci/admin/services/codex'}),
 ['ignored.json']=cjson.encode({schemaVersion=1,id='bad;id',name='Bad',kind='cli',
  command='/bin/sh',statusCommand={'/bin/sh','status'},manageUrl='https://example.invalid/'})
}
local calls={}
local fs={
 dir=function() return function() index=index+1;return names[index] end end,
 readfile=function(path)return descriptors[path:match('[^/]+$')]end,
 access=function(path,mode)return path=='/usr/bin/codex'or path=='/usr/libexec/codex-runtime'end
}
local sys={exec=function(command)calls[#calls+1]=command;return cjson.encode({configured=true,installed=true,authenticated=false,version='1.2.3'})end}
local util={shellquote=function(value)return "'"..value.."'"end}
local result=module.new({fs=fs,jsonc={parse=cjson.decode},sys=sys,util=util,directory='/fixtures'}):list()
print(cjson.encode({providers=result,calls=calls}))
'''


class ProviderContractTest(unittest.TestCase):
    def test_provider_registry_is_data_driven_and_fail_closed(self):
        result = subprocess.run(
            ["lua", "-"], input=HARNESS, text=True, capture_output=True, check=True,
            env={**os.environ, "PROVIDERS": str(PROVIDERS)},
        )
        value = json.loads(result.stdout)
        self.assertEqual(len(value["providers"]), 1)
        provider = value["providers"][0]
        self.assertEqual(provider["id"], "codex")
        self.assertEqual(provider["manage_url"], "/cgi-bin/luci/admin/services/codex")
        self.assertTrue(provider["installed"])
        self.assertEqual(provider["version"], "1.2.3")
        self.assertEqual(value["calls"], ["'/usr/libexec/codex-runtime' provider-status 2>/dev/null"])

    def test_luci_has_no_installer_or_runtime_manager(self):
        makefile = (APP / "Makefile").read_text()
        controller = (APP / "luasrc/controller/agentflow.lua").read_text()
        view = (APP / "luasrc/view/agentflow/status.htm").read_text()
        self.assertNotIn("luci-lib-taskd", makefile)
        self.assertNotIn("luci-app-mise", makefile)
        self.assertNotIn("agent_install", controller)
        self.assertNotIn("agentflow-runtime", controller)
        self.assertNotIn("Install now", view)
        self.assertIn("status.providers", view)
        self.assertIn("independent plugins", view)


if __name__ == "__main__":
    unittest.main()
