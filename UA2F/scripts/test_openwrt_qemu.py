#!/usr/bin/env python3
"""Boot OpenWrt in QEMU and exercise UA2F as a real routed package."""

import argparse
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import time
import uuid

import pexpect


TEST_USER_AGENT = "UA2F-OpenWrt-QEMU/1.0"
GUEST_PROMPT = re.compile(r"root@[^:\r\n]+:[^#\r\n]*# ")


class OpenWrtQemuTest:
    def __init__(
        self,
        image,
        package,
        expected_version,
        log_path,
        boot_timeout,
        coverage_archive=None,
    ):
        self.image = Path(image).resolve()
        self.package = Path(package).resolve()
        self.expected_version = expected_version
        self.log_path = Path(log_path).resolve()
        self.boot_timeout = boot_timeout
        self.coverage_archive = (
            Path(coverage_archive).resolve() if coverage_archive is not None else None
        )
        self.helper = Path(__file__).with_name("http_test_endpoint.py").resolve()

        suffix = f"{os.getpid():x}"[-5:]
        self.client_ns = f"ua2f-qemu-client-{suffix}"
        self.origin_ns = f"ua2f-qemu-origin-{suffix}"
        self.lan_bridge = f"u2b{suffix}l"
        self.wan_bridge = f"u2b{suffix}w"
        self.lan_tap = f"u2t{suffix}l"
        self.wan_tap = f"u2t{suffix}w"
        self.client_if = f"u2c{suffix}"
        self.client_host_if = f"u2h{suffix}l"
        self.origin_if = f"u2o{suffix}"
        self.origin_host_if = f"u2h{suffix}w"

        self.work_dir = None
        self.qemu = None
        self.qemu_log = None
        self.package_server = None
        self.origin_server = None
        self.package_server_port = None

    @staticmethod
    def _run(command, check=True, capture=False, timeout=60):
        result = subprocess.run(
            [str(part) for part in command],
            check=False,
            text=True,
            stdout=subprocess.PIPE if capture else subprocess.DEVNULL,
            stderr=subprocess.STDOUT if capture else subprocess.DEVNULL,
            timeout=timeout,
        )
        if check and result.returncode != 0:
            output = result.stdout.strip() if result.stdout else ""
            raise RuntimeError(f"command failed ({result.returncode}): {' '.join(map(str, command))}\n{output}")
        return result

    def _ns_run(self, namespace, command, check=True, capture=False, timeout=60):
        return self._run(
            ["ip", "netns", "exec", namespace, *command],
            check=check,
            capture=capture,
            timeout=timeout,
        )

    def preflight(self):
        if os.name != "posix" or os.geteuid() != 0:
            raise RuntimeError("test_openwrt_qemu.py requires Linux root privileges")
        if not self.image.is_file():
            raise RuntimeError(f"OpenWrt image not found: {self.image}")
        if not self.package.is_file():
            raise RuntimeError(f"UA2F package not found: {self.package}")
        if self.package.suffix not in (".ipk", ".apk"):
            raise RuntimeError(f"unsupported OpenWrt package format: {self.package.suffix}")
        if not self.helper.is_file():
            raise RuntimeError(f"HTTP test helper not found: {self.helper}")
        for executable in ("ip", "qemu-img", "qemu-system-x86_64"):
            if shutil.which(executable) is None:
                raise RuntimeError(f"required executable not found: {executable}")

    def setup_network(self):
        for namespace in (self.client_ns, self.origin_ns):
            self._run(["ip", "netns", "add", namespace])
            self._run(["ip", "-n", namespace, "link", "set", "lo", "up"])

        for bridge in (self.lan_bridge, self.wan_bridge):
            self._run(["ip", "link", "add", bridge, "type", "bridge"])
            self._run(["ip", "link", "set", bridge, "up"])

        for tap, bridge in ((self.lan_tap, self.lan_bridge), (self.wan_tap, self.wan_bridge)):
            self._run(["ip", "tuntap", "add", "dev", tap, "mode", "tap"])
            self._run(["ip", "link", "set", tap, "master", bridge])
            self._run(["ip", "link", "set", tap, "up"])

        self._run(
            ["ip", "link", "add", self.client_if, "type", "veth", "peer", "name", self.client_host_if]
        )
        self._run(["ip", "link", "set", self.client_if, "netns", self.client_ns])
        self._run(["ip", "link", "set", self.client_host_if, "master", self.lan_bridge])
        self._run(["ip", "link", "set", self.client_host_if, "up"])
        self._run(["ip", "-n", self.client_ns, "addr", "add", "10.242.1.2/24", "dev", self.client_if])
        self._run(["ip", "-n", self.client_ns, "link", "set", self.client_if, "up"])
        self._run(["ip", "-n", self.client_ns, "route", "add", "default", "via", "10.242.1.1"])

        self._run(
            ["ip", "link", "add", self.origin_if, "type", "veth", "peer", "name", self.origin_host_if]
        )
        self._run(["ip", "link", "set", self.origin_if, "netns", self.origin_ns])
        self._run(["ip", "link", "set", self.origin_host_if, "master", self.wan_bridge])
        self._run(["ip", "link", "set", self.origin_host_if, "up"])
        self._run(["ip", "-n", self.origin_ns, "addr", "add", "10.242.2.2/24", "dev", self.origin_if])
        self._run(["ip", "-n", self.origin_ns, "link", "set", self.origin_if, "up"])
        self._run(["ip", "-n", self.origin_ns, "route", "add", "default", "via", "10.242.2.1"])

    @staticmethod
    def _available_tcp_port():
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.bind(("127.0.0.1", 0))
            return sock.getsockname()[1]

    def start_host_services(self):
        self.package_server_port = self._available_tcp_port()
        self.package_server = subprocess.Popen(
            [
                sys.executable,
                "-m",
                "http.server",
                str(self.package_server_port),
                "--bind",
                "0.0.0.0",
                "--directory",
                str(self.package.parent),
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.STDOUT,
        )
        self.origin_server = subprocess.Popen(
            [
                "ip",
                "netns",
                "exec",
                self.origin_ns,
                sys.executable,
                str(self.helper),
                "serve",
                "--port",
                "80",
                "--port",
                "443",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.STDOUT,
        )
        time.sleep(0.5)
        if self.package_server.poll() is not None:
            raise RuntimeError("package HTTP server exited during startup")
        if self.origin_server.poll() is not None:
            raise RuntimeError("origin HTTP server exited during startup")

    def start_qemu(self):
        self.work_dir = tempfile.TemporaryDirectory(prefix="ua2f-openwrt-qemu-")
        overlay = Path(self.work_dir.name) / "openwrt-overlay.qcow2"
        self._run(
            [
                "qemu-img",
                "create",
                "-q",
                "-f",
                "qcow2",
                "-F",
                "raw",
                "-b",
                str(self.image),
                str(overlay),
            ]
        )

        acceleration = ["-accel", "tcg,thread=multi", "-cpu", "max"]
        kvm = Path("/dev/kvm")
        if kvm.exists() and os.access(kvm, os.R_OK | os.W_OK):
            acceleration = ["-accel", "kvm", "-cpu", "host"]

        command = [
            "qemu-system-x86_64",
            "-name",
            "ua2f-openwrt-ci",
            "-m",
            "512",
            "-smp",
            "2",
            "-no-reboot",
            "-nographic",
            "-monitor",
            "none",
            "-nic",
            "none",
            *acceleration,
            "-drive",
            f"file={overlay},format=qcow2,if=virtio",
            "-netdev",
            f"tap,id=lan,ifname={self.lan_tap},script=no,downscript=no",
            "-device",
            "virtio-net-pci,netdev=lan,mac=52:54:00:2a:01:01",
            "-netdev",
            f"tap,id=wan,ifname={self.wan_tap},script=no,downscript=no",
            "-device",
            "virtio-net-pci,netdev=wan,mac=52:54:00:2a:02:01",
            "-netdev",
            "user,id=mgmt",
            "-device",
            "virtio-net-pci,netdev=mgmt,mac=52:54:00:2a:03:01",
        ]

        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        self.qemu_log = self.log_path.open("w", encoding="utf-8", errors="replace")
        self.qemu = pexpect.spawn(command[0], command[1:], encoding="utf-8", codec_errors="replace", timeout=30)
        self.qemu.logfile = self.qemu_log
        self._wait_for_shell()

    def _wait_for_shell(self):
        deadline = time.monotonic() + self.boot_timeout
        while time.monotonic() < deadline:
            timeout = max(1, min(30, int(deadline - time.monotonic())))
            matched = self.qemu.expect(
                [r"Please press Enter to activate this console", GUEST_PROMPT, pexpect.TIMEOUT, pexpect.EOF],
                timeout=timeout,
            )
            if matched == 0:
                self.qemu.sendline("")
            elif matched == 1:
                return
            elif matched == 3:
                raise RuntimeError("QEMU exited before the OpenWrt shell became ready")
        raise RuntimeError(f"OpenWrt did not boot within {self.boot_timeout} seconds")

    def guest_command(self, command, check=True, timeout=120):
        marker = f"__UA2F_RC_{uuid.uuid4().hex}__"
        self.qemu.sendline(f"{command}; ua2f_status=$?; echo {marker}$ua2f_status")
        self.qemu.expect(re.escape(marker) + r"([0-9]+)", timeout=timeout)
        output = self.qemu.before
        status = int(self.qemu.match.group(1))
        self.qemu.expect(GUEST_PROMPT, timeout=30)
        if check and status != 0:
            raise RuntimeError(f"guest command failed ({status}): {command}\n{output}")
        return status, output

    def configure_openwrt(self):
        print("[qemu] configuring OpenWrt LAN, WAN, management, and firewall", flush=True)
        self.guest_command("ubus wait_for network.interface", timeout=120)
        self.guest_command("sleep 3")
        commands = (
            "uci -q delete network.lan || true",
            "uci set network.lan=interface",
            "uci set network.lan.device=eth0",
            "uci set network.lan.proto=static",
            "uci set network.lan.ipaddr=10.242.1.1",
            "uci set network.lan.netmask=255.255.255.0",
            "uci -q delete network.wan || true",
            "uci set network.wan=interface",
            "uci set network.wan.device=eth1",
            "uci set network.wan.proto=static",
            "uci set network.wan.ipaddr=10.242.2.1",
            "uci set network.wan.netmask=255.255.255.0",
            "uci -q delete network.wan6 || true",
            "uci set network.mgmt=interface",
            "uci set network.mgmt.device=eth2",
            "uci set network.mgmt.proto=dhcp",
            "uci commit network",
            "/etc/init.d/network restart",
            "sleep 8",
            "uci set firewall.@zone[0].network=lan",
            "uci set firewall.@zone[1].network='wan mgmt'",
            "uci set firewall.@forwarding[0].src=lan",
            "uci set firewall.@forwarding[0].dest=wan",
            "uci commit firewall",
            "/etc/init.d/firewall restart",
            "sleep 3",
        )
        for command in commands:
            self.guest_command(command)

        self.guest_command("ip -4 addr show dev eth0")
        self.guest_command("ip -4 addr show dev eth1")
        self.guest_command("ip -4 addr show dev eth2")
        self.guest_command("ping -c 1 -W 3 10.242.1.2")
        self.guest_command("ping -c 1 -W 3 10.242.2.2")

    def install_package(self):
        print(f"[qemu] installing the freshly built UA2F {self.package.suffix}", flush=True)
        package_url = (
            f"http://10.0.2.2:{self.package_server_port}/"
            f"{shlex.quote(self.package.name)}"
        )
        remote_package = f"/tmp/ua2f{self.package.suffix}"
        if self.package.suffix == ".apk":
            self.guest_command("apk update", timeout=600)
            self.guest_command(f"wget -O {remote_package} {package_url}", timeout=120)
            self.guest_command(f"apk add --allow-untrusted {remote_package}", timeout=600)
            self.guest_command("apk info -e ua2f")
        else:
            self.guest_command("opkg update", timeout=600)
            self.guest_command(f"wget -O {remote_package} {package_url}", timeout=120)
            self.guest_command(f"opkg install {remote_package}", timeout=600)
            self.guest_command("opkg status ua2f | grep -q 'Status: install user installed'")
        _, output = self.guest_command("/usr/bin/ua2f --version")
        if self.expected_version not in output:
            raise AssertionError(
                f"installed UA2F version did not contain {self.expected_version!r}:\n{output}"
            )
        if self.coverage_archive is not None:
            self.guest_command("rm -rf /tmp/ua2f-gcov")
            self.guest_command(
                "uci set ua2f.main.gcov_prefix=/tmp/ua2f-gcov && uci commit ua2f"
            )

    def probe(self, port=80, requests=1):
        result = self._ns_run(
            self.client_ns,
            [
                sys.executable,
                str(self.helper),
                "probe",
                "--host",
                "10.242.2.2",
                "--port",
                str(port),
                "--requests",
                str(requests),
                "--path",
                "/openwrt?padding=32768",
                "--user-agent",
                TEST_USER_AGENT,
                "--timeout",
                "15",
            ],
            capture=True,
            timeout=60,
        )
        return json.loads(result.stdout)

    @staticmethod
    def assert_user_agent(responses, expected, label):
        for index, response in enumerate(responses):
            if response["user_agent"] != expected:
                raise AssertionError(
                    f"{label} response {index}: expected {expected!r}, got {response['user_agent']!r}"
                )
            if len(response["padding"]) != 32768:
                raise AssertionError(f"{label} response {index}: response body was truncated")

    def exercise_mode(self, mode):
        print(f"[qemu] testing OpenWrt init/firewall mode {mode}", flush=True)
        configure = (
            "uci set ua2f.enabled.enabled=1 && "
            "uci set ua2f.firewall.handle_fw=1 && "
            "uci set ua2f.firewall.handle_tls=0 && "
            "uci set ua2f.firewall.handle_intranet=1 && "
            f"uci set ua2f.main.mode={mode} && "
            "uci set ua2f.main.nfqueue_workers=2 && "
            "uci set ua2f.main.proxy_workers=2 && "
            "uci commit ua2f"
        )
        self.guest_command(configure)
        self.guest_command("/etc/init.d/ua2f restart", timeout=60)
        self.guest_command("sleep 2")
        self.guest_command("/etc/init.d/ua2f running")
        self.guest_command("nft list table inet ua2f")

        # A second restart catches duplicate nft chains and stale TPROXY policy routes.
        self.guest_command("/etc/init.d/ua2f restart", timeout=60)
        self.guest_command("sleep 2")
        self.guest_command("/etc/init.d/ua2f running")

        rewritten = self.probe(requests=3)
        self.assert_user_agent(rewritten, "F" * len(TEST_USER_AGENT), f"{mode} port 80")
        bypassed = self.probe(port=443)
        self.assert_user_agent(bypassed, TEST_USER_AGENT, f"{mode} port 443 bypass")

    def stop_and_verify_cleanup(self):
        self.guest_command("/etc/init.d/ua2f stop")
        self.guest_command("sleep 1")
        status, _ = self.guest_command("nft list table inet ua2f >/dev/null 2>&1", check=False)
        if status == 0:
            raise AssertionError("UA2F nft table remained after stopping the service")

    def export_coverage(self):
        if self.coverage_archive is None:
            return

        print("[qemu] exporting OpenWrt gcov data", flush=True)
        guest_archive = "/tmp/ua2f-gcov.tar.gz"
        self.guest_command(
            "test \"$(find /tmp/ua2f-gcov -name '*.gcda' | wc -l)\" -gt 0"
        )
        self.guest_command("sync")
        self.guest_command(
            f"tar -C /tmp/ua2f-gcov -czf {guest_archive} .", timeout=120
        )

        begin = f"__UA2F_GCOV_BEGIN_{uuid.uuid4().hex}__"
        end = f"__UA2F_GCOV_END_{uuid.uuid4().hex}__"
        _, output = self.guest_command(
            f"echo {begin}; hexdump -ve '1/1 \"%02x\"' {guest_archive}; "
            f"echo; echo {end}",
            timeout=120,
        )
        normalized = output.replace("\r", "")
        match = re.search(
            rf"^{re.escape(begin)}\n(?P<payload>.*?)^{re.escape(end)}$",
            normalized,
            flags=re.MULTILINE | re.DOTALL,
        )
        if match is None:
            raise RuntimeError("could not locate gcov archive markers in serial output")

        payload = "".join(match.group("payload").split())
        try:
            archive = bytes.fromhex(payload)
        except ValueError as error:
            raise RuntimeError("guest returned invalid hexadecimal gcov data") from error
        if not archive.startswith(b"\x1f\x8b"):
            raise RuntimeError("guest gcov archive is not gzip data")

        self.coverage_archive.parent.mkdir(parents=True, exist_ok=True)
        self.coverage_archive.write_bytes(archive)
        print(
            f"[qemu] wrote {len(archive)} bytes to {self.coverage_archive}",
            flush=True,
        )

    @staticmethod
    def _terminate_process(process):
        if process is None or process.poll() is not None:
            return
        process.send_signal(signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)

    def cleanup(self):
        if self.qemu is not None:
            if self.qemu.isalive():
                self.qemu.close(force=True)
            self.qemu = None
        if self.qemu_log is not None:
            self.qemu_log.close()
            self.qemu_log = None
        self._terminate_process(self.origin_server)
        self._terminate_process(self.package_server)
        for namespace in (self.client_ns, self.origin_ns):
            self._run(["ip", "netns", "delete", namespace], check=False)
        for interface in (self.lan_tap, self.wan_tap, self.lan_bridge, self.wan_bridge):
            self._run(["ip", "link", "delete", interface], check=False)
        if self.work_dir is not None:
            self.work_dir.cleanup()
            self.work_dir = None

    def run(self):
        self.preflight()
        try:
            self.setup_network()
            self.start_host_services()
            self.start_qemu()
            self.configure_openwrt()
            self.install_package()
            for mode in ("NFQUEUE", "REDIRECT", "TPROXY"):
                self.exercise_mode(mode)
            self.stop_and_verify_cleanup()
            self.export_coverage()
            print("[qemu] all OpenWrt package and routing tests passed", flush=True)
        finally:
            self.cleanup()


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True, help="decompressed OpenWrt x86_64 combined image")
    parser.add_argument("--package", required=True, help="UA2F x86_64 .ipk or .apk built for the image release")
    parser.add_argument("--expected-version", required=True)
    parser.add_argument("--log", default="openwrt-qemu.log")
    parser.add_argument("--boot-timeout", type=int, default=300)
    parser.add_argument(
        "--coverage-archive",
        help="write a gzip-compressed archive of gcda files collected in the guest",
    )
    return parser.parse_args()


if __name__ == "__main__":
    arguments = parse_args()
    OpenWrtQemuTest(
        arguments.image,
        arguments.package,
        arguments.expected_version,
        arguments.log,
        arguments.boot_timeout,
        arguments.coverage_archive,
    ).run()
