from pathlib import Path
import unittest


APP_DIR = Path(__file__).resolve().parents[1]


class AgentFlowLuciOpenContractTest(unittest.TestCase):
    def read(self, relative):
        return (APP_DIR / relative).read_text(encoding="utf-8")

    def test_luci_open_matches_linkease_proxy_pattern(self):
        makefile = self.read("Makefile")
        controller = self.read("luasrc/controller/agentflow.lua")
        status = self.read("luasrc/view/agentflow/status.htm")

        self.assertNotIn("+luci-lib-linkeaseauth", makefile)
        self.assertIn('entry({"admin", "services", "agentflow", "open"}', controller)
        self.assertIn("open.sysauth = false", controller)
        self.assertIn("function agentflow_open()", controller)
        self.assertIn("uhttpd_apps_proxy_available()", controller)
        self.assertIn("linkeasefull_running()", controller)
        self.assertIn("return base_path", controller)
        self.assertIn("url_authority(request_or_lan_host(), port)", controller)
        self.assertIn("http.redirect(entry_url)", controller)
        self.assertNotIn('linkease_auth_url("auth")', controller)
        self.assertIn('url("admin/services/agentflow/open")', status)
        self.assertNotIn('window.location.hostname + ":" + st.port', status)


if __name__ == "__main__":
    unittest.main()
