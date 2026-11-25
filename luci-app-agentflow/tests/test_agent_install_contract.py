from pathlib import Path
import unittest


APP_DIR = Path(__file__).resolve().parents[1]


class AgentInstallContractTest(unittest.TestCase):
    def read(self, relative):
        return (APP_DIR / relative).read_text(encoding="utf-8")

    def test_luci_loads_task_window_and_starts_whitelisted_installer(self):
        makefile = self.read("Makefile")
        controller = self.read("luasrc/controller/agentflow.lua")
        status = self.read("luasrc/view/agentflow/status.htm")

        self.assertIn("+luci-lib-taskd", makefile)
        self.assertIn('<%+tasks/embed%>', status)
        for agent in ("codexcli", "claude-code", "opencode", "kimi", "reasonix"):
            self.assertIn(f'id="agentflow-agent-{agent}"', status)
            self.assertIn(f"agentflowAgentDialog(true, '{agent}')", status)
        self.assertNotIn('<select id="agentflow-agent-select"', status)
        self.assertNotIn("<h4>", status)
        self.assertEqual(status.count('class="agentflow-agent-title"'), 5)
        self.assertNotIn("Update", status)
        self.assertNotIn("Uninstall", status)
        self.assertIn('id="agentflow-open"', status)
        self.assertIn('id="agentflow-agent-install-now"', status)
        self.assertIn("agentflowSelectedAgent", status)
        self.assertIn("window.taskd.show_log(data.task_id", status)
        self.assertNotIn('local token =', status)
        self.assertIn("window.taskd.csrfToken", status)
        self.assertIn("token: agentflowCsrfToken", status)
        self.assertIn('http.formvalue("agent")', controller)
        for agent in ("codexcli", "claude-code", "opencode", "kimi", "reasonix"):
            self.assertIn(f'id = "{agent}"', controller)
        self.assertIn('supported_agents[supported_agent.id] = true', controller)
        self.assertIn('context.authtoken or context.token', controller)
        self.assertIn('http.formvalue("token") ~= expected', controller)
        self.assertIn('/etc/init.d/tasks task_add ', controller)
        self.assertIn('task_id = "agentflow-agent-install"', controller)

    def test_status_uses_application_owned_fixed_runtime(self):
        controller = self.read("luasrc/controller/agentflow.lua")
        status = self.read("luasrc/view/agentflow/status.htm")
        self.assertIn("/usr/libexec/agentflow-runtime status", controller)
        self.assertNotIn("node@lts", controller)
        self.assertNotIn(".local/share/mise/shims", controller)
        self.assertIn("runtime = state.runtime", controller)
        self.assertIn("st.agents_available", status)
        self.assertIn("item.installed === true", status)
        self.assertIn("agentflow-runtime-status", status)
        self.assertIn("runtime.glibc", status)
        self.assertIn("runtime.home", status)

    def test_modal_theme_prefers_body_attribute_then_system_theme(self):
        status = self.read("luasrc/view/agentflow/status.htm")

        self.assertIn('body[theme="dark"] .agentflow-shell', status)
        self.assertIn('@media (prefers-color-scheme: dark)', status)
        self.assertIn('body:not([theme]) .agentflow-shell', status)

    def test_controller_uses_local_runtime_task_without_remote_script_or_global_mise(self):
        controller = self.read("luasrc/controller/agentflow.lua")
        self.assertNotIn("installapp-mise.sh", controller)
        self.assertNotIn("installer_url", controller)
        self.assertNotIn("node@lts", controller)
        self.assertIn("/usr/libexec/agentflow-runtime install ", controller)
        self.assertIn("/.runtime/work/install-agent-", controller)
        self.assertIn("fs.lstat(task_script)", controller)
        self.assertIn("fs.writefile(task_script", controller)
        self.assertIn('local command = "/bin/sh "', controller)
        self.assertIn('object = "luci-app-agentflow"', controller)



if __name__ == "__main__":
    unittest.main()
