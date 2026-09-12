# Install Hermes UI Customizations on Another Hermes VPS

This repo is private, so the safest simple setup is a read-only GitHub deploy
key from your friend's Hermes VPS.

## 1. Friend Generates an SSH Deploy Key

Run this on the friend's Hermes VPS:

```bash
sudo -i
mkdir -p ~/.ssh
chmod 700 ~/.ssh

ssh-keygen -t ed25519 \
  -C "hermes-ui-customizations@$(hostname)" \
  -f ~/.ssh/hermes_ui_customizations \
  -N ""

cat ~/.ssh/hermes_ui_customizations.pub
```

Send only the `.pub` output to the repo owner. Never send the private key file:

```text
/root/.ssh/hermes_ui_customizations
```

## 2. Repo Owner Adds the Public Key to GitHub

Open:

```text
https://github.com/kdbdevs/hermes-ui-customizations
```

Then go to:

```text
Settings -> Deploy keys -> Add deploy key
```

Use a title like:

```text
friend-hermes-vps
```

Paste the public key. Leave `Allow write access` unchecked unless that VPS must
push into this repo. For auto-pull, read-only access is enough.

## 3. Friend Configures SSH Alias

Run this on the friend's Hermes VPS:

```bash
sudo -i
ssh-keyscan github.com >> ~/.ssh/known_hosts

cat >> ~/.ssh/config <<'EOF'
Host github.com-hermes-ui
  HostName github.com
  User git
  IdentityFile ~/.ssh/hermes_ui_customizations
  IdentitiesOnly yes
EOF

chmod 600 ~/.ssh/config
ssh -T git@github.com-hermes-ui
```

GitHub may say shell access is not provided. That is fine as long as the key is
accepted.

## 4. Clone and Install

```bash
sudo -i
git clone git@github.com-hermes-ui:kdbdevs/hermes-ui-customizations.git /root/hermes-ui-customizations
cd /root/hermes-ui-customizations

./install.sh
```

If the friend only wants the theme and Kanban UI, disable Preview Lab:

```bash
INSTALL_PREVIEW_LAB=0 ./install.sh
```

## 5. Auto-Pull Updates

The installer creates this systemd timer:

```bash
systemctl status hermes-ui-customizations-sync.timer
```

It runs on boot and then roughly every 24 hours:

```bash
/root/hermes-ui-customizations/sync.sh
```

Run a manual update any time:

```bash
sudo -i
/root/hermes-ui-customizations/sync.sh
```

## 6. Verify

Check installed services:

```bash
systemctl status hermes-preview-lab.service
```

Check local health endpoint:

```bash
curl -fsS http://127.0.0.1:8088/health
```

Open Hermes UI and select:

```text
n8n Workflow
```
