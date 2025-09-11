import atexit
import http.server
import json
import logging
import os
import socket
import socketserver
import subprocess
import sys
import threading
import time
from http.server import HTTPServer, BaseHTTPRequestHandler

import requests
from fake_useragent import UserAgent
from tqdm import tqdm
from fastapi import FastAPI, Request
from fastapi.responses import Response
from fastapi.staticfiles import StaticFiles
from uvicorn import Config, Server

ua = UserAgent()

PORT = 37491


app = FastAPI()

@app.get("/")
async def root(request: Request):
    user_agent = request.headers.get("user-agent")

    if not all(c == 'F' for c in user_agent):
        return Response(status_code=400)

    return Response(content=str(len(user_agent)).encode())

def start_server():
    config4 = Config(app=app, host="127.0.0.1", port=PORT, access_log=False)
    config6 = Config(app=app, host="::1", port=PORT, access_log=False)
    server4 = Server(config4)
    server6 = Server(config6)
    t4 = threading.Thread(target=server4.run)
    t4.daemon = True
    t6 = threading.Thread(target=server6.run)
    t6.daemon = True
    t4.start()
    t6.start()

def start_ua2f(u: str):
    env = os.environ.copy()

    ua2f_abs_path = os.path.abspath(u)
    build_dir = os.path.dirname(ua2f_abs_path)
    
    print(f"Starting UA2F from build directory: {build_dir}")
    original_cwd = os.getcwd()
    os.chdir(build_dir)
    
    binary_name = os.path.basename(ua2f_abs_path)
    p = subprocess.Popen([f'./{binary_name}'], env=env, cwd=build_dir)
    
    os.chdir(original_cwd)
    
    def graceful_shutdown():
        try:
            p.terminate()
            p.wait(timeout=5)
        except subprocess.TimeoutExpired:
            p.kill()
    
    atexit.register(graceful_shutdown)
    return p


def setup_iptables():
    os.system(f"sudo iptables -A OUTPUT -p tcp --dport {PORT} -j NFQUEUE --queue-num 10010")
    os.system(f"sudo ip6tables -A OUTPUT -p tcp --dport {PORT} -j NFQUEUE --queue-num 10010")


def cleanup_iptables():
    os.system(f"sudo iptables -D OUTPUT -p tcp --dport {PORT} -j NFQUEUE --queue-num 10010")
    os.system(f"sudo ip6tables -D OUTPUT -p tcp --dport {PORT} -j NFQUEUE --queue-num 10010")


if __name__ == "__main__":
    if os.name != 'posix':
        raise Exception("This script only supports Linux")

    if os.geteuid() != 0:
        raise Exception("This script requires root privileges")

    ua2f = sys.argv[1]

    setup_iptables()

    start_server()

    ua2f_process = start_ua2f(ua2f)

    print(f"Starting UA2F: {ua2f}")

    time.sleep(3)

    for i in tqdm(range(1024)):
        nxt = ua.random
        response = requests.get(f"http://127.0.0.1:{PORT}", headers={
            "User-Agent": nxt
        })
        assert response.ok
        assert response.text == str(len(nxt))

    for i in tqdm(range(4096)):
        nxt = ua.random
        response = requests.get(f"http://[::1]:{PORT}", headers={
            "User-Agent": nxt
        })
        assert response.ok
        assert response.text == str(len(nxt))

    print("Tests completed, shutting down UA2F gracefully...")
    
    try:
        ua2f_process.terminate()
        ua2f_process.wait(timeout=5)
        print("UA2F terminated gracefully")
    except subprocess.TimeoutExpired:
        print("UA2F didn't respond to SIGTERM, force killing...")
        ua2f_process.kill()

    # clean
    cleanup_iptables()
