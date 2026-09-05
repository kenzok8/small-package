import json
import pathlib
import unittest


APP_DIR = pathlib.Path(__file__).resolve().parents[1]


class DesktopManifestContractTest(unittest.TestCase):
    def setUp(self):
        self.manifest = json.loads(
            (APP_DIR / "files" / "agentflow-plugin.json").read_text()
        )

    def test_manifest_uses_agentflow_app_base_proxy(self):
        self.assertEqual(self.manifest["id"], "agentflow")
        self.assertEqual(self.manifest["staticRoot"], "/usr/share/agentflow/www")
        self.assertEqual(self.manifest["standalone"]["entry"], "index.html")
        self.assertEqual(self.manifest["standalone"]["basePath"], "/apps/agentflow/")
        self.assertEqual(
            self.manifest["standalone"]["url"],
            "/cgi-bin/luci/admin/services/agentflow/open",
        )
        self.assertEqual(
            self.manifest["standalone"]["externalOpen"],
            {"enabled": True, "label": "Open AgentFlow"},
        )
        self.assertEqual(self.manifest["auth"]["mode"], "passthrough")

        backend = self.manifest["backend"]
        self.assertEqual(backend["upstreamBasePath"], "/apps/agentflow/")
        self.assertEqual(backend["pathMode"], "preserve")
        self.assertEqual(backend["proxyMode"], "app-base")

    def test_desktop_entry_matches_manifest_contract(self):
        desktop = self.manifest["desktop"]
        self.assertEqual(desktop["mode"], "module")
        self.assertEqual(desktop["entry"], "desktop-entry.js")
        self.assertEqual(desktop["isolation"], "shadow-dom")

        self.assertFalse(
            (APP_DIR / "files" / "www" / "desktop-entry.js").exists(),
            "desktop-entry.js must be served by AgentFlow backend, not the static iframe wrapper",
        )


if __name__ == "__main__":
    unittest.main()
