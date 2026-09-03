#!/bin/bash
# ============================================================
# ETAPE 5 : Serveur Mail (Postfix + Dovecot) avec LDAP
# ============================================================
set -e

echo "============================================="
echo "  ETAPE 5 : Serveur Mail (Postfix + Dovecot)"
echo "============================================="

read -p "IP de la VM : " VM_IP
read -p "Mot de passe admin LDAP : " LDAP_ADMIN_PASS

SSL_DIR="/etc/ssl/l2eni"

# ============================================================
# POSTFIX
# ============================================================
echo ""
echo "[1/6] Installation de Postfix..."
DEBIAN_FRONTEND=noninteractive apt install -y postfix postfix-ldap

echo "[2/6] Configuration de Postfix..."
cat > /etc/postfix/main.cf <<EOF
# --- Identity ---
myhostname = mail.l2eni.mg
mydomain = l2eni.mg
myorigin = \$mydomain
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 192.168.0.0/16 10.0.0.0/8

# --- Listen ---
inet_interfaces = all
inet_protocols = all

# --- TLS (SSL auto-signe) ---
smtpd_tls_cert_file = ${SSL_DIR}/mail.l2eni.mg.crt
smtpd_tls_key_file = ${SSL_DIR}/mail.l2eni.mg.key
smtpd_tls_security_level = may
smtpd_tls_auth_only = yes
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_security_level = may
smtp_tls_CApath = /etc/ssl/certs

# --- SASL via Dovecot ---
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain = \$mydomain

# --- Restrictions ---
smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination

# --- Delivery via LMTP (Dovecot) ---
virtual_transport = lmtp:unix:private/dovecot-lmtp

# --- LDAP lookups ---
virtual_mailbox_domains = l2eni.mg
virtual_mailbox_maps = ldap:/etc/postfix/ldap_mailbox.cf
virtual_alias_maps = ldap:/etc/postfix/ldap_alias.cf
EOF

# Config LDAP pour Postfix
cat > /etc/postfix/ldap_mailbox.cf <<EOF
server_host = ldap://localhost
version = 3
bind = yes
bind_dn = cn=admin,dc=l2eni,dc=mg
bind_pw = ${LDAP_ADMIN_PASS}
search_base = ou=people,dc=l2eni,dc=mg
query_filter = (&(objectClass=inetOrgPerson)(mail=%s))
result_attribute = mail
result_filter = %s
EOF

cat > /etc/postfix/ldap_alias.cf <<EOF
server_host = ldap://localhost
version = 3
bind = yes
bind_dn = cn=admin,dc=l2eni,dc=mg
bind_pw = ${LDAP_ADMIN_PASS}
search_base = ou=people,dc=l2eni,dc=mg
query_filter = (&(objectClass=inetOrgPerson)(uid=%s))
result_attribute = mail
result_filter = %s
EOF

# ============================================================
# DOVECOT
# ============================================================
echo "[3/6] Installation de Dovecot..."
apt install -y dovecot-core dovecot-ldap dovecot-lmtpd dovecot-sieve

echo "[4/6] Configuration de Dovecot..."

# Configuration principale
cat > /etc/dovecot/dovecot.conf <<'EOF'
protocols = imap lmtp sieve
listen = *, ::
EOF

# Mail location
cat > /etc/dovecot/conf.d/10-mail.conf <<'EOF'
mail_location = maildir:/var/vmail/%d/%n/Maildir
namespace inbox {
  inbox = yes
  mailbox Drafts { special_use = \Drafts; auto = subscribe; }
  mailbox Junk { special_use = \Junk; auto = subscribe; }
  mailbox Sent { special_use = \Sent; auto = subscribe; }
  mailbox Trash { special_use = \Trash; auto = subscribe; }
}
mail_uid = vmail
mail_gid = vmail
first_valid_uid = 7200
last_valid_uid = 7200
EOF

# Auth via LDAP
cat > /etc/dovecot/conf.d/10-auth.conf <<EOF
disable_plaintext_auth = no
auth_mechanisms = plain login

passdb {
  driver = ldap
  args = /etc/dovecot/dovecot-ldap.conf
}

userdb {
  driver = ldap
  args = /etc/dovecot/dovecot-ldap.conf
}
EOF

# Config LDAP pour Dovecot
cat > /etc/dovecot/dovecot-ldap.conf <<EOF
hosts = ldap://localhost
dn = cn=admin,dc=l2eni,dc=mg
dnpass = ${LDAP_ADMIN_PASS}
auth_bind = yes
ldap_version = 3
base = ou=people,dc=l2eni,dc=mg
pass_filter = (&(objectClass=inetOrgPerson)(uid=%n))
pass_attrs = userPassword=userPassword
user_filter = (&(objectClass=inetOrgPerson)(uid=%n))
user_attrs = home=home,uidNumber=uid,gidNumber=gid
EOF

# LMTP socket pour la livraison
cat > /etc/dovecot/conf.d/10-master.conf <<'EOF'
service imap-login {
  inet_listener imap { port = 143 }
  inet_listener imaps { port = 993 ssl = yes }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
  unix_listener auth-userdb {
    mode = 0660
    user = vmail
    group = vmail
  }
}

service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0660
    user = postfix
    group = postfix
  }
}
EOF

# SSL Dovecot
cat > /etc/dovecot/conf.d/10-ssl.conf <<EOF
ssl = required
ssl_cert = <${SSL_DIR}/mail.l2eni.mg.crt
ssl_key = <${SSL_DIR}/mail.l2eni.mg.key
ssl_ca = <${SSL_DIR}/ca.crt
ssl_min_protocol = TLSv1.2
EOF

# [5/6] Creer l'utilisateur vmail
echo "[5/6] Creation de l'utilisateur vmail..."
useradd -r -u 7200 -d /var/vmail -s /usr/sbin/nologin vmail 2>/dev/null || true
mkdir -p /var/vmail
chown -R vmail:vmail /var/vmail
chmod 700 /var/vmail

# [6/6] Demarrer les services
echo "[6/6] Demarrage des services..."
systemctl restart dovecot
systemctl enable dovecot
systemctl restart postfix
systemctl enable postfix

# Tests rapides
echo ""
echo "Tests de configuration :"
echo "---"
postconf -n | grep -E "^(myhostname|mydomain|virtual_)" 
echo "---"
doveconf -n 2>/dev/null | head -20
echo "---"

echo ""
echo "============================================="
echo "  ETAPE 5 TERMINEE !"
echo "  Postfix  : SMTP (25, 465, 587)"
echo "  Dovecot  : IMAP (143, 993)"
echo "  Auth     : LDAP (l2eni.mg)"
echo "  Stockage : /var/vmail/"
echo "============================================="
