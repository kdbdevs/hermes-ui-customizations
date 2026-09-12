# Hermes VPS Inventory

Agent-readable infrastructure map generated from read-only scans. Secrets and passwords are intentionally excluded.

## hermes-main

- Host: `self`
- User: `root`
- Tags: `hermes, cloudflare, preview-lab, app-lab`
- Status: `ok`
- OS: Ubuntu 24.04.4 LTS
- Kernel: Linux 6.8.0-134-generic
- Provider: Linode
- IPs: `104.64.209.22/24, 2600:3c15::2000:64ff:fe61:80c0/64, fe80::2000:64ff:fe61:80c0/64`
- Detected stack: `cloudflared, node, npm, python3`
- Cloudflare Tunnel: active
- Hermes: detected
  - `dashboard_theme=n8n-workflow`
  - `dashboard_public_url=http://104.64.209.22:9119`
  - `platforms=webhook`
  - `mcp_servers=context7,deepwiki,semgrep,cloudflare`
  - `plugins=disk-cleanup,openai-codex,security-guidance,web/ddgs,web/firecrawl,web/keenable`

### Listening Ports
```text
tcp   LISTEN 0      128        127.0.0.1:8644       0.0.0.0:*    users:(("hermes",pid=151133,fd=21))                      
tcp   LISTEN 0      4096       127.0.0.1:20241      0.0.0.0:*    users:(("cloudflared",pid=148801,fd=9))                  
tcp   LISTEN 0      4096         0.0.0.0:22         0.0.0.0:*    users:(("sshd",pid=134180,fd=3),("systemd",pid=1,fd=148))
tcp   LISTEN 0      5          127.0.0.1:8088       0.0.0.0:*    users:(("python3",pid=155331,fd=3))                      
tcp   LISTEN 0      511        127.0.0.1:18080      0.0.0.0:*    users:(("MainThread",pid=156516,fd=21))                  
tcp   LISTEN 0      4096   127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=135417,fd=15))             
tcp   LISTEN 0      4096      127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=135417,fd=17))             
tcp   LISTEN 0      511        127.0.0.1:3101       0.0.0.0:*    users:(("MainThread",pid=156822,fd=21))                  
tcp   LISTEN 0      2048         0.0.0.0:9119       0.0.0.0:*    users:(("hermes",pid=140000,fd=20))                      
tcp   LISTEN 0      4096            [::]:22            [::]:*    users:(("sshd",pid=134180,fd=4),("systemd",pid=1,fd=149))
```

### Running Services
```text
cloudflared.service             loaded active running Cloudflare Tunnel client
  cron.service                    loaded active running Regular background program processing daemon
  dbus.service                    loaded active running D-Bus System Message Bus
  getty@tty1.service              loaded active running Getty on tty1
  haveged.service                 loaded active running Entropy Daemon based on the HAVEGE algorithm
  hermes-app-app-lab-demo.service loaded active running Hermes App Lab app: /root/hermes-apps/app-lab-demo
  hermes-app-lab.service          loaded active running Hermes App Lab reverse proxy
  hermes-dashboard.service        loaded active running Hermes Agent Web Dashboard
  hermes-preview-lab.service      loaded active running Hermes Preview Lab static preview server
  polkit.service                  loaded active running Authorization Manager
  rsyslog.service                 loaded active running System Logging Service
  serial-getty@ttyS0.service      loaded active running Serial Getty on ttyS0
  ssh.service                     loaded active running OpenBSD Secure Shell server
  systemd-hostnamed.service       loaded active running Hostname Service
  systemd-journald.service        loaded active running Journal Service
  systemd-logind.service          loaded active running User Login Management
  systemd-networkd.service        loaded active running Network Configuration
  systemd-resolved.service        loaded active running Network Name Resolution
  systemd-timesyncd.service       loaded active running Network Time Synchronization
  systemd-udevd.service           loaded active running Rule-based Manager for Device Events and Files
  udisks2.service                 loaded active running Disk Manager
  unattended-upgrades.service     loaded active running Unattended Upgrades Shutdown
  upower.service                  loaded active running Daemon for power management
  user@0.service                  loaded active running User Manager for UID 0
```

### App Dirs / Repos
```text
/opt/hermes-app-lab
/opt/hermes-preview-lab
/opt/hermes-vps-inventory
/root/.hermes/plugin-data/hermes-achievements
/root/.local/state/hermes
/root/herdi-ai-brain/.git
/root/hermes-apps
/root/hermes-inventory
/root/hermes-ui-customizations
/root/hermes-ui-customizations/.git
/root/hermes-workspace
/root/projects
/root/projects/impeccable-20260911191716/.git
/var/lib/hermes-apps
/var/lib/hermes-previews
```

### Timers / Cron
```text
NEXT                             LEFT LAST                              PASSED UNIT                           ACTIVATES
Sat 2026-09-12 08:40:00 UTC  4min 58s Sat 2026-09-12 08:30:02 UTC 4min 58s ago sysstat-collect.timer          sysstat-collect.service
Sat 2026-09-12 08:41:32 UTC      6min Sat 2026-09-12 07:23:32 UTC 1h 11min ago fwupd-refresh.timer            fwupd-refresh.service
Sat 2026-09-12 10:58:38 UTC  2h 23min Fri 2026-09-11 10:58:38 UTC      21h ago update-notifier-download.timer update-notifier-download.service
Sat 2026-09-12 11:08:38 UTC  2h 33min Fri 2026-09-11 11:08:38 UTC      21h ago systemd-tmpfiles-clean.timer   systemd-tmpfiles-clean.service
Sat 2026-09-12 17:00:00 UTC        8h -                                      - hermes-memory-backup.timer     hermes-memory-backup.service
Sun 2026-09-13 00:00:00 UTC       15h -                                      - cloudflared-update.timer       cloudflared-update.service
Sun 2026-09-13 00:00:00 UTC       15h Sat 2026-09-12 00:00:00 UTC       8h ago dpkg-db-backup.timer           dpkg-db-backup.service
Sun 2026-09-13 00:00:00 UTC       15h Sat 2026-09-12 00:00:00 UTC       8h ago logrotate.timer                logrotate.service
Sun 2026-09-13 00:07:00 UTC       15h Sat 2026-09-12 00:07:00 UTC       8h ago sysstat-summary.timer          sysstat-summary.service
Sun 2026-09-13 01:19:26 UTC       16h Sat 2026-09-12 06:32:23 UTC  2h 2min ago apt-daily.timer                apt-daily.service
Sun 2026-09-13 03:10:17 UTC       18h -                                      - e2scrub_all.timer              e2scrub_all.service
Sun 2026-09-13 06:05:24 UTC       21h Sat 2026-09-12 06:29:08 UTC  2h 5min ago apt-daily-upgrade.timer        apt-daily-upgrade.service
Sun 2026-09-13 10:55:48 UTC  1 day 2h Sat 2026-09-12 04:18:15 UTC 4h 16min ago man-db.timer                   man-db.service
Mon 2026-09-14 00:12:37 UTC 1 day 15h Fri 2026-09-11 10:53:43 UTC            - fstrim.timer                   fstrim.service
Sat 2026-09-19 03:36:28 UTC    6 days -                                      - update-notifier-motd.timer     update-notifier-motd.service
-                                   - -                                      - apport-autoreport.timer        apport-autoreport.service
-                                   - -                                      - snapd.snap-repair.timer        snapd.snap-repair.service
-                                   - -                                      - ua-timer.timer                 ua-timer.service
18 timers listed.
NEXT                            LEFT LAST                         PASSED UNIT                           ACTIVATES
Sat 2026-09-12 10:59:38 UTC 2h 24min Fri 2026-09-11 10:59:38 UTC 21h ago launchpadlib-cache-clean.timer launchpadlib-cache-clean.service
Sat 2026-09-12 17:16:52 UTC       8h -                                 - hermes-ui-backup.timer         hermes-ui-backup.service
2 timers listed.
644 root:root /etc/cron.d/.placeholder
644 root:root /etc/cron.d/e2scrub_all
644 root:root /etc/cron.d/sysstat
644 root:root /etc/cron.daily/.placeholder
644 root:root /etc/cron.hourly/.placeholder
644 root:root /etc/cron.weekly/.placeholder
755 root:root /etc/cron.daily/apport
755 root:root /etc/cron.daily/apt-compat
755 root:root /etc/cron.daily/dpkg
755 root:root /etc/cron.daily/logrotate
755 root:root /etc/cron.daily/man-db
755 root:root /etc/cron.daily/sysstat
755 root:root /etc/cron.weekly/man-db
```
