from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
APPLICATIONS = ROOT / "applications"


def read(relative):
    return (APPLICATIONS / relative).read_text()


class MiseRuntimeContractTest(unittest.TestCase):
    def test_mise_package_installs_shared_runtime_contract(self):
        makefile = read("mise/Makefile")
        config = read("mise/files/mise.config")
        defaults = read("mise/files/mise.uci-default")
        helper = read("mise/files/istore_runtime.sh")

        self.assertIn("/etc/config/mise", makefile)
        self.assertIn("/lib/functions/istore_runtime.sh", makefile)
        self.assertIn("$(INSTALL_BIN) ./files/mise.uci-default", makefile)
        self.assertIn("[ -f /etc/uci-defaults/mise ]", makefile)

        self.assertIn("config mise 'main'", config)
        self.assertIn("option runtime_dir ''", config)
        self.assertIn("option auto_discover '1'", config)

        self.assertIn(". /lib/functions/istore_runtime.sh", defaults)
        self.assertIn("istore_runtime_init", defaults)

        self.assertIn("config_get conf_dir main conf_dir", helper)
        self.assertIn('"$conf_dir" "$ISTORE_RUNTIME_DEFAULT_SUBDIR"', helper)
        self.assertIn("ISTORE_RUNTIME_HOME_SUBDIR=\"home\"", helper)
        self.assertIn("ISTORE_RUNTIME_CONF_DIR", helper)
        self.assertIn('export HOME="$runtime_home"', helper)
        self.assertIn('export XDG_DATA_HOME="$HOME/.local/share"', helper)
        self.assertIn('export MISE_DATA_DIR="$XDG_DATA_HOME/mise"', helper)
        self.assertIn('export PATH="$MISE_DATA_DIR/shims:$HOME/.local/bin:$PATH"', helper)

    def test_agentflow_consumes_shared_runtime_home(self):
        init = read("agentflow/files/agentflow.init")
        cbi = read("luci-app-agentflow/luasrc/model/cbi/agentflow.lua")
        model = read("luci-app-agentflow/luasrc/model/agentflow.lua")
        translations = read("luci-app-agentflow/po/zh-cn/agentflow.po")

        self.assertIn(". /lib/functions/istore_runtime.sh", init)
        self.assertIn("istore_runtime_export_env", init)
        self.assertIn('AGENT_FLOW_DATA=$data_dir/data', init)
        self.assertIn('HOME=$HOME', init)
        self.assertIn('MISE_DATA_DIR=$MISE_DATA_DIR', init)
        self.assertNotIn("$data_dir/global", init)
        self.assertNotIn(".local/share/mise/shims:$PATH", init)

        self.assertIn('translate("Shared runtime home")', cbi)
        self.assertIn("agentflow_model.runtime_home", cbi)
        self.assertIn('return runtime_dir .. "/home"', model)
        self.assertIn('return conf_dir .. "/Runtime"', model)

        self.assertIn('msgid "Shared runtime home"', translations)
        self.assertIn('msgstr "共享运行时 HOME"', translations)


if __name__ == "__main__":
    unittest.main()
