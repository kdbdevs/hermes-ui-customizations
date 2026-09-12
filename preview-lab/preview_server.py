#!/usr/bin/env python3
"""Tiny static preview board for Hermes-generated UI artifacts."""

from __future__ import annotations

import html
import json
import mimetypes
import os
import posixpath
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse


ROOT = Path(os.environ.get("HERMES_PREVIEW_ROOT", "/var/lib/hermes-previews/sites")).resolve()
HOST = os.environ.get("HERMES_PREVIEW_HOST", "127.0.0.1")
PORT = int(os.environ.get("HERMES_PREVIEW_PORT", "8088"))


def _read_meta(site_dir: Path) -> dict:
    meta_path = site_dir / ".hermes-preview.json"
    if not meta_path.exists():
        return {}
    try:
        data = json.loads(meta_path.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _site_rows() -> str:
    rows = []
    if ROOT.exists():
        for site_dir in sorted((p for p in ROOT.iterdir() if p.is_dir()), key=lambda p: p.stat().st_mtime, reverse=True):
            slug = site_dir.name
            meta = _read_meta(site_dir)
            title = html.escape(str(meta.get("title") or slug))
            summary = html.escape(str(meta.get("summary") or "Hermes preview artifact"))
            updated = html.escape(str(meta.get("updated_at") or ""))
            rows.append(
                f'<a class="preview-card" href="/sites/{html.escape(slug)}/">'
                f"<span>{title}</span><small>{summary}</small><em>{updated}</em></a>"
            )
    if not rows:
        rows.append('<div class="empty">No previews yet. Ask Hermes to publish a UI artifact.</div>')
    return "\n".join(rows)


def _index_html() -> bytes:
    body = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Hermes Preview Lab</title>
  <style>
    :root {{
      color-scheme: dark;
      --bg: #0f0b17;
      --panel: #1f1a2b;
      --panel-2: #2a2437;
      --text: #f4f1ff;
      --muted: #a59dad;
      --line: #4b435d;
      --accent: #ff6d4a;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      min-height: 100vh;
      font: 15px/1.5 Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      color: var(--text);
      background:
        radial-gradient(circle at 24px 24px, rgba(255,255,255,.08) 1px, transparent 1px) 0 0/24px 24px,
        linear-gradient(135deg, #0f0b17 0%, #171020 55%, #100c16 100%);
    }}
    header {{
      display: flex;
      justify-content: space-between;
      gap: 24px;
      align-items: end;
      padding: 36px 40px 24px;
      border-bottom: 1px solid rgba(255,255,255,.08);
    }}
    h1 {{ margin: 0; font-size: 28px; letter-spacing: 0; }}
    p {{ margin: 8px 0 0; color: var(--muted); max-width: 680px; }}
    code {{
      border: 1px solid rgba(255,255,255,.14);
      border-radius: 6px;
      padding: 4px 7px;
      background: rgba(255,255,255,.06);
      color: #ffd6c8;
    }}
    main {{ padding: 28px 40px 40px; }}
    .grid {{
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 14px;
    }}
    .preview-card, .empty {{
      display: grid;
      min-height: 128px;
      padding: 18px;
      border: 1px solid rgba(255,255,255,.11);
      border-radius: 8px;
      background: linear-gradient(180deg, rgba(42,36,55,.94), rgba(31,26,43,.94));
      box-shadow: 0 18px 50px rgba(0,0,0,.22);
      text-decoration: none;
      color: inherit;
    }}
    .preview-card:hover {{ border-color: rgba(255,109,74,.65); transform: translateY(-1px); }}
    .preview-card span {{ font-weight: 750; font-size: 17px; }}
    .preview-card small {{ color: var(--muted); }}
    .preview-card em {{ align-self: end; color: #c8c0d3; font-size: 12px; font-style: normal; }}
    .empty {{ color: var(--muted); }}
  </style>
</head>
<body>
  <header>
    <div>
      <h1>Hermes Preview Lab</h1>
      <p>Live location for Hermes UI, wireframe, landing page, and prototype demonstrations.</p>
    </div>
  </header>
  <main><section class="grid">{_site_rows()}</section></main>
</body>
</html>"""
    return body.encode("utf-8")


class Handler(BaseHTTPRequestHandler):
    server_version = "HermesPreviewLab/1.0"

    def do_HEAD(self) -> None:
        path = unquote(urlparse(self.path).path)
        if path == "/health":
            self._send_json({"status": "ok", "service": "hermes-preview-lab"}, head_only=True)
            return
        if path in {"", "/"}:
            self._send(200, b"", "text/html; charset=utf-8", head_only=True)
            return
        if path.startswith("/sites/"):
            self._serve_site(path, head_only=True)
            return
        self._send(404, b"", "text/plain; charset=utf-8", head_only=True)

    def do_GET(self) -> None:
        path = unquote(urlparse(self.path).path)
        if path == "/health":
            self._send_json({"status": "ok", "service": "hermes-preview-lab"})
            return
        if path in {"", "/"}:
            self._send(200, _index_html(), "text/html; charset=utf-8")
            return
        if path.startswith("/sites/"):
            self._serve_site(path)
            return
        self._send(404, b"Not found\n", "text/plain; charset=utf-8")

    def log_message(self, fmt: str, *args) -> None:
        print("%s - - [%s] %s" % (self.address_string(), self.log_date_time_string(), fmt % args), flush=True)

    def _serve_site(self, raw_path: str, *, head_only: bool = False) -> None:
        rel = raw_path.removeprefix("/sites/")
        clean = posixpath.normpath("/" + rel).lstrip("/")
        parts = clean.split("/", 1)
        slug = parts[0]
        rest = parts[1] if len(parts) > 1 else ""
        if not slug or slug.startswith("."):
            self._send(404, b"Not found\n", "text/plain; charset=utf-8", head_only=head_only)
            return
        site_root = (ROOT / slug).resolve()
        target = (site_root / rest).resolve()
        if site_root != target and site_root not in target.parents:
            self._send(403, b"Forbidden\n", "text/plain; charset=utf-8", head_only=head_only)
            return
        if target.is_dir():
            target = target / "index.html"
        if not target.exists() and (site_root / "index.html").exists():
            target = site_root / "index.html"
        if not target.is_file():
            self._send(404, b"Not found\n", "text/plain; charset=utf-8", head_only=head_only)
            return
        ctype = mimetypes.guess_type(str(target))[0] or "application/octet-stream"
        self._send(200, target.read_bytes(), ctype, head_only=head_only)

    def _send_json(self, data: dict, *, head_only: bool = False) -> None:
        self._send(200, json.dumps(data).encode("utf-8"), "application/json; charset=utf-8", head_only=head_only)

    def _send(self, status: int, body: bytes, content_type: str, *, head_only: bool = False) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if not head_only:
            self.wfile.write(body)


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Hermes Preview Lab listening on {HOST}:{PORT}, root={ROOT}", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
