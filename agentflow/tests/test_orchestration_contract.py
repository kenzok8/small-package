from pathlib import Path
import subprocess
import unittest


APP = Path(__file__).resolve().parents[1]


class AgentFlowOrchestrationContractTest(unittest.TestCase):
    def read(self, relative):
        return (APP / relative).read_text(encoding="utf-8")

    def test_package_has_no_private_cli_runtime(self):
        recipe = self.read("Makefile")
        self.assertIn("AGENTFLOW_HASH_x86_64:=496c1c67b4a77c2dba24fba9f49f9cccc1d4e0d0fb7aa7759cf1822bc5fdfd31", recipe)
        self.assertIn("AGENTFLOW_HASH_aarch64:=4f11062649cc048b12545df635ea68c6ec3dd9113ffd34c47f21076649bfa8aa", recipe)
        self.assertNotIn("+mise-runtime", recipe)
        self.assertNotIn("agentflow-runtime", recipe)
        self.assertNotIn("agentflow-agents.lua", recipe)
        for name in ("agentflow-runtime", "agentflow-runtime.lua", "agentflow-agents.lua", "runtime-cli.lua"):
            self.assertFalse((APP / "files" / name).exists(), name)

    def test_service_uses_system_providers_and_private_home(self):
        init = self.read("files/agentflow.init")
        config = self.read("files/agentflow.config")
        self.assertIn("option home_dir ''", config)
        self.assertIn('host=127.0.0.1', init)
        self.assertIn('PATH="/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"', init)
        self.assertIn('"AGENTFLOW_PROVIDER_MODE=1"', init)
        self.assertIn('prepare_private_dir "$home_dir"', init)
        self.assertNotIn("/.runtime/bin", init)
        self.assertNotIn("mise", init.lower())
        self.assertNotIn("chmod -R", init)
        self.assertNotIn("chgrp", init)
        subprocess.run(["sh", "-n", str(APP / "files/agentflow.init")], check=True)

    def test_upgrade_preserves_legacy_data(self):
        migration = self.read("files/agentflow.uci-default")
        self.assertIn('data_dir/.runtime', migration)
        self.assertIn('home_dir="$legacy_home"', migration)
        self.assertNotIn("rm -rf", migration)
        self.assertNotIn("rm -r", migration)
        subprocess.run(["sh", "-n", str(APP / "files/agentflow.uci-default")], check=True)


if __name__ == "__main__":
    unittest.main()
