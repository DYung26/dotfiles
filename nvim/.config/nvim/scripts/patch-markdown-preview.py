#!/usr/bin/env python3
"""Apply small compatibility fixes to markdown-preview.nvim's bundled Node server."""
from pathlib import Path
import sys

root = Path(sys.argv[1]).expanduser()
routes = root / "app/routes.js"
s = routes.read_text()
old = """// /page/:number
use((req, res, next) => {
  if (/\\/page\\/\\d+/.test(req.asPath)) {
    return fs.createReadStream('./out/index.html').pipe(res)
  }"""
new = """// /page/:number and the client-side /:number URL used after socket startup/reload.
use((req, res, next) => {
  if (/^\\/page\\/\\d+$/.test(req.asPath) || /^\\/\\d+$/.test(req.asPath)) {
    res.setHeader('Content-Type', 'text/html; charset=utf-8')
    return fs.createReadStream('./out/index.html').pipe(res)
  }"""
if new not in s:
    if old not in s:
        raise SystemExit("Could not find markdown-preview route patch location")
    s = s.replace(old, new, 1)
routes.write_text(s)

server = root / "app/server.js"
s = server.read_text()
needle = "    req.asPath = req.url.replace(/[?#].*$/, '')\n"
addition = """    req.asPath = req.url.replace(/[?#].*$/, '')
    // Explicit MIME types are required for stylesheets and scripts behind raw Node routes.
    if (req.asPath.endsWith('.css')) res.setHeader('Content-Type', 'text/css; charset=utf-8')
    else if (req.asPath.endsWith('.js')) res.setHeader('Content-Type', 'application/javascript; charset=utf-8')
    else if (req.asPath.endsWith('.json')) res.setHeader('Content-Type', 'application/json; charset=utf-8')
    else if (req.asPath.endsWith('.svg')) res.setHeader('Content-Type', 'image/svg+xml')
    else if (req.asPath.endsWith('.ico')) res.setHeader('Content-Type', 'image/x-icon')
"""
if addition not in s:
    if needle not in s:
        raise SystemExit("Could not find markdown-preview MIME patch location")
    s = s.replace(needle, addition, 1)
server.write_text(s)

css = root / "app/_static/page.css"
s = css.read_text()
s = s.replace("  float: left;\n", "  float: none;\n  margin-left: auto;\n", 1)
css.write_text(s)
