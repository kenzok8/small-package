#!/usr/bin/env python3
"""Small dependency-free HTTP endpoint and keep-alive probe for integration tests."""

import argparse
import http.client
import http.server
import json
import signal
import socket
import threading
import urllib.parse


class EchoHandler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _handle(self, include_body=True):
        content_length = int(self.headers.get("Content-Length", "0"))
        request_body = self.rfile.read(content_length).decode("utf-8", errors="replace")
        query = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query)
        padding_bytes = min(int(query.get("padding", ["0"])[0]), 1024 * 1024)
        payload = json.dumps(
            {
                "user_agent": self.headers.get("User-Agent"),
                "method": self.command,
                "body": request_body,
                "path": self.path,
                "padding": "x" * padding_bytes,
            },
            separators=(",", ":"),
        ).encode()

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        if include_body:
            self.wfile.write(payload)

    do_GET = _handle
    do_POST = _handle
    do_PUT = _handle
    do_DELETE = _handle
    do_PATCH = _handle
    do_OPTIONS = _handle

    def do_HEAD(self):
        self._handle(include_body=False)

    def log_message(self, format_string, *args):
        return


class IPv6ThreadingHTTPServer(http.server.ThreadingHTTPServer):
    address_family = socket.AF_INET6

    def server_bind(self):
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
        super().server_bind()


def serve(args):
    servers = []
    threads = []
    for port in args.port:
        servers.append(http.server.ThreadingHTTPServer((args.bind_ipv4, port), EchoHandler))
        if args.ipv6:
            servers.append(IPv6ThreadingHTTPServer((args.bind_ipv6, port), EchoHandler))

    stopped = threading.Event()

    def stop(_signum, _frame):
        stopped.set()

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    for server in servers:
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        threads.append(thread)

    stopped.wait()
    for server in servers:
        server.shutdown()
        server.server_close()
    for thread in threads:
        thread.join(timeout=5)


def probe(args):
    connection = http.client.HTTPConnection(args.host, args.port, timeout=args.timeout)
    responses = []
    try:
        for _ in range(args.requests):
            headers = {}
            if not args.omit_user_agent:
                headers["User-Agent"] = args.user_agent
            body = args.body.encode() if args.body is not None else None
            connection.request(args.method, args.path, body=body, headers=headers)
            response = connection.getresponse()
            response_body = response.read()
            if response.status != 200:
                raise RuntimeError(f"HTTP {response.status}: {response_body[:200]!r}")
            responses.append(json.loads(response_body))
    finally:
        connection.close()
    print(json.dumps(responses, separators=(",", ":")))


def parse_args():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    server_parser = subparsers.add_parser("serve")
    server_parser.add_argument("--bind-ipv4", default="0.0.0.0")
    server_parser.add_argument("--bind-ipv6", default="::")
    server_parser.add_argument("--ipv6", action="store_true")
    server_parser.add_argument("--port", type=int, action="append", required=True)
    server_parser.set_defaults(func=serve)

    probe_parser = subparsers.add_parser("probe")
    probe_parser.add_argument("--host", required=True)
    probe_parser.add_argument("--port", type=int, default=80)
    probe_parser.add_argument("--path", default="/")
    probe_parser.add_argument("--method", default="GET")
    probe_parser.add_argument("--body")
    probe_parser.add_argument("--user-agent", default="UA2F-Integration/1.0")
    probe_parser.add_argument("--omit-user-agent", action="store_true")
    probe_parser.add_argument("--requests", type=int, default=1)
    probe_parser.add_argument("--timeout", type=float, default=10)
    probe_parser.set_defaults(func=probe)
    return parser.parse_args()


if __name__ == "__main__":
    arguments = parse_args()
    arguments.func(arguments)
