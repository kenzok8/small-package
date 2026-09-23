from pathlib import Path
import unittest


APP_DIR = Path(__file__).resolve().parents[1]


class AgentFlowLuciOpenContractTest(unittest.TestCase):
    def read(self, relative):
        return (APP_DIR / relative).read_text(encoding="utf-8")

    def test_luci_open_delegates_to_shared_apps_entry(self):
        makefile = self.read("Makefile")
        controller = self.read("luasrc/controller/agentflow.lua")
        status = self.read("luasrc/view/agentflow/status.htm")

        self.assertIn("+luci-lib-linkeaseauth", makefile)
        self.assertIn("+linkease-app-entry", makefile)
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


if __name__ == "__main__":
    unittest.main()
