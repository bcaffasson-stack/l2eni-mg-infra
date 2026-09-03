#!/bin/bash
# ============================================================
# ETAPE 7 : Roundcube Webmail
# ============================================================
set -e

echo "============================================="
echo "  ETAPE 7 : Roundcube Webmail"
echo "============================================="

read -p "Mot de passe admin LDAP : " LDAP_ADMIN_PASS
SSL_DIR="/etc/ssl/l2eni"

# [1/5] Installer MariaDB + Roundcube
echo "[1/5] Installation de MariaDB + Roundcube..."
export DEBIAN_FRONTEND=noninteractive
apt install -y mariadb-server roundcube roundcube-core roundcube-mysql roundcube-plugins

# [2/5] Configurer MariaDB pour Roundcube
echo "[2/5] Configuration de la base Roundcube..."
mysql -e "CREATE DATABASE IF NOT EXISTS roundcube CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'roundcube'@'localhost' IDENTIFIED BY 'roundcube_pass';"
mysql -e "GRANT ALL PRIVILEGES ON roundcube.* TO 'roundcube'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# [3/5] Configurer Roundcube
echo "[3/5] Configuration de Roundcube..."

# Sauvegarder la config originale
cp /etc/roundcube/config.inc.php /etc/roundcube/config.inc.php.bak

cat > /etc/roundcube/config.inc.php <<'RCEOF'
<?php
/*
 * Configuration Roundcube pour L2ENI
 */

// Base de donnees
$config['db_dsnw'] = 'mysql://roundcube:roundcube_pass@localhost/roundcube';

// Serveur IMAP (Dovecot local)
$config['default_host'] = 'ssl://127.0.0.1:993';
$config['default_port'] = 993;

// Serveur SMTP (Postfix local)
$config['smtp_server'] = 'tls://127.0.0.1:587';
$config['smtp_port'] = 587;
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';

// Langue et timezone
$config['language'] = 'fr_FR';
$config['timezone'] = 'Indian/Antananarivo';

// Securite
$config['des_key'] = 'L2ENI-SECRET-KEY-2026-CHANGE-ME';
$config['enable_installer'] = false;

// Dossier IMAP par defaut
$config['maildir'] = '';

// Carnet d'adresses LDAP
$config['ldap_public'] = array(
    'l2eni' => array(
        'name' => 'L2ENI LDAP',
        'host' => 'ldap://localhost',
        'port' => 389,
        'use_tls' => false,
        'user' => 'cn=admin,dc=l2eni,dc=mg',
        'pass' => 'LDAP_ADMIN_PASS_PLACEHOLDER',
        'base_dn' => 'ou=people,dc=l2eni,dc=mg',
        'search_filter' => '(&(objectClass=inetOrgPerson)(|(mail=*%q*)(cn=*%q*)(sn=*%q*)))',
        'name_field' => 'cn',
        'email_field' => 'mail',
        'surname_field' => 'sn',
        'required_fields' => array('cn', 'mail'),
    )
);

// Skin
$config['skin'] = 'elastic';

// Plugins
$config['plugins'] = array(
    'archive',
    'zipdownload',
    'password',
    'managesieve',
    'jqueryui',
);
RCEOF

# Remplacer le mot de passe LDAP dans la config
sed -i "s/LDAP_ADMIN_PASS_PLACEHOLDER/${LDAP_ADMIN_PASS}/" /etc/roundcube/config.inc.php

# [4/5] Configurer le VirtualHost Apache pour webmail
echo "[4/5] Creation du VirtualHost webmail.l2eni.mg..."

cat > /etc/apache2/sites-available/webmail-l2eni-mg.conf <<EOF
<VirtualHost *:80>
    ServerName webmail.l2eni.mg
    Redirect permanent / https://webmail.l2eni.mg/
</VirtualHost>

<VirtualHost *:443>
    ServerName webmail.l2eni.mg

    SSLEngine on
    SSLCertificateFile    ${SSL_DIR}/webmail.l2eni.mg.crt
    SSLCertificateKeyFile ${SSL_DIR}/webmail.l2eni.mg.key
    SSLCertificateChainFile ${SSL_DIR}/ca.crt

    DocumentRoot /var/lib/roundcube/public_html

    <Directory /var/lib/roundcube/public_html>
        AllowOverride All
        Require all granted
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/webmail-error.log
    CustomLog \${APACHE_LOG_DIR}/webmail-access.log combined
</VirtualHost>
EOF

a2ensite webmail-l2eni-mg.conf

# Permissions
chown -R www-data:www-data /var/lib/roundcube/

# [5/5] Redemarrer les services
echo "[5/5] Redemarrage des services..."
apachectl -t
systemctl restart apache2

echo ""
echo "============================================="
echo "  ETAPE 7 TERMINEE !"
echo "  URL : https://webmail.l2eni.mg"
echo "  Login : prof1 / prof123"
echo "         etudiant1 / etudiant123"
echo "         admin / admin123"
echo "  IMAP : ssl://localhost:993"
echo "  SMTP : tls://localhost:587"
echo "============================================="
