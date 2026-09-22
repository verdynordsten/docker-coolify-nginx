"""Tiny demo service: GET / and GET /healthz. Stdlib only."""
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

NAME = os.environ.get("APP_NAME", "demo")


class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            body = b'{"status":"ok"}'
        else:
            body = ('{"app":"%s","msg":"hello from behind nginx"}' % NAME).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8000), H).serve_forever()
