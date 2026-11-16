#!/usr/bin/env python3
import os
import socket
import socketserver
import threading

GATEWAY = os.environ.get("MT5_MCP_GATEWAY_HOST", "172.20.0.1")
MAPPINGS = {
    int(os.environ.get("MT5_MCP_GATEWAY_PORT_1", "22345")): int(os.environ.get("MT5_MCP_TARGET_PORT_1", "22345")),
    int(os.environ.get("MT5_MCP_GATEWAY_PORT_2", "22346")): int(os.environ.get("MT5_MCP_TARGET_PORT_2", "22346")),
}

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
            a.start()
            b.start()
            a.join()
            b.join()

class ThreadingServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

servers = []
for port in MAPPINGS:
    server = ThreadingServer((GATEWAY, port), ProxyHandler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    servers.append(server)
threading.Event().wait()
