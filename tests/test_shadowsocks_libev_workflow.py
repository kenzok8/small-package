from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "Auto update v2.yml"
MAKEFILE = ROOT / "shadowsocks-libev" / "Makefile"


class ShadowsocksLibevWorkflowTest(unittest.TestCase):
    def test_hash_uses_openwrt_sdk_download_and_check(self):
        workflow = WORKFLOW.read_text()

        self.assertIn("ss_libev_hash", workflow)
        self.assertIn("openwrt/sdk:x86_64-24.10.4", workflow)
        self.assertIn("./scripts/feeds update ss_libev_hash", workflow)
        self.assertIn("./scripts/feeds install -p ss_libev_hash -f shadowsocks-libev", workflow)
        self.assertIn("make package/feeds/ss_libev_hash/shadowsocks-libev/download", workflow)
        self.assertIn("make package/feeds/ss_libev_hash/shadowsocks-libev/check", workflow)
        self.assertIn("DOWNLOAD_MIRROR=0", workflow)
        self.assertIn('sha256sum "$ARCHIVE_PATH"', workflow)
        self.assertIn(
            "PKG_MIRROR_HASH:=0000000000000000000000000000000000000000000000000000000000000000",
            workflow,
        )
        shadowsocks_job = workflow.split("job_auto_update_shadowsocks_libev:", 1)[1]
        self.assertNotIn("git archive", shadowsocks_job)
        self.assertNotIn("TAR_TIMESTAMP", shadowsocks_job)
        self.assertNotIn("zstd -T0", shadowsocks_job)

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

    def test_hash_artifacts_stay_outside_git_workspace(self):
        workflow = WORKFLOW.read_text()

        self.assertIn('HASH_WORK_DIR="$RUNNER_TEMP/shadowsocks-libev-hash"', workflow)
        self.assertIn('-v "$HASH_WORK_DIR:/hashwork"', workflow)
        self.assertNotIn('"$WORK_DIR/shadowsocks-libev-hash.txt"', workflow)
        self.assertNotIn('"$WORK_DIR/shadowsocks-libev_make_download.log"', workflow)

    def test_commit_only_when_shadowsocks_makefile_changed(self):
        workflow = WORKFLOW.read_text().split("job_auto_update_shadowsocks_libev:", 1)[1]

        self.assertIn('git diff --quiet -- shadowsocks-libev/Makefile', workflow)
        self.assertNotIn('if [ -n "$(git status --porcelain)" ]; then', workflow)


if __name__ == "__main__":
    unittest.main()
