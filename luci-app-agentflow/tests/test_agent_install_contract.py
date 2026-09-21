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

    def test_status_reports_installed_agents_from_shared_mise_runtime(self):
        controller = self.read("luasrc/controller/agentflow.lua")
        status = self.read("luasrc/view/agentflow/status.htm")

        self.assertIn("istore_runtime_env", controller)
        self.assertIn('where node@lts', controller)
        for package in (
            "@openai/codex",
            "@anthropic-ai/claude-code",
            "opencode-ai",
            "@moonshot-ai/kimi-code",
            "reasonix",
        ):
            self.assertIn(f'package = "{package}"', controller)
        self.assertIn('status.version = package_json.version', controller)
        self.assertIn('agents_available = agents_available', controller)
        self.assertIn('st.agents_available', status)
        self.assertIn('item.installed === true', status)
        self.assertIn('installButton.disabled = !available || installed', status)
        self.assertIn('installed ? agentflowLabels.installed : agentflowLabels.install', status)

    def test_modal_theme_prefers_body_attribute_then_system_theme(self):
        status = self.read("luasrc/view/agentflow/status.htm")

        self.assertIn('body[theme="dark"] .agentflow-shell', status)
        self.assertIn('@media (prefers-color-scheme: dark)', status)
        self.assertIn('body:not([theme]) .agentflow-shell', status)

    def test_controller_runs_remote_installer_inside_taskd(self):
        controller = self.read("luasrc/controller/agentflow.lua")

        self.assertFalse((APP_DIR / "root/usr/libexec/istorec/agentflow-agent.sh").exists())
        self.assertNotIn("/usr/libexec/istorec/agentflow-agent.sh", controller)
        self.assertIn("installapp/installapp-mise.sh", controller)
        self.assertIn("istore_runtime_env", controller)
        self.assertIn('wget -O "$installer" "$installer_url"', controller)
        self.assertIn('/bin/sh "$installer" "$agent"', controller)
        self.assertIn('task_script = "/tmp/agentflow-agent-install.sh"', controller)
        self.assertIn("fs.writefile(task_script", controller)
        self.assertIn('rm -f "$installer" "$0"', controller)
        self.assertIn('local command = "/bin/sh "', controller)
        self.assertNotIn('local command = "/bin/sh -c "', controller)
        self.assertLess(controller.index("istore_runtime_env"), controller.index('"set -u"'))


if __name__ == "__main__":
    unittest.main()
