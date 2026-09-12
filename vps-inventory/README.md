# Hermes VPS Inventory

Agent-readable infrastructure inventory for Hermes.

Passwords do not belong in this repo or generated reports. Put hosts in
`/root/hermes-inventory/hosts.tsv` on the Hermes VPS and use SSH keys or
temporary manual login where needed.

## Files

- `hosts.example.tsv` - tab-separated host list template
- `scan_vps_inventory.sh` - read-only scanner over SSH
- `render_inventory_report.py` - JSONL to Markdown report renderer
- `SKILL.md` - Hermes skill installed into agent profiles

## Typical Run

```bash
scan-vps-inventory /root/hermes-inventory/hosts.tsv /root/hermes-inventory/scans
latest=$(ls -t /root/hermes-inventory/scans/vps-inventory-*.jsonl | head -1)
render-vps-inventory "$latest" /root/hermes-inventory/INVENTORY.md
```
