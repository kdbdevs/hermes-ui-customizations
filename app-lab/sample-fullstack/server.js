#!/usr/bin/env node
"use strict";

const http = require("http");

const HOST = process.env.HOST || "127.0.0.1";
const PORT = Number(process.env.PORT || "3101");

const html = `<!doctype html>
<html lang="id">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Hermes Fullstack Demo</title>
  <style>
    *{box-sizing:border-box}body{margin:0;min-height:100vh;font:15px/1.5 Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:radial-gradient(circle at 24px 24px,rgba(255,255,255,.07) 1px,transparent 1px) 0 0/24px 24px,#0f0b17;color:#f7f2ff}.shell{min-height:100vh;display:grid;grid-template-columns:320px 1fr}.side{padding:32px;border-right:1px solid rgba(255,255,255,.1);background:rgba(24,18,34,.82)}.brand{font-weight:900;font-size:24px}.nav{display:grid;gap:8px;margin-top:32px}.nav span{padding:10px 12px;border-radius:8px;color:#b8afc3}.nav span:first-child{background:#2c2638;color:#fff}.main{padding:40px}.top{display:flex;justify-content:space-between;align-items:center;gap:20px}.status{border:1px solid rgba(255,255,255,.14);background:#211c2d;border-radius:8px;padding:12px 14px;color:#98f5c4}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px;margin-top:28px}.card{min-height:150px;padding:18px;border:1px solid rgba(255,255,255,.11);border-radius:8px;background:linear-gradient(180deg,#2a2437,#1f1a2b)}.card b{display:block;font-size:30px;margin-top:14px}.feed{margin-top:14px;color:#a99fb4}@media(max-width:820px){.shell{grid-template-columns:1fr}.side{border-right:0;border-bottom:1px solid rgba(255,255,255,.1)}.grid{grid-template-columns:1fr}}
  </style>
</head>
<body>
  <div class="shell">
    <aside class="side"><div class="brand">Hermes App Lab</div><div class="nav"><span>Dashboard</span><span>API Health</span><span>Deployments</span></div></aside>
    <main class="main">
      <div class="top"><div><h1>Fullstack app running live</h1><p>Frontend ini mengambil data dari backend Node di route <code>/api/status</code>.</p></div><div class="status" id="status">Checking API...</div></div>
      <section class="grid">
        <div class="card">Backend<b id="backend">-</b><div class="feed">Node HTTP server</div></div>
        <div class="card">Port<b id="port">-</b><div class="feed">Assigned by App Lab</div></div>
        <div class="card">Updated<b id="time">-</b><div class="feed">Live JSON response</div></div>
      </section>
    </main>
  </div>
  <script>
    fetch('/api/status').then(r=>r.json()).then(data=>{
      document.getElementById('status').textContent='API online';
      document.getElementById('backend').textContent=data.service;
      document.getElementById('port').textContent=data.port;
      document.getElementById('time').textContent=new Date(data.time).toLocaleTimeString();
    }).catch(()=>{document.getElementById('status').textContent='API unavailable'});
  </script>
</body>
</html>`;

const server = http.createServer((req, res) => {
  if (req.url === "/health" || req.url === "/api/status") {
    const body = JSON.stringify({
      status: "ok",
      service: "node-backend",
      port: PORT,
      time: new Date().toISOString(),
    });
    res.writeHead(200, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
    res.end(body);
    return;
  }
  res.writeHead(200, { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" });
  res.end(html);
});

server.listen(PORT, HOST, () => {
  console.log(`Hermes sample fullstack app listening on ${HOST}:${PORT}`);
});
