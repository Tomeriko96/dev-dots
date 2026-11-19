#!/usr/bin/env python3
"""Make a dev server inside the devcontainer reachable on the host's localhost.

Why: with rootless podman + devcontainer-cli, `forwardPorts` in devcontainer.json
is ignored (only VS Code honours it) and the container has its own network
namespace, so http://localhost:PORT on the laptop reaches nothing.

How: run this ON THE HOST (or in a toolbox). It listens on 127.0.0.1:PORT and
pipes every connection through `podman exec -i <container> node ...` into the
container's 127.0.0.1:PORT. No rebuild, no published ports, nothing exposed to
the network. WebSockets (hot reload) work too.

    python3 .devcontainer/port-bridge.py 4321            # auto-detects the devcontainer
    python3 .devcontainer/port-bridge.py 4321 5173 3030  # several ports
    python3 .devcontainer/port-bridge.py -c <name> 4321  # pick a container explicitly

Inside the container, bind the dev server to 127.0.0.1 (e.g. `astro dev --host 127.0.0.1`).
From a toolbox, podman is reached via `flatpak-spawn --host podman` automatically.
"""
from __future__ import annotations

import argparse
import shutil
import socket
import subprocess
import sys
import threading

# Runs inside the container: connect to the local port and splice stdin/stdout.
NODE_PIPE = (
    "const s=require('net').connect(+process.argv[1],'127.0.0.1');"
    "process.stdin.pipe(s);s.pipe(process.stdout);"
    "process.stdin.on('end',()=>s.end());"
    "s.on('error',()=>process.exit(1));s.on('close',()=>process.exit(0));"
)


def podman_cmd() -> list[str]:
    if shutil.which("podman"):
        return ["podman"]
    if shutil.which("flatpak-spawn"):  # inside a toolbox
        return ["flatpak-spawn", "--host", "podman"]
    sys.exit("podman not found (also not via flatpak-spawn --host)")


def find_container(podman: list[str]) -> str:
    out = subprocess.run(
        [*podman, "ps", "--filter", "label=devcontainer.local_folder",
         "--format", "{{.Names}}\t{{.Labels}}"],
        capture_output=True, text=True, check=True,
    ).stdout.strip().splitlines()
    names = [line.split("\t")[0] for line in out if line]
    if len(names) == 1:
        return names[0]
    if not names:
        sys.exit("No running devcontainer found; pass one with -c (see `podman ps`).")
    sys.exit("Several devcontainers running, pick one with -c: " + ", ".join(names))


def pump(src, dst) -> None:
    try:
        while chunk := src(65536):
            dst(chunk)
    except OSError:
        pass


def handle(conn: socket.socket, podman: list[str], container: str, port: int) -> None:
    proc = subprocess.Popen(
        [*podman, "exec", "-i", container, "node", "-e", NODE_PIPE, str(port)],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
    )

    def to_container():
        def write(b):
            proc.stdin.write(b)
            proc.stdin.flush()
        pump(conn.recv, write)
        try:
            proc.stdin.close()
        except OSError:
            pass

    t = threading.Thread(target=to_container, daemon=True)
    t.start()
    pump(proc.stdout.read1, conn.sendall)
    try:
        conn.shutdown(socket.SHUT_RDWR)
    except OSError:
        pass
    conn.close()
    proc.wait()


def serve(port: int, podman: list[str], container: str) -> None:
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("127.0.0.1", port))
    srv.listen(64)
    print(f"  http://localhost:{port}  ->  {container}:127.0.0.1:{port}")
    while True:
        conn, _ = srv.accept()
        threading.Thread(target=handle, args=(conn, podman, container, port), daemon=True).start()


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("ports", nargs="+", type=int)
    ap.add_argument("-c", "--container", help="container name or id (default: auto-detect)")
    ap.add_argument("--podman", help='podman command, e.g. "flatpak-spawn --host podman"')
    args = ap.parse_args()

    podman = args.podman.split() if args.podman else podman_cmd()
    container = args.container or find_container(podman)
    print("Bridging (Ctrl-C to stop):")
    for port in args.ports:
        threading.Thread(target=serve, args=(port, podman, container), daemon=True).start()
    try:
        threading.Event().wait()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
