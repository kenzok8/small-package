#!/usr/bin/env python3
"""Exercise UA2F as a routed NFQUEUE/REDIRECT/TPROXY middlebox."""

import argparse
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time


PROXY_MARK = "0xc9"
TPROXY_MARK = "0x1c9"
TPROXY_TABLE = "457"
LISTEN_PORT = "10010"
TEST_USER_AGENT = "UA2F-Netns/1.0"
POST_BODY = "User-Agent: this text is an HTTP body and must remain unchanged"


class RoutedIntegrationTest:
    def __init__(self, binary, modes, ipv6=True):
        self.binary = Path(binary).resolve()
        self.modes = modes
        self.ipv6 = ipv6
        suffix = f"{os.getpid():x}"[-5:]
        self.client_ns = f"ua2f-client-{suffix}"
        self.router_ns = f"ua2f-router-{suffix}"
        self.origin_ns = f"ua2f-origin-{suffix}"
        self.client_if = f"u2c{suffix}"
        self.router_lan_if = f"u2l{suffix}"
        self.origin_if = f"u2o{suffix}"
        self.router_wan_if = f"u2w{suffix}"
        self.origin_process = None
        self.ua2f_process = None
        self.ua2f_log = tempfile.NamedTemporaryFile(prefix="ua2f-netns-", suffix=".log", delete=False)
        self.helper = Path(__file__).with_name("http_test_endpoint.py").resolve()

    @staticmethod
    def _run(command, check=True, capture=False):
        result = subprocess.run(
            [str(part) for part in command],
            check=False,
            text=True,
            stdout=subprocess.PIPE if capture else subprocess.DEVNULL,
            stderr=subprocess.STDOUT if capture else subprocess.DEVNULL,
        )
        if check and result.returncode != 0:
            output = result.stdout.strip() if result.stdout else ""
            raise RuntimeError(f"command failed ({result.returncode}): {' '.join(map(str, command))}\n{output}")
        return result

    def _ns_run(self, namespace, command, check=True, capture=False):
        return self._run(["ip", "netns", "exec", namespace, *command], check=check, capture=capture)

    def preflight(self):
        if os.name != "posix" or os.geteuid() != 0:
            raise RuntimeError("test_netns.py requires Linux root privileges")
        if not self.binary.is_file():
            raise RuntimeError(f"UA2F binary not found: {self.binary}")
        for executable in ("ip", "iptables", "ip6tables"):
            if shutil.which(executable) is None:
                raise RuntimeError(f"required executable not found: {executable}")
        for module in ("nfnetlink_queue", "xt_TPROXY", "nf_tproxy_ipv4", "nf_tproxy_ipv6"):
            self._run(["modprobe", module], check=False)

    def setup_network(self):
        for namespace in (self.client_ns, self.router_ns, self.origin_ns):
            self._run(["ip", "netns", "add", namespace])
            self._run(["ip", "-n", namespace, "link", "set", "lo", "up"])

        self._run(["ip", "link", "add", self.client_if, "type", "veth", "peer", "name", self.router_lan_if])
        self._run(["ip", "link", "set", self.client_if, "netns", self.client_ns])
        self._run(["ip", "link", "set", self.router_lan_if, "netns", self.router_ns])
        self._run(["ip", "link", "add", self.origin_if, "type", "veth", "peer", "name", self.router_wan_if])
        self._run(["ip", "link", "set", self.origin_if, "netns", self.origin_ns])
        self._run(["ip", "link", "set", self.router_wan_if, "netns", self.router_ns])

        addresses = (
            (self.client_ns, self.client_if, "10.241.1.2/24"),
            (self.router_ns, self.router_lan_if, "10.241.1.1/24"),
            (self.origin_ns, self.origin_if, "10.241.2.2/24"),
            (self.router_ns, self.router_wan_if, "10.241.2.1/24"),
        )
        for namespace, interface, address in addresses:
            self._run(["ip", "-n", namespace, "addr", "add", address, "dev", interface])
            self._run(["ip", "-n", namespace, "link", "set", interface, "up"])

        self._run(["ip", "-n", self.client_ns, "route", "add", "default", "via", "10.241.1.1"])
        self._run(["ip", "-n", self.origin_ns, "route", "add", "default", "via", "10.241.2.1"])

        if self.ipv6:
            ipv6_addresses = (
                (self.client_ns, self.client_if, "fd42:241:1::2/64"),
                (self.router_ns, self.router_lan_if, "fd42:241:1::1/64"),
                (self.origin_ns, self.origin_if, "fd42:241:2::2/64"),
                (self.router_ns, self.router_wan_if, "fd42:241:2::1/64"),
            )
            for namespace, interface, address in ipv6_addresses:
                self._run(["ip", "-n", namespace, "-6", "addr", "add", address, "dev", interface, "nodad"])
            self._run(["ip", "-n", self.client_ns, "-6", "route", "add", "default", "via", "fd42:241:1::1"])
            self._run(["ip", "-n", self.origin_ns, "-6", "route", "add", "default", "via", "fd42:241:2::1"])

        self._ns_run(self.router_ns, ["sysctl", "-qw", "net.ipv4.ip_forward=1"])
        self._ns_run(self.router_ns, ["sysctl", "-qw", "net.ipv4.conf.all.rp_filter=0"])
        self._ns_run(self.router_ns, ["sysctl", "-qw", "net.ipv4.conf.default.rp_filter=0"])
        if self.ipv6:
            self._ns_run(self.router_ns, ["sysctl", "-qw", "net.ipv6.conf.all.forwarding=1"])

    def start_origin(self):
        command = [
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
        ]
        if self.ipv6:
            command.append("--ipv6")
        self.origin_process = subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)

        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            try:
                result = self.probe("10.241.2.2", user_agent="origin-ready")
                if result[0]["user_agent"] == "origin-ready":
                    return
            except (RuntimeError, json.JSONDecodeError):
                time.sleep(0.2)
        raise RuntimeError("origin HTTP endpoint did not become ready")

    def flush_firewall(self):
        for command in ("iptables", "ip6tables"):
            for table in ("mangle", "nat"):
                self._ns_run(self.router_ns, [command, "-t", table, "-F"], check=False)
                self._ns_run(self.router_ns, [command, "-t", table, "-X"], check=False)
        self._ns_run(
            self.router_ns,
            ["ip", "rule", "del", "fwmark", TPROXY_MARK, "table", TPROXY_TABLE],
            check=False,
        )
        self._ns_run(self.router_ns, ["ip", "route", "flush", "table", TPROXY_TABLE], check=False)
        if self.ipv6:
            self._ns_run(
                self.router_ns,
                ["ip", "-6", "rule", "del", "fwmark", TPROXY_MARK, "table", TPROXY_TABLE],
                check=False,
            )
            self._ns_run(self.router_ns, ["ip", "-6", "route", "flush", "table", TPROXY_TABLE], check=False)

    def setup_firewall(self, mode):
        self.flush_firewall()
        if mode == "NFQUEUE":
            self._ns_run(
                self.router_ns,
                [
                    "iptables", "-t", "mangle", "-A", "POSTROUTING", "-o", self.router_wan_if,
                    "-p", "tcp", "--dport", "80", "-m", "conntrack", "--ctdir", "ORIGINAL",
                    "-j", "NFQUEUE", "--queue-num", "10010",
                ],
            )
            if self.ipv6:
                self._ns_run(
                    self.router_ns,
                    [
                        "ip6tables", "-t", "mangle", "-A", "POSTROUTING", "-o", self.router_wan_if,
                        "-p", "tcp", "--dport", "80", "-m", "conntrack", "--ctdir", "ORIGINAL",
                        "-j", "NFQUEUE", "--queue-num", "10010",
                    ],
                )
            return

        if mode == "REDIRECT":
            self._ns_run(
                self.router_ns,
                [
                    "iptables", "-t", "nat", "-A", "PREROUTING", "-i", self.router_lan_if,
                    "-p", "tcp", "--dport", "80", "-m", "mark", "!", "--mark", PROXY_MARK,
                    "-j", "REDIRECT", "--to-ports", LISTEN_PORT,
                ],
            )
            if self.ipv6:
                self._ns_run(
                    self.router_ns,
                    [
                        "ip6tables", "-t", "nat", "-A", "PREROUTING", "-i", self.router_lan_if,
                        "-p", "tcp", "--dport", "80", "-m", "mark", "!", "--mark", PROXY_MARK,
                        "-j", "REDIRECT", "--to-ports", LISTEN_PORT,
                    ],
                )
            return

        if mode != "TPROXY":
            raise RuntimeError(f"unsupported test mode: {mode}")

        self._ns_run(self.router_ns, ["ip", "rule", "add", "fwmark", TPROXY_MARK, "table", TPROXY_TABLE])
        self._ns_run(
            self.router_ns,
            ["ip", "route", "replace", "local", "0.0.0.0/0", "dev", "lo", "table", TPROXY_TABLE],
        )
        self._ns_run(
            self.router_ns,
            [
                "iptables", "-t", "mangle", "-A", "PREROUTING", "-i", self.router_lan_if,
                "-p", "tcp", "--dport", "80", "-m", "mark", "!", "--mark", PROXY_MARK,
                "-j", "TPROXY", "--on-ip", "127.0.0.1", "--on-port", LISTEN_PORT,
                "--tproxy-mark", f"{TPROXY_MARK}/0xffffffff",
            ],
        )
        if self.ipv6:
            self._ns_run(
                self.router_ns,
                ["ip", "-6", "rule", "add", "fwmark", TPROXY_MARK, "table", TPROXY_TABLE],
            )
            self._ns_run(
                self.router_ns,
                ["ip", "-6", "route", "replace", "local", "::/0", "dev", "lo", "table", TPROXY_TABLE],
            )
            self._ns_run(
                self.router_ns,
                [
                    "ip6tables", "-t", "mangle", "-A", "PREROUTING", "-i", self.router_lan_if,
                    "-p", "tcp", "--dport", "80", "-m", "mark", "!", "--mark", PROXY_MARK,
                    "-j", "TPROXY", "--on-ip", "::1", "--on-port", LISTEN_PORT,
                    "--tproxy-mark", f"{TPROXY_MARK}/0xffffffff",
                ],
            )

    def start_ua2f(self, mode):
        environment = ["env"]
        if mode in ("REDIRECT", "TPROXY"):
            environment.append("UA2F_PROXY_WORKERS=2")
        command = [
            "ip",
            "netns",
            "exec",
            self.router_ns,
            *environment,
            str(self.binary),
            "--mode",
            mode,
            "--listen-port",
            LISTEN_PORT,
        ]
        self.ua2f_process = subprocess.Popen(command, stdout=self.ua2f_log, stderr=subprocess.STDOUT)
        time.sleep(1)
        if self.ua2f_process.poll() is not None:
            raise RuntimeError(f"UA2F exited while starting {mode}\n{self.read_ua2f_log()}")

    def stop_ua2f(self):
        if self.ua2f_process is None:
            return
        if self.ua2f_process.poll() is None:
            self.ua2f_process.send_signal(signal.SIGTERM)
            try:
                self.ua2f_process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                self.ua2f_process.kill()
                self.ua2f_process.wait(timeout=5)
        if self.ua2f_process.returncode not in (0, -signal.SIGTERM):
            raise RuntimeError(f"UA2F exited with {self.ua2f_process.returncode}\n{self.read_ua2f_log()}")
        self.ua2f_process = None

    def probe(self, host, port=80, user_agent=TEST_USER_AGENT, requests=1, method="GET", body=None, path="/"):
        command = [
            sys.executable,
            str(self.helper),
            "probe",
            "--host",
            host,
            "--port",
            str(port),
            "--requests",
            str(requests),
            "--method",
            method,
            "--path",
            path,
        ]
        if user_agent is None:
            command.append("--omit-user-agent")
        else:
            command.extend(["--user-agent", user_agent])
        if body is not None:
            command.extend(["--body", body])
        result = self._ns_run(self.client_ns, command, capture=True)
        return json.loads(result.stdout)

    @staticmethod
    def assert_rewritten(responses, expected_user_agent, label):
        for index, response in enumerate(responses):
            actual = response["user_agent"]
            if actual != expected_user_agent:
                raise AssertionError(f"{label} response {index}: expected UA {expected_user_agent!r}, got {actual!r}")

    def exercise_mode(self, mode):
        print(f"[netns] testing {mode}", flush=True)
        self.setup_firewall(mode)
        self.start_ua2f(mode)
        expected = "F" * len(TEST_USER_AGENT)
        try:
            responses = self.probe("10.241.2.2", requests=3, path="/keepalive?padding=65536")
            self.assert_rewritten(responses, expected, f"{mode} IPv4 keep-alive")
            if len(responses[0]["padding"]) != 65536:
                raise AssertionError(f"{mode}: large response was truncated")

            post = self.probe("10.241.2.2", method="POST", body=POST_BODY, path="/post")
            self.assert_rewritten(post, expected, f"{mode} IPv4 POST")
            if post[0]["body"] != POST_BODY:
                raise AssertionError(f"{mode}: request body was modified")

            no_ua = self.probe("10.241.2.2", user_agent=None, path="/no-user-agent")
            if no_ua[0]["user_agent"] is not None:
                raise AssertionError(f"{mode}: added an absent User-Agent")

            bypass = self.probe("10.241.2.2", port=443, path="/bypass")
            if bypass[0]["user_agent"] != TEST_USER_AGENT:
                raise AssertionError(f"{mode}: unexpectedly modified bypass port 443")

            if self.ipv6:
                ipv6 = self.probe("fd42:241:2::2", requests=2, path="/ipv6")
                self.assert_rewritten(ipv6, expected, f"{mode} IPv6")
        finally:
            self.stop_ua2f()
            self.flush_firewall()

    def read_ua2f_log(self):
        self.ua2f_log.flush()
        try:
            return Path(self.ua2f_log.name).read_text(errors="replace")
        except OSError:
            return ""

    def restore_coverage_ownership(self):
        uid = os.environ.get("SUDO_UID")
        gid = os.environ.get("SUDO_GID")
        if uid is None or gid is None:
            return
        for coverage_file in self.binary.parent.rglob("*.gcda"):
            os.chown(coverage_file, int(uid), int(gid))

    def cleanup(self):
        try:
            self.stop_ua2f()
        except RuntimeError as error:
            print(error, file=sys.stderr)
        if self.origin_process is not None and self.origin_process.poll() is None:
            self.origin_process.terminate()
            try:
                self.origin_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.origin_process.kill()
                self.origin_process.wait(timeout=5)
        for namespace in (self.client_ns, self.router_ns, self.origin_ns):
            self._run(["ip", "netns", "delete", namespace], check=False)
        self.restore_coverage_ownership()
        self.ua2f_log.close()

    def run(self):
        self.preflight()
        try:
            self.setup_network()
            self.start_origin()
            for mode in self.modes:
                self.exercise_mode(mode)
            print(f"[netns] passed modes: {', '.join(self.modes)}", flush=True)
        except Exception:
            print(self.read_ua2f_log(), file=sys.stderr)
            raise
        finally:
            self.cleanup()


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("binary")
    parser.add_argument("--modes", default="NFQUEUE,REDIRECT,TPROXY")
    parser.add_argument("--skip-ipv6", action="store_true")
    return parser.parse_args()


if __name__ == "__main__":
    arguments = parse_args()
    selected_modes = [mode.strip().upper() for mode in arguments.modes.split(",") if mode.strip()]
    invalid_modes = set(selected_modes) - {"NFQUEUE", "REDIRECT", "TPROXY"}
    if invalid_modes:
        raise SystemExit(f"unsupported modes: {', '.join(sorted(invalid_modes))}")
    RoutedIntegrationTest(arguments.binary, selected_modes, ipv6=not arguments.skip_ipv6).run()
