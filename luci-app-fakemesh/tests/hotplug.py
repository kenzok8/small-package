"""Run with python3 luci-app-fakemesh/tests/hotplug.py; requires BusyBox and flock."""
import os
import re
import shlex
import subprocess
import tempfile
from pathlib import Path

source = (Path(__file__).parent / "../root/etc/hotplug.d/iface/19-fakemesh").read_text()
function = re.search(r"(?ms)^schedule_umdns_reload\(\)\n\{\n.*?^\}", source).group()

with tempfile.TemporaryDirectory(prefix="fakemesh-hotplug-") as temporary:
    directory = Path(temporary)
    service = directory / "umdns"
    service.write_text("""#!/bin/sh
if [ -e /proc/$$/fd/8 ]; then
    echo inherited >> "$FAKEMESH_TEST_DIR/leaks"
    exit 1
fi
case "$1" in
    enabled) [ ! -f "$FAKEMESH_TEST_DIR/disabled" ] ;;
    reload) echo reload >> "$FAKEMESH_TEST_DIR/reloads" ;;
esac
""")
    service.chmod(0o755)
    function = function.replace("/var/lock/fakemesh-umdns-reload.lock", shlex.quote(str(directory / "lock")))
    function = function.replace("/etc/init.d/umdns", shlex.quote(str(service)))
    # Shorten only the wait; execute the production locking and service calls.
    script = "sleep() { [ \"$1\" = 60 ] || exit 1; command sleep 0.3; }\n" + function
    environment = dict(os.environ, FAKEMESH_TEST_DIR=str(directory))

    def burst():
        subprocess.run(
            ["busybox", "ash", "-c", script + "\nfor event in 1 2 3 4 5 6 7 8 9 10 11 12; do schedule_umdns_reload; done\n"],
            env=environment, capture_output=True, check=True, timeout=10,
        )

    burst()
    assert (directory / "reloads").read_text().splitlines() == ["reload"]
    burst()
    assert (directory / "reloads").read_text().splitlines() == ["reload", "reload"]
    (directory / "disabled").touch()
    burst()
    assert len((directory / "reloads").read_text().splitlines()) == 2
    assert not (directory / "leaks").exists()

print("Hotplug checks passed: burst coalescing, lock release, disabled service, no inherited lock FD.")
