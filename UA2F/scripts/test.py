import atexit
import http.server
import os
import socketserver
import subprocess
import sys
import threading
import time

import requests
from fake_useragent import UserAgent

ua = UserAgent()

PORT = 37491


class MyHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        user_agent = self.headers.get('User-Agent')

        # assert user_agent only contains F
        if not all([c == 'F' for c in user_agent]):
            self.send_response(200)
        else:
            self.send_response(400)
        self.end_headers()
        ua_len = len(user_agent)
        self.wfile.write(str(ua_len).encode())


def start_server():
    with socketserver.TCPServer(("", PORT), MyHandler, True) as httpd:
        httpd.serve_forever()
        atexit.register(httpd.shutdown)


def start_ua2f(u: str):
    p = subprocess.Popen([u])
    atexit.register(lambda: p.kill())


# iptables 设置函数
def setup_iptables():
    os.system(f"sudo iptables -A OUTPUT -p tcp --dport {PORT} -j NFQUEUE --queue-num 10010")


def cleanup_iptables():
    os.system(f"sudo iptables -D OUTPUT -p tcp --dport {PORT} -j NFQUEUE --queue-num 10010")


if __name__ == "__main__":
    if os.name != 'posix':
        raise Exception("This script only supports Linux")

    if os.geteuid() != 0:
        raise Exception("This script requires root privileges")

    ua2f = sys.argv[1]

    setup_iptables()

    server_thread = threading.Thread(target=start_server)
    server_thread.daemon = True
    server_thread.start()

    print(f"Starting server on port {PORT}")

    ua2f_thread = threading.Thread(target=start_ua2f, args=(ua2f,))
    ua2f_thread.daemon = True
    ua2f_thread.start()

    print(f"Starting UA2F: {ua2f}")

    time.sleep(2)

    for i in range(10000):
        nxt = ua.random
        response = requests.get(f"http://localhost:{PORT}", headers={
            "User-Agent": nxt
        })
        assert response.ok
        assert response.text == str(len(nxt))


    # clean
    cleanup_iptables()
