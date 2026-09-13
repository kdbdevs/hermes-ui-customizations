# Panduan Install Hermes UI Customizations

Panduan ini untuk memasang custom UI Hermes dari repo:

```text
https://github.com/kdbdevs/hermes-ui-customizations
```

Repo ini public, jadi VPS teman tidak perlu deploy key GitHub. Cukup clone,
install, lalu Hermes UI akan mendapat theme `n8n Workflow`, Kanban Flow visual,
dan command recovery untuk dipakai setelah update Hermes.

## Yang Akan Terpasang

- Theme dashboard `n8n Workflow`
- Kanban Flow visual workflow UI
- Node drag, zoom, resize, dan dynamic connector
- Preview Lab opsional untuk demo UI statis
- Auto-sync timer dari GitHub
- Command recovery:
  - `hermes-ui-backup`
  - `hermes-ui-restore`

Repo ini hanya untuk UI/theme. Jangan masukkan config Hermes, memory agent,
password VPS, API key, database, log, atau inventory pribadi.

## 1. Masuk ke VPS Hermes

Jalankan di VPS teman:

```bash
sudo -i
```

Pastikan dependency dasar tersedia:

```bash
apt update
apt install -y git curl
```

## 2. Clone Repo Public

```bash
cd /root
git clone https://github.com/kdbdevs/hermes-ui-customizations.git
cd /root/hermes-ui-customizations
```

Kalau folder sudah ada:

```bash
cd /root/hermes-ui-customizations
git pull --ff-only origin main
```

## 3. Install Semua Fitur

```bash
./install.sh
```

Installer akan memasang theme, Kanban Flow custom, Preview Lab, auto-sync timer,
dan command recovery.

Setelah selesai, buka Hermes UI lalu pilih theme:

```text
Config/System -> Theme -> n8n Workflow
```

## 4. Install Tanpa Preview Lab

Kalau cuma mau theme dan Kanban Flow:

```bash
INSTALL_PREVIEW_LAB=0 ./install.sh
```

## 5. Update Manual dari GitHub

Kalau owner repo menambahkan update baru:

```bash
sudo -i
/root/hermes-ui-customizations/sync.sh
```

Atau:

```bash
cd /root/hermes-ui-customizations
git pull --ff-only origin main
./install.sh
```

## 6. Auto-Sync Harian

Installer membuat timer systemd:

```bash
systemctl status hermes-ui-customizations-sync.timer
```

Timer ini berjalan saat boot dan kemudian kira-kira setiap 24 jam untuk menarik
update terbaru dari GitHub.

## 7. Sebelum Update Hermes

Update Hermes bisa menimpa file dashboard bawaan. Jalankan backup dulu:

```bash
sudo -i
hermes-ui-backup
```

Backup snapshot akan disimpan di:

```text
/root/hermes-backups/hermes-ui-customizations
```

## 8. Setelah Update Hermes

Kalau theme atau Kanban Flow custom hilang setelah update Hermes:

```bash
sudo -i
hermes-ui-restore
```

Command ini akan:

- Pull update terbaru dari GitHub
- Backup file dashboard Hermes yang sedang aktif
- Install ulang theme custom
- Install ulang Kanban Flow custom
- Restart Hermes dashboard

## 9. Cek Status

```bash
systemctl --user is-active hermes-dashboard.service
systemctl is-active hermes-ui-customizations-sync.timer
```

Kalau Preview Lab ikut dipasang:

```bash
systemctl is-active hermes-preview-lab.service
curl -fsS http://127.0.0.1:8088/health
```

## 10. Troubleshooting

Kalau `git clone` gagal, cek internet dan pastikan repo bisa diakses:

```bash
curl -I https://github.com/kdbdevs/hermes-ui-customizations
```

Kalau theme belum muncul di Hermes UI:

```bash
sudo -i
hermes-ui-restore
```

Lalu hard refresh browser.

Kalau dashboard tidak aktif:

```bash
systemctl --user status hermes-dashboard.service
journalctl --user -u hermes-dashboard.service -n 100 --no-pager
```

Kalau Kanban Flow tidak berubah setelah install:

```bash
sudo -i
cd /root/hermes-ui-customizations
git pull --ff-only origin main
./install.sh
systemctl --user restart hermes-dashboard.service
```
