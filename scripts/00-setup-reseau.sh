#!/bin/bash
# ============================================================
# ETAPE 0 : Configuration reseau et hostname
# ============================================================
set -e

echo "============================================="
echo "  ETAPE 0 : Configuration reseau + hostname"
echo "============================================="

# Demander l'IP de la VM
echo ""
read -p "Quelle est l'IP de ta VM ? (ex: 192.168.1.50) : " VM_IP
read -p "Quel est l'interface reseau ? (ex: enp0s3, eth0) : " NET_IFACE

# Configurer le hostname
echo "[1/4] Configuration du hostname..."
hostnamectl set-hostname serveur.l2eni.mg

# Configurer /etc/hosts
echo "[2/4] Configuration de /etc/hosts..."
cat > /etc/hosts <<EOF
127.0.0.1   localhost
${VM_IP}    serveur.l2eni.mg serveur l2eni.mg
EOF

# Configurer le resolver pour utiliser notre propre DNS
echo "[3/4] Configuration du resolver..."
cat > /etc/resolv.conf <<EOF
nameserver 127.0.0.1
nameserver 8.8.8.8
search l2eni.mg
EOF

# Mettre a jour le systeme
echo "[4/4] Mise a jour du systeme..."
apt update && apt upgrade -y

echo ""
echo "============================================="
echo "  ETAPE 0 TERMINEE !"
echo "  IP : ${VM_IP}"
echo "  Hostname : serveur.l2eni.mg"
echo "============================================="
echo ""
echo "IMPORTANT : Note ton IP (${VM_IP}), tu en auras besoin."
echo "Sur ton PC Windows, ajoute dans C:\\Windows\\System32\\drivers\\etc\\hosts :"
echo "  ${VM_IP}  l2eni.mg appli.l2eni.mg webmail.l2eni.mg mail.l2eni.mg ns1.l2eni.mg"
echo ""
