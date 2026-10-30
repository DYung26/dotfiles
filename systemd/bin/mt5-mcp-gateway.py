#!/usr/bin/env python3
"""Expose the local MT5 MCP endpoints to Docker on the host-gateway IP only."""
import socket
import socketserver
import threading

GATEWAY = "172.20.0.1"
MAPPINGS = {22345: 22345, 22346: 22346}

class ProxyHandler(socketserver.BaseRequestHandler):
    def handle(self):
        try:
            upstream = socket.create_connection(("127.0.0.1", MAPPINGS[self.server.server_address[1]]), timeout=5)
        except OSError:
            return
        with upstream:
            def pump(src, dst):
                try:
                    while True:
                        data = src.recv(65536)
                        if not data:
                            break
                        dst.sendall(data)
                except OSError:
                    pass
                finally:
                    try:
                        dst.shutdown(socket.SHUT_WR)
                    except OSError:
                        pass
            a = threading.Thread(target=pump, args=(self.request, upstream), daemon=True)
            b = threading.Thread(target=pump, args=(upstream, self.request), daemon=True)
            a.start(); b.start(); a.join(); b.join()

class ThreadingServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

servers = []
for port in MAPPINGS:
    server = ThreadingServer((GATEWAY, port), ProxyHandler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    servers.append(server)
threading.Event().wait()
