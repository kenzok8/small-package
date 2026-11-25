import json
from pathlib import Path
import re
import subprocess
import unittest


APP_DIR = Path(__file__).resolve().parents[1]
AGENTFLOW_DIR = APP_DIR.parent
META_DIR = AGENTFLOW_DIR / "app-meta-agentflow"
RUNTIME_DIR = AGENTFLOW_DIR / "agentflow"


class AgentFlowLuciOpenContractTest(unittest.TestCase):
    def read(self, relative):
        return (APP_DIR / relative).read_text(encoding="utf-8")

    def test_luci_open_delegates_to_shared_apps_entry(self):
        makefile = self.read("Makefile")
        controller = self.read("luasrc/controller/agentflow.lua")
        status = self.read("luasrc/view/agentflow/status.htm")
        meta = (META_DIR / "Makefile").read_text(encoding="utf-8")

        self.assertIn("+luci-lib-linkeaseauth", makefile)
        self.assertIn("+linkease-app-entry", makefile)
        self.assertIn("PKG_VERSION:=1.0.2-r1", makefile)
        self.assertIn("PKG_RELEASE:=9", meta)
        self.assertIn("META_LUCI_ENTRY:=/cgi-bin/luci/admin/services/agentflow", meta)
        self.assertIn('entry({"admin", "services", "agentflow", "open"}', controller)
        self.assertIn("open.sysauth = false", controller)
        self.assertIn("function agentflow_open()", controller)
        self.assertIn('compat():open("agentflow")', controller)
        self.assertIn('compat():legacy_status("agentflow"', controller)
        self.assertIn('url("admin/services/linkease_apps/open")', status)
        self.assertNotIn('window.location.hostname + ":" + st.port', status)

    def test_app_meta_configures_private_data_and_home(self):
        meta = (META_DIR / "Makefile").read_text(encoding="utf-8")
        config = (META_DIR / "config.sh").read_text(encoding="utf-8")
        entry = (META_DIR / "entry.sh").read_text(encoding="utf-8")

        self.assertIn("META_AUTOCONF:=path enable", meta)
        self.assertIn('data_dir="$ISTORE_CONF_DIR/AgentFlow"', config)
        self.assertIn('set agentflow.@agentflow[0].home_dir="$home_dir"', config)
        self.assertIn('set agentflow.@agentflow[0].enabled="$enabled"', config)
        self.assertIn("ISTORE_DONT_START", config)
        self.assertIn('APP=agentflow', entry)
        self.assertIn('json_add_string "href" "/cgi-bin/luci/admin/services/agentflow"', entry)
        self.assertIn("linkease_apps/open?id=agentflow", entry)

    def test_app_meta_and_desktop_icons_have_single_owners(self):
        manifest = json.loads((RUNTIME_DIR / "files/agentflow-plugin.json").read_text())
        self.assertEqual(manifest["id"], "agentflow")
        self.assertEqual(manifest["auth"]["mode"], "passthrough")
        self.assertEqual(manifest["backend"]["host"], "127.0.0.1")
        self.assertTrue((RUNTIME_DIR / "files/www/logo.svg").is_file())
        self.assertTrue((META_DIR / "logo.png").read_bytes().startswith(b"\x89PNG\r\n\x1a\n"))

    def test_missing_gateway_disables_open_and_provider_list_remains_visible(self):
        template = self.read("luasrc/view/agentflow/status.htm")
        source = template[template.index("function agentflowAbsoluteUrl"):template.index("XHR.poll")]
        source = re.sub(r"<%:([^%]+)%>", r"\1", source)
        harness = r'''
const vm = require('node:vm'), assert = require('node:assert/strict');
function element() { return {children:[], appendChild(v){this.children.push(v)}, removeChild(){this.children.shift()}, style:{}} }
const elements = {
 'agentflow-open': {}, 'agentflow-address': {}, 'agentflow-service-description': {},
 'agentflow-service-icon': {}, 'agentflow-service-title': {}, 'agentflow-provider-list': element()
};
Object.defineProperty(elements['agentflow-provider-list'], 'firstChild', {get(){return this.children[0]}});
const context = {
 URL, window:{location:{href:'http://router.lan/cgi-bin/luci/admin/services/agentflow'}},
 document:{
  getElementById:id=>elements[id]||null,
  createElement:tag=>{const value=element();value.tagName=tag;return value}
 },
 agentflowLabels:{ready:'Ready',notInstalled:'Not installed',manage:'Manage',version:'Version',noProviders:'None',copied:'Copied'}
};
vm.createContext(context); vm.runInContext(source, context);
context.agentflowRenderStatus({running:true,access:{available:false},providers:[{id:'codex',name:'Codex',installed:true,version:'1.2.3',manage_url:'/manage'}]});
assert.equal(elements['agentflow-open'].disabled, true);
assert.equal(elements['agentflow-provider-list'].children.length, 1);
assert.equal(elements['agentflow-provider-list'].children[0].children[0].textContent, 'Codex');
'''
        result = subprocess.run(
            ["node", "-e", "const source=" + json.dumps(source) + ";\n" + harness],
            capture_output=True, text=True, timeout=15,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
