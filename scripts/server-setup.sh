#!/usr/bin/env bash
# ============================================================
#  server-setup.sh — Hetzner CX22 (Ubuntu 24.04) Bootstrap
#  Einmalig als root ausführen: bash server-setup.sh
# ============================================================
set -euo pipefail

DEPLOY_USER="deploy"
REPO_URL="https://github.com/DEIN-GITHUB-USER/mini-apps.git"   # <── anpassen
APP_DIR="/opt/mini-apps"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 1/6  System-Updates"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
apt-get update -q && apt-get upgrade -y -q

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 2/6  Docker installieren"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
apt-get install -y -q ca-certificates curl gnupg lsb-release git ufw

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -q
apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable --now docker
echo "✅ Docker $(docker --version)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 3/6  Deploy-User anlegen"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ! id "$DEPLOY_USER" &>/dev/null; then
  useradd -m -s /bin/bash "$DEPLOY_USER"
  echo "User '$DEPLOY_USER' erstellt"
fi

# deploy darf Docker nutzen
usermod -aG docker "$DEPLOY_USER"

# SSH-Key kopieren (root → deploy)
mkdir -p /home/$DEPLOY_USER/.ssh
cp /root/.ssh/authorized_keys /home/$DEPLOY_USER/.ssh/authorized_keys 2>/dev/null || true
chown -R $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.ssh
chmod 700 /home/$DEPLOY_USER/.ssh
chmod 600 /home/$DEPLOY_USER/.ssh/authorized_keys

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 4/6  Repo klonen"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mkdir -p "$APP_DIR"
if [ ! -d "$APP_DIR/.git" ]; then
  git clone "$REPO_URL" "$APP_DIR"
fi
chown -R $DEPLOY_USER:$DEPLOY_USER "$APP_DIR"
echo "✅ Repo unter $APP_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 5/6  Firewall (UFW)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh        # 22
ufw allow http       # 80
ufw allow https      # 443
ufw --force enable
ufw status verbose
echo "✅ Firewall aktiv"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 6/6  SSH absichern"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Passwort-Login deaktivieren, Root-Login sperren
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/'              /etc/ssh/sshd_config
systemctl reload ssh
echo "✅ SSH gehärtet (nur Key-Auth, kein Root-Login)"

echo ""
echo "════════════════════════════════════════════════"
echo " ✅  Server-Setup abgeschlossen!"
echo "    Nächster Schritt: .env anlegen und"
echo "    'docker compose up -d --build' ausführen"
echo "════════════════════════════════════════════════"
