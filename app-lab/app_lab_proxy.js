#!/usr/bin/env node
"use strict";

const fs = require("fs");
const http = require("http");
const net = require("net");
const path = require("path");
const { URL } = require("url");

const HOST = process.env.HERMES_APP_LAB_HOST || "127.0.0.1";
const PORT = Number(process.env.HERMES_APP_LAB_PORT || "18080");
const REGISTRY_PATH = process.env.HERMES_APP_LAB_REGISTRY || "/var/lib/hermes-apps/registry.json";
const PUBLIC_BASE = (process.env.HERMES_APP_LAB_PUBLIC_BASE || "https://apps.cloudnes.space").replace(/\/+$/, "");

let registryMtime = 0;
let registry = { apps: {} };

function readRegistry() {
  try {
    const stat = fs.statSync(REGISTRY_PATH);
    if (stat.mtimeMs === registryMtime) return registry;
    registryMtime = stat.mtimeMs;
    const next = JSON.parse(fs.readFileSync(REGISTRY_PATH, "utf8"));
    registry = next && typeof next === "object" ? next : { apps: {} };
  } catch {
    registry = { apps: {} };
    registryMtime = 0;
  }
  return registry;
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function slugFromHost(hostHeader) {
  const host = String(hostHeader || "").split(":")[0].toLowerCase();
  if (host === "apps.cloudnes.space") return "";
  if (host.endsWith(".apps.cloudnes.space")) {
    return host.slice(0, -".apps.cloudnes.space".length);
  }
  return "";
}

function catalogHtml() {
  const apps = readRegistry().apps || {};
  const rows = Object.entries(apps)
    .sort(([, a], [, b]) => String(b.updated_at || "").localeCompare(String(a.updated_at || "")))
    .map(([slug, app]) => {
      const url = `https://${slug}.apps.cloudnes.space/`;
      return `<a class="card" href="${url}">
        <span>${escapeHtml(app.title || slug)}</span>
        <small>${escapeHtml(app.summary || "Hermes fullstack app")}</small>
        <code>${escapeHtml(url)}</code>
        <em>port ${escapeHtml(app.port || "")} · ${escapeHtml(app.updated_at || "")}</em>
      </a>`;
    })
    .join("") || `<div class="empty">No apps deployed yet. Ask Hermes to deploy one with <code>hermes-app-deploy</code>.</div>`;

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Hermes App Lab</title>
  <style>
    :root{color-scheme:dark;--bg:#0f0b17;--panel:#242030;--text:#f6f2ff;--muted:#a9a1b4;--line:#474052;--accent:#ff6d4a}
    *{box-sizing:border-box}body{margin:0;min-height:100vh;font:15px/1.5 Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:var(--text);background:radial-gradient(circle at 24px 24px,rgba(255,255,255,.08) 1px,transparent 1px) 0 0/24px 24px,linear-gradient(135deg,#0f0b17,#171020)}
    header{display:flex;justify-content:space-between;gap:24px;align-items:end;padding:36px 40px 24px;border-bottom:1px solid rgba(255,255,255,.08)}
    h1{margin:0;font-size:28px;letter-spacing:0}p{margin:8px 0 0;color:var(--muted);max-width:720px}
    main{padding:28px 40px 40px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:14px}
    .card,.empty{display:grid;gap:10px;min-height:148px;padding:18px;border:1px solid rgba(255,255,255,.11);border-radius:8px;background:linear-gradient(180deg,rgba(42,36,55,.96),rgba(31,26,43,.96));box-shadow:0 18px 50px rgba(0,0,0,.22);text-decoration:none;color:inherit}
    .card:hover{border-color:rgba(255,109,74,.65);transform:translateY(-1px)}.card span{font-weight:780;font-size:17px}.card small,.empty{color:var(--muted)}code{color:#ffd6c8}.card em{align-self:end;color:#c8c0d3;font-size:12px;font-style:normal}
  </style>
</head>
<body>
  <header><div><h1>Hermes App Lab</h1><p>Running fullstack applications deployed by Hermes agents.</p></div><code>${escapeHtml(PUBLIC_BASE)}</code></header>
  <main><section class="grid">${rows}</section></main>
</body>
</html>`;
}

function getTarget(slug) {
  const apps = readRegistry().apps || {};
  const app = apps[slug];
  if (!app || !app.port) return null;
  return { host: app.host || "127.0.0.1", port: Number(app.port), app };
}

function proxyHttp(req, res, target) {
  const options = {
    hostname: target.host,
    port: target.port,
    path: req.url,
    method: req.method,
    headers: { ...req.headers, host: `${target.host}:${target.port}`, "x-forwarded-host": req.headers.host || "" },
  };
  const upstream = http.request(options, (upRes) => {
    res.writeHead(upRes.statusCode || 502, upRes.headers);
    upRes.pipe(res);
  });
  upstream.on("error", (err) => {
    res.writeHead(502, { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store" });
    res.end(`App upstream unavailable: ${err.message}\n`);
  });
  req.pipe(upstream);
}

const server = http.createServer((req, res) => {
  const pathName = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`).pathname;
  if (pathName === "/health") {
    res.writeHead(200, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
    res.end(JSON.stringify({ status: "ok", service: "hermes-app-lab" }));
    return;
  }
  const slug = slugFromHost(req.headers.host);
  if (!slug) {
    const body = catalogHtml();
    res.writeHead(200, { "content-type": "text/html; charset=utf-8", "content-length": Buffer.byteLength(body), "cache-control": "no-store" });
    res.end(body);
    return;
  }
  const target = getTarget(slug);
  if (!target) {
    res.writeHead(404, { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store" });
    res.end(`No Hermes App Lab app registered for ${slug}\n`);
    return;
  }
  proxyHttp(req, res, target);
});

server.on("upgrade", (req, socket, head) => {
  const slug = slugFromHost(req.headers.host);
  const target = slug ? getTarget(slug) : null;
  if (!target) {
    socket.write("HTTP/1.1 404 Not Found\r\n\r\n");
    socket.destroy();
    return;
  }
  const upstream = net.connect(target.port, target.host, () => {
    upstream.write(`${req.method} ${req.url} HTTP/${req.httpVersion}\r\n`);
    for (const [key, value] of Object.entries(req.headers)) {
      upstream.write(`${key}: ${value}\r\n`);
    }
    upstream.write(`host: ${target.host}:${target.port}\r\n\r\n`);
    if (head && head.length) upstream.write(head);
    upstream.pipe(socket);
    socket.pipe(upstream);
  });
  upstream.on("error", () => socket.destroy());
});

server.listen(PORT, HOST, () => {
  console.log(`Hermes App Lab proxy listening on ${HOST}:${PORT}, registry=${REGISTRY_PATH}`);
});
