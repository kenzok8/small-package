import json
from pathlib import Path
import unittest


APP_DIR = Path(__file__).resolve().parents[1]
AGENTFLOW_DIR = APP_DIR.parent
META_DIR = AGENTFLOW_DIR / "app-meta-agentflow"
META_MAKEFILE = META_DIR / "Makefile"
RUNTIME_DIR = AGENTFLOW_DIR / "agentflow"


class AgentFlowLuciOpenContractTest(unittest.TestCase):
    def read(self, relative):
        return (APP_DIR / relative).read_text(encoding="utf-8")

    def test_luci_open_delegates_to_shared_apps_entry(self):
        makefile = self.read("Makefile")
        controller = self.read("luasrc/controller/agentflow.lua")
        status = self.read("luasrc/view/agentflow/status.htm")
        meta = META_MAKEFILE.read_text(encoding="utf-8")

        self.assertIn("+luci-lib-linkeaseauth", makefile)
        self.assertIn("+linkease-app-entry", makefile)
        self.assertIn("PKG_RELEASE:=2", meta)
        self.assertIn("META_LUCI_ENTRY:=/cgi-bin/luci/admin/services/agentflow", meta)
        self.assertIn('entry({"admin", "services", "agentflow", "open"}', controller)
        self.assertIn("open.sysauth = false", controller)
        self.assertIn("function agentflow_open()", controller)
        self.assertIn('compat():open("agentflow")', controller)
        self.assertIn('compat():legacy_status("agentflow"', controller)
        self.assertIn('http = require "luci.http"', controller)
        self.assertIn('resolver = require("luci.model.linkease.apps_openwrt").new()', controller)
        self.assertIn('auth_url = dispatcher.build_url("admin", "services", "linkease_auth", "auth")', controller)
        self.assertNotIn("uhttpd_apps_proxy_available", controller)
        self.assertNotIn("linkeasefull_running", controller)
        self.assertIn('url("admin/services/agentflow/open")', status)
        self.assertNotIn('window.location.hostname + ":" + st.port', status)

    def test_app_meta_autoconfigures_agentflow_and_exposes_management_entry(self):
        meta = META_MAKEFILE.read_text(encoding="utf-8")
        config = (META_DIR / "config.sh").read_text(encoding="utf-8")
        entry = (META_DIR / "entry.sh").read_text(encoding="utf-8")

        self.assertIn("META_AUTOCONF:=path enable", meta)
        self.assertIn('[ -n "$ISTORE_CONF_DIR" ] || exit 1', config)
        self.assertIn('data_dir="$ISTORE_CONF_DIR/AgentFlow"', config)
        self.assertIn('set agentflow.@agentflow[0].enabled="$enabled"', config)
        self.assertIn('set agentflow.@agentflow[0].data_dir="$data_dir"', config)
        self.assertIn('ISTORE_DONT_START', config)
        self.assertIn('if [ "$enabled" = "1" ]; then', config)
        self.assertIn('/etc/init.d/agentflow restart', config)
        self.assertIn('/etc/init.d/agentflow stop || true', config)
        self.assertNotIn('/etc/init.d/agentflow restart || true', config)

        self.assertIn('json_add_string "app" "agentflow"', entry)
        self.assertIn('json_add_boolean "docker" "0"', entry)
        self.assertIn('pidof agentflow', entry)
        self.assertIn('json_add_string "web" ":${port}${base_path}"', entry)
        self.assertIn(
            'json_add_string "href" "/cgi-bin/luci/admin/services/agentflow"',
            entry,
        )
        self.assertIn('/etc/init.d/agentflow start', entry)
        self.assertIn('/etc/init.d/agentflow stop', entry)
        self.assertNotIn("linkease_apps/open", entry)

    def test_app_meta_and_desktop_icons_have_single_owners(self):
        manifest = json.loads(
            (RUNTIME_DIR / "files/agentflow-plugin.json").read_text(encoding="utf-8")
        )
        self.assertEqual(manifest["id"], "agentflow")
        self.assertEqual(manifest["icon"], "logo.svg")
        self.assertEqual(manifest["staticRoot"], "/usr/share/agentflow/www")
        self.assertTrue((RUNTIME_DIR / "files/www/logo.svg").is_file())

        meta_logo = META_DIR / "logo.png"
        self.assertTrue(meta_logo.is_file())
        self.assertTrue(meta_logo.read_bytes().startswith(b"\x89PNG\r\n\x1a\n"))
        self.assertFalse(
            (META_DIR / "root/usr/share/linkeasefull/desktop-apps.d").exists(),
            "agentflow runtime already owns the desktop manifest",
        )

if __name__ == "__main__":
    unittest.main()
