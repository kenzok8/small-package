from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "Auto update v2.yml"
MAKEFILE = ROOT / "shadowsocks-libev" / "Makefile"


class ShadowsocksLibevWorkflowTest(unittest.TestCase):
    def test_hash_uses_openwrt_sdk_download_and_check(self):
        workflow = WORKFLOW.read_text()

        self.assertIn("ss_libev_hash", workflow)
        self.assertIn("make package/feeds/ss_libev_hash/shadowsocks-libev/download", workflow)
        self.assertIn("make package/feeds/ss_libev_hash/shadowsocks-libev/check", workflow)
        self.assertIn("DOWNLOAD_MIRROR=0", workflow)
        self.assertIn(
            "PKG_MIRROR_HASH:=0000000000000000000000000000000000000000000000000000000000000000",
            workflow,
        )
        self.assertNotIn("git archive --format=tar HEAD", workflow)


    def test_same_version_still_recomputes_hash(self):
        workflow = WORKFLOW.read_text()

        same_version_block = (
            'if [ "$OLD_VER" = "$NEW_VER" ] && [ "$OLD_COMMIT" = "$NEW_COMMIT" ]; then\n'
            '            echo "status=failure"'
        )
        self.assertNotIn(same_version_block, workflow)
        self.assertIn('echo "old_hash=$OLD_HASH" >> $GITHUB_OUTPUT', workflow)


    def test_current_hash_matches_openwrt_check_log(self):
        makefile = MAKEFILE.read_text()

        self.assertIn(
            "PKG_MIRROR_HASH:=96d0b486a0c8dbb2acf2af56534f6c765565c127c3695c98b5157b24993a4839",
            makefile,
        )


if __name__ == "__main__":
    unittest.main()
