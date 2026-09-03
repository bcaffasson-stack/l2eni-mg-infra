#!/bin/bash
# ============================================================
# ETAPE 2 : Serveur DNS (BIND9) pour l2eni.mg
# ============================================================
set -e

echo "============================================="
echo "  ETAPE 2 : Serveur DNS (BIND9)"
echo "============================================="

read -p "Quelle est l'IP de ta VM ? (ex: 192.168.1.50) : " VM_IP

# Installer BIND9
echo "[1/5] Installation de BIND9..."
apt install -y bind9 bind9utils dnsutils

# Configurer named.conf.options (DNS autoritatif)
echo "[2/5] Configuration de BIND9..."
cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";

    # Mode autoritatif uniquement (pas de recursion)
    recursion no;
    allow-query { any; };
    allow-transfer { none; };

    listen-on { any; };
    listen-on-v6 { any; };

    minimal-responses yes;
    version "not disclosed";
};
EOF

# Creer le dossier des zones
mkdir -p /etc/bind/zones

# Configurer named.conf.local
echo "[3/5] Ajout de la zone l2eni.mg..."
cat > /etc/bind/named.conf.local <<EOF
zone "l2eni.mg" {
    type master;
    file "/etc/bind/zones/db.l2eni.mg";
    allow-query { any; };
};
EOF

# Creer le fichier de zone DNS
echo "[4/5] Creation du fichier de zone..."
cat > /etc/bind/zones/db.l2eni.mg <<EOF
\$TTL    86400
@       IN  SOA     ns1.l2eni.mg. admin.l2eni.mg. (
                    2026081701  ; Serial (AAAA-MM-JJNN)
                    3600        ; Refresh
                    1800        ; Retry
                    604800      ; Expire
                    86400 )     ; Negative TTL

; Nameservers
@           IN  NS      ns1.l2eni.mg.

; A Records
ns1         IN  A       ${VM_IP}
@           IN  A       ${VM_IP}
appli       IN  A       ${VM_IP}
webmail     IN  A       ${VM_IP}
mail        IN  A       ${VM_IP}

; MX Record (serveur mail)
@           IN  MX  10  mail.l2eni.mg.

; CNAME (optionnel)
www         IN  CNAME   l2eni.mg.
EOF

# Verifier la configuration
echo "[5/5] Verification de la configuration..."
named-checkconf
named-checkzone l2eni.mg /etc/bind/zones/db.l2eni.mg

# Redemarrer BIND9
systemctl restart bind9
systemctl enable bind9

# Tester
echo ""
echo "Test DNS local..."
echo "---"
dig @localhost l2eni.mg A +short
dig @localhost appli.l2eni.mg A +short
dig @localhost webmail.l2eni.mg A +short
dig @localhost mail.l2eni.mg A +short
dig @localhost l2eni.mg MX +short
echo "---"

echo ""
echo "============================================="
echo "  ETAPE 2 TERMINEE !"
echo "  DNS autoritatif pour l2eni.mg"
echo "  IP : ${VM_IP}"
echo "============================================="
echo ""
echo "SUR TON PC WINDOWS, ajoute dans le fichier hosts :"
echo "  C:\\Windows\\System32\\drivers\\etc\\hosts"
echo ""
echo "  ${VM_IP}  l2eni.mg appli.l2eni.mg webmail.l2eni.mg mail.l2eni.mg ns1.l2eni.mg"
echo ""
echo "Pour modifier ce fichier, ouvre le Bloc-notes en tant qu'ADMINISTRATEUR."
