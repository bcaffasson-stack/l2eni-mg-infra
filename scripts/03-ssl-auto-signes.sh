#!/bin/bash
# ============================================================
# ETAPE 3 : Certificats SSL auto-signes
# ============================================================
set -e

echo "============================================="
echo "  ETAPE 3 : Certificats SSL auto-signes"
echo "============================================="

SSL_DIR="/etc/ssl/l2eni"
mkdir -p "$SSL_DIR"

# [1/4] Creer l'autorite de certification locale (CA)
echo "[1/4] Creation de la CA locale..."
openssl genrsa -out "$SSL_DIR/ca.key" 4096
openssl req -new -x509 -days 3650 -key "$SSL_DIR/ca.key" \
    -out "$SSL_DIR/ca.crt" \
    -subj "/C=MG/ST=Antananarivo/L=Antananarivo/O=L2ENI/CN=L2ENI-CA"

# Fonction pour generer un certificat pour un domaine
generer_cert() {
    local DOMAIN=$1
    local IP=$2

    echo "  -> Certificat pour ${DOMAIN}..."

    # Creer la config SAN (Subject Alternative Names)
    cat > "$SSL_DIR/${DOMAIN}.cnf" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C = MG
ST = Antananarillo
L = Antananarillo
O = L2ENI
CN = ${DOMAIN}

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = ${DOMAIN}
IP.1 = ${IP}
EOF

    # Generer la cle privee
    openssl genrsa -out "$SSL_DIR/${DOMAIN}.key" 2048

    # Generer la CSR (Certificate Signing Request)
    openssl req -new -key "$SSL_DIR/${DOMAIN}.key" \
        -out "$SSL_DIR/${DOMAIN}.csr" \
        -config "$SSL_DIR/${DOMAIN}.cnf"

    # Signer avec la CA
    openssl x509 -req -days 3650 \
        -in "$SSL_DIR/${DOMAIN}.csr" \
        -CA "$SSL_DIR/ca.crt" \
        -CAkey "$SSL_DIR/ca.key" \
        -CAcreateserial \
        -out "$SSL_DIR/${DOMAIN}.crt" \
        -extensions v3_req \
        -extfile "$SSL_DIR/${DOMAIN}.cnf"
}

# [2/4] Generer les certificats pour chaque domaine
echo "[2/4] Generation des certificats..."
read -p "Quelle est l'IP de ta VM ? (ex: 192.168.1.50) : " VM_IP

generer_cert "appli.l2eni.mg" "$VM_IP"
generer_cert "webmail.l2eni.mg" "$VM_IP"
generer_cert "mail.l2eni.mg" "$VM_IP"

# [3/4] Installer les certificats dans le trust store
echo "[3/4] Installation dans le trust store..."
cp "$SSL_DIR/ca.crt" /usr/local/share/ca-certificates/l2eni-ca.crt
update-ca-certificates

# [4/4] Permissions
chmod 600 "$SSL_DIR"/*.key
chmod 644 "$SSL_DIR"/*.crt

echo ""
echo "Certificats generes :"
ls -la "$SSL_DIR"/*.crt
echo ""
echo "============================================="
echo "  ETAPE 3 TERMINEE !"
echo "  CA         : ${SSL_DIR}/ca.crt"
echo "  appli      : ${SSL_DIR}/appli.l2eni.mg.crt"
echo "  webmail    : ${SSL_DIR}/webmail.l2eni.mg.crt"
echo "  mail       : ${SSL_DIR}/mail.l2eni.mg.crt"
echo "============================================="
