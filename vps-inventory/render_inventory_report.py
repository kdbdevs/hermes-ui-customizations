#!/usr/bin/env python3
"""Render Hermes VPS inventory JSONL into agent-friendly Markdown."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def lines(text: str) -> list[str]:
    return [ln for ln in (text or "").splitlines() if ln.strip()]


def first_match(text: str, pattern: str) -> str:
    m = re.search(pattern, text or "", re.MULTILINE)
    return m.group(1).strip() if m else ""


def summarize(record: dict) -> str:
    s = record.get("sections", {})
    os_name = first_match(s.get("os", ""), r"Operating System:\s*(.+)") or first_match(s.get("os", ""), r'PRETTY_NAME="?([^"\n]+)')
    kernel = first_match(s.get("os", ""), r"Kernel:\s*(.+)")
    provider = first_match(s.get("os", ""), r"Hardware Vendor:\s*(.+)")
    public_ips = []
    for ln in lines(s.get("ip", "")):
        if " UP " in ln or ln.startswith("eth"):
            public_ips.extend(re.findall(r"\b(?:\d{1,3}\.){3}\d{1,3}/\d+\b", ln))
            public_ips.extend(re.findall(r"\b[0-9a-f:]{4,}/\d+\b", ln, re.I))

    listeners = []
    for ln in lines(s.get("listeners", ""))[1:]:
        if "LISTEN" in ln:
            listeners.append(ln)

    web_bins = []
    for ln in lines(s.get("web_stack", "")):
        if "=" in ln:
            web_bins.append(ln.split("=", 1)[0])

    hermes = s.get("hermes", "")
    cloudflared = "active" if "Active: active" in s.get("cloudflared", "") else ""

    md = []
    title = record.get("ref") or record.get("host")
    md.append(f"## {title}")
    md.append("")
    md.append(f"- Host: `{record.get('host')}`")
    md.append(f"- User: `{record.get('user')}`")
    md.append(f"- Tags: `{', '.join(record.get('tags') or []) or '-'}`")
    md.append(f"- Status: `{record.get('status')}`")
    if os_name:
        md.append(f"- OS: {os_name}")
    if kernel:
        md.append(f"- Kernel: {kernel}")
    if provider:
        md.append(f"- Provider: {provider}")
    if public_ips:
        md.append(f"- IPs: `{', '.join(public_ips)}`")
    if web_bins:
        md.append(f"- Detected stack: `{', '.join(sorted(set(web_bins)))}`")
    if cloudflared:
        md.append("- Cloudflare Tunnel: active")
    if hermes:
        md.append("- Hermes: detected")
        for ln in lines(hermes):
            if any(key in ln for key in ("dashboard_theme=", "dashboard_public_url=", "platforms=", "mcp_servers=", "plugins=")):
                md.append(f"  - `{ln}`")
    md.append("")
    md.append("### Listening Ports")
    md.append("```text")
    md.extend(listeners[:80] or ["No listener data"])
    md.append("```")
    md.append("")
    md.append("### Running Services")
    md.append("```text")
    md.extend(lines(s.get("system_services", ""))[:80] or ["No service data"])
    md.append("```")
    md.append("")
    md.append("### App Dirs / Repos")
    md.append("```text")
    md.extend(lines(s.get("app_dirs", ""))[:120] or ["No app dirs detected"])
    md.append("```")
    md.append("")
    md.append("### Timers / Cron")
    md.append("```text")
    md.extend((lines(s.get("timers", "")) + lines(s.get("cron", "")))[:120] or ["No timer/cron data"])
    md.append("```")
    md.append("")
    return "\n".join(md)


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("Usage: render_inventory_report.py <scan.jsonl> [out.md]")
    src = Path(sys.argv[1])
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else src.with_suffix(".md")
    records = [json.loads(line) for line in src.read_text(encoding="utf-8").splitlines() if line.strip()]
    body = ["# Hermes VPS Inventory", ""]
    body.append("Agent-readable infrastructure map generated from read-only scans. Secrets and passwords are intentionally excluded.")
    body.append("")
    for rec in records:
        body.append(summarize(rec))
    out.write_text("\n".join(body), encoding="utf-8")
    print(out)


if __name__ == "__main__":
    main()
