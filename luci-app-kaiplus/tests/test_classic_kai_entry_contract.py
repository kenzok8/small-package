from pathlib import Path
import unittest


APP_DIR = Path(__file__).resolve().parents[1]


class ClassicKaiEntryContractTest(unittest.TestCase):
    def read(self, relative):
        return (APP_DIR / relative).read_text(encoding="utf-8")

    def test_status_reports_classic_kai_manifest(self):
        controller = self.read("luasrc/controller/kaiplus.lua")

        self.assertIn('fs.access("/usr/share/kai/kai-plugin.json")', controller)
        self.assertIn('fs.access("/usr/lib/lua/luci/controller/kai.lua")', controller)

    def test_entry_opens_kai_luci_and_prompts_to_install_when_missing(self):
        controller = self.read("luasrc/controller/kaiplus.lua")
        status = self.read("luasrc/view/kaiplus/kaiplus_status.htm")

        self.assertNotIn('entry({"admin", "services", "kaiplus", "open_kai"}', controller)
        self.assertIn('url("admin/services/kai")', status)
        self.assertIn("st.kai_installed === true", status)
        self.assertIn("function openClassicKai()", status)
        self.assertIn("Classic KAI is not installed. Install it now?", status)
        self.assertIn("window.location.href = kaiLuciUrl", status)

    def test_missing_kai_starts_taskd_install_and_opens_log(self):
        makefile = self.read("Makefile")
        controller = self.read("luasrc/controller/kaiplus.lua")
        status = self.read("luasrc/view/kaiplus/kaiplus_status.htm")

        self.assertIn("+luci-lib-taskd", makefile)
        self.assertIn('<%+tasks/embed%>', status)
        self.assertIn('entry({"admin", "services", "kaiplus", "install_kai"}', controller)
        self.assertIn("require_post_csrf()", controller)
        self.assertIn("/bin/is-opkg install luci-app-kai", controller)
        self.assertNotIn("app-meta-kai", controller)
        self.assertIn("/etc/init.d/tasks task_add ", controller)
        self.assertIn("window.taskd.show_log", status)
        self.assertIn("token: kaiCsrfToken", status)

    def test_action_buttons_share_one_row(self):
        status = self.read("luasrc/view/kaiplus/kaiplus_status.htm")

        actions = status.index('<div class="kaiplus-actions">')
        kaiplus = status.index('id="kaiplus-open"', actions)
        classic = status.index('id="kaiplus-open-kai"', actions)
        actions_end = status.index("</div>", classic)
        self.assertLess(kaiplus, classic)
        self.assertLess(classic, actions_end)
        self.assertIn("margin: 16px;", status)


if __name__ == "__main__":
    unittest.main()
