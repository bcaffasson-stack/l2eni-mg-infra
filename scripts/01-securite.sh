#!/bin/bash
# ============================================================
# ETAPE 1 : Durcissement securite (SSH, UFW, fail2ban)
# ============================================================
set -e

echo "============================================="
echo "  ETAPE 1 : Securite du serveur"
echo "============================================="

# Creer un utilisateur non-root
echo "[1/6] Creation d'un utilisateur admin..."
adduser admin_l2eni --disabled-password --gecos "" 2>/dev/null || true
usermod -aG sudo admin_l2eni
echo "admin_l2eni:admin123" | chpasswd
echo "Utilisateur admin_l2eni cree (mot de passe: admin123)"

# Installer les outils de securite
echo "[2/6] Installation de UFW + fail2ban..."
apt install -y ufw fail2ban

# Configurer UFW (Pare-feu)
echo "[3/6] Configuration du pare-feu UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment "SSH"
ufw allow 80/tcp comment "HTTP"
ufw allow 443/tcp comment "HTTPS"
ufw allow 25/tcp comment "SMTP"
ufw allow 465/tcp comment "SMTPS"
ufw allow 587/tcp comment "Submission"
ufw allow 993/tcp comment "IMAPS"
ufw allow 143/tcp comment "IMAP"
ufw allow 53/tcp comment "DNS TCP"
ufw allow 53/udp comment "DNS UDP"
ufw --force enable

# Configurer fail2ban
echo "[4/6] Configuration de fail2ban..."
cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF
systemctl restart fail2ban
systemctl enable fail2ban

# Installer les mises a jour automatiques
echo "[5/6] Installation des mises a jour automatiques..."
apt install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF
dpkg-reconfigure -f noninteractive unattended-upgrades

# Installer les outils utiles
echo "[6/6] Installation des outils utilitaires..."
apt install -y curl wget vim nano net-tools dnsutils mailutils

echo ""
echo "============================================="
echo "  ETAPE 1 TERMINEE !"
echo "  - User admin_l2eni cree (MDP: admin123)"
echo "  - Pare-feu UFW actif"
echo "  - fail2ban actif"
echo "  - Mises a jour auto"
echo "============================================="
